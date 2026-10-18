# frozen_string_literal: true

module TopRankByReactions
  class TopPostsQuery
    def self.reactions_table_exists?
      return @reactions_table_exists if defined?(@reactions_table_exists)

      @reactions_table_exists = ActiveRecord::Base.connection.table_exists?(:discourse_reactions_reaction_users)
    end

    def self.reset_cache!
      remove_instance_variable(:@reactions_table_exists) if defined?(@reactions_table_exists)
    end

    def initialize(topic, guardian = nil)
      @topic = topic
      @guardian = guardian
    end

    def top_post_ids
      return [] unless should_display?

      min_reactions = [SiteSetting.top_rank_by_reactions_min_reactions.to_i, 1].max
      max_posts = [[SiteSetting.top_rank_by_reactions_max_posts.to_i, 1].max, 5].min

      reaction_counts = count_reactions_per_post
      return [] if reaction_counts.empty?

      eligible = reaction_counts
                   .select { |_, count| count >= min_reactions }
                   .sort_by { |post_id, count| [-count, post_id] }
                   .first(max_posts)

      return [] if eligible.empty?

      eligible_ids = eligible.map(&:first)

      valid_ids = Post
                    .where(id: eligible_ids)
                    .where(topic_id: @topic.id)
                    .where(deleted_at: nil)
                    .where(post_type: Post.types[:regular])
                    .where("post_number > 1")
                    .pluck(:id)

      eligible_ids.select { |id| valid_ids.include?(id) }
    end

    def top_posts_data
      ids = top_post_ids
      return [] if ids.blank?

      reaction_counts = count_reactions_per_post
      posts = Post
                .includes(:user)
                .where(id: ids)
                .where(topic_id: @topic.id)
                .where(deleted_at: nil)
                .index_by(&:id)

      ids.each_with_index.map do |id, idx|
        post = posts[id]
        next unless post

        user = post.user
        avatar_template = user&.avatar_template.to_s
        avatar_url = avatar_template.gsub("{size}", "72")

        username = user&.username || "anonymous"
        name = user&.name.presence || username

        {
          id: post.id,
          post_number: post.post_number,
          user: {
            id: user&.id,
            username: username,
            name: name,
            avatar_template: avatar_template,
            avatar_url: avatar_url,
          },
          cooked: post.cooked,
          created_at: post.created_at,
          reaction_count: reaction_counts[id].to_i,
          rank: idx + 1,
        }
      end.compact
    end

    def should_display?
      SiteSetting.top_rank_by_reactions_enabled &&
        @topic.present? &&
        !@topic.private_message? &&
        @topic.posts_count.to_i >= SiteSetting.top_rank_by_reactions_min_posts.to_i
    end

    def valid_reactions_list
      reactions = []

      if SiteSetting.respond_to?(:discourse_reactions_enabled_reactions)
        configured = SiteSetting.discourse_reactions_enabled_reactions.to_s.split("|").map(&:strip).reject(&:blank?)
        reactions.concat(configured)
      end

      if SiteSetting.respond_to?(:discourse_reactions_reaction_for_like)
        main_rx = SiteSetting.discourse_reactions_reaction_for_like.to_s.gsub("-", "").strip
        reactions << main_rx if main_rx.present?
      end

      reactions << "heart"
      reactions.uniq
    end

    def count_reactions_per_post
      valid_rx = valid_reactions_list

      if self.class.reactions_table_exists?
        sql = <<~SQL
          SELECT post_id, COUNT(DISTINCT user_id) AS total
          FROM (
            SELECT pa.post_id, pa.user_id
            FROM post_actions pa
            INNER JOIN posts p ON p.id = pa.post_id
            WHERE p.topic_id = :topic_id
              AND p.post_number > 1
              AND p.deleted_at IS NULL
              AND p.post_type = :regular
              AND pa.post_action_type_id = :like_type_id
              AND pa.deleted_at IS NULL

            UNION

            SELECT dru.post_id, dru.user_id
            FROM discourse_reactions_reaction_users dru
            INNER JOIN discourse_reactions_reactions drr ON drr.id = dru.reaction_id
            INNER JOIN posts p ON p.id = dru.post_id
            WHERE p.topic_id = :topic_id
              AND p.post_number > 1
              AND p.deleted_at IS NULL
              AND p.post_type = :regular
        SQL

        params = {
          topic_id: @topic.id,
          like_type_id: PostActionType::LIKE_POST_ACTION_ID,
          regular: Post.types[:regular]
        }

        if valid_rx.present?
          sql += " AND drr.reaction_value IN (:valid_rx)"
          params[:valid_rx] = valid_rx
        end

        sql += <<~SQL
          ) ranked
          GROUP BY post_id
        SQL

        results = DB.query(sql, **params)
      else
        results = DB.query(<<~SQL, topic_id: @topic.id, like_type_id: PostActionType::LIKE_POST_ACTION_ID, regular: Post.types[:regular])
          SELECT pa.post_id, COUNT(DISTINCT pa.user_id) AS total
          FROM post_actions pa
          INNER JOIN posts p ON p.id = pa.post_id
          WHERE p.topic_id = :topic_id
            AND p.post_number > 1
            AND p.deleted_at IS NULL
            AND p.post_type = :regular
            AND pa.post_action_type_id = :like_type_id
            AND pa.deleted_at IS NULL
          GROUP BY pa.post_id
        SQL
      end

      results.each_with_object({}) { |r, h| h[r.post_id] = r.total }
    end
  end
end
