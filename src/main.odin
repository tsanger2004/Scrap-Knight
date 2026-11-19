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
rarity_from_roll :: proc() -> Part_Rarity {
	roll := rand.float32()
	if roll < tuning.rarity_epic_chance do return .Epic
	if roll < tuning.rarity_epic_chance + tuning.rarity_rare_chance do return .Rare
	return .Common
}
rarity_scale :: proc(rarity: Part_Rarity) -> f32 {
	switch rarity {
	case .Common: return 1
	case .Rare: return 1.25
	case .Epic: return 1.5
	}
	return 1
}
rarity_name :: proc(rarity: Part_Rarity) -> cstring {
	switch rarity {
	case .Common: return "COMMON"
	case .Rare: return "RARE"
	case .Epic: return "EPIC"
	}
	return "COMMON"
}
vec_perpendicular :: proc(a: Vec2) -> Vec2 { return Vec2{-a.y, a.x} }
vec_dot :: proc(a, b: Vec2) -> f32 { return a.x*b.x + a.y*b.y }
vec_rotate :: proc(a: Vec2, radians: f32) -> Vec2 {
	c := math.cos(radians)
	s := math.sin(radians)
	return Vec2{a.x*c - a.y*s, a.x*s + a.y*c}
}

// Clears the previous run and initializes player, weapon, and wave state.
reset_game :: proc() {
	game = Game{}
	game.player = Player{
		pos = level.player_spawn,
		health = tuning.player_health,
		max_health = tuning.player_health,
		shield = 0,
		speed = tuning.player_speed,
	}
	game.fuel_effect = .None
	game.cog_effect = .None
	game.scrap_effect = .None
	game.fuel_rarity = .Common
	game.cog_rarity = .Common
	game.scrap_rarity = .Common
	game.barrel_durability = tuning.barrel_starting_durability
	game.barrel_max = tuning.barrel_starting_max
	game.message = "SCAVENGE PARTS TO KEEP YOUR WEAPON ALIVE"
	game.message_timer = tuning.message_duration
	game.wave = 1
	game.state = .Playing
}

// Finds an inactive enemy slot and spawns a tuned enemy on a random arena edge.
// CP4
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
		health := tuning.enemy_base_health + game.wave / tuning.enemy_health_wave_bonus
		speed := tuning.enemy_speed + f32(game.wave) * tuning.enemy_speed_wave_bonus
		if rand.float32() < min(tuning.gunner_chance + f32(game.wave) * tuning.gunner_chance_wave_bonus, tuning.gunner_chance_max) {
			kind = .Gunner
			health += tuning.gunner_health_bonus
			speed *= tuning.gunner_speed_multiplier
		} else if rand.float32() < min(tuning.charger_chance + f32(game.wave) * tuning.charger_chance_wave_bonus, tuning.charger_chance_max) {
			kind = .Charger
			health += tuning.charger_health_bonus
			speed *= tuning.charger_speed_multiplier
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
		rarity := rarity_from_roll()
		durability := tuning.part_base_durability + game.wave * tuning.part_wave_durability
		game.parts[i] = Part{pos = pos, kind = kind, rarity = rarity, durability = durability, alive = true}
		return
	}
}

// Adds one player bullet. Barrel durability is spent once per firing pattern.
fire_one :: proc(direction: Vec2) {
	damage := 1 + game.barrel_level
	if game.cog_effect == .Heavy do damage += int(f32(tuning.cog_heavy_damage) * rarity_scale(game.cog_rarity))
	if game.fuel_effect == .Flame do damage += int(f32(tuning.fuel_flame_damage) * rarity_scale(game.fuel_rarity))
	if game.barrel_durability <= 0 do damage = 1
	bullet_speed := tuning.bullet_speed
	if game.fuel_effect == .Flame do bullet_speed = tuning.fuel_flame_speed
	for i in 0..<MAX_BULLETS {
		if game.bullets[i].alive do continue
		game.bullets[i] = Bullet{
			pos = game.player.pos,
			velocity = vec_scale(direction, bullet_speed),
			damage = damage,
			alive = true,
		}
		return
	}
}

// Creates bullets for the active Cog and Fuel firing effects.
fire :: proc() {
	mouse := rl.GetMousePosition()
	direction := vec_normalize(vec_sub(mouse, game.player.pos))
	if vec_length(direction) < 0.1 do return
	if game.cog_effect == .Spread {
		fire_one(direction)
		spread_count := tuning.cog_spread_count
		spread_angle := tuning.cog_spread_angle
		if game.cog_rarity == .Rare do spread_angle *= 1.15
		if game.cog_rarity == .Epic do spread_angle *= 1.30
		fire_one(vec_rotate(direction, spread_angle))
		if spread_count > 2 do fire_one(vec_rotate(direction, -spread_angle))
		if game.cog_rarity == .Rare {
			fire_one(vec_rotate(direction, spread_angle * 1.8))
			fire_one(vec_rotate(direction, -spread_angle * 1.8))
		}
		if game.cog_rarity == .Epic {
			fire_one(vec_rotate(direction, spread_angle * 1.8))
			fire_one(vec_rotate(direction, -spread_angle * 1.8))
			fire_one(vec_rotate(direction, spread_angle * 2.5))
			fire_one(vec_rotate(direction, -spread_angle * 2.5))
		}
	} else {
		fire_one(direction)
	}
	game.barrel_durability -= 1
	if game.barrel_durability <= 0 {
		game.barrel_durability = 0
		game.message = "BARREL BROKEN - FIND A REPLACEMENT"
		game.message_timer = tuning.barrel_broken_message_duration
	}
}

