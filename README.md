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

1. Fight increasingly dense waves of Scrappers, Chargers, and Gunners.
2. Spend barrel durability whenever the weapon fires.
3. Collect Fuel, Cog, and Scrap drops that replace the active effect in each system.
4. Survive as long as possible while adapting to a weapon that can break.

## CP4 enemy behavior

Enemies use an explicit state machine with three named states:

* **Chase** - steer directly toward the player's current position.
* **Attack** - when contact range is reached, apply the existing enemy damage system once.
* **Recover** - pause for a short wind-up/cooldown, then return to **Attack** if still in range or **Chase** if the player escaped.
* **Strafe** - Gunners move sideways when a player bullet is approaching, then return to ranged attacking.

The transitions are `Chase -> Attack` on contact, `Attack -> Recover` after the hit,
`Attack -> Chase` if the player leaves range, and `Recover -> Attack/Chase` when
the cooldown ends. Gunners enter `Strafe` when an incoming player bullet is close
and moving toward them. Movement uses direct steering rather than pathfinding because
the current arena is open and bounded; steering gives enemies responsive pursuit
without requiring a navigation graph. Scrappers and Chargers use contact attacks;
Gunners keep distance and fire hostile projectiles while their type-specific
speed, health, and damage tuning preserves their different combat roles.

Runtime tuning is read once from `data/game.cfg` at startup. Edit a value such as
`player_speed` or `spawn_interval`, restart the game, and the behavior changes
without editing Odin code. The LDtk level in `data/main_arena.ldtk` supplies the
arena tile layout and player spawn. Its tileset, player texture, and pickup sound
are loaded once at startup and shared by the game loop.

---

## CP5 balancing

The tuned difficulty curve is **forgiving opening -> rising mid-run pressure ->
controlled late-run ceiling**. The run gives the player time to learn the weapon
and enemy telegraphs, then density and enemy speed become more demanding. The
spawn floor prevents the late game from becoming an unreadable instant spike.

### Before and after

| Tuned value | Before | After | Purpose |
|---|---:|---:|---|
| `spawn_interval` | 1.20 s | 1.45 s | Longer breathing room in the opening |
| `spawn_interval_wave_reduction` | 0.08 s/wave | 0.07 s/wave | Slower, more gradual mid-run ramp |
| `spawn_interval_floor` | 0.28 s | 0.52 s | Keeps late-run enemy density readable |
| `enemy_speed` | 100 | 82 | Gives players more reaction time early |
| `enemy_speed_wave_bonus` | 3/wave | 2/wave | Slows the speed escalation |
| `enemy_health_wave_bonus` | +1 health/3 waves | +1 health/4 waves | Delays the health step-up |
| `charger_damage`  | 14 | 20 | Increased Threat |
| `scrapper_damage` | 8 | 14 | Increased Threat |
| `gunner_damage` | 10 | 15 | Increased Threat |

### Enemy drop systems

Defeated enemies now drop one of three independent systems. Each pickup replaces
only that system's current variant; Fuel, Cog, and Scrap effects can coexist.

* **Fuel can**
  * **Flame:** slower projectiles with bonus damage.
  * **Turbo:** 45% shorter firing interval.
* **Cog**
  * **Heavy:** adds bonus damage to every shot.
  * **Trident:** fires a center shot and two angled side shots.
* **Scrap**
  * **Glass:** 30 less maximum health, 45 movement speed gained, and 15 shield.
  * **Tank:** 30 more maximum health, 35 movement speed lost, and 25 shield.

All variants and numerical tradeoffs are loaded from `data/game.cfg`, so edits
can be tested at the next restart without recompiling.

### Item rarity

Every Fuel, Cog, or Scrap drop rolls as **Common**, **Rare**, or **Epic**.
The rarity controls both presentation and effectiveness:

* **Common:** silver-white floor glow and base values.
* **Rare:** blue floor glow, 25% stronger tradeoff or bonus.
* **Epic:** purple floor glow, 50% stronger tradeoff or bonus, with a wider
  Cog spread pattern.

Rare drop odds are configurable with `rarity_rare_chance` and
`rarity_epic_chance` in `data/game.cfg`. Epic is checked first, so the
remaining probability becomes Common; the three tiers are visually distinct
while standing on the ground.

### Evidence behind the tune

The shape was measured directly from the existing formulas:

* Spawn interval is `max(spawn_interval - wave * spawn_interval_wave_reduction,
  spawn_interval_floor)`. At wave 1 this changes from 1.12 s to 1.38 s, making
  the opening interval about 23% longer.
* At wave 10 the interval changes from 0.40 s to 0.75 s, while wave 15 changes
  from 0.28 s to 0.52 s. The former reached 0.28 s at wave 12; the tuned curve
  reaches 0.52 s at wave 14 and remains there. This adds a clearly readable
  pressure transition instead of a fast floor.
* Enemy speed is `enemy_speed + wave * enemy_speed_wave_bonus`. At wave 5 speed
  changes from 115 to 92, and at wave 10 from 130 to 102. Health is `base +
  wave / health_wave_bonus`; the +1 health threshold moves from wave 3 to wave
  4 and from wave 6 to wave 8.

To retune CP5, change only `data/game.cfg` and restart. No recompilation is
needed. These values are loaded at startup through `load_tuning()` in
`src/assets.odin`; no balance constant in CP5 should be duplicated into Odin.
