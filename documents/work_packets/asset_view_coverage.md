# Asset view-coverage work packet

## Purpose and boundary

Define flat proxies that expose camera-compensation failures for R0/R1 and P1; final art and engine implementation are excluded. Dependencies: [integrated plan](../design/integrated_game_plan.md), [camera roadmap](../design/visual_engine_roadmap.md), and [asset contract](../design/asset_cohesion.md).

This assignment owns only this document. Agree the subsequent authoring directory with the integration owner, who owns camera code, shared configuration, materials policy, and scene integration. Return coverage gaps and contract requests to them.

## Exact minimum proxy set

This inventory is provisional. Preserve editable sources and stable IDs.

| Proxy | Exact first-test contents |
|---|---|
| Child | Eight neutral cards: front, rear, left, and right at two authored elevations, 20° and 52°. One additional 20° front casting pose to test hand/line attachment; nine cards total. Unsupported action/view combinations remain explicit gaps. |
| Bucket | Four independent pieces: rear wall, interior floor, front wall, and front rim. The rear wall includes its visible rim segment. Child/tool layers sit between rear and front pieces. |
| Fish | Two silhouettes of one provisional anatomically plausible fish: side and dorsal views. Reuse them for two behavior profiles; do not invent two species. Include a bendable body axis. |
| Sky | One broken cloud-ribbon card, reusable at different world positions, plus a plain sky gradient. |
| Ocean | One continuous base plane and one low-wave overlay card; no separate physical water height. |
| Fishing rig | One rod strip, one lure card, and one rendered line connected to explicit grip, tip, and lure anchors. Omit float pending rig selection. |
| Find | One recoverable-tool silhouette; reuse its drawing for an inventory preview. Exact tool remains provisional. |

Ichigo is an ungendered young child of unspecified age, with no hat, wearing their dad’s very oversized number 15 sports jersey. Keep 15 correctly oriented wherever visible; independently author opposing views instead of mirroring numbered artwork. Use a round wooden bucket giant relative to the child, with an unmistakable opening and staves. Hairstyle, footwear, sport, jersey colors, exact dimensions, and species remain provisional. Use the shared faded palette for comparisons.

## Evaluation matrix

Use perspective, 60° vertical FOV, fixed camera azimuth, no roll, and matched approximately 20–30% assembly frame height. Pitch is downward from horizontal. Run every row at 16:9 and 16:10, including a resize and the agreed smallest viewport.

| Pitch | Expected ideal sky band | Primary failure probes |
|---|---|---|
| 12° | Approximately 32% | Rim hides hands/child; near fish compress together; ocean overlays expose edges. |
| 20° | Approximately 18% | Default silhouette, oversized jersey/15, casting grip, bucket containment, and target readability. |
| 26° | Approximately 8% | Elevation substitution starts distorting faces/opening; inspect pose-switch popping and narrow horizon. |
| 38° | None | Interior coverage, false depth from layered walls, fish side-to-top changes, line/rim intersections. |
| 52° | None | Maximum card foreshortening, missing top surfaces, child hidden inside bucket, dorsal fish clarity. |

Sky values are geometric expectations, not captures. Sweep continuously both ways. Fixed camera azimuth does not fix actor heading: rotate child/bucket and fish through full headings, including oblique angles between authored views.

## Occlusion and transform probes

Check rear wall → child/tools → front rim/wall ordering against actual depth at every pitch; simple permanent layer ordering may fail at high elevation. Move fish behind the bucket, beneath water, and across silhouette boundaries. Record whether concealment reads naturally and whether target feedback remains understandable without seeing through opaque objects.

Compare unmodified cards, limited billboarding, bounded scale compensation, and elevation switching independently. Billboards cannot reveal interiors, unseen surfaces, correct anatomy, or missing silhouettes. Warping cannot repair self-occlusion. Avoid grazing-angle scale blowups. Check alpha sorting, exposed backs, double-image crossfades, threshold jitter, and shadows rotating with cards.

Keep simulation roots, collision, reach, heading, and target IDs independent of visual transforms. Document bend-before-orientation ordering for fish; rendered hand/tool attachments must coincide during deformation.

## Acceptance and shared decisions

Static review can verify inventory counts, identity, unmirrored 15, palette consistency, source provenance, axes, pivots, anchor declarations, and declared coverage gaps. It cannot establish camera readability or performance.

Runtime acceptance requires comparable captures and a failure log for every matrix row, full sweep, cast, actor turn, and bucket/fish crossing. Repeat readability checks with reduced motion and lowest quality. Record scene revision, settings, viewport, and measured frame times; label untested cases. R1 succeeds when failure angles and minimum extra views/geometry are documented, even if flat assets fail. Production readiness requires surviving the selected range and interactions.

Request shared decisions on supported range versus always-visible sky; framing/physical dimensions; accepted pose switching; transparency, shadow, and underwater-visibility rules; rig choice; and which failures justify shallow geometry. Preserve matched conditions for later flat, dimensional-paper, low-poly, and medium-poly comparisons. No runtime or artwork validation has been performed for this planning document.
