const webpack = require("webpack");

// Mirror of rspack-minimizer-test/nondeterministic-css-minimizer.js. Same input
// produces different output bytes on every run, so we can compare how Webpack's
// hashing reacts vs. Rspack's.
class NondeterministicCssMinimizer {
  apply(compiler) {
    compiler.hooks.compilation.tap(
      "NondeterministicCssMinimizer",
      (compilation) => {
        compilation.hooks.processAssets.tap(
          {
            name: "NondeterministicCssMinimizer",
            stage: webpack.Compilation.PROCESS_ASSETS_STAGE_OPTIMIZE_SIZE,
          },
          (assets) => {
            for (const name of Object.keys(assets)) {
              if (!name.endsWith(".css")) continue;
              const original = assets[name].source().toString();
              const stamped = `${original}/* nonce: ${Math.random()} */\n`;
              compilation.updateAsset(
                name,
                new webpack.sources.RawSource(stamped),
              );
            }
          },
        );
      },
    );
  }
}

module.exports = NondeterministicCssMinimizer;
