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
