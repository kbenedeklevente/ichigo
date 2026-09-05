# P1 visual review and feedback gate

Status, 5 September 2026: first runnable camera study. Godot 4.7.2 stable on Apple M2 / 8 GiB, Compatibility renderer, 1280×800 capture viewport. The normal launch stays open; `--capture-dir` intentionally exits after five saved images. Both automated capture sessions completed with exit status 0, not a crash.

## Implemented and observed

- A continuous bounded camera tilt with 12°, 20°, 26°, 38°, and 52° capture samples; wide and sky-preserving profile controls.
- Screen-relative bucket movement, a shared calm-water wave fixture, fish motion proxies, and a sky with pale horizontal ribbon clouds.
- A young-child/bucket placeholder with oversized number 15 jersey, no hat, open wooden bucket interior, and a visible rod.
- Reachable-water line targeting with wave-surface refinement and bucket-occlusion rejection. Committed coordinates survive camera changes.
- Pause/resume, cancel, mouse/keyboard bindings, controller mappings, and hideable developer controls.

Rendered captures were inspected at 20° and 52°. The first inspection exposed ocean geometry showing inside the bucket; both ocean layers now mask that interior, and the later captures show its floor instead. Lighting was calibrated to avoid clipping the placeholder wood into bright yellow. The higher view reveals the bucket interior and nearby water but loses the horizon, as the geometry predicted. The 20° view retains a narrow sky band.

A normal session was launched and its live window inspected. An observed UI state showed the sky-preserving range clamping a detail request to 26°, consistent with that profile. This is not a comprehensive physical-input/device test. Full controller and GUI-routing checks remain open.

## Verification boundaries

123 camera/ocean contract checks and 34 actual-scene integration checks passed. See [execution notes](p1_test_notes.md). Proxy instantiation and pose/anchor smoke checks also passed. Rendered screenshots establish that this scene draws; no sustained frame-time benchmark or finished gameplay-quality claim has been made.

The proxies currently use shallow modeled/low-detail forms. They are not the full directional flat-card library or a completed paper/low-poly/medium-poly comparison. Fish sit at the surface for visibility testing; convincing underwater presentation is still open. There is no inventory, fishing fight, encounter director, progression, weather cycle, or save system in this build.

## Decisions requested from the user

1. Retain the full tilt range with a sky-visible default, restrict normal motion to keep the sky present, or revise framing before choosing?
2. Make the child and bucket larger on screen, retain the current framing, or make them smaller to emphasize the ocean?

Character appearance, final geometry/material style, camera policy, and gameplay choices require user feedback before being locked. The current implementation values remain provisional. The next visual work applies that feedback, then produces matched flat-paper, dimensional-paper, low-poly, and medium-poly representation comparisons.
