# Bug Report: Compilation Hash ([fullhash]) Does Not Update for CSS-Only Changes

## Summary

The compilation hash (`[fullhash]`) remains unchanged when CSS assets are modified during the `process_assets` phase, causing cache invalidation failures for any files using `[fullhash]` in their filenames.

## Environment

- **Rspack Version**: 2.0.0-alpha.0
- **Plugins**: `CssExtractRspackPlugin` + `RealContentHashPlugin`
- **Affected**: Any configuration using `[fullhash]` placeholder with CSS extraction

## Description

When CSS content changes due to minification or optimization (e.g., CSS minifier converting 4 individual `border-*-radius` properties into a single `border-radius` shorthand), the following occurs:

✅ **What works correctly:**
- CSS `[contenthash]` updates: `5449af185c83c419` → `3654b2575534afba`
- Runtime chunk `[contenthash]` updates: `f31eb5ba0b7a8905` → `c30602758bc0aeaf`
- JavaScript `[contenthash]` remains stable when JS unchanged

❌ **What fails:**
- Compilation `[fullhash]` does NOT update
- Any files using `[fullhash]` retain stale hashes
- Leads to cache invalidation failures and non-deterministic builds

## Reproduction

**Automated reproduction available:**
- **Rspack test**: `fullhash-bug-reproduction/` - Run `./reproduce-bug.sh` to see the bug
- **Webpack comparison**: `fullhash-bug-reproduction-webpack/` - Run `./reproduce-webpack.sh` to see correct behavior

**Comparison document**: `WEBPACK_VS_RSPACK_COMPARISON.md` - Side-by-side analysis proving this is a bug

## Steps to Reproduce

### Minimal Reproduction

1. **Create a project with:**
   ```javascript
   // rspack.config.js
   module.exports = {
     output: {
       filename: '[name].[fullhash].js',
       cssFilename: '[name].[contenthash].css',
     },
     plugins: [
       new CssExtractRspackPlugin(),
     ],
     optimization: {
       realContentHash: true,
     },
   };
   ```

2. **Add CSS with optimizable properties:**
   ```scss
   // styles.module.scss
   .component {
     border-top-left-radius: 16px;
     border-top-right-radius: 16px;
     border-bottom-left-radius: 16px;
     border-bottom-right-radius: 16px;
   }
   ```

3. **Build twice:**
   - First build: CSS minifier may or may not optimize
   - Second build: CSS minifier optimizes to `border-radius: 16px;`

4. **Observe outputs:**
   ```
   Build 1:
   - styles.5449af185c83c419.css (4 individual properties)
   - main.e098e78d675ace54.js (using fullhash)
   - runtime.f31eb5ba0b7a8905.js

   Build 2:
   - styles.3654b2575534afba.css (1 shorthand property) ✓ Changed
   - main.e098e78d675ace54.js (SAME fullhash)         ✗ Should change
   - runtime.c30602758bc0aeaf.js                      ✓ Changed
   ```

### Real-World Scenarios

This bug manifests in several production scenarios:

**Scenario 1: Non-deterministic CSS minification**
- CSS minifier optimizations vary between builds
- Content hashes update but fullhash stays the same
- CDN/browser caches serve wrong asset versions

**Scenario 2: Module Federation**
- Remote entries use `[fullhash]` for cache busting
- CSS changes don't update remote entry filenames
- Host apps cache stale remote entries, causing chunk mismatches

**Scenario 3: Build reproducibility**
- Identical source code produces different CSS output
- Different assets share the same fullhash
- CI/CD systems can't detect actual changes

## Expected Behavior

When **any** asset content changes (including CSS), the compilation `[fullhash]` should update to reflect that the build output has changed. This ensures:
- Unique hashes for unique builds (deterministic builds produce identical hashes)
- Proper cache invalidation for CDN and browser caches
- Build tools can reliably detect changes
- Module Federation and other federated architectures stay synchronized

## Actual Behavior

The compilation `[fullhash]` only updates when JavaScript chunk contents change. CSS-only changes (even though they update `[contenthash]`) do not influence the `[fullhash]`.

## Root Cause Analysis

### Timeline of Hash Calculation

The bug is an architectural timing issue in the compilation passes:

