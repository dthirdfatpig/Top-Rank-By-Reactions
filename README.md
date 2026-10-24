# Top-Rank-By-Reactions

**Version:** 0.0.9  
**Changelog:** [CHANGELOG.md](CHANGELOG.md)

A Discourse plugin that features the most reacted replies in regular topics directly beneath the original post (Post #1), while preserving the original chronological timeline and context across the entire topic stream.

---

## How It Works

Instead of altering the topic's natural chronological conversation stream, **Top-Rank-By-Reactions provides the best of both worlds**:

1. **Featured at the Top**: Directly under Post #1 (the original post), a dedicated section highlights the top-reacted replies (up to your configured limit), ranked by total reactions (highest first).
2. **Preserved in the Timeline**: Each featured reply **also remains in its original chronological position** in the stream. Quotes, replies, and conversation context stay 100% natural when reading the topic from start to finish.
3. **Trophy Badge Beside Username**: Every ranked post displays a sleek **`🏆 #N Top Reacted`** badge right next to the author's username in the post header.
4. **Quick Jump Button**: Clicking the jump button on any featured reply smoothly scrolls down to that exact post in the conversation timeline with a brief highlight.

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
| `top_rank_by_reactions_min_reactions` | Integer | `1` | Minimum number of reactions required for a post to be featured at the top under Post #1. |
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
1. Go to **Discourse Admin &rarr; Settings &rarr; Plugins &rarr; `top_rank_by_reactions`**.
2. Check `top_rank_by_reactions_enabled` and configure your thresholds.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
