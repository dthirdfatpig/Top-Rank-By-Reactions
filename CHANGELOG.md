# Changelog

All notable changes to the **Top-Rank-By-Reactions** Discourse plugin will be documented in this file.

## [0.0.8] - 2026-10-24

### Fixed
- **Clean Discourse Serializer Deprecations**: Migrated all `add_to_serializer` calls to the modern `include_condition: -> { ... }` keyword argument, removing deprecated positional arguments and manual `include_*?` method overrides. Completely eliminates serializer deprecation logs in `/logs`.

---

## [0.0.7] - 2026-10-18

### Security & Hardening
- **Hidden & Flagged Post Exclusion**: Explicitly excluded hidden/flagged posts (`hidden = false`) from reaction counts and featured selections, preventing flagged or reported posts from appearing at the top.
- **Guardian Permission Scoping**: Integrated Discourse `Guardian` checks into query and serializer layers. Caches are partitioned per user session ID (`guardian.user.id`) to guarantee that permission-restricted topics or posts are never visible to unauthorized or anonymous users.
- **Avatar Fallbacks**: Added Discourse system user fallbacks for missing, deleted, or anonymous user avatars.
- **Zero Information Leakage Verified**: Confirmed that serialized payloads only contain standard public post attributes (no emails, IPs, private tokens, or unapproved fields).

---

## [0.0.6] - 2026-10-18

### Fixed
- **Ember/Glimmer Runtime TypeError**: Fixed `can't access property "topicUrl", this is undefined` exception in `TopRankFeaturedReplies` component by converting template helper methods to pure module-level functions with explicitly passed parameters. This unblocks Ember's post stream rendering and ensures all replies in the topic load cleanly.
- Added comprehensive defensive guards for topic and user attributes in serializers and templates.

---

## [0.0.5] - 2026-10-18

### Added
- **Dual Display (Beginning + Original Place)**: The most reacted posts now appear prominently at the beginning of the topic directly under Post #1 in a dedicated featured card section, **while also maintaining their original chronological position** in the post stream. This preserves timeline continuity, reply context, and quotes when reading a topic.
- **Trophy Badge Beside Username**: Moved the trophy rank badge (`🏆 #N Top Reacted`) to appear inline right next to the author's username in the post header (`post-meta-data-poster-name`), providing a native and cohesive look.
- **Direct Jump Navigation**: Featured replies under Post #1 include a direct jump button ("Reply #N") with smooth scrolling and temporary highlight to navigate straight to the reply's place in the chronological timeline.
- **Browser Stylesheet MIME Type Fix**: Added route handling in `plugin.rb` supporting uppercase plugin directory names (`/[-a-zA-Z0-9_]+/`). Resolves the browser error in MS Edge, Chrome, and Safari (`Refused to apply style ... because its MIME type ('text/html') is not a supported stylesheet MIME type`).

### Changed
- Stream posts no longer require SQL reordering, ensuring native pagination, virtual scrolling, and quotes operate with 100% standard Discourse stability.
- Refined SCSS styling with full support for both light and dark themes using Discourse CSS custom properties.

---

## [0.0.4] - 2026-10-17

### Fixed
- Migrated post decoration to modern Glimmer component architecture (`api.renderBeforeWrapperOutlet` / `api.renderAfterWrapperOutlet`), resolving `decorateWidget is not a function` errors on Discourse instances using the Glimmer post stream.

---

## [0.0.3] - 2026-10-16

### Added
- Stream reordering SQL with custom default scope and windowed pagination extension (`TopicViewExtension`).
- Support for all reactions from official `discourse-reactions` (`discourse_reactions_enabled_reactions`) with user deduplication.

---

## [0.0.2] - 2026-10-15

### Changed
- Standardized plugin name and directory to `Top-Rank-By-Reactions` to eliminate asset precompilation warnings.

---

## [0.0.1] - 2026-10-15

### Added
- Initial plugin release with admin settings: enabled, min reactions, min posts, and max posts.
