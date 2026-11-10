package main

import rl "vendor:raylib"
import "core:fmt"
import "core:encoding/json"
import "core:strconv"
import "core:strings"

config_path: cstring = "data/game.cfg"
level_path: cstring = "data/main_arena.ldtk"
tileset_path: cstring = "assets/Floor Tileset.png"
scrap_path: cstring = "assets/Scrap.png"

// Loads the first LDtk level, copying tiles and the player spawn into fixed arrays.
load_level :: proc() -> Level_Data {
	level_data: Level_Data
	level_data.player_spawn = Vec2{ARENA_W / 2, ARENA_H / 2}
	raw := rl.LoadFileText(level_path)
	if raw == nil {
		fmt.println("ERROR: Could not load data/main_arena.ldtk; using an empty arena.")
		return level_data
	}
	defer rl.UnloadFileText(raw)

	level_file: Level_File
	err := json.unmarshal_string(string(cstring(raw)), &level_file)
	if err != nil || len(level_file.levels) == 0 {
		fmt.println("ERROR: Could not parse data/main_arena.ldtk; using an empty arena.")
		return level_data
	}
	for layer in level_file.levels[0].layer_instances {
		if layer.identifier == "Tiles" {
			for tile in layer.grid_tiles {
				if level_data.tile_count >= MAX_LEVEL_TILES do break
				level_data.tiles[level_data.tile_count] = Arena_Tile{
					position = Vec2{f32(tile.px[0]), f32(tile.px[1])},
					source = rl.Rectangle{f32(tile.src[0]), f32(tile.src[1]), 16, 16},
				}
				level_data.tile_count += 1
			}
		}
		if layer.identifier == "Entities" {
			for entity in layer.entity_instances {
				if entity.identifier == "Player_Spawn" {
					level_data.player_spawn = Vec2{f32(entity.px[0]), f32(entity.px[1])}
				}
			}
		}
	}
	return level_data
}

