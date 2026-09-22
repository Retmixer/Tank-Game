# Стальной рубеж — Godot

Native Godot 4 project alongside the existing browser edition. The browser app is retained as-is; this directory is the native port.

## Open and run

1. Install or extract Godot 4.7.2 (or a compatible Godot 4.x release).
2. In Godot Project Manager, import `godot/project.godot`, or open this folder as a project.
3. Press **F6** only for the selected scene; use **F5** to run the full game.

On Windows, from the repository root, the equivalent command is:

```powershell
godot --path .\godot
```

## Ported systems

- The 12 vehicle definitions, armor zones, progression values, and all three original map definitions are loaded from `data/game_data.json`, exported from the browser game's source data.
- Training Ground, Desert Range, and Winter Factory are built as native 3D scenes with height-mapped terrain, map-specific paths, buildings, rock formations, tree lines, industrial objects, collision, lighting, and atmosphere.
- The original PBR texture and audio resources are included under `assets/` with the existing attribution/licensing files.
- Native vehicle construction, WASD movement, turret/cannon aiming, mouse firing, shell flight, armor penetration/ricochet, track damage and repair, 3×3 / 5×5 / 7×7 bot battles with difficulty options, capture objective, aiming zoom, battle HUD, garage, research, pause/settings/results, and ENet 1v1 lobby are implemented in GDScript.
- Game progress is saved separately by Godot to `user://steel_frontier_save.json`. Browser localStorage is not automatically imported.

## Controls

- **WASD** — drive/steer
- **Mouse** — rotate camera and aim
- **Left mouse button** — fire
- **Hold Shift** — aim/zoom
- **Tab** — scoreboard
- **Esc** — pause

For a Radmin VPN match, one player hosts from the Local Network lobby and shares the displayed Radmin IPv4 address. The other player enters that address. Both computers must allow UDP port `28765` through the firewall.

## Notes

- `.godot/` is a generated editor/import cache and is intentionally excluded from Git.
- No APK is built by this project setup.
- The project uses Godot's Forward+ renderer on desktop and Mobile renderer on mobile devices.
