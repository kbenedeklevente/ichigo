# Five wave art experiments

2026-09-05. Baseline: `8255dd4`. These are parallel visual proposals, not a chosen replacement for the main game. Each lives in its own Git worktree and branch. The user will choose or combine directions after reviewing actual engine captures.

## Shared brief

Keep the 12–52° camera range, default 20° framing, calm baseline, oversized jersey 15, no hat, young ungendered child and brown wooden bucket. Preserve independent sky/wind weather, the simulated grid surrounding the smaller rendered grid, and the event pacing rules. Illustration, shape and composition are the variables in this experiment.

The latest brief explicitly permits removing the shared **visible** water surface. The three theatre studies can keep an invisible continuous gameplay sampler beneath separate illustrated props. That is an experimental approximation: a raycast or bucket waterline does not automatically match every decorative paper crest. Selecting a theatre direction requires a later interaction/occlusion pass.

## Directions

| # | Name | Construction | Artistic question |
|---|---|---|---|
| 01 | Prussian Ink | Shared raised mesh, redesigned SVG and matching CPU/GPU profiles | Can carved dark ink, curling foam and sweeping relief make the existing construction feel illustrated? |
| 02 | Faded Tides | Shared raised mesh, broad scalloped profiles and new SVG | Can pale blue, aged ivory and fine current lines deliver a quieter, faded print? |
| 03 | Paper Theatre | Independent upright cutout wave cards in staggered rows | Can clearly separate stage pieces produce a cohesive ocean with individual motion? |
| 04 | Woodblock Wings | Long overlapping scenic flats, layered sweeping bands | Can larger theatrical compositions reduce tile repetition and frame the bucket? |
| 05 | Ink Diorama | Multiple depths of sculpted paper silhouettes and drawn props | Can a complete miniature paper set unify foreground, character and distant sea? |

Branches use `codex/01-prussian-ink` through `codex/05-ink-diorama`. Worktrees are siblings under `/Users/benedekkoos/projects/ichigo-experiments/`. Each contains its own `documents/experiments/variant.md` with implementation notes, checks and limits.

## Reference research and interpretation

- [Team Lazerbeam's Shroom and Gloom art test](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom) describes placing 2D illustrations in 3D space, then experimenting with color, lighting and animation. Apply this construction principle through original wave and scenery drawings; the game's mushroom assets are not used.
- [Hokusai, At Sea off Kazusa — The Met](https://www.metmuseum.org/art/collection/search/56238) offers a calmer marine reference than the Great Wave. The museum discusses the deep blue foreground echoing the horizon and sky to flatten depth. Apply repeated ink colors and broad horizontal depth bands.
- The user's Great Wave image supplies faded indigo, pale blue, warm paper, engraved contours and curling foam. Adapt these at a modest wave scale; do not recreate its giant wave composition.
- The user's Red Fuji image supplies horizontal ivory cloud ribbons, a restrained printed palette and intentional flat color areas.
- The user's Shipwrecked screenshot supplies overlapping upright wave silhouettes and repeated ornament that remains cohesive across independent pieces.

All new SVG artwork is editable source, not a copied game texture. Generated geometry must support its drawing rather than stretching a tiny pattern across generic glossy 3D water.

## Review procedure

1. Each agent writes its variant plan and implements a runnable branch.
2. Import with Godot 4.7.2 and run checks appropriate to the changed construction.
3. Capture the same calm seed/time and camera angles (12, 20, 26, 38, 52°) through the real game viewport.
4. Inspect silhouette, paper edge, pattern legibility, bucket occlusion, horizon continuity and high-angle gaps. Correct obvious failures before presenting.
5. Show all five in a gallery with matched angle controls and access to the original baseline. Keep runnable launch commands alongside the images.
6. Ask which qualities to retain. Do not merge an artistic winner until the user responds.

This is a visual experiment, not a fishing/inventory/story expansion. Future production work includes weather extremes, movement/recycling, targeting consistency, art coverage for every camera angle and measured performance.

## Next priority after selection

User clarification, 2026-09-06: fish are secondary now. The next visual pass should focus on the ocean's layer cohesion, individual weather-driven motion, coverage throughout 12–52° and bucket framing. Do not expand fishing or block visual refinement on fish visibility/targeting. The hidden gameplay surface remains a documented future integration concern, not the immediate task.
