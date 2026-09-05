# Open-ocean survival — concept plan v0.1

> Historical concept plan. The [integrated design package](../../documents/design/README.md) is the current planning authority. It supersedes this document's food/water loop, required navigation/route progression, unrestricted camera assumptions, and earlier slice order. Current direction: travel in any heading with encounter-driven progress; a bounded adjustable camera; cohesive assets across its range; paper, low-poly, and medium-poly experiments; and an initial playable proposal without hunger or thirst. Preserve the material below as the record of earlier exploration, not as conflicting instructions for implementation.

Prepared 5 September 2026. Planning and concept-art deliverables; no playable engine build has been produced in this phase.

## The game we are making

A solitary ocean-survival adventure in which learning to read wildlife, water, and weather gives you the means to survive and unravel a personal mystery. The ocean is beautiful enough to linger in, believable enough to learn from, and occasionally dangerous enough to demand your full attention.

Confirmed direction: Mac first; a technically competent creator with a computer science BSc; believable wildlife and survival with painterly visuals; wonder and solitude punctuated by danger. Most gameplay takes place on open ocean. Fishing is central. Puzzles drive an overarching story. Encounters and weather vary between playthroughs. There are no cutscenes, and events permit helpful, disruptive, exploitative, or avoidant responses with consequences.

The supplied images are visual references, not instructions. The novel's Ichigo is the creative reference. The character and vessel details below are the user's explicit design requirements; the storyline and systems elsewhere remain proposals to develop together.

### Confirmed character and vessel correction

Ichigo is a young child with no specified age or gender. Use they/them in design documents and do not infer gender from appearance. They wear their dad's sports jersey with the number **15**, visibly oversized: dropped shoulders, large sleeves, and a long hem. No hat for now. Jersey color, hairstyle, and sport-specific details remain open.

Their vessel is a wooden bucket, giant relative to the child's size, with a round opening and recognizable wooden-stave construction. It is not a skiff or conventional boat. Convey the scale through the child's small hands, the rim height, and empty space inside the bucket. Size and camera placement must still let the child and jersey read clearly.

Earlier generated boards use an adult wearing a hat in a skiff; those depictions are superseded. Retain those boards only as material, palette, water, and sky studies. Future character and environment concepts must use the child, oversized number 15 jersey, no hat, and bucket.

Treat the bucket as a deliberate storybook premise while keeping wildlife behavior and environmental cause-and-effect believable. Revisit vessel stability, storage, steering, fishing reach, and first-person visibility around the bucket rather than carrying over skiff assumptions unchanged. References to boat/vessel in the systems plan now mean this bucket.

## 1. Flesh out the idea together

Start with a focused design session before committing to plot or making a large asset library. Resolve:

- **Who and why:** protagonist, reason for being offshore, personal reason to continue, and what reaching safety would mean. Draft three short premises, then choose one.
- **Where and when:** one coherent marine region and season. This determines plausible species, weather, currents, equipment, and what the player could actually infer from observations.
- **Daily experience:** choose the balance of drifting, steering, fishing, repairing, observing, and solving. Decide whether the player can swim; keep free diving outside the first demo.
- **Survival pressure:** begin with water, food/energy, and boat condition. Establish how forgiving failure is. Proposed default: setbacks and recoverable losses; optional harsher survival later.
- **Story form:** establish a beginning, a central question, three knowledge milestones, and an ending the player performs through gameplay.
- **Wildlife contract:** define what counts as collaboration. Proposed meaning: working with natural behavior and processes, with occasional protective intervention, without animals dispensing rewards or becoming obedient companions.
- **Practical limits:** identify Mac chip/RAM and an initial display-resolution target. Agree on a small number of sessions per milestone after the first technical experiment.

Deliverable: a one-page agreed brief, a playable-loop sketch, the selected art direction, and a six-encounter backlog. The premise below is a proposal to react to, not an already agreed story.

## 2. Proposed story and gameplay loop

**Story to revisit after the character correction:** the earlier adult-navigator/ocean-survey premise is superseded. Develop a child-centered journey that supports wonder, solitude, and puzzle-led discovery. A route home remains a possible objective; the child's relationship to their dad and the jersey's personal meaning are questions for the design session, not established plot facts. Existing navigation/instrument puzzles are mechanic sketches to reassess for the child's perspective and bucket vessel.

Navigation and observation puzzles advance three broad milestones: establish where you are; understand where the survey went; use that understanding to choose and execute a route toward safety. Any historical setting or equipment failure must make the absence of easy electronic navigation credible.

