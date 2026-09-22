# Scrap Knight - Game Design Document

**Student Name:** Nolan Tsang

**Date:** September 22, 2026

**Class:** CSCI 4160U Game Development

**Repository Link:** https://github.com/tsanger2004/Scrap-Knight

---

## Description

**Description:**
Scrap Knight is a top-down action roguelite game where the player's weapon is built from scavenged mechanical parts. Each part has limited durability and can break during combat. Players must constantly fight, collect replacement parts, and adapt their weapon to survive increasingly difficult enemies.

---

## Core Gameplay Loop

**The Gameplay Loop:**
Fight enemies → collect dropped weapon parts → replace broken or unwanted parts → continue fighting → survive increasing difficulty → defeat the final boss.

### Primary Mechanics

* Weapon assembled from multiple parts.
* Weapon parts have durability and can break.
* Enemies drop replacement parts.
* Collecting parts changes the player's weapon.

### Secondary Mechanics

* Top-down movement and shooting.
* Different enemy types.
* Different weapon part types.
* Health and damage.
* Increasing enemy difficulty.

### Tertiary Mechanics

* Scrap/resource pickups.
* Special weapon effects.
* Arena hazards.
* Boss encounters.

---

## MDA Framework

### Mechanics

* Movement and shooting.
* Weapon part system.
* Part durability.
* Enemy AI.
* Pickups.
* Health/damage.
* Progressively stronger enemies.

### Dynamics

* Players must decide which parts to collect.
* Players may need to risk entering dangerous areas to find replacement parts.
* Breaking parts forces players to adapt their weapon.
* Different combinations of parts create different playstyles.

### Aesthetics

* Challenge.
* Tension.
* Discovery.
* Mastery.
* Fast-paced action.

---

## Player Experience

### How Should They Feel?

The player should feel engaged, pressured, and rewarded for adapting to changing situations. The main pleasures are challenge, discovery, and mastery. Players should feel that their decisions about weapon parts directly affect their ability to survive.

### Game Inspirations

* *Vampire Survivors*
* *Brotato*
* *Risk of Rain 2*
* *Enter the Gungeon*

### Non-Game Inspirations

* Scrap machinery and junkyards.
* Improvised mechanical devices.
* Repairing and modifying real-world machines.
* Mechanical parts and tools.

### Genre

Top-down action shooter / survival roguelite.

### Target Audience

Primarily **Killers**, who enjoy combat and overcoming enemies, with elements for **Achievers**, who enjoy improving their weapon and surviving increasingly difficult encounters.

### Progression Over Time

The game begins with a basic weapon and simple enemies. As the player progresses, enemies become more difficult and introduce new threats. Weapon parts will break throughout the run, requiring the player to constantly replace and adapt their weapon. New and stronger parts become available as the game progresses, eventually leading to a final boss encounter.

### Themes

* Improvisation.
* Adaptation.
* Resourcefulness.
* Making something useful out of scrap.

---

## Platform & Tools

* PC
* Raylib
* Odin
* Git/GitHub

---

## Anything Else Unusual That Needs Explaining

The game is designed around maintaining a weapon rather than simply upgrading it. Weapon parts can break during normal gameplay, so the player must actively search for replacement parts while continuing to fight. The intention is for this system to remain part of the gameplay rather than interrupting combat with frequent upgrade menus.

---

## Scope and Cutoff lines

The core scope of the game is to start the player with a basic gun which allows enhancements to be built onto it using weapon parts. As the player progresses through the run, enemies get stronger through introducing new enemy types. Weapon parts are dropped by enemies during combat, encouraging players to adapt their weapon and play style during the gameplay. As they get deeper into the run, the chance for higher level weapon parts increases, eventually the run will end with a boss encounter.

The cutoff line will include the basic weapon-part system, weapon durability and breaking, a few enemy types, increasing difficulty, stronger weapon-part drops over time, and a playable run structure.

Stretch goals include adding more weapon enhancements, implementing a boss encounter, adding more enemy types, and adding arena hazards. These features will be added if the core gameplay is completed and I have additional development time.

---
