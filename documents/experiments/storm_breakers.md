# Quiet Cut storm breakers

6 September 2026. **Implemented for visual review on `codex/crest-body-studies`.** The user selected Quiet Cut, then approved its storm counterpart and the proposed maximum-weather activation and elongated splash footprint. Quiet Cut is now the ordinary default; the original and other artwork studies remain available in the optional selector and Git.

## Behavior and initial tuning

At maximum combined weather, all three crest shapes gain a longer, split breaking lip while retaining Quiet Cut's shallow, restrained lower body. Individual crests can grow large, quickly crash, and leave ivory foam rings on the lower water panels.

| Parameter | Initial experiment |
| --- | --- |
| Eligibility | Both local fields near maximum: physical wind ≥11.97 and sky strength ≥3.99 |
| Chance | 1.5% per eligible logical crest's primary swell cycle |
| Global spacing | At least 2.5 seconds between new breakers |
| Concurrent limit | Three lifecycles, including fading foam |
| Rise | 1.6 seconds |
| Peak | 2.35× ordinary local crest height; maximum ordinary scale remains 2× |
| Crash | 0.38 seconds, with forward shear and collapse to 0.08× ordinary height |
| Recovery | Begins 0.3 seconds after impact and returns to ordinary height over one second |
| Surface foam | Spreads over 0.85 seconds; fully retired 3.8 seconds after impact |
| Footprint | 8×12 world units, equivalent to 2×3 logical cells; irregular elliptical falloff |

Timing, probability and transient exaggeration are initial tuning for this authorized experiment, not final balance. Both maximum tiers mean **Tempest sky + Tempest wind**; named Storm + Storm is only 75% combined strength and cannot start breakers. The narrow endpoint tolerance accommodates exponential field convergence. Storm artwork blends in just below the eligibility threshold to avoid a hard texture pop. A transition may pass through the eligible range only briefly; this does not add automatic Tempest probabilities to the scheduler.

## Ownership and grid contract

`game/world/storm_breakers.gd` owns the lifecycles and is advanced by `EnvironmentRuntime` after each fixed 30 Hz weather step. It follows the existing primary swell phase at each stable logical anchor. Only a newly crossed cycle can roll. A separate seed keyed by world cell and cycle keeps draws independent of the scheduler/weather random streams. Admission also requires capacity, cooldown expiry and no existing breaker at that anchor. Blocked crossings are discarded rather than queued.

The tracked window is the 17×17 logical crest region around the player, independent of camera angle and visual density. Newly entered anchors are primed at their current cycle, preventing a roll merely from entering the window. The cycle map is replaced each step and stays bounded; active effects finish at their original world positions. Moving the player can change the candidate window. Decorative breakers are not simulated across the entire distant weather region.

The renderer consumes at most three records: crest anchor, gain/lean, crash direction and foam spread/fade. No per-frame chance rolls, per-visual-tile state, new springs, or extra ocean mesh are introduced. The logical weather field remains 33×33 with 4-unit cells. The existing height scale and submerged-root offset grow together; collapse shears only the exposed crest in the captured local wind direction. Conservative vertical bounds were expanded to include the transient peak.

At impact, the foam footprint begins near the crest's staggered root, offset three units along the crash direction. The longer footprint axis follows that direction. Lower-panel fragments sample the continuous world-space footprint and a varied ring pattern. The surface drawing retains its original opacity and base color underneath; rings are composited into it. Increasing density changes ring spacing/detail, not footprint extent, crest count, chance, or physics resolution. Lower densities contain fewer larger rings. Foam is masked around the bucket by the existing dry-hull exclusion.

These are decorative weather phenomena, not encounter events. They do not reserve weather/encounter slots, alter chance scheduling or release encounter locks. **No new bucket impulses, collision, damage or fluid-volume simulation is included.** The invisible gameplay water sampler remains the existing approximation. A natural weather change stops new rolls when local conditions leave the maximum range; existing breakers finish. Laboratory Replace-now clears active breakers and foam immediately, including while paused.

## Assets and launch

The earlier staged SVG Hokusai experiment was reverted. The user subsequently selected **the first standalone generated sprite (A)** to replace the maximum-storm asset. Live maximum-storm crests now use `game/presentation/waves/storm_sprite_a_extended.png` in all three shape slots, retaining existing per-anchor mirroring and motion. Ordinary Quiet Cut remains in use below the narrow maximum-weather art transition. There is no height-based stage switching.

The original `storm_sprite_a.png` is an unchanged copy of `wave-sprite-candidates/source-a-opaque.png` (1774×887), retained for comparison. The active sibling is a generated edit of that sprite: its blue body extends downward into a wide rectangular foundation with straight sides and bottom. It keeps the same canvas and broadly preserves the crown, with minor generated variations. The maximum-storm root depth blends from 1.65 to 1.35 times local crest scale, raising the crown by 0.6 world units at ordinary maximum strength. The foundation remains submerged; root placement still scales with breaker growth and collapse. Width, spacing, lower panels and logical physics are unchanged. The image generator baked a near-neutral pale checkerboard into it rather than alpha. The game material keys that backdrop out using linear-RGB saturation/lightness; colored ivory foam and blue ink remain opaque. No CPU bitmap edits were applied and the PNG must not be represented as a standalone RGBA cutout. This key is specific to the selected source and is not applied to ordinary SVG assets or surface foam. Future art with neutral white content needs its own transparency review.

