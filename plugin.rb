# frozen_string_literal: true
# name: Top-Rank-By-Reactions
# about: Highlights the most reacted posts under the original post in Discourse. Supports likes and all official Discourse reactions.
# version: 0.0.2
# authors: Discourse Team
# url: https://github.com/dthirdfatpig/Top-Rank-By-Reactions
# required_version: 2.7.0

enabled_site_setting :top_rank_by_reactions_enabled

register_asset "stylesheets/common/top-rank-by-reactions.scss"

# Register UI control icons
register_svg_icon "arrow-down"
register_svg_icon "chevron-down"
register_svg_icon "chevron-up"
register_svg_icon "trophy"

after_initialize do
  module ::TopRankByReactions
    PLUGIN_NAME = "Top-Rank-By-Reactions"
  end

  require_relative "lib/top_rank_by_reactions/top_posts_query"

  # Include top_reacted_posts on the topic view serializer
  add_to_serializer(:topic_view, :top_reacted_posts, false) do
    TopRankByReactions::TopPostsQuery.new(object.topic, scope).top_posts
  end

  add_to_serializer(:topic_view, :include_top_reacted_posts?) do
    SiteSetting.top_rank_by_reactions_enabled &&
      object.topic.present? &&
      !object.topic.private_message? &&
      object.topic.posts_count.to_i >= SiteSetting.top_rank_by_reactions_min_posts.to_i
  end

  # Also add to PostSerializer for post #1 so it is available directly on the first post
  add_to_serializer(:post, :top_reacted_posts, false) do
    TopRankByReactions::TopPostsQuery.new(topic, scope).top_posts
  end

  add_to_serializer(:post, :include_top_reacted_posts?) do
    object.post_number == 1 &&
      SiteSetting.top_rank_by_reactions_enabled &&
      topic.present? &&
      !topic.private_message? &&
      topic.posts_count.to_i >= SiteSetting.top_rank_by_reactions_min_posts.to_i
  end
end
