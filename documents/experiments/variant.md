# 04 — Woodblock Wings

Status: isolated visual experiment based on `8255dd4`. The window title is **Ichigo — 04 Woodblock Wings**. Launch this worktree normally; its weather-backed study is enabled by default.

## Plan and rationale

Replace every visible shared water surface with overlapping theatrical scenic flats. Each illustrated wing is 38 metres wide, spanning more than nine of the existing four-metre simulation cells. A fixed 32m × 3m world lattice contains 225 flats (five columns and 45 rows), extending farther behind the player than in front. Each quad inclines 66 degrees backward from upright, so the illustration retains useful horizontal depth at the high camera angle. Overlapping lower edges cover the spaces between crest silhouettes. The lower sky is a matte indigo void.

The original `wing.svg` drawing uses long asymmetric blue silhouettes, three broad cream curling foam gestures, pale azure shoulders, deliberately grouped curved line bundles, and uneven lower cut-paper edges. Offset rows and mirrored variants break direct repetition. This is a calm, shallow sea assembled as a puppet-theatre set. It borrows the vocabulary of woodblock carving without reproducing the monumental Great Wave composition.

Foreground wings keep deep indigo ink. Distance softly shifts the same artwork toward pale azure and finally warm ivory mist. Indigo returns in the upper sky, while ivory horizontal cloud ribbons connect the set's horizontal rhythm to the background. No specular lighting is applied to the sea. Shader fragments with low source alpha are explicitly discarded; remaining fragments use opaque depth, avoiding large black rectangular alpha-scissor artefacts and blended-card sorting.

Each wing independently samples weather at its fixed world anchor. Coarse water height and wave amplitude produce restrained bob and pivot; a deterministic cell seed offsets phase. Wings retained during travel preserve their world coordinates and nodes leaving the window are reused. The camera never drives wave positions. Weather darkening and rainfall remain active.

## Shared boundaries

The existing 1089-cell simulation, 289 near-cell exports, event runtime, targeting, and buoyancy field are unchanged. Both legacy ocean sheets are hidden. The existing near-water presentation is replaced entirely by `woodblock_wings.gd`; no shared water surface remains visible. Camera range remains 12–52 degrees with a default of 20. The brown bucket and hatless child with the oversized blue “15” jersey remain the baseline proxy.

Gameplay uses the invisible illustrated-water sampler. **Collision, fishing targets, and buoyancy are approximate relative to the scenic flats, not exact visual collisions with the new foam silhouettes.** The flats are intentionally a separate scenic representation of the same local weather; their bob is smaller than the hidden crest relief. Do not present this experiment as solving exact illustrated-surface targeting.

## Checks

- Godot 4.7.2 headless editor import: passed.
- `game/tests/woodblock_wings_tests.gd`: 17 checks passed. Covers hidden legacy sheets, replacement near renderer, baseline cell counts, wing dimensions, bounded recycling, retained world anchors, simulation immutability during presentation updates, five camera angles, rain and weather-driven bob.
- `game/tests/weather_simulation_tests.gd`: 128 checks passed, zero failures. Local timing sample: 6.554ms per fixed tick including the original 289 panel exports.
- Existing capture mode remains intact: `--capture-dir=/absolute/path` saves 12°, 20°, 26°, 38°, and 52° views. Root-task captures at 20° and 52° showed legible bold cut-paper waves and no card gaps. A follow-up cut-edge mask softens the square sheet ends; remaining overlap seams are intentional visible scenery joins. This agent has not launched a competing graphical window.

## References

- [Team Lazerbeam, Shroom and Gloom art-test announcement](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom): hand-drawn 2D illustrations placed in three-dimensional environments. Applied here as depth-bearing painted scenery rather than a screen overlay.
- [The Met, Hokusai, At Sea off Kazusa, ca. 1830–32](https://www.metmuseum.org/art/collection/search/56238): the museum describes the repeated deep blue of foreground water and upper sky flattening distance. This informs the repeated indigo with azure and ivory between.
- User-provided Hokusai Great Wave reference: vocabulary of carved foam hooks and curved line groups; its giant wave scale is deliberately not adopted.
- User-provided Hokusai mountain/cloud reference: long broken horizontal ivory cloud ribbons and restrained printing palette.
- User-provided illustrated game-water reference: overlapping wave strips remain legible as a constructed sea.

## Limits and next decisions

The original SVG repeats across the bounded set; the offset and mirroring are useful for this art-direction trial but a final version would benefit from multiple hand-drawn sibling wings. Very low angles compress line detail in the distant rows, and movement across the outer lattice boundary can reveal a new distant row. The sea is explicitly scenic and has no exact mesh collision. Existing tests that assert the baseline near renderer's `_panels` or exact visible raised-wave geometry are baseline-specific; the new scene test checks this variant's actual contract. Final visual approval must inspect all five captures and live calm/strong weather motion.
