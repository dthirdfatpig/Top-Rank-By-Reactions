import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import TopRankByReactionsItem from "./top-rank-by-reactions-item";

export default class TopRankByReactionsList extends Component {
  get topPosts() {
    return (
      this.args.post?.top_reacted_posts ||
      this.args.post?.topic?.top_reacted_posts ||
      []
    );
  }

  get hasPosts() {
    return this.topPosts.length > 0;
  }

  get listTitle() {
    try {
      if (this.topPosts.length === 1) {
        return i18n("top_rank_by_reactions.title_single");
      }
      return i18n("top_rank_by_reactions.title_multiple");
    } catch (_) {
      return this.topPosts.length === 1
        ? "Top Reacted Reply"
        : "Top Reacted Replies";
    }
  }

  <template>
    {{#if this.hasPosts}}
      <section class="top-rank-by-reactions-container">
        <div class="top-rank-by-reactions-banner">
          <div class="top-rank-banner-left">
            <span class="top-rank-banner-icon">
              {{icon "trophy"}}
            </span>
            <h3 class="top-rank-banner-title">{{this.listTitle}}</h3>
          </div>
          <span class="top-rank-banner-count">
            {{this.topPosts.length}}
          </span>
        </div>

        <div class="top-rank-by-reactions-items">
          {{#each this.topPosts as |rankedPost|}}
            <TopRankByReactionsItem
              @rankedPost={{rankedPost}}
              @topic={{@post.topic}}
            />
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
