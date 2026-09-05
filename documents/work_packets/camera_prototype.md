# P1 camera prototype — integration work packet

Owner: primary integration agent, with the human creator. Status: scoped and ready for engine setup; runtime implementation has not started.

Authority: [integrated game plan](../design/integrated_game_plan.md) and [visual engine roadmap](../design/visual_engine_roadmap.md). This packet narrows their first experiment; it does not finalize their open artistic choices.

## Question to answer

Can the child/bucket scene support readable local interactions while retaining an attractive sky-visible travel view? Compare the planned wide tilt range with the narrower horizon-preserving range before choosing production assets.

## Local readiness

The current project is `/Users/benedekkoos/projects/ichigo`. The inspected host reports an Apple M2 and 8 GiB memory. No Godot executable was found on PATH or as a Godot app in `/Applications` or the user's `Applications` directory. This does not rule out an installation elsewhere. The first implementation step is to locate or install the chosen stable Godot 4 build and record its version. No editor installation or performance benchmark was performed in this preparation pass.

Start comparison captures at a modest explicitly recorded internal resolution, then test both 16:9 and 16:10. Keep volumetric effects off in the baseline so camera and silhouette decisions can be evaluated independently. The 60 fps goal remains a target until measured on this host.

## Owned implementation surface

The integration owner creates the Godot project configuration, input actions, main prototype scene, camera controller, physical proxy roots, simple ocean sampling, and target-selection integration. Subagents must not independently create competing project settings or input maps.

The initial scene contains a child silhouette in the correct oversized number 15 jersey without a hat, a layered bucket, a continuous ocean plane, sky/cloud ribbons, one fish proxy, one static reachable target, and an explicitly unreachable target. Use the asset packet for proxy construction details. No inventory, fishing fight, reward system, or story implementation is required for this test.

## Experiment controls and invariants

- Fixed camera azimuth and no roll; positive-down pitch 12°–52°, starting at 20°.
- Perspective with an explicitly vertical 60° FOV. Capture 12°, 20°, 26°, 38°, and 52° at matched subject scale.
- Compare a 12°–26° limited preset with the wider range. Label settings as developer controls; they are not final gameplay UI.
- Retain real world-space roots, physical waterline, target IDs, and reach while visual children compensate for camera angle.
- Allow screen-relative steering, a continuous tilt control, preset transitions, selection, and a simple cast-target marker. This marker tests projection, not the fishing minigame.
- Reject sky rays, near-parallel invalid intersections, behind-camera hits, and points beyond reach. Once accepted, a target remains in world space during a camera sweep.
- One clock drives any proxy bobbing and the ocean sample. Camera tilt does not reset simulation time.

## Implementation sequence

1. Establish the editor/version and a launchable minimal scene.
2. Add camera/framing controls and static proxies; inspect the horizon and rim/child visibility.
3. Add target projection and record whether near-target overlap changes usability with pitch.
4. Add gentle coordinated surface/bucket motion and a fish path behind the bucket.
5. Run the shared declarative scenarios and produce comparable captures with settings recorded.
6. Review with the user: acceptable sky coverage, useful upper pitch, subject scale, and minimum geometry/view coverage.

The human creator can own the pitch/framing function or shared wave-height function as a substantive first coding contribution. Keep each task understandable and locally editable.

## Exit and handoff

Deliver the editable scene/code, a settings record, motion captures, observed failures, and a proposed camera/asset contract. Separate actual results from expected geometric behavior. Until this scene is tested, no asset packet can claim full camera compatibility. The next production wave begins only once the chosen view range, targeting behavior, and representation needs are established.
