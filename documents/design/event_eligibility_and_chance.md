# Event eligibility and chance authoring

6 September 2026. Implemented at the user’s request before starter-content work. `event_chance.gd` validates/evaluates definitions; `environment_scheduler.gd` owns chance admission. Illustrative content weights below remain unselected. Existing salvage balance is preserved at profile anchors and existing approved pacing remains in force.

## Three separate questions

1. **May this event happen?** Eligibility predicates give a yes/no answer: prerequisites, tools if actually available, story flags, completion/repetition policy, cooldowns and hard environmental exclusions.
2. **How likely is it under these conditions?** A base occurrence rate is multiplied by a wind × time-of-day table and a separate sky modifier.
3. **Can it start now?** The coordinator checks activity ownership, quiet time, weather stability and linked reservations. Eligibility does not grant permission to interrupt an active encounter.

Keep definitions as data. The [coordinator](weather_encounter_scheduler.md) owns admission and chance evaluation; weather and encounter handlers execute admitted work. The weather simulator owns front progress, phase duration and physical response. Chance frequency does not set weather-transition speed.

## Definition shape

| Field | Meaning |
|---|---|
| `id`, `activation`, `domain` | Stable identity; trigger/chance/both; weather or encounter |
| `eligibility` | Hard prerequisites and exclusions, including cooldown/repetition rules |
| `base_rate_per_second` | Hazard per second of eligible scheduling time at weight 1 |
| `wind_time_weights` | Four wind rows, four cyclic time anchors: dawn/day/dusk/night |
| `sky_weights` | Separate sunny/cloudy/raincloud/storm multipliers |
| `payload` | Requested weather or encounter content; linked requests reference both |

Wind rows are 0 calm, 1 breeze, 2 strong, 3 storm. They refer to a derived normalized wind coordinate, not physical force or animation oscillation counts. `weather.chance_context(point)` maps interpolated base scalar strengths 0.12/1.8/5/9 to 0/1/2/3 without changing those physical units or the unresolved visual-oscillation design.

An illustrative table for a daylight drifting-object encounter follows. These numbers are examples, not selected balance or natural-frequency claims.

| Wind | Dawn | Day | Dusk | Night |
|---|---:|---:|---:|---:|
| 0 — calm | 0.5 | 1.0 | 0.5 | 0 |
| 1 — breeze | 1.0 | 1.5 | 1.0 | 0 |
| 2 — strong | 0.5 | 0.8 | 0.5 | 0 |
| 3 — storm | 0 | 0 | 0 | 0 |

The entries are **relative weights, not percentages**. A 1.5 means 1.5 times the base hazard before the pacing cap. Proposed sky weights might be sunny 1, cloudy 1, raincloud 0.5, storm 0. This still allows combinations such as sunny strong wind or cloudy calm water.

`raw_rate = base_rate_per_second × wind_time_weight × sky_weight`

Interpolate ordinary weights between adjacent wind levels and cyclic time anchors, including night → dawn. A zero at a sampled anchor produces zero there, but interpolation toward a positive neighbor produces a positive value. If an event must never occur throughout a condition or interval, express that as a hard exclusion, evaluated before interpolation. Time anchors follow the existing daylight convention: dawn 0, day 0.25, dusk 0.5, night 0.75. Hard excluded time ranges use half-open cyclic intervals; wind min/max are inclusive. Definitions supply their own exclusions. The current game still holds daytime at 0.25; every enabled definition has equal time-column weights, so this does not activate a new day/night cycle or invent time balance.

For encounter selection, sample local weather near the player from the **base** simulation during idle/hold. Encounter-local departure gusts must not feed back into future event probability. Effective-field eligibility is not currently supported; adding it requires an explicit dependency. Do not evaluate against the incoming weather's final target while its front is still approaching. New encounter admission is blocked during that transition anyway.

For a weather candidate, the weights describe its likelihood under the **current** conditions; its payload describes the destination conditions. This avoids making storm arrival require an existing storm. Candidate filtering can express allowed transitions without forcing sky and wind into matching pairs. Sky weights interpolate from base cloud cover across the existing profile anchors 0.12/0.65/0.88/1.0. Hard sky exclusions use the nearest of those categories; they do not use the incoming target. This is a compact authoring coordinate, not a new weather simulation.

