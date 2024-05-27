# Kieran Griperay
# kjg86@pitt.edu

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

# updates all the parts of the game.dsa
update_all:
enter
	jal obj_update_all
	jal update_timers
	jal update_camera
leave

# ------------------------------------------------------------------------------------------------

# updates all timer variables (well... there's just one)
update_timers:
enter s0
	lw s0, player_move_timer
	ble s0, 0, _break
	sub s0, s0, 1
	sw s0, player_move_timer
	_break:
	
	
leave s0

# ------------------------------------------------------------------------------------------------

# positions camera based on player position.
update_camera:
enter
	li a0, 0
	jal obj_get_topleft_pixel_coords
	add v0 v0 CAMERA_OFFSET_X
	add v1 v1 CAMERA_OFFSET_Y
	move a0, v0
	move a1, v1
	jal tilemap_set_scroll
	
leave

# ------------------------------------------------------------------------------------------------
# Player object
# ------------------------------------------------------------------------------------------------

# a0 = object index (but you can just access the player_ variables directly)
obj_update_player:
enter
	lw t0, player_moving
	bne t0, 0, _skip_place_input
	
	jal player_check_goal
	jal player_check_vines
	
	bne v0, 0, _leave
	
	jal player_check_place_input
	jal player_check_move_input
	j _breakkk
	
_skip_place_input:
	li a0, 0
	jal obj_move
	
	
_leave:
_breakkk:
	jal player_check_dig_input
leave

# ------------------------------------------------------------------------------------------------
player_check_goal:
enter s0 s1
	li a0, 0
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	
	jal tilemap_get_tile
	move t0, v0
	bne t0, TILE_GOAL, _stahp
	lw s0, bugs_saved
	lw s1, bugs_to_save
	bne s0, s1, _stahp
	
	li t0, 1
	sw t0, game_over
	_stahp:
leave s0 s1
# ------------------------------------------------------------------------------------------------
player_check_vines:
enter s0
	li a0, 0
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	
	jal tilemap_get_tile
	move t0, v0
	
	bne t0, TILE_VINES, _no_vine
	move a0, zero
	li a1, PLAYER_MOVE_VELOCITY
	li a2, PLAYER_MOVE_DURATION
	jal obj_start_moving_backward
	_no_vine:
	li v0, 0

leave s0
# ------------------------------------------------------------------------------------------------
player_check_place_input:
enter s0
	#key check
	jal input_get_keys_pressed
	and s0, v0, KEY_Z
	beq s0, 0, _end
	#performs or to check grade_mode and player dirt
	li t0, GRADER_MODE
	lw t1, player_dirt
	or t0, t0, t1
	beq t0, 0, _end
	#this checks the tile infront
	
	li a0, 0
	jal obj_get_tile_coords_in_front
	move a0, v0
	move a1, v1
	
	jal tilemap_get_tile
	bne v0, TILE_EMPTY, _end
	
	#check if object
	li a0, 0
	li a1, TILE_SIZE
	jal obj_get_pixel_coords_in_front
	
	move a0, v0
	move a1, v1
	
	jal obj_find_at_position
	bne v0, -1, _end
	
	li a0, 0
	#li a1, TILE_SIZE
	jal obj_get_tile_coords_in_front
	
	move a0, v0
	move a1, v1
	li a2, TILE_DIRT
	jal tilemap_set_tile
	
	lw t0, player_dirt
	sub t0, t0, 1
	sw t0, player_dirt
	
	_end:
leave s0
# ------------------------------------------------------------------------------------------------
player_check_move_input:
enter s0
	jal input_get_keys_held
	move s0, v0
	
	and t0, s0, KEY_U
	beq t0, 0, _endIFU
	li a0, DIR_N
	jal player_try_move
	
_endIFU:
	and t0, s0, KEY_D
	beq t0, 0, _endIFS
	li a0, DIR_S
	jal player_try_move
_endIFS:
	and t0, s0, KEY_L
	beq t0, 0, _endIFW
	li a0, DIR_W
	jal player_try_move
_endIFW:
	and t0, s0, KEY_R
	beq t0, 0, _endIFE
	li a0, DIR_E
	jal player_try_move
_endIFE:

leave s0
# ------------------------------------------------------------------------------------------------
player_try_move:

enter s0 s1
	lw s0 player_dir
	
	beq s0, a0, _skip
	move s1, a0
	
	sw a0, player_dir
	
	li s0, PLAYER_MOVE_DELAY
	sw s0, player_move_timer
	
	_skip:
	
	lw s0, player_move_timer
	bne s0, 0, _ignore
	
	li s0, PLAYER_MOVE_DELAY
	move s1, s0
	sw s1, player_move_timer
	
	li a0, 0
	lw a1, player_dir
	jal obj_collision_check
	
	beq v0, COLLISION_TILE, _cTile
	beq v0, COLLISION_OBJ, _object
	j _default
	_cTile:
		li v0 COLLISION_TILE
		j _ignore
	_object:
		#li v0 COLLISION_OBJ
		move a0, v1
		jal player_try_push_object
		beq v0, 0, _ignore
		
	#come back to
	_default:
	move a0, zero
	li a1, PLAYER_MOVE_VELOCITY
	li a2, PLAYER_MOVE_DURATION
	jal obj_start_moving_forward
	
	_ignore:
