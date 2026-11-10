package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:math/rand"

game: Game
tuning: Tuning
assets: Assets
level: Level_Data

// Basic vector helpers keep gameplay calculations independent of Raylib utility calls.
vec_add :: proc(a, b: Vec2) -> Vec2 { return Vec2{a.x + b.x, a.y + b.y} }
vec_sub :: proc(a, b: Vec2) -> Vec2 { return Vec2{a.x - b.x, a.y - b.y} }
vec_scale :: proc(a: Vec2, amount: f32) -> Vec2 { return Vec2{a.x * amount, a.y * amount} }
vec_length :: proc(a: Vec2) -> f32 { return math.sqrt(a.x*a.x + a.y*a.y) }
vec_normalize :: proc(a: Vec2) -> Vec2 {
	length := vec_length(a)
	if length < 0.001 do return Vec2{0, 0}
	return vec_scale(a, 1.0 / length)
}
// Returns the Euclidean distance between two world positions.
distance :: proc(a, b: Vec2) -> f32 { return vec_length(vec_sub(a, b)) }
// Returns a uniformly distributed floating-point value in the inclusive range.
random_range :: proc(low, high: f32) -> f32 { return low + rand.float32() * (high - low) }
vec_perpendicular :: proc(a: Vec2) -> Vec2 { return Vec2{-a.y, a.x} }
vec_dot :: proc(a, b: Vec2) -> f32 { return a.x*b.x + a.y*b.y }

// Clears the previous run and initializes player, weapon, and wave state.
reset_game :: proc() {
	game = Game{}
	game.player = Player{
		pos = level.player_spawn,
		health = 100,
		max_health = 100,
		speed = tuning.player_speed,
	}
	game.barrel_durability = 80
	game.barrel_max = 80
	game.message = "SCAVENGE PARTS TO KEEP YOUR WEAPON ALIVE"
	game.message_timer = 5
	game.wave = 1
	game.state = .Playing
}

// Finds an inactive enemy slot and spawns a tuned enemy on a random arena edge.
spawn_enemy :: proc() {
	for i in 0..<MAX_ENEMIES {
		if game.enemies[i].alive do continue
		edge := int(rand.int31() % 4)
		pos := Vec2{0, 0}
		switch edge {
		case 0: pos = Vec2{random_range(30, ARENA_W - 30), 30}
		case 1: pos = Vec2{random_range(30, ARENA_W - 30), ARENA_H - 30}
		case 2: pos = Vec2{30, random_range(30, ARENA_H - 30)}
		case 3: pos = Vec2{ARENA_W - 30, random_range(30, ARENA_H - 30)}
		}
		kind := Enemy_Kind.Scrapper
		health := 3 + game.wave / 3
		speed := tuning.enemy_speed + f32(game.wave) * 3
		if rand.float32() < min(tuning.gunner_chance + f32(game.wave) * 0.005, 0.25) {
			kind = .Gunner
			health += 2
			speed *= 0.85
		} else if rand.float32() < min(tuning.charger_chance + f32(game.wave) * 0.01, 0.35) {
			kind = .Charger
			health += 3
			speed *= 1.35
		}
		game.enemies[i] = Enemy{
			pos = pos,
			kind = kind,
			state = .Chase,
			health = health,
			speed = speed,
			alive = true,
		}
		return
	}
}

// Fires a hostile projectile from a Gunner toward the player's current position.
fire_enemy_bullet :: proc(enemy: ^Enemy) {
	for i in 0..<MAX_ENEMY_BULLETS {
		bullet := &game.enemy_bullets[i]
		if bullet.alive do continue
		direction := vec_normalize(vec_sub(game.player.pos, enemy.pos))
		bullet^ = Enemy_Bullet{
			pos = enemy.pos,
			velocity = vec_scale(direction, tuning.gunner_bullet_speed),
			damage = tuning.gunner_damage,
			alive = true,
		}
		return
	}
}

// Finds an inactive pickup slot and creates a random weapon-part drop.
drop_part :: proc(pos: Vec2) {
	for i in 0..<MAX_PARTS {
		if game.parts[i].alive do continue
		kind := Part_Kind(rand.int31() % 3)
		durability := 20 + game.wave * 4
		game.parts[i] = Part{pos = pos, kind = kind, durability = durability, alive = true}
		return
	}
}

// Creates one bullet aimed from the player toward the current mouse position.
fire :: proc() {
	mouse := rl.GetMousePosition()
	direction := vec_normalize(vec_sub(mouse, game.player.pos))
	if vec_length(direction) < 0.1 do return
	for i in 0..<MAX_BULLETS {
		if game.bullets[i].alive do continue
		damage := 1 + game.barrel_level
		if game.barrel_durability <= 0 do damage = 1
		game.bullets[i] = Bullet{
			pos = game.player.pos,
			velocity = vec_scale(direction, tuning.bullet_speed),
			damage = damage,
			alive = true,
		}
		game.barrel_durability -= 1
		if game.barrel_durability <= 0 {
			game.barrel_durability = 0
			game.message = "BARREL BROKEN - FIND A REPLACEMENT"
			game.message_timer = 3
		}
		return
	}
}

