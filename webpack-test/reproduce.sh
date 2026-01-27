#!/bin/bash

set -e

echo "==================================================================="
echo "Webpack [fullhash] Behavior Test"
echo "==================================================================="
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "⚠️  node_modules not found. Please run 'npm install' first."
  exit 1
fi

# Clean up
echo "🧹 Cleaning up previous builds..."
rm -rf dist build1 build2

# Build 1
echo ""
echo "==================================================================="
echo "BUILD 1: Initial build"
echo "==================================================================="
npm run build
echo ""
echo "📦 Build 1 outputs:"
ls -lh dist/
mkdir build1
cp -r dist/* build1/

# Extract hashes from Build 1
BUILD1_FULLHASH=$(ls build1/*.js | sed -n 's/.*main\.\([a-f0-9]*\)\.js/\1/p')
BUILD1_CSSHASH=$(ls build1/*.css | sed -n 's/.*main\.\([a-f0-9]*\)\.css/\1/p')

echo ""
echo "Build 1 hashes:"
echo "  [fullhash]:    $BUILD1_FULLHASH"
echo "  [contenthash]: $BUILD1_CSSHASH"

# Modify CSS
echo ""
echo "==================================================================="
echo "🔧 Modifying CSS content (JS unchanged)..."
echo "==================================================================="
cat > src/styles.css << 'EOF'
/* Build version 2 - CSS content changed! */
.test {
  color: green;
  background: yellow;
  font-size: 16px;
}
EOF
echo "✓ CSS modified"

# Build 2
echo ""
echo "==================================================================="
echo "BUILD 2: After CSS change (JS unchanged)"
echo "==================================================================="
rm -rf dist
npm run build
echo ""
echo "📦 Build 2 outputs:"
ls -lh dist/
mkdir build2
cp -r dist/* build2/

# Extract hashes from Build 2
BUILD2_FULLHASH=$(ls build2/*.js | sed -n 's/.*main\.\([a-f0-9]*\)\.js/\1/p')
BUILD2_CSSHASH=$(ls build2/*.css | sed -n 's/.*main\.\([a-f0-9]*\)\.css/\1/p')

echo ""
echo "Build 2 hashes:"
echo "  [fullhash]:    $BUILD2_FULLHASH"
echo "  [contenthash]: $BUILD2_CSSHASH"

# Compare
echo ""
echo "==================================================================="
echo "📊 WEBPACK RESULTS"
echo "==================================================================="
echo ""

echo "CSS [contenthash]:"
if [ "$BUILD1_CSSHASH" = "$BUILD2_CSSHASH" ]; then
  echo "  ✅ SAME:    $BUILD1_CSSHASH"
else
  echo "  ✅ CHANGED: $BUILD1_CSSHASH → $BUILD2_CSSHASH"
  echo "     (Expected: should change because CSS content changed)"
fi

echo ""
echo "JS [fullhash]:"
if [ "$BUILD1_FULLHASH" = "$BUILD2_FULLHASH" ]; then
  echo "  ❌ SAME:    $BUILD1_FULLHASH"
  echo "     (Unexpected: webpack should update fullhash)"
  echo ""
  echo "⚠️  WEBPACK ALSO HAS THE BUG!"
else
  echo "  ✅ CHANGED: $BUILD1_FULLHASH → $BUILD2_FULLHASH"
  echo "     (Expected: fullhash should change when any output changes)"
  echo ""
  echo "✅ WEBPACK WORKS CORRECTLY!"
  echo "   CSS content changed, and [fullhash] updated accordingly."
fi

echo ""
echo "==================================================================="

# Restore original CSS
cat > src/styles.css << 'EOF'
/* Build version 1 - This CSS will change between builds */
.test {
  color: red;
  background: blue;
}
EOF