leave s0 s1
# ------------------------------------------------------------------------------------------------
player_try_push_object:
enter s0 s1
	move t0, a0
	move s1, a0
	
	lw s0, player_dir
	
	beq s0, DIR_E, _continue
	beq s0, DIR_W, _continue
	
	j _return_no
	_continue:
	move a0, t0
	lw s0, object_moving(s1)
	bne s0, 0, _return_no
	#check for obstruction
	move a0, t0
	lw a1, player_dir
	jal obj_collision_check
	beq v0, COLLISION_NONE, _push
	beq v0, COLLISION_TILE, _return_no
	beq v0, COLLISION_OBJ, _return_no
	
	j _dip
	_push:
		move a0, s1
		lw a1, player_dir
		jal obj_push
		
	_return_yes:
		li v0, 1
		j _dip
	_return_no:
		li v0, 0
	_dip:
leave s0 s1
# ------------------------------------------------------------------------------------------------
player_check_dig_input:
enter s0
	jal input_get_keys_pressed
	and s0, v0, KEY_X
	beq s0, 0, _endAnd
	
	li a0 0
	jal obj_get_tile_coords_in_front
	move a0, v0
	move a1, v1
	
	jal tilemap_get_tile
	
	bne v0, TILE_DIRT, _endAnd
	
	li a0, 0
	jal obj_get_tile_coords_in_front
	move a0, v0
	move a1, v1
	
	li a2, TILE_EMPTY
	jal tilemap_set_tile
	
	lw s0, player_dirt
	beq s0, PLAYER_MAX_DIRT, _skip_dirt
	add s0, s0 1
	
	_skip_dirt:
	sw s0, player_dirt
	
	_endAnd:
leave s0
# ------------------------------------------------------------------------------------------------
# Diamond object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_diamond:
enter s0
	move s0, a0 #diamond obj
	jal obj_move_or_check_for_falling #check to see if it should fall
	
	move a0, s0
	jal obj_collides_with_player #check collision
	bne v0, 1, _leave_diamond
	
	lw t0, player_diamonds
	add t0, t0, 1
	sw t0, player_diamonds
	
	move a0, s0
	jal obj_free
	
	_leave_diamond:
leave s0

# ------------------------------------------------------------------------------------------------
# Boulder object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_boulder:
enter
	jal obj_move_or_check_for_falling
leave

# ------------------------------------------------------------------------------------------------
# Bug object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_bug:
enter s0 s1 s2
	move s2, a0
	
	lw t0, object_moving(s2)
	beq t0, 0, _object_not_moving
		jal obj_move
		j _aight_imma_head_out
	
	_object_not_moving:
	#else part
	#check for goal tile
	move a0, s2
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	jal tilemap_get_tile
	
	bne v0, TILE_GOAL, _bug_not_on_goal #if bug is on goal
	move a0, s2
	lw s0, bugs_saved #runs if the bug is on the goal

	add s0, s0, 1
	sw s0, bugs_saved
	move a0, s2
	jal obj_free
	
_bug_not_on_goal:
	#chekc for vine
	move a0, s2
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	jal tilemap_get_tile
	
	beq v0, TILE_VINES, _vines
	j _move_sequence
	_vines:
	
	move a0, s2
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	li a2, TILE_EMPTY
	jal tilemap_set_tile
	
	_move_sequence:
	#begin move sequence
	#check infront 
	move a0, s2
	jal check_front
	move s1, v0
	
	#j _move_it
		
		#check for brick on left of bug
		lw a1, object_dir(s2)
		move a0, s2
		add a1, a1, 3
		rem a1, a1, 4
		jal obj_collision_check
		beq v0, COLLISION_NONE, _turn_left
		beq v0, COLLISION_TILE, _turn_right
		beq v0, COLLISION_OBJ, _turn_right
		
		_turn_right:
			move a0, s2
			bne s1, 1, _move_it
			lw t0, object_dir(s2) #this rotates bug right
			add t0, t0, 1
			rem t0, t0, 4
			sw t0, object_dir(s2)
			
			jal obj_draw_bug
			j _aight_imma_head_out
			
			_move_it:
			move a0, s2
			jal buggy
			j _aight_imma_head_out
		_turn_left:
			
			
			lw t0, object_dir(s2)
			add t0, t0, 3
			rem t0, t0, 4
			sw t0, object_dir(s2)
			move a0, s2
			jal obj_draw_bug
			j _move_it
			
	_aight_imma_head_out:
	
leave s0 s1 s2
# ------------------------------------------------------------------------------------------------
buggy:
enter

	li a1, BUG_MOVE_VELOCITY
	li a2, BUG_MOVE_DURATION
	jal obj_start_moving_forward
leave
# ------------------------------------------------------------------------------------------------
check_front:
enter s0
	 #checks in front of bug for tile, or obj
	move s0, a0
	lw a1, object_dir(s0)
	jal obj_collision_check
	beq v0, 1, _return1
	beq v0, 0, _return1
	beq v0, -1, _return0
	
	_return1:
	li v0, 1
	j _end_front
	_return0:
	li v0, 0
	
	_end_front:
leave s0
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
	jal obj_get_topleft_pixel_coords
	
	move a0, v0
	move a1, v1
	
	lw t0, player_dir
	mul t0, t0, 4
	
	lw a2, player_textures(t0)
	
	jal blit_5x5_sprite_trans
	
	
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_diamond:
enter
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	la a2, tex_diamond
	
	jal blit_5x5_sprite_trans
	
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_boulder:
enter
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	la a2, tex_boulder
	
	jal blit_5x5_sprite_trans
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_bug:
enter s0
move s0, a0
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	lw t0, object_dir(s0)
	
	mul t0, t0, 4
	lw a2, bug_textures(t0)
	
	jal blit_5x5_sprite_trans

leave s0 

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
# ------------------------------------------------------------------------------------------------