// Loads default gameplay values, then overrides recognized keys from the config file.
load_tuning :: proc() -> Tuning {
	tuning := Tuning{
		player_speed = 250,
		player_health = 100,
		bullet_speed = 620,
		fire_interval = 0.25,
		grip_fire_interval_reduction = 0.025,
		broken_fire_interval = 0.45,
		spawn_interval = 1.2,
		spawn_interval_floor = 0.28,
		wave_duration = 20,
		spawn_interval_wave_reduction = 0.08,
		enemy_speed = 65,
		enemy_speed_wave_bonus = 3,
		enemy_base_health = 3,
		enemy_health_wave_bonus = 3,
		gunner_health_bonus = 2,
		charger_health_bonus = 3,
		charger_chance = 0.15,
		charger_chance_wave_bonus = 0.01,
		charger_chance_max = 0.35,
		gunner_chance = 0.12,
		gunner_chance_wave_bonus = 0.005,
		gunner_chance_max = 0.25,
		charger_speed_multiplier = 1.35,
		gunner_speed_multiplier = 0.85,
		charger_damage = 14,
		scrapper_damage = 8,
		gunner_damage = 10,
		gunner_bullet_speed = 300,
		gunner_fire_interval = 1.2,
		gunner_attack_range = 300,
		gunner_retreat_range = 320,
		gunner_contact_range = 150,
		gunner_strafe_duration = 0.8,
		gunner_strafe_speed_multiplier = 2.2,
		bullet_threat_range = 105,
		bullet_threat_dot = 0.65,
		contact_attack_range = 32,
		contact_recover_duration = 0.9,
		damage_invulnerability_duration = 0.65,
		enemy_bullet_hit_range = 20,
		player_bullet_hit_range = 22,
		part_drop_chance = 0.55,
		part_base_durability = 20,
		part_wave_durability = 4,
		barrel_starting_durability = 80,
		barrel_starting_max = 80,
		barrel_max_durability = 140,
		barrel_max_increase = 5,
		grip_speed_bonus = 18,
		plating_health_bonus = 12,
		plating_heal = 20,
		part_pickup_range = 30,
		message_duration = 2.5,
		barrel_broken_message_duration = 3,
	}
	raw := rl.LoadFileText(config_path)
	if raw == nil {
		fmt.println("ERROR: Could not load data/game.cfg; using safe defaults.")
		return tuning
	}
	defer rl.UnloadFileText(raw)
	lines, err := strings.split_lines(string(cstring(raw)))
	if err != nil {
		fmt.println("ERROR: Could not parse data/game.cfg; using safe defaults.")
		return tuning
	}
	for line in lines {
		clean_line := strings.trim_space(line)
		if clean_line == "" || clean_line[0] == '#' do continue
		parts, split_err := strings.split_n(clean_line, "=", 2)
		if split_err != nil || len(parts) != 2 do continue
		key := strings.trim_space(parts[0])
		value := strconv.atof(strings.trim_space(parts[1]))
		switch key {
		case "player_speed": tuning.player_speed = f32(value)
		case "player_health": tuning.player_health = f32(value)
		case "bullet_speed": tuning.bullet_speed = f32(value)
		case "fire_interval": tuning.fire_interval = f32(value)
		case "grip_fire_interval_reduction": tuning.grip_fire_interval_reduction = f32(value)
		case "broken_fire_interval": tuning.broken_fire_interval = f32(value)
		case "spawn_interval": tuning.spawn_interval = f32(value)
		case "spawn_interval_floor": tuning.spawn_interval_floor = f32(value)
		case "wave_duration": tuning.wave_duration = f32(value)
		case "spawn_interval_wave_reduction": tuning.spawn_interval_wave_reduction = f32(value)
		case "enemy_speed": tuning.enemy_speed = f32(value)
		case "enemy_speed_wave_bonus": tuning.enemy_speed_wave_bonus = f32(value)
		case "enemy_base_health": tuning.enemy_base_health = int(value)
		case "enemy_health_wave_bonus": tuning.enemy_health_wave_bonus = int(value)
		case "gunner_health_bonus": tuning.gunner_health_bonus = int(value)
		case "charger_health_bonus": tuning.charger_health_bonus = int(value)
		case "charger_chance": tuning.charger_chance = f32(value)
		case "charger_chance_wave_bonus": tuning.charger_chance_wave_bonus = f32(value)
		case "charger_chance_max": tuning.charger_chance_max = f32(value)
		case "gunner_chance": tuning.gunner_chance = f32(value)
		case "gunner_chance_wave_bonus": tuning.gunner_chance_wave_bonus = f32(value)
		case "gunner_chance_max": tuning.gunner_chance_max = f32(value)
		case "charger_speed_multiplier": tuning.charger_speed_multiplier = f32(value)
		case "gunner_speed_multiplier": tuning.gunner_speed_multiplier = f32(value)
		case "charger_damage": tuning.charger_damage = int(value)
		case "scrapper_damage": tuning.scrapper_damage = int(value)
		case "gunner_damage": tuning.gunner_damage = int(value)
		case "gunner_bullet_speed": tuning.gunner_bullet_speed = f32(value)
		case "gunner_fire_interval": tuning.gunner_fire_interval = f32(value)
		case "gunner_attack_range": tuning.gunner_attack_range = f32(value)
		case "gunner_retreat_range": tuning.gunner_retreat_range = f32(value)
		case "gunner_contact_range": tuning.gunner_contact_range = f32(value)
		case "gunner_strafe_duration": tuning.gunner_strafe_duration = f32(value)
		case "gunner_strafe_speed_multiplier": tuning.gunner_strafe_speed_multiplier = f32(value)
		case "bullet_threat_range": tuning.bullet_threat_range = f32(value)
		case "bullet_threat_dot": tuning.bullet_threat_dot = f32(value)
		case "contact_attack_range": tuning.contact_attack_range = f32(value)
		case "contact_recover_duration": tuning.contact_recover_duration = f32(value)
		case "damage_invulnerability_duration": tuning.damage_invulnerability_duration = f32(value)
		case "enemy_bullet_hit_range": tuning.enemy_bullet_hit_range = f32(value)
		case "player_bullet_hit_range": tuning.player_bullet_hit_range = f32(value)
		case "part_drop_chance": tuning.part_drop_chance = f32(value)
		case "part_base_durability": tuning.part_base_durability = int(value)
		case "part_wave_durability": tuning.part_wave_durability = int(value)
		case "barrel_starting_durability": tuning.barrel_starting_durability = int(value)
		case "barrel_starting_max": tuning.barrel_starting_max = int(value)
		case "barrel_max_durability": tuning.barrel_max_durability = int(value)
		case "barrel_max_increase": tuning.barrel_max_increase = int(value)
		case "grip_speed_bonus": tuning.grip_speed_bonus = f32(value)
		case "plating_health_bonus": tuning.plating_health_bonus = f32(value)
		case "plating_heal": tuning.plating_heal = f32(value)
		case "part_pickup_range": tuning.part_pickup_range = f32(value)
		case "message_duration": tuning.message_duration = f32(value)
		case "barrel_broken_message_duration": tuning.barrel_broken_message_duration = f32(value)
		}
	}
	return tuning
}

// Creates the generated player texture and loads the external tileset and pickup sound.
load_assets :: proc() -> Assets {
	rl.InitAudioDevice()
	image := rl.GenImageChecked(32, 32, 4, 4, rl.LIME, rl.DARKGREEN)
	player_texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	tileset_texture := rl.LoadTexture(tileset_path)
	if !rl.IsTextureValid(tileset_texture) {
		fmt.println("ERROR: Could not load assets/Floor Tileset.png; arena tiles will be blank.")
	}
	scrap_texture := rl.LoadTexture(scrap_path)
	if !rl.IsTextureValid(scrap_texture) {
		fmt.println("ERROR: Could not load assets/Scrap.png; pickup icons will use fallback colors.")
	}
	pickup_sound := rl.LoadSound("assets/pickup.wav")
	if !rl.IsSoundValid(pickup_sound) {
		fmt.println("ERROR: Could not load assets/pickup.wav; pickups will be silent.")
	}
	return Assets{
		player_texture = player_texture,
		tileset_texture = tileset_texture,
		scrap_texture = scrap_texture,
		pickup_sound = pickup_sound,
	}
}

// Releases every Raylib resource acquired by load_assets.
unload_assets :: proc(assets: ^Assets) {
	rl.UnloadTexture(assets.player_texture)
	rl.UnloadTexture(assets.tileset_texture)
	rl.UnloadTexture(assets.scrap_texture)
	if rl.IsSoundValid(assets.pickup_sound) do rl.UnloadSound(assets.pickup_sound)
	rl.CloseAudioDevice()
}
