# Coordinating weather and encounters

6 September 2026. Proposal requested by the user; not implemented or accepted yet. This replaces neither the current weather handler nor the encounter rules until reviewed.

## Problem and existing foundation

Weather and encounters need independent scheduling, with linked story requests able to require both. Independent queue heads and partial allocation could leave weather waiting for an encounter while the encounter waits for weather. Ordinary eligible requests should be able to pass a blocked request without interrupting an active one.

The current game already runs weather approach/hold/clear lifecycles and a salvage encounter fixture. `event_director.gd` has up to 64 pending explicit triggers and one weather exclusive group; chance proposals do not accumulate. `environment_runtime.gd` blocks weather transitions during an encounter and delays encounters during transitions. It does not yet implement a size-two weather queue or atomic weather/encounter pairs.

## Recommended model

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

Submitting validates all payloads and capacity before recording anything. Return a clear accepted/duplicate/full/invalid result; never enqueue half of a pair. A required story intent that cannot yet be accepted remains pending in its story owner for later retry, rather than silently disappearing or being marked complete. Use stable request IDs to deduplicate retries.

## Start and completion rules

- At most one weather lifecycle owns the weather track, including its transitions. An empty pending queue does not cancel the active weather. When no request owns weather, the target defaults to calm and returns there through the ordinary transition.
- A stable active weather can host a compatible ordinary encounter. Approaching/clearing weather cannot, preserving the existing user rule. An active encounter holds outgoing weather transitions but does not pause water, wind or cloud animation.
- A linked story request waits without owning either track until both can be reserved. Once reserved, weather approaches first; the encounter begins when that weather is established. Its requested conditions remain held through the encounter. After the encounter/departure ends, the weather exits or hands off through the normal transition policy, then releases its ownership.
- If the pair is cancelled/fails during preparation, cancel the unstarted encounter and release the reservation with an orderly weather exit. Admission/reservation is not narrative completion.
- A local encounter gust modifies effective fields; it does not independently take over the weather track or enqueue a second weather event.

## Queue size, bypass and fairness

User requirement: weather queue has a maximum size of two. **Pending clarification:** whether this means two waiting weather-bearing requests in addition to the active lifecycle, or two total including the active lifecycle. A linked request counts as one weather-bearing request. Encounter capacity is separately configurable; matching array indexes are unnecessary.

Recommendation: permit bypass of blocked queued requests only when the candidate is safe under current activity and transition rules. It must not preempt an active encounter or force a weather transition through it. This distinguishes independent scheduling from permission to ignore the other system's locks.

A linked story request must not starve while shorter ordinary requests keep refilling the available track. Once an eligible story request becomes the oldest highest-priority request, stop admitting new ordinary work that would delay its needed tracks; let existing activities finish. Then acquire both atomically. This temporary drain policy is part of the proposed priority behavior and needs review alongside the user's bypass preference.

Chance opportunities should continue to roll only when eligible rather than building a backlog during a blocked story. Explicit triggered requests can wait. Preserve existing quiet intervals and world-event exclusivity unless the user expressly changes them.

See [eligibility and chance authoring](event_eligibility_and_chance.md) for the proposed per-definition rate tables and separate weather/encounter pacing budgets. The coordinator decides admission and starts the weather handler; the simulator owns transition progress and reports when conditions are established. Reserving a linked encounter must not activate the weather-transition hold before its required approach completes.

## Implementation sequence after review

1. Add coordinator/request types and explicit queue-capacity behavior around the existing handlers; do not rewrite the physics or renderer.
2. Test one weather-only front through calm → approach → established → clear → calm, including a second queued front and a full-queue rejection.
3. Integrate ordinary encounter admission/transition holds and prove a blocked pair can be bypassed only by safe requests.
4. Test a linked weather + placeholder encounter fixture: both reserved together, weather settles first, encounter starts, conditions held, clean completion/cancellation. This is a scheduling fixture, not invented story content.
5. Persist request IDs/order, reservations, active ownership and lifecycle state; verify restore cannot start a pair twice or release only half.

Tests should cover capacity boundaries, pair validation/no partial allocation, no concurrent weather fronts, no transitions during ordinary encounters, bounded story waiting, cancellation during preparation, and deterministic snapshot replay.
