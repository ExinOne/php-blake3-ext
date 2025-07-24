#!/bin/bash

# BLAKE3 Sources Verification Script
# This script compares local BLAKE3 C sources with the official repository

set -e

# Configuration
OFFICIAL_REPO="https://github.com/BLAKE3-team/BLAKE3.git"
OFFICIAL_COMMIT="df610ddc3b93841ffc59a87e3da659a15910eb46"
LOCAL_BLAKE3_DIR="src/blake3"

echo "=== BLAKE3 Sources Verification ==="
echo "Official repo: $OFFICIAL_REPO"
echo "Official commit: $OFFICIAL_COMMIT"
echo "Local sources: $LOCAL_BLAKE3_DIR"
echo ""

# Check if local sources directory exists
if [ ! -d "$LOCAL_BLAKE3_DIR" ]; then
    echo "ERROR: Local BLAKE3 sources directory not found: $LOCAL_BLAKE3_DIR"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d -t blake3-verification-XXXXXXXX)
readonly TEMP_DIR
echo "Creating temporary directory: $TEMP_DIR"

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == /tmp/blake3-verification-* ]]; then
        echo "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf -- "$TEMP_DIR"
    else
        echo "Skip cleanup: suspicious TEMP_DIR='$TEMP_DIR'" >&2
    fi
}
trap cleanup EXIT INT TERM

# Clone official repository
echo "Cloning official BLAKE3 repository..."
git clone --quiet "$OFFICIAL_REPO" "$TEMP_DIR/blake3-official"

# Checkout specific commit
echo "Checking out commit: $OFFICIAL_COMMIT"
cd "$TEMP_DIR/blake3-official"
git checkout --quiet "$OFFICIAL_COMMIT"

# Go back to project root
cd - > /dev/null

# Compare files
echo ""
echo "=== Comparing files ==="

# List of BLAKE3 C files to compare
FILES=(
    "blake3.h"
    "blake3_impl.h"
    "blake3.c"
    "blake3_dispatch.c"
    "blake3_portable.c"
    "blake3_sse2.c"
    "blake3_sse41.c"
    "blake3_avx2.c"
    "blake3_avx512.c"
    "blake3_neon.c"
)

ALL_MATCH=true

for file in "${FILES[@]}"; do
    local_file="$LOCAL_BLAKE3_DIR/$file"
    official_file="$TEMP_DIR/blake3-official/c/$file"
    
    if [ ! -f "$local_file" ]; then
        echo "❌ Local file missing: $file"
        ALL_MATCH=false
        continue
    fi
    
    if [ ! -f "$official_file" ]; then
        echo "❌ Official file missing: $file"
        ALL_MATCH=false
        continue
    fi
    
    # Compare files using diff
    if diff -q "$local_file" "$official_file" > /dev/null; then
        echo "✅ $file - IDENTICAL"
    else
        echo "❌ $file - DIFFERENT"
        ALL_MATCH=false
        echo "   Use 'diff $local_file $official_file' to see differences"
    fi
done

echo ""
echo "=== Verification Result ==="
if [ "$ALL_MATCH" = true ]; then
    echo "✅ SUCCESS: All BLAKE3 C sources match the official repository!"
    echo "   Commit: $OFFICIAL_COMMIT"
    echo "   Repository: $OFFICIAL_REPO"
else
    echo "❌ FAILURE: Some files do not match the official repository!"
    exit 1
fi 