# !/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "requests<3",
# ]
# ///
"""
Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
import logging
import os
import re
import time
from pathlib import Path
from typing import List, Optional

import requests

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

IMAGE_PATTERN = re.compile(r"^(\d+)_([0-9a-fA-F]{32})\.(jpg|jpeg|png|gif)$")
GELBOORU_MD5_PATTERN = re.compile(
    r'<section[^>]+class="[^"]*image-container note-container[^"]*"'
    r'[^>]*data-md5="([0-9a-fA-F]{32})"'
)
GELBOORU_TAG_UL_PATTERN = re.compile(r'<ul[^>]+id="tag-list"[^>]*>([\s\S]*?)</ul>')
GELBOORU_TAG_LI_PATTERN = re.compile(
    r'<li[^>]+class="tag-type-general"[^>]*>[\s\S]*?' r'<a [^>]*href="[^"]*tags=[^>]+>([^<]+)</a>',
    re.IGNORECASE,
)


def get_image_files(root_dir: Path) -> List[str]:
    """Find all image files matching {id}_{hash}.{ext} in root_dir."""
    files = []
    for entry in os.listdir(root_dir):
        if IMAGE_PATTERN.match(entry):
            files.append(entry)
    return files


def fetch_danbooru_tags(md5_hash: str) -> Optional[List[str]]:
    """Fetch tags from Danbooru API using MD5 hash."""
    url = "https://danbooru.donmai.us/posts.json"
    params = {"md5": md5_hash}
    logger.info(f"[Danbooru] Query: {url} params={params}")

    try:
        resp = requests.get(url, params=params, timeout=10)
        logger.info(f"[Danbooru] Status: {resp.status_code}")
        resp.raise_for_status()
        data = resp.json()
        logger.info(f"[Danbooru] Response: {data}")

        if not data:
            logger.info("[Danbooru] No data found.")
            return None

        # Handle both dict and list responses
        post = data[0] if isinstance(data, list) else data
        if isinstance(data, list) and not data:
            logger.info("[Danbooru] No data found (empty list).")
            return None

        tags = []
        general = post.get("tag_string_general", "")
        character = post.get("tag_string_character", "")

        if general:
            tags.extend(general.split())
        if character:
            tags.extend(character.split())

        logger.info(f"[Danbooru] Tags: {tags}")
        return tags if tags else None

    except Exception as e:
        logger.error(f"[Danbooru] Exception: {e}")
        return None


def fetch_gelbooru_tags(md5_hash: str, post_id: str) -> Optional[List[str]]:
    """Fetch tags from Gelbooru by parsing HTML using post ID and MD5 hash."""
    logger.info(f"[Gelbooru] HTML parse for hash: {md5_hash}")

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        )
    }

    try:
        post_url = f"https://gelbooru.com/index.php?page=post&s=view&id={post_id}"
        resp = requests.get(post_url, headers=headers, timeout=10)
        logger.info(f"[Gelbooru-HTML] Post Status: {resp.status_code} for id {post_id}")

        if resp.status_code != 200:
            logger.error(f"[Gelbooru-HTML] Post HTTP {resp.status_code}")
            return None

        html = resp.text

        # Parse MD5 from data-md5 attribute
        md5_match = GELBOORU_MD5_PATTERN.search(html)
        if not md5_match or md5_match.group(1).lower() != md5_hash.lower():
            logger.warning(
                f"[Gelbooru-HTML] md5 {md5_hash} not found " f"in data-md5 for id {post_id}."
            )
            found_md5 = md5_match.group(1) if md5_match else None
            logger.info(f"[Gelbooru-HTML] md5 in data-md5: {found_md5}")
            return None

        logger.info(f"[Gelbooru-HTML] Matched md5 for id {post_id} (from data-md5)")

        # Parse tags from tag-list
        tags = _parse_gelbooru_tags(html)

        if tags:
            logger.info(f"[Gelbooru-HTML] Tags (from tag-list): {tags}")
            return tags
        else:
            logger.warning("[Gelbooru-HTML] No tags found in tag-list. " "Dumping snippet:")
            logger.debug(html[:2000])
            return None

    except Exception as e:
        logger.error(f"[Gelbooru-HTML] Exception: {e}")
        return None


def _parse_gelbooru_tags(html: str) -> List[str]:
    """Parse tags from Gelbooru HTML tag-list section."""
    tags = []
    tag_ul = GELBOORU_TAG_UL_PATTERN.search(html)

    if not tag_ul:
        return tags

    tag_block = tag_ul.group(1)

    # Split by Tag header to get only general tags
    tag_section = re.split(r"<li[^>]*><b>\s*Tag\s*</b></li>", tag_block, flags=re.IGNORECASE)

    if len(tag_section) > 1:
        tag_block = tag_section[1]
    else:
        tag_block = ""

    # Extract tag names from general tag links
    tags = [m.group(1).replace(" ", "_") for m in GELBOORU_TAG_LI_PATTERN.finditer(tag_block)]

    return tags


def write_tags_file(image_path: Path, tags: List[str]) -> None:
    """Write tags to corresponding .txt file."""
    txt_path = image_path.with_suffix(".txt")
    tags_line = ", ".join(tag.replace(" ", "_") for tag in tags)

    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(tags_line + "\n")


def process_image_file(root: Path, filename: str) -> None:
    """Process a single image file to fetch and save tags."""
    match = IMAGE_PATTERN.match(filename)
    if not match:
        logger.warning(f"Filename {filename} doesn't match expected pattern")
        return

    img_id, md5_hash, ext = match.groups()
    img_path = root / filename

    # Try Danbooru first
    tags = fetch_danbooru_tags(md5_hash)

    # Fallback to Gelbooru if Danbooru fails
    if not tags:
        logger.info(f"[Info] Not found on Danbooru, try Gelbooru: {md5_hash}")
        tags = fetch_gelbooru_tags(md5_hash, img_id)

    if tags:
        write_tags_file(img_path, tags)
        logger.info(f"Tags written: {img_path.with_suffix('.txt').name}")
    else:
        logger.error(
            f"[ERROR] No tags found for {filename} (hash: {md5_hash})! "
            "This should not happen. "
            "Please check the logs above for details."
        )


def main() -> None:
    """Main function to process all image files in the current directory."""
    root = Path(__file__).parent
    image_files = get_image_files(root)

    logger.info(f"Found {len(image_files)} images:")

    for filename in image_files:
        logger.info(f"Processing: {filename}")
        process_image_file(root, filename)
        time.sleep(1)  # Rate limiting


if __name__ == "__main__":
    main()
