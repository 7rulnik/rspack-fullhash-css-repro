const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const NondeterministicCssMinimizer = require("./nondeterministic-css-minimizer");

/** @type {import('webpack').Configuration} */
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
        use: [MiniCssExtractPlugin.loader, "css-loader"],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: "[name].[contenthash].css",
    }),
    new NondeterministicCssMinimizer(),
  ],
  optimization: {
    realContentHash: true,
  },
};
