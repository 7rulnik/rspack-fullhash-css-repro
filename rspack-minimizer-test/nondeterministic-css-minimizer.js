const { Compilation, sources } = require("@rspack/core");

// Stand-in for a real-world non-deterministic CSS minimizer (e.g. lightningcss
// invoked with an unstable `unusedSymbols` ordering). Same input → different
// bytes on every run, so we can observe how Rspack's hashing reacts.
class NondeterministicCssMinimizer {
  apply(compiler) {
    compiler.hooks.compilation.tap(
      "NondeterministicCssMinimizer",
      (compilation) => {
        compilation.hooks.processAssets.tap(
          {
            name: "NondeterministicCssMinimizer",
            stage: Compilation.PROCESS_ASSETS_STAGE_OPTIMIZE_SIZE,
          },
          (assets) => {
            for (const name of Object.keys(assets)) {
              if (!name.endsWith(".css")) continue;
              const original = assets[name].source().toString();
              const stamped = `${original}/* nonce: ${Math.random()} */\n`;
              compilation.updateAsset(name, new sources.RawSource(stamped));
            }
          },
        );
      },
    );
  }
}

module.exports = NondeterministicCssMinimizer;
