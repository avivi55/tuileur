#!/bin/bash

BASE_DIR="$(pwd)"
TILES_DIR="$BASE_DIR/tiles"
TARGET_DIR="$TILES_DIR/All"

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

COUNTER=1

while read -r file; do
    EXTENSION="${file##*.}"
    
    REL_PATH=$(realpath --relative-to="$TARGET_DIR" "$file")
    
    ln -s "$REL_PATH" "$TARGET_DIR/tile${COUNTER}.${EXTENSION}"
    
    ((COUNTER++))
done < <(find "$TILES_DIR" -type f \( -name "*.svg" -o -name "*.png" -o -name "*.jpg" \) | grep -v "$TARGET_DIR" | sort)

echo "Successfully created $((COUNTER-1)) relative symbolic links in $TARGET_DIR"