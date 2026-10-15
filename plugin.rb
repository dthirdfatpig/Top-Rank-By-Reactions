# frozen_string_literal: true
# name: Top-Rank-By-Reactions
# about: Bumps the most reacted posts (likes and all official Discourse reactions) to the top under the original post in Discourse topics.
# version: 0.0.3
# authors: Discourse Team
# url: https://github.com/dthirdfatpig/Top-Rank-By-Reactions
# required_version: 2.7.0

enabled_site_setting :top_rank_by_reactions_enabled

register_asset "stylesheets/common/top-rank-by-reactions.scss"

register_svg_icon "trophy"

after_initialize do
  module ::TopRankByReactions
    PLUGIN_NAME = "Top-Rank-By-Reactions"

    def self.should_rank_topic?(topic)
      return false unless SiteSetting.top_rank_by_reactions_enabled
      return false if topic.blank? || topic.private_message?
      return false if topic.posts_count.to_i < SiteSetting.top_rank_by_reactions_min_posts.to_i

      top_reaction_post_ids(topic).present?
    end

    def self.top_reaction_post_ids(topic)
      return [] if topic.blank?

      cache_key = :@top_rank_reaction_post_ids
      if topic.instance_variable_defined?(cache_key)
        return topic.instance_variable_get(cache_key)
      end

      ids = TopPostsQuery.new(topic).top_post_ids
      topic.instance_variable_set(cache_key, ids)
      ids
    end

    def self.order_sql_for_topic(topic)
      ids = top_reaction_post_ids(topic)
      return nil if ids.blank?

      when_clauses = ids.each_with_index.map { |id, idx| "WHEN #{id.to_i} THEN #{idx + 1}" }.join(" ")
      "CASE posts.post_number WHEN 1 THEN 0 ELSE CASE posts.id #{when_clauses} ELSE #{ids.length + 1} END END ASC, posts.sort_order ASC"
    end
  end

  require_relative "lib/top_rank_by_reactions/top_posts_query"
  require_relative "lib/top_rank_by_reactions/topic_view_extension"

  # Apply custom default scope to reorder posts in the topic stream
  # Keeps post #1 at the top, followed by the top reacted replies, followed by remaining posts
  TopicView.apply_custom_default_scope do |scope, topic_view|
    if TopRankByReactions.should_rank_topic?(topic_view.topic) &&
         !topic_view.instance_variable_get(:@replies_to_post_number) &&
         !topic_view.instance_variable_get(:@post_ids)

      order_sql = TopRankByReactions.order_sql_for_topic(topic_view.topic)
      if order_sql.present?
        scope = scope.unscope(:order).order(Arel.sql(order_sql))
      end
    end
    scope
  end

  # Prepend TopicViewExtension to handle stream pagination and windowing for reordered posts
  reloadable_patch do
    ::TopicView.prepend(TopRankByReactions::TopicViewExtension)
  end

  # Add top_reaction_rank to PostSerializer so the frontend can identify bumped posts
  add_to_serializer(:post, :top_reaction_rank, false) do
    topic_view&.top_reaction_rank_for(object.id)
  end

  add_to_serializer(:post, :include_top_reaction_rank?) do
    topic_view.present? && topic_view.respond_to?(:top_reaction_rank_for) && topic_view.top_reaction_rank_for(object.id).present?
  end
end
