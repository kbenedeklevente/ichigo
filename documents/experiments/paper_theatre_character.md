# Paper Theatre: child and bucket art study

The user selected Paper Theatre's waves and requested matching art for Ichigo and the bucket on main. This pass keeps those selected waves unchanged and replaces the solid character/vessel appearance with original layered vector drawings. The character treatment is a new study awaiting visual review, not a second water variant.

## Artistic plan and implementation

Use Paper Theatre's chunky dark indigo outlines, faded teal blocks, carved highlight strokes and aged ivory edges. Warm brown staves and small wood-grain knots distinguish the bucket from the sea. Original SVG source adapted from the prior Ink Diorama character study is reworked into `game/presentation/paper_theatre/`; no reference images are copied into game assets.

Ichigo retains the original away-facing orientation, with tousled hair viewed from behind, no hat and no assigned gender or exact age. Tiny hands and feet contrast with broad dropped sleeves and a long, loose jersey hem. The correctly oriented 15 is path-drawn on the back, with a clear left vertical on the 5. A dark lower fold and broken seam strokes echo the wave illustrations without putting dense detail behind the number.

Five main spatial layers plus thin side-wall and rim connectors establish the vessel: horizontal interior floor/seat; rear wall and lip; child; brown front wall; separate ivory-edged front rim. They use alpha-tested paper cutouts with modest fixed authored tilt, no billboarding and no solid staves or spherical head. The floor is an independently drawn top view to support the higher camera pitches. The separate front lip sits 0.014 m ahead of the front wall to avoid coincident surfaces. A first 52° capture exposed gaps between front/rear art; two gently curved illustrated side walls and narrow top-rim connectors now close those gaps without solid staves. A drawn rod strip, wrap and reaching-hand cutout keep the physical tool attachment clear.

## Preserved interfaces

The scene still instantiates its existing `BucketSimulationRoot` and collider. Only its art script preload changes. Waterline origin, `get_grip_local()`, `get_rod_tip_local()` and `update_pose(time, moving)` retain their prior meanings. The grip is `(0.38, 1.08, -0.18)` and the rod tip is `(1.13, 1.95, -0.79)` in local metres. The reaching hand/rod stay stationary within that root while the body keeps the prior subtle sway.

Camera framing, 12°–52° range, 20° default, water simulation/rendering, waves, sky, fish and event behavior are outside this change. No physics shape follows a paper-art distortion. Fixed azimuth is the supported coverage; independently authored side/front views remain future work if actor yaw is introduced.

## Checks and review

Godot 4.7.2 headless editor import and a three-frame weather-study startup both passed without errors. Actual captures are saved at 12°, 20°, 26°, 38° and 52°; static capture and continuous tilt must establish opening/containment, jersey readability and the coherence of paper edges. Import success alone does not approve the art. Particular review risks are front-rim occlusion, flat-layer separation at the highest pitch, the small back-view number at gameplay scale, and grip continuity during body sway.

Normal launch and editor Play now use Paper Theatre. Use `--camera-baseline` for the historical camera fixture. [Compare the matching-prop pass](gallery/current.html). Art approval remains with the user; continuous movement and extreme weather still need visual review.
