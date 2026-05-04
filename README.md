# Rspack [fullhash] Bug Reproduction

This repository contains a minimal, reproducible test case demonstrating a bug in Rspack where the `[fullhash]` placeholder does not update when CSS-only changes occur.

## The Bug

When CSS content changes but JavaScript remains unchanged:
- ✅ CSS `[contenthash]` correctly updates
- ❌ Compilation `[fullhash]` incorrectly stays the same

This causes different build outputs to have identical fullhashes, breaking cache invalidation.

> **Status (2026-05-04):** [#13491](https://github.com/web-infra-dev/rspack/pull/13491) (in `@rspack/core` ≥ `2.0.0-rc.2`) fixes the source-change scenario above — `rspack-test/` now passes on `2.0.1`. A second scenario remains, see below.

## Scenario 2 — Non-deterministic CSS minimizer

`rspack-minimizer-test/` covers a related case still observable on `2.0.1`: with a non-deterministic CSS minimizer (e.g. `lightningcss` invoked with unstable `unusedSymbols` ordering), two builds of identical source produce **different on-disk bytes** but identical compilation `[fullhash]`. The CSS asset filename `[contenthash]` does update (via `realContentHash`), but the JS `[fullhash]` does not — so the build artefact is divergent under a stable fullhash.

```bash
cd rspack-minimizer-test
npm install
./reproduce.sh
```

### Webpack behaves the same way

`webpack-minimizer-test/` runs the identical scenario against `webpack@5`. Result: webpack also keeps `[fullhash]` stable while the CSS bytes (and `[contenthash]`) change. So this is **not an Rspack-specific bug** — it's how both pipelines work: `[fullhash]` is computed during `seal`, *before* `processAssets`-stage minimizers run. `realContentHash: true` rewrites asset filename `[contenthash]` post-hoc, but does not revisit `[fullhash]`.

Practical implications:
- A non-deterministic minimizer ships divergent bytes under a stable `[fullhash]` on both engines.
- For cache invalidation that tracks final bytes, use per-chunk `[contenthash]` (with `realContentHash: true`), not `[fullhash]`.
- The robust fix is to make the minimizer deterministic (e.g. stable input ordering).

## Proof: Webpack Comparison

This repository includes both:
- **Rspack test** - Demonstrates the bug
- **Webpack test** - Shows correct behavior

**Result**: Webpack correctly updates `[fullhash]` when CSS changes, proving this is a Rspack bug.

## Quick Start

### Option 1: Run Both Tests (Recommended)

```bash
# Install and run both tests
./run-both.sh
```

This will:
1. Install dependencies for both rspack and webpack tests
2. Run both reproduction scripts
3. Show side-by-side comparison

### Option 2: Run Individual Tests

**Rspack (shows the bug):**
```bash
cd rspack-test
npm install
./reproduce.sh
```

**Webpack (shows correct behavior):**
```bash
cd webpack-test
npm install
./reproduce.sh
```

## Expected Results

### Rspack ❌ (Bug)
```
BUILD 1:
  [fullhash]:    15d7bc99b1b65226
  [contenthash]: 6fdaa5b099f97dd7

BUILD 2 (CSS changed, JS unchanged):
  [fullhash]:    15d7bc99b1b65226  ❌ SAME (bug!)
  [contenthash]: 47fc5c9ca2bb0b36  ✅ CHANGED

🐛 BUG CONFIRMED!
   Different builds have identical fullhashes
```

### Webpack ✅ (Correct)
```
BUILD 1:
  [fullhash]:    2744b4031b9654aa8cff
  [contenthash]: ae891b0bda76b6bc11e1

BUILD 2 (CSS changed, JS unchanged):
  [fullhash]:    0c563ca2858722d902ca  ✅ CHANGED
  [contenthash]: 3e8477e598f9aa23b9e4  ✅ CHANGED

✅ WEBPACK WORKS CORRECTLY!
   Different builds have different fullhashes
```
