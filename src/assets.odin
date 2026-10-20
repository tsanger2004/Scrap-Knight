package main

import rl "vendor:raylib"
import "core:fmt"
import "core:encoding/json"
import "core:strconv"
import "core:strings"

config_path: cstring = "data/game.cfg"
level_path: cstring = "data/main_arena.ldtk"
tileset_path: cstring = "assets/Floor Tileset.png"

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

load_tuning :: proc() -> Tuning {
	tuning := Tuning{
		player_speed = 250,
		bullet_speed = 620,
		fire_interval = 0.25,
		spawn_interval = 1.2,
		spawn_interval_floor = 0.28,
		enemy_speed = 65,
		charger_chance = 0.15,
		charger_damage = 14,
		scrapper_damage = 8,
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
		case "bullet_speed": tuning.bullet_speed = f32(value)
		case "fire_interval": tuning.fire_interval = f32(value)
		case "spawn_interval": tuning.spawn_interval = f32(value)
		case "spawn_interval_floor": tuning.spawn_interval_floor = f32(value)
		case "enemy_speed": tuning.enemy_speed = f32(value)
		case "charger_chance": tuning.charger_chance = f32(value)
		case "charger_damage": tuning.charger_damage = int(value)
		case "scrapper_damage": tuning.scrapper_damage = int(value)
		}
	}
	return tuning
}

load_assets :: proc() -> Assets {
	rl.InitAudioDevice()
	image := rl.GenImageChecked(32, 32, 4, 4, rl.LIME, rl.DARKGREEN)
	player_texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	tileset_texture := rl.LoadTexture(tileset_path)
	if !rl.IsTextureValid(tileset_texture) {
		fmt.println("ERROR: Could not load assets/Floor Tileset.png; arena tiles will be blank.")
	}
	pickup_sound := rl.LoadSound("assets/pickup.wav")
	if !rl.IsSoundValid(pickup_sound) {
		fmt.println("ERROR: Could not load assets/pickup.wav; pickups will be silent.")
	}
	return Assets{player_texture = player_texture, tileset_texture = tileset_texture, pickup_sound = pickup_sound}
}

unload_assets :: proc(assets: ^Assets) {
	rl.UnloadTexture(assets.player_texture)
	rl.UnloadTexture(assets.tileset_texture)
	if rl.IsSoundValid(assets.pickup_sound) do rl.UnloadSound(assets.pickup_sound)
	rl.CloseAudioDevice()
}
