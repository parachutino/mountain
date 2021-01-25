extends KinematicBody2D
class_name Player

const FLOOR_NORMAL: = Vector2.UP

onready var state = $AnimationTree.get("parameters/playback")
onready var animation_player = $AnimationPlayer
onready var player = $player
onready var inventory = $Inventory

# NOT PUBLIC, set from Inventory
#export (String, "Nothing", "Climbing Shoes", "Ice Crampons", "Snow Rackets") onready var shoes = "Nothing" setget shoes_changed
#export (String, "Nothing", "Rain Coat", "Jumping Tool", "Parachute") onready var accesory = "Nothing" setget accesory_changed

var shoes = "Nothing" setget shoes_changed
var accesory = "Nothing" setget accesory_changed

# PRINT DEBUG MESSAGES
export var debugMode = false

# Define MAX velocidad en X y en Y...
export var speed: = Vector2(200.0, 350.0)
export var gravity: = 1000.0
export var stomp_impulse = 1000.0

export (float, 0, 1) var windResistance = 0.2
export (float, 0, 1) var rainResistance = 0.4
export (float, 0, 1) var snowResistance = 0.4

# Da inercia al movimiento (by Diego)
export var terrainAcceleration: Dictionary = {
	"air" : 0.02,
	"unknown" : 0.25,
	"grass" : 0.25,
	"stone" : 0.1,
	"ice": 0.02,
	"snow": 0.5
	}

export var terrainSpeed: Dictionary = {
	"air" : Vector2(1, 1),
	"unknown" : Vector2(1, 1),
	"grass" : Vector2(1, 1),
	"stone" : Vector2(1, 1),
	"ice": Vector2(1, 1),
	"snow": Vector2(0.5, 0.5) # jump 0.5 makes player get stuck on snow slopes....
	}


var weather: String = 'clear' setget weather_changed
var weatherSize: float = 0.0 setget weatherSize_changed
var wind: float = 0.0

var _direction: = Vector2.ZERO
var _velocity: = Vector2.ZERO
var _acceleration: float = 0.25
var _modified_speed: Vector2 = speed
var _snap
var _floor_normal

var terrain: String = "air"
var last_terrain: String = "normal"
var player_tile_position: Vector2

# Store default variables for in-game calculations... check _set_default_variables() function
var default_speed: Vector2
var default_gravity: float
var default_windResistance: float
var default_rainResistance: float
var default_snowResistance: float
var default_terrainAcceleration: Dictionary = terrainAcceleration.duplicate()
var default_terrainSpeed: Dictionary = terrainSpeed.duplicate()

# Modifiers for stats
var speed_modifier: Vector2 # DEFAULT (1, 1) : Multiplied by speed
var acceleration_modifier: float
var gravity_modifier: float # DEFAULT 1 : Multiplied by Gravity
var windResistance_modifier: float # DEFAULT 0 : Added to resistance
var rainResistance_modifier: float # DEFAULT 0 : Added to resistance
var snowResistance_modifier: float # DEFAULT 0 : Added to resistance
var terrainAcceleration_modifier: Dictionary # DEFAULT 0 : Added to terrainAcceleration
var terrainSpeed_modifier: Dictionary # DEFAULT 0 : Added to terrainSpeed

var playerSpritesNormal: Dictionary = {
	"Nothing" : preload("res://assets/climber/climber_hiking_sprite.png"),
	"Climbing Shoes" : preload("res://assets/climber/climber_climbing_sprite.png"),
	"Ice Crampons" : preload("res://assets/climber/climber_crampons_sprite.png"),
	"Snow Rackets": preload("res://assets/climber/climber_rackets_sprite.png"),
	}


func _ready():
	set_default_stats()
	calculate_stats()

func _process(delta: float) -> void:
	temp_UI()

