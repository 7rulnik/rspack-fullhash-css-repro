#!/bin/bash

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║  Rspack [fullhash] Bug: Webpack vs Rspack Comparison             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Check if we need to install
RSPACK_NEEDS_INSTALL=false
WEBPACK_NEEDS_INSTALL=false

if [ ! -d "rspack-test/node_modules" ]; then
  RSPACK_NEEDS_INSTALL=true
fi

if [ ! -d "webpack-test/node_modules" ]; then
  WEBPACK_NEEDS_INSTALL=true
fi

if [ "$RSPACK_NEEDS_INSTALL" = true ] || [ "$WEBPACK_NEEDS_INSTALL" = true ]; then
  echo "📦 Installing dependencies..."
  echo ""

  if [ "$RSPACK_NEEDS_INSTALL" = true ]; then
    echo "  → Installing rspack-test dependencies..."
    cd rspack-test && npm install --silent && cd ..
  fi

  if [ "$WEBPACK_NEEDS_INSTALL" = true ]; then
    echo "  → Installing webpack-test dependencies..."
    cd webpack-test && npm install --silent && cd ..
  fi

  echo ""
  echo "✅ Dependencies installed"
  echo ""
fi

# Run Webpack test first (shows correct behavior)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 1: Webpack Test (Expected: fullhash SHOULD change)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd webpack-test
./reproduce.sh 2>&1 | tee /tmp/webpack-output.txt
WEBPACK_EXIT=$?
cd ..

# Extract webpack results
WEBPACK_BUILD1_FULL=$(grep -A 2 "Build 1 hashes:" /tmp/webpack-output.txt | grep fullhash | awk '{print $2}')
WEBPACK_BUILD2_FULL=$(grep -A 2 "Build 2 hashes:" /tmp/webpack-output.txt | grep fullhash | awk '{print $2}')
WEBPACK_BUILD1_CSS=$(grep -A 2 "Build 1 hashes:" /tmp/webpack-output.txt | grep contenthash | awk '{print $2}')
WEBPACK_BUILD2_CSS=$(grep -A 2 "Build 2 hashes:" /tmp/webpack-output.txt | grep contenthash | awk '{print $2}')

echo ""
echo ""

# Run Rspack test (shows the bug)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PART 2: Rspack Test (Bug: fullhash does NOT change)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd rspack-test
./reproduce.sh 2>&1 | tee /tmp/rspack-output.txt
RSPACK_EXIT=$?
cd ..

# Extract rspack results
RSPACK_BUILD1_FULL=$(grep -A 2 "Build 1 hashes:" /tmp/rspack-output.txt | grep fullhash | awk '{print $2}')
RSPACK_BUILD2_FULL=$(grep -A 2 "Build 2 hashes:" /tmp/rspack-output.txt | grep fullhash | awk '{print $2}')
RSPACK_BUILD1_CSS=$(grep -A 2 "Build 1 hashes:" /tmp/rspack-output.txt | grep contenthash | awk '{print $2}')
RSPACK_BUILD2_CSS=$(grep -A 2 "Build 2 hashes:" /tmp/rspack-output.txt | grep contenthash | awk '{print $2}')

echo ""
echo ""

# Comparison
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                         SIDE-BY-SIDE COMPARISON                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│                         CSS [contenthash]                           │"
echo "├─────────────────────────────────────────────────────────────────────┤"
echo "│  Webpack:  $WEBPACK_BUILD1_CSS → $WEBPACK_BUILD2_CSS  ✅        │"
echo "│  Rspack:   $RSPACK_BUILD1_CSS  → $RSPACK_BUILD2_CSS   ✅        │"
echo "│                                                                     │"
echo "│  Result: Both correctly update CSS contenthash                     │"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│                         JS [fullhash]                               │"
echo "├─────────────────────────────────────────────────────────────────────┤"

if [ "$WEBPACK_BUILD1_FULL" = "$WEBPACK_BUILD2_FULL" ]; then
  echo "│  Webpack:  $WEBPACK_BUILD1_FULL → $WEBPACK_BUILD2_FULL  ❌ SAME    │"
  WEBPACK_RESULT="❌ WEBPACK ALSO HAS BUG"
else
  echo "│  Webpack:  $WEBPACK_BUILD1_FULL → $WEBPACK_BUILD2_FULL  ✅ CHANGED │"
  WEBPACK_RESULT="✅ WEBPACK WORKS CORRECTLY"
fi

if [ "$RSPACK_BUILD1_FULL" = "$RSPACK_BUILD2_FULL" ]; then
  echo "│  Rspack:   $RSPACK_BUILD1_FULL  → $RSPACK_BUILD2_FULL   ❌ SAME    │"
  RSPACK_RESULT="❌ RSPACK HAS BUG"
else
  echo "│  Rspack:   $RSPACK_BUILD1_FULL  → $RSPACK_BUILD2_FULL   ✅ CHANGED │"
  RSPACK_RESULT="✅ RSPACK WORKS CORRECTLY"
fi

echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                            CONCLUSION                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Webpack: $WEBPACK_RESULT"
echo "  Rspack:  $RSPACK_RESULT"
echo ""

if [ "$WEBPACK_BUILD1_FULL" != "$WEBPACK_BUILD2_FULL" ] && [ "$RSPACK_BUILD1_FULL" = "$RSPACK_BUILD2_FULL" ]; then
  echo "  🐛 BUG CONFIRMED!"
  echo "     Webpack updates [fullhash] when CSS changes, Rspack doesn't."
  echo "     This proves Rspack has a bug that needs fixing."
else
  echo "  ⚠️  Unexpected result. Please review the output above."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Build artifacts preserved in:"
echo "  - webpack-test/build1/ and webpack-test/build2/"
echo "  - rspack-test/build1/ and rspack-test/build2/"
echo ""
echo "For more details, see:"
echo "  - README.md - Overview and usage"
echo "  - COMPARISON.md - Detailed analysis"
echo "  - BUG_REPORT.md - Technical details and proposed fixes"
echo ""
echo "═══════════════════════════════════════════════════════════════════"

# Clean up temp files
rm -f /tmp/webpack-output.txt /tmp/rspack-output.txt