The loop is: notice a cue → approach or avoid → observe/manipulate → gain knowledge or resources → repair or solve → choose the next heading → encounter changed conditions. Quiet stretches are part of the experience. The director should make them interesting through navigation, wildlife behavior, sound, and anticipation rather than filling every minute with incidents.

**Minimal text is a core presentation requirement.** Tell the story through the child's actions, recurring objects, environmental changes, sound, and the consequences of play. Teach interactions through readable affordances, demonstrations, and safe opportunities to experiment. Avoid mandatory prose journals, dialogue boxes, tutorial paragraphs, and written quest explanations. Use brief control prompts or labels only where needed; retain concise settings, captions, and optional accessibility descriptions. Do not replace written exposition with long spoken exposition.

If we keep a journal, make it primarily a visual fieldbook: sketches, silhouettes, tracks, spatial relationships, and sequences of observed behavior. It records what the player has seen without automatically answering every puzzle. Wildlife learning should emerge from observing and testing a real behavior. Keep research citations in development documents and optional reference material; short factual labels can be available on request when a precise fact cannot be conveyed visually. Avoid trivia quizzes and arbitrary locks floating in the sea.

For future inventory and survival feedback, prefer recognizable objects, visible quantities where practical, gestures, and changes in the bucket or child's condition. Use short labels when icons alone are ambiguous. Pair essential sound cues with visible feedback and avoid conveying essential information through color alone. These are design constraints for later implementation; the current phase remains visual exploration.

## 3. Art direction

**Updated direction following the user's review: prioritize the LEFT paper-cutout treatment.** It is the preferred starting point, with further visual exploration required. The initial comparison board explored paper cutout, painterly 3D, and more naturalistic volumetric rendering. The middle option was an initial recommendation and is superseded by this selection.

Current experiment: **dimensional paper cutouts**. Build thin meshes with visible paper edges, shallow extrusion, matte fibrous surfaces, and soft shadows between layers. Bend and deform those meshes so low ocean sheets undulate, cloud ribbons slowly change contour, and wildlife flexes naturally. Here, volume means physical depth and thickness in the artwork; true volumetric fog or cloud rendering is a separate optional layer. Test depth and material deformation together before adding expensive atmospheric effects.

The second concept board, `paper-cutout-iterations.png`, explores A — soft paper, B — sculpted paper, and C — luminous paper. Proposed next test: B's dimensional forms with A's restrained layer depth. C supplies an optional lighting treatment. The generated studies still exaggerate surface embossing and, in B, water-layer thickness; production tests should reduce both and evaluate motion. These are unapproved visual proposals.

First reusable asset vocabulary after style selection: a gently deformable water ribbon over a continuous ocean underlayer, a thin cloud ribbon with a stable horizontal silhouette, one anatomically plausible fish mesh with a bendable body, and paper/ink material swatches. Keep surface deformation low-amplitude and coordinated; do not independently animate layers into gaps or disconnect the boat from the apparent water height. Author geometry and UVs for these motion needs rather than treating the generated scene as a sprite sheet.

Immediate scope is visual style only: compare variants and identify a reusable asset vocabulary. Do not begin implementing inventory, weather simulation, or the full survival loop in this phase. Generated studies are reference targets; reusable game assets will need clean meshes/textures, pivots, topology, materials, and movement tests.

From the first reference, borrow faded pigment, warm paper, pale foam, restrained indigo, and irregular print edges. From the second, borrow the indigo sky gradient and long broken horizontal ivory clouds. The first demo uses calm open water, small ripples, gentle long swells, and an uninterrupted horizon. Do not reproduce the giant curling wave or the reference composition.

| Palette role | Proposed color | Application |
|---|---|---|
| Parchment | `#E9DDBB` | Journal, dry canvas, weathered highlights |
| Ivory | `#F4EDD6` | Cloud bands and sparse bright water accents |
| Indigo | `#183E57` | Ocean depth, silhouettes, upper sky |
| Faded blue | `#447489` | Main ocean/sky midtones |
| Sea teal | `#789E9D` | Subsurface transitions and haze |
| Weathered rust | `#AE7866` | Small clothing and equipment accents |

These are proposed art colors, not exact samples. Fading must not erase contrast needed to read lines, fish silhouettes, or puzzle markings.

Use full 3D geometry for the boat, hands, tools, and nearby animals. Use matte surfaces with subtle material-local grain, restrained shading bands, and selective edge detail. Keep grain stable in motion; a heavy full-screen paper filter can obscure distant wildlife and shimmer. Deep ocean has no visible seabed. Fish close to the surface fade into depth.

