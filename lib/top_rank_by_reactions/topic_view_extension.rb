# frozen_string_literal: true

module TopRankByReactions
  module TopicViewExtension
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
