# World, event scheduling, weather, and time

## Latest weather specification

Use the [illustrated ocean and nested weather plan](paper_ocean_weather.md) for the new square-cell matrices, rendered subset, player-centered coordinates, individual panel dynamics, four sky/four wind categories, incoming fronts and transition phases. That plan supersedes older broad weather suggestions below. Pairing rules and the scope of player agency remain pending user answers; do not implement an assumed answer.

## Open travel without a required route

Implement a continuous navigable ocean around the bucket. The player may paddle in any horizontal direction, stop, drift, turn back, or circle a local event. Physical positions and relative velocities must be real enough for targeting, fishing, and puzzles. Macro progression depends on knowledge, capabilities, and encounter outcomes rather than global coordinates.

No heading is inherently more rewarding. Wind/current can make a local approach easier or harder, and one visible opportunity may lie on a particular side of the bucket. Those are meaningful local choices. Equivalent journeys in other directions must still receive viable opportunities and story access.

Do not secretly make straight-line distance the progression meter; that would turn drifting, observation, or circling into inferior play. Schedule opportunities using world time, current context, history, pacing, and meaningful completed actions. Idling can allow ambient encounters without granting completed puzzle/story rewards automatically.

## Local space and continuity

Start with a bounded active simulation region large enough for the test camera and encounters. Maintain near gameplay actors, a surrounding opportunity region, and a distant ocean/sky presentation. These are technical regions, not visible walls or loading screens.

An event becomes a persistent local object once placed. Moving the camera or changing heading does not relocate it to stay conveniently in front of the player. Turning back within the retention window should reveal the same event and consequences. Retire distant events only after a distance/time rule and absence of active references such as a hooked fish, puzzle, selected object, or pending reward.

Store compact records for resolved/abandoned encounters so streaming cannot farm fresh rewards. The game need not maintain an infinite revisitable map; state that limitation in the system design, and provide a generous local continuity window. Handle long travel with coordinate rebasing only when needed. Rebase the bucket, actors, line endpoints, anchors, camera, and ocean sampling consistently; logical IDs and reward records do not change.

## Opportunity generation and fairness

Use separate RNG streams for encounters, rewards, weather, and decoration. Persist generator states and content-version identifiers. The same seed and compatible inputs/state should reproduce event decisions; bit-for-bit cross-platform physics replay is not promised.

Scheduling pipeline:

1. Read shared environment, player capabilities/knowledge, recent history, and pacing state.
2. Filter out ecologically or mechanically invalid encounters.
3. Weight remaining families for variety, relevance, cooldown, and anti-stall needs.
4. Select an opportunity using the encounter stream and reserve its identity.
5. Place it coherently outside visible spawning exposure, or use an observable natural arrival.
6. Allow the player to encounter, bypass, or disturb it; commit state through the owning systems.

Use the supported camera envelope when evaluating spawn visibility. Tilting up must not reveal a ring of props popping into existence, and tilting down must not trigger a new reward roll. If safe off-screen placement is unavailable, delay placement or use authored entry movement instead of cheating visibility. Eligibility and rewards are not functions of the player's selected pitch.

Quiet intervals are a deliberate pacing state. Avoid turning every few metres into an event. A finite event library can create varied playthroughs, not a mathematical guarantee that no two will ever resemble one another.

## Weather and time as one environmental state

EnvironmentState owns time phase, sun direction, ambient light, cloud cover, visibility/fog, wind vector, precipitation, ocean/swell parameters, and transition progress. Rendering, audio, fishing, and wildlife read this state. They do not independently choose weather or time.

Use weather states with durations and compatible transitions rather than random jumps each frame. Blend lighting, cloud shapes/coverage, mist, rain, audio, and water response at appropriate different rates. Swell may lag wind; visible wetness can outlast rain. Keep the calm-water slice's amplitudes low even during its gentle weather transition.

Time of day advances independently of player heading and normally follows a coherent cycle. Vary the starting time and weather evolution by seed where useful. Chance-based weather does not require random noon-to-night jumps. Do not reset sunrise because the player turned around. Preview dawn/day/dusk/night art before choosing a gameplay day length; any compression is an explicit design abstraction.

| State/change | Gameplay opportunity | Presentation requirement |
|---|---|---|
| Calm, clear conditions | Surface observation and precise casting | Low water motion, clear silhouettes, visible sky |
| Cloud cover increases | Different contrast/visibility, eligible behavior changes | Cloud, light, water color, and audio agree gradually |
| Light rain | A mood/handling variation or condition-based encounter | No obligation to collect water; readable fishing feedback |
| Mist | Nearby investigation and reduced distant sight | Essential local cues still available through visual/audio alternatives |
| Dusk/night, later | Different researched wildlife activity and story presentation | Preserve readable targets; avoid pure darkness or mandatory text cues |
| Stronger weather, later | More demanding physical events and changes in debris availability | Fair warning and transitions; no giant-wave copying in the first demo |

## Availability without sudden spawning

Environment changes affect whether an encounter can begin, continue, evolve, or leave. Define that policy per encounter. A fish already hooked does not disappear when an eligibility threshold crosses; an active event completes or exits believably. Use hysteresis/transition windows where threshold oscillation could repeatedly enable/disable behavior.

No mandatory puzzle depends exclusively on one rare weather/time combination. Preserve alternatives and opportunity safeguards. A photo-like spectacle may be rare because missing it does not block the story. Natural facts presented through conditions need research; do not universally equate rain, darkness, or calm with a species' behavior.

## Tasks and validation

1. Build continuous local steering/drift and stable encounter anchors with debug bounds.
2. Implement environment and director state as data, using test-only placeholder events.
3. Add three encounter families, cooldowns, persistence, and heading-independent eligibility.
4. Add calm-to-overcast or light-rain transition; connect visuals, sound, and fishing to the same state.
5. Preview time-of-day transitions; integrate a full cycle only after visibility and pacing review.
6. Add save/resume and stress-test turning back, long travel, camera sweeps, and active interactions.

Run rotated versions of equivalent scripted scenarios to check that progression does not depend on global heading. Compare opportunity distributions across a batch of seeds rather than demanding identical frames. Test observation-heavy and moving play, rare-condition dry spells, repeated pause/load, active fishing during a transition, and interrupted rewards. Report maximal observed waits and unreachable prerequisite paths, then manually verify that varied runs feel meaningful.