// Reads movement input, applies bounded movement, and handles automatic firing.
// CP4
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
	fire_rate := tuning.fire_interval - f32(game.grip_level) * tuning.grip_fire_interval_reduction
	if game.fuel_effect == .Turbo {
		turbo_multiplier := tuning.fuel_turbo_fire_multiplier
		if game.fuel_rarity == .Rare do turbo_multiplier *= 0.88
		if game.fuel_rarity == .Epic do turbo_multiplier *= 0.76
		fire_rate *= turbo_multiplier
	}
	if game.fuel_effect == .Flame do fire_rate *= 1.10
	if game.barrel_durability <= 0 do fire_rate = tuning.broken_fire_interval
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
			if !enemy.alive || distance(bullet.pos, enemy.pos) > tuning.player_bullet_hit_range do continue
			enemy.health -= bullet.damage
			bullet.alive = false
			if enemy.health <= 0 {
				enemy.alive = false
				game.kills += 1
				if rand.float32() < tuning.part_drop_chance do drop_part(enemy.pos)
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
		if distance(bullet.pos, game.player.pos) < tuning.enemy_bullet_hit_range && game.player.invulnerable <= 0 {
			apply_player_damage(f32(bullet.damage))
			game.player.invulnerable = tuning.damage_invulnerability_duration
			bullet.alive = false
		}
	}
}

apply_player_damage :: proc(damage: f32) {
	remaining_damage := damage
	if game.player.shield > 0 {
		absorbed := min(game.player.shield, remaining_damage)
		game.player.shield -= absorbed
		remaining_damage -= absorbed
	}
	if remaining_damage > 0 do game.player.health -= remaining_damage
}

// Returns true when a player bullet is moving toward an enemy at close range.
bullet_threatens_enemy :: proc(enemy: ^Enemy) -> bool {
	for bullet in game.bullets {
		if !bullet.alive do continue
		to_enemy := vec_sub(enemy.pos, bullet.pos)
		if distance(bullet.pos, enemy.pos) < tuning.bullet_threat_range && vec_dot(vec_normalize(bullet.velocity), vec_normalize(to_enemy)) > tuning.bullet_threat_dot {
			return true
		}
	}
	return false
}

// Moves a Gunner sideways relative to the nearest incoming bullet.
// CP4
strafe_from_bullets :: proc(enemy: ^Enemy, dt: f32) {
	for bullet in game.bullets {
		if !bullet.alive do continue
		to_enemy := vec_sub(enemy.pos, bullet.pos)
		if distance(bullet.pos, enemy.pos) >= tuning.bullet_threat_range || vec_dot(vec_normalize(bullet.velocity), vec_normalize(to_enemy)) <= tuning.bullet_threat_dot do continue
		side := vec_perpendicular(vec_normalize(bullet.velocity))
		if vec_dot(side, vec_sub(enemy.pos, game.player.pos)) < 0 do side = vec_scale(side, -1)
		enemy.pos = vec_add(enemy.pos, vec_scale(side, enemy.speed * tuning.gunner_strafe_speed_multiplier * dt))
		enemy.pos.x = clamp(enemy.pos.x, 24, ARENA_W - 24)
		enemy.pos.y = clamp(enemy.pos.y, 24, ARENA_H - 24)
		return
	}
}

