# Execution, integration, and later delegation

## Planning boundary

The initial camera/world/art/gameplay decisions were developed together in one context, as requested. This package is the integrated planning baseline. No subagents were used to fragment that design, and no game implementation is claimed here.

Implementation can be divided after this baseline is reviewed and the relevant shared contracts are set. Experimental choices remain explicitly provisional. Subagents should implement bounded tasks against those contracts, return findings, and propose contract changes to the integration owner instead of independently redefining the game.

## Shared architecture and ownership

Godot 4 and typed GDScript are the baseline. Use one engine project and a few focused scenes/resources. Avoid building a general framework or introducing plugins before an experiment shows a concrete need. The architecture below is a plan; types and folders are not yet implemented.

| Module | Owns | Must not own |
|---|---|---|
| WorldController | Simulation clock/pause, bucket motion, local coordinates/rebasing | Camera-specific reward or progression rules |
| OceanSurface | Shared height/normal/flow sample and visual surface parameters | Separate invented buoyancy height in another module |
| EnvironmentController | Weather, time, transitions, shared environment snapshot | Per-camera weather choices |
| CameraController | Pitch, projection, smoothing, framing, screen/world projection | Collision, item state, fish outcomes |
| InputRouter / InteractionController | Action mapping, active mode, selection, cancellation | Duplicate competing control handlers |
| Asset visuals | Geometry/cards, deformation, materials, animation, visual anchors | Physics/capability changes caused by billboard transforms |
| InventoryController | Item instances, slots, equipment, capability queries | Encounter placement or independent reward rerolls |
| FishingController | Fishing states, fish-fight model, cast/line state | General weather clock or storage mutations outside transactions |
| EncounterDirector / EncounterInstance | Opportunity selection/placement; local lifecycle and actors | Rewriting story facts or camera transforms |
| Knowledge / StoryController | Observations, milestone predicates, consequential history | Fixed global destination requirements |
| OutcomeCoordinator / SaveController | Idempotent outcome commits and complete save snapshots | Generating new rewards during load |

Keep logical state serializable without visual nodes. Use stable IDs for items, encounters, actors, targets, and outcomes. Camera/style changes should not require a save migration because they are representations of the same logical world.

## Minimum interface contracts before parallel implementation

These are interface sketches, not final API signatures. Use meters, seconds, documented coordinate axes, and versioned records consistently.

| Contract | Required contents / behavior |
|---|---|
| EnvironmentState | Simulation time, time phase, weather values/transition, wind, swell, visibility; immutable snapshot for readers during a tick |
| OceanSample(position, time) | Height, normal, and local flow/velocity with documented units; same phase/origin as rendered surface |
| CameraProfile / CameraState | Projection, vertical FOV policy, allowed pitch/yaw, anchor/framing; targeting uses active projection |
| InteractionTarget | Stable target ID, world anchor/shape, range, supported verbs, availability; visual card scale cannot increase range |
| InteractionSession | Owner/mode, selected target, allowed inputs, interruption/exit behavior, requested camera framing |
| ItemDefinition / ItemInstance | Definition ID, capability tags, stack policy, representation ID; instance ID, quantity and relevant mutable state |
| EncounterDefinition / Instance | Eligibility and family; stable ID, reserved placement, actors, state, RNG/reward commitments, persistence |
| Outcome | Unique transaction ID, evidence/capability effects, item rewards/losses, encounter result, consequence references |
| StoryState | Knowledge IDs with evidence provenance, milestone states, relevant choices; no camera or global-heading predicates |
| SaveSnapshot | Schema/content version, logical world state, all RNG states, pending outcomes, clock/environment, inventory, active encounter/fishing state |

Use a single outcome application path. A completed puzzle or catch emits an outcome with a stable ID; applying it updates its owners once. Record enough transaction state that save/load cannot grant an item twice or lose the matching story observation. Visual feedback follows the accepted outcome, not an independent guessed result.

Provide deterministic fixture data for isolated module tests. Validate facts/capabilities as IDs at content load so a misspelled prerequisite cannot quietly make an encounter impossible.

## Systems that also need explicit planning

### Input, interface, and minimal text

Define input actions and mode precedence before fishing and inventory proceed independently. Separate camera tilt from aiming and movement. Pointer and controller use the same world-targeting rules. Provide clear focus, cancel/back, and pause. Do not let opening the pouch accidentally cast or discard an item.

World motion is paused by the prototype inventory/settings rule. Fishing and puzzle interaction boundaries must reconcile state before switching modes. The source of truth is the simulation clock; audio, weather and particles need a documented pause policy rather than arbitrary process-mode defaults.

Use concise settings/accessibility labels; keep gameplay explanation mostly visual. Inventory counts can use numbers when counting individual drawn objects would be confusing. Provide a visible equivalent for essential sounds and shape/motion equivalents for color distinctions.

### Audio and animation

Build a small audio vocabulary: bucket/water contact, paddle movement, wind/weather change, line load, bite commitment, and wildlife response. Place sources where the event happens. Mix important interaction cues clearly without turning every event into a notification. Pair animation and audio timing with the actual simulation state.

Animation needs idle breathing/settling, paddling, casting, tending a line, observation, landing/release, and interrupted action transitions. Treat the oversized jersey and small child's reach as constraints on the rigs. Avoid lengthy uninterruptible animation masquerading as interactive story.

### Saves, reproducibility, and content versioning

Save simulation snapshots at coherent tick boundaries or safe interaction points. Include pending rewards, fish/line state, encounter lifecycle, RNG state, environment transitions, and inventory transactions. If a particular active state is initially unsupported, establish a visible safe checkpoint policy before calling save/resume complete.

