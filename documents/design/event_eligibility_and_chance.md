# Event eligibility and chance authoring

6 September 2026. Documented at the user's request. This is the recommended authoring model from the discussion, not a claim that the matrix schema or coordinator is implemented. Content examples and new balance values require review. Existing approved pacing remains in force.

## Three separate questions

1. **May this event happen?** Eligibility predicates give a yes/no answer: prerequisites, tools if actually available, story flags, completion/repetition policy, cooldowns and hard environmental exclusions.
2. **How likely is it under these conditions?** A base occurrence rate is multiplied by a wind × time-of-day table and a separate sky modifier.
3. **Can it start now?** The coordinator checks activity ownership, quiet time, weather stability and linked reservations. Eligibility does not grant permission to interrupt an active encounter.

Keep definitions as data. The proposed [coordinator](weather_encounter_scheduler.md) owns admission and chance evaluation; weather and encounter handlers execute admitted work. The weather simulator owns front progress, phase duration and physical response. Chance frequency does not set weather-transition speed.

## Definition shape

| Field | Meaning |
|---|---|
| `id`, `activation`, `domain` | Stable identity; trigger/chance/both; weather or encounter |
| `eligibility` | Hard prerequisites and exclusions, including cooldown/repetition rules |
| `base_rate_per_second` | Hazard per second of eligible scheduling time at weight 1 |
| `wind_time_weights` | Four wind rows, four cyclic time anchors: dawn/day/dusk/night |
| `sky_weights` | Separate sunny/cloudy/raincloud/storm multipliers |
| `payload` | Requested weather or encounter content; linked requests reference both |

Wind rows are 0 calm, 1 breeze, 2 strong, 3 storm. They refer to the proposed normalized wind intensity, not the current physical wind-strength values or animation oscillation counts. Continuous interpolation must not silently replace the physical wind units.

An illustrative table for a daylight drifting-object encounter follows. These numbers are examples, not selected balance or natural-frequency claims.

| Wind | Dawn | Day | Dusk | Night |
|---|---:|---:|---:|---:|
| 0 — calm | 0.5 | 1.0 | 0.5 | 0 |
| 1 — breeze | 1.0 | 1.5 | 1.0 | 0 |
| 2 — strong | 0.5 | 0.8 | 0.5 | 0 |
| 3 — storm | 0 | 0 | 0 | 0 |

The entries are **relative weights, not percentages**. A 1.5 means 1.5 times the base hazard before the pacing cap. Proposed sky weights might be sunny 1, cloudy 1, raincloud 0.5, storm 0. This still allows combinations such as sunny strong wind or cloudy calm water.

`raw_rate = base_rate_per_second × wind_time_weight × sky_weight`

Interpolate ordinary weights between adjacent wind levels and cyclic time anchors, including night → dawn. A zero at a sampled anchor produces zero there, but interpolation toward a positive neighbor produces a positive value. If an event must never occur throughout a condition or interval, express that as a hard exclusion, evaluated before interpolation. Define time-anchor positions and exclusion thresholds during implementation review; do not assume a full day/night cycle already runs.

For encounter selection, sample settled local weather near the player from the **base** simulation. Encounter-local departure gusts must not feed back into future event probability. If an event explicitly needs effective local conditions, declare that dependency. Do not evaluate against the incoming weather's final target while its front is still approaching. New encounter admission is blocked during that transition anyway.

For a weather candidate, the weights describe its likelihood under the **current** conditions; its payload describes the destination conditions. This avoids making storm arrival require an existing storm. Candidate filtering can express allowed transitions without forcing sky and wind into matching pairs.

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

Weather has a **separate** pacing budget and transition gates. The encounter ceiling is not a universal weather timer. Existing study weather definitions each use rate 1/960 s across sixteen combinations, before eligibility/cooldowns; this is temporary study balance, not a newly approved weather cadence. The proposed two-entry weather queue still has an unresolved active-versus-waiting capacity definition.

## Percentages for authoring and debugging

For constant conditions, `p(dt) = 1 - exp(-rate × dt)`. If designers prefer a standalone probability over 60 eligible seconds, convert with `rate = -ln(1 - P60) / 60`, where `P60` is a fraction in [0,1). It is not the final probability after competition and caps.

At the approved aggregate ceiling, the chance of any encounter is about 0.416% per eligible second or 2.062% per five eligible seconds. These intervals describe the same constant-condition distribution. Variable conditions require integrating/summing hazard over their eligible durations; changing sample frequency can otherwise change results. A mean eligible wait is not a deadline. Active events, weather transitions and quiet periods lengthen actual elapsed time between encounters.

Debug output should expose exclusion reasons, base rate, sampled weights, raw/limited aggregate rate and selected candidate. Keep that information out of normal gameplay UI.

## Triggers, outcomes and persistence

Story and other explicit triggers bypass the random roll, not prerequisites or scheduling locks. Linked weather + encounter requests reserve both tracks atomically, allow weather to approach, then start the encounter when established. An unstarted reservation must not freeze its own weather approach. Whether story requests bypass post-encounter quiet time remains a separate policy decision.

Dispatch, successful interaction, offscreen departure and narrative completion are different outcomes. Do not award an achievement or story milestone merely because an opportunity spawned. Preserve seeded chance state, cooldowns, pending IDs, reservations and active lifecycle state through save/restore; rendering frame rate must not consume chance RNG.

## Implementation boundary and next steps

Already implemented: generic triggered/chance weather definitions, weather lifecycle execution, a separate salvage-only chance path with sky/wind multipliers, quiet time, encounter locks and seeded state. The salvage chance path currently reads categorical environment status. It does not implement this four-by-four time table, interpolated wind intensity, a unified coordinator or a full time-of-day presentation.

1. Review the [starter opportunities](starter_event_ideas.md) and choose one small prototype; keep all others as proposals.
2. Confirm outstanding coordinator and wind-intensity contracts before dependent implementation. A manual daytime weather demonstration can reuse the existing engine without resolving every future system.
3. Add definition validation and pure rate evaluation; keep current approved pacing and a fixed daytime sample until time progression is deliberately introduced.
4. Integrate selection with the reviewed coordinator. Verify hard zeros, independent sky/wind mixtures, cap behavior, blocked-time handling, trigger revalidation and deterministic restore. Compare tick durations under constant conditions with meaningful statistical/tolerance checks.

See [encounter fields and pacing](encounter_fields_and_pacing.md) for lifecycle/modifier ownership and [shared event system](event_system.md) for activation/outcome semantics.
