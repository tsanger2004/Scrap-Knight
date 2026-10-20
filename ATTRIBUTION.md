# Attribution

## AI Use

- GitHub Copilot, accessed through Copilot SDK in VS Code, assisted with project
  structure, Odin/Raylib setup, and CP2 architecture.
- The author reviewed, understood, and made the final decisions for all submitted
  code and design changes.

## Libraries and Tools

- Odin programming language: https://odin-lang.org/
- Raylib, used through Odin's built-in `vendor:raylib` package:
  https://github.com/raysan5/raylib
- Pixelorama, used to create the arena tileset:
  https://orama-interactive.itch.io/pixelorama
- LDtk, used to author the arena layout and entity placement:
  https://ldtk.io/

## Assets

- Visuals: the player texture is generated at startup with Raylib's
  `GenImageChecked`; no external visual asset is used. Other visuals are
  programmer-created shapes rendered with Raylib. The arena tileset is
  `assets/Floor Tileset.png`, created for this project.
- Arena layout: created in LDtk and stored in `data/main_arena.ldtk`.
- Sound effects: `assets/pickup.wav` is a short procedurally generated tone
  shipped with this repository; it is original project content, not downloaded
  from a third party.
- Music: none.
- Fonts: no custom font; the default Raylib font is used.