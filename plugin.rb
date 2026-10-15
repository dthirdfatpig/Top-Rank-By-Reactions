# frozen_string_literal: true
# name: Top-Rank-By-Reactions
# about: Highlights the most reacted posts (likes and all official Discourse reactions) under the original post.
# version: 0.0.2
# authors: Discourse Team
# url: https://github.com/dthirdfatpig/Top-Rank-By-Reactions
# required_version: 2.7.0

enabled_site_setting :top_rank_by_reactions_enabled

register_asset "stylesheets/common/top-rank-by-reactions.scss"

register_svg_icon "arrow-down"
register_svg_icon "chevron-down"
register_svg_icon "chevron-up"
register_svg_icon "trophy"

after_initialize do
  module ::TopRankByReactions
    PLUGIN_NAME = "Top-Rank-By-Reactions"
  end

  require_relative "lib/top_rank_by_reactions/top_posts_query"
  require_relative "lib/top_rank_by_reactions/topic_view_serializer_extension"

  # Prepend our extension into TopicViewSerializer — same pattern as discourse-solved.
  # This adds `top_reacted_posts` to the topic JSON so the frontend can access it
  # as `post.topic.top_reacted_posts` on post #1.
  reloadable_patch do
    ::TopicViewSerializer.prepend(TopRankByReactions::TopicViewSerializerExtension)
  end
end
