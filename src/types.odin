package main

import rl "vendor:raylib"

SCREEN_W :: 1280
SCREEN_H :: 720
ARENA_W :: 960
ARENA_H :: 720
SIDEBAR_X :: ARENA_W

MAX_ENEMIES :: 48
MAX_BULLETS :: 96
MAX_PARTS :: 24
MAX_LEVEL_TILES :: 3000

Vec2 :: rl.Vector2

Enemy_Kind :: enum { Scrapper, Charger }
Part_Kind :: enum { Barrel, Grip, Plating }
Game_State :: enum { Playing, Game_Over }

Player :: struct {
	pos: Vec2,
	health: f32,
	max_health: f32,
	speed: f32,
	fire_timer: f32,
	invulnerable: f32,
}

Enemy :: struct {
	pos: Vec2,
	kind: Enemy_Kind,
	health: int,
	speed: f32,
	alive: bool,
}

Bullet :: struct {
	pos, velocity: Vec2,
	damage: int,
	alive: bool,
}

Part :: struct {
	pos: Vec2,
	kind: Part_Kind,
	durability: int,
	alive: bool,
}

Game :: struct {
	player: Player,
	enemies: [MAX_ENEMIES]Enemy,
	bullets: [MAX_BULLETS]Bullet,
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

Arena_Tile :: struct {
	position: Vec2,
	source: rl.Rectangle,
}

Level_Data :: struct {
	tiles: [MAX_LEVEL_TILES]Arena_Tile,
	tile_count: int,
	player_spawn: Vec2,
}

Tuning :: struct {
	player_speed: f32,
	bullet_speed: f32,
	fire_interval: f32,
	spawn_interval: f32,
	spawn_interval_floor: f32,
	enemy_speed: f32,
	charger_chance: f32,
	charger_damage: int,
	scrapper_damage: int,
}

Assets :: struct {
	player_texture: rl.Texture2D,
	tileset_texture: rl.Texture2D,
	pickup_sound: rl.Sound,
}
