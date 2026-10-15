# frozen_string_literal: true

module TopRankByReactions
  module TopicViewExtension
    # Monkey patch core's method to support stream ordering near a post number
    # Similar to discourse-post-voting's TopicViewExtension
    def filter_posts_near(post_number)
      return super unless TopRankByReactions.should_rank_topic?(topic)

      post_number = 1 if post_number.to_i == 0

      cte_query = <<~SQL
        WITH posts AS (
          #{@filtered_posts.to_sql}
        ),
        rows AS (
          SELECT
            id,
            post_number,
            ROW_NUMBER() OVER () AS row_number
          FROM posts
        )
      SQL

      row_number, max_row_number = DB.query_single(<<~SQL)
        #{cte_query}
        SELECT
          row_number,
          (SELECT row_number FROM rows ORDER BY row_number DESC LIMIT 1) AS max_row_number
        FROM rows
        WHERE rows.post_number = #{post_number.to_i}
      SQL

      row_number = 1 if row_number.blank?

      posts_before = (@limit.to_f / 4).floor
      posts_before = 1 if posts_before.zero?
      posts_after = @limit - posts_before - 1

      range =
        if (row_number - posts_before) <= 0
          1..(@limit - (row_number - 1))
        elsif (max_row_number - row_number) < posts_after
          (max_row_number - @limit + 1)..max_row_number
        else
          (row_number - posts_before)..(row_number + posts_after)
        end

      range_arr = range.to_a
      return super if range_arr.empty?

      post_ids = DB.query_single(<<~SQL)
        #{cte_query}
        SELECT id
        FROM rows
        WHERE rows.row_number IN (#{range_arr.join(",")})
      SQL

      return super if post_ids.blank?

      filter_posts_by_ids(post_ids)
    end

    def next_page
      return super unless TopRankByReactions.should_rank_topic?(topic)

      last_filtered = @filtered_posts.last
      return super unless last_filtered

      @highest_post_number = last_filtered.post_number

      @next_page ||=
        if last_post && @highest_post_number && (@highest_post_number != last_post.post_number)
          @page + 1
        end
    end

    def top_reaction_ranks
      @top_reaction_ranks ||= begin
        ids = TopRankByReactions.top_reaction_post_ids(topic)
        ids.each_with_index.to_h { |id, idx| [id, idx + 1] }
      end
    end

    def top_reaction_rank_for(post_id)
      top_reaction_ranks[post_id]
    end
  end
end
