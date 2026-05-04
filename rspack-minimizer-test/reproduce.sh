#!/bin/bash

set -e

echo "==================================================================="
echo "Rspack non-deterministic CSS minimizer reproduction"
echo "==================================================================="
echo ""
echo "Two builds with IDENTICAL source code. The synthetic minimizer"
echo "(see nondeterministic-css-minimizer.js) emits different bytes each"
echo "run — same as a real-world lightningcss invocation with unstable"
echo "unusedSymbols ordering."
echo ""

if [ ! -d "node_modules" ]; then
  echo "node_modules not found. Run 'npm install' first." >&2
  exit 1
fi

echo "Cleaning previous builds..."
rm -rf dist build1 build2

echo ""
echo "==================================================================="
echo "BUILD 1"
echo "==================================================================="
npm run build
mkdir build1
cp -r dist/* build1/

BUILD1_FULLHASH=$(ls build1/*.js | sed -n 's/.*main\.\([a-f0-9]*\)\.js/\1/p')
BUILD1_CSSHASH=$(ls build1/*.css | sed -n 's/.*main\.\([a-f0-9]*\)\.css/\1/p')
BUILD1_CSSBYTES=$(shasum -a 256 build1/*.css | awk '{print $1}')

echo ""
echo "Build 1:"
echo "  JS  [fullhash]:    $BUILD1_FULLHASH"
echo "  CSS [contenthash]: $BUILD1_CSSHASH"
echo "  CSS bytes (sha256): $BUILD1_CSSBYTES"

echo ""
echo "==================================================================="
echo "BUILD 2 — no source changes; minimizer alone produces different bytes"
echo "==================================================================="
rm -rf dist
npm run build
mkdir build2
cp -r dist/* build2/

BUILD2_FULLHASH=$(ls build2/*.js | sed -n 's/.*main\.\([a-f0-9]*\)\.js/\1/p')
BUILD2_CSSHASH=$(ls build2/*.css | sed -n 's/.*main\.\([a-f0-9]*\)\.css/\1/p')
BUILD2_CSSBYTES=$(shasum -a 256 build2/*.css | awk '{print $1}')

echo ""
echo "Build 2:"
echo "  JS  [fullhash]:    $BUILD2_FULLHASH"
echo "  CSS [contenthash]: $BUILD2_CSSHASH"
echo "  CSS bytes (sha256): $BUILD2_CSSBYTES"

echo ""
echo "==================================================================="
echo "RESULTS"
echo "==================================================================="
echo ""

echo "CSS bytes:"
if [ "$BUILD1_CSSBYTES" = "$BUILD2_CSSBYTES" ]; then
  echo "  IDENTICAL — repro condition not met (minimizer ran deterministically)"
  exit 1
else
  echo "  DIFFER (synthetic minimizer is intentionally non-deterministic)"
fi

echo ""
echo "CSS [contenthash]:"
if [ "$BUILD1_CSSHASH" = "$BUILD2_CSSHASH" ]; then
  echo "  SAME — realContentHash did not pick up the byte change"
else
  echo "  CHANGED ($BUILD1_CSSHASH -> $BUILD2_CSSHASH)"
  echo "  Asset filename tracks post-minimizer bytes via realContentHash."
fi

echo ""
echo "JS [fullhash]:"
if [ "$BUILD1_FULLHASH" = "$BUILD2_FULLHASH" ]; then
  echo "  SAME ($BUILD1_FULLHASH)"
  echo "  Different on-disk bytes carry the same compilation fullhash."
  echo "  This is the symptom we observe in production: a non-deterministic"
  echo "  minimizer ships divergent bytes under a stable [fullhash]."
else
  echo "  CHANGED ($BUILD1_FULLHASH -> $BUILD2_FULLHASH)"
fi

echo ""
echo "==================================================================="
