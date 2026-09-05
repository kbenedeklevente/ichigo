# P1 camera study

This is the first runnable Godot prototype, not the fishing or survival game. It tests camera framing, world-space targeting, shared water motion, and temporary child/bucket/fish forms. The art style, character details, scale, and final view range remain decisions for review.

## Run

Pinned and tested editor: **Godot 4.7.2 stable**, standard GDScript build. On the development Mac the verified official editor is installed at `/Applications/Godot.app`. [Official macOS download](https://godotengine.org/download/macos/).

Double-click `Run Ichigo.command` in the project root, or run:

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

Sky, Travel, and Detail compare 12°, 20°, and 52°. Keep sky temporarily constrains the range to 12°–26°. These are developer study controls, not final game UI. The line has no fishing fight or reward behavior yet. Moving or tilting the camera does not move a committed endpoint; its visible marker follows the local water surface.

## Technical baseline and limits

- Godot Compatibility renderer on the M2 test machine; no volumetric effects in this baseline. Final renderer/art selection is still open.
- Direct-follow wave fixture shared by the water and bucket; no independent shader wall clock.
- The local ocean masks its surface inside the bucket so its interior remains dry.
- The fish are visible surface-level geometry proxies, not finished underwater wildlife rendering or species claims.
- Steering works in every horizontal direction. The prototype has no encounter generator, inventory, story, saves, or progression yet.
- Camera targeting has a 12 m horizontal reach, rejects sky/invalid rays, and checks bucket occlusion. A committed line is a visual targeting experiment, not a simulated rope.
- Materials, child hairstyle/skin/jersey coloring, and the shallow geometry are provisional representations. The full flat/paper/low-/medium-poly comparison has not been produced.
- Keyboard/mouse and real rendered captures are reviewed separately from headless logic tests; controller bindings need physical-device playtesting.

## Checks and captures

```sh
./scripts/run_game.sh --headless --script game/tests/camera_contract_tests.gd
./scripts/run_game.sh --headless --script game/tests/scene_integration_tests.gd
./scripts/run_game.sh --resolution 1280x800 -- --capture-dir=/absolute/path/to/captures
```

Capture mode renders the five documented pitch samples at fixed simulation time. It opens a game window and then exits automatically. It must not be confused with the normal interactive launch.

The [design roadmap](../documents/design/visual_engine_roadmap.md) and [work packet](../documents/work_packets/camera_prototype.md) define the next comparisons. The human creator can begin with `game/camera/orbit_camera.gd` for framing, or `game/world/ocean_surface.gd` and its shader for the shared wave function.
