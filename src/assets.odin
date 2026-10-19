package main

import rl "vendor:raylib"
import "core:fmt"
import "core:strconv"
import "core:strings"

config_path: cstring = "data/game.cfg"

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
	pickup_sound := rl.LoadSound("assets/pickup.wav")
	if !rl.IsSoundValid(pickup_sound) {
		fmt.println("ERROR: Could not load assets/pickup.wav; pickups will be silent.")
	}
	return Assets{player_texture = player_texture, pickup_sound = pickup_sound}
}

unload_assets :: proc(assets: ^Assets) {
	rl.UnloadTexture(assets.player_texture)
	if rl.IsSoundValid(assets.pickup_sound) do rl.UnloadSound(assets.pickup_sound)
	rl.CloseAudioDevice()
}
