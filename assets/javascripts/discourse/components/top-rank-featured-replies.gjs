import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";

function getAvatarUrl(template) {
  if (!template) {
    return "";
  }
  return template.replace("{size}", "72");
}

function getPostUrl(topic, postNumber) {
  const baseUrl = topic?.url || window.location.pathname;
  return `${baseUrl.replace(/\/$/, "")}/${postNumber}`;
}

function getJumpTitle(postNumber) {
  try {
    return i18n("top_rank_by_reactions.jump_to_post", {
      post_number: postNumber,
    });
  } catch (_) {
    return `Jump to reply #${postNumber}`;
  }
}

function renderCooked(cooked) {
  return htmlSafe(cooked || "");
}

export default class TopRankFeaturedReplies extends Component {
  get topic() {
    return this.args.post?.topic;
  }

  get topPosts() {
    return (
      this.args.post?.top_ranked_posts ||
      this.topic?.top_ranked_posts ||
      []
    );
  }

  get hasPosts() {
    return Boolean(this.topPosts && this.topPosts.length > 0);
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
      const url = getPostUrl(this.topic, postNumber);
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
                      src={{getAvatarUrl item.user.avatar_template}}
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
                      {{#if item.user.name}}
                        {{item.user.name}}
                      {{else}}
                        {{item.user.username}}
                      {{/if}}
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
                    href={{getPostUrl this.topic item.post_number}}
                    class="top-rank-jump-btn"
                    title={{getJumpTitle item.post_number}}
                    {{on "click" (fn this.jumpToPost item.post_number)}}
                  >
                    <span>Reply #{{item.post_number}}</span>
                    {{icon "arrow-down"}}
                  </a>
                </div>
              </header>

              <div class="top-rank-card-cooked cooked">
                {{renderCooked item.cooked}}
              </div>
            </article>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
