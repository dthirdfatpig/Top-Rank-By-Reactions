import Component from "@glimmer/component";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import RenderGlimmer from "discourse/widgets/render-glimmer";
import TopRankByReactionsList from "../components/top-rank-by-reactions-list";

// Mirrors the discourse-solved pattern exactly:
//
//   shouldRender checks args.post.post_number === 1 && args.post.topic.top_reacted_posts
//
// `post.topic.top_reacted_posts` is populated from the TopicViewSerializer
// extension (prepended via reloadable_patch in plugin.rb), the same way
// discourse-solved's `post.topic.accepted_answer` works.
//
// We do NOT use addTrackedPostProperties here because top_reacted_posts lives
// on the TOPIC model (from the serializer), not on individual post models.
// Tracking it as a post property would be incorrect and could break reactivity.

function initializeWithApi(api) {
  // Modern Glimmer post stream (Discourse 3.1+)
  api.renderAfterWrapperOutlet(
    "post-content-cooked-html",
    class extends Component {
      static shouldRender(args) {
        // Mirrors: args.post.post_number === 1 && args.post.topic.accepted_answer
        const topPosts = args.post?.topic?.top_reacted_posts;
        return args.post?.post_number === 1 && Array.isArray(topPosts) && topPosts.length > 0;
      }

      <template>
        <TopRankByReactionsList @post={{@outletArgs.post}} />
      </template>
    }
  );

  // Legacy widget-based post stream fallback
  withSilencedDeprecations("discourse.post-stream-widget-overrides", () => {
    api.decorateWidget("post-contents:after-cooked", (helper) => {
      if (helper.attrs.post_number !== 1) {
        return;
      }
      const post = helper.getModel();
      const topPosts = post?.topic?.top_reacted_posts;
      if (!Array.isArray(topPosts) || topPosts.length === 0) {
        return;
      }
      return new RenderGlimmer(
        helper.widget,
        "div.top-rank-by-reactions-widget-wrapper",
        <template><TopRankByReactionsList @post={{@data.post}} /></template>,
        { post }
      );
    });
  });
}

export default {
  name: "top-rank-by-reactions",
  initialize() {
    withPluginApi("1.34.0", initializeWithApi);
  },
};
