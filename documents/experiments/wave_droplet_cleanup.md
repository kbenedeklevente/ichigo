# Paper Theatre wave droplet cleanup — 6 September 2026

The user requested removal of the isolated cream teardrop dots with indigo outlines shown in their reference crop. This is an authorized artwork correction to the [selected Paper Theatre study](variant.md).

Removed seven standalone teardrop paths from each of `theatre_curl.svg`, `theatre_double.svg`, and `theatre_sweep.svg`: 21 paths total. Inspected `theatre_ribbon.svg`; it contains none and remains unchanged. Wave contours, foam spirals, engraved flow lines, and palette are preserved. Renderer, motion, weather rain, physics, and character assets are unchanged.

All four SVGs parse successfully. Godot 4.7.2 headless editor import passed, and `git diff --check` passed. All five camera captures completed successfully. The integration review inspected the 20° frame and confirmed the isolated droplets are gone while the wave silhouettes and spiral patterns remain. Updated captures are in `gallery/current-paper-theatre/`. No motion change is included.
