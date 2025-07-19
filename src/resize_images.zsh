#!/bin/zsh
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ==================================================================
#
# Resize all images in the current working directory to have the long side as 1024px, skipping images that are already smaller.
# Usage: resize_images.zsh (from any directory)


# Set nullglob for safe globbing
setopt nullglob

# Remove all .npz files in the current directory
rm -f -- *.npz
echo "Removed all .npz files in current directory"

# Fail fast if magick is not available
if ! command -v magick >/dev/null 2>&1; then
  echo "command not found: magick" >&2
  exit 1
fi

resize_image() {
  local img="$1"
  # Skip if not a file
  [[ ! -f "$img" ]] && return

  # Get width and height
  local dims
  dims=$(magick identify -format "%w %h" "$img" 2>/dev/null) || {
    echo "magick: error processing $img" >&2
    return
  }
  local width height
  read width height <<< "$dims"

  # Skip small images
  if (( width < 1024 && height < 1024 )); then
    echo "Skip $img (size: ${width}x${height})"
    return
  fi

  # Resize
  if (( width >= height )); then
    magick "$img" -resize x1024\> "$img" 2>/dev/null || {
      echo "magick: error processing $img" >&2
      return
    }
    echo "Landscape image $img resized height to 1024 (overwritten)"
  else
    magick "$img" -resize 1024x\> "$img" 2>/dev/null || {
      echo "magick: error processing $img" >&2
      return
    }
    echo "Portrait image $img resized width to 1024 (overwritten)"
  fi
}

for img in *.jpg *.png; do
  resize_image "$img"
done
