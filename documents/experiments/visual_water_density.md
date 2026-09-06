# Visual water density — retained version

6 September 2026. User-requested experiment on `codex/visual-water-density`, based on committed main `219b07a`. The user selected this version to keep, then requested a separate branch to preserve the large curling/shark-fin crests while refining the smaller background water. That follow-up does not rewrite this saved iteration.

## Implemented controls and separation

The **Wave density** slider runs from 1× to 8× per side, with 2× as this branch's initial preview. It works while paused. Readout shows visual spacing, tile count and FPS. Tab hides study controls. The setting is a laboratory presentation control and resets on launch; it is not added to world saves.

Logical cells remain 4 m, the active simulation remains 33×33 (1,089 samples), and the rendered logical footprint remains 17×17 cells (68 m square). Density `d` creates `(17d)²` smaller visual tiles, with one crest and one reclining ribbon per tile. Both drawings shrink in this retained iteration. At 8×, 18,496 tiles contain 36,992 drawings; no extra springs, velocities, event cells or simulation particles are allocated.

The existing sampler uploads a fixed 33×33 RGBA float texture: spring height, amplitude, scalar wind strength and cloud cover. It occupies 17,424 bytes before driver overhead at every slider value. The vertex shader samples four neighboring logical texels, interpolates height/weather and derives slope, then poses each independent illustration. The 0.5–2× weather height response and 2× vertical-motion gain remain in effect. This gives a finer visual presentation of the same physics; it does not increase fluid-solver accuracy.

Static MultiMesh anchors/art choices rebuild only when density changes or the player crosses a logical-cell boundary. World-coordinate identities remain stable when the window scrolls into negative coordinates. Explicit bounds include shader displacement and artwork extent. At the maximum, transform/custom-data storage is roughly 2.3 MiB across the two MultiMeshes, plus engine/driver overhead; it is rendering data, not particle simulation state.

## Local limit test

Actual OpenGL Compatibility rendering on Apple M2 / Godot 4.7.2, 1280×800, vsync disabled. Four densities, sunny calm and maximum storm baselines, 20° and 52° camera pitch; each case uses 20 warm-up frames and 60 measured frames. Physics still steps at 30 Hz. The test manually advances the usual scene/weather update with chance content disabled. These are short scene measurements, not a guaranteed game frame rate or a monotonic scaling curve.

| Density | Tile side | Tiles | Drawings | Measured FPS range | Largest layout rebuild |
|---|---|---:|---:|---:|---:|
| 1× | 4 m | 289 | 578 | 101–119 | 0.4 ms |
| 2× | 2 m | 1,156 | 2,312 | 76–90 | 0.9 ms |
| 4× | 1 m | 4,624 | 9,248 | 65–90 | 3.6 ms |
| 8× | 0.5 m | 18,496 | 36,992 | 67–87 | 13.3 ms |

The shader path keeps ordinary renderer CPU update around 0.03 ms in calm and 0.13–0.14 ms with rain in this run. The fixed physics/scene update dominates CPU work; high-density artwork adds GPU work. The maximum has a roughly 13 ms one-off layout rebuild when its window shifts. At high density the tiny ink lines become noisy and repeated rows more apparent, so 8× is an inspection limit rather than the recommended art setting. Root inspected calm 2×/4× and storm 2×/8× captures; 2× remains the starting preview for review.

[Raw results](visual-water-density/results.json) include frame means/p95, CPU timing, counts and texture size. Reproduce with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x800 --script game/tests/visual_density_benchmark.gd
```

## Verification

- Rendered density contracts: 81 checks, covering every slider step, fixed footprint, unchanged runtime snapshots/gameplay height, constant field allocation, cached anchors, negative-coordinate continuity, culling and save compatibility.
- Paper Theatre cards: 18 checks, updated to verify static anchors plus dynamic shader fields rather than obsolete CPU pose arrays.
- Weather scene: 19 checks including three rendered captures; rain, lighting, targeting and pause remain integrated.
- A one-off reference comparison rendered the saved `219b07a` CPU implementation and the new shader at 1× with identical state/camera. Mean absolute byte error was 0.010491 at 20° and 0.007735 at 52° on a 0–255 scale, consistent with small floating-point/raster differences.

The MultiMesh geometry checks require the actual renderer, not Godot's headless dummy renderer, which does not retain the same transform-query behavior. Tests free the scene before engine shutdown. The density suite exits successfully but the local OpenGL backend reports two 349,524-byte texture leaks during teardown; this shutdown diagnostic remains unresolved and is not counted as a clean resource-lifetime check. No in-run allocation growth was measured by this suite.

## Saved views

[Original density](visual-water-density/calm-20-density-1.png) · [2× calm](visual-water-density/calm-20-density-2.png) · [2× storm](visual-water-density/storm-52-density-2.png) · [8× storm limit](visual-water-density/storm-52-density-8.png)

## Next branch

Retain this complete iteration. The next branch will separate crest size/density from the lower water tiles. The user confirmed that curling crests should retain their original size and spacing; only the lower water panels should become smaller and denser. This is now implemented in the separate [full-size crest follow-up](full_size_wave_crests.md).
