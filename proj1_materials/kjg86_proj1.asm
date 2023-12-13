# YOUR FULL NAME HERE
# YOUR PITT USERNAME HERE

# This is used in a few places to make grading your project easier.
.eqv GRADER_MODE 0

# This .include has to be up here so we can use the constants in the variables below.
.include "game_constants.asm"

# ------------------------------------------------------------------------------------------------
.data
# Boolean (0/1): 1 when the game is over, either successfully or not.
game_over: .word 0

# 0 = player can move, nonzero = they can't
player_move_timer: .word 0

# How many diamonds the player has collected.
player_diamonds: .word 0

# How many dirt blocks the player has picked up.
player_dirt: .word 0

# How many bugs the player has saved.
bugs_saved: .word 0

# How many bugs need to be saved.
bugs_to_save: .word 0

# Object arrays. These are parallel arrays. The player object is in slot 0,
# so the "player_x" and "player_y" labels are pointing to the same place as
# slot 0 of those arrays. Same thing for the other arrays.
object_type:   .word OBJ_EMPTY:NUM_OBJECTS
player_x:
object_x:      .word 0:NUM_OBJECTS # fixed 24.8 - X position
player_y:
object_y:      .word 0:NUM_OBJECTS # fixed 24.8 - Y position
player_vx:
object_vx:     .word 0:NUM_OBJECTS # fixed 24.8 - X velocity
player_vy:
object_vy:     .word 0:NUM_OBJECTS # fixed 24.8 - Y velocity
player_moving:
object_moving: .word 0:NUM_OBJECTS # 0 = still, nonzero = moving for this many frames
player_dir:
object_dir:    .word 0:NUM_OBJECTS # direction object is facing

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2227_0611.asm"
.include "tilemap.asm"
.include "textures.asm"
.include "map.asm"
.include "levels.asm"
.include "obj.asm"
.include "collide.asm"

# ------------------------------------------------------------------------------------------------

.globl main
main:
	# load the map and objects
	la  a0, level_1
	#la  a0, test_level_dirt
	#la  a0, test_level_diamonds
	#la  a0, test_level_vines
	#la  a0, test_level_boulders
	#la  a0, test_level_goal
	#la  a0, test_level_bug_movement
	#la  a0, test_level_bug_vines
	#la  a0, test_level_bug_goal
	#la  a0, test_level_blank
	jal load_map

	# main game loop
	_loop:
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	# might seem silly to have the whole function be one line,
	# but abstracting it into a function like this means that we
	# can expand the "game over" condition in the future.
	lw v0, game_over
leave

# ------------------------------------------------------------------------------------------------

# does what it says.
show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# they finished successfully!
	li   a0, 7
	li   a1, 15
	lstr a2, "yay! you"
	li   a3, COLOR_GREEN
	jal  display_draw_colored_text

	li   a0, 12
	li   a1, 21
	lstr a2, "did it!"
	li   a3, COLOR_GREEN
	jal  display_draw_colored_text

	li   a0, 25
	li   a1, 37
	la   a2, tex_diamond
	jal  display_blit_5x5_trans

	li   a0, 32
	li   a1, 37
	lw   a2, player_diamonds
	jal  display_draw_int

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------

# updates all the parts of the game.
update_all:
enter
	jal obj_update_all
	jal update_timers
	jal update_camera
leave

# ------------------------------------------------------------------------------------------------

# updates all timer variables (well... there's just one)
update_timers:
enter

leave

# ------------------------------------------------------------------------------------------------

# positions camera based on player position.
update_camera:
enter

leave

# ------------------------------------------------------------------------------------------------
# Player object
# ------------------------------------------------------------------------------------------------

# a0 = object index (but you can just access the player_ variables directly)
obj_update_player:
enter

leave

# ------------------------------------------------------------------------------------------------
# Diamond object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_diamond:
enter

leave

# ------------------------------------------------------------------------------------------------
# Boulder object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_boulder:
enter

leave

# ------------------------------------------------------------------------------------------------
# Bug object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_bug:
enter

leave

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

# draws everything.
draw_all:
enter
	jal tilemap_draw
	jal obj_draw_all
	jal hud_draw
leave

# ------------------------------------------------------------------------------------------------

# draws the HUD ("heads-up display", the icons and numbers at the top of the screen)
hud_draw:
enter
	# draw a big black rectangle - this covers up any objects that move off
	# the top of the tilemap area
	li  a0, 0
	li  a1, 0
	li  a2, 64
	li  a3, TILEMAP_VIEWPORT_Y
	li  v1, COLOR_BLACK
	jal display_fill_rect_fast

	# draw how many diamonds the player has
	li  a0, 1
	li  a1, 1
	la  a2, tex_diamond
	jal display_blit_5x5_trans

	li  a0, 7
	li  a1, 1
	lw  a2, player_diamonds
	jal display_draw_int

	# draw how many dirt blocks the player has
	li  a0, 20
	li  a1, 1
	la  a2, tex_dirt
	jal display_blit_5x5_trans

	li  a0, 26
	li  a1, 1
	lw  a2, player_dirt
	jal display_draw_int

	# draw how many bugs have been saved and need to be saved
	li  a0, 39
	li  a1, 1
	la  a2, tex_bug_N
	jal display_blit_5x5_trans

	li  a0, 45
	li  a1, 1
	lw  a2, bugs_saved
	jal display_draw_int

	li  a0, 51
	li  a1, 1
	li  a2, '/'
	jal display_draw_char

	li  a0, 57
	li  a1, 1
	lw  a2, bugs_to_save
	jal display_draw_int
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index (but you can just access the player_ variables directly)
obj_draw_player:
enter

leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_diamond:
enter

leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_boulder:
enter

leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_bug:
enter

leave

# ------------------------------------------------------------------------------------------------

# a0 = world x
# a1 = world y
# a2 = pointer to texture
# draws a 5x5 image, but coordinates are relative to the "world" (i.e. the tilemap).
# figures out the screen coordinates and draws it there.
blit_5x5_sprite_trans:
enter
	# draw the dang thing
	# x = x - tilemap_scx + TILEMAP_VIEWPORT_X
	lw  t0, tilemap_scx
	sub a0, a0, t0
	add a0, a0, TILEMAP_VIEWPORT_X

	# y = y - tilemap_scy + TILEMAP_VIEWPORT_Y
	lw  t0, tilemap_scy
	sub a1, a1, t0
	add a1, a1, TILEMAP_VIEWPORT_Y

	jal display_blit_5x5_trans
leave