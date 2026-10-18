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
      return `#${this.rank} Top Reacted`;
    }
  }

  <template>
    {{#if this.rank}}
      <span class="top-rank-poster-badge {{this.rankClass}}" title={{this.rankText}}>
        {{icon "trophy" class="gold-trophy"}}
        <span class="top-rank-badge-text">{{this.rankText}}</span>
      </span>
    {{/if}}
  </template>
}
