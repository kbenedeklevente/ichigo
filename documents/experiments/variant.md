# 03 — Paper Theatre

Selected by the user on 6 September 2026 and merged into main at `1622c52`. This renderer makes the visible sea out of 289 upright illustrated crest cutouts and 289 broad, reclining scenic ribbons. Each card is a rigid XY quad with a transparent die-cut silhouette, placed in a staggered 17 × 17 grid. Both original ocean planes are hidden in weather-study mode. The reclining ribbons overlap in depth between crest rows; an ink-blue matte lower sky hemisphere backs small residual gaps. There is no visible connected water mesh beneath the cards.

Three original SVG drawings explore a hooked breaker, paired curls, and a long sweeping crest. Their indigo shadows, ivory foam outlines, small spiral foam marks, and parallel engraved flow lines are authored in the artwork. Row overlap, asymmetry, occasional reflected drawings, and restrained changes in scale make a puppet-stage arrangement. Alpha scissor and opaque depth drawing remove transparent rectangular sorting artifacts. The cards receive weather illumination without atmospheric haze washing out their ink.

Each foot follows twice its own cell's signed spring height after the user's vertical-motion adjustment, with its pivot driven by that cell's simulated slope. Neighbor coupling and incoming fronts remain owned by the existing 33 × 33 weather simulation. Artwork never slides through a shared displacement field. Rain, encounter logic, pause, replay, and the 12°–52° camera (20° default) remain operational. The child with oversized number-15 jersey, no hat, and brown open bucket remains a matching layered-illustration study.

## References and decisions

- [Shroom and Gloom art test](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom): its explicit use of drawn 2D illustrations in 3D space informs the rigid cutout construction and readable artwork. No game assets are copied.
- The user's Don't Starve: Shipwrecked screenshot: repeated curling wave rows inform coherent lateral overlap and staged depth.
- [Hokusai, At Sea off Kazusa, ca. 1830–32, The Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/56238), plus the user's supplied wave references: deep blue water and a repeated ink horizon inform the palette; curling contour lines and pale foam inform the three original drawings.

## Gameplay approximation and limits

The retained `illustrated_water_surface.gd` is invisible. Buoyancy, normals, targeting, fish positions, and encounters use its preexisting continuous height field. Decorative upright cards are not colliders and cannot be represented by a single-valued height map. A card's visible crest therefore does not equal its collision height; casting through scenery still targets the underlying gameplay sea. The bucket has a small shader cutout to keep its interior dry.

This stage is designed for the existing fixed camera azimuth, not free orbit. After the first 20°/52° capture review exposed large gray gaps, the second pass added separate low ribbon cards, reduced calm crest height, and changed the lower matte backing to ink blue. Root reviewed fresh 12°, 20° and 52° captures after the coverage fix. The finite 17 × 17 boundary and reuse of four drawings are study limits. Matching illustrated bucket/child art is implemented for review; see [character study](paper_theatre_character.md). Launch with `-- --weather-study`; the selected scene is also the default; the legacy fixture uses `--camera-baseline` for its existing camera contract tests. Capture arguments and deterministic capture flow are preserved.

## Verification

Headless editor import passed. Paper-card geometry/weather/pause checks: 18 passed. Weather scene integration checks: 16 passed. Weather simulation checks: 128 passed. `git diff --check` passed. Rendered aesthetic acceptance requires the coordinated root-agent angle captures; this agent does not launch graphical Godot.
