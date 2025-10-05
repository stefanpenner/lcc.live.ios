#!/bin/bash

# Install potrace if not installed
if ! command -v potrace &> /dev/null; then
    echo "Installing potrace via Homebrew..."
    brew install potrace
fi

# Convert PNG to PBM (bitmap) first
convert image.png -colorspace Gray -threshold 50% image.pbm

# Convert PBM to SVG using potrace
potrace image.pbm -s -o image.svg

# Clean up temporary file
rm image.pbm

echo "✅ Vector version created: image.svg"
