const rspack = require("@rspack/core");
const NondeterministicCssMinimizer = require("./nondeterministic-css-minimizer");

/** @type {import("@rspack/core").Configuration} */
module.exports = {
  mode: "production",
  entry: "./src/index.js",
  output: {
    path: __dirname + "/dist",
    filename: "[name].[fullhash].js",
    clean: true,
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [rspack.CssExtractRspackPlugin.loader, "css-loader"],
        type: "javascript/auto",
      },
    ],
  },
  plugins: [
    new rspack.CssExtractRspackPlugin({
      filename: "[name].[contenthash].css",
    }),
    new NondeterministicCssMinimizer(),
  ],
  optimization: {
    realContentHash: true,
  },
};
