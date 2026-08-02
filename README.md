# SLICE LAB

A mobile-first cinematic slicing game built with Godot 4.7.

## Gameplay

- Swipe across the screen to slice fruit.
- Slice multiple objects in one gesture to multiply the score.
- Missing fruit costs one life.
- Touching a bomb ends the run.
- Best score is saved locally.

## Visual assets

The CI build downloads compact CC0 models and PBR textures from Poly Haven for the lemon, pomegranate, kiwi, and table surface. The project also includes procedural fallback fruit and materials, so it remains buildable if an optional download is unavailable.

## Android build

GitHub Actions exports a signed ARM64 debug APK on each push. The artifact is named `Slice-Lab-Android`.

Local Godot export path:

```text
build/Slice_Lab.apk
```
