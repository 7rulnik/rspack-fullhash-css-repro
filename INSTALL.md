# Installation & Usage Guide

## Prerequisites

- Node.js 20+
- npm (comes with Node.js)
- Git (for cloning)
- Unix-like shell (macOS, Linux, WSL on Windows)

## Quick Start (3 steps)

### 1. Clone or Download

**Option A: Git clone**
```bash
git clone <repository-url>
cd rspack-fullhash-bug-reproduction
```

**Option B: Download ZIP**
```bash
# Download and extract, then:
cd rspack-fullhash-bug-reproduction
```

### 2. Run the Comparison

```bash
./run-both.sh
```

This will:
- Install dependencies for both tests (if needed)
- Run webpack test (correct behavior)
- Run rspack test (shows bug)
- Display side-by-side comparison

### 3. View Results

You'll see output like:

```
╔═══════════════════════════════════════════════════════════════════╗
║                            CONCLUSION                             ║
╚═══════════════════════════════════════════════════════════════════╝

  Webpack: ✅ WEBPACK WORKS CORRECTLY
  Rspack:  ❌ RSPACK HAS BUG

  🐛 BUG CONFIRMED!
     Webpack updates [fullhash] when CSS changes, Rspack doesn't.
```

## Manual Testing

If you prefer to run tests individually:

### Test Rspack (shows bug)

```bash
cd rspack-test
npm install
./reproduce.sh
```

Expected: fullhash stays SAME when CSS changes ❌

### Test Webpack (correct behavior)

```bash
cd webpack-test
npm install
./reproduce.sh
```

Expected: fullhash CHANGES when CSS changes ✅

## What Gets Installed

### Rspack Test
- `@rspack/core` - latest (1.7.3 as of January 2026)
- `@rspack/cli` - latest (1.7.3 as of January 2026)
- `css-loader` - latest (7.1.2 as of January 2026)

### Webpack Test
- `webpack` - latest (5.104.1 as of January 2026)
- `webpack-cli` - latest (6.0.1 as of January 2026)
- `mini-css-extract-plugin` - latest (2.10.0 as of January 2026)
- `css-loader` - latest (7.1.2 as of January 2026)

Total size: ~100MB for both node_modules combined

## Troubleshooting

### Permission denied when running scripts

```bash
chmod +x run-both.sh
chmod +x rspack-test/reproduce.sh
chmod +x webpack-test/reproduce.sh
```

### npm install fails

Try clearing cache:
```bash
npm cache clean --force
cd rspack-test && npm install
cd ../webpack-test && npm install
```

### Script doesn't run on Windows

Use WSL (Windows Subsystem for Linux) or Git Bash:
```bash
bash ./run-both.sh
```

## Clean Up

### Remove build artifacts
```bash
rm -rf rspack-test/{dist,build1,build2}
rm -rf webpack-test/{dist,build1,build2}
```

### Remove dependencies
```bash
rm -rf rspack-test/node_modules
rm -rf webpack-test/node_modules
```

### Complete clean
```bash
git clean -fdx  # If using git
# Or manually delete node_modules, dist, build* folders
```

## Directory Structure After Install

```
rspack-fullhash-bug-reproduction/
├── Documentation
│   ├── README.md          # Start here
│   ├── INSTALL.md         # This file
│   ├── SUMMARY.md         # Overview
│   ├── BUG_REPORT.md      # Technical details
│   └── COMPARISON.md      # Webpack vs Rspack
│
├── Tests
│   ├── run-both.sh        # Run everything
│   ├── rspack-test/
│   │   ├── node_modules/  # After npm install
│   │   └── ...
│   └── webpack-test/
│       ├── node_modules/  # After npm install
│       └── ...
│
└── Meta
    ├── LICENSE
    └── .gitignore
```

## What Happens When You Run

1. **Dependency Check** - Installs if needed
2. **Webpack Build 1** - Initial CSS (red/blue)
3. **Webpack Build 2** - Modified CSS (green/yellow)
4. **Rspack Build 1** - Initial CSS (red/blue)
5. **Rspack Build 2** - Modified CSS (green/yellow)
6. **Comparison** - Side-by-side hash analysis
7. **Result** - Shows webpack ✅ vs rspack ❌

## Time Required

- First run (with install): ~2-3 minutes
- Subsequent runs: ~10-20 seconds

## Disk Space

- Source files: ~50KB
- With dependencies: ~100MB
- With build artifacts: ~101MB

## Next Steps After Testing

1. Review `BUG_REPORT.md` for technical details
2. Review `COMPARISON.md` for analysis
3. Share results with Rspack team
4. Reference in bug reports/discussions

## Getting Help

If you encounter issues:
1. Check Node.js version: `node --version` (should be 20+)
2. Check npm version: `npm --version` (should be 10+)
3. Try manual installation (see above)
4. Check console output for specific errors

## Success Indicators

You'll know it worked when:
- ✅ Both tests complete without errors
- ✅ Webpack fullhash changes between builds
- ✅ Rspack fullhash stays same between builds
- ✅ Side-by-side comparison shows "BUG CONFIRMED"

## Sharing Results

To share your test results:
```bash
./run-both.sh > test-results.txt 2>&1
# Share test-results.txt
```

Or create a GitHub issue with:
- Output from `./run-both.sh`
- Node version (`node --version`)
- OS (`uname -a` on Unix, `ver` on Windows)
