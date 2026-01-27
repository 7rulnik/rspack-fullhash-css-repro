# Version Information

## Package Versions Used

This reproduction uses `"latest"` tags in `package.json` to ensure it always tests against the most recent stable releases.

### Current Versions (as of January 2026)

**Rspack Test:**
- `@rspack/core`: 1.7.3
- `@rspack/cli`: 1.7.3
- `css-loader`: 7.1.2

**Webpack Test:**
- `webpack`: 5.104.1
- `webpack-cli`: 6.0.1
- `mini-css-extract-plugin`: 2.10.0
- `css-loader`: 7.1.2

## Why "latest" Tags?

Using `"latest"` ensures:
1. ✅ Always tests against current releases
2. ✅ No need to update version numbers
3. ✅ Proves bug exists in latest stable versions
4. ✅ Makes reproduction future-proof

## Checking Installed Versions

After installing, you can check what versions were installed:

```bash
# Rspack test
cd rspack-test
npm list @rspack/core @rspack/cli css-loader --depth=0

# Webpack test
cd webpack-test
npm list webpack webpack-cli mini-css-extract-plugin css-loader --depth=0
```

## Version History

| Date | Rspack | Webpack | Bug Status |
|------|--------|---------|------------|
| 2026-01 | 1.7.3 | 5.104.1 | ❌ Bug confirmed |
| 2026-01 | 1.1.7 | 5.104.1 | ❌ Bug confirmed |

The bug has been present in all tested versions of Rspack.

## Pinning Versions

If you need to pin to specific versions for reproducibility, edit the `package.json` files:

```json
{
  "devDependencies": {
    "@rspack/cli": "1.7.3",
    "@rspack/core": "1.7.3",
    "css-loader": "7.1.2"
  }
}
```

## Future Testing

When new versions are released:
1. Delete `node_modules/` and `package-lock.json`
2. Run `npm install` to get latest versions
3. Run `./reproduce.sh` to verify bug status
4. Update this file with new version info
