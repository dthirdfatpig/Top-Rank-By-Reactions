# Top-Rank-By-Reactions

**Version:** 0.0.4

A Discourse plugin that bumps the most reacted posts in regular topics directly to the top of the post stream beneath the original post (Post #1).

---

## How It Works

Instead of creating a summary box or requiring a special topic type (like Q&A/voting plugins do), **Top-Rank-By-Reactions works automatically on regular topics**:

1. **Post #1 (Original Post)** remains at the very top of the topic.
2. **Top Reacted Replies** (up to your configured limit) are bumped up in the post stream directly under Post #1, ranked by reaction count (highest first).
3. **All other replies** follow below in their regular chronological order.
4. Each bumped post displays a **`🏆 #N Top Reacted Reply`** badge above its content.

---

## Universal Discourse Reactions Support

This plugin integrates directly with the official [`discourse-reactions`](https://meta.discourse.org/t/discourse-reactions/183261) plugin:

- **Any reaction set in "Discourse reactions enabled reactions"** (`discourse_reactions_enabled_reactions`) works with this plugin to bump posts.
- Whether users react with hearts, thumbs up (`+1`), smiles, applause, or custom emojis, they all count towards the post's total.
- Also supports core Discourse likes.
- **Deduplication**: Counts unique reacting users across likes and emoji reactions so reactions are accurately tallied.

---

## Admin Configuration

Configure the plugin in Discourse Admin under **Settings &rarr; Plugins &rarr; `top_rank_by_reactions`**:

| Setting | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `top_rank_by_reactions_enabled` | Boolean | `false` | Enable or disable the plugin. |
| `top_rank_by_reactions_min_reactions` | Integer | `1` | Minimum number of reactions required for a post to be bumped to the top under Post #1. |
| `top_rank_by_reactions_min_posts` | Integer | `5` | Minimum number of posts in a topic before ranking starts. |
| `top_rank_by_reactions_max_posts` | Integer (1–5) | `1` | Maximum number of posts to bump to the top (from 1 to 5), ranked by number of reactions (more reactions upper). |

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
1. Go to **Discourse Admin &rarr; Settings &rarr; Plugins &rarr; `top_rank_by_reactions`**.
2. Check `top_rank_by_reactions_enabled` and configure your thresholds.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
