# Rspack [fullhash] Bug Reproduction

This repository contains a minimal, reproducible test case demonstrating a bug in Rspack where the `[fullhash]` placeholder does not update when CSS-only changes occur.

## The Bug

When CSS content changes but JavaScript remains unchanged:
- ✅ CSS `[contenthash]` correctly updates
- ❌ Compilation `[fullhash]` incorrectly stays the same

This causes different build outputs to have identical fullhashes, breaking cache invalidation.

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

## Why This Matters

### Production Impact

- **Cache invalidation failures** - CDNs/browsers serve stale assets
- **Non-deterministic builds** - Same source produces different output with same hash
- **Module Federation issues** - Remote entries with stale `[fullhash]` cause runtime errors
- **Version tracking problems** - Cannot rely on fullhash for build identification

### Example Scenario

```
Build A: app.abc123.js + styles.xyz789.css
Build B: app.abc123.js + styles.def456.css  ← Different CSS, same fullhash!

Problem: Build B has different content but same fullhash as Build A
Result: Caches serve wrong version, users get mismatched assets
```

## Technical Details

### What Changes Between Builds

**CSS File:**
```diff
- color: red;
- background: blue;
+ color: green;
+ background: yellow;
+ font-size: 16px;
```

**JavaScript File:**
```javascript
// Identical in both builds
(()=>{"use strict";console.log("App loaded...")})();
```

### Configuration

Both tests use identical configurations:

```javascript
{
  output: {
    filename: '[name].[fullhash].js',
  },
  plugins: [
    new CssExtractPlugin({
      filename: '[name].[contenthash].css',
    }),
  ],
  optimization: {
    realContentHash: true,
  },
}
```

## Root Cause

The bug occurs because:

1. Compilation `[fullhash]` is calculated during `create_hash_pass` (before CSS processing)
2. `RealContentHashPlugin` updates CSS content hashes during `process_assets_pass` (after fullhash calculation)
3. The fullhash is never recalculated to account for CSS changes

**Timeline:**
```
create_hash_pass      → Compute fullhash (frozen)
create_chunk_assets   → Emit CSS assets
process_assets_pass   → Optimize/minify CSS
                      → Update CSS contenthash
                      → ❌ Don't update fullhash
```

## Comparison with Webpack

Webpack correctly updates `[fullhash]` when **any** asset changes, including CSS. This proves:
- Rspack's behavior is a bug, not expected
- The fix should make Rspack match webpack
- Users expect webpack-compatible behavior

See `COMPARISON.md` for detailed side-by-side analysis.

## Files in This Repository

```
rspack-fullhash-bug-reproduction/
├── README.md                  # This file
├── INSTALL.md                 # Installation & usage guide
├── SUMMARY.md                 # Repository overview
├── VERSIONS.md                # Version information & history
├── COMPARISON.md              # Detailed comparison analysis
├── BUG_REPORT.md              # Full technical bug report
├── run-both.sh                # Run both tests and compare
├── rspack-test/               # Rspack reproduction
│   ├── package.json
│   ├── rspack.config.js
│   ├── reproduce.sh           # Automated test script
│   └── src/
│       ├── index.js
│       └── styles.css
└── webpack-test/              # Webpack comparison
    ├── package.json
    ├── webpack.config.js
    ├── reproduce.sh           # Automated test script
    └── src/
        ├── index.js
        └── styles.css
```

## Requirements

- Node.js 20+
- npm or pnpm

## Contributing

If you have insights or proposed fixes for this bug:
1. Run the reproduction to confirm the issue
2. Review `BUG_REPORT.md` for technical details
3. Submit findings to the Rspack repository

## License

MIT

## Related Links

- **Rspack Repository**: https://github.com/web-infra-dev/rspack
- **Webpack Documentation**: https://webpack.js.org/configuration/output/#template-strings

---

**Bug Reproduction Date**: January 2026
**Tested Versions**:
- Rspack: 1.7.3 (latest stable) ❌ (has bug)
- Webpack: 5.104.1 (latest stable) ✅ (works correctly)
- css-loader: 7.1.2 (latest)