// Reads movement input, applies bounded movement, and handles automatic firing.
update_player :: proc(dt: f32) {
	movement := Vec2{0, 0}
	if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) do movement.y -= 1
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) do movement.y += 1
	if rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT) do movement.x -= 1
	if rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT) do movement.x += 1
	movement = vec_normalize(movement)
	game.player.pos = vec_add(game.player.pos, vec_scale(movement, game.player.speed * dt))
	game.player.pos.x = clamp(game.player.pos.x, 24, ARENA_W - 24)
	game.player.pos.y = clamp(game.player.pos.y, 24, ARENA_H - 24)
	game.player.invulnerable = max(game.player.invulnerable - dt, 0)
	game.player.fire_timer -= dt
	fire_rate := tuning.fire_interval - f32(game.grip_level) * 0.025
	if game.barrel_durability <= 0 do fire_rate = 0.45
	if rl.IsMouseButtonDown(.LEFT) && game.player.fire_timer <= 0 {
		fire()
		game.player.fire_timer = fire_rate
	}
}

// Advances bullets and resolves their first enemy collision.
update_bullets :: proc(dt: f32) {
	for i in 0..<MAX_BULLETS {
		bullet := &game.bullets[i]
		if !bullet.alive do continue
		bullet.pos = vec_add(bullet.pos, vec_scale(bullet.velocity, dt))
		if bullet.pos.x < 0 || bullet.pos.x > ARENA_W || bullet.pos.y < 0 || bullet.pos.y > ARENA_H {
			bullet.alive = false
			continue
		}
		for j in 0..<MAX_ENEMIES {
			enemy := &game.enemies[j]
			if !enemy.alive || distance(bullet.pos, enemy.pos) > 22 do continue
			enemy.health -= bullet.damage
			bullet.alive = false
			if enemy.health <= 0 {
				enemy.alive = false
				game.kills += 1
				if rand.float32() < 0.55 do drop_part(enemy.pos)
			}
			break
		}
	}
}

// Moves hostile projectiles and applies damage when one reaches the player.
update_enemy_bullets :: proc(dt: f32) {
	for i in 0..<MAX_ENEMY_BULLETS {
		bullet := &game.enemy_bullets[i]
		if !bullet.alive do continue
		bullet.pos = vec_add(bullet.pos, vec_scale(bullet.velocity, dt))
		if bullet.pos.x < 0 || bullet.pos.x > ARENA_W || bullet.pos.y < 0 || bullet.pos.y > ARENA_H {
			bullet.alive = false
			continue
		}
		if distance(bullet.pos, game.player.pos) < 20 && game.player.invulnerable <= 0 {
			game.player.health -= f32(bullet.damage)
			game.player.invulnerable = 0.65
			bullet.alive = false
		}
	}
}

// Returns true when a player bullet is moving toward an enemy at close range.
bullet_threatens_enemy :: proc(enemy: ^Enemy) -> bool {
	for bullet in game.bullets {
		if !bullet.alive do continue
		to_enemy := vec_sub(enemy.pos, bullet.pos)
		if distance(bullet.pos, enemy.pos) < 105 && vec_dot(vec_normalize(bullet.velocity), vec_normalize(to_enemy)) > 0.65 {
			return true
		}
	}
	return false
}

// Moves a Gunner sideways relative to the nearest incoming bullet.
strafe_from_bullets :: proc(enemy: ^Enemy, dt: f32) {
	for bullet in game.bullets {
		if !bullet.alive do continue
		to_enemy := vec_sub(enemy.pos, bullet.pos)
		if distance(bullet.pos, enemy.pos) >= 105 || vec_dot(vec_normalize(bullet.velocity), vec_normalize(to_enemy)) <= 0.65 do continue
		side := vec_perpendicular(vec_normalize(bullet.velocity))
		if vec_dot(side, vec_sub(enemy.pos, game.player.pos)) < 0 do side = vec_scale(side, -1)
		enemy.pos = vec_add(enemy.pos, vec_scale(side, enemy.speed * 1.5 * dt))
		enemy.pos.x = clamp(enemy.pos.x, 24, ARENA_W - 24)
		enemy.pos.y = clamp(enemy.pos.y, 24, ARENA_H - 24)
		return
	}
}

