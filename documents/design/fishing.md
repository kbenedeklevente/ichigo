# Fishing design and implementation plan

## Experience and role

Fishing is a tactile contest of observation, timing, and controlled response. The player should notice a fish's intent, choose how to present the lure, feel the line load, and recognize a chance to reel or yield. It must remain enjoyable when no food meter exists and after the player understands the basics.

Success develops mastery, reveals wildlife behavior, supports optional collection/release, and sometimes enables a nearby encounter or physical retrieval. Do not use a disconnected progress bar as the entire minigame. Do not require dialogue, long instructions, or random button sequences.

## Complete interaction loop

| State | Player action | Feedback and transition |
|---|---|---|
| Observe | Read surface movement, silhouettes, habitat and conditions | A readable opportunity; nothing forces a cast |
| Prepare/aim | Choose available rig/lure; select reachable water | Visible line arc/range or restrained target cue; sky and unreachable areas invalid |
| Cast | Set direction and controlled power/distance | Lure enters the world at a stable position |
| Present | Retrieve slowly, pause, or give a small lure motion | Fish approach/inspect/ignore according to their profile and current state |
| Bite | Respond to a distinguishable commitment cue | Rod, line, ripple and sound agree; missed response can allow another approach |
| Fight | Reel, yield, and adjust rod direction | Fish movement and sustained line load determine risk and progress |
| Land | Guide the tired fish into reachable position | Short player-controlled landing action; continuous scene |
| Resolve | Observe, release, retain if meaningful, or stow a retrieved object | Persistent result, return to travel with preferred camera restored |

Cancel/retrieve is available before a bite. During a fight, deliberately yielding or cutting/releasing the line exits with an appropriate consequence; do not lock the player in an animation. Baseline fishing capability remains available after failure.

## The first compelling fight model

Model a small set of legible variables: line length/slack, tension, fish effort, fish distance/direction, and accumulated strain. Tension responds to relative motion, reeling, and yielding. Fish effort changes with readable bursts and recovery phases. Sustained excessive load builds strain; do not break the line from a single untelegraphed numerical spike.

Reeling shortens available line and can raise load. Yielding gives line and relieves load but loses distance. Rod angle influences leverage/strain within a simple consistent rule. A visibly slack line risks losing the fish after a readable interval. Landing requires control and proximity, not merely waiting for a hidden timer.

This is a gameplay model to tune, not a promised physical simulation. Start with a spring/damping-inspired load approximation clamped to plausible behavior, then verify that visual rod bend, line shape, and motion match its outcomes. Do not implement a complex rope solver before the basic decisions feel good.

Prototype two behavioral profiles: one with short rapid changes, another with steadier pulls and clear rests. Their names are design labels until a real species is selected and researched. Higher difficulty should ask for better interpretation and control, not simply longer fights or larger invisible health bars.

## Controls and camera contract

Use a dedicated interaction mode owned by InputRouter. Suggested actions: aim, primary cast/reel, secondary yield/cancel, rod direction, camera tilt, and pause. Map keyboard/mouse and controller using the same action semantics. In a fight, input must not accidentally both steer the bucket and move the rod; bucket drift remains simulated and intentional repositioning is a separately defined action if later needed.

Cast targets use actual camera-to-world projection and a maximum reach. Sky rays have no cast point. Store an accepted cast in world coordinates; changing camera pitch must not move it. Keep the selected fish/float by stable ID. Line endpoints follow the actual rod/lure anchors.

Suggest a slightly higher framing for fishing, but let the player adjust pitch within the supported range. Avoid an automatic low-to-high snap at the bite. The frame should hold the bucket, line, lure, and near fish activity; distant or deep fish can use water disturbance cues rather than a permanent through-water outline.

The first prototype stays in third person. First-person fishing is a separate experiment after hand, rig, water, and bucket-interior assets support it. Avoid building the minigame around a first-person-only cue that the main camera cannot show.

## Readability, fairness, and accessibility

Use rod bend, line vibration/shape, water motion, fish posture, and synchronized audio to teach states. Critical cues need both visible and audible options. Do not rely on red/green or on hearing a bite. Optional concise prompts and an assist indicator may help players who cannot infer small motions.

Provide hold/toggle alternatives, adjustable response windows and input sensitivity, reduced camera motion, and a practice encounter with repeatable conditions. Avoid mandatory rapid tapping. Track whether failure followed a readable decision or an unexpected transition.

Weather/time influence fish eligibility and presentation conditions. They must not replace skill with an arbitrary success roll after correct play. Smoothly changing waves alter drift/load; avoid sudden director-driven weather jumps during a fight. Save the chosen fish/profile and committed result state so reloading cannot redraw a more valuable catch.

## Prototype tasks and acceptance

1. Build a practice scene with a known fish, fixed conditions, placeholder assets, and visible developer diagnostics.
2. Implement aim/cast/retrieve with valid-range feedback at every supported pitch.
3. Add approach and bite cues; test comprehension without narration.
4. Add reel/yield/rod response and two behavior profiles; tune fair failures.
5. Add landing and release/retain/retrieval integration with inventory and knowledge.
6. Play through a camera transition and gentle weather change during the full loop.

Pass when a new player learns a first catch through concise cues, an experienced player can improve through decisions, both profiles feel different, and outcomes remain stable across camera settings. Test invalid targets, maximum reach, cancellation, pause, save/resume, loss of target, line snag, and full inventory. Record typical fight durations and repeated-player feedback before choosing final pacing numbers.
