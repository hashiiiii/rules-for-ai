# Hallmark adaptations

The bundle retains the existing dotfiles snapshot based on upstream commit `aeb42fb354ff4efa36ab475773a082315a3af2ce`.

- `preserve-local-guidance.patch` retains the three modified instruction and reference files from dotfiles.
- `grid-theme.patch` retains the locally added Grid reference and supplies its missing palette tokens. Both originate from upstream commit `0e74745a104abed1a2fbeaea46d57cf0adacdc1d`.
- `bundled-references.patch` repairs links to the renamed instructions and bundled palette, and points human-only recipes and example builds at the pinned upstream commit. It also removes an extra blank line at the end of `component-cookbook.md` for whitespace checks.
- `catalog-grid.patch` includes Grid in the catalog count and studied-DNA check, so the added theme cannot bypass that check.

Only the required token stylesheet and root license are copied from outside the upstream skill directory.
The example websites are references, so they are linked rather than bundled with their separate assets.
Keep these patches reviewable when updating the upstream commit; a patch conflict requires review of the changed guidance.
