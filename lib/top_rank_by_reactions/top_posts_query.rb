# frozen_string_literal: true

module TopRankByReactions
  class TopPostsQuery
    # Memoize whether the discourse-reactions tables exist so we only check once per process.
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

    def top_posts
      return [] unless should_display?

      # Cache on the topic object per-request to avoid running twice
      # (topic_view serializer might be accessed more than once).
      cache_key = :@top_rank_cache
      return @topic.instance_variable_get(cache_key) if @topic.instance_variable_defined?(cache_key)

      result = fetch_top_posts
      @topic.instance_variable_set(cache_key, result)
      result
    end

    private

    def should_display?
      SiteSetting.top_rank_by_reactions_enabled &&
        @topic.present? &&
        !@topic.private_message? &&
        @topic.posts_count.to_i >= SiteSetting.top_rank_by_reactions_min_posts.to_i
    end

    def min_reactions
      [SiteSetting.top_rank_by_reactions_min_reactions.to_i, 1].max
    end

    def max_posts
      [[SiteSetting.top_rank_by_reactions_max_posts.to_i, 1].max, 5].min
    end

    def fetch_top_posts
      reaction_counts = count_reactions_per_post
      return [] if reaction_counts.empty?

      # Keep only posts that meet the minimum threshold, ranked by total desc
      eligible = reaction_counts
                   .select { |_, count| count >= min_reactions }
                   .sort_by { |post_id, count| [-count, post_id] }
                   .first(max_posts)

      return [] if eligible.empty?

      eligible_ids = eligible.map(&:first)

      posts_by_id = Post
                      .where(id: eligible_ids)
                      .where(deleted_at: nil)
                      .where(post_type: Post.types[:regular])
                      .where("post_number > 1")
                      .includes(:user)
                      .index_by(&:id)

      breakdown = load_reactions_breakdown(eligible_ids)

      eligible.each_with_index.filter_map do |(post_id, reaction_count), idx|
        post = posts_by_id[post_id]
        next unless post

        user = post.user
        {
          id: post.id,
          post_number: post.post_number,
          rank: idx + 1,
          reaction_count: reaction_count,
          created_at: post.created_at,
          excerpt: PrettyText.excerpt(post.cooked, 350, keep_emoji_images: true),
          url: post.url,
          user: user && {
            id: user.id,
            username: user.username,
            name: (user.name.presence || user.username),
            avatar_template: user.avatar_template
          },
          reactions: breakdown[post.id] || []
        }
      end
    end

    # ---------------------------------------------------------------------------
    # Core reaction counting
    # ---------------------------------------------------------------------------
    # How discourse-reactions stores data:
    #   1. Main reaction (heart by default, configured via discourse_reactions_reaction_for_like)
    #      → creates ONLY a PostAction like record. No ReactionUser row.
    #   2. Other emoji reactions that COUNT as a like
    #      → creates BOTH a PostAction AND a ReactionUser row.
    #   3. Emoji reactions EXCLUDED from like
    #      → creates ONLY a ReactionUser row.
    #
    # Strategy: UNION post_actions (catches 1 and 2) with reaction_users (catches 2 and 3),
    # then COUNT(DISTINCT user_id) to deduplicate users who appear in both.
    # This correctly counts every distinct user who reacted with ANY enabled reaction.
    def count_reactions_per_post
      if self.class.reactions_table_exists?
        results = DB.query(<<~SQL, topic_id: @topic.id, like_type_id: PostActionType::LIKE_POST_ACTION_ID, regular: Post.types[:regular])
          SELECT post_id, COUNT(DISTINCT user_id) AS total
          FROM (
            -- Standard likes (covers main reaction + like-counting reactions)
            SELECT pa.post_id, pa.user_id
            FROM   post_actions pa
            INNER JOIN posts p ON p.id = pa.post_id
            WHERE  p.topic_id    = :topic_id
              AND  p.post_number > 1
              AND  p.deleted_at  IS NULL
              AND  p.post_type   = :regular
              AND  pa.post_action_type_id = :like_type_id
              AND  pa.deleted_at IS NULL

            UNION ALL

            -- Emoji reactions via discourse-reactions (covers all emoji including excluded-from-like ones)
            SELECT dru.post_id, dru.user_id
            FROM   discourse_reactions_reaction_users dru
            INNER JOIN posts p ON p.id = dru.post_id
            WHERE  p.topic_id    = :topic_id
              AND  p.post_number > 1
              AND  p.deleted_at  IS NULL
              AND  p.post_type   = :regular
          ) ranked
          GROUP BY post_id
        SQL
      else
        # discourse-reactions not installed — fall back to plain likes only
        results = DB.query(<<~SQL, topic_id: @topic.id, like_type_id: PostActionType::LIKE_POST_ACTION_ID, regular: Post.types[:regular])
          SELECT pa.post_id, COUNT(DISTINCT pa.user_id) AS total
          FROM   post_actions pa
          INNER JOIN posts p ON p.id = pa.post_id
          WHERE  p.topic_id    = :topic_id
            AND  p.post_number > 1
            AND  p.deleted_at  IS NULL
            AND  p.post_type   = :regular
            AND  pa.post_action_type_id = :like_type_id
            AND  pa.deleted_at IS NULL
          GROUP BY pa.post_id
        SQL
      end

      results.each_with_object({}) { |r, h| h[r.post_id] = r.total }
    end

    # ---------------------------------------------------------------------------
    # Reaction emoji breakdown for display pills
    # ---------------------------------------------------------------------------
    # Only available when discourse-reactions is installed.
    # Returns a hash of post_id => [{emoji:, emoji_url:, count:}, ...]
    def load_reactions_breakdown(post_ids)
      return {} unless self.class.reactions_table_exists? && post_ids.present?

      results = DB.query(<<~SQL, post_ids: post_ids)
        SELECT post_id, reaction_value, reaction_users_count
        FROM   discourse_reactions_reactions
        WHERE  post_id IN (:post_ids)
          AND  reaction_users_count > 0
        ORDER BY reaction_users_count DESC
      SQL

      results.group_by(&:post_id).transform_values do |rows|
        rows.map do |row|
          emoji_url = begin
            Emoji.url_for(row.reaction_value)
          rescue StandardError
            nil
          end
          { emoji: row.reaction_value, emoji_url: emoji_url, count: row.reaction_users_count }
        end
      end
    end
  end
end