The thick-black `storm_quiet_cut/` crest sources and the rejected `storm_growth/` atlas are historical comparisons. The separate ivory `surface_foam.svg` still supplies crash rings.

The independently requested [five-source turbulence](multisource_wave_motion.md) is retained: signed swells from different directions reinforce or cancel on the existing weather grid. Its primary phase still drives breaker cycle checks. This artwork revert does not undo the physics change.

The lower-panel default is now **4× per side**, twice the previous 2× starting density (four times as many lower panels), and the detail slider extends to **16×**. At that limit, 0.25-unit lower panels total 73,984, alongside the same 289 full-size crests. No new particles or springs are stored. Foam ring spacing can follow the finer detail down to 0.25 units; its world-space footprint remains fixed.

```sh
./scripts/run_game.sh --resolution 1280x800 -- --storm-breakers
```

This review launch starts at Tempest/Tempest with Replace-now selected and disables automatic scheduler chance so the weather stays suitable for inspection. Breaker chances remain active. Ordinary launches retain normal scheduler behavior and calm initial weather. Existing keys 1–0, pause, camera and density controls still work; 9 selects Tempest sky and 0 selects Tempest wind. No forced or guaranteed breaker is inserted into the live demo.

## Persistence

Joint laboratory snapshots now use version 4 and include bounded breaker state, cycle history, seed, counters and clock. Existing version-3 snapshots migrate with no active breakers; their already elapsed wave cycles are not replayed. Version 4 restores reject malformed breaker data atomically and validate the shared weather clock. Weather/scheduler formats and independent RNG streams are unchanged.

## Verification and review limits

Passed 21 breaker contract checks, 162 rendered-study checks, 29 environment runtime checks, 108 scheduler/chance checks and 122 five-level weather checks. Checks cover maximum-only admission, bounded state, repeated-render/pause invariance, seeded continuation, snapshot migration, immediate replacement, renderer uniforms, preserved crest count and unchanged field resolution.

The rendered fixture samples normal/peak/crash/foam at 12°, 20° and 52°, and densities 1, 2 and 8. Peak at 20° and foam at 52°/density 8 were visually inspected: the raised silhouette and ring patch are present; large foreground crests can occlude the bucket at low angles. This is an outstanding visual/readability review, not an accepted final result. A live maximum-weather demo was launched without runtime errors observed at startup.

On the Apple M2, a short paused 1280×800 Compatibility-renderer sample at 52° measured median/p95 frame intervals of 12.0/14.4 ms at density 2 with one foam patch, and 13.0/16.0 ms at density 8. Matched no-effect samples were 11.1/13.3 and 14.8/19.1 ms respectively. These noisy samples do not establish an isolated effect cost or guarantee 60 fps for moving gameplay or three simultaneous patches.

Run `game/tests/storm_breaker_tests.gd` headlessly and `game/tests/storm_breaker_visual_study.gd` with rendering to reproduce. The latter uses a fixed crest fixture to capture exact lifecycle phases; it does not demonstrate random event frequency.

[Storm asset](storm-breakers/curl.png) · [Peak at 20°](storm-breakers/peak-20-density2.png) · [Surface foam at density 8](storm-breakers/foam-52-density8.png)

Next: user review of peak size, crash speed, foam visibility and low-angle bucket occlusion before further visual or gameplay changes.

Historical captures linked above precede the black-band and five-source-motion changes; previous timings do not cover the new 16× limit. The finer-density renderer passed 170 contract checks. The turbulence agent reported 374 passing checks across interference, weather, fifth-tier, instant-weather, joint-runtime and breaker suites.

## Selected generated sprite verification

Sprite A integration passed 166 rendered-study checks at camera angles 12°/20°/52° and lower-panel densities 1×/4×/16×. The selected texture, unchanged crest count, fixed physics field, and pause-safe rendering were checked. Normal Tempest at 20° and a peak at 52° were inspected: the checkerboard is removed by the material key; fine foam detail remains demanding at a distance. The key was tightened to preserve more pale foam. PNG mipmap generation was then enabled for distance filtering, reimported successfully, and the live maximum-Tempest demo relaunched. Stored captures precede that final filtering change; review its in-motion appearance in the demo.

## Extended rectangular base review

The requested generated extension and storm-only root lift passed 166 rendered-study checks with mipmaps enabled, at 12°/20°/52° and densities 1×/4×/16×. Captures are in `extended-storm-sprite/`. Normal maximum-weather views at 12° and 20°, plus the 52° peak fixture, were visually inspected: the rectangular foundation stays beneath the lower panels and the crown rises higher. Low-angle crests can still hide the bucket; this remains a user-review concern. No checkerboard rectangle was visible in these inspected frames. The original sprite and its earlier captures are retained for comparison.

## Next-session decision

User instruction, 6 September 2026: use the current extended-base asset (`game/presentation/waves/storm_sprite_a_extended.png`) for the waves that grow large, crash and create surface bubbles/foam. **Recorded for later implementation only.** The current renderer still applies this asset to every crest at maximum combined weather. Next session, tie selection of this artwork to the individual breaker lifecycle rather than the weather-wide art blend, retaining the existing crash and bubble footprint. The artwork for non-breaking maximum-weather crests and exact asset-switch timing remain to be confirmed with the user; do not silently choose them.
