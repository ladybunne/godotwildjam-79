class_name JumpComponent
extends PlatformerComponent

# ---------------------------------------------------------
# NOTE: Need to add an option for short-hops.
# ---------------------------------------------------------

# Note 2: Add buffered walljumps.

# Note 3: Add ceiling bonks.

# Parabolic Jump Parameters

# Representation of how fast the character can move at max speed.
# Expressed as a number of pixels travelled per second.
#@export var max_run_speed: int = 400

# Horizontal distance to be reached by the peak of the jump.
# (e.g. half the TOTAL distance desired on flat terrain)
# Expressed as a number of pixels.
#@export var target_distance: int = 64

## Vertical distance to be reached by the peak of the jump.
## Expressed as a number of grid spaces.
@export var jump_height_tiles: float = 5

## Time to reach the peak of the jump, expressed in seconds.
@export var jump_duration: float = 0.4

# Internal variable used for jump calculations.
var jump_velocity: float = 0

## The highest amount of tiles per second you can fall at. Ignored if zero.
## Recommended values: jump height x 4 for a floaty feel, x6 or x8 for a faster fall.
## (Note: these numbers are NOT scientific, lmfao.)
@export var terminal_velocity: int = 0

## The max amount of seconds you can wait before inputting jump after walking off a ledge
## and having it still count as a jump.
@export_range(0.0, 1 << 32) var coyote_time: float = 0.1

var coyote_time_timer: Timer = null :
	set(p_coyote_time_timer):
			coyote_time_timer = p_coyote_time_timer
			if coyote_time_timer != null:
				coyote_time_timer.wait_time = coyote_time
				coyote_time_timer.one_shot = true
				coyote_time_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS

var is_on_floor_cache: bool = false


## Doublejumps. Set to -1 to enable infinite doublejumps.
@export var air_jumps: int = 0
var current_air_jumps: int = air_jumps

## Whether air jumps get refreshed by touching a wall.
@export var refresh_air_jumps_on_wallslide: bool = false

## Whether holding down disables airjumps.
@export var air_jump_hold_down_to_disable: bool = true


## Whether you can glide by holding down jump.
@export var glide_enabled: bool = false

## The amount of tiles you fall per second while gliding.
@export var glide_fall_speed: float = 2.0

## Whether holding down lets you preserve doublejumps by engaging hover without doublejumping.
@export var glide_hold_down_preserves_doublejump: bool = true


## Whether you can slide down walls you're in contact with.
@export var wallslide_enabled: bool = false

## The amount of tiles you fall per second while wallsliding.
@export var wallslide_speed: float = 3.0

## The multiplier applied to the character's max run speed when initiating a walljump.
## Basically the speed you get launched [i]from[/i] the wall.
## Bad, temporary.
@export var walljump_kick: float = 1.5

## Whether holding down disables wallsliding.
@export var wallslide_hold_down_to_disable: bool = true

## Whether you need to hold towards the wall in order to walljump off it.
@export var walljump_hold_in_required: bool = true

## Whether you can perform walljumps while moving upwards.
@export var walljump_rejump_while_going_up: bool = true

## Coyote jumping but for walljumps.
@export_range(0.0, 1 << 32) var walljump_coyote_time: float = 0.1

## Timer for coyote walljumps.
var walljump_coyote_time_timer: Timer = null :
	set(p_walljump_coyote_time_timer):
			walljump_coyote_time_timer = p_walljump_coyote_time_timer
			if walljump_coyote_time_timer != null:
				walljump_coyote_time_timer.wait_time = walljump_coyote_time
				walljump_coyote_time_timer.one_shot = true
				walljump_coyote_time_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS

## Caching of is_on_wall() for coyote walljump stuff.
var is_on_wall_cache: bool = false

var wallslide_shapecast: ShapeCast2D = null


## Whether you can fly by holding jump. Holding down stops this, if you really want to glide.
@export var flight_enabled: bool = false

## The speed at which you can fly.
@export var flight_speed: float = 5.0

## Whether holding up lets you preserve doublejumps by engaging flight without doublejumping.
@export var flight_hold_up_preserves_doublejump: bool = true

## Whether holding down just disables flying entirely.
@export var flight_hold_down_to_disable: bool = true


@export_group("Wallslide Extras (Not Implemented)")

## Not implemented yet.
@export var hold_up_to_wallcling: bool = false

## Not implemented yet.
@export var wallcling_duration: float = 0.0

@export_group("")


@export_group("Not Implemented Yet")

## Whether to defer horizontal velocity to the run component.
## If this is disabled, the jump component will be expected to handle
## horizontal movement while in midair.
## Not implemented yet.
@export var defer_hvel_to_run_component: bool = true

