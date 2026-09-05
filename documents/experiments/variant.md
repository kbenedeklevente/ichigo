# 01 — Prussian Ink

A playable original woodblock sea study: dark saturated Prussian blue supports warm ivory curling foam, broad light-blue carved contour bundles, and a parchment-to-indigo sky. The atlas is original SVG geometry, not a reproduction of a print.

The visible shape changes from short pointed fins into broad serpentine ribbons. Each crest bends sideways, varies smoothly along its crown, and carries a lower companion shoulder. The central high portions remain rounded; long tapered ends overlap into more continuous currents. A world-space carved current pattern connects the empty water between the raised ribbons. The 0.56 m face scale keeps the baseline modest, and the existing weather field continues to govern roots, amplitude, motion, buoyancy and target picking.

CPU `illustrated_water_surface.gd` and GPU `water_panel.gdshader` evaluate the same ribbon, crown, echo and taper equations. The existing connected mesh, sampling diagonal, camera range 12–52 degrees (default 20), hatless jersey-15 character, and wooden bucket remain the shared experiment controls. The title and visible subtitle identify this version.

References: [Hokusai, At Sea off Kazusa, The Met](https://www.metmuseum.org/art/collection/search/56238), for deep blue foreground, flattened depth and a horizon that echoes the foreground; [Shroom and Gloom development announcement](https://teamlazerbeam.itch.io/shroom-and-gloom-jam/devlog/745144/announcement-things-are-happening-with-shroom-and-gloom), for a coherent illustration vocabulary deployed in 3D space. User image references guided the contrast, curling marks and the desire for an actual shaped sea.

Run: `scripts/run_game.sh -- --weather-study`. Existing interaction and weather keys are shown in the HUD. This is an artistic comparison branch, not a final approved direction. The mesh is still a height field, so curls are illustrated contours and curved crest paths, not geometric overhangs. Repetition remains finite, though the seeded crown and sweeping width disrupt the earlier isolated fin rhythm. Distant carving is deliberately softened by the common haze boundary.

Validation: Godot 4.7.2 headless import completed cleanly with an absolute project path. The unchanged existing raised-wave reconstruction suite passed all 47 checks (triangle reconstruction, bounded relief, steep front faces, normals, seams, recentering, camera independence and field upload). One hundred shared samples took 0.99 ms in this run. Camera screenshots are captured by the parent experiment coordinator to avoid concurrent graphical Godot sessions.

Visual review: the coordinator captured the actual 20-degree view and confirmed strong differentiation. Fine crest lines show some jagged shimmering at distance; simplifying the distant ink or introducing a dedicated distance texture is a next-pass art/LOD consideration. This prototype retains that visible limitation for comparison.
