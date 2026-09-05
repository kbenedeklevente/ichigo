# Wildlife encounters and environmental puzzles

## Current implementation proposal

Use [encounter fields and pacing](encounter_fields_and_pacing.md) for the six candidate events, weather-dependent rates, exclusive encounter gate, stable weather during encounters, sparse spatial index, optional local modifier matrices and wind-driven departure. Off-screen retirement and quest completion are separate outcomes. The new numerical pacing values are proposals, not yet implemented or approved.

## Purpose and shared constraints

Encounters make the ocean feel inhabited and offer observation, interaction, discovery, and occasional danger. Animals have their own behavior before, during, and after the player's involvement. Every encounter must remain playable and legible through the supported camera range, with minimal required text.

Use one researched region/season for the first content set. The examples below are design hypotheses; validate species, co-occurrence, timing, scale, feeding behavior, and reactions before presenting them as wildlife facts. Do not turn an association into a guaranteed natural rule simply because it is convenient for a puzzle.

## Three-set classification

L = learn a wildlife/survival fact; C = work with nature to gain access to a useful material/tool/capability; V = visual wonder. These are intended payoffs. A visually polished learning encounter does not automatically need a V tag; a C-only encounter can reuse knowledge already learned.

| Venn region | Design sketch | Agency |
|---|---|---|
| L | Examine a caught fish's identifying features | Observe, release, or retain if supported |
| C | Use an already familiar drifting habitat to approach loose salvage | Recover carefully, disturb it, or leave |
| V | Watch a school turn beneath the bucket | Drift alongside, paddle through, or move away |
| L + C | Learn a feeding pattern and apply it to lure presentation | Experiment successfully, mistime it, or disrupt the opportunity |
| L + V | Observe seabird search/feeding behavior | Follow locally, sketch the pattern, or scatter the activity |
| C + V | Apply known fishing behavior during a striking school encounter | Make a controlled catch or lose the school through disturbance |
| L + C + V | Understand a floating habitat's local movement, work with its drift to recover a useful object, and observe the life around it | Compare movement, choose an approach, retrieve or disrupt |

The collaboration set includes working with natural processes. It does not require animals to understand the player's goals. Any protected-animal intervention needs its own researched design; do not assume freeing an animal grants affection, transport, or loot. Fishing/retrieval can have negative consequences without awarding an abstract morality score.

## Encounter authoring contract

Every encounter definition includes:

- Stable ID/version, family, L/C/V tags, and source/abstraction notes.
- Eligibility: environment, time, weather, capabilities, knowledge, and exclusions.
- Observable cue and how it is readable at low/high camera pitch.
- Actors, bounds, local anchors, and continuous autonomous behavior.
- Available verbs, at least two materially different responses, and supported harmful/disruptive consequences.
- Opportunity window, progression relevance, reward/evidence alternatives, cooldown and repetition policy.
- Active/abandoned/completed states, persistence, interruption and save behavior.
- Audio/visual feedback and optional short accessibility description.

Lifecycle: eligible opportunity → placed and cued → active/approachable → interaction or bypass → resolved or left active → persisted/retired under world rules. The director owns availability; the encounter owns its local behavior; inventory/knowledge own committed outcomes. The camera only presents the situation.

## Puzzle design grammar

A good puzzle lets the player notice a relationship, form a hypothesis, manipulate something, and read the result. Use spatial arrangements, motion, shape, timing, and physical affordances. Provide multiple cues to essential relationships and avoid sequences distinguishable only by color, tiny markings, or sound.

Candidate families:

1. **Drift and intercept:** recover an object from a local moving arrangement by positioning the bucket and timing a hook/scoop. Observable relative motion matters; absolute compass heading does not. Alternative: obtain the same needed tool through another eligible salvage opportunity.
2. **Tension and routing:** untangle or route line around visible anchor points to release/retrieve an object. The state is readable through physical movement and load. Pulling carelessly may tighten the tangle or disturb nearby activity; backtracking remains possible.
3. **Observation and response:** infer when to approach or present a lure from a repeating, researched behavior. Avoid magic animal-command sequences. Another observation source can teach the same essential knowledge if this encounter leaves.
4. **Conditions and visibility:** use a change in light, water, or mist to reveal a useful local relationship. A required story fact must also have another source; do not force indefinite waiting for a rare weather state.

The first slice implements one family thoroughly, with two evidence/access routes. Decorative combinations should not multiply puzzle complexity before one feels satisfying.

## First integrated encounter proposal

A recoverable human-made tool is caught among drifting material near a small habitat. The player can watch its relative motion, paddle to a suitable local position, and use their fishing rig to retrieve it. Pulling through the crowded side disturbs wildlife and can snag the line; a patient approach uses the current's local movement to create a cleaner path. An alternative nearby arrangement offers a different approach when equipped with a previously found tool.

This links camera targeting, fishing controls, item capacity, wildlife response, and knowledge. The tool's usefulness is demonstrated by another reachable affordance. It is a candidate scene, not a claim that a particular real species/habitat behaves this way.

## Failure and story continuity

An encounter can be missed, disrupted, or abandoned. Preserve that consequence locally. Do not respawn an identical fresh version immediately behind the player or erase damage when the camera changes. The story system can later offer different evidence for the same required understanding, consistent with weather and available actors.

Helping, taking, and leaving should all be expressible through normal controls, without a text-based moral-choice menu. Not every response grants equivalent rewards, but no single cruel or altruistic action is mandatory merely because it holds the only progression key.

## Tasks and acceptance

1. Create six encounter cards spanning the Venn regions; label unverified natural-history assumptions.
2. Select three families for the slice, including one puzzle and one quiet spectacle.
3. Build the shared lifecycle and one encounter using placeholder actors.
4. Connect its fish/tool/knowledge outcomes through the shared event contracts.
5. Validate low/high camera views, bypass, disturbance, cancellation, weather transition, full inventory, and save/resume.

Pass when the player can perceive a cue, choose a response, see the consequence, and understand the learned relationship without a prose explanation. Ecological review and gameplay-comprehension review are separate: an encounter must be both accurate enough for its claim and understandable.
