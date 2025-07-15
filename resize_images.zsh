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


# Set nullglob option to handle cases where no files match the pattern
setopt nullglob

# Remove all .npz files in the current directory before resizing images
rm -f -- *.npz
echo "Removed all .npz files in current directory"

for img in *.jpg *.png; do
  [[ ! -f "$img" ]] && continue
  # Get image width and height
  read width height < <(magick identify -format "%w %h" "$img")
  # Skip images smaller than 1024px on both sides
  if (( width < 1024 && height < 1024 )); then
    echo "Skip $img (size: ${width}x${height})"
    continue
  fi
  # Determine if the image is landscape or portrait
  if (( width >= height )); then
    # Landscape: resize height to 1024, overwrite original file
    magick "$img" -resize x1024\> "$img"
    echo "Landscape image $img resized height to 1024 (overwritten)"
  else
    # Portrait: resize width to 1024, overwrite original file
    magick "$img" -resize 1024x\> "$img"
    echo "Portrait image $img resized width to 1024 (overwritten)"
  fi
done