Prototype two cloud treatments: shaped layered cloud meshes/cards, and softened volumetric cloud forms if affordable. Godot's built-in volumetric fog is useful for sea haze; it does not automatically provide the art-directed volumetric cloud system we want. Treat cloud rendering as a separate experiment. Water remains a mesh/shader with buoyancy, rather than attempting a full volumetric fluid simulation.

The selected paper-cutout direction must be tested from free-camera viewing angles and first-person inspection. Thin dimensional meshes can retain a consistent appearance across viewpoints better than flat camera-facing sprites. Use layers selectively; avoid exposed gaps in the ocean, sliding textures, paper edges resembling large breaking waves, or shadows that make the water look like stacked solid terraces.

Visual priority order: ocean and horizon; sky; boat and camera; animal silhouette and motion; close-up hands/tools; interface. Sound is part of this: hull creaks, changing wind, line tension, water impacts, and distant calls can direct attention without quest arrows.

Concept images set a target, not an engine performance promise. The generated board is not a playable screenshot or a rigged asset pack.

## 4. Wildlife: three overlapping sets

The sets describe each encounter's intended payoff: **L — learn**, **C — collaborate/access**, **V — visual wonder**. They are independent tags, not a requirement that everything rewards all three. A C-only encounter can use knowledge already learned; a V-only encounter can still respond to the player's presence. The following are design sketches pending the region/species research pass.

| Venn region | Proposed encounter | Player agency and consequence |
|---|---|---|
| L only | Inspect and sketch identifying features of a caught fish | Observe, retain, or release; record what was actually seen |
| C only | Revisit a familiar floating habitat and recover loose cordage from its edge | Use known drift behavior to approach; extract carefully or disturb the patch |
| V only | A small school turns beneath the boat | Drift alongside, paddle through, or leave; proximity changes its movement |
| L + C | Apply an observed feeding pattern to selective fishing | Adjust depth/bait/tension; obtain food or lose the opportunity through disturbance |
| L + V | Watch seabirds alternate searching and feeding | Track and journal their behavior; approaching too closely disperses the activity |
| C + V | Fish at a familiar, visually striking feeding event | Use existing knowledge to make a catch or overrun the school; no new fact is required |
| L + C + V | Read a floating seaweed habitat and its drift, recover abandoned material, and observe the life around it | Compare observations for a navigation puzzle; take a careful route or damage the habitat and lose access to nearby activity |

The collaboration set includes working with currents, timing, and habitat structure; it need not imply reciprocal intent from animals. Recoverable tools come from plausible human debris or existing boat equipment. Helping an animal does not trigger gratitude, guaranteed loot, or magical guidance. Harmful actions remain possible within the implemented verbs; the world expresses their effects through injury, disturbance, resource loss, and altered behavior, without a universal morality score.

