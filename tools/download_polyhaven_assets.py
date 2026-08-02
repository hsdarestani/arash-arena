#!/usr/bin/env python3
"""Download and mobile-optimize CC0/OFL assets used by Dakechi."""
from __future__ import annotations

import json
import pathlib
import shutil
import sys
import urllib.parse
import urllib.request
from typing import Any, Iterable

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "polyhaven"
FONT_ROOT = ROOT / "assets" / "fonts"
USER_AGENT = "Dakechi-Godot/0.3 (+https://github.com/hsdarestani/arash-arena)"
MODEL_IDS = (
    "lemon",
    "food_pomegranate_01",
    "food_kiwi_01",
    "food_apple_01",
    "yellow_onion",
    "sweet_potato",
    "hamburger_buns",
)
TEXTURE_ID = "wood_table_001"
MAX_TEXTURE_SIZE = 1024
FONT_URLS = {
    "Vazirmatn-Regular.ttf": "https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/fonts/ttf/Vazirmatn-Regular.ttf",
    "Vazirmatn-Bold.ttf": "https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/fonts/ttf/Vazirmatn-Bold.ttf",
}


def request_bytes(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def request_json(url: str) -> Any:
    return json.loads(request_bytes(url).decode("utf-8"))


def walk(value: Any, path: tuple[str, ...] = ()) -> Iterable[tuple[tuple[str, ...], Any]]:
    yield path, value
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk(child, path + (str(key),))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, path + (str(index),))


def urls_in(value: Any) -> list[str]:
    result: list[str] = []
    for _, node in walk(value):
        if isinstance(node, dict) and isinstance(node.get("url"), str):
            result.append(node["url"])
    return result


def download(url: str, target: pathlib.Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=150) as response, target.open("wb") as output:
        shutil.copyfileobj(response, output)
    print(f"Downloaded {target.relative_to(ROOT)} ({target.stat().st_size / 1024 / 1024:.1f} MB)")


def optimize_image(path: pathlib.Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGB") if source.mode not in ("RGB", "RGBA") else source.copy()
        image.thumbnail((MAX_TEXTURE_SIZE, MAX_TEXTURE_SIZE), Image.Resampling.LANCZOS)
        suffix = path.suffix.lower()
        if suffix in (".jpg", ".jpeg"):
            image.convert("RGB").save(path, quality=86, optimize=True, progressive=True)
        else:
            image.save(path, optimize=True, compress_level=9)
    print(f"Optimized {path.relative_to(ROOT)} to {image.width}x{image.height}")


def choose_model(data: Any) -> dict[str, Any]:
    candidates: list[tuple[int, dict[str, Any]]] = []
    for path, node in walk(data):
        if not isinstance(node, dict):
            continue
        url = node.get("url")
        if not isinstance(url, str) or not url.lower().endswith((".gltf", ".glb")):
            continue
        joined = "/".join(path).lower()
        score = 0
        if "1k" in joined:
            score += 1000
        elif "2k" in joined:
            score += 500
        if "gltf" in joined:
            score += 100
        if url.lower().endswith(".gltf"):
            score += 30
        candidates.append((score, node))
    if not candidates:
        raise RuntimeError("No glTF candidate found")
    return max(candidates, key=lambda item: item[0])[1]


def resolve_dependency_url(uri: str, urls: list[str]) -> str | None:
    wanted = pathlib.PurePosixPath(urllib.parse.unquote(uri)).name.lower()
    exact = [
        url
        for url in urls
        if pathlib.PurePosixPath(urllib.parse.unquote(urllib.parse.urlparse(url).path)).name.lower()
        == wanted
    ]
    if exact:
        return exact[0]
    stem = pathlib.Path(wanted).stem.lower()
    partial = [
        url
        for url in urls
        if stem in pathlib.PurePosixPath(urllib.parse.unquote(urllib.parse.urlparse(url).path)).name.lower()
    ]
    return partial[0] if partial else None


def download_model(asset_id: str) -> None:
    data = request_json(f"https://api.polyhaven.com/files/{asset_id}")
    selected = choose_model(data)
    main_url = str(selected["url"])
    extension = pathlib.Path(urllib.parse.urlparse(main_url).path).suffix.lower()
    folder = ASSET_ROOT / asset_id
    main_target = folder / f"{asset_id}{extension}"
    download(main_url, main_target)
    if extension == ".glb":
        return

    document = json.loads(main_target.read_text(encoding="utf-8"))
    dependency_urls = urls_in(selected)
    uris: list[str] = []
    for buffer in document.get("buffers", []):
        if isinstance(buffer, dict) and isinstance(buffer.get("uri"), str):
            uris.append(buffer["uri"])
    for image in document.get("images", []):
        if isinstance(image, dict) and isinstance(image.get("uri"), str):
            uris.append(image["uri"])

    for uri in dict.fromkeys(uris):
        if uri.startswith("data:"):
            continue
        dependency_url = resolve_dependency_url(uri, dependency_urls)
        if dependency_url is None:
            raise RuntimeError(f"Missing dependency URL for {uri}")
        target = folder / pathlib.PurePosixPath(uri)
        download(dependency_url, target)
        if target.suffix.lower() in (".png", ".jpg", ".jpeg"):
            optimize_image(target)


def choose_texture(data: Any, keywords: tuple[str, ...]) -> str | None:
    candidates: list[tuple[int, str]] = []
    for path, node in walk(data):
        if not isinstance(node, dict) or not isinstance(node.get("url"), str):
            continue
        url = str(node["url"])
        if not url.lower().endswith((".jpg", ".jpeg", ".png")):
            continue
        joined = "/".join(path).lower()
        if not any(keyword in joined for keyword in keywords):
            continue
        score = 1000 if "1k" in joined else 500 if "2k" in joined else 0
        score += 15 if url.lower().endswith((".jpg", ".jpeg")) else 5
        candidates.append((score, url))
    return max(candidates, key=lambda item: item[0])[1] if candidates else None


def download_table_texture() -> None:
    data = request_json(f"https://api.polyhaven.com/files/{TEXTURE_ID}")
    folder = ASSET_ROOT / TEXTURE_ID
    selections = {
        "table_diffuse.jpg": ("diff", "albedo"),
        "table_normal.jpg": ("nor_gl", "normal_gl"),
        "table_roughness.jpg": ("rough",),
    }
    for filename, keywords in selections.items():
        url = choose_texture(data, keywords)
        if url:
            target = folder / filename
            download(url, target)
            optimize_image(target)


def download_fonts() -> None:
    for filename, url in FONT_URLS.items():
        download(url, FONT_ROOT / filename)


def main() -> int:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
    FONT_ROOT.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    for asset_id in MODEL_IDS:
        try:
            download_model(asset_id)
        except Exception as error:
            failures.append(f"{asset_id}: {error}")
            print(f"Warning: {failures[-1]}", file=sys.stderr)
    try:
        download_table_texture()
    except Exception as error:
        failures.append(f"{TEXTURE_ID}: {error}")
        print(f"Warning: {failures[-1]}", file=sys.stderr)
    try:
        download_fonts()
    except Exception as error:
        failures.append(f"fonts: {error}")
        print(f"Warning: {failures[-1]}", file=sys.stderr)
    print("Dakechi asset preparation finished.")
    if failures:
        print("Some optional assets were unavailable; built-in fallbacks will be used.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
