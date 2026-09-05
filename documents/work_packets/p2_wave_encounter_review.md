# Raised waves and encounter integration review

Status: second wave-geometry revision and first salvage encounter integration. Two Astra 6 High agents implemented bounded wave and encounter components; the primary agent integrated them and reviewed actual renders. This is a development study, not final art or a finished quest/fishing loop.

## Raised waves

The flat quad sheets are replaced in weather-study mode by a thin continuous surface with genuinely raised, asymmetric pointed crests. The first rounded revision was insufficient for the user's shark-fin description; the second has a longer concave flank, short falling flank, steeper dark face and pale lip. Artist relief is a study setting of approximately0.50–0.66m while the existing calm spring motion stays gentle.

Both the GPU vertex shader and [shared sampler](../../game/world/illustrated_water_surface.gd) reconstruct the same surface. Gameplay interpolation matches the rendered triangle diagonal, rather than sampling an unrelated smooth approximation. The bucket and line targeting use that height. Targeting brackets the first surface crossing so steep crests do not make Newton iteration jump through a visible foreground wave.

Actual20° and52° captures of the sharper revision were inspected under `outputs/raised-waves-pointed/`. Raised faces and pointed silhouettes are visible, the high view retains a shoulder, and the bucket remains dry. Calm water still has conspicuous repeated crest rows; drawing style, spacing, contrast and silhouette need the user's next visual review. The child/bucket remain the older solid proxies.

Renderer budget:289 assemblies,625 vertices each,332,928 triangles total in one near batch; one33×33 two-channel float field upload per simulation tick, shared original SVG artwork and no CPU mesh rebuild per frame. A bounded per-tick vertex-height cache reduced the agent's100 nearby complete samples to approximately1.24ms. These are implementation measurements, not a measured60fps guarantee. Spatial batching/LOD and actual GPU frame-time profiling remain unfinished.

## Approved encounter behavior

- Ordinary hooked-fish fights do **not** independently block weather or events. There is no finished fishing minigame yet; the runtime deliberately has no fishing-fight admission gate.
- One world encounter owns the encounter slot until retirement. Weather cannot begin a new front or enter its next transition while that slot is occupied; ongoing waves and local forces continue.
- Established weather can remain behind an encounter. New weather triggers remain queued; chance rolls are not backlogged while admission is blocked.
- Side encounters start forced departure at180 seconds even without interaction; a20-second local gust ramp drives the salvage away. Developer key O starts departure immediately as an abandoned outcome for testing.
- Full actor bounds must be off the padded viewport and out of interaction range for3 seconds before cleanup. Leaving view does not grant a reward or completed outcome.
- Retirement starts90 seconds of quiet. Random rates are capped at1/240 per eligible second, converted with `1-exp(-rate*dt)`. Rates may be lower. Triggered salvage also obeys the quiet interval.

Only a drifting salvage fixture is enabled, with an original illustrated driftwood marker. Its rate depends on the current independent sky/wind combination. Other candidate events have no handlers and cannot appear yet. The I key queues salvage through the same gate. No inventory reward, authored story point, wildlife fact or collection mechanic is implied by this fixture.

## Event fields and ownership

EventInstance owns position, velocity, bounds, presence/departure timers and outcome. A sparse spatial index covers its full actor/modifier bounds. LocalFieldModifier supports both a finite analytic gust and optional event-relative packed matrices with signed wind/current/amplitude channels and bilinear sampling.

The weather system preserves base weather fields. Event deltas are composed for effective wind/current and wave forcing; no per-frame accumulation is written into the base. The bucket reads the local current, and the connected springs respond to amplitude forcing. Removing a source restores base wind/current samples immediately after its fade, while legitimate physical wave motion decays naturally.

Combined runtime snapshots now use version2 and include encounter state, quiet/RNG state, weather hold and event-owned analytic-source reconstruction. This remains a native Variant, in-memory contract; no full-game save UI is implemented. Custom local grids can be sampled but their general persistence/authoring integration is still future work. The salvage instance reconstructs its analytic source from saved state.

## Verification

Dedicated agent suites passed47 raised-surface checks and197 encounter checks. Root integration checks cover an encounter holding a weather front beyond its original duration, continued wave phase, queued weather preservation, local current composition, signed local grids, removal without corrupting base fields, active snapshot reconstruction, off-screen retirement, quiet onset and weather resumption.

Scene tests additionally seek an actual raised crest and verify the bucket follows its rendered height, alongside camera-angle targeting, rainfall/light response and pause. Standard camera, director and weather suites are retained. These checks do not replace motion review, physical controller testing or GPU profiling.

All nine headless suites passed872 checks in the final integration run. Follow-up feedback from the user was that these waves are better; the illustration remains an editable SVG and the raised shape is procedural. This feedback supports the direction without declaring final asset approval. Double-clicking `Run Ichigo.command` now opens the raised-wave study by default.
