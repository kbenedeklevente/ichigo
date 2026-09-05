# P1 camera study

This is the first runnable Godot prototype, not the fishing or survival game. It tests camera framing, world-space targeting, shared water motion, and temporary child/bucket/fish forms. The user selected the full 12°–52° range and illustrated paper assets. The current solid proxies are awaiting replacement; they do not represent the selected art direction.

## Weather and event study

Run `./scripts/run_game.sh -- --weather-study` to open **Ichigo — Raised Waves Study** with pointed illustrated crests, shared triggered/chance weather and the salvage encounter fixture. Keys1–4 select sky,5–8 wind. I requests salvage; O sends it away as abandoned. Requests respect active encounters, weather transitions and the approved quiet interval. See [parameters, controls and known limits](../documents/design/weather_runtime_parameters.md). This adds the event/weather foundation; the solid child/bucket proxies still need replacement.

## Run

Pinned and tested editor: **Godot 4.7.2 stable**, standard GDScript build. On the development Mac the verified official editor is installed at `/Applications/Godot.app`. [Official macOS download](https://godotengine.org/download/macos/).

Double-click `Run Ichigo.command` in the project root for the latest raised-wave/encounter study. For the original camera baseline, run:

```sh
./scripts/run_game.sh
```

To edit the project:

```sh
./scripts/run_game.sh --editor
```

The launcher also accepts an executable via `ICHIGO_GODOT`, a project-local editor under `work/runtime`, or a `godot`/`godot4` executable on PATH. Normal play stays open until you close the window. Capture mode explicitly closes after saving its five images; that is intentional.

## Controls

| Action | Keyboard/mouse | Controller mapping |
|---|---|---|
| Move bucket | WASD | Left stick |
| Tilt camera | Q/E, mouse wheel, or study slider | Shoulder buttons |
| Aim | Pointer over reachable water | Right stick reticle |
| Place line endpoint | Left click / Space | A |
| Clear line | Right click / Backspace | B |
| Pause/resume | Escape / study button | Start |
| Hide/show study controls | Tab | Keyboard only in this prototype |

Sky, Travel, and Detail compare 12°, 20°, and 52°. The Keep sky option has been removed following user review. These are developer study controls, not final game UI. The line has no fishing fight or reward behavior yet. Moving or tilting the camera does not move a committed endpoint; its visible marker follows the local water surface.

## Technical baseline and limits

- Godot Compatibility renderer on the M2 test machine; no volumetric effects in this baseline. Final renderer/art selection is still open.
- Direct-follow wave fixture shared by the water and bucket; no independent shader wall clock.
- The local ocean masks its surface inside the bucket so its interior remains dry.
- The fish are visible surface-level geometry proxies, not finished underwater wildlife rendering or species claims.
- Steering works in every horizontal direction. Weather-study mode has a generic event director and in-memory state snapshots; authored encounters, inventory, story progression and a game save UI remain unfinished.
- Camera targeting has a 12 m horizontal reach, rejects sky/invalid rays, and checks bucket occlusion. A committed line is a visual targeting experiment, not a simulated rope.
- Framing is slightly smaller (camera distance 10.2 m, previously 9.4 m) and the bucket uses warmer brown wood. Child-to-bucket proportions and gameplay reach are preserved.
- Solid child/bucket proxies still need replacement with layered illustrations. See the [paper ocean and weather plan](../documents/design/paper_ocean_weather.md). Low-/medium-poly and volumetric studies remain optional later experiments; the next work prioritizes illustrated panels.
- Keyboard/mouse and real rendered captures are reviewed separately from headless logic tests; controller bindings need physical-device playtesting.

## Checks and captures

```sh
./scripts/run_game.sh --headless --script game/tests/camera_contract_tests.gd
./scripts/run_game.sh --headless --script game/tests/scene_integration_tests.gd
./scripts/run_game.sh --resolution 1280x800 -- --capture-dir=/absolute/path/to/captures
```

Capture mode renders the five documented pitch samples at fixed simulation time. It opens a game window and then exits automatically. It must not be confused with the normal interactive launch.

The [design roadmap](../documents/design/visual_engine_roadmap.md) and [work packet](../documents/work_packets/camera_prototype.md) define the next comparisons. The human creator can begin with `game/camera/orbit_camera.gd` for framing, or `game/world/ocean_surface.gd` and its shader for the original shared wave fixture. The weather study uses `game/world/weather_simulation.gd` for its authoritative surface.

Additional foundation checks:

```sh
./scripts/run_game.sh --headless --script game/tests/event_director_tests.gd
./scripts/run_game.sh --headless --script game/tests/weather_simulation_tests.gd
./scripts/run_game.sh --headless --script game/tests/environment_runtime_tests.gd
./scripts/run_game.sh --headless --script game/tests/weather_scene_tests.gd -- --weather-study
```

Raised-wave and encounter checks:

```sh
./scripts/run_game.sh --headless --script game/tests/raised_wave_tests.gd
./scripts/run_game.sh --headless --script game/tests/encounter_runtime_tests.gd
./scripts/run_game.sh --headless --script game/tests/encounter_weather_tests.gd
```

The [latest review](../documents/work_packets/p2_wave_encounter_review.md) records implementation boundaries and visual feedback needs.
