import Component from "@glimmer/component";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import RenderGlimmer from "discourse/widgets/render-glimmer";
import TopRankByReactionsList from "../components/top-rank-by-reactions-list";

function initializeWithApi(api) {
  // Track top_reacted_posts on posts
  api.addTrackedPostProperties("top_reacted_posts");

  // Modern Glimmer Post Stream wrapper outlet
  api.renderAfterWrapperOutlet(
    "post-content-cooked-html",
    class extends Component {
      static shouldRender(args) {
        const post = args.post;
        if (!post || post.post_number !== 1) {
          return false;
        }

        const topPosts =
          post.top_reacted_posts || post.topic?.top_reacted_posts;
        return Array.isArray(topPosts) && topPosts.length > 0;
      }

      <template>
        <TopRankByReactionsList @post={{@outletArgs.post}} />
      </template>
    }
  );

  // Fallback for legacy widget-based post streams
  withSilencedDeprecations("discourse.post-stream-widget-overrides", () => {
    api.decorateWidget("post-contents:after-cooked", (helper) => {
      const post = helper.getModel();
      if (!post || helper.attrs.post_number !== 1) {
        return;
      }

      const topPosts =
        post.top_reacted_posts || post.topic?.top_reacted_posts;
      if (Array.isArray(topPosts) && topPosts.length > 0) {
        return new RenderGlimmer(
          helper.widget,
          "div.top-rank-by-reactions-widget-wrapper",
          <template><TopRankByReactionsList @post={{@data.post}} /></template>,
          { post }
        );
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