func _physics_process(_delta: float) -> void:
		
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0 # Interrupts jump if button released

	_direction = get_direction() # Gets input from keyboard / joystick
	
	get_tile_type()
	
	_floor_normal = get_floor_normal()
	
	recalculate_all()
	
	# Calcula la velocidad de movimiento del KinematicBody2D y la asigna a la variable _velocity
	_velocity = calculate_move_velocity(_velocity, _direction, _modified_speed, is_jump_interrupted)

#	var snap_vector = Vector2(0,5) if is_on_floor() and (_direction.y != 0 or terrain != "air") else Vector2(0,0)
	var snap_vector = Vector2(0,5) if is_on_floor() and check_snap() else Vector2(0,0)
	
	# Hace moverse el "KinematicBody2D" con lógica de plataformas (colision con plataformas) usando la _velocity calculada anteriormente
	# IMPORTANTE: Se redefine la "_velocity" anulando la gravedad si esta sobre una plataforma...
	# Se podria usar solo el metodo move_and_slide, pero al llegar al fin de una plataforma caeria bruscamente.

	_velocity = move_and_slide_with_snap(_velocity, snap_vector, FLOOR_NORMAL,
								true, # Stop on Slope
								2, # Max Slides
								PI/2.5, # Slope Angle... standard = PI/4
								false # No Infinite Inertia (for correct interaction with RigidBody2D)
								)
#
#	_velocity = move_and_slide(_velocity, FLOOR_NORMAL,
#								false, # Stop on Slope
#								4, # Max Slides
#								PI/2.1, # Slope Angle... standard = PI/4
#								false # No Infinite Inertia (for correct interaction with RigidBody2D)
#								)

	state_machine() #APPLY STATE ANIMATION

func check_snap():
	
		# SNAPS ONLY IF GOING UP ON SLOPE
	if abs(player.scale.x + _floor_normal.x ) < 0.5 and abs(player.scale.x + _floor_normal.x ) > 0.1 and not Input.is_action_pressed("jump"):
		return true
	else:
		return false

func state_machine():
	
	if _direction.x > 0: player.scale.x = 1
	elif _direction.x < 0: player.scale.x = -1
	
	if is_on_floor():
		if _direction.x == 0:
			state.travel("idle")
			# SEEDS HAT ANIMATION WHEN IDLE ACCORDING TO WIND
			var animation_speed = 2 + 6 * abs(wind)
			$AnimationTree.set("parameters/idle/TimeScale/scale", animation_speed)
		else:
			# Set Run Animation Speed based on velocity (average with 1 to avoid extreme speeds)
			var animation_speed = (abs(_velocity.x / speed.x) + 1) / 2
			$AnimationTree.set("parameters/run/TimeScale/scale", animation_speed)
			# print_debug("Animation Speed: ", animation_speed)
			
			state.travel("run")

		
	else:
		if terrain == "air":
			state.travel("fall")
	
	if _direction.y == -1:
		state.travel("jump")

func change_sprite(shoes, accesory):
	
	player.set_texture(playerSpritesNormal[shoes])

func recalculate_all():
	calculate_stats()
	_acceleration = set_acceleration() # Defines aceleration based on terrain
	_modified_speed = calculate_modified_speed()

func temp_UI(): # UI TEMPORANEA CON TASTIERA E JOYSTICK
	
	# KEYBOARD 1234 5678
	if Input.is_action_just_pressed("select_shoes_0"): inventory.shoes = inventory.shoesInventory[0]
	if Input.is_action_just_pressed("select_shoes_1"): inventory.shoes = inventory.shoesInventory[1]
	if Input.is_action_just_pressed("select_shoes_2"): inventory.shoes = inventory.shoesInventory[2]
	if Input.is_action_just_pressed("select_shoes_3"): inventory.shoes = inventory.shoesInventory[3]
	if Input.is_action_just_pressed("select_accesory_0"): inventory.accesory = inventory.accesoryInventory[0]
	if Input.is_action_just_pressed("select_accesory_1"): inventory.accesory = inventory.accesoryInventory[1]
	if Input.is_action_just_pressed("select_accesory_2"): inventory.accesory = inventory.accesoryInventory[2]
	if Input.is_action_just_pressed("select_accesory_3"): inventory.accesory = inventory.accesoryInventory[3]


