# Inventory and chance-based loot progression

## Purpose

Give discoveries a physical home and let equipment open new ways to play. The initial design omits hunger, thirst, eating, and drinking. Inventory should create anticipation and useful decisions without turning the journey into repetitive replenishment.

Progress has three persistent forms: what Ichigo has learned, which tool capabilities are available, and which story milestones have been completed. Items can enable a capability, but mandatory knowledge must have an alternative source. See the [integrated plan](integrated_game_plan.md) for this shared rule.

## Proposed starting inventory

| Starting object | Role | Loss policy in the first slice |
|---|---|---|
| Bucket and worn number 15 jersey | Vessel and character identity | Not ordinary inventory items; cannot be accidentally discarded |
| Simple paddle or scoop usable for steering | Reliable local movement | Baseline steering is always recoverable/available |
| Simple fishing rod/handline with line | Immediate access to the fishing loop | No permanent loss of the only fishing capability |
| One basic reusable lure | Lets the player fish without farming consumable bait | Recoverable fallback if an encounter consumes or loses the equipped lure |
| Small cloth pouch | Storage presented as recognizable objects | Fixed initial capacity; no storage-upgrade grind in the slice |

The exact paddle, rig, and pouch appearance must suit a child and bucket. These are proposed starting objects, not novel details. A visual fieldbook can be added only if it helps players remember observations; it is not mandatory written reading.

Prototype **six general storage slots**, separate from worn identity/vessel and baseline tool mounts. Stack only interchangeable materials, using small legible counts where needed. Treat six as a tuning value. Do not begin with weight, item rotation, spoilage, or automatic overflow deletion.

## Interface and interactions

Open a compact illustrated pouch/inspection layout while keeping the world visible. Show actual recognizable objects; select, use/equip, inspect, stow, or deliberately discard. Provide controller and pointer equivalents. Use a consistent slot focus highlight and a brief optional name for ambiguous objects. Item text is not the primary way to explain its use.

Keep inventory presentation separate from camera projection: a world item has a stable identity even if its representation changes with camera pitch. Short camera framing may improve visibility, but inventory access must not require a particular camera angle.

Proposed slice behavior: inventory and paused settings freeze simulation; active fishing/puzzle interactions return to a clear safe boundary before opening the pouch. Test whether this preserves flow. Implement this as one global pause rule so weather cannot secretly continue while fish freeze. A later real-time inventory mode is an explicit design decision, not an accident of UI implementation.

When capacity is full, keep the reward in a pending interaction/tray with replace, leave, or discard choices; no silent loss. World finds remain physically present for the local persistence window. Story evidence goes to knowledge state after meaningful observation and does not depend on a free item slot. Dangerous or irreversible item actions must be deliberate.

## Reward families

| Reward | Source | What it changes |
|---|---|---|
| Useful material | Plausible floating debris/salvage | Repairs or modifies a tool when that system exists |
| Tool component | Human-made lost gear, recovered object | A distinct handling/reach/retrieval capability |
| Lure variation | Crafted/recovered fishing gear | Presentation or attraction tradeoff, not a universal stat upgrade |
| Wildlife observation | Watching/interacting successfully | Visual knowledge record and new encounter interpretation |
| Keepsake | Authored physical story encounter | Recurring motif or relationship, with minimal text |
| Optional collection | Recognizable shell/debris/specimen appropriate to setting | Personal expression and discovery, without required completionism |

Fish do not drop arbitrary metal/tool loot. Retrieval while fishing must visibly snag an actual object. Helping wildlife does not guarantee a gift. Avoid rarity colors as a substitute for a meaningful use.

## Chance-based progression model

Define reward tables by encounter family, environment, unlocked capabilities, ownership, and recent rewards. Roll a result once at a defined point, store it on the encounter/reward record, and preserve it through camera changes and save/load. Turning around or reopening inventory must not reroll it.

Use duplicate protection for unique tools and lower the frequency of redundant finds. A repeat common material must still have a known use, otherwise prefer a different eligible result. Introduce a new affordance in a safe nearby opportunity soon after acquiring its tool so its purpose can be learned through use.

Rarity creates surprise; essential progression cannot depend on an unbounded rare drop. Each required capability needs either a deterministic recovery/crafting route from ordinary available materials or multiple encounter alternatives with a bounded opportunity safeguard. Count relevant completed opportunities, not meters travelled, camera movements, or arbitrary clicks. The safeguard guarantees access to an opportunity, not an automatic reward for ignoring it.

Milestone availability depends on useful actions and existing knowledge. Do not fill every quiet interval with a reward. Keep optional rare/cosmetic finds genuinely optional and avoid endless vertical stat increases that make earlier tools meaningless.

## Failure and recovery

A fish escaping can cost time, position, or a recoverable lure. The player retains a basic viable way to fish and move. A dropped unique progression item remains recoverable or has an alternate capability route. Save pending rewards and transactions to prevent duplication when closing the game halfway through a pickup.

Proposed catch outcomes: release after observation; temporarily keep a specimen if it has an authored use; or leave the interaction. Permanent fish storage is not automatically valuable now that eating is omitted. Test whether keeping adds a meaningful choice; remove empty collection bookkeeping if it does not. Observation can be recorded on release, so retaining/killing every fish is not the only progression route.

## Implementation sequence and checks

1. Define ItemDefinition, ItemInstance, capability tags, and inventory transactions from the shared contracts.
2. Implement starting kit, add/remove/equip, capacity, and save state with placeholder UI.
3. Connect one physical find to the pouch and one tool to a visible new action.
4. Add a small reward table, duplicate protection, fixed reward IDs, and a fallback capability route.
5. Test the loop with fishing and the story milestone before expanding the item list.

Acceptance: full inventory, duplicate reward, interrupted pickup, loading after a roll, discarded optional item, failed fishing, and repeated dry reward streaks all preserve coherent state. No seed requires eating/drinking or permanently blocks the baseline tools. New players can explain what a discovered tool lets them do after seeing its use.
