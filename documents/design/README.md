# Ichigo — integrated design and implementation plan

Status: planning baseline, 5 September 2026. Prepared together in one context before delegating implementation. These documents describe proposed systems and experiments; they do not represent an implemented game or measured performance.

For a specific game system, use the [context map](context_map.md) to load only its relevant plans. The repository [Ichigo design-context skill](../../.codex/skills/ichigo-design-context/SKILL.md) keeps this retrieval and documentation-update workflow consistent.

Start with the [integrated game plan](integrated_game_plan.md). It is the authority for shared decisions. Specialist plans refine it; they must not independently redefine the camera, progression, input, or world rules.

| Document | Responsibility |
|---|---|
| [Integrated game plan](integrated_game_plan.md) | Player experience, decisions, scope, dependencies, open questions |
| [Visual engine experimentation roadmap](visual_engine_roadmap.md) | Camera and projection, flat-asset transformations, paper/low-poly/medium-poly comparisons, atmosphere |
| [Asset cohesion](asset_cohesion.md) | Shared proportions, materials, view coverage, animation, production acceptance |
| [Inventory and loot progression](inventory_progression.md) | Starting equipment, storage, chance-based rewards, progression safeguards |
| [Fishing](fishing.md) | Complete minigame, controls, feedback, mastery, consequences |
| [Wildlife encounters and puzzles](encounters_puzzles.md) | Three-set encounter model, behaviors, puzzle authoring, player agency |
| [Overarching story points](story_points.md) | Minimal-text narrative structure, milestone graph, ending through play |
| [Raised illustrated-wave correction](raised_paper_waves.md) | Immediate visual priority: replace rejected horizontal sheets with raised crest assemblies and matching surface sampling |
| [Encounter fields and pacing](encounter_fields_and_pacing.md) | Latest exclusive-encounter requirements, weather-dependent rate proposals, spatial event index and local field composition |
| [Shared event system](event_system.md) | Trigger/chance activation, lifecycle, prerequisites, persistence and domain handlers |
| [Weather runtime parameters](weather_runtime_parameters.md) | Independent profiles, front timing, grid and spring tuning, executable study and limits |
| [Illustrated ocean and nested weather](paper_ocean_weather.md) | Latest visual feedback, square simulation/render grids, per-panel physics proposal, weather phases and pending decisions |
| [World, weather, and time](world_weather_time.md) | Direction-independent travel, persistent local space, event scheduling, natural transitions |
| [Execution and delegation](execution_and_delegation.md) | Shared contracts, ordered tasks, ownership boundaries, integration and validation |

The [development philosophy](../dev_philosophy.md) applies throughout. The [earlier concept plan](../../docs/concept/ocean-game-concept-plan.md) is historical background; its survival, navigation, and camera proposals are superseded where they conflict with this baseline. Existing [art studies](../../docs/concept/art/) supply palette and material references only: their adult, hat, and skiff are incorrect for Ichigo.

## Immediate next action

Current work: Paper Theatre is selected and merged into main (`1622c52`). Keep its waves and match Ichigo/bucket to the same paper aesthetic. Other visual variants are retired; the [gallery](../experiments/gallery/index.html) preserves the comparison. The original camera build instructions below are historical.

The first context split is now organized in [bounded work packets](../work_packets/README.md), with the primary agent retaining camera/integration ownership.

Build a camera-and-asset test scene with a child silhouette in a bucket, water, sky, one target, and one fish proxy. Compare angle and projection before producing a full asset set. The current request completes the planning package; implementation and subagent execution follow as separate work.

Implementation update: the [camera study](../../game/README.md) is runnable. The user selected the full tilt range and requested smaller framing, browner wood, and illustrated panels. Those follow-up choices are resolved. The [weather study](weather_runtime_parameters.md) now runs shared triggered/chance events, independent weather profiles, connected paper-water sheets and nested simulation. The raised-crest correction and salvage encounter-field foundation now run together. See the [latest implementation review](../work_packets/p2_wave_encounter_review.md). The user finds the pointed waves better; further visual refinement, child/bucket illustration and authored event content remain unfinished.
