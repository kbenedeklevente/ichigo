# Coordinating weather and encounters

6 September 2026. Implemented at the user’s request. The user confirmed the weather capacity is **two total, including active weather**. The coordinator wraps the existing weather and salvage handlers; no starter content is enabled by this change.

## Weather execution modes — 6 September 2026

The study now supports normal transitions, queued instant execution and explicit laboratory replacement. Future event definitions may set `payload.instant = true` without bypassing admission or encounter locks. Only the manual replacement mode interrupts active/waiting weather. See [weather algorithm review](weather_algorithm_review.md) for exact semantics, baseline behavior, cancellation and automatic selection analysis.

## Problem and existing foundation

Weather and encounters need independent scheduling, with linked story requests able to require both. Independent queue heads and partial allocation could leave weather waiting for an encounter while the encounter waits for weather. Ordinary eligible requests should be able to pass a blocked request without interrupting an active one.

The game runs weather approach/hold/clear lifecycles and a salvage encounter fixture through `environment_scheduler.gd`. `environment_runtime.gd` routes commands to handlers and reports completion. The older standalone `event_director.gd` and independent salvage chance path remain isolated study/test utilities; the integrated game no longer uses them for admission.

## Implemented model

One coordinator owns a pending request collection, ordering and two activity tracks:

- Weather track: idle/calm, approaching, established, clearing.
- Encounter track: idle, preparing/reserved, active, departing.

Expose weather and encounter pending queues as filtered views if useful for debugging. Keep one authoritative request record so a linked pair cannot end up at different queue positions, start halfway or be cancelled in only one queue. Queue position is not a time slot; event durations are variable.

Request variants:

| Kind | Required payload | Scheduling |
|---|---|---|
| Weather request | Weather | Waits for weather availability and the encounter transition gate |
| Encounter request | Encounter | Waits for encounter availability and stable, eligible weather |
| Linked request | Weather and encounter | Reserves both together; neither may be allocated alone |

A `submit_story(weather, encounter)` convenience method validates both payloads and creates a linked, story-priority request. Keep story importance distinct from resource requirements internally; a non-story sequence could also need coordinated weather later.

Submitting validates all payloads and capacity before recording anything. Return a clear accepted/duplicate/full/invalid/ineligible result; never enqueue half of a pair. A required story intent that cannot yet be accepted remains pending in its story owner for later retry, rather than silently disappearing or being marked complete. Use stable request IDs to deduplicate retries.

## Start and completion rules

- At most one weather lifecycle owns the weather track, including its transitions. An empty pending queue does not cancel the active weather. When no request owns weather, the target defaults to calm and returns there through the ordinary transition.
- A stable active weather can host a compatible ordinary encounter. Approaching/clearing weather cannot, preserving the existing user rule. An active encounter holds outgoing weather transitions but does not pause water, wind or cloud animation.
- A linked story request waits without owning either track until both can be reserved. Once reserved, weather approaches first; the encounter begins when that weather is established. Its requested conditions remain held through the encounter. After the encounter/departure ends, the weather exits or hands off through the normal transition policy, then releases its ownership.
- If the pair is cancelled/fails during preparation, cancel the unstarted encounter and release the reservation with an orderly weather exit. Admission/reservation is not narrative completion.
- A local encounter gust modifies effective fields; it does not independently take over the weather track or enqueue a second weather event.

## Queue size, bypass and fairness

Confirmed capacity: **two weather-bearing requests total**, counting the active lifecycle and waiting requests. Therefore one active front leaves room for one waiting front or pair. A linked request counts once. The single pending collection also has a 64-request bound; encountering a full queue leaves all state unchanged. Only one encounter can be active/reserved. Matching array indexes are unnecessary.

Permit bypass of blocked queued requests only when the candidate is safe under current activity and transition rules. It must not preempt an active encounter or force a weather transition through it. This distinguishes independent scheduling from permission to ignore the other system's locks.

A linked story request must not starve while shorter ordinary requests keep refilling the available track. Once an eligible story request becomes the oldest highest-priority request, stop admitting new ordinary work that would delay its needed tracks; let existing activities finish. Then acquire both atomically. This drain policy is implemented for viable story pairs. A pair whose prerequisites or destination exclusions are currently impossible does not block ordinary work.

Chance opportunities should continue to roll only when eligible rather than building a backlog during a blocked story. Explicit triggered requests can wait. Preserve existing quiet intervals and world-event exclusivity unless the user expressly changes them.

See [eligibility and chance authoring](event_eligibility_and_chance.md) for the implemented per-definition rate tables and separate weather/encounter pacing budgets. The coordinator decides admission and starts the weather handler; the simulator owns transition progress and reports when conditions are established. Reserving a linked encounter must not activate the weather-transition hold before its required approach completes.

## Runtime API and lifecycle details

- `scheduler.submit(request_id, weather_id, encounter_id, story, context)` accepts definition IDs, with weather/encounter optional except for story pairs. Payloads are validated when the catalog is configured. Caller IDs make retries idempotent. Different request IDs may queue the same repeatable definitions behind active work; the laboratory trigger convenience still suppresses duplicate button requests.
- `runtime.trigger_weather(axis, condition)` and `runtime.trigger_encounter("salvage", flags)` route existing laboratory controls through the same scheduler. `runtime.submit_story(request_id, weather_id, encounter_id, flags)` exercises pairing without inventing narrative content.
- Explicit requests skip chance weights but recheck hard eligibility and prerequisites at allocation. Story pairs also check that the destination could support their encounter. Once the front reaches hold, actual local fields must support it before activation. If those fields lag, retry during the finite hold; if the front starts clearing first, cancel the unstarted encounter.
- Story requests currently respect the existing 90-second quiet period. No quiet-time bypass is introduced. Trigger priority is followed by FIFO; viable story pairs prevent ordinary refill while waiting for both tracks.
- Cancellation of a pending request removes it atomically. Cancelling preparation releases its unstarted encounter; the weather completes its existing lifecycle and normal clear without jumping its spatial envelope. Live encounters resolve/depart through their handler before releasing the track. A cancelled pair does not become narrative completion.
- The simulator retains its 12s approach / 18s hold / 12s clear defaults and physical response constants. The scheduler sets the transition hold only for an actual active encounter, including departure.
- The scheduler owns encounter quiet time, cooldowns, request identity/ordering, chance RNG and accumulated hazard. Weather front placement uses a separate RNG. Chance requests are admitted immediately or discarded; they never fill the pending queue.

Snapshots include pending/active requests, both owners, preparation/tail phase, outcomes, cooldowns, quiet time and partial chance ticks. Restore validates ownership and definition identity before replacing live state. Runtime snapshot version 3 rejects earlier laboratory version-2 snapshots instead of silently losing their old queues; this project does not yet have released player saves.

## Verification and remaining scope

The scheduler suite covers capacity including active weather, pair validation, preparation versus active holds, safe bypass, story draining, cancellation, cooldown/quiet ownership, hard exclusions, interpolation, weighted frequency and deterministic restore. Existing weather/encounter integration and actual rendered-scene tests remain the regression checks. See [implementation review](../work_packets/scheduler_chance_implementation.md) for the validation record and limits.

No starter idea, wildlife behavior, inventory reward or new story milestone is implemented here. The next content choice remains with the user.
