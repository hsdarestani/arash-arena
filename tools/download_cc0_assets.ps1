$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "assets\cc0"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$assets = @(
  @{
    Name = "Knight.glb"
    Url = "https://cdn.jsdelivr.net/gh/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0@main/addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb"
  },
  @{
    Name = "Skeleton_Minion.glb"
    Url = "https://cdn.jsdelivr.net/gh/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0@main/addons/kaykit_character_pack_skeletons/Characters/gltf/Skeleton_Minion.glb"
  }
)

foreach ($asset in $assets) {
  $target = Join-Path $out $asset.Name
  Write-Host "Downloading $($asset.Name)..."
  Invoke-WebRequest -Uri $asset.Url -OutFile $target
}

Write-Host "CC0 character assets downloaded. Reopen Godot so the GLB files are imported."
