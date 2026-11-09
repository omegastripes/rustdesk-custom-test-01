#!/bin/bash

# Path to ImageMagick convert command
# Can be set via environment variable: IM_CONVERT_PATH
# Or passed as first argument to script
CONVERT_PATH="${IM_CONVERT_PATH:-$1}"

if [ -z "$CONVERT_PATH" ]; then
    echo "Error: ImageMagick convert path not provided."
    echo "Usage: IM_CONVERT_PATH=/path/to/convert ./gen_icon.sh [android_source_dir]"
    echo "Or: ./gen_icon.sh /path/to/convert [android_source_dir]"
    exit 1
fi

if [ ! -f "$CONVERT_PATH" ]; then
    echo "Error: convert not found at: $CONVERT_PATH"
    exit 1
fi

# Android icon processing
ANDROID_SOURCE_DIR="$2"

if [ -n "$ANDROID_SOURCE_DIR" ]; then
    if [ ! -d "$ANDROID_SOURCE_DIR" ]; then
        echo "Error: Android source directory not found: $ANDROID_SOURCE_DIR"
        exit 1
    fi

    echo "Processing Android icons from: $ANDROID_SOURCE_DIR"

    # Android densities and their multipliers (relative to mdpi=1x)
    # Source icons are at 12x scale, so we divide by 12 then multiply by density
    declare -A DENSITIES=(
        ["mdpi"]=1
        ["hdpi"]=1.5
        ["xhdpi"]=2
        ["xxhdpi"]=3
        ["xxxhdpi"]=4
    )

    # Icon types to process
    ICON_TYPES=(
        "ic_launcher.png"
        "ic_launcher_foreground.png"
        "ic_launcher_round.png"
        "ic_stat_logo.png"
    )

    # Target directory
    TARGET_DIR="../flutter/android/app/src/main/res"

    for icon_type in "${ICON_TYPES[@]}"; do
        source_file="$ANDROID_SOURCE_DIR/$icon_type"

        if [ ! -f "$source_file" ]; then
            echo "Warning: Source icon not found: $source_file"
            continue
        fi

        echo "Processing: $icon_type"

        # Get source image dimensions
        dimensions=$("$CONVERT_PATH" "$source_file" -ping -format "%w %h" info:)
        source_width=$(echo $dimensions | awk '{print $1}')
        source_height=$(echo $dimensions | awk '{print $2}')

        echo "  Source size: ${source_width}x${source_height}"

        for density in "${!DENSITIES[@]}"; do
            target_dir="$TARGET_DIR/mipmap-$density"

            # Create target directory if it doesn't exist
            mkdir -p "$target_dir"

            # Calculate target size: source_size / 12 * multiplier
            target_width=$(awk "BEGIN {printf \"%.0f\", $source_width / 12 * ${DENSITIES[$density]}}")
            target_height=$(awk "BEGIN {printf \"%.0f\", $source_height / 12 * ${DENSITIES[$density]}}")

            "$CONVERT_PATH" "$source_file" -resize "${target_width}x${target_height}" "$target_dir/$icon_type"
            echo "  -> $target_dir/$icon_type (${target_width}x${target_height})"
        done
    done

    echo "Android icons processing complete."
fi

# Original Windows icon processing
for size in 16 32 48 64 128 256 512 1024; do
    #inkscape -z -o $size.png -w $size -h $size icon.svg >/dev/null 2>/dev/null
    "$CONVERT_PATH" icon.png -resize ${size}x${size} ${size}.png
done
# from ImageMagick
"$CONVERT_PATH" 16.png 32.png 48.png 128.png 256.png -colors 256 icon.ico
#/bin/rm 16.png 32.png 48.png 128.png 256.png
