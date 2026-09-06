# Scheduler and chance implementation review

6 September 2026. Implemented before starter-content work, as requested. The user selected a maximum of **two weather-bearing requests total, including active weather**.

## Result

The integrated game uses `environment_scheduler.gd` as its sole admission owner. It tracks optional weather/encounter requests in one collection, reserves linked requests atomically, starts required weather before the encounter, and holds weather transitions through actual encounter/departure. Existing laboratory weather keys and salvage requests route through it. Weather interpolation, physical grids, illustrated ocean assets and salvage actor behavior remain in their existing handlers.

`event_chance.gd` validates and evaluates base rates, a 4×4 wind/time table, independent sky weights and hard flag/wind/sky/time exclusions. The scheduler integrates eligible hazard on the fixed world step and rolls at one-second intervals, selecting one candidate by relative hazard. Encounter pacing retains 90 seconds of quiet and the 1/240 eligible-second aggregate ceiling. Weather retains the sixteen-combination study rates with its own 1/60 ceiling. All current time columns are neutral and daylight remains held; salvage rates match the previous implementation at every sky/wind profile anchor.

Requests have stable identities separate from definition IDs. A distinct linked story request can wait for the same repeatable weather/encounter definitions that are currently active. Convenience laboratory triggers still suppress duplicate button requests. Per-definition cooldown and once-only rules are rechecked at allocation. A full queue or invalid pair never mutates half a request.

## Validation

Executed using `/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2) on the local Mac:

| Suite | Result | Evidence |
|---|---|---|
| `environment_scheduler_tests.gd` | 108 passed | Capacity, atomic pairs, repeated definitions with distinct request IDs, preparation/hold, safe bypass, story drain, cancellation, prerequisites/cooldowns/once, matrix interpolation/hard zeros, hazard ceiling, weighted statistical check, snapshots and real linked handlers |
| `environment_runtime_tests.gd` | 29 passed | Weather handler routing, complete lifecycle, cooldown, fixed-step frame partition and deterministic restore |
| `encounter_weather_tests.gd` | 25 passed | Established-weather encounter, queued weather lock, continuing physics, modifier composition, offscreen retirement and quiet time |
| `encounter_runtime_tests.gd` | 197 passed | Existing standalone actor fixture, spatial/lifecycle/state checks |
| `weather_simulation_tests.gd` | 128 passed | Existing grid, front and connected physical simulation |
| `weather_scene_tests.gd -- --weather-study` | 16 passed, rendered with OpenGL | Paper Theatre scene, near/far grid counts, weather/rain/light integration, camera targeting and pause |

The new suite also checks all sixteen existing salvage profile-anchor rates, a local gust not altering base-weather chance input, and save/restore during linked preparation, active encounter and weather tail. Catalog/payload and inconsistent-owner snapshot rejection are atomic. Documentation links and `git diff --check` are part of the final repository verification.

Reproduction:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script game/tests/environment_scheduler_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script game/tests/weather_scene_tests.gd -- --weather-study
```

## Limits and next work

- Runtime snapshot version 3 rejects old laboratory version-2 snapshots explicitly. There are no released player saves to migrate; an old director queue is never silently discarded during restore.
- Only the existing salvage handler is registered for encounters. New families need their own actor/persistence integration and registration; the starter ideas remain proposals.
- Day/time weights are supported, but a complete day/night visual cycle and non-neutral content balance are not introduced here.
- Cancelling preparation lets already-started weather complete its normal lifecycle/clear; it does not instantly dissolve a front or teleport its center. Live encounters resolve and depart through their handler.
- A linked encounter waits for actual local eligibility during the front's finite hold. If requirements disappear, or clearing begins first, the unstarted encounter is cancelled without narrative completion.
- The derived 0–3 wind coordinate is for authoring. It does not resolve or alter the pending side-to-side wave animation frequency/amplitude choices.
- Standalone `event_director.gd` and the older salvage chance methods remain study utilities. The integrated runtime uses neither as a second chance owner.

The next user decision is which starter content, if any, to prototype. This change implements infrastructure only.