## The amount of seconds the character spends in jumpsquat before starting a jump.
## Not implemented yet.
@export var jumpsquat_time: float = 0.0

## The max amount of seconds you can pre-buffer a jump input while about to hit the ground. 
## Not implemented yet.
@export var rejump_buffer_time: float = 0.25

@export_group("")

# Input names. Set by the PlatformerCharacter this exists on.
# This should be removed; instead, pass through "did jump this frame" or something?
# Gotta think about the paradigms, Jonas!
var move_left_name: String = ""
var move_right_name: String = ""
var move_up_name: String = ""
var move_down_name: String = ""
var jump_name: String = ""

# Animation stuff. To be removed in lieu of states!
var is_gliding: bool = false
var is_wallsliding: bool = false
var is_flying: bool = false


var is_on_wall: bool = false
var jumped_this_frame: bool = false

# Have flight use an on/off paradigm rather than just holding it down.
var flight_on: bool = false

enum JumpState {
	NONE,
	UNKNOWN,
	GROUND,
	JUMP,
	FALL,
	WALLSLIDE,
	WALLJUMP,
	GLIDE,
	FLY,
}

var jump_state: JumpState = JumpState.GROUND

func jump_height(p_bonus_height: int = 0) -> float:
	return maxf(1.0, jump_height_tiles + p_bonus_height) * maxi(1, grid_height)

func target_duration() -> float:
	#return float(jump_distance) / max_run_speed
	return 1.0

func initial_velocity(p_bonus_height: int = 0, p_bonus_duration: float = 0.0) -> float:
	# Old method
	# return -gravity() * jump_duration
	
	# New method
	return -(2 * jump_height(p_bonus_height) / jump_duration + p_bonus_duration)

func gravity() -> float:
	return -(-2 * jump_height() / pow(jump_duration, 2))

# Added parameters to let other things (i.e. launchpads!) add extra jump height.
# Returns if the jump was a coyote jump.
func jump(p_bonus_height: int = 0, p_bonus_duration: float = 0.0) -> bool:
	jump_velocity = initial_velocity(p_bonus_height, p_bonus_duration)
	jump_state = JumpState.JUMP

	var was_coyote_jump: bool = false
	
	# Stop the coyote timer if this was a coyote jump.
	if coyote_time > 0 and not coyote_time_timer.is_stopped():
#		print("coyote!")
		was_coyote_jump = true
	
	# Just always stop coyote timers if we jump, because it would be silly to not.
	coyote_time_timer.stop()
	walljump_coyote_time_timer.stop()
	
	jumped_this_frame = true
	
	return was_coyote_jump

# Separate jump function for walljumps to save my sanity.
func walljump(p_character: PlatformerCharacter):
	jump_velocity = initial_velocity()
	jump_state = JumpState.WALLJUMP
	
	# Stop the coyote walljump timer if this was a coyote jump.
	if wallslide_enabled and walljump_coyote_time > 0 and not walljump_coyote_time_timer.is_stopped():
		#print("wall coyote!")
		pass
	
	# Same as above.
	coyote_time_timer.stop()
	walljump_coyote_time_timer.stop()
	
	jumped_this_frame = true
	
	# Obviously a LOT more needs to be done here.
	# Add in a "sidewards kick" a la Zero Mission.
	# Update: This is really, truly, absolutely awful.
	# I'm so sorry, future me.
	p_character.run_component.vector.x = p_character.run_component.speed() * walljump_kick \
		* p_character.get_wall_normal().x

# You've left a wall (for the purposes of walljumps) on this frame if:
# - you were on a wall last frame
# - your x-position has changed since last frame
# - you're not on the ground
#
# In an ideal world we could just check the cache against is_on_wall(), but
# as we well know by now, it's bugged and unreliable.
func left_wall_this_frame(p_character: PlatformerCharacter, p_is_on_wall: bool) -> bool:
	return is_on_wall_cache and not p_is_on_wall and not p_character.is_on_floor()

func update_vector(p_delta: float, p_character: PlatformerCharacter) -> void:
	frame_setup(p_delta, p_character)
	discern_state(p_delta, p_character)
	process_inputs(p_delta, p_character)
	apply_gravity(p_delta, p_character)
	finalise_update(p_delta, p_character)

