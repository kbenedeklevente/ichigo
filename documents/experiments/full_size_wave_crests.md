# Full-size crests with smaller water panels

6 September 2026. Implemented on `codex/full-size-wave-crests`, branched from retained commit `c05d76f` on `codex/visual-water-density`. The [first density iteration](visual_water_density.md) remains separately version controlled. This follow-up implements the user's confirmed correction; its final appearance awaits review.

## Accepted behavior

The **Water detail** slider changes only the lower reclining water panels. Curling/shark-fin crests keep their original size, spacing and artwork identity at every slider value. Their existing weather-dependent height (½× in calm through 2× at maximum wind and sky strength) and doubled vertical motion remain active.

The slider runs from 1× to 8× per side, starts at 2×, and works while paused. Logical cells remain 4 m, the simulation remains 33×33, and the rendered footprint remains 68 m square. Lower panels interpolate the fixed weather field on the GPU; denser rendering adds no simulated particles or springs.

| Detail | Lower-panel side | Lower panels | Curling crests | Total drawings |
| --- | --- | --- | --- | --- |
| 1× | 4 m | 289 | 289 | 578 |
| 2× | 2 m | 1,156 | 289 | 1,445 |
| 4× | 1 m | 4,624 | 289 | 4,913 |
| 8× | 0.5 m | 18,496 | 289 | 18,785 |

Crests have a separate cached layout keyed to the logical window. Changing detail rebuilds only the lower-panel layout. Both drawing types still sample the same fixed 1,089 weather values, carried in a 17,424-byte RGBA float texture. This improves visual sampling density; it does not increase physical simulation resolution.

## Verification and limits

- Rendered density suite: 90 checks passed, including all slider values, unchanged simulation snapshots and gameplay height, fixed allocation/footprint, stable anchors across negative coordinates, and save compatibility.
- With lower panels hidden and the scene frozen, the rendered crest image at 1× and 8× was pixel-identical. Crest anchors and artwork data also remain unchanged at every slider step.
- Weather scene integration: 16 checks passed.
- Rendered captures inspected at calm 20°/2× and storm 52°/8×. The maximum detail produces dense ink texture and remains an experiment limit. This is implementation verification, not user visual approval.

The rendered suites require the actual graphics backend; Godot's headless dummy renderer cannot validate the MultiMesh geometry queries. The latest density run exited without the earlier retained iteration's texture teardown diagnostic, but no claim of a resolved resource-lifetime cause or long-running memory test is made.

[Calm at 2×](full-size-wave-crests/calm-20-density-2.png) · [Storm at 8×](full-size-wave-crests/storm-52-density-8.png)

## Next review

Compare the lower-panel detail in motion while the large crests remain consistent. Keep the existing 2× starting preview until the user selects another value. Further changes to artwork scale, repetition or density defaults require visual feedback.
