# Patches

This directory is reserved for small project-owned patches that cannot yet be represented by a pinned upstream commit.

At present, no local patch is required. The project uses the implementation from upstream PR #256 at the pinned commit documented in `docs/research.md`.

If a patch is added here:

1. keep it minimal and reviewable;
2. document the upstream base commit;
3. explain why it is needed;
4. prefer submitting it upstream rather than maintaining a permanent fork;
5. never include captured fingerprint data, firmware extracted from proprietary packages, secrets or personal logs.