Use versioned schemas and explicit migration/rejection behavior. A seed alone cannot restore player actions, consumed loot, or evolved world state. Repeatable test fixtures are separate from a promise of bit-identical physics across platforms or future engine versions.

### Performance, tooling, and source control

Record the target Mac and render resolution first. Target 60 fps, then measure CPU/GPU cost, frame-time spikes, transparency/overdraw, materials, shadows, water, and scene counts. Define a low-cost quality preset and compare readability there. Do not optimize by silently shrinking the tested camera range.

Keep a developer-only panel for seed, director decisions, opportunity prerequisites, camera pitch/FOV, environment state, active interaction, and timing. Production UI should not expose this implementation detail. Keep screenshots/captures associated with the exact scene/version and settings.

Use small feature branches/commits, source assets plus exports, and an engine-generated-file ignore policy. Store large source media appropriately if it becomes necessary; Git LFS can be evaluated when asset size warrants it, not installed speculatively. Do not commit credentials or machine-specific cache data.

### Research and provenance

Every implemented wildlife fact needs a source and a clear separation between observation and gameplay abstraction. Keep authoring/source information for art, audio, and references. Existing generated concepts are not a rigged asset library or verified biological reference. Select the region before final species production.

## Ordered implementation milestones

| Stage | Work package | Required output and exit gate |
|---|---|---|
| P0: Integrated planning | This package; unresolved decisions recorded | Shared constraints and provisional choices are explicit; no conflicting active briefs |
| P1: Camera and proxy scene | R0/R1, child/bucket scale, ocean/sky, target projection | Compare low/high views and transition; choose what sky visibility must mean |
| P2: Representation and cohesion | R2/R3, matched flat/paper/low-poly/medium-poly set | Chosen visual direction, supported view range, anchors/material contract |
| P3: Play foundation | Steering, input modes, clock, interaction targets, save skeleton | Stable world-space actions across pitch and pause/resume |
| P4: Fishing and inventory | Practice fishing, starting kit, one useful find, transactions | Full fishing loop and meaningful tool use without hunger/thirst |
| P5: Encounters and environment | Three families, persistence, gentle weather transition | No camera/heading rerolls, plausible transitions, local continuity |
| P6: Puzzle-led story slice | One complete milestone, two opportunity routes | Playable consequence, no prose dependency or rare-drop block |
| P7: Variation and polish | Replay batch, manual plays, sound, animation, accessibility, performance | Coherent 15–20 minute target experience across representative seeds/settings |

Do not treat this as a fixed calendar estimate. After P1, estimate the next milestone from observed iteration cost. Avoid producing an entire asset library or final narrative before the camera and one interaction work.

## Later subagent work packets

Use one integration owner and at most three concurrently active subagents under the current tool limit. The following are logical ownership roles, not a requirement to spawn every role at once. Preserve the human creator's choice of a substantive coding task in each wave.

| Wave | Integration owner / human collaboration | Independent bounded packets | Boundary / prerequisite |
|---|---|---|---|
| 1 | Camera scene, projection, targeting; user can own pitch/framing or ocean sampling | Asset proxy/view-coverage study; data contract/fixture draft; wildlife reference shortlist | All use this plan; no production assets or new mechanics |
| 2 | Integrate chosen camera/assets and shared input/world clock | Inventory transactions + placeholder pouch; isolated fishing practice module; environment/director prototype with dummy events | P1/P2 decisions and interface contracts fixed enough to code against |
| 3 | Integrate one complete story beat and preserve overall feel | Encounter/puzzle content; production art/animation for approved list; audio/accessibility/performance pass | Fishing/inventory/environment interfaces working in a shared build |

When delegating, include: goal, dependencies, exact allowed files/directories, interface version, acceptance checks, forbidden shared edits, and required output summary. Proposed future code areas are `game/camera`, `game/world`, `game/fishing`, `game/inventory`, `game/encounters`, and `game/presentation`; finalize them when scaffolding the engine project.

The integration owner edits shared project configuration, input actions, autoloads, core contracts, and integration scenes. Other agents submit interface-change requests rather than modifying those files concurrently. Distinct worktrees may be used for conflicting work; otherwise assign non-overlapping paths in the shared checkout. Agents must not reset or overwrite another contributor's work.

Each packet returns what changed, how it was validated, known limitations, and integration instructions. Review code and playable behavior together before accepting the packet. A subagent's isolated success is not evidence that the integrated game works.

## Validation plan

| Area | Meaningful checks |
|---|---|
| Camera/assets | Complete tilt sweep, both target aspect ratios, low quality, rim/child/tool overlap, sky visibility, targets at reach boundary |
| Fishing | Learn without narration, distinct fish profiles, stable target while tilting, fair failures, cancel/pause/load |
| Inventory | Full slots, duplicate/unique items, reward committed once, lost baseline tool fallback, useful new capability |
| Director/world | Rotate equivalent scenarios, turn back, idle/observe, camera reveal boundary, no reward reroll, long travel/rebase |
| Weather/time | Shared interpolation, no despawn of hooked fish, no abrupt lighting mismatch, no sole rare weather progression gate |
| Story/puzzles | Two access paths, skipped clue, disrupted event, alternate evidence, minimal-text comprehension |
| Persistence | Save before/after reward and during supported interaction; load preserves clocks, targets, inventory and outcome IDs |
| Experience | Quiet moments remain enjoyable; spectacle stays interactive; tools and knowledge create recognizable progress |

Automate state invariants and prerequisite/reward validation where useful. Use manual playtests for comprehension, comfort, visual cohesion, and fun. No tests are required for every cosmetic edit; repeat validation when the relevant behavior changes or a known risk remains unresolved.
