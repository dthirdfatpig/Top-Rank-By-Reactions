# frozen_string_literal: true

# Mirrors the discourse-solved TopicViewSerializerExtension pattern exactly.
# Adds `top_reacted_posts` to the topic view JSON so the Ember Topic model
# carries the data, making it accessible on the frontend as:
#   post.topic.top_reacted_posts   (from post #1)
module TopRankByReactions::TopicViewSerializerExtension
  extend ActiveSupport::Concern

  prepended { attributes :top_reacted_posts }

  def include_top_reacted_posts?
    return false unless SiteSetting.top_rank_by_reactions_enabled
    return false if object.topic.blank? || object.topic.private_message?
    return false if object.topic.posts_count.to_i < SiteSetting.top_rank_by_reactions_min_posts.to_i

    true
  end

  def top_reacted_posts
    TopRankByReactions::TopPostsQuery.new(object.topic, scope).top_posts
  end
end
