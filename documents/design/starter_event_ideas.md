# Starter weather and encounter ideas

6 September 2026. Three subagent reviews covered weather presentation, small environmental puzzles and wildlife/wonder. These are **unselected proposals**, consolidated for user review. No gameplay or assets were implemented by this review. Visual quality remains the priority; fish are secondary.

Use [eligibility and chance authoring](event_eligibility_and_chance.md) for selection. The preferences below are proposed gameplay/readability weights, not probabilities or wildlife-frequency facts. Numerical balance follows selection and a manually triggered visual test. Do not enable every candidate simply because it appears here.

## Recommended first review

**Passing paper cloud** is the smallest visual weather test: reuse an approaching cloudy front, preserve independent wind, and watch it settle and clear. It needs no encounter or new drawing. This is a curated demonstration/tuning pass on working effects, not a claim that weather is missing.

**Free the wedged plank** is the smallest proposed interactive puzzle. It adds a nearby nudge and a readable consequence to the salvage foundation. It requires new interaction code; the fixture currently only spawns, drifts and departs.

**One resting seabird** is a possible first wildlife art study after choosing and researching a regional species. It offers observation and a disturbance response without requiring fishing or inventory.

The user chooses the first prototype before implementation. The weather preview can precede coordinator work; it does not require silently settling the pending queue capacity or wave oscillation questions.

## Weather and ambient candidates

| Candidate | Visual payoff and player response | Smallest addition | Proposed conditions |
|---|---|---|---|
| Passing paper cloud | A torn cloud bank approaches from a random direction, softens light overhead and clears. The player continues steering and can tilt toward it. | One curated existing cloudy-front payload; tune its existing cloud/light presentation. | Sunny starting sky makes change legible; favor daylight; equal wind weights. |
| Brief shower | Rain strokes gather around the bucket, then thin as the sky lightens. Movement remains available. | Reuse raincloud profile and local rain instances. No new art; review density and timing. | Sunny/cloudy start; favor daylight; rarer than cloud front. A gentle wind preview is a test setting, not permanent sky/wind coupling. |
| Warm clearing light | Wave highlights and paper horizon briefly warm as the cloud cover opens. | New palette interpolation in sky/wave presentation; initially preview a fixed dawn/dusk setting. | Dawn/dusk clearing phase; exclude full night; wind independent. |

The first two occupy the weather track, with its own budget and approach/hold/clear lifecycle. Warm clearing is a conditional visual detail within a weather lifecycle, not another scheduled event. Established weather can host an encounter, and clearing waits for that encounter's lock. These ambient changes need no puzzle-success state or encounter interruption.

Current cloud banks are procedural shader ribbons, not authored paper cloud cards. Rain exists; splashes, wet clothing and rain audio are additional work. Day/night presentation is unfinished, so warm clearing is a larger addition than the first two.

Implementation anchors: `game/events/event_catalog.gd`, `game/events/environment_runtime.gd`, `game/world/weather_simulation.gd`, `game/world/weather_presentation.gd`, `game/world/paper_sky.gdshader`, and the sky connection in `game/camera_study.gd`.

## Interactive environmental candidates

All three permit observing, trying an unhelpful action, correcting it, or leaving. No inventory reward or story milestone is implied. Their payoff is a visible change in the local arrangement. They are environmental mechanism tests; do not label them wildlife-learning encounters before they actually teach a verified fact.

| Candidate | Readable relationship and agency | Minimum new work | Proposed conditions / relative scope |
|---|---|---|---|
| Free the wedged plank | A short plank rocks inside forked driftwood. Nudge its exposed end to turn it free; pushing the crowded side wedges it more tightly. Released drift demonstrates success. | Two or three original paper cards; proximity/approach-side nudge; saved `wedged / tightened / free` states and local offsets. | Favor wind 0–1, daytime, sunny/cloudy; reduce wind 2/rain, exclude wind 3. Smallest puzzle. |
| Turn a little sail | Fabric on a board catches the breeze. Turn it to pull the board through a debris opening, or push the fork aside. A poor orientation catches again. | Wood/fabric drawings; two orientations; opening test; local wind-dependent drift and saved state. | Require nonzero wind, favor 1, reduce 2, exclude 3; prefer daylight. More work to make force and drawing agree. |
| Give the cord some slack | Two boards are linked by a cord snagged on a peg. Pulling tight draws them together; approach the slack side and release the loop to separate them. | Board/peg art and a cord strip; side/slack checks; saved `slack / taut / released` states. No general knot solver. | Favor wind 0–1 and daylight; initially exclude 2–3 until readable. Largest of these three because the cord must read across camera angles. |

Authored mechanisms can be small state machines; they do not need general rigid-body or rope simulation. They still need visible spatial reasoning, reversible mistakes and convincing motion. The sail mechanism could later enter the cooperation Venn set if using wind grants meaningful access; no capability reward exists in this prototype proposal.

## Wildlife and quiet wonder candidates

| Candidate | Player agency and Venn classification | Minimum new work | Proposed conditions / research |
|---|---|---|---|
| One resting seabird | A small ivory bird sits on dark driftwood, occasionally turning its head. Drifting alongside preserves the scene; approaching too closely prompts flight and leaves the wood behind. **V only.** | Reuse floating scrap/anchor; original resting and wing-open poses; proximity response; short flight arc; full moving bounds. | Favor sunny/cloudy daylight, wind 0–1; exclude 2–3 initially. Select species/season and verify substrate, scale, disturbance response and takeoff before representing real behavior. |
| A feather turning between waves | An ivory feather turns in a gap between crests. Watch beside it, or pass through its small area to send it spinning away. **V only.** | One original feather card; drift/rotation state; new localized impulse. No existing bucket-wake system can be assumed. | Favor sunny/cloudy, wind 0–1; dusk only if readable; exclude rain/storm initially. Research floating behavior and a regional feather reference. |

Neither grants affection, transport, loot or automatic knowledge. The feather is mechanically simple but may be too slight to justify occupying the exclusive encounter slot; review its visual payoff before choosing it. It could instead become ordinary ambient detail later, which would need an explicit classification decision.

## Shared cost and acceptance criteria

Current `game/events/encounter_runtime.gd`, `game/events/event_instance.gd` and encounter presentation support salvage specifically, including save validation. New encounter families need bounded dispatch and persistence support, not just replacement artwork. Existing reuse includes seeded placement, drifting anchors, encounter exclusivity, stable weather, modifier/departure fields, visibility and outcome records. No full retrieval, wildlife interaction, inventory or fishing minigame can be treated as an existing dependency.

- Start the selected prototype manually so chance waiting does not hide visual or interaction problems. Keep all player controls available and introduce no cutscene or required explanatory text.
- Review artwork, occlusion and interaction readability at 12°, 20°, 38° and 52°. Verify the current approximate gameplay surface is adequate for its particular actors.
- For encounters, show success/disruption explicitly before departure obscures the result. The current runtime initiates departure after resolution; retirement alone is never puzzle completion.
- Reuse the approved 90-second quiet interval, total encounter hazard ceiling of 1/240 eligible seconds, and 180-second lingering departure. Keep weather transitions blocked through the active encounter/departure while physical animation continues.
- After manual approval, add the chosen definition's hard exclusions and relative weights. Day-phase eligibility needs wiring; current chance logic reads only sky/wind categories. Verify saved interaction state and full actor bounds before enabling random admission.

Next decision: select one starter demonstration or encounter. Detailed rates, new verbs and artwork remain reviewable proposals until that choice.
