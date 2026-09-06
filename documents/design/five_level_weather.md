# Five-level weather and restrained crest heights

6 September 2026. Implemented on `codex/full-size-wave-crests`. The user clarified **ten weather levels total: five sky levels and five wind levels**, with a **2× maximum crest height**, not 10×. They requested lower fully calm crests and a curve that stays low longer before rising faster.

## Levels and study parameters

Each axis uses a continuous strength coordinate from **0 to 4**. Ten named levels do not imply a combined strength of ten: the sum ranges from 0 to 8. Sky and wind still mix independently, giving **25 combinations**.

| Level | Sky | Cloud cover | Rain | Light factor | Wind | Physical strength | Wave amplitude | Wave speed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | Sunny | 0.12 | 0 | 1.00 | Calm | 0.12 | 0.12 m | 0.65 |
| 1 | Cloudy | 0.65 | 0 | 0.73 | Breeze | 1.8 | 0.24 m | 1.00 |
| 2 | Raincloud | 0.88 | 0.58 | 0.49 | Strong | 5.0 | 0.48 m | 1.70 |
| 3 | Storm | 1.00 | 1.00 | 0.26 | Storm | 9.0 | 0.78 m | 2.50 |
| 4 | Tempest | 1.00 | 1.00 | 0.14 | Tempest | 12.0 | 1.05 m | 3.20 |

Tempest is the new study-tier name. Its physical numbers are initial tuning for review. Existing four-tier profile values are unchanged. Rain and cloud coverage remain bounded to one; Tempest sky is darker and has a higher independent strength coordinate. It does not introduce lightning or a new rain asset.

**Controls:** 1–4 sky, 5–8 wind as before; **9 selects Tempest sky**, **0 selects Tempest wind**. All three weather-change modes support the new profiles. Replace-now mode applies them while paused; queued modes respect scheduler admission and locks.

## Crest-height curve

Only upright curling crests use the new curve:

```text
t = clamp((wind_strength_coordinate + sky_strength_coordinate) / 8, 0, 1)
u = 1 - ln(1 + 9 × (1 - t)) / ln(10)
crest_height_scale = 0.35 + (2.0 - 0.35) × u
```

This is a reversed normalized logarithm. Its slope increases with strength, matching “keep crests low longer, then rise faster.” It is finite at both endpoints. Fully sunny/calm crests are 0.35× original height, 30% lower than the preceding 0.5× setting. Both maximum tiers together reach exactly 2×. There is no 10× geometry scale; ten is also the logarithm's input at its opposite endpoint.

| Combined normalized strength | Crest height scale |
| --- | --- |
| 0% | 0.350× |
| 25% | 0.533× |
| 50% | 0.778× |
| 75% — Storm sky + Storm wind | 1.155× |
| 100% — Tempest sky + Tempest wind | 2.000× |

The crest's vertical drawing dimension and submerged root offset scale together around its moving waterline. Width, depth, spacing, artwork identity and the separate doubled spring-motion gain remain unchanged. The lower ribbons retain their previous 0.5×–2× linear height response, with each strength contribution capped at the old Storm level, preserving their coverage. Visual density continues to affect only the lower panels.

## Field, scheduler and persistence contracts

A dedicated `sky_strength` scalar is now part of the fixed weather grid. It blends toward each sky profile's 0–4 value using the same 3-second response constant as the other sky fields. Strength cannot be inferred from cloud coverage because both upper tiers have 100% coverage. Day/night lighting also cannot determine weather severity.

The GPU texture remains 33×33 RGBA float and 17,424 bytes: R spring height, G amplitude, B physical wind strength, A sky strength. The extra scalar in the CPU simulation costs 8,712 bytes for the production grid, excluding temporary snapshots. There are no extra simulation particles or springs. The renderer interpolates the fixed field and applies the crest curve locally as a front moves through the visible grid.

Chance authoring now uses a **5 wind × 4 time** table and five sky weights. Hard wind bounds extend to 4. The fifth sky mixes with Storm using the independent sky-strength field; this also means intermediate sky weights now follow that field rather than being reconstructed from cloud cover. Old profile-anchor probabilities remain unchanged, but intermediate encounter weights can differ from the preceding cloud-derived mapping. The current salvage fixture copies its Storm weights to Tempest as a conservative placeholder.

The nine combinations involving Tempest are **trigger-only** for now. The original sixteen random weather candidates retain their rates and aggregate ceiling; adding the study tier does not introduce an unreviewed automatic-weather frequency or new extreme-weather probability. The new combinations can be assigned chance weights later. The standalone historical event-director catalog remains four-tier; the integrated game uses the expanded scheduler catalog.

Weather snapshot format is now version 2 to require the independent sky field. The expanded catalog also changes the scheduler fingerprint. Previous laboratory snapshots are rejected rather than reinterpreted; prior versions remain recoverable through Git. New joint snapshots restore and replay the fifth-level fields and queued/instant execution correctly.

## Verification and next review

Checks cover all 25 combinations, correct profile coordinates, catalog weights, unchanged random weather rates, fifth-tier interpolation/exclusion, finite spring dynamics, queued execution and deterministic restore. Rendered checks cover 9/0 while paused, GPU field transfer and the 0.35×–2× uniform range. Calm at 20° and Tempest at 12°/52° were captured for review; the lower calm silhouettes and bounded maximum were visually inspected.

Validation: 122 five-level checks, 137 weather checks, 108 scheduler/chance checks, 46 mode checks, 29 runtime checks, 25 encounter/weather checks, 16 rendered mode checks and 90 rendered density checks passed (573 total).

Review the calm baseline and Tempest in motion before further art tuning. Fifth-tier automatic probabilities remain a separate design choice. No change to chance timing, event locks, day/night behavior or the pending lateral-motion design is included.

[Calm preview](../experiments/five-level-weather/calm-paused.png) · [Tempest preview](../experiments/five-level-weather/tempest-52.png)

## Storm breaker follow-up

The selected [Quiet Cut storm breaker experiment](../experiments/storm_breakers.md) adds a temporary 2.35× gain to individual maximum-weather crests, followed by a crash and foam. The 2× cap above remains the ordinary weather-height baseline, not a cap on this newly requested transient. The fixed weather grid, profile values and automatic Tempest probabilities are unchanged. Joint runtime saves now include breakers in version 4, with migration from version 3.
