# Scrap Knight - Main Quest Project

**Student Name:** Nolan Tsang

**Class:** CSCI 4160U Game Development

**Repository Link:** https://github.com/tsanger2004/Scrap-Knight

---

## Description

**Description:**
Scrap Knight is a top-down action roguelite game where the player's weapon is built from scavenged mechanical parts. Each part has limited durability and can break during combat. Players must constantly fight, collect replacement parts, and adapt their weapon to survive increasingly difficult enemies.

---

## Platform & Tools

* PC
* Raylib
* Odin
* Git/GitHub

---

## How to build and run the game

The prototype uses Odin's built-in `vendor:raylib` package. With Odin installed and
available on `PATH`, run:

```powershell
odin run src
```

To build an executable without launching it:

```powershell
odin build src -out:scrap_knight.exe
.\scrap_knight.exe
```

## Prototype controls

* **WASD / Arrow keys** - Move the Scrap Knight.
* **Mouse** - Aim.
* **Left mouse button** - Fire the assembled weapon.
* **R** - Rebuild after the player is defeated.

## Design slice

This first playable slice focuses on the project's core loop:

1. Fight increasingly dense waves of Scrappers and Chargers.
2. Spend barrel durability whenever the weapon fires.
3. Collect dropped Barrel, Grip, and Plating parts to repair or improve the build.
4. Survive as long as possible while adapting to a weapon that can break.

Runtime tuning is read once from `data/game.cfg` at startup. Edit a value such as
`player_speed` or `spawn_interval`, restart the game, and the behavior changes
without editing Odin code. The generated player texture and pickup sound are
loaded once at startup and shared by the game loop.
---