## One encounter roll, then one selection

Keep the existing one-second scheduling cadence and separate 30 Hz physics. For eligible encounter candidates with raw rates `r_i`:

```text
S = sum(r_i)
B = 1 / 240                         # approved encounter hazard ceiling
R = min(S, B)
p_any = 1 - exp(-R * eligible_dt)
if S > 0 and seeded_roll() < p_any:
    choose one candidate with probability r_i / S
    recheck prerequisites and allocate atomically
```

No eligible candidates means no random encounter. Preserve 90 seconds of guaranteed quiet after departure, per-family cooldowns and the one-encounter lock. Do not count blocked time as eligible time or release a burst of missed rolls when a lock ends. Random proposals do not build a backlog. Explicit requests may wait and must be revalidated before allocation.

The cap prevents a larger catalog from exceeding the approved encounter density. Below the cap, adding candidates can still increase total frequency. A future fixed opportunity rate with purely relative selection weights would eliminate that effect, but would change the existing pacing model and needs review.

Weather has a **separate** pacing budget and transition gates. The encounter ceiling is not a universal weather timer. Existing study weather definitions each use rate 1/960 s across sixteen combinations, before eligibility/cooldowns; this is temporary study balance, not a newly approved weather cadence. The confirmed capacity is two weather-bearing requests total, including active. Weather has a separate 1/60 eligible-second aggregate ceiling, preserving the sixteen-profile study ceiling; cooldowns lower the available total. Weather chance is checked before encounter chance at a shared tick; a newly admitted front closes encounter admission for its approach.

## Percentages for authoring and debugging

For constant conditions, `p(dt) = 1 - exp(-rate × dt)`. If designers prefer a standalone probability over 60 eligible seconds, convert with `rate = -ln(1 - P60) / 60`, where `P60` is a fraction in [0,1). It is not the final probability after competition and caps.

At the approved aggregate ceiling, the chance of any encounter is about 0.416% per eligible second or 2.062% per five eligible seconds. These intervals describe the same constant-condition distribution. Variable conditions require integrating/summing hazard over their eligible durations; changing sample frequency can otherwise change results. A mean eligible wait is not a deadline. Active events, weather transitions and quiet periods lengthen actual elapsed time between encounters.

Debug output should expose exclusion reasons, base rate, sampled weights, raw/limited aggregate rate and selected candidate. Keep that information out of normal gameplay UI.

## Triggers, outcomes and persistence

Story and other explicit triggers bypass the random roll, not prerequisites or scheduling locks. Linked weather + encounter requests reserve both tracks atomically, allow weather to approach, then start the encounter when established. An unstarted reservation must not freeze its own weather approach. Story requests currently obey the existing post-encounter quiet interval. A future bypass would be a separate policy change.

Dispatch, successful interaction, offscreen departure and narrative completion are different outcomes. Do not award an achievement or story milestone merely because an opportunity spawned. Preserve seeded chance state, cooldowns, pending IDs, reservations and active lifecycle state through save/restore; rendering frame rate must not consume chance RNG.

## Implementation boundary and next steps

Implemented: catalog validation, hard flag/wind/sky/time exclusions, four-by-four wind/time interpolation, independent sky interpolation, separate weather/encounter budgets, one weighted selection per domain, and scheduler persistence. Rates are integrated on the 30 Hz world step and rolled once per eligible second. Blocked time consumes no chance RNG and clears partial opportunities instead of producing a backlog. Hard-ineligible candidates are removed before selection.

`event_catalog.gd::scheduler_definitions()` converts the existing sixteen weather definitions and salvage probabilities. Salvage still has no new gameplay interaction. Its old profile-anchor rates are preserved exactly; interpolation adds smooth behavior between anchors. The integrated game calls the encounter handler in managed mode, so its old standalone chance/trigger queue does not also run.

Validation and implementation limits are recorded in the [scheduler review](../work_packets/scheduler_chance_implementation.md). Day/night presentation, richer predicates and content-specific balance remain future work. The [starter opportunities](starter_event_ideas.md) remain proposals; implement one only after the user selects it.

See [encounter fields and pacing](encounter_fields_and_pacing.md) for lifecycle/modifier ownership and [shared event system](event_system.md) for activation/outcome semantics.
