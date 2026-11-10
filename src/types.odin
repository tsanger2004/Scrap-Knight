package main

import rl "vendor:raylib"

// Window and arena dimensions are shared by gameplay bounds and rendering.
SCREEN_W :: 1280
SCREEN_H :: 720
ARENA_W :: 960
ARENA_H :: 720
SIDEBAR_X :: ARENA_W

MAX_ENEMIES :: 48
MAX_BULLETS :: 96
MAX_ENEMY_BULLETS :: 64
MAX_PARTS :: 24
MAX_LEVEL_TILES :: 3000

// Vec2 aliases Raylib's floating-point 2D position type.
Vec2 :: rl.Vector2

// Enemy_Kind selects the enemy's combat tuning.
Enemy_Kind :: enum { Scrapper, Charger, Gunner }
// Enemy_State is the per-enemy state-machine state.
Enemy_State :: enum { Chase, Attack, Recover, Strafe }
// Part_Kind identifies which player upgrade a pickup provides.
Part_Kind :: enum { Barrel, Grip, Plating }
// Game_State controls whether simulation is active or awaiting a restart.
Game_State :: enum { Playing, Game_Over }

// Player contains movement, health, and weapon timing state.
Player :: struct {
	pos: Vec2,
	health: f32,
	max_health: f32,
	speed: f32,
	fire_timer: f32,
	invulnerable: f32,
}

// Enemy stores steering data and the timers used by its state machine.
Enemy :: struct {
	pos: Vec2,
	kind: Enemy_Kind,
	state: Enemy_State,
	state_timer: f32,
	health: int,
	speed: f32,
	alive: bool,
}

// Bullet moves in a straight line until it leaves the arena or hits an enemy.
Bullet :: struct {
	pos, velocity: Vec2,
	damage: int,
	alive: bool,
}

// Enemy_Bullet is a hostile projectile fired by a Gunner.
Enemy_Bullet :: struct {
	pos, velocity: Vec2,
	damage: int,
	alive: bool,
}

// Part is a collectible upgrade dropped by defeated enemies.
Part :: struct {
	pos: Vec2,
	kind: Part_Kind,
	durability: int,
	alive: bool,
}

// Game is the complete mutable state for one run.
Game :: struct {
	player: Player,
	enemies: [MAX_ENEMIES]Enemy,
	bullets: [MAX_BULLETS]Bullet,
	enemy_bullets: [MAX_ENEMY_BULLETS]Enemy_Bullet,
	parts: [MAX_PARTS]Part,
	barrel_durability: int,
	barrel_max: int,
	barrel_level: int,
	grip_level: int,
	plating_level: int,
	spawn_timer: f32,
	elapsed: f32,
	kills: int,
	wave: int,
	state: Game_State,
	message: cstring,
	message_timer: f32,
}

// The following structures mirror the subset of LDtk JSON used by the game.
Level_Tile :: struct {
	px: [2]int `json:"px"`,
	src: [2]int `json:"src"`,
}

Level_Layer :: struct {
	identifier: string `json:"__identifier"`,
	grid_tiles: []Level_Tile `json:"gridTiles"`,
	entity_instances: []Level_Entity `json:"entityInstances"`,
}

Level_Entity :: struct {
	identifier: string `json:"__identifier"`,
	px: [2]int `json:"px"`,
}

Level_Definition :: struct {
	layer_instances: []Level_Layer `json:"layerInstances"`,
	px_wid: int `json:"pxWid"`,
	px_hei: int `json:"pxHei"`,
}

Level_File :: struct {
	levels: []Level_Definition `json:"levels"`,
}

// Arena_Tile is the render-ready form of an LDtk tile.
Arena_Tile :: struct {
	position: Vec2,
	source: rl.Rectangle,
}

// Level_Data contains bounded, runtime-friendly level information.
Level_Data :: struct {
	tiles: [MAX_LEVEL_TILES]Arena_Tile,
	tile_count: int,
	player_spawn: Vec2,
}

// Tuning contains gameplay values loaded from data/game.cfg.
Tuning :: struct {
	player_speed: f32,
	bullet_speed: f32,
	fire_interval: f32,
	spawn_interval: f32,
	spawn_interval_floor: f32,
	enemy_speed: f32,
	charger_chance: f32,
	gunner_chance: f32,
	charger_damage: int,
	scrapper_damage: int,
	gunner_damage: int,
	gunner_bullet_speed: f32,
	gunner_fire_interval: f32,
}

// Assets owns the textures and sound shared by the game loop.
Assets :: struct {
	player_texture: rl.Texture2D,
	tileset_texture: rl.Texture2D,
	pickup_sound: rl.Sound,
}