## Set up some initial stuff for update_vector.
func frame_setup(p_delta: float, p_character: PlatformerCharacter):	
	# Animation stuff. This will be replaced eventually.
	is_gliding = false
	is_wallsliding = false
	is_flying = false
	
	# Do this first, to compare against cache and stuff.
	is_on_wall = stupid_wallslide_shapecast_thing(p_character) or p_character.is_on_wall()
	jumped_this_frame = false
	
	# Start coyote time if it's applicable.
	if coyote_time > 0 and not p_character.is_on_floor() and is_on_floor_cache and \
			jump_velocity >= 0:
		coyote_time_timer.start()
	
	# Start wallslide coyote time too, same deal.
	# If you can wallslide, and walljump coyote time is enabled, and we're known
	# to have left the wall this frame...
	# ...and if our jump_velocity ISN'T its maximum (i.e. we didn't leave the wall by jumping),
	# then, and only then, do we start walljump coyote time.
	if wallslide_enabled and walljump_coyote_time > 0 and left_wall_this_frame(p_character, is_on_wall) and \
			jump_velocity > initial_velocity() and jump_state != JumpState.WALLJUMP:
		walljump_coyote_time_timer.start()
#		print("[{frame}] started coyote time".format({"frame": Engine.get_frames_drawn()}))
	
	# Refresh air jumps.
	if p_character.is_on_floor():
		current_air_jumps = air_jumps

## Figure out which state we're in.
func discern_state(p_delta: float, p_character: PlatformerCharacter):
	# Bonus thing to turn off walljump coyote time.
	# This is decoupled from sliding because you can be gliding/flying against a
	# wall, which should stop coyote time despite not putting you in a wallslide
	# state.
	if wallslide_enabled and is_on_wall:
		walljump_coyote_time_timer.stop()
	
	# Flight checks!
	if flight_enabled and p_character.input_jump:
		
		# Holding down can disable flight.
		if flight_hold_down_to_disable and p_character.input_move.y > 0:
			pass
		
		# Check that flight is providing more lift than our current jump velocity.
		# If not, we're not flying!
		elif -flight_speed * grid_height > jump_velocity:
			pass
		
		else:
			#print("%s, %s" % [flight_hold_down_to_disable, p_character.input_move.y])
			jump_state = JumpState.FLY
			return
	
	# Glide checks!
	if glide_enabled and jump_velocity >= 0 and \
			not p_character.is_on_floor() and \
			p_character.input_jump:
		jump_state = JumpState.GLIDE
		return
	
	# Wallslide checks!
	if wallslide_enabled and jump_velocity >= 0 and \
			is_on_wall and not p_character.is_on_floor() and \
			signi(p_character.input_move.x) == -p_character.get_wall_normal().x:
		
		# Holding down may prevent wallslides depending on settings.
		if wallslide_hold_down_to_disable and p_character.input_move.y > 0:
			pass
		
		else:
			jump_state = JumpState.WALLSLIDE
			return
	
	if jump_velocity <= 0:
		jump_state = JumpState.JUMP
		return
	
	if p_character.is_on_floor() and jump_velocity >= 0:
		jump_state = JumpState.GROUND
		return
		
	# Otherwise we be fallin'!
	jump_state = JumpState.FALL

## Receive inputs and produce impulses based on those inputs.
func process_inputs(p_delta: float, p_character: PlatformerCharacter):
	# Check for a jump.
	if p_character.input_jump and Input.is_action_just_pressed(jump_name):
		
		# Check walljump first before regular jump.
		# Fun fact - this is_on_floor() check is required to allow jumps when you're in the corner...
		# ...but only sometimes. It was inconsistent in testing.
		# Weird!
		if wallslide_enabled and \
				(is_on_wall or \
				(walljump_coyote_time > 0 and not walljump_coyote_time_timer.is_stopped())) and \
				not p_character.is_on_floor():
			
			# Holding down can potentially override wall interactions.
			if wallslide_hold_down_to_disable and p_character.input_move.y > 0:
				#print("hold down failed")
				pass
			
			# You normally need to be moving downwards to walljump (conventions, I guess???),
			# but I've added an override since it usually feels pretty bad.
			elif not walljump_rejump_while_going_up and jump_velocity < 0:
				#print("rejump while going up failed")
				pass
			
			# Normally I intend for characters to have to hold against the wall to be able to jump
			# off it - it feels a bit weird being alongside a wall, doing a jump input with no
			# direction and getting a walljump. This also has an override.
			elif walljump_hold_in_required and not p_character.input_move.x:
				#print("hold in failed")
				pass
			
			# Special check for if you're in walljump coyote time, you're required to hold a direction
			# and it's NOT away (since walljump coyote time is for if you're jumping AWAY from a wall):
			elif walljump_coyote_time > 0 and not walljump_coyote_time_timer.is_stopped() and \
					signi(p_character.input_move.x) != p_character.get_wall_normal().x:
				#print("coyote time hold direction failed")
				pass
			
			else:
#				print(walljump_coyote_time > 0)
#				print(not walljump_coyote_time_timer.is_stopped())
#				print(signi(Input.get_axis(move_left_name, move_right_name)))
#				print(p_character.get_wall_normal().x)
#				print()
				
				walljump(p_character)
				return
		
		# Otherwise try a regular jump.
		if p_character.is_on_floor() or current_air_jumps != 0 or \
				(coyote_time > 0 and not coyote_time_timer.is_stopped()):
			
			if glide_enabled and not p_character.is_on_floor() and jump_state == JumpState.GLIDE and \
					glide_hold_down_preserves_doublejump and p_character.input_move.y > 0:
				#print("glide hold down preserve doublejump thing is enabled and holding down")
				pass
			
			# If holding up allows flight to preserve doublejumps, don't doublejump
			# if we're holding up.
			elif flight_enabled and not p_character.is_on_floor() and jump_state == JumpState.FLY and \
					flight_hold_up_preserves_doublejump and p_character.input_move.y < 0:
				#print("flight hold up preserve doublejump thing is enabled and holding up")
				pass
			
			else:
				# Hop.
				var was_coyote_jump = jump()
				
				# Otherwise subtract an air jump.
				if not was_coyote_jump and not p_character.is_on_floor():
					current_air_jumps -= 1

## Apply gravity depending on the jump state. Some states will do nothing,
## most will actually apply gravity, and others will do stuff after gravity has
## been applied.
func apply_gravity(p_delta: float, p_character: PlatformerCharacter):
	match jump_state:
		JumpState.GROUND:
			# If on the ground and not moving upwards, set velocity to 0.
			jump_velocity = 0
			
			# Also stop coyote time.
			if coyote_time > 0 and not coyote_time_timer.is_stopped():
				coyote_time_timer.stop()
			
			# And stop walljump coyote time, too.
			if walljump_coyote_time > 0 and not walljump_coyote_time_timer.is_stopped():
				walljump_coyote_time_timer.stop()
		JumpState.JUMP:
			# Maybe we need to not apply gravity on the first frame? It seems to
			# have thrown out a few jump calculations.
			if jumped_this_frame:
				return
		JumpState.WALLJUMP:
			# Same deal.
			if jumped_this_frame:
				return
	
	# Apply gravity.
	jump_velocity += gravity() * p_delta
	
	# Slow down to terminal velocity if applicable.
	if terminal_velocity > 0 and jump_velocity > terminal_velocity * grid_height:
		jump_velocity = terminal_velocity * grid_height
	
	# Then, extra stuff based on state...
	match jump_state:
		JumpState.GROUND:
			pass
		JumpState.FALL:
			pass
		JumpState.WALLSLIDE:
			# Slow down to wallslide speed if on a wall.
			jump_velocity = min(jump_velocity, wallslide_speed * grid_height)
			is_wallsliding = true
			
			# This is also really, really terrible.
			p_character.run_component.vector.x = 0
			
			if refresh_air_jumps_on_wallslide:
				current_air_jumps = air_jumps
		JumpState.GLIDE:
			# Then clamp to glide speed if glide is enabled.
			jump_velocity = min(jump_velocity, glide_fall_speed * grid_height)
			is_gliding = true
		JumpState.FLY:
			# Shitty little implementation of flight.
			jump_velocity = min(jump_velocity, -flight_speed * grid_height)
			is_flying = true

## Finally, set vector and do some cache cleanup.
func finalise_update(p_delta: float, p_character: PlatformerCharacter):
	vector.y = jump_velocity
	is_on_floor_cache = p_character.is_on_floor()
	is_on_wall_cache = is_on_wall

func reset_vector() -> void:
	super.reset_vector()
	jump_velocity = 0

# Fuckity fuck fuck, have to use stupid dumb shapecast nonsense garbage.
# Hmph.
# At least it works.
func stupid_wallslide_shapecast_thing(p_character: PlatformerCharacter) -> bool:
	if wallslide_shapecast != null:
		# I tried using p_character.safe_margin and it didn't have great detection.
		# Not sure what's up with that, but one pixel's fine. Probably.
		# Edit: Seems to need two. For some fucking reason.
		wallslide_shapecast.target_position = Vector2(-2, 0)
		wallslide_shapecast.force_shapecast_update()
		if wallslide_shapecast.get_collision_count() > 0:
			return true
		
		wallslide_shapecast.target_position = Vector2(2, 0)
		wallslide_shapecast.force_shapecast_update()
		if wallslide_shapecast.get_collision_count() > 0:
			return true
		
	return false

# Physics Calculation Notes

# pos += vel * delta + 0.5 * acc * pow(delta, 2)
	
# We'd move_and_slide() the above once the horizontal component is added in.

# new_acc = f(pos)
# vel += 0.5 * (acc + new_acc) * delta
# acc = new_acc

# ---

# pos += vel * delta + 0.5 * acc * pow(delta, 2)
# vel += acc * delta

# 100% accurate as long as acceleration is constant

# ---
