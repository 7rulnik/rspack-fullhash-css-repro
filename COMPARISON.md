# Webpack vs Rspack: [fullhash] Behavior Comparison

## Summary

**Webpack**: ✅ Correctly updates `[fullhash]` when CSS-only changes occur
**Rspack**: ❌ Does NOT update `[fullhash]` when CSS-only changes occur

This proves that Rspack has a bug and should match webpack's behavior.

## Test Setup

Identical configurations for both:
- Entry: `index.js` importing CSS
- CSS extraction plugin
- `realContentHash: true`
- Output: `[name].[fullhash].js` and `[name].[contenthash].css`

**Test procedure:**
1. Build with CSS: `color: red; background: blue;`
2. Modify CSS to: `color: green; background: yellow; font-size: 16px;`
3. Build again (JS unchanged)
4. Compare hashes

## Results

### Webpack 5.104.1 ✅

```
BUILD 1:
  [fullhash]:    2744b4031b9654aa8cff
  [contenthash]: ae891b0bda76b6bc11e1
  JS content:    (()=>{"use strict";console.log("App...")})();

BUILD 2 (CSS changed, JS unchanged):
  [fullhash]:    0c563ca2858722d902ca  ✅ CHANGED
  [contenthash]: 3e8477e598f9aa23b9e4  ✅ CHANGED
  JS content:    (()=>{"use strict";console.log("App...")})();

✅ WEBPACK WORKS CORRECTLY!
   - CSS contenthash changed (expected)
   - JS fullhash changed even though JS content is identical
   - Different builds have different fullhashes
```

### Rspack 2.0.0-alpha.0 ❌

```
BUILD 1:
  [fullhash]:    15d7bc99b1b65226
  [contenthash]: 6fdaa5b099f97dd7
  JS content:    (()=>{...})()

BUILD 2 (CSS changed, JS unchanged):
  [fullhash]:    15d7bc99b1b65226  ❌ SAME (BUG!)
  [contenthash]: 47fc5c9ca2bb0b36  ✅ CHANGED
  JS content:    (()=>{...})()

❌ RSPACK HAS A BUG!
   - CSS contenthash changed (expected)
   - JS fullhash did NOT change (bug!)
   - Different builds have the SAME fullhash
```

## Key Findings

### 1. Webpack Updates Fullhash Correctly

When CSS changes:
- Webpack updates both `[contenthash]` (for CSS) and `[fullhash]` (for compilation)
- Even though JS content is identical, the fullhash changes
- This ensures unique hashes for unique builds

### 2. Rspack Only Updates Contenthash

When CSS changes:
- Rspack updates `[contenthash]` (for CSS) correctly
- But does NOT update `[fullhash]` (for compilation)
- This causes different builds to share the same fullhash

### 3. JS Content is Identical in Both Cases

For both webpack and rspack:
- JS content is byte-for-byte identical between builds
- The JS code doesn't reference the CSS hash directly
- Yet webpack still updates fullhash, rspack doesn't

## Why This Matters

### Webpack's Behavior is Correct

Webpack's `[fullhash]` represents the **entire compilation**, including:
- All JavaScript chunks
- All CSS assets
- All extracted assets

When **any** part of the build output changes, the fullhash should change.

### Rspack's Behavior is Incorrect

Rspack's `[fullhash]` only reflects:
- JavaScript chunk contents
- ❌ NOT CSS asset contents

This breaks the semantic meaning of "full" hash.

## Impact on Users

### With Webpack (Correct Behavior)

```
Build 1: app.abc123.js + styles.xyz789.css
Build 2: app.def456.js + styles.111222.css

✅ Different builds → Different fullhashes
✅ Cache invalidation works
✅ Module Federation works
✅ CDN versioning works
```

### With Rspack (Bug)

```
Build 1: app.abc123.js + styles.xyz789.css
Build 2: app.abc123.js + styles.111222.css  ❌ Same fullhash!

❌ Different builds → Same fullhash
❌ Cache invalidation fails
❌ Module Federation breaks
❌ CDN serves wrong versions
```

## Reproduction

### Webpack Test
```bash
cd fullhash-bug-reproduction-webpack
npm install
./reproduce-webpack.sh
```

### Rspack Test
```bash
cd fullhash-bug-reproduction
pnpm install
./reproduce-bug.sh
```

## Conclusion

This comparison **definitively proves** that:

1. ✅ Webpack correctly updates `[fullhash]` when CSS changes
2. ❌ Rspack incorrectly keeps `[fullhash]` unchanged when CSS changes
3. 🐛 This is a **bug in Rspack**, not expected behavior
4. 🎯 Rspack should be fixed to match webpack's behavior

The fix should ensure that `[fullhash]` accounts for **all** compilation outputs, including CSS assets processed by `RealContentHashPlugin`.

---

**Test Date**: January 23, 2026
**Webpack Version**: 5.104.1
**Rspack Version**: 2.0.0-alpha.0
