# 05 · Ink Diorama

Status: isolated, unselected visual proposal on `codex/05-ink-diorama`, based on `8255dd4`. This experiment overrides the baseline's visible continuous-substrate requirement only here; it does not change accepted main-game art direction.

## Intent and composition

An open ocean assembled as a miniature paper theatre: original asymmetrical whorl drawings in the foreground, calmer carved ribbons around the child, and thin pale linework in the distance. Faded indigo, pale blue and aged ivory tie the sea to the original child and warm brown wooden bucket. The larger curves remain small scenic motifs, never a giant breaking Great Wave.

Every near-water prop has its own shallow asymmetric hinge mesh, independent pivot, lateral placement and weather-driven height/tilt. The 289 rendered weather cells still feed 289 near props; the simulation remains the unchanged 33 × 33 field. Eight rows of independent distant illustrated props overlap beyond the near field. No shared visible near/far water mesh survives. The lower sky hemisphere has an ink-blue atmospheric fill so the space beyond the miniature scenery does not expose gray sky. This is intentionally theatrical depth, not a physically exact ocean.

The child and bucket are fully replaced with original editable SVG artwork. Separate interior, child and front-wall drawings preserve layered containment. The child has no hat, an unspecified gender, small hands, and dad's very oversized jersey with an original path-drawn, correctly oriented 15. The bucket retains its brown staves, bands, oversized rim and wood-grain gouges. Old child/bucket geometry is no longer instantiated. The existing simulation root, waterline, collision body, grip and rod-tip interfaces remain.

The camera stays at 12°–52°, defaults to 20°, and retains the baseline focus, distance and framing. The five-angle capture mode remains intact. Weather controls, independent sky/wind axes, simulation and event state remain unchanged; original rain effects are retained with their old water batch hidden. Default launch now opens this experiment directly.

## References and interpretation

- [Team Lazerbeam's Shroom and Gloom art-test account](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom) describes drawings placed in 3D space with color and animation. This supports the paper-theatre construction; it does not document that game's water or collision implementation.
- [Hokusai, At Sea off Kazusa, The Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/56238), circa 1830–32: layered blue water, strong graphic contours and restrained distant forms. The six SVG files in `game/presentation/ink/` are original authored vector drawings, not traced or copied reference assets.
- User-provided visual references are part of this session's art brief. The experiment emphasizes flat illustrated scenic props rather than solid volume, small repeated upright cards, or uninterrupted long horizontal bands.

## Validation and limits

Godot 4.7.2 headless editor import succeeded. Headless scene startup succeeded. All 118 camera/ocean contract checks passed. These establish import/runtime and baseline math health; they do not approve appearance. Graphical capture and motion review are coordinated by the parent task.

The baseline invisible `illustrated_water_surface.gd` sampler still drives buoyancy, reach and target rays. **Collision/targeting is approximate relative to the independent visible cards**, not exact relief matching. Artistic clearance lowers nearby paper beneath the bucket; that does not change physical reach. Near drawings change motif across distance bands, and distant scenery follows the player as theatrical scenery. These are explicit experiment limitations to review during movement. The rendering uses separate instances and shared materials; performance is not profiled. Fish and salvage remain baseline interaction assets and are outside the child/bucket replacement scope.

Next review: all five pitches, continuous tilt, steering across cell borders, low-angle horizon overlap, calm-to-wind transition, and rod/target visibility. Selection remains the user's decision.