"""STATS FUNCTIONS"""
func set_default_stats():
	# Store stats default values from public variables
	default_speed = speed
	default_gravity = gravity
	default_windResistance = windResistance
	default_rainResistance = rainResistance
	default_snowResistance = snowResistance
	default_terrainAcceleration = terrainAcceleration.duplicate()
	default_terrainSpeed = terrainSpeed.duplicate()
	terrainAcceleration_modifier = terrainAcceleration.duplicate()
	terrainSpeed_modifier = terrainSpeed.duplicate()
	
	if debugMode: print_debug("Set default stats")


func reset_stats():
	
	# RESET Main
	speed = default_speed
	gravity = default_gravity
	windResistance = default_windResistance
	rainResistance = default_rainResistance
	snowResistance = default_snowResistance
	
	# RESET Terrain Stats
	for type in terrainAcceleration:
		terrainAcceleration[type] = default_terrainAcceleration[type]
	for type in terrainSpeed:
		terrainSpeed[type] = default_terrainSpeed[type]
	
	if debugMode: print_debug("Resetted stats")

func reset_modifiers():
	# RESET Main Modifiers
	speed_modifier = Vector2(1, 1) # DEFAULT (1, 1)
	gravity_modifier = 1.0 # DEFAULT 1
	acceleration_modifier = 1 # DEFAULT 1
	windResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.3)
	rainResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.5)
	snowResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.5)
	
	# RESET Terrain Modifiers
	for modifier in terrainAcceleration_modifier:
		terrainAcceleration_modifier[modifier] = 0.0 # DEFAULT 0
	for modifier in terrainSpeed_modifier:
		terrainSpeed_modifier[modifier] = Vector2(0, 0) # DEFAULT (0, 0)

	if debugMode: print_debug("Resetted modifiers")


func get_modifiers():
	reset_modifiers()
	speed_modifier = speed_modifier * inventory.item[shoes].speed_modifier * inventory.item[accesory].speed_modifier # DEFAULT (1, 1)
	gravity_modifier = gravity_modifier * inventory.item[shoes].gravity_modifier * inventory.item[accesory].gravity_modifier # DEFAULT 1
	acceleration_modifier = acceleration_modifier * inventory.item[shoes].acceleration_modifier * inventory.item[accesory].acceleration_modifier
	windResistance_modifier += inventory.item[shoes].windResistance_modifier + inventory.item[accesory].windResistance_modifier # DEFAULT 0 (Default resistance: 0.3)
	rainResistance_modifier += inventory.item[shoes].rainResistance_modifier + inventory.item[accesory].rainResistance_modifier # DEFAULT 0 (Default resistance: 0.5)
	snowResistance_modifier += inventory.item[shoes].snowResistance_modifier + inventory.item[accesory].snowResistance_modifier# DEFAULT 0 (Default resistance: 0.5)

	# Get Terrain Modifiers
	for modifier in terrainAcceleration_modifier:
		terrainAcceleration_modifier[modifier] = inventory.item[shoes].terrainAcceleration_modifier[modifier] + inventory.item[accesory].terrainAcceleration_modifier[modifier] # DEFAULT 0
	for modifier in terrainSpeed_modifier:
		terrainSpeed_modifier[modifier] = inventory.item[shoes].terrainSpeed_modifier[modifier] + inventory.item[accesory].terrainSpeed_modifier[modifier] # DEFAULT (0, 0)
	
	if debugMode: print_debug("Got modifiers for: ", inventory.item[shoes].name," & ",inventory.item[accesory].name, " equips.")

