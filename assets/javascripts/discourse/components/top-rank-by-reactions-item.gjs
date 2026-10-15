import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class TopRankByReactionsItem extends Component {
  @tracked expanded = false;

  get post() {
    return this.args.rankedPost;
  }

  get rankClass() {
    return `rank-${this.post.rank}`;
  }

  get rankLabel() {
    try {
      return i18n("top_rank_by_reactions.rank", { rank: this.post.rank });
    } catch (_) {
      return `#${this.post.rank} Top Reacted`;
    }
  }

  get reactionsLabel() {
    const count = this.post.reaction_count;
    try {
      return i18n("top_rank_by_reactions.reactions_count", { count });
    } catch (_) {
      return count === 1 ? "1 reaction" : `${count} reactions`;
    }
  }

  get jumpLabel() {
    try {
      return i18n("top_rank_by_reactions.jump_to_post", {
        post_number: this.post.post_number,
      });
    } catch (_) {
      return `Jump to post #${this.post.post_number}`;
    }
  }

  get avatarUrl() {
    const template = this.post.user?.avatar_template;
    return template ? template.replace("{size}", "48") : "";
  }

  get formattedDate() {
    try {
      return new Date(this.post.created_at).toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    } catch (_) {
      return "";
    }
  }

  // Show toggle only when full cooked content is significantly longer than the excerpt
  get hasLongContent() {
    return (
      this.post.cooked &&
      this.post.excerpt &&
      this.post.cooked.length > this.post.excerpt.length + 50
    );
  }

  get renderedContent() {
    if (this.expanded && this.post.cooked) {
      return htmlSafe(this.post.cooked);
    }
    return htmlSafe(this.post.excerpt || this.post.cooked || "");
  }

  @action
  toggleExpanded() {
    this.expanded = !this.expanded;
  }

  @action
  jumpToPost(event) {
    const postElem = document.getElementById(`post_${this.post.post_number}`);
    if (postElem) {
      event.preventDefault();
      postElem.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }

  <template>
    <div
      class="top-rank-by-reactions-item {{this.rankClass}}"
      data-post-number={{this.post.post_number}}
    >
      {{!-- Header: rank badge + author + reaction count --}}
      <div class="top-rank-item-header">
        <div class="top-rank-badge-and-user">
          <span class="top-rank-badge">
            {{#if (eq this.post.rank 1)}}
              {{icon "trophy" class="gold-trophy"}}
            {{/if}}
            {{this.rankLabel}}
          </span>

          {{#if this.post.user}}
            <div class="top-rank-user-info">
              {{#if this.avatarUrl}}
                <img
                  src={{this.avatarUrl}}
                  alt={{this.post.user.username}}
                  class="top-rank-avatar avatar"
                  width="24"
                  height="24"
                />
              {{/if}}
              <span class="top-rank-username">{{this.post.user.name}}</span>
            </div>
          {{/if}}
        </div>

        <div class="top-rank-meta-actions">
          <span class="top-rank-reactions-pill" title={{this.reactionsLabel}}>
            {{this.reactionsLabel}}
          </span>
          {{#if this.formattedDate}}
            <span class="top-rank-date">{{this.formattedDate}}</span>
          {{/if}}
        </div>
      </div>

      {{!-- Reaction emoji breakdown pills --}}
      {{#if this.post.reactions.length}}
        <div class="top-rank-reactions-breakdown">
          {{#each this.post.reactions as |reaction|}}
            <span class="reaction-pill-mini" title={{reaction.emoji}}>
              {{#if reaction.emoji_url}}
                <img
                  src={{reaction.emoji_url}}
                  alt={{reaction.emoji}}
                  class="emoji reaction-emoji-img"
                  width="18"
                  height="18"
                />
              {{else}}
                <span class="reaction-emoji-text">:{{reaction.emoji}}:</span>
              {{/if}}
              <span class="mini-count">{{reaction.count}}</span>
            </span>
          {{/each}}
        </div>
      {{/if}}

      {{!-- Post content excerpt (expandable) --}}
      <div class="top-rank-item-body">
        <blockquote class="top-rank-item-content">
          {{this.renderedContent}}
        </blockquote>

        {{#if this.hasLongContent}}
          <button
            type="button"
            class="btn btn-flat btn-xsmall top-rank-expand-btn"
            {{on "click" this.toggleExpanded}}
          >
            {{#if this.expanded}}
              {{icon "chevron-up"}}
              {{i18n "top_rank_by_reactions.show_less"}}
            {{else}}
              {{icon "chevron-down"}}
              {{i18n "top_rank_by_reactions.show_full_post"}}
            {{/if}}
          </button>
        {{/if}}
      </div>

      {{!-- Footer: jump to post button --}}
      <div class="top-rank-item-footer">
        <a
          href={{this.post.url}}
          class="btn btn-default btn-small top-rank-jump-btn"
          {{on "click" this.jumpToPost}}
        >
          {{icon "arrow-down"}}
          <span>{{this.jumpLabel}}</span>
        </a>
      </div>
    </div>
  </template>
}
