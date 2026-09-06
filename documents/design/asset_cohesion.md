# Asset cohesion and production plan

## Selected direction — Paper Theatre, 6 September 2026

The user chose Paper Theatre from the five art studies. It is merged into main at `1622c52`: independent upright illustrated crest cards plus separate reclining ribbon cards, weather-driven cell motion, and an ink-colored backdrop. There is no shared visible water mesh. Older requirements below for a matching visible substrate are superseded by this choice. The existing invisible gameplay sampler is retained as a documented approximation; fish and fishing integration are secondary now.

Preserve the selected wave drawings and composition while matching Ichigo and the brown bucket to their paper, ink and palette. Next visual priorities are layer cohesion, convincing motion, repetition, camera coverage at 12–52° and bucket framing. See [the selected study](../experiments/variant.md) and [comparison review](../experiments/showcase_review.md).

## Lower-water pattern simplification — 6 September 2026

The user requested a more homogeneous base after increasing visual panel density. The current branch removes repeated spirals and bright linework from `theatre_ribbon.svg`, using two close blue tones beneath the full-size illustrated crests. See the [full-size crest study](../experiments/full_size_wave_crests.md) for the preserved prior version and rendered review. This is an asset-only refinement; logical cells and panel motion keep their existing contracts.

## Latest water review

The flat sheet water is rejected. Use [raised illustrated waves](raised_paper_waves.md): thin drawings with a rising dark face, pale crest lip and readable upper shoulder. Equal-sided cells organize the simulation, not the visible silhouette. Preserve calm motion, a continuous water substrate and shared crest/buoyancy sampling.

## First prototype review

The solid bucket/child proxies missed the requested art direction. Prioritize layered illustrations in the selected 12°–52° camera range, with a slightly smaller on-screen assembly and browner wood. Water drawings have individual motion and overlapping silhouettes on equal-sided grid cells. Follow the [paper ocean study](paper_ocean_weather.md); low-/medium-poly comparisons below remain later options.

## Dependency and objective

Begin with proxies while the [camera experiment](visual_engine_roadmap.md) is open. Produce the wider asset set only after its supported view range and representation contract are recorded. Every asset must look like it belongs to the same world from every supported angle, including during transitions.

## Identity rules

- Ichigo is a young child of unspecified gender and age. Use plausible child proportions without assigning an exact age. The very oversized sports jersey belongs to their dad and bears a legible, correctly oriented 15. No hat. Hairstyle, jersey colors, footwear, and sport-specific styling remain open.
- The round wooden bucket is large relative to the child. Keep the rim, stave construction, opening, and interior unmistakable. Trial proportions must show small hands, loose jersey folds, and enough interior space without hiding the child at the default angle.
- Use faded indigo, pale blue/teal, warm parchment, ivory clouds, and restrained rust accents. Initial palette: `#183E57`, `#447489`, `#789E9D`, `#E9DDBB`, `#F4EDD6`, `#AE7866`. These are proposed color anchors, not exact sampled pigment values.
- Low-poly and medium-poly variants inherit this palette and composition. Paper texture is optional within those comparisons, but silhouette simplicity and visual restraint remain shared.
- Maintain biologically plausible animal scale, body structure, and movement. A playful representation does not justify arbitrary species behavior.
- The water is calm and deep, with no visible seabed. Paper-water forms must read as low waves rather than solid steps. The sky uses long, broken ivory cloud ribbons against faded blue.

## Shared asset contract

Store these fields in an asset manifest or accompanying resource once production starts:

| Field | Contract |
|---|---|
| Identity | Stable asset ID, version, source file, creator/provenance, usage rights/source references |
| Scale | Meters as engine units; compare against one child/bucket reference scene; physical scale separate from visual exaggeration |
| Coordinates | Godot world Y-up; document source conversion, forward axis, pivots, and texture orientation |
| Anchors | Explicit waterline, center, grip, seat, line attachment, interaction target, and other relevant points |
| Representation | Flat, layered, thin mesh, low-poly, or medium-poly; supported pitch and yaw coverage |
| Materials | Palette roles, grain scale, edge treatment, roughness/highlights, lighting and transparency policy |
| Motion | Idle, movement, interaction and response states; deformation axis, amplitude limits, and bounds |
| Physics | Independent collision/interaction proxy and physical footprint; visual compensation cannot change these |
| Readability | Minimum useful on-screen size, occlusion behavior, target area, color-independent cues |
| Delivery | Editable source plus engine import/export asset; reproducible import settings and preview captures |

Keep geometry budgets provisional until a representative scene is profiled. Export modeled assets through glTF/GLB. Preserve source artwork, meshes, and texture-editing files rather than only exported images. Generated concepts are references unless deliberately processed and validated as usable source assets.

## Cohesion policies to choose in the test scene

Use one sun/light direction and consistent ambient fill. Avoid baking strong contradictory lighting into sprites that will later sit under moving sunlight. Grain belongs to the material/object at a stable scale and should not slide when the camera tilts. Keep line thickness, torn-edge frequency, fold size, and apparent paper thickness consistent at comparable viewing distances.

Establish separate policies for opaque cutout surfaces, translucent atmosphere, and underwater visibility. A full-screen texture filter is not a substitute for coherent materials. Decide whether shadows come from the asset geometry or a simple stable proxy, especially for camera-facing cards. Document acceptable stylization rather than letting each asset solve it independently.

For the bucket, explicitly test rear wall → child/tools → front rim occlusion at low, middle, and high views. Do not resize the gameplay collider to follow a distorted sprite. If visible handles or line attachments move under deformation, their rendered attachment positions must match the tools without altering gameplay reach.

## Initial asset package

| Asset | Required variations | Key acceptance check |
|---|---|---|
| Child | Idle, steering gesture, casting, tending line, observing | Jersey scale and 15 stay readable; no exposed card back or incorrect mirrored text |
| Bucket | Exterior, interior, rim; optional separate staves/folds per style | Looks round and contains the child throughout the tilt range |
| Fishing rig | Rod/handline proxy, lure, float if used, line | Tip/line/hand attachment holds during movement and camera change |
| Fish | Two behavior silhouettes or one species with two prototype profiles | Heading, turn, depth, and response can be read without labels |
| Water | Raised illustrated crest assemblies, shared palette/line weight, coherent overlap | Visible face/lip/shoulder at all approved angles; shared water sampling; no accidental ocean holes |
| Sky | Cloud ribbon family and gradient | Clouds have a shared visual rhythm and plausible parallax |
| Find | One recoverable tool/material and its inventory view | Same object is recognizable in-world and in the pouch |

Inventory depictions should reuse the same asset or a deliberately matched drawing. Do not generate unrelated icons that change material, proportions, or silhouette. Use clear silhouettes before adding ornament.

## Work sequence and acceptance

1. Make a scale/palette sheet and proxy scene using the confirmed child and bucket.
2. Supply cheap assets for R0/R1; record where flat transformations fail.
3. Review the illustrated-panel scene first; supply other style comparisons later if requested.
4. Lock shared materials, view coverage, anchors, and export conventions with the rendering owner.
5. Produce the small package above, integrating each item in the actual camera scene immediately.
6. Review in motion under clear light, overcast, dusk, water overlap, and both pitch endpoints.

An asset is ready when its source is included, imports correctly, uses the agreed anchors/scale/materials, survives the full camera sweep, and supports its interaction. A beautiful single view alone does not pass. Any new asset that requires expanding the camera range or changing the common shader returns to the shared decision process.
