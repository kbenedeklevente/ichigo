# Three lower-crest artwork studies

6 September 2026. The user requested three more restrained lower-body designs while preserving the upper curl they liked. The preceding complete game state is committed and pushed as **`acf75b7`** on `codex/full-size-wave-crests`. These proposals live on **`codex/crest-body-studies`**; no winner has been selected.

## Comparison

| Study | Lower-body treatment | Intended effect |
| --- | --- | --- |
| 1 — Quiet Cut | Shorter, shallow hem; two blue shapes; two long contour lines | A simple cut-paper silhouette with little ornament |
| 2 — Ink Wash | Fuller body; continuous blue-to-indigo gradient | Let the foot visually merge with the lower sea |
| 3 — Long Current | Tapered hem; two broad sweeping accents | Suggest flow through shape rather than small repeated marks |

Each is a complete family of three SVGs: single curl, double curl and sweep. All retain the original open crown contour and its three ink/ivory/grain strokes. Interior engraving is reduced to two crown-following contours; the lower repeated spiral marks, numerous vertical engravings and scalloped dark apron are removed. Lower silhouettes and fills differ deliberately. Original assets are untouched.

The variants keep the existing dimensions, pivots, UVs, height curve and weather motion. Switching drawings changes only the three crest material textures; the lower-water ribbon texture, simulation, scheduler, camera, bucket and visual-density setting do not change. Art sources are reproducibly generated from the original crowns by `scripts/art/build_crest_body_studies.py`, and the nine editable SVG outputs are committed.

## Showcase and live switching

Open [the comparison page](crest-body-study/index.html). It includes all three proposals, all three drawing shapes, matched calm/storm screenshots at 20° and 52°, zoomable images, and an original-comparison button. All four art families are captured from identical simulation state within each weather/camera pair.

For the live study:

```sh
./scripts/run_game.sh --resolution 1280x800 -- --crest-study
```

The additional **Crest** selector offers saved original, Quiet Cut, Ink Wash and Long Current. It works during pause and does not advance physics. The ordinary game launch still uses the saved original and does not display the study selector. Use the existing weather replacement mode and controls to compare other conditions in motion.

Regenerate the SVGs, import them, then regenerate the matched captures:

```sh
python3 scripts/art/build_crest_body_studies.py
./scripts/run_game.sh --headless --editor --import
./scripts/run_game.sh --resolution 1280x800 --script game/tests/crest_body_study.gd -- --crest-study
```

## Review and verification

The initial pass exposed abrupt truncation of interior lines. That pass was refined before delivery to use continuous long contours rather than clipped engraving. Godot imports all nine SVGs. The final rendered study passed **66 checks**, covering material loading, unchanged runtime snapshots on art switching, selection handling and capture output. The browser comparison layout was inspected at 1280 px width. Source validation confirms the original crown paths/stroke attributes are preserved across all variants.

Captured and inspected individual artwork and in-game views; this is sampled visual verification, not acceptance across every animation phase. Quiet Cut and Long Current shorten the lower apron; their existing row overlap should be reviewed in motion, particularly in stronger weather. The background sea continues to provide its existing illustrated coverage.

Next step: the user compares these three proposals and chooses one or identifies features to combine. Do not replace the accepted crest assets until that review.