func calculate_stats():

	get_modifiers() # IS THIS NECESSARY???
	
	# SPEED:
	speed = default_speed * speed_modifier
	# GRAVITY:
	gravity = default_gravity * gravity_modifier

	# WIND RESISTANCE:
	windResistance = default_windResistance + windResistance_modifier
	# ADD WIND RESISTANCE BASED ON TERRAIN ACCELERATION
	windResistance += (terrainAcceleration[terrain] + terrainAcceleration_modifier[terrain]) * acceleration_modifier
	if windResistance < 0: windResistance = 0 # LOW LIMIT
	elif windResistance > 1: windResistance = 1 # HIGH LIMIT
	if debugMode: print_debug("Wind Reistance: ",windResistance)
	
	# RAIN RESISTANCE:
	rainResistance = default_rainResistance + rainResistance_modifier
	if rainResistance < 0: rainResistance = 0 # LOW LIMIT
	elif rainResistance > 1: rainResistance = 1 # HIGH LIMIT
	if debugMode: print_debug("Rain Reistance: ",rainResistance)
	
	# SNOW RESISTANCE:
	snowResistance = default_snowResistance + snowResistance_modifier
	if snowResistance < 0: snowResistance = 0 # LOW LIMIT
	elif snowResistance > 1: snowResistance = 1 # HIGH LIMIT


	if debugMode: print_debug("Calculated stats...")

"""MOVEMENT FUNCTIONS"""

func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		spd: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
		
	var new_velocity: = linear_velocity
	var floor_normal = get_floor_normal()
	
	# DEFAULT FORMULA
	# new_velocity.x = spd.x * direction.x 
	# TERRAIN ANGLE AFFECTS SPEED
	# new_velocity.x = spd.x * (direction.x + floor_normal.x/2)
	# TERRAIN ANGLE AND ACCELERATION AFFECT SPEED X)
#	new_velocity.x = spd.x * (direction.x + floor_normal.x * 0.5 - floor_normal.x * _acceleration) # TERRAIN ANGLE AFFECTS SPEED
	# TERRAIN ANGLE AND ACCELERATION ONLY WHILE GOING UP IN SLOPES
#	if abs(direction.x + floor_normal.x ) < 0.5: new_velocity.x = spd.x * (direction.x + floor_normal.x * 0.5 - floor_normal.x * _acceleration) # TERRAIN ANGLE AFFECTS SPEED
#	if abs(direction.x + floor_normal.x ) < 0.5 and abs(direction.x + floor_normal.x ) > 0:
	if abs(direction.x) - abs(floor_normal.x ) < 0.5 and abs(direction.x) - abs(floor_normal.x ) > 0:
		new_velocity.x = spd.x * (direction.x + floor_normal.x * 0.5 - floor_normal.x * _acceleration) # TERRAIN ANGLE AFFECTS SPEED
	else:
		new_velocity.x = spd.x * direction.x#	
#	print_debug("Speed * (", direction.x, " + ", floor_normal.x * 0.5, " - ", floor_normal.x * _acceleration,")")
#	print_debug("Dir: ",direction, "Normal: ", floor_normal)
	
	# WIND
	if (abs(wind) - windResistance) > 0:
		new_velocity.x += speed.x * (wind - (wind/abs(wind) * windResistance))
	"""---------"""
	
	# ACCELERATION: Gradually accelerate / brake
	new_velocity.x = linear_velocity.x + (new_velocity.x - linear_velocity.x) * _acceleration
 

	# JUMP (IMPORTANT: DELTA) 
	
	# DEFAULT GRAVITY FORMULA
	# new_velocity.y += gravity * get_physics_process_delta_time() 

	
	if is_on_floor():
		# TERRAIN ACCELERATION FORMULA: REDUCES GRAVITY EFFECT ON SLOPES
#		new_velocity.y += gravity * get_physics_process_delta_time()
		new_velocity.y += gravity * (1 - 2 * _acceleration) * get_physics_process_delta_time()