// Runs each enemy's state machine and applies contact or ranged attacks.
// CP4
update_enemies :: proc(dt: f32) {
	for i in 0..<MAX_ENEMIES {
		enemy := &game.enemies[i]
		if !enemy.alive do continue

		// CP4
		switch enemy.state {
		case .Chase:
			direction := vec_normalize(vec_sub(game.player.pos, enemy.pos))
			if enemy.kind == .Gunner && bullet_threatens_enemy(enemy) {
				// CP4
				enemy.state = .Strafe
				enemy.state_timer = tuning.gunner_strafe_duration
				continue
			}
			if enemy.kind == .Gunner && distance(enemy.pos, game.player.pos) < tuning.gunner_attack_range {
				// CP4
				enemy.state = .Attack
				continue
			}
			// CP4 - Direct steering toward the player
			enemy.pos = vec_add(enemy.pos, vec_scale(direction, enemy.speed * dt))
			if distance(enemy.pos, game.player.pos) < 27 {
				// CP4
				enemy.state = .Attack
			}
		case .Attack:
			if enemy.kind == .Gunner {
				if bullet_threatens_enemy(enemy) {
					// CP4
					enemy.state = .Strafe
					enemy.state_timer = tuning.gunner_strafe_duration
				} else if distance(enemy.pos, game.player.pos) > tuning.gunner_retreat_range {
					// CP4
					enemy.state = .Chase
				} else if distance(enemy.pos, game.player.pos) < tuning.gunner_contact_range {
					// CP4
					enemy.state = .Strafe
					enemy.state_timer = tuning.gunner_strafe_duration
				} else {
					enemy.state_timer -= dt
					if enemy.state_timer <= 0 {
						fire_enemy_bullet(enemy)
						// CP4
						enemy.state = .Recover
						enemy.state_timer = tuning.gunner_fire_interval
					}
				}
				continue
			}
			if distance(enemy.pos, game.player.pos) >= tuning.contact_attack_range {
				// CP4
				enemy.state = .Chase
				continue
			}
			if game.player.invulnerable <= 0 {
				damage := tuning.scrapper_damage
				if enemy.kind == .Charger do damage = tuning.charger_damage
				apply_player_damage(f32(damage))
				game.player.invulnerable = tuning.damage_invulnerability_duration
			}
			// CP4
			enemy.state = .Recover
			enemy.state_timer = tuning.contact_recover_duration
		case .Recover:
			enemy.state_timer -= dt
			if enemy.state_timer <= 0 {
				if enemy.kind == .Gunner {
					if bullet_threatens_enemy(enemy) {
						// CP4
						enemy.state = .Strafe
						enemy.state_timer = tuning.gunner_strafe_duration
					} else if distance(enemy.pos, game.player.pos) > tuning.gunner_retreat_range {
						// CP4
						enemy.state = .Chase
					} else {
						// CP4
						enemy.state = .Attack
					}
				} else if distance(enemy.pos, game.player.pos) < tuning.contact_attack_range {
					// CP4
					enemy.state = .Attack
				} else {
					// CP4
					enemy.state = .Chase
				}
			}
		case .Strafe:
			if enemy.kind != .Gunner {
				// CP4
				enemy.state = .Chase
				continue
			}
			strafe_from_bullets(enemy, dt)
			enemy.state_timer -= dt
			if enemy.state_timer <= 0 {
				if distance(enemy.pos, game.player.pos) > tuning.gunner_retreat_range {
					// CP4
					enemy.state = .Chase
				} else {
					// CP4
					enemy.state = .Attack
				}
			}
		}
	}
}

apply_scrap_effect :: proc(effect: Scrap_Effect, rarity: Part_Rarity) {
	game.player.max_health = tuning.player_health
	game.player.speed = tuning.player_speed
	game.player.shield = 0
	game.scrap_effect = effect
	game.scrap_rarity = rarity
	scale := rarity_scale(rarity)
	switch effect {
	case .Glass:
		game.player.max_health += tuning.scrap_glass_health * scale
		game.player.speed += tuning.scrap_glass_speed * scale
		game.player.shield = tuning.scrap_glass_shield * scale
		game.message = fmt.ctprintf("%s GLASS SCRAP", rarity_name(rarity))
	case .Tank:
		game.player.max_health += tuning.scrap_tank_health * scale
		game.player.speed += tuning.scrap_tank_speed * scale
		game.player.shield = tuning.scrap_tank_shield * scale
		game.message = fmt.ctprintf("%s TANK SCRAP", rarity_name(rarity))
	case .None:
		game.message = "SCRAP REMOVED"
	}
	game.player.max_health = max(game.player.max_health, 1)
	game.player.health = min(game.player.health, game.player.max_health)
	game.player.health = max(game.player.health, 1)
}

// Collects nearby drops and replaces the active effect in that drop's system.
collect_parts :: proc() {
	for i in 0..<MAX_PARTS {
		part := &game.parts[i]
		if !part.alive || distance(part.pos, game.player.pos) > tuning.part_pickup_range do continue
		part.alive = false
		if rl.IsSoundValid(assets.pickup_sound) do rl.PlaySound(assets.pickup_sound)
		switch part.kind {
		case .Fuel:
			game.fuel_rarity = part.rarity
			if rand.float32() < 0.5 {
				game.fuel_effect = .Flame
				game.message = fmt.ctprintf("%s FUEL: FLAME ROUNDS", rarity_name(part.rarity))
			} else {
				game.fuel_effect = .Turbo
				game.message = fmt.ctprintf("%s FUEL: TURBO FIRE", rarity_name(part.rarity))
			}
		case .Cog:
			game.cog_rarity = part.rarity
			if rand.float32() < 0.5 {
				game.cog_effect = .Heavy
				game.message = fmt.ctprintf("%s COG: HEAVY ROUNDS", rarity_name(part.rarity))
			} else {
				game.cog_effect = .Spread
				game.message = fmt.ctprintf("%s COG: SPREAD PATTERN", rarity_name(part.rarity))
			}
		case .Scrap:
			if rand.float32() < 0.5 do apply_scrap_effect(.Glass, part.rarity)
			else do apply_scrap_effect(.Tank, part.rarity)
		}
		game.message_timer = tuning.message_duration
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
	game.wave = 1 + int(game.elapsed / tuning.wave_duration)
	game.spawn_timer -= dt
	spawn_rate := max(tuning.spawn_interval - f32(game.wave) * tuning.spawn_interval_wave_reduction, tuning.spawn_interval_floor)
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