// Runs each enemy's state machine and applies contact or ranged attacks.
update_enemies :: proc(dt: f32) {
	for i in 0..<MAX_ENEMIES {
		enemy := &game.enemies[i]
		if !enemy.alive do continue

		switch enemy.state {
		case .Chase:
			direction := vec_normalize(vec_sub(game.player.pos, enemy.pos))
			if enemy.kind == .Gunner && bullet_threatens_enemy(enemy) {
				enemy.state = .Strafe
				enemy.state_timer = 0.45
				continue
			}
			if enemy.kind == .Gunner && distance(enemy.pos, game.player.pos) < 300 {
				enemy.state = .Attack
				continue
			}
			enemy.pos = vec_add(enemy.pos, vec_scale(direction, enemy.speed * dt))
			if distance(enemy.pos, game.player.pos) < 27 {
				enemy.state = .Attack
			}
		case .Attack:
			if enemy.kind == .Gunner {
				if bullet_threatens_enemy(enemy) {
					enemy.state = .Strafe
					enemy.state_timer = 0.45
				} else if distance(enemy.pos, game.player.pos) > 320 {
					enemy.state = .Chase
				} else if distance(enemy.pos, game.player.pos) < 150 {
					enemy.state = .Strafe
					enemy.state_timer = 0.45
				} else {
					enemy.state_timer -= dt
					if enemy.state_timer <= 0 {
						fire_enemy_bullet(enemy)
						enemy.state = .Recover
						enemy.state_timer = tuning.gunner_fire_interval
					}
				}
				continue
			}
			if distance(enemy.pos, game.player.pos) >= 32 {
				enemy.state = .Chase
				continue
			}
			if game.player.invulnerable <= 0 {
				damage := tuning.scrapper_damage
				if enemy.kind == .Charger do damage = tuning.charger_damage
				game.player.health -= f32(damage)
				game.player.invulnerable = 0.65
			}
			enemy.state = .Recover
			enemy.state_timer = 0.65
		case .Recover:
			enemy.state_timer -= dt
			if enemy.state_timer <= 0 {
				if enemy.kind == .Gunner {
					if bullet_threatens_enemy(enemy) {
						enemy.state = .Strafe
						enemy.state_timer = 0.45
					} else if distance(enemy.pos, game.player.pos) > 320 {
						enemy.state = .Chase
					} else {
						enemy.state = .Attack
					}
				} else if distance(enemy.pos, game.player.pos) < 32 {
					enemy.state = .Attack
				} else {
					enemy.state = .Chase
				}
			}
		case .Strafe:
			if enemy.kind != .Gunner {
				enemy.state = .Chase
				continue
			}
			strafe_from_bullets(enemy, dt)
			enemy.state_timer -= dt
			if enemy.state_timer <= 0 {
				if distance(enemy.pos, game.player.pos) > 320 {
					enemy.state = .Chase
				} else {
					enemy.state = .Attack
				}
			}
		}
	}
}

// Collects nearby parts and applies their upgrade-specific effects immediately.
collect_parts :: proc() {
	for i in 0..<MAX_PARTS {
		part := &game.parts[i]
		if !part.alive || distance(part.pos, game.player.pos) > 30 do continue
		part.alive = false
		if rl.IsSoundValid(assets.pickup_sound) do rl.PlaySound(assets.pickup_sound)
		switch part.kind {
		case .Barrel:
			game.barrel_level += 1
			game.barrel_durability = min(game.barrel_max + part.durability, 140)
			game.barrel_max = min(game.barrel_max + 5, 140)
			game.message = "BARREL INSTALLED: MORE DAMAGE, FRESH DURABILITY"
		case .Grip:
			game.grip_level += 1
			game.player.speed += 18
			game.message = "GRIP INSTALLED: YOU MOVE AND FIRE FASTER"
		case .Plating:
			game.plating_level += 1
			game.player.max_health += 12
			game.player.health = min(game.player.health + 20, game.player.max_health)
			game.message = "PLATING INSTALLED: ARMOR REPAIRED"
		}
		game.message_timer = 2.5
	}
}

// Advances the simulation in a fixed order and transitions to Game Over at zero health.
update_game :: proc(dt: f32) {
	switch game.state {
	case .Game_Over:
		if rl.IsKeyPressed(.R) do reset_game()
		return
	case .Playing:
		// All simulation changes happen in this update path.
	}
	game.elapsed += dt
	game.wave = 1 + int(game.elapsed / 20)
	game.spawn_timer -= dt
	spawn_rate := max(tuning.spawn_interval - f32(game.wave) * 0.08, tuning.spawn_interval_floor)
	if game.spawn_timer <= 0 {
		spawn_enemy()
		game.spawn_timer = spawn_rate
	}
	update_player(dt)
	update_bullets(dt)
	update_enemies(dt)
	update_enemy_bullets(dt)
	collect_parts()
	game.message_timer -= dt
	if game.player.health <= 0 do game.state = .Game_Over
}

// Initializes Raylib and game data, then runs the update/draw loop until quit.
main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "Scrap Knight - Main Quest")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	tuning = load_tuning()
	level = load_level()
	assets = load_assets()
	defer unload_assets(&assets)
	reset_game()
	for !rl.WindowShouldClose() {
		update_game(rl.GetFrameTime())
		rl.BeginDrawing()
		draw_game()
		rl.EndDrawing()
	}
}
