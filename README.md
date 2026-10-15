# Top-Rank-By-Reactions

**Version:** 0.0.2

A Discourse plugin that highlights and ranks the most reacted posts in a topic directly beneath the original post (Post #1).

---

## Universal Reaction Support

This plugin integrates directly with Discourse's official reactions system ([`discourse-reactions`](https://meta.discourse.org/t/discourse-reactions/183261)):

- **Any reaction set in "Discourse reactions enabled reactions"** (`discourse_reactions_enabled_reactions`) works with this plugin to rank and bump posts.
- Whether users react with hearts, thumbs up (`+1`), smiles, applause, or any custom emojis you have configured on your forum, they all count towards the post's reaction total.
- Also supports core Discourse likes.
- **Smart Deduplication**: Counts distinct reacting users across both likes and reaction emojis so reactions are accurately tallied without duplicate counts.
- **Real Emoji Rendering**: Renders the authentic Discourse emoji images for all configured reactions in the breakdown display.

---

## Admin Configuration

Configure the plugin in Discourse Admin under **Settings &rarr; Plugins &rarr; `top_rank_by_reactions`**:

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `top_rank_by_reactions_enabled` | Boolean | `false` | Enable or disable the plugin. |
| `top_rank_by_reactions_min_reactions` | Integer | `1` | Minimum number of reactions required for a post to go to the top under the original post. |
| `top_rank_by_reactions_min_posts` | Integer | `5` | Minimum number of posts in a topic before ranking starts. |
| `top_rank_by_reactions_max_posts` | Integer (1–5) | `1` | Maximum number of posts to feature at the top (from 1 to 5), ranked by number of reactions (more reactions upper). |

---

## Installation

Add the plugin repository to your Discourse `containers/app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dthirdfatpig/Top-Rank-By-Reactions.git
```

Rebuild your Discourse container:

```bash
cd /var/discourse
./launcher rebuild app
```

After the rebuild finishes:
1. Go to **Discourse Admin &rarr; Plugins** (it will appear as `Top-Rank-By-Reactions`).
2. Go to **Settings &rarr; Plugins &rarr; `top_rank_by_reactions`** and check `top_rank_by_reactions_enabled`.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
