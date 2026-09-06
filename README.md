# Ichigo

An ocean adventure about a young child in a wooden bucket, with tactile fishing, wildlife, puzzles, chance-based discoveries, and a strongly authored visual identity.

Current phase: a playable **Paper Theatre visual/weather prototype** in Godot 4.7.2, with illustrated child/bucket assets, adjustable camera, weather scheduling, crossing wave motion and experimental storm breakers. Fishing, inventory and authored story remain unfinished.

## Run the game on Mac

Install the standard **Godot 4.7.2** build at `/Applications/Godot.app`. In Terminal, run:

```sh
cd /Users/benedekkoos/projects/ichigo
./scripts/run_game.sh --resolution 1280x800
```

For the current **100% storm wave demo**, run:

```sh
./scripts/run_game.sh --resolution 1280x800 -- --storm-breakers
```

This starts Tempest sky + Tempest wind with immediate weather replacement enabled. Automatic weather selection is disabled for this review; occasional growing/crashing waves and surface bubble/foam rings remain active. The current extended-base asset is applied to all maximum-storm crests. The next planned change is to reserve it for the large crashing breakers; see [the saved decision](documents/experiments/storm_breakers.md#next-session-decision).

Alternatively, double-click `Run Ichigo.command` for normal Paper Theatre play. To open the editor, run `./scripts/run_game.sh --editor`. If the repository is elsewhere, use its actual directory. For a different Godot installation, set `ICHIGO_GODOT` to the executable path; the launcher also searches `godot`/`godot4` on PATH.

**Controls:** WASD moves; Q/E or mouse wheel tilts the camera; Tab toggles the study controls; Escape pauses. Keys 1–4 select sky, 5–8 select wind, 9 selects Tempest sky and 0 selects Tempest wind. Close the window to quit. See [full controls and setup](game/README.md).

## Plans

- [Shared event system](documents/design/event_system.md)
- [Weather study and parameters](documents/design/weather_runtime_parameters.md)
- [Current design and implementation plans](documents/design/README.md)
- [Development philosophy](documents/dev_philosophy.md)
- [Illustrated ocean panels and nested weather plan](documents/design/paper_ocean_weather.md)
- [Visual engine experimentation roadmap](documents/design/visual_engine_roadmap.md)
- [Earlier concept art and notes](docs/concept/README.md)