Research anchor: NOAA describes floating Sargassum as habitat supporting many species. It is a useful candidate if we choose an appropriate Atlantic setting. This does not validate every proposed drift or salvage mechanic; those remain to be checked. [NOAA: Sargasso Sea](https://oceanservice.noaa.gov/facts/sargassosea.html)

For every implemented animal: maintain a species sheet with region/season, scale, movement, feeding, response to boats, source links, fact versus gameplay abstraction, and animation references. Avoid turning apparent ecological associations into guaranteed navigation signals.

## 5. Fishing and survival

Fishing should reward observation: choose a spot and depth, present bait, read a bite, manage tension, land or release the fish. Fish behavior, the line, and the boat all remain in the same world. Use continuous feedback and optional accessibility assists instead of repeated button-mashing.

The first demo needs one small catchable species, one bait type, a handline or simple rod, believable tension, and retain/release choices. Food is useful, but catching fish should not be the only way to progress the story. Tune survival so the player can stop and watch without being punished every few seconds.

Water collection, equipment repairs, and exposure can grow later. **Future inventory system explicitly requested:** item storage, quantities, selecting/using tools, and later capacity/equipment decisions; settle the exact design when the core interactions are established. It is not part of the current visual-style work. Research survival facts before presenting them as educational content; initially model only the systems we can communicate and validate properly.

## 6. Puzzles, camera, and no cutscenes

Use third person for travel, awareness, and the relationship between the tiny boat and immense ocean. Shift to first person when the player actively inspects or manipulates something. Let the camera move smoothly into the same physical scene; retain look control and a clear way to disengage. World events continue, with difficulty options for slowing precision interactions and reducing camera motion.

Three puzzle families:

1. **Read the drift:** compare a fixed/reference bearing with multiple observations of a floating object; account for boat drift and windage; infer which heading intercepts a recoverable survey marker. A single floating object is not a universal current meter.
2. **Repair the instrument:** inspect a damaged mechanism, route or connect components, test it, and match the recovered reading to a pictorial diagram or environmental landmark. Failure consumes time or changes available approaches, not the only copy of a story clue.
3. **Find the observational window:** combine sketched observations with available visibility or celestial observations. Cloud cover changes which evidence can be used. Provide another evidence route rather than making the player wait indefinitely for one sky state.

Prototype puzzle 1 at a deliberately simplified, legible scale. The physical manipulation should be meaningful: align bearings and an estimate on a damp chart, then test the prediction by steering. The first-person transition emphasizes commitment and tactility, not a hidden movie. Urgent actions such as bracing or cutting a snagged line use the same controls with tighter timing; any QTE remains interactive and accessible.

Every event definition must include its observable cue, approach, at least two materially different responses, interruption behavior, and consequences. Not every action must succeed, and the player cannot command weather or wildlife. Even a spectacular event allows steering, observing, avoiding, fishing where appropriate, or disturbance. Critical conclusions occur through actions in the world.

## 7. Chance with narrative coherence

Use a seeded encounter director. First filter by habitat, season, time, weather, water state, story knowledge, available actors, and resource prerequisites. Then draw from eligible encounters using weights, cooldowns, and recent-history penalties. Schedule quiet intervals as well as opportunities.

Weather is a stateful stochastic process with durations and transitions, not an independent random choice every frame. Wind, cloud, precipitation, visibility, and swell need plausible relationships and transition times. Swell can persist after local wind changes.

**Future expansion explicitly requested:** additional weather effects and a time-of-day system with natural transitions. Coordinate sun direction, sky and ocean color, cloud coverage, lighting, fog, rain, wind, sound, and wildlife activity. Interpolate relevant quantities at different rates so conditions develop rather than switch abruptly; allow residual swell and lingering wet materials. Reserve compatible material parameters in the art experiments, but defer implementing these systems while selecting the visual style.

| Condition | Example available gameplay | Constraint |
|---|---|---|
| Calm/clear | Surface observation, precise chart work, some fishing opportunities | Visibility reveals existing wildlife; it does not create species |
| Light rain | Rain collection and equipment handling | Smooth onset; some navigation cues become harder to read |
| Mist | Close-range investigation and directional sound cues | No supernatural sound-as-GPS; fewer distant visual cues |
| After rough weather, later expansion | Newly exposed or drifting debris and repairs | Rough seas and large storms are outside the first demo |

Story progression is a graph of knowledge requirements. Each necessary fact has multiple possible encounter sources or evidence routes. Chance chooses the source, location, timing, and complications; player interpretation and choices advance the graph. Increase opportunities after long dry spells, and keep drawing from currently valid weather-compatible alternatives. If the player misses or destroys a clue, preserve a later route to the same essential knowledge.

All encounters can still be chance-based while progression is protected at the level of information availability. A bounded opportunity guarantee is a deliberate constraint on randomness, not a claim of pure independent chance. Review that tradeoff in the design session.

Separate RNG streams for weather, wildlife, story opportunities, and decoration. Save their state alongside persistent consequences and active events. This makes bugs reproducible; full replay also needs player inputs and deterministic simulation assumptions. Repeated playthroughs should feel different, but a finite system cannot guarantee mathematical uniqueness.

## 8. Engine and language decision

**Choose Godot 4, typed GDScript, and Godot shaders for the first visual/playable experiment.** Pin a stable version at project setup. Use Forward+ initially, subject to the actual Mac's support and measured performance. Use Blender for original geometry and rigging, exporting glTF/GLB, and Git for source and design history.

This is a workflow judgment: a small team can iterate on scenes, scripts, resources, and custom painterly shaders in a compact project. Typed GDScript keeps the code close to the editor and supports rapid tuning. Your CS background lets us focus on engine architecture, graphics, physics, and design rather than basic programming lessons. Reconsider C# if you strongly prefer its tooling or have a concrete library requirement; avoid a mixed-language project initially.

Godot supports macOS, including native Apple Silicon and x86_64 builds, and officially supports GDScript, C#, and C++. [Godot FAQ](https://docs.godotengine.org/en/stable/about/faq.html)

| Option | Fit for this project | Main tradeoff |
|---|---|---|
| Godot + typed GDScript | Preferred for the painterly prototype and direct ownership of compact systems | Budget real work for water shading, buoyancy, and custom art direction |
| Unity + C# | Strong alternative if its existing HDRP water/cloud workflow substantially reduces our workload | Rendering-pipeline choice and Mac performance need an early benchmark |
| Unreal + Blueprints/C++ | Alternative if the ambition shifts toward high-end naturalistic rendering | Larger production workflow; verify Mac-specific rendering support before choosing features |

Godot documents Forward+, Mobile, and Compatibility renderer differences; volumetric fog requires Forward+. It must be an optional quality layer rather than essential to puzzle readability. [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [Volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)

Unity's HDRP includes water and volumetric environment features; Unreal documents its Water System and Mac-specific requirements. These establish capabilities, not a measured performance comparison. [Unity HDRP environments](https://unity.com/blog/lighting-and-environments-hdrp-updates-unity-6), [Unreal Water System](https://dev.epicgames.com/documentation/en-us/unreal-engine/water-system-in-unreal-engine), [Unreal Mac requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/macos-development-requirements-for-unreal-engine)

Initial architecture: BoatController, shared OceanSurface height/normal sampling for visuals and buoyancy, WeatherController, WildlifeAgent, EncounterDirector, InteractionController, StoryKnowledge, and SaveState. Encounter and species definitions should be editable resources. Keep school-level visuals inexpensive; individually simulate only nearby interactive animals. A moving local ocean and streamed encounters can create open-water scale without simulating an entire ocean.

## 9. Build sequence and exit criteria

| Stage | Work | Ready to move on when |
|---|---|---|
| 0. Flesh out | Resolve the design questions in section 1; select setting and premise | We can describe one ordinary minute, one memorable encounter, and the ending's player action |
| 1. Art comparison | Review this board; make matching engine views and short camera-motion captures | A direction reads well at boat distance and in first person |
| 2. Visual experiment | Calm ocean, boat buoyancy, sky, fog toggle, third/first-person camera | Attractive and comfortable in motion on the target Mac, with measured frame times |
| 3. Interaction prototype | Steering, fishing, inspecting, one reactive school, save/load | Catch/release and interruptible inspection work without stealing control |
| 4. Story prototype | One complete navigation puzzle with two clue routes and a playable outcome | Solving changes the journey; losing one clue does not block completion |
| 5. Replay variation | Weather transitions, weighted encounters, cooldowns, persistent consequences | Multiple seeds differ meaningfully and preserve viable progression |
| 6. Polished demo | Wildlife animation, audio, materials, readable minimal interface | The 15–20 minute slice conveys wonder, survival, agency, and discovery |

First-demo budget: one small boat, one local ocean region, one character, three encounter types (fish school, seabird activity, floating habitat), one catchable fish, three gentle weather states, one puzzle with two evidence routes, one story milestone, one save slot, and replayable seeds. Start with a small suite of authored event variations. Keep multiplayer, major storms, huge waves, complex base building, free diving, and a global ecosystem out of this slice.

Target 60 fps at an agreed internal resolution on the actual Mac, then choose a 30 fps quality option only if that tradeoff is acceptable. These are targets, not established results. Profile water, transparency, shadows, animal count, and volumetric effects before expanding scope. Test at the intended render resolution rather than silently using the full Retina panel resolution.

Validate the director with a batch of seeds for impossible prerequisites and excessive waits; manually play a smaller representative set because simulation alone cannot verify meaning or enjoyment. Test missed clues, interrupted puzzles, unhelpful weather, harmful interaction, and save/load during events. Validate art from both cameras and in every demo weather state.

Include a comprehension playtest without developer narration or explanatory prose: can a new player discover the interaction, recognize its consequence, and infer the next useful action? Improve the scene, feedback, or interaction where understanding breaks down; add a brief prompt when necessary. Check that a wildlife encounter communicates the intended fact accurately, rather than merely looking attractive. Test optional accessibility text separately so reducing default text does not remove access to essential information.

## 10. How we work together

Work in short, reviewable increments with a visible result each session. I can scaffold a system, explain its constraints, and review changes; you can take ownership of a substantive feature immediately. A good first contribution is the shared wave-height function and buoyancy tuning, or the encounter resource and weighting logic.

Each increment ends with a playable check, a small code review, and a decision about what felt right. Keep three short notes: current visual target, current gameplay question, and next experiment. Avoid expanding the feature list until the ocean, camera, and one encounter feel convincing.

The immediate next milestone is refining the selected paper-cutout look, including shallow dimensional geometry and gentle deformation. Inventory, additional weather effects, and natural time-of-day transitions are recorded for later. The subsequent calm-water engine experiment should answer one question: does simply being in this boat feel like the game we want to make?
