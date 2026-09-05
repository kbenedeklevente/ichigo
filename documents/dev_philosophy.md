# Development philosophy

Our development philosophy for Ichigo is **art-led, systems-driven, and built through small playable experiments—with the human creator actively shaping both the design and the code.**

These principles are intended to transfer to other games.

## Principles

1. **Start with the feeling.** Define what the player should feel during an ordinary minute of play. For Ichigo, that is wonder and solitude, punctuated by danger. Use that feeling to judge mechanics, pacing, visuals, and sound.

2. **Find the visual identity early.** Explore references, palette, materials, silhouettes, and scale before producing lots of assets. Compare alternatives, identify what works, and test the chosen treatment in motion. Visual quality is a core design requirement.

3. **Make the art support interaction.** Assets should accommodate movement, changing viewpoints, and player actions. Ichigo's deformable paper forms are an example: their construction helps create a living environment.

4. **Give the world believable rules.** Stylization and an imaginative premise can coexist with convincing behavior and consequences. Decide which things are grounded in reality and which are deliberate abstractions, then stay consistent.

5. **Preserve player agency.** Important moments happen through play. Players can investigate, participate, interfere, withdraw, or fail, and the world responds. Camera changes should deepen interaction while retaining meaningful control.

6. **Make understanding drive progress.** Observation, experimentation, and puzzles teach players how the world works. Knowledge opens possibilities and advances the story.

7. **Use randomness within coherent systems.** Conditions influence which events can happen. Variation changes opportunities and complications while preserving plausible behavior and viable paths through the game.

8. **Build the smallest experience that proves the idea.** Start with one environment, one compelling interaction, and one meaningful outcome. Each prototype should answer a specific question. Expand when the experience works.

9. **Keep development collaborative and inspectable.** Use readable code, version control, small changes, and frequent playable reviews. The human creator owns substantive parts of the implementation; the AI collaborator helps build, explain, debug, and evaluate.

10. **Maintain a disciplined backlog.** Capture promising ideas, then keep the current experiment focused. For Ichigo, inventory and expanded weather are recorded while we resolve the visual style.

11. **Communicate through play.** Teach mechanics and convey meaning through composition, animation, sound, behavior, and visible consequences. In Ichigo, use as little on-screen text as possible. Introduce interactions through safe opportunities to try them, and test whether players understand what to do without written explanation. Keep concise text available where it improves clarity or accessibility.

12. **Plan connected systems together, then delegate bounded work.** Resolve the relationships between camera, asset construction, controls, progression, and narrative in one integrated design context. Record shared contracts and open questions before dividing implementation among subagents. Give each work packet clear ownership and acceptance checks, with one integration owner preserving the whole experience.

## Reusable project brief

> Develop this game through small, art-led playable experiments. Begin by defining the intended player experience and exploring a distinctive visual identity. Treat visuals, motion, sound, and interaction as connected design decisions.
>
> Build a world with consistent rules, meaningful player agency, and consequences. Let observation and understanding contribute to progression. Where randomness is useful, constrain it through world conditions and progression requirements.
>
> Communicate primarily through visuals, sound, and interaction. Minimize required reading, and keep necessary labels, controls, and accessibility text concise. Test whether the experience remains understandable without explanatory prose.
>
> Choose tools that support fast iteration, readable implementation, and active human participation. Keep changes small and version-controlled. For each milestone, state the question being tested, build the minimum experience needed to answer it, evaluate it in play, and refine before expanding scope.
>
> Keep future ideas in a backlog. Explain technical decisions clearly and give me substantive opportunities to design and code.
>
> Plan interdependent systems together before delegating. Define shared interfaces, ownership boundaries, and integration checks so parallel work preserves one coherent game.

## Ichigo-specific commitments

Ichigo's ocean setting, paper aesthetic, wildlife Venn diagram, explicit no-cutscene rule, and minimal-text presentation are project-specific commitments. When reusing this philosophy, define the new game's own setting, visual language, interaction priorities, and presentation rules.

The current [integrated design plan](design/README.md) adds direction-independent ocean travel, a bounded adjustable camera with a sky-visible travel view, and camera-consistent assets. The initial playable proposal omits hunger/thirst and emphasizes fishing, discoveries, tools, puzzles, and story. Paper, low-poly, and medium-poly approaches remain visual experiments until compared in motion.
