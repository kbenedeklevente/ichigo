---
name: ichigo-design-context
description: Retrieve the relevant Ichigo game plans before discussing or changing a system, then keep its design, implementation status and next steps aligned. Use for Ichigo gameplay, art, camera, weather, events, fishing, inventory, story and architecture work.
---

# Ichigo design context

Work from the relevant part of the maintained game plan, without loading the whole documentation tree.

## Find and read

Use the current Ichigo checkout/worktree as the root (`git rev-parse --show-toplevel`); do not silently switch a worktree task to main. Confirm it contains `documents/design/integrated_game_plan.md`. If working outside a checkout, locate the user's selected Ichigo project before editing.

Read `documents/design/context_map.md` and the current constraints/status sections of `documents/design/integrated_game_plan.md`. Route the user's subject through the map and read the named primary plans. Follow only the cross-system links needed by the requested behavior. For example, fish catch rewards need fishing plus inventory; fish appearance only needs fishing's visual needs plus asset cohesion. Do not load all systems just because the game is interrelated.

For implementation, inspect the current code and relevant latest work packet before claiming a plan is built. For a design-only question, consult code only where implementation status affects the answer. Historical concept art and old work packets are evidence, not newer decisions.

## Reconcile and act

The user's current request and accepted session decisions take priority over older documents. Distinguish accepted constraints, proposed designs, isolated experiments and verified implementation. Check dated amendments and linked implementation reviews; filenames or old headings such as “latest” do not establish precedence by themselves.

Briefly state which system plans guide substantive work and identify material conflicts. Apply already authorized decisions. If a new design choice needs the user's input, present the concrete choice and wait; silence or a timeout is not approval. Continue independent authorized work while waiting. This skill does not require renewed approval for routine fixes or choices inside an explicitly authorized experiment.

Keep the task's next step concrete and bounded. When delegating, pass the affected documentation paths, accepted constraints, ownership boundary and expected verification. Do not have independent agents invent incompatible shared contracts.

## Keep the plan truthful

When behavior or an accepted design changes, update the owning document in the same change as the implementation. Update dependent documents only where their claims or interfaces changed. Preserve unresolved questions as unresolved. Record relevant validation and the next review/implementation step; do not present headless tests as visual approval.

Keep experiments in `documents/experiments/` on their own branches and mark them as proposals until selected. Do not rewrite the main game direction to match an unselected variant. Read-only questions do not require ceremonial documentation edits.

When adding, moving or superseding a system document, update `documents/design/context_map.md` so future retrieval remains correct. Prefer one canonical explanation and links over copied requirements. End with the outcome, checks/limits and any decision still awaiting the user, linking the changed plans when useful.
