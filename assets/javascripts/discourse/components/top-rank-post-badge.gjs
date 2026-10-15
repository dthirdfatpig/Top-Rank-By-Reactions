import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class TopRankPostBadge extends Component {
  get rank() {
    return this.args.post?.top_reaction_rank;
  }

  get rankClass() {
    return `rank-${this.rank}`;
  }

  get rankText() {
    try {
      return i18n("top_rank_by_reactions.rank", { rank: this.rank });
    } catch (_) {
      return `#${this.rank} Top Reacted Reply`;
    }
  }

  <template>
    {{#if this.rank}}
      <div class="top-rank-bumped-badge-container">
        <span class="top-rank-bumped-badge {{this.rankClass}}">
          {{icon "trophy" class="gold-trophy"}}
          <span class="top-rank-badge-text">{{this.rankText}}</span>
        </span>
      </div>
    {{/if}}
  </template>
}
