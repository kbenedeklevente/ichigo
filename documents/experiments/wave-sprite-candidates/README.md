# Standalone wave sprite candidates

Originally requested for separate review. The user subsequently selected A for the maximum-storm game asset; B remains unselected. Two generated raster candidates: A has denser carved foam and spray, B has a broader cleaner curl. Generated with the built-in image tool from the user's Hokusai crop. Both raw candidates are 1774×887 (2:1).

**Source A is now used by the game with material-based background keying.** Godot inspection found no alpha in either output: the apparent checkerboard is painted into opaque pixels. A second background-extraction generation also returned opaque pixels. The original preferred candidates are retained here as `source-a-opaque.png` and `source-b-opaque.png`; they must not be described as transparent sprites. The selected PNG was copied unchanged to `game/presentation/waves/storm_sprite_a.png`; the water shader supplies the cutout by keying pale neutral pixels. The original copy remains unchanged. A subsequently requested generated sibling, `storm_sprite_a_extended.png`, is now active: it extends the blue base into a rectangle, with a modest storm-only renderer lift. See [storm breakers](../storm_breakers.md) for placement and verification. Neither source file itself has a transparent alpha channel.

The `.gdignore` file keeps this candidate folder out of Godot's import scan. The isolated sources stay here for review; only the explicitly selected A family is referenced by the live maximum-storm material.

## Generation brief

Single side-view wave sprite; true transparent background requested; 2:1 canvas; full cutout silhouette with padding and a shallow waterline at 80% of height. Hokusai-reference faded indigo, fine ink, ivory branching foam, internal pigment grain. No landscape, paper background, typography, UI, floor shadow or painted checkerboard. A: compact dense canopy, five rising water ribbons and sparse interior flecks. B: open curl, fewer larger foam claws, three broad ribbons and minimal speckles.

These are raster candidates, not SVG source replacements for the current game. The source-alpha check is recorded above; runtime transparency is supplied by the selected-sprite material key.
