# frozen_string_literal: true
# name: Top-Rank-By-Reactions
# about: Features the most reacted posts under the original post while preserving natural chronological timeline in Discourse topics.
# version: 0.0.7
# authors: Discourse Team
# url: https://github.com/dthirdfatpig/Top-Rank-By-Reactions
# required_version: 2.7.0

enabled_site_setting :top_rank_by_reactions_enabled

register_asset "stylesheets/common/top-rank-by-reactions.scss"

register_svg_icon "trophy"
register_svg_icon "arrow-down"

after_initialize do
  # Fix for uppercase plugin names and strict stylesheet MIME checking in modern browsers (MS Edge / Chrome / Safari).
  # Discourse core routes /stylesheets/:name with constraint /[-a-z0-9_]+/, which 404s and returns text/html
  # when the plugin directory or name contains uppercase letters.
  Discourse::Application.routes.prepend do
    get "stylesheets/:name" => "stylesheets#show_source_map",
      constraints: {
        name: /[-a-zA-Z0-9_]+/,
        format: /css\.map/,
      },
      format: true

    get "stylesheets/:name" => "stylesheets#show",
      constraints: {
        name: /[-a-zA-Z0-9_]+/,
        format: "css",
      },
      format: true
  end

  module ::TopRankByReactions
    PLUGIN_NAME = "Top-Rank-By-Reactions"

    def self.should_rank_topic?(topic, guardian = nil)
      return false unless SiteSetting.top_rank_by_reactions_enabled
      return false if topic.blank? || topic.private_message?
      return false if guardian.present? && !guardian.can_see_topic?(topic)
      return false if topic.posts_count.to_i < SiteSetting.top_rank_by_reactions_min_posts.to_i

      top_reaction_post_ids(topic, guardian).present?
    end

    def self.top_reaction_post_ids(topic, guardian = nil)
      return [] if topic.blank?

      user_id = guardian&.user&.id || 0
      cache_key = :"@top_rank_reaction_post_ids_#{user_id}"
      if topic.instance_variable_defined?(cache_key)
        return topic.instance_variable_get(cache_key)
      end

      ids = TopPostsQuery.new(topic, guardian).top_post_ids
      topic.instance_variable_set(cache_key, ids)
      ids
    end

    def self.top_ranked_posts(topic, guardian = nil)
      return [] unless should_rank_topic?(topic, guardian)

      user_id = guardian&.user&.id || 0
      cache_key = :"@top_ranked_posts_data_#{user_id}"
      if topic.instance_variable_defined?(cache_key)
        return topic.instance_variable_get(cache_key)
      end

      data = TopPostsQuery.new(topic, guardian).top_posts_data
      topic.instance_variable_set(cache_key, data)
      data
    end

    def self.top_reaction_rank_for(topic, post_id, guardian = nil)
      return nil unless should_rank_topic?(topic, guardian)

      ids = top_reaction_post_ids(topic, guardian)
      idx = ids.index(post_id)
      idx ? idx + 1 : nil
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

  # Prepend TopicViewExtension to topic view
  reloadable_patch do
    ::TopicView.prepend(TopRankByReactions::TopicViewExtension)
  end

  # Add top_ranked_posts to TopicViewSerializer for topic-level access
  add_to_serializer(:topic_view, :top_ranked_posts, false) do
    TopRankByReactions.top_ranked_posts(object.topic, scope)
  end

  add_to_serializer(:topic_view, :include_top_ranked_posts?) do
    TopRankByReactions.should_rank_topic?(object.topic, scope)
  end

  # Also add top_ranked_posts directly to PostSerializer on post #1
  add_to_serializer(:post, :top_ranked_posts, false) do
    current_topic = respond_to?(:topic) && topic ? topic : object.topic
    TopRankByReactions.top_ranked_posts(current_topic, scope)
  end

  add_to_serializer(:post, :include_top_ranked_posts?) do
    current_topic = respond_to?(:topic) && topic ? topic : object.topic
    object.post_number == 1 && TopRankByReactions.should_rank_topic?(current_topic, scope)
  end

  # Add top_reaction_rank to PostSerializer so stream posts can display their rank badge
  add_to_serializer(:post, :top_reaction_rank, false) do
    current_topic = respond_to?(:topic) && topic ? topic : object.topic
    topic_view&.top_reaction_rank_for(object.id) || TopRankByReactions.top_reaction_rank_for(current_topic, object.id, scope)
  end

  add_to_serializer(:post, :include_top_reaction_rank?) do
    current_topic = respond_to?(:topic) && topic ? topic : object.topic
    rank = topic_view&.top_reaction_rank_for(object.id) || TopRankByReactions.top_reaction_rank_for(current_topic, object.id, scope)
    rank.present? && rank > 0
  end
end