```
┌─────────────────────────────────────────────────────────┐
│ Pass 16: create_hash_pass                               │
│ ├─ CssExtractRspackPlugin.content_hash hook             │
│ │  └─ Computes CSS hash from SOURCE modules             │
│ ├─ Compute all chunk content hashes                     │
│ ├─ Compute chunk hashes from content hashes             │
│ └─ Compute COMPILATION HASH from chunk hashes           │
│    ❄️  FROZEN - Will not change after this point        │
├─────────────────────────────────────────────────────────┤
│ Pass 18: create_chunk_assets_pass                       │
│ └─ CssExtractRspackPlugin.render_manifest hook          │
│    └─ Emit CSS assets with initial content              │
├─────────────────────────────────────────────────────────┤
│ Pass 19: process_assets_pass                            │
│ └─ RealContentHashPlugin (OPTIMIZE_HASH stage)          │
│    ├─ Minifies/optimizes CSS content                    │
│    ├─ Computes new contenthash from ACTUAL content      │
│    ├─ Updates asset.info.content_hash                   │
│    ├─ Renames assets to use new contenthash             │
│    └─ ❌ Does NOT recalculate compilation.hash          │
└─────────────────────────────────────────────────────────┘
```

### Code References

1. **Compilation hash calculation:**
   - **File:** `crates/rspack_core/src/compilation/create_hash/mod.rs`
   - **Lines:** 310-320
   ```rust
   // create full hash
   self
     .chunk_by_ukey
     .values()
     .sorted_unstable_by_key(|chunk| chunk.ukey())
     .filter_map(|chunk| chunk.hash(&self.chunk_hashes_artifact))
     .for_each(|hash| {
       hash.hash(&mut compilation_hasher);
     });
   self.hot_index.hash(&mut compilation_hasher);
   self.hash = Some(compilation_hasher.digest(&self.options.output.hash_digest));
   ```
   - **Issue:** Hash is computed from chunk hashes only, which are based on module contents BEFORE asset processing

2. **CSS content hash hook:**
   - **File:** `crates/rspack_plugin_extract_css/src/plugin.rs`
   - **Lines:** 583-623 (content_hash hook)
   - Runs during `create_hash_pass`, hashes CSS module source code

3. **CSS asset rendering:**
   - **File:** `crates/rspack_plugin_extract_css/src/plugin.rs`
   - **Lines:** 625-697 (render_manifest hook)
   - Runs during `create_chunk_assets_pass`, emits CSS files

4. **RealContentHashPlugin:**
   - **File:** `crates/rspack_plugin_real_content_hash/src/lib.rs`
   - **Lines:** 81-292
   - **Stage:** `PROCESS_ASSETS_STAGE_OPTIMIZE_HASH` (2500)
   - Updates asset content hashes based on final rendered content
   - Does NOT trigger compilation.hash recalculation

5. **Pass execution order:**
   - **File:** `crates/rspack_core/src/compilation/run_passes.rs`
   - **Lines:** 72-76
   ```rust
   create_hash_pass().await?;           // Line 72 - Calculates fullhash
   create_module_assets_pass().await?;  // Line 73
   create_chunk_assets_pass().await?;   // Line 74 - Emits CSS
   process_assets_pass().await?;        // Line 75 - Optimizes/minifies
   after_seal_pass().await?;            // Line 76
   ```

### Why This Happens

The compilation fullhash is "frozen" before `RealContentHashPlugin` runs. When CSS gets minified/optimized during `process_assets_pass`:

1. CSS content changes (e.g., 4 properties → 1 shorthand, saves ~374 bytes)
2. `RealContentHashPlugin` computes new contenthash from actual content
3. Assets are renamed with new contenthash
4. **BUT** `compilation.hash` was already computed and stored
5. No mechanism exists to recalculate it based on final asset contents

## Impact

### Severity: **High**

**Affected Use Cases:**
1. **Any output using `[fullhash]`:** Files with stale hashes cause cache invalidation failures
2. **CDN Caching:** Different asset contents share same fullhash, breaking cache strategies
3. **Build Determinism:** Identical source code produces different assets with same fullhash
4. **Version Tracking:** Cannot rely on fullhash for build identification
5. **Module Federation:** Remote entries with stale `[fullhash]` cause runtime errors

**Production Symptoms:**
- Stale assets being served to users due to cache invalidation failures
- Non-deterministic builds (same source → different output, same hash)
- CI/CD systems unable to detect actual changes
- Module Federation: chunk mismatches and runtime errors
- Browser/CDN caches serving mismatched file versions

## Proposed Solutions

### Option 1: Post-Process Hash Recalculation (Recommended)

After `RealContentHashPlugin` updates asset hashes, recalculate compilation hash:

