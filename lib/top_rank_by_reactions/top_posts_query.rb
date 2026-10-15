# frozen_string_literal: true

module TopRankByReactions
  class TopPostsQuery
    attr_reader :topic, :guardian

    def self.reactions_table_exists?
      return @reactions_table_exists if defined?(@reactions_table_exists)

      @reactions_table_exists = ActiveRecord::Base.connection.table_exists?(:discourse_reactions_reactions)
    end

    def self.reset_table_cache!
      remove_instance_variable(:@reactions_table_exists) if defined?(@reactions_table_exists)
    end

    def initialize(topic, guardian = nil)
      @topic = topic
      @guardian = guardian
    end

    def top_posts
      return [] unless should_display?

      # Memoize on the topic instance to ensure the SQL query runs at most once per request
      if @topic.instance_variable_defined?(:@top_rank_by_reactions_cache)
        return @topic.instance_variable_get(:@top_rank_by_reactions_cache)
      end

      posts = fetch_top_posts
      @topic.instance_variable_set(:@top_rank_by_reactions_cache, posts)
      posts
    end

    def should_display?
      return false unless SiteSetting.top_rank_by_reactions_enabled
      return false if @topic.blank? || @topic.private_message?
      return false if @topic.posts_count.to_i < SiteSetting.top_rank_by_reactions_min_posts.to_i

      true
    end

    def valid_reactions_list
      reactions = []

      # Read configured reactions from discourse-reactions official site setting
      if SiteSetting.respond_to?(:discourse_reactions_enabled_reactions)
        configured = SiteSetting.discourse_reactions_enabled_reactions.to_s.split("|").map(&:strip).reject(&:blank?)
        reactions.concat(configured)
      end

      # Read main reaction for like (defaults to heart)
      if SiteSetting.respond_to?(:discourse_reactions_reaction_for_like)
        main_rx = SiteSetting.discourse_reactions_reaction_for_like.to_s.gsub("-", "").strip
        reactions << main_rx if main_rx.present?
      end

      reactions << "heart"
      reactions.uniq
    end

    private

    def fetch_top_posts
      min_reactions = [SiteSetting.top_rank_by_reactions_min_reactions.to_i, 1].max
      max_posts = [[SiteSetting.top_rank_by_reactions_max_posts.to_i, 1].max, 5].min
      valid_rx = valid_reactions_list

      post_reactions_map = calculate_reactions_for_topic(valid_rx)
      return [] if post_reactions_map.blank?

      # Filter posts by minimum reaction count threshold and sort descending
      eligible_entries = post_reactions_map.select { |_post_id, count| count >= min_reactions }
                                           .sort_by { |post_id, count| [-count, post_id] }
                                           .take(max_posts)

      return [] if eligible_entries.empty?

      eligible_post_ids = eligible_entries.map(&:first)

      # Fetch post records with authors
      posts = @topic.posts
                    .where(id: eligible_post_ids)
                    .where(deleted_at: nil)
                    .where(post_type: Post.types[:regular])
                    .where("post_number > 1")
                    .includes(:user)

      reactions_breakdown = fetch_reactions_breakdown(eligible_post_ids, valid_rx)

      # Build sorted list matching rank order
      ranked_posts = []
      eligible_entries.each_with_index do |(post_id, reaction_count), index|
        post = posts.find { |p| p.id == post_id }
        next unless post

        user = post.user
        display_name = user&.name.presence || user&.username

        ranked_posts << {
          id: post.id,
          post_number: post.post_number,
          rank: index + 1,
          reaction_count: reaction_count,
          created_at: post.created_at,
          excerpt: PrettyText.excerpt(post.cooked, 350, keep_emoji_images: true),
          cooked: post.cooked,
          url: post.url,
          user: user ? {
            id: user.id,
            username: user.username,
            name: display_name,
            avatar_template: user.avatar_template
          } : nil,
          reactions: reactions_breakdown[post.id] || []
        }
      end

      ranked_posts
    end

    def calculate_reactions_for_topic(valid_rx)
      if self.class.reactions_table_exists?
        # Unify regular likes (post_actions) and all enabled Discourse reactions
        sql = <<~SQL
          SELECT union_subquery.post_id, COUNT(DISTINCT union_subquery.user_id) AS total_count
          FROM (
            SELECT pa.post_id, pa.user_id
            FROM post_actions pa
            JOIN posts p ON p.id = pa.post_id
            WHERE p.topic_id = :topic_id
              AND p.post_number > 1
              AND p.deleted_at IS NULL
              AND p.post_type = :regular_post_type
              AND pa.post_action_type_id = :like_type_id
              AND pa.deleted_at IS NULL
            UNION
            SELECT dru.post_id, dru.user_id
            FROM discourse_reactions_reaction_users dru
            JOIN discourse_reactions_reactions drr ON drr.id = dru.reaction_id
            JOIN posts p ON p.id = dru.post_id
            WHERE p.topic_id = :topic_id
              AND p.post_number > 1
              AND p.deleted_at IS NULL
              AND p.post_type = :regular_post_type
        SQL

        params = {
          topic_id: @topic.id,
          like_type_id: PostActionType::LIKE_POST_ACTION_ID,
          regular_post_type: Post.types[:regular]
        }

        if valid_rx.present?
          sql += " AND drr.reaction_value IN (:valid_reactions)"
          params[:valid_reactions] = valid_rx
        end

        sql += <<~SQL
          ) union_subquery
          GROUP BY union_subquery.post_id
        SQL

        results = DB.query(sql, **params)
      else
        # Standard Discourse likes only
        sql = <<~SQL
          SELECT pa.post_id, COUNT(DISTINCT pa.user_id) AS total_count
          FROM post_actions pa
          JOIN posts p ON p.id = pa.post_id
          WHERE p.topic_id = :topic_id
            AND p.post_number > 1
            AND p.deleted_at IS NULL
            AND p.post_type = :regular_post_type
            AND pa.post_action_type_id = :like_type_id
            AND pa.deleted_at IS NULL
          GROUP BY pa.post_id
        SQL

        results = DB.query(
          sql,
          topic_id: @topic.id,
          like_type_id: PostActionType::LIKE_POST_ACTION_ID,
          regular_post_type: Post.types[:regular]
        )
      end

      results.each_with_object({}) { |r, h| h[r.post_id] = r.total_count }
    end

    def fetch_reactions_breakdown(post_ids, valid_rx)
      return {} unless self.class.reactions_table_exists? && post_ids.present?

      sql = <<~SQL
        SELECT post_id, reaction_value, reaction_users_count
        FROM discourse_reactions_reactions
        WHERE post_id IN (:post_ids)
          AND reaction_users_count > 0
      SQL

      params = { post_ids: post_ids }
      if valid_rx.present?
        sql += " AND reaction_value IN (:valid_reactions)"
        params[:valid_reactions] = valid_rx
      end

      sql += " ORDER BY reaction_users_count DESC"

      results = DB.query(sql, **params)
      results.group_by(&:post_id).transform_values do |rows|
        rows.map do |row|
          emoji_url = begin
            Emoji.url_for(row.reaction_value)
          rescue StandardError
            nil
          end

          {
            emoji: row.reaction_value,
            emoji_url: emoji_url,
            count: row.reaction_users_count
          }
        end
      end
    end
  end
end
