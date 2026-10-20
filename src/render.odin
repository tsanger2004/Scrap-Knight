package main

import rl "vendor:raylib"
import "core:fmt"

draw_game :: proc() {
	rl.ClearBackground(rl.Color{16, 20, 25, 255})
	rl.DrawRectangle(0, 0, ARENA_W, ARENA_H, rl.Color{25, 31, 35, 255})
	for i in 0..<level.tile_count {
		tile := level.tiles[i]
		rl.DrawTextureRec(assets.tileset_texture, tile.source, tile.position, rl.WHITE)
	}
	for part in game.parts {
		if !part.alive do continue
		color := rl.GOLD
		if part.kind == .Grip do color = rl.SKYBLUE
		if part.kind == .Plating do color = rl.LIGHTGRAY
		rl.DrawRectangleV(vec_sub(part.pos, Vec2{8, 8}), Vec2{16, 16}, color)
		rl.DrawRectangleLines(i32(part.pos.x - 8), i32(part.pos.y - 8), 16, 16, rl.WHITE)
	}
	for bullet in game.bullets {
		if bullet.alive do rl.DrawCircleV(bullet.pos, 4, rl.YELLOW)
	}
	for enemy in game.enemies {
		if !enemy.alive do continue
		color := rl.ORANGE
		if enemy.kind == .Charger do color = rl.RED
		rl.DrawCircleV(enemy.pos, 17, color)
		rl.DrawCircleV(enemy.pos, 8, rl.Color{50, 35, 30, 255})
	}
	player_color := rl.LIME
	if game.player.invulnerable > 0 do player_color = rl.WHITE
	rl.DrawTextureV(assets.player_texture, vec_sub(game.player.pos, Vec2{16, 16}), player_color)
	aim := vec_normalize(vec_sub(rl.GetMousePosition(), game.player.pos))
	rl.DrawLineEx(game.player.pos, vec_add(game.player.pos, vec_scale(aim, 28)), 6, rl.DARKGRAY)
	rl.DrawRectangle(SIDEBAR_X, 0, SCREEN_W - SIDEBAR_X, SCREEN_H, rl.Color{13, 17, 21, 255})
	rl.DrawText("SCRAP KNIGHT", SIDEBAR_X + 24, 26, 28, rl.GOLD)
	rl.DrawText("SURVIVE THE SCRAPYARD", SIDEBAR_X + 25, 60, 14, rl.LIGHTGRAY)
	rl.DrawText(fmt.ctprintf("WAVE %d", game.wave), SIDEBAR_X + 25, 102, 24, rl.WHITE)
	rl.DrawText(fmt.ctprintf("KILLS %d", game.kills), SIDEBAR_X + 25, 133, 18, rl.LIGHTGRAY)
	rl.DrawText("HULL", SIDEBAR_X + 25, 180, 15, rl.LIGHTGRAY)
	rl.DrawRectangle(SIDEBAR_X + 25, 202, 210, 18, rl.Color{65, 28, 28, 255})
	rl.DrawRectangle(SIDEBAR_X + 25, 202, i32(210 * max(game.player.health, 0) / game.player.max_health), 18, rl.GREEN)
	rl.DrawText(fmt.ctprintf("%d / %d", int(max(game.player.health, 0)), int(game.player.max_health)), SIDEBAR_X + 82, 202, 14, rl.WHITE)
	rl.DrawText("WEAPON PARTS", SIDEBAR_X + 25, 255, 16, rl.GOLD)
	rl.DrawText(fmt.ctprintf("BARREL  %d / %d", game.barrel_durability, game.barrel_max), SIDEBAR_X + 25, 285, 17, rl.WHITE)
	barrel_color := rl.LIME
	if game.barrel_durability < 20 do barrel_color = rl.RED
	rl.DrawRectangle(SIDEBAR_X + 25, 311, 210, 12, rl.DARKGRAY)
	rl.DrawRectangle(SIDEBAR_X + 25, 311, i32(210 * f32(game.barrel_durability) / f32(game.barrel_max)), 12, barrel_color)
	rl.DrawText(fmt.ctprintf("BARREL LV %d", game.barrel_level), SIDEBAR_X + 25, 337, 15, rl.LIGHTGRAY)
	rl.DrawText(fmt.ctprintf("GRIP LV %d", game.grip_level), SIDEBAR_X + 25, 365, 15, rl.LIGHTGRAY)
	rl.DrawText(fmt.ctprintf("PLATING LV %d", game.plating_level), SIDEBAR_X + 25, 393, 15, rl.LIGHTGRAY)
	rl.DrawText("WASD / ARROWS  MOVE", SIDEBAR_X + 25, 510, 14, rl.LIGHTGRAY)
	rl.DrawText("MOUSE  AIM + FIRE", SIDEBAR_X + 25, 534, 14, rl.LIGHTGRAY)
	rl.DrawText("COLLECT GLOWING PARTS", SIDEBAR_X + 25, 558, 14, rl.LIGHTGRAY)
	if game.message_timer > 0 do rl.DrawText(game.message, 25, ARENA_H - 34, 16, rl.GOLD)
	if game.state == .Game_Over {
		rl.DrawRectangle(0, 0, ARENA_W, ARENA_H, rl.Color{0, 0, 0, 170})
		rl.DrawText("THE SCRAPYARD CLAIMED YOU", 220, 285, 30, rl.RED)
		rl.DrawText(fmt.ctprintf("Survived wave %d  |  Kills %d", game.wave, game.kills), 320, 330, 18, rl.WHITE)
		rl.DrawText("PRESS R TO REBUILD", 355, 375, 20, rl.GOLD)
	}
}
