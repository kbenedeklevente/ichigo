# Shared triggered and chance event system

Status: first executable foundation, 5 September 2026. This follows the user's decision to separate story-triggered events from chance-based side opportunities while allowing the same activation concepts in any domain. The weather handler is integrated; quest, achievement and story handlers remain to be authored.

## Latest encounter revision

The user now requires no overlapping encounters and no weather transitions during an encounter, with weather-dependent chance rates and local event field modifiers. The [encounter-fields proposal](encounter_fields_and_pacing.md) defines that revision. Its global admission/transition gate supersedes the earlier future-concurrent-domain proposal below; the current code still only enforces per-group exclusivity. Rate tables, quiet intervals and fishing protection remain proposed until reviewed.

## Activation and outcomes are separate

An event definition describes **what can happen**. Its activation policy describes **why it starts**. Its handler controls **what happens during play**. Completion and rewards depend on the resulting outcome; dispatch alone does not complete a quest, solve a puzzle or grant an achievement.

| Activation | Source | Intended use |
|---|---|---|
| `trigger` | An explicit call after prerequisites are met | Main-story progression, player actions, scripted consequences |
| `chance` | A seeded chance tick while eligible | Side encounters, discoveries, ambient activity, achievement opportunities |
| `both` | Either path starts the same event handler | Weather and other reusable events that can serve story or incidental play |

Main-story sequence and prerequisites are authored. Side-event availability may be random. Story-triggered weather still receives a random arrival direction. An achievement recognizes an actual feat/outcome; chance supplies its opportunity, not an unearned achievement. Local steering, fishing and puzzle decisions keep their consequences. What the player cannot avoid by simply choosing another heading is the arrival of a scheduled weather front.

## Definition contract

Each definition has a stable `id`, a `domain`, an `activation` policy, `requires` flags, `rate_per_second`, `cooldown_seconds`, `once`, `priority`, `exclusive_group` and handler-specific `payload`.

Example story-driven weather definition, an integration example rather than authored Ichigo plot:

```gdscript
{
    "id": "story.example.weather", "domain": "weather", "activation": "trigger",
    "requires": ["example_puzzle_solved"], "once": true, "priority": 100,
    "exclusive_group": "weather", "rate_per_second": 0.0,
    "cooldown_seconds": 0.0,
    "payload": {"sky": "raincloud", "wind": "strong", "approach_s": 12.0,
                "hold_s": 18.0, "clearing_s": 12.0}
}
```

The story controller adds the milestone flag only after the player actually solves the puzzle, then calls `trigger(id, context)`. Pass current flags to subsequent `advance` calls too; queued events are rechecked before dispatch. Definitions must be registered when configuring the director. Runtime configuration resets its state, so do not use `configure` to append content mid-play.

Future wildlife/fishing/loot conditions should be translated into explicit eligibility flags by their owning systems, or extend the condition schema deliberately. The current engine does not parse an arbitrary scripting language for conditions. Camera orientation and frame rate are never eligibility inputs.

## Lifecycle and conflicts

`eligible → queued/proposed → active → finished(outcome) → cooldown/consumed`

- Triggered events are queued once, bounded to64 pending requests. Priority then FIFO determines dispatch. A queued story event waits for an occupied exclusive group; it does not interrupt a visible event.
- Chance evaluation uses fixed one-second ticks and `1 - exp(-rate * tick_duration)` per eligible definition. With equal-priority simultaneous candidates, selection is randomized. Current exclusions/cooldowns alter the eligible distribution.
- Chance proposals are not accumulated behind an occupied group. Waiting through a long story event does not cause a burst of backlogged random weather afterward.
- One `weather` exclusive group serializes weather fronts. A future unrelated group can proceed concurrently. No global lock prevents every other domain from acting.
- An active event stays active until its owner calls `finish(id, outcome)`. Weather calls this only after its complete approach/hold/clear lifecycle.
- Cooldown begins at finish. A `once` event is consumed at dispatch, including a failed outcome. Retryable required story content must use an explicit retry policy or a repeatable opportunity definition; do not accidentally make a failed handler permanently block the story.
- Failed admission returns false; no reward or world mutation should be committed before admission. Runtime weather-handler rejection finishes the event as failed.

No actual main-story events or quest rewards are invented by this foundation. The [story plan](story_points.md) supplies the later authored milestone graph, and [encounter plan](encounters_puzzles.md) supplies outcome semantics.

## Weather integration

The study catalog has16 complete `weather.mix.<sky>.<wind>` combinations, all supporting both activation paths. Each has an idle rate of `1/960` per second and a120-second per-definition cooldown. With all16 eligible, aggregate hazard is approximately one event per60 seconds of eligible idle time; this is not a promise of an event every minute. Equal initial weights make the axes independent; cooldowns change the available set afterward.

Eight single-axis trigger-only aliases remain available for code tests. Their omitted axis uses the weather baseline. The study's number keys instead assemble a full pair from the last selected sky and wind, so combinations can actually be previewed. Queued front requests do not skip the currently active front. Repeated requests for the same active, queued or cooling-down ID are rejected.

Event activation and incoming-front direction have separate seeded RNG streams. The bridge runs at30Hz, forwards weather payloads to the handler, and releases the director's weather group when the handler finishes. Other domains use the generic director directly and supply their own handlers; the weather bridge does not auto-complete or award non-weather events.

The detailed parameters, matrix layout and physical behavior are in [weather runtime parameters](weather_runtime_parameters.md).

## Code and persistence

- [event_director.gd](../../game/events/event_director.gd): admission, fixed chance ticks, queue, priority, lifecycle and cooldowns.
- [event_catalog.gd](../../game/events/event_catalog.gd): editable weather definitions.
- [environment_runtime.gd](../../game/events/environment_runtime.gd): director-to-weather bridge and synchronized stepping.
- [weather_simulation.gd](../../game/world/weather_simulation.gd): fields, fronts and connected springs.

Director snapshots preserve catalog fingerprint, RNG, time/remainder, queue order, active events, consumed IDs, cooldowns and outcomes. Combined runtime snapshots also preserve panel fields/velocities, weather phase, front direction/progress and both RNG states. The weather snapshot contains Godot vectors and packed arrays: use native Variant serialization, not plain JSON. This is an in-memory persistence contract, not a finished save menu or full-game save format. Rendering state and the player's world state still need to be included by the eventual save owner.

## Validation and next content work

Tests cover activation provenance, flags, once/cooldown behavior, queue conflicts, chance fairness, frame partitioning, blocked chance behavior, snapshot rejection/replay, actual weather-handler completion and active-front restore. Scene tests confirm that rainfall and lighting respond, the bucket and targeting sample the new water, and pause freezes both systems.

Next, author a small story milestone with an explicit trigger and a side encounter with chance eligibility against this same interface. Decide their actual narrative and player outcomes with the user first. Keep the event system generic rather than encoding a story's meaning into the weather renderer.
