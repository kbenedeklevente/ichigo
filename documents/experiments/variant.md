# 02 — Faded Tides

A quiet, sunbleached ocean: low overlapping scallops carry fine engraved currents and small ivory foam scrolls. The broad pale waves should read as flowing printed paper around a solitary brown bucket. This branch is a runnable visual experiment, not final art approval.

## Plan and implementation

1. Replace the narrow asymmetric fin with a 5.1–5.8 m rounded span and a nominal 0.34 m rise. A smooth broad envelope overlaps neighbouring swells, and a shallow cosine undulation scallops the crest in plan. Both the CPU sampler and GPU deformation use the same coefficients. Travel slows from 0.38 to 0.24 per phase unit.
2. Redraw the crest SVG as pale aizuri blue and dusty teal washes, long families of fine parallel current lines, broad aged-ivory scallops and nested foam scrolls. Tiny ochre/rust strokes provide restrained warm notes. This is original vector artwork; reference paintings are not pasted into the scene.
3. Map the broad shoulder into the engraved atlas, the rounded lip into the ivory foam band, and the softened front into pale teal. Keep the existing connected mesh and triangle-exact gameplay sampler so the bucket, targeting and waves occupy one surface.
4. Fade the sky to blue-grey with long irregular horizontal ivory cloud ribbons. Match the far-water haze to the muted near-water palette.
5. Preserve the brown bucket, modest framing, hatless child, oversized jersey with readable 15, 12–52° camera with 20° default, weather controls and five-angle capture mode.

## Palette

| Role | Colour |
| --- | --- |
| Pale aizuri wash | `#89b0bb` |
| Dusty teal front | `#719ba6` |
| Quiet water paper | `#a9c4c4` |
| Aged ivory foam | `#f0e6cc` |
| Engraved contour | `#5c8797` |
| Sparse ochre / rust | `#b79b6a` / `#aa7961` |

The shared geometry is deliberately much wider and lower than the starting pointed-wave study. Its overlapping calm relief measured 0.406 m in the existing triangle-sampling fixture, with maximum sampled front slope 0.795. The art-specific regression limits now reject steep fins while preserving real relief.

## Run and compare

Double-click `Run Ichigo.command`, or run:

```sh
./scripts/run_game.sh -- --weather-study
```

The window title is **Ichigo — 02 Faded Tides**. Capture arguments are unchanged:

```sh
./scripts/run_game.sh -- --weather-study --capture-dir=/absolute/output/directory
```

Captures cover 12°, 20°, 26°, 38° and 52°. Review low-angle scalloped silhouettes, visible parallel engraving at 20°, and atlas transitions at 52°. The brown bucket should be the strongest warm focal point.

## Verification and limits

- Godot 4.7.2 headless editor import: passed.
- Camera contracts: 118 checks passed.
- Shared raised-water geometry: 47 checks passed, including exact mesh triangle heights, normals, cell-edge continuity and camera-independent anchors.
- Weather scene integration: 15 checks passed; 30-frame headless weather startup passed.
- The weather scene assertion now compares storm buoyancy to the actual shared illustrated surface; its previous root-only comparison was invalid when a broad crest covered the origin.
- Graphical capture and visual approval belong to the integration review; headless import does not prove GPU appearance. No graphical Godot instance was launched during this branch implementation.

Limits: bounded nearby mesh density and dominant-crest atlas selection remain experimental. Engraved lines can merge into a wash at distance; the design intentionally embraces that print-like simplification. Local weather can darken this faded palette. The existing child remains a procedural proxy.

## References

- [Katsushika Hokusai, *At Sea off Kazusa*, ca. 1830–32, The Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/56238): ink and colour on paper, public-domain collection record. Used for the visual relationship between patterned water and horizon bands, with a deliberately lighter palette here.
- User-provided `codex-clipboard-8c1e41d6-b6f3-4277-8bf2-cf99439c6c67.png`: *The Great Wave* reference, inspected for nested foam and flowing current contours.
- User-provided `codex-clipboard-6ff73741-db84-4099-a1b7-a03faed12f51.png`: red Fuji reference, inspected for flat, irregular horizontal ivory cloud ribbons.
