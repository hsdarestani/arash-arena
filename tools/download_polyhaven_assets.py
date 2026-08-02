#!/usr/bin/env python3
"""Download compact CC0 Poly Haven assets for the Slice Lab Android build.

The game always has procedural fallbacks, so network/API changes never break CI.
"""
from __future__ import annotations

import json
import pathlib
import shutil
import sys
import urllib.parse
import urllib.request
from typing import Any, Iterable

ROOT = pathlib.Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "polyhaven"
USER_AGENT = "SliceLab-Godot/0.2 (+https://github.com/hsdarestani/arash-arena)"
MODEL_IDS = ("lemon", "food_pomegranate_01", "food_kiwi_01")
TEXTURE_ID = "wood_table_001"


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
    with urllib.request.urlopen(
        urllib.request.Request(url, headers={"User-Agent": USER_AGENT}), timeout=120
    ) as response, target.open("wb") as output:
        shutil.copyfileobj(response, output)
    print(f"Downloaded {target.relative_to(ROOT)} ({target.stat().st_size / 1024 / 1024:.1f} MB)")


def download_model(asset_id: str) -> None:
    data = request_json(f"https://api.polyhaven.com/files/{asset_id}")
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
            score += 100
        if "gltf" in joined:
            score += 30
        if url.lower().endswith(".gltf"):
            score += 20
        candidates.append((score, node))
    if not candidates:
        raise RuntimeError(f"No glTF candidate found for {asset_id}")
    _, selected = max(candidates, key=lambda item: item[0])
    main_url = selected["url"]
    extension = pathlib.Path(urllib.parse.urlparse(main_url).path).suffix.lower()
    folder = ASSET_ROOT / asset_id
    download(main_url, folder / f"{asset_id}{extension}")
    for dependency_url in urls_in(selected):
        if dependency_url == main_url:
            continue
        name = pathlib.Path(urllib.parse.urlparse(dependency_url).path).name
        if name:
            download(dependency_url, folder / name)


def choose_texture(data: Any, keywords: tuple[str, ...]) -> str | None:
    candidates: list[tuple[int, str]] = []
    for path, node in walk(data):
        if not isinstance(node, dict) or not isinstance(node.get("url"), str):
            continue
        url = node["url"]
        if not url.lower().endswith((".jpg", ".jpeg", ".png")):
            continue
        joined = "/".join(path).lower()
        if not any(keyword in joined for keyword in keywords):
            continue
        score = 100 if "1k" in joined else 0
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
            download(url, folder / filename)


def main() -> int:
    ASSET_ROOT.mkdir(parents=True, exist_ok=True)
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
    print("Poly Haven asset preparation finished.")
    if failures:
        print("Some optional assets were unavailable; procedural fallbacks will be used.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
