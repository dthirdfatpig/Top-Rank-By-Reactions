import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default class TopRankFeaturedReplies extends Component {
  get topPosts() {
    return (
      this.args.post?.top_ranked_posts ||
      this.args.post?.topic?.top_ranked_posts ||
      []
    );
  }

  get hasPosts() {
    return this.topPosts.length > 0;
  }

  get sectionTitle() {
    try {
      if (this.topPosts.length > 1) {
        return i18n("top_rank_by_reactions.title_multiple");
      }
      return i18n("top_rank_by_reactions.title_single");
    } catch (_) {
      return this.topPosts.length > 1
        ? "Top Reacted Replies"
        : "Top Reacted Reply";
    }
  }

  get sectionSubtitle() {
    const count = this.topPosts.length;
    return count === 1 ? "1 reply" : `${count} replies`;
  }

  get topicUrl() {
    return this.args.post?.topic?.url || window.location.pathname;
  }

  postUrl(postNumber) {
    return `${this.topicUrl}/${postNumber}`;
  }

  avatarUrl(template) {
    if (!template) {
      return "";
    }
    return template.replace("{size}", "72");
  }

  renderHtml(cooked) {
    return htmlSafe(cooked || "");
  }

  jumpTitle(postNumber) {
    try {
      return i18n("top_rank_by_reactions.jump_to_post", {
        post_number: postNumber,
      });
    } catch (_) {
      return `Jump to reply #${postNumber}`;
    }
  }

  @action
  jumpToPost(postNumber, event) {
    if (event) {
      event.preventDefault();
    }

    const postElement = document.getElementById(`post_${postNumber}`);
    if (postElement) {
      postElement.scrollIntoView({ behavior: "smooth", block: "start" });
      postElement.classList.add("highlighted");
      setTimeout(() => {
        postElement.classList.remove("highlighted");
      }, 2500);
    } else {
      const url = this.postUrl(postNumber);
      if (DiscourseURL?.routeTo) {
        DiscourseURL.routeTo(url);
      } else {
        window.location.href = url;
      }
    }
  }

  <template>
    {{#if this.hasPosts}}
      <section class="top-rank-featured-container" aria-label="Top Reacted Replies">
        <header class="top-rank-featured-main-header">
          <div class="top-rank-header-title">
            {{icon "trophy" class="gold-trophy"}}
            <span>{{this.sectionTitle}}</span>
          </div>
          <span class="top-rank-header-subtitle">{{this.sectionSubtitle}}</span>
        </header>

        <div class="top-rank-featured-list">
          {{#each this.topPosts as |item|}}
            <article
              class="top-rank-featured-card rank-{{item.rank}}"
              id="top-rank-card-{{item.post_number}}"
            >
              <header class="top-rank-card-header">
                <div class="top-rank-card-author">
                  <a
                    href="/u/{{item.user.username}}"
                    class="top-rank-avatar-link"
                    data-user-card={{item.user.username}}
                  >
                    <img
                      src={{this.avatarUrl item.user.avatar_template}}
                      class="avatar top-rank-avatar"
                      alt={{item.user.username}}
                      width="36"
                      height="36"
                      loading="lazy"
                    />
                  </a>
                  <div class="top-rank-card-names">
                    <a
                      href="/u/{{item.user.username}}"
                      class="top-rank-author-name"
                      data-user-card={{item.user.username}}
                    >
                      {{item.user.name}}
                    </a>
                    <span class="top-rank-author-username">@{{item.user.username}}</span>
                  </div>
                </div>

                <div class="top-rank-card-badges">
                  <span class="top-rank-rank-pill rank-{{item.rank}}">
                    {{icon "trophy" class="gold-trophy"}}
                    <span>#{{item.rank}} Top Reacted</span>
                  </span>

                  {{#if item.reaction_count}}
                    <span
                      class="top-rank-reactions-pill"
                      title="{{item.reaction_count}} reactions"
                    >
                      <span class="heart-icon">❤️</span>
                      <span class="reactions-count">{{item.reaction_count}}</span>
                    </span>
                  {{/if}}

                  <a
                    href={{this.postUrl item.post_number}}
                    class="top-rank-jump-btn"
                    title={{this.jumpTitle item.post_number}}
                    {{on "click" (fn this.jumpToPost item.post_number)}}
                  >
                    <span>Reply #{{item.post_number}}</span>
                    {{icon "arrow-down"}}
                  </a>
                </div>
              </header>

              <div class="top-rank-card-cooked cooked">
                {{{this.renderHtml item.cooked}}}
              </div>
            </article>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
