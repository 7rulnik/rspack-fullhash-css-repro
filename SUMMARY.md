# Standalone Reproduction - Summary

## What This Repository Contains

A complete, standalone reproduction of the Rspack `[fullhash]` bug, including:

✅ **Rspack test** - Demonstrates the bug with published npm packages
✅ **Webpack comparison** - Proves webpack handles this correctly
✅ **Automated comparison** - One-command script to run both and compare
✅ **Complete documentation** - Bug report, technical analysis, and usage guide

## Quick Test

```bash
git clone <this-repo>
cd rspack-fullhash-bug-reproduction
./run-both.sh
```

Output:
```
╔═══════════════════════════════════════════════════════════════════╗
║                            CONCLUSION                             ║
╚═══════════════════════════════════════════════════════════════════╝

  Webpack: ✅ WEBPACK WORKS CORRECTLY
  Rspack:  ❌ RSPACK HAS BUG

  🐛 BUG CONFIRMED!
     Webpack updates [fullhash] when CSS changes, Rspack doesn't.
```

## Repository Structure

```
rspack-fullhash-bug-reproduction/
├── README.md              # Main documentation
├── BUG_REPORT.md          # Detailed technical analysis
├── COMPARISON.md          # Webpack vs Rspack comparison
├── SUMMARY.md             # This file
├── LICENSE                # MIT License
├── .gitignore            # Git ignore rules
├── run-both.sh            # Run both tests and compare
│
├── rspack-test/           # Rspack reproduction
│   ├── package.json       # Uses @rspack/core@^1.1.7
│   ├── rspack.config.js   # Config with [fullhash]
│   ├── reproduce.sh       # Automated test script
│   └── src/
│       ├── index.js       # JS entry (unchanged)
│       └── styles.css     # CSS (will change)
│
└── webpack-test/          # Webpack comparison
    ├── package.json       # Uses webpack@^5.90.0
    ├── webpack.config.js  # Identical config
    ├── reproduce.sh       # Automated test script
    └── src/
        ├── index.js       # Same as rspack
        └── styles.css     # Same as rspack
```

## Test Results (Confirmed)

### Rspack 1.7.3 (latest stable) ❌

```
Build 1: main.1f16aa77fa5bfc1b.js + main.6fdaa5b099f97dd7.css
Build 2: main.1f16aa77fa5bfc1b.js + main.47fc5c9ca2bb0b36.css
                    ↑ SAME fullhash!           ↑ Different CSS
```

### Webpack 5.104.1 (latest stable) ✅

```
Build 1: main.2744b4031b9654aa8cff.js + main.ae891b0bda76b6bc11e1.css
Build 2: main.0c563ca2858722d902ca.js + main.3e8477e598f9aa23b9e4.css
                    ↑ Different fullhash!       ↑ Different CSS
```

## Why This Matters

When the same fullhash represents different build outputs:
- ❌ Cache invalidation fails (CDN/browser caches)
- ❌ Module Federation breaks (stale remote entries)
- ❌ Non-deterministic builds
- ❌ Can't use fullhash for versioning

## Key Features of This Reproduction

1. **Standalone** - No need for Rspack monorepo, works with npm packages
2. **Automated** - One command runs both tests and compares
3. **Clear output** - Visual comparison showing the bug
4. **Webpack proof** - Shows correct behavior for comparison
5. **Complete docs** - Technical details for fixing the bug

## Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Main documentation, quickstart guide |
| `BUG_REPORT.md` | Technical analysis, root cause, proposed fixes |
| `COMPARISON.md` | Detailed webpack vs rspack side-by-side |
| `SUMMARY.md` | This file - overview of what's included |

## Usage

### Run everything (recommended):
```bash
./run-both.sh
```

### Run individual tests:
```bash
cd rspack-test && npm install && ./reproduce.sh
cd webpack-test && npm install && ./reproduce.sh
```

## Verified On

- **Date**: January 2026
- **Node**: 20.19.4
- **Rspack**: 1.7.3 (latest stable) ❌ Bug confirmed
- **Webpack**: 5.104.1 (latest stable) ✅ Works correctly
- **css-loader**: 7.1.2 (latest)

## Next Steps

1. Share this repository with Rspack maintainers
2. Reference in GitHub issue
3. Use as proof of bug for discussion
4. Basis for implementing fix

## Credits

Bug discovered through production analysis of non-deterministic CSS minification causing Module Federation cache invalidation failures.

## License

MIT - See LICENSE file