**Location:** `crates/rspack_plugin_real_content_hash/src/lib.rs`

```rust
// After updating all assets (line ~287)
if hash_to_new_hash.len() > 0 {
  // Assets changed, need to recalculate compilation hash
  let mut hasher = RspackHash::from(&compilation.options.output);

  // Hash all final assets
  for (name, asset) in compilation.assets() {
    asset.get_source().hash(&mut hasher);
  }

  // Update compilation hash
  compilation.hash = Some(hasher.digest(&compilation.options.output.hash_digest));

  // Re-render any assets that use [fullhash] placeholder
  // This includes Module Federation remote entries, any output files, etc.
}
```

**Pros:**
- Minimal invasiveness
- Accounts for all asset-level changes
- Preserves existing architecture

**Cons:**
- Adds complexity to RealContentHashPlugin
- May require re-rendering some assets that depend on fullhash

### Option 2: Include Asset Contents in Initial Hash

Modify `create_hash_pass` to include rendered asset contents:

**Location:** `crates/rspack_core/src/compilation/create_hash/mod.rs`

**Pros:**
- Single source of truth
- No need for recalculation

**Cons:**
- Requires rendering assets earlier in the pipeline
- May conflict with optimization plugins

### Option 3: Two-Phase Hashing

1. Compute preliminary hash in `create_hash_pass`
2. Mark as "tentative"
3. Finalize hash after `process_assets_pass` completes

**Pros:**
- Clear separation of concerns
- Allows plugins to stabilize before final hash

**Cons:**
- Requires significant architectural changes
- May impact performance

### Option 4: Separate Fullhash Concept

Introduce distinction between:
- `[compilationhash]` - from source modules (current behavior)
- `[fullhash]` - from final emitted assets (new behavior)

**Pros:**
- Backward compatible (can keep both)
- Gives users control over behavior

**Cons:**
- Adds complexity to user configuration
- Doesn't fix the semantic issue

## Recommendation

**Option 1** is recommended as it:
- Fixes the immediate bug
- Has minimal architectural impact
- Aligns with user expectations (fullhash should reflect full build output)
- Matches webpack's behavior

## Additional Context

### Webpack Comparison

**Webpack 5.104.1 correctly updates `[fullhash]` when CSS changes**, proving this is a Rspack-specific bug:

```
Webpack:
  Build 1: [fullhash] = 2744b4031b9654aa8cff
  Build 2: [fullhash] = 0c563ca2858722d902ca  ✅ Changed

Rspack:
  Build 1: [fullhash] = 15d7bc99b1b65226
  Build 2: [fullhash] = 15d7bc99b1b65226  ❌ Same (bug!)
```

In both cases, CSS changed but JS content remained identical. Webpack updated the fullhash, Rspack did not.

See `WEBPACK_VS_RSPACK_COMPARISON.md` for detailed side-by-side analysis.

### Webpack Implementation

Webpack's behavior shows that `[fullhash]` is computed from all emitted assets, not just chunk hashes. See webpack's `Compilation.createHash()` implementation.

### Test Coverage

**Existing tests:**
- `tests/rspack-test/hashCases/real-content-hash-fullhash/` - validates realContentHash with fullhash
- This test validates basic realContentHash behavior but doesn't cover CSS-only changes

**New test case for this bug:**
- `tests/rspack-test/hashCases/fullhash-css-only-change/` - demonstrates the setup for CSS+fullhash
- Note: hashCases run single compilations, so this test shows the structure but doesn't verify the bug itself (which requires comparing two builds with different CSS)

### Workarounds

Until fixed, users can:
1. Inject a build timestamp/ID into assets to force unique filenames
2. Use `[contenthash]` for all outputs (loses compilation-wide versioning)
3. Disable CSS minification (not practical for production)

## Related Files

- `crates/rspack_core/src/compilation/create_hash/mod.rs` (hash calculation)
- `crates/rspack_plugin_extract_css/src/plugin.rs` (CSS extraction)
- `crates/rspack_plugin_real_content_hash/src/lib.rs` (content hash optimization)
- `crates/rspack_core/src/compilation/run_passes.rs` (pass execution order)
- `crates/rspack_plugin_runtime/src/runtime_module/get_full_hash.rs` (fullhash runtime)

---

**Credit:** Bug discovered and analyzed through production Jenkins builds showing non-deterministic CSS minification causing cache invalidation failures. The issue affects any usage of `[fullhash]` with CSS extraction, including Module Federation, CDN caching, and build versioning scenarios.
