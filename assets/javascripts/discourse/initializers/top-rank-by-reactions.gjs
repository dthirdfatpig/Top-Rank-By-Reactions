import Component from "@glimmer/component";
import { withPluginApi } from "discourse/lib/plugin-api";
import TopRankPostBadge from "../components/top-rank-post-badge";
import TopRankFeaturedReplies from "../components/top-rank-featured-replies";

function initializeWithApi(api) {
  if (api.addTrackedPostProperties) {
    api.addTrackedPostProperties("top_reaction_rank", "top_ranked_posts");
  }

  // Add CSS class to top-ranked posts in the topic stream
  if (api.addPostClassesCallback) {
    api.addPostClassesCallback((post) => {
      if (post?.top_reaction_rank > 0) {
        return ["post-top-ranked", `top-rank-${post.top_reaction_rank}`];
      }
    });
  }

  // 1: Render trophy + text badge NEXT TO the username in the post header
  if (api.renderAfterWrapperOutlet) {
    api.renderAfterWrapperOutlet(
      "post-meta-data-poster-name",
      class extends Component {
        static shouldRender(args) {
          return Boolean(args?.post?.top_reaction_rank > 0);
        }

        <template>
          <TopRankPostBadge @post={{@outletArgs.post}} />
        </template>
      }
    );
  }

  // 2: Render top reacted replies featured section directly UNDER post #1
  if (api.renderAfterWrapperOutlet) {
    api.renderAfterWrapperOutlet(
      "post-content-cooked-html",
      class extends Component {
        static shouldRender(args) {
          if (!args?.post || args.post.post_number !== 1) {
            return false;
          }
          const items =
            args.post.top_ranked_posts ||
            args.post.topic?.top_ranked_posts;
          return Boolean(items && items.length > 0);
        }

        <template>
          <TopRankFeaturedReplies @post={{@outletArgs.post}} />
        </template>
      }
    );
  }
}

export default {
  name: "top-rank-by-reactions",
  initialize() {
    withPluginApi("1.34.0", initializeWithApi);
  },
};
