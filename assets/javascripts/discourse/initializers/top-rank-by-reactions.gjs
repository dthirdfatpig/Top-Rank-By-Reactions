import Component from "@glimmer/component";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import TopRankPostBadge from "../components/top-rank-post-badge";

function initializeWithApi(api) {
  api.addTrackedPostProperties("top_reaction_rank");

  // Add CSS class to bumped posts in the topic stream
  api.addPostClassesCallback((post) => {
    if (post?.top_reaction_rank > 0) {
      return ["post-top-ranked", `top-rank-${post.top_reaction_rank}`];
    }
  });

  // Modern Glimmer post stream: render trophy badge above the cooked post content
  api.renderBeforeWrapperOutlet(
    "post-content-cooked-html",
    class extends Component {
      static shouldRender(args) {
        return args.post?.top_reaction_rank > 0;
      }

      <template>
        <TopRankPostBadge @post={{@outletArgs.post}} />
      </template>
    }
  );

  // Legacy widget post stream fallback
  withSilencedDeprecations("discourse.post-stream-widget-overrides", () => {
    api.decorateWidget("post-contents:before-cooked", (helper) => {
      const post = helper.getModel();
      if (post?.top_reaction_rank > 0) {
        return helper.h("div.top-rank-bumped-badge-container", [
          helper.h(
            `span.top-rank-bumped-badge.rank-${post.top_reaction_rank}`,
            `🏆 #${post.top_reaction_rank} Top Reacted Reply`
          ),
        ]);
      }
    });
  });
}

export default {
  name: "top-rank-by-reactions",
  initialize() {
    withPluginApi("1.34.0", initializeWithApi);
  },
};
