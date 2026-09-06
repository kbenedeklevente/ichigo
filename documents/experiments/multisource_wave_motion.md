# Multiple-source sea motion

6 September 2026. Implemented for visual review in the current Ichigo study. The user requested a more turbulent lower sea with independent sources of different strengths whose waves mathematically reinforce and cancel. This is a stylized crossing-sea experiment; artwork and lateral decorative oscillation remain separately owned.

## Signed superposition

`game/world/wave_sources.gd` supplies five world-anchored swell trains to `weather_simulation.gd`. At world position `p`, each contributes:

```text
energy = smoothstep(0.12, 1.05, local_wave_amplitude)
weight_i = lerp(calm_weight_i, tempest_weight_i, energy)
group_i = 0.68 + 0.32 sin(0.23 k_i·p − (0.12 + 0.027 i) primary_phase
                         + 0.018 simulation_time + seeded_group_phase_i)
height_i = local_wave_amplitude × weight_i × group_i
           × sin(k_i·p − rate_i × primary_phase − seeded_phase_i)
target_height = sum(height_i)
```

The primary source has `group_0 = 1` and `seeded_phase_0 = 0`. Its original `(x + 0.28 z) / 24` spatial phase and integrated temporal phase remain exact so storm-breaker cycle eligibility retains its existing meaning. Other direction vectors are normalized before multiplication by `2π / wavelength`.

| Source | World X/Z direction | Wavelength parameter | Phase rate | Calm weight | Tempest weight |
| --- | --- | --- | --- | --- | --- |
| Primary swell | (1, 0.28) | 24 m | 1.00 | 0.720 | 0.46 |
| Cross swell | (−0.17, 1) | 20 m | 1.13 | 0.190 | 0.40 |
| Returning swell | (−0.86, 0.50) | 28 m | 0.91 | 0.035 | 0.34 |
| Opposing diagonal | (−0.36, −0.93) | 18 m | 1.27 | 0.030 | 0.28 |
| Second diagonal | (0.65, −0.76) | 32 m | 0.79 | 0.025 | 0.24 |

These are independent incoming swell sources, represented as extended wave trains rather than finite splash emitters. They cover every travel direction without relocating with the player. Slow envelopes change each secondary source's strength between 36% and 100%, producing shifting patches of reinforcement and cancellation. Equal crest phases add; crest against trough subtracts. No absolute value, maximum, or hard height clipping replaces the signed sum.

The sum of weights is 1 in calm and 1.72 in Tempest, so the target is analytically bounded by `abs(height) ≤ amplitude × 1.72`; at the ordinary Tempest amplitude it is at most 1.806 m. Actual samples are normally much smaller because sources rarely align. Existing event amplitude modifiers can change the amplitude supplied to the same bounded response. Calm preserves a dominant slow swell while opposing directions become substantially stronger with increased wave energy. Source mixing follows the existing smoothed local amplitude, so residual crossing seas remain while a front clears. Sky alone does not force wind or turbulence.

## Runtime contract

- The existing fixed 30 Hz connected spring solve consumes this target. Spring coefficients and damping are unchanged.
- The logical grid remains 33×33, with 4 m cells. Lower drawings and gameplay samples consume the same existing height field; there are no added particles or per-drawing springs.
- Physical `wind_strength`, `wind_x`, `wind_z` and the 0–4 chance coordinate retain their meanings. Height cancellation does not weaken weather eligibility or prevent a maximum-weather breaker.
- Source phases use a separate RNG seeded by `weather_seed XOR 0x57415645`. No weather or scheduler random draws are consumed. Source state is derived from the existing seed, integrated primary phase and simulation clock, so weather snapshots stay version 2 with no new persisted fields.
- Pause stops source evolution with the simulation. Instant weather replacement recalculates the field and increments its revision while preserving time and primary phase. Grid scrolling retains overlapping springs and initializes border cells from the same world-anchored sources.

## Verification and next review

`game/tests/multisource_wave_tests.gd`: 19 checks pass. Tests cover different-strength addition/subtraction, exact opposite-phase cancellation, real reinforced/cancelled spatial patches, analytic bounds, four-direction propagation definitions, seeded variation, evolving envelopes, stronger normalized crossing energy in Tempest, thirty seconds of finite connected-spring motion while scrolling, exact snapshot continuation, pause, instant revisions, unchanged chance coordinates and unchanged cell count.

Regression checks: weather simulation 137, five-level weather 122, instant weather 46. Runtime and storm-breaker regression results are recorded by the integrating agent after completion.

The simulation changes ordinary spring motion and therefore also reaches crest roots and the approximate bucket sampler; it is not a lower-panel-only visual warp. Existing doubled visual motion can exaggerate adjacent panel height differences. Review calm and Tempest in motion at 12°, 20° and 52° for ribbon coverage, bucket readability and whether crossing motion is sufficiently apparent. Numerical checks establish interference and stability; they do not establish visual acceptance.