#		print_debug(1 - 2 * _acceleration)
		
	else:
		# ADDS GRAVITY MODIFIER while falling only:
		if new_velocity.y + gravity * gravity_modifier * get_physics_process_delta_time() > 0:
			new_velocity.y += gravity * gravity_modifier * get_physics_process_delta_time()

		else:
			# DEFAULT (NO TERRAIN ACCELERATION FORMULA)... Used only on air
			new_velocity.y += gravity * get_physics_process_delta_time()
		# end TERRAIN ACCELERATION FORMULA


	if direction.y == -1.0:
		# new_velocity.y = spd.y * direction.y # (ORIGINAL, no floor normal...)
#		new_velocity.y = spd.y * floor_normal.y # Apply floor normal to jump
#		new_velocity.y = spd.y * (floor_normal.y - (1 + floor_normal.y) * _acceleration) # Apply floor normal to jump
		new_velocity.y = spd.y * (floor_normal.y - (1 + floor_normal.y) * 2 * _acceleration) # Apply floor normal to jump
#		print_debug("Jump Modifier = ", 1 * (floor_normal.y - (1 + floor_normal.y) * 2 * _acceleration))
#		print_debug("Acceleration = ", _acceleration)
		
		"""JUMP gets more impulse or less penalty in X from FLOOR NORMAL depending on floor acceleration"""
		# print_debug("Velocidad: ",new_velocity.x)
		new_velocity.x += spd.x * floor_normal.x * -direction.x * _acceleration
		# print_debug(100, " + ", 100 * floor_normal.x * -direction.x * _acceleration)
		# print_debug(new_velocity.x, " + ", spd.x * floor_normal.x * -direction.x * _acceleration)
		# print_debug("Floor Normal: ",floor_normal)
		# print_debug("Salto: ",new_velocity.x)
		"""..."""

	if is_jump_interrupted:
		new_velocity.y = sqrt(spd.y)

	return new_velocity


func get_direction() -> Vector2:
	var dir = Vector2(	
		# La dirección en X será 1 si aprieta derecha y -1 si aprieta izquierda
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0
		)
	
	# DEBUG JUMP
	# if Input.is_action_just_pressed("jump") and not is_on_floor(): print_debug("NOT ON FLOOR!!")
	
	return dir


func set_acceleration():
	
	var accel = (terrainAcceleration[terrain] + terrainAcceleration_modifier[terrain]) * acceleration_modifier
	
	# SLIDE MORE ON SLOPES...
	if abs(_floor_normal.y) > 0:
		accel = accel * abs(_floor_normal.y)
	
	# RAIN AFFECTS ACCELERATION
	if weather == "rain":
		accel = accel * (1 - weatherSize * (1 - rainResistance))
	
	# IF SNOWING AND SNOW RACKETS, Adds acceleration
	if weather == "snow" and shoes == "Snow Rackets" and terrain != "air":
		accel = accel + 0.25 * weatherSize
		if debugMode: print_debug("RACKETS ACCELERATION")
	
	if accel > 0.5: accel = 0.5 # HIGH LIMIT
	elif accel <= 0: accel = 0.005 # LOW LIMIT
	
	if debugMode: print_debug("Set Acceleration: ", accel)
	
	return accel


func calculate_modified_speed():
	var last_speed = _modified_speed #DEBUG SPEED
	var new_speed = last_speed
	
	# APPLY SPEED MODIFIER
	# print_debug("Terrain Speed: ", terrainSpeed[terrain], " Terrain Speed Modifier: ", terrainSpeed_modifier[terrain])
	# print_debug("Terrain: ",terrain, " / Final Modifier: ", terrainSpeed[terrain] + terrainSpeed_modifier[terrain])
	new_speed = speed * (terrainSpeed[terrain] + terrainSpeed_modifier[terrain])
	
	#print_debug(new_speed)
	
	# SNOW WEATHER SPEED MODIFIER
	if weather == "snow":
		
		# SNOW RACKETS: Normalize speed depending on snow size (Size 1 = Normal)
		if shoes == "Snow Rackets": 
			if terrain == "snow" or terrain == "air":
				pass
			else:
				new_speed.x = speed.x * (0.5 + 0.5 * weatherSize)
				if debugMode: print_debug("RACKETS SPEED")
		
		else:
			new_speed.x = new_speed.x * (1 - weatherSize * (1 - snowResistance))
			if debugMode: print_debug("Speed X: ", new_speed.x, " * (1 - weatherSize ", weatherSize, " * (1 - snowResistance)", snowResistance, "): = ", _modified_speed.x)
		
		
	if debugMode: print_debug("Speed: ", speed, " / Modified Speed: ", new_speed)
	
