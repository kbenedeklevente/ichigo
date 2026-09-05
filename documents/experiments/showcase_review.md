# Wave art showcase review

**Selection, 6 September 2026:** Paper Theatre is the chosen direction, merged into main at `1622c52`. Other active studies are retired. Keep the selected waves and match the child/bucket artwork next. The comparison notes below record the earlier review process.

6 September 2026. Five isolated implementations from baseline `8255dd4`; no artistic winner merged. The user's current priority is finding the visual balance: drawn detail, separate paper layers, calm open space and convincing motion. Fish remain secondary.

Open [the comparison gallery](gallery/index.html). It contains 25 actual Godot viewport captures for the five variants (12, 20, 26, 38, 52°), a baseline comparison and five archived earlier milestones. All gallery images are committed for future comparison. The exact initial rounded-crest source state was not separately committed; its history entry explicitly identifies an archived image only.

| Variant | Main source commits before common documentation updates | Findings and limits |
|---|---|---|
| Prussian Ink | `b02e451`, `d29d3ff` | Strong dark carved currents; broad relief survives camera tilt. Fine light contours alias at distance. Still uses a shared mesh and procedural child/bucket. |
| Faded Tides | `b611a65`, `6587b6d` | Quiet pale palette and wider, lower swells. Engraving is delicate and can shimmer or disappear with distance; original child/bucket proxy remains. |
| Paper Theatre | `08899e5`, `5a29e5d` | Bold independent curl silhouettes. Added separate low ribbon cards after captures exposed broad gray gaps at high angles. Repetition and visible paper joins remain. |
| Woodblock Wings | `5975728`, `b0de449` | Long simple scenic bands give broad graphic shapes. Sloped overlapping flats cover the camera range; scalloped ends reduce square cutoffs. Band joins and repeated motifs still need composition work. |
| Ink Diorama | `56d836b`, `22f4e28` | Full illustrated child/bucket and curved paper ocean props. Corrected the small jersey drawing so 15 is unmistakable. Rectangular joins, distant moiré and single-view character coverage are still experimental. |

## Verification

All five imported and produced their five-angle captures in Godot 4.7.2, Compatibility renderer, 1280×800 on the user's Mac. Capture runs intentionally exit after saving their images; this is not a game crash. Default calm captures share seed 15 and presentation time 1.5. Root inspected each variant at the low, default and high angles; obvious gaps and label/jersey errors received follow-up commits and recaptures.

Agents ran construction-appropriate checks: shared-surface reconstruction for 01/02, camera contracts, weather integration or card/scene checks for the theatre branches. Headless checks passed as documented in each branch's `documents/experiments/variant.md`. This is not full user visual approval, a measured 60fps claim or completed moving-weather QA. Fine-line aliasing, layer seams and production-quality motion remain review subjects.

The browser gallery was checked for loaded images, synchronized angle switching and readable layout. Images open for closer inspection; earlier archived frames keep their original camera framing. The source revisions in `gallery/manifest.json` identify the reviewed worktrees.

## Run or revisit

From the main checkout:

```sh
python3 scripts/wave_experiments.py run 3
python3 scripts/wave_experiments.py capture 3
python3 scripts/wave_experiments.py gallery
```

After selection, 3 launches main; the other worktrees are retired. `capture 3` saves a new character-pass set without overwriting the chosen wave baseline; `gallery` updates the HTML and manifest. Inspect and commit refreshed captures together with their source changes. Opening `gallery/index.html` directly works offline; to serve it locally:

```sh
python3 -m http.server 8767 --bind 127.0.0.1 --directory documents/experiments/gallery
```

The temporary worktrees under `/Users/benedekkoos/projects/ichigo-experiments/` were removed after selection. Branches are `codex/01-prussian-ink`, `codex/02-faded-tides`, `codex/03-paper-theatre`, `codex/04-woodblock-wings`, and `codex/05-ink-diorama`. Each branch's commit history preserves its refinements. The earlier main revisions remain available without resetting main; use a separate checkout when revisiting them.

## Next review

Choose which visual qualities to keep, rather than treating one experiment as an indivisible winner. Then refine ocean cohesion, independent motion, repetition, camera coverage and bucket framing. Do not expand fishing or require fish-specific integration during that pass. Theatre branches retain an invisible gameplay sampler; exact matching between decorative crests and interactions is deferred.
