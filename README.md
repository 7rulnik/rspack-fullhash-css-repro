# Rspack/Webpack `[fullhash]` + non-deterministic CSS minimizer

This repository explores how `[fullhash]` and `[contenthash]` behave when a CSS minimizer produces different bytes for identical input.

## Historical context — fixed bug

An earlier scenario in this repo demonstrated that `[fullhash]` did not update when CSS-only source changes occurred (while `[contenthash]` did). That bug is **fixed** in Rspack by [#13491 — fix(hash): keep fullhash in sync with css-only content changes](https://github.com/web-infra-dev/rspack/pull/13491), shipped in `@rspack/core@2.0.0-rc.2` and present in `2.0.1`. The reproduction code for that scenario has been removed; only this note remains.

## Active scenario — non-deterministic CSS minimizer

When the CSS minimizer is non-deterministic (e.g. `lightningcss` invoked with unstable `unusedSymbols` ordering), two builds of identical source produce **different on-disk CSS bytes**. In this case:

- ✅ The CSS asset filename `[contenthash]` updates (via `realContentHash: true`).
- ❌ The compilation `[fullhash]` does **not** update.

So divergent build artefacts ship under a stable `[fullhash]`.

### This is not Rspack-specific

`webpack-minimizer-test/` runs the same scenario against `webpack@5` and produces the same result. Both engines compute `[fullhash]` during `seal`, *before* `processAssets`-stage minimizers run. `realContentHash: true` rewrites asset filename `[contenthash]` post-hoc but does not revisit `[fullhash]`.

### Practical implications

- A non-deterministic minimizer ships divergent bytes under a stable `[fullhash]` on both engines.
- For cache invalidation that tracks final bytes, use per-chunk `[contenthash]` (with `realContentHash: true`), not `[fullhash]`.
- The robust fix is to make the minimizer deterministic — e.g. sort `unusedSymbols` before passing to `lightningcss`.

## Reproductions

Both directories use a synthetic non-deterministic minimizer (`nondeterministic-css-minimizer.js`) that appends a per-build random nonce to extracted CSS, simulating a real-world non-deterministic minimizer reliably without depending on `lightningcss`'s specific quirks.

### Rspack

```bash
cd rspack-minimizer-test
npm install
./reproduce.sh
```

### Webpack

```bash
cd webpack-minimizer-test
npm install
./reproduce.sh
```

Each script runs two builds with identical source, prints the `[fullhash]` and `[contenthash]` from each, and asserts the divergence.