#	print_debug("Speed: ", speed, " / Modified Speed: ", _modified_speed)

	return new_speed


func get_tile_type(): #sets terrain variable and returns tile_type
	var current_tile
	
	last_terrain = terrain
	
	if is_on_floor():
#		var collision = get_slide_collision(0) if get_slide_count() > 0 else null # FIRST COLLISION
		var collision = get_slide_collision(get_slide_count()-1) if get_slide_count() > 0 else null # LAST COLLISION
		if collision and collision.collider is TileMap:
			# Find the character's position in tile coordinates
			var tile_pos = collision.collider.world_to_map(position)
			#tile_pos -= collision.normal # Find the colliding tile position
			var tile_id = collision.collider.get_cellv(tile_pos) # Get the tile id
			if not tile_id == TileMap.INVALID_CELL:
				current_tile = collision.collider.tile_set.tile_get_name(tile_id)
				if not current_tile in terrainAcceleration:
					current_tile = "unknown"
				
			else: current_tile = terrain
			
			if tile_pos != player_tile_position:
				player_tile_position = tile_pos
				if current_tile == "unknown": #DEBUG ERROR if Tile is unknown
					print_debug("Unknown tile type. Check tile name in scene's TileMap and terrainAcceleration Dictionary in Player")
				# DEBUG tile position and type
				#print_debug("Player tile: ", tile_pos, " / Tile type: ", current_tile)
				#print_debug(_acceleration)
				#print_debug(_modified_speed)
				
	else: current_tile = "air" # Acceleration on air
	
	if not current_tile: current_tile = "unknown"
	terrain = current_tile
	return current_tile


# Calculates jump velocity
func calculate_stomp_velocity(linear_velocity: Vector2, impulse: float) -> Vector2:
	var out: = 	linear_velocity
	out.y = -impulse
	return out

# Player dies
func die() -> void:
	queue_free()
	PlayerData.deaths += 1


"""SETGET FUNCTIONS"""
func weather_changed(new_weather):
	weather = new_weather
	recalculate_all()
	
	if debugMode: print_debug(weather, " speed")


func weatherSize_changed(new_weatherSize):
	weatherSize = new_weatherSize
	recalculate_all()
	
	if debugMode: print_debug("Weather size: ", weatherSize, " speed")


func shoes_changed(new_shoes):
#	yield(inventory, "ready")
	if shoes:
		shoes = new_shoes
		recalculate_all()
		
		if debugMode: print_debug(inventory.item[shoes].name, " equipped. ", inventory.item[shoes].description)
		if debugMode: print_debug(shoes, " speed")
		
	else:
		shoes = "Nothing"
		
		if debugMode: print_debug("No shoes equipped")
	
	change_sprite(new_shoes, accesory)

func accesory_changed(new_accesory):
#	yield(inventory, "ready")
	if accesory:
		accesory = new_accesory
		recalculate_all()
		
		if debugMode: print_debug(inventory.item[accesory].name, " equipped. ", inventory.item[accesory].description)
		if debugMode: print_debug(accesory, " speed")
	
	else:
		accesory = "Nothing"
	
		if debugMode: print_debug("No accesory equipped")



"""SIGNAL FUNCTIONS"""
# Hace saltar al Player cuando un AREA2D entra en la zona especificada
func _on_EnemyDetector_area_entered(_area: Area2D) -> void:
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)

# Mata al Player cuando un BODY entra en la zona especificada
func _on_EnemyDetector_body_entered(_body):
	# Mata al player
	die()
