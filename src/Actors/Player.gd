extends KinematicBody2D
class_name Player

const FLOOR_NORMAL: = Vector2.UP

# Define MAX velocidad en X y en Y...
export var speed: = Vector2(200.0, 350.0)
export var gravity: = 1000.0
export var stomp_impulse = 1000.0

# Da inercia al movimiento (by Diego)
export var terrainAcceleration = {
	"air" : 0.02,
	"unknown" : 0.25,
	"grass" : 0.25,
	"stone" : 0.1,
	"ice": 0.02,
	"snow": 0.5
	}

var terrainSpeed = {
	"air" : Vector2(1, 1),
	"unknown" : Vector2(1, 1),
	"grass" : Vector2(1, 1),
	"stone" : Vector2(1, 1),
	"ice": Vector2(1, 1),
	"snow": Vector2(0.5, 0.5)
	}

export (float, 0, 1) var windResistance = 0.3
export (float, 0, 1) var rainResistance = 0.5
export (float, 0, 1) var snowResistance = 0.5

var weather = 'clear' setget weather_changed
var weatherSize: float = 0 setget weatherSize_changed
var wind: float = 0

var _velocity: = Vector2.ZERO
var _acceleration: = 0.25
var _modified_speed: Vector2 = speed

var terrain = ""
var last_terrain = "normal"
var player_tile_position: Vector2

var state_machine
var player

# Store default variables for in-game calculations... check _set_default_variables() function
var default_speed
var default_gravity
var default_terrainAcceleration
var default_terrainSpeed
var default_windResistance
var default_rainResistance
var default_snowResistance

# Modifiers for stats
var speed_modifier = Vector2(1, 1) # DEFAULT 1
var gravity_modifier = 1.0 # DEFAULT 1
var terrainAcceleration_modifier: Dictionary
var terrainSpeed_modifier: Dictionary
var windResistance_modifier = 0.0 # DEFAULT 0
var rainResistance_modifier = 0.0 # DEFAULT 0
var snowResistance_modifier = 0.0 # DEFAULT 0


func _ready():
	state_machine = $AnimationTree.get("parameters/playback")
	player = $player
	_set_default_stats()
	recalculate_stats()


func _set_default_stats():
	
	# Store default values from Public variables
	default_speed = speed
	default_gravity = gravity
	default_terrainAcceleration = terrainAcceleration.duplicate()
	default_terrainSpeed = terrainSpeed.duplicate()
	default_windResistance = windResistance
	default_rainResistance = rainResistance
	default_snowResistance = snowResistance
	
	# Create terrain speed and acceleration modifiers
	terrainAcceleration_modifier = terrainAcceleration.duplicate()
	terrainSpeed_modifier = terrainSpeed.duplicate()
	
	for modifier in terrainAcceleration_modifier:
		modifier = 0.0
	
	for modifier in terrainSpeed_modifier:
		modifier = 0.0


func recalculate_stats():
	print_debug("Recalculating stats...")
	# SPEED:
	speed = default_speed * speed_modifier
	# GRAVITY:
	gravity = default_gravity * gravity_modifier
	# TERRAIN ACCELERATION:

	for acceleration_modifier in terrainAcceleration:
		terrainAcceleration[acceleration_modifier] = default_terrainAcceleration[acceleration_modifier] + terrainAcceleration_modifier[acceleration_modifier]
		print_debug(default_terrainAcceleration[acceleration_modifier], terrainAcceleration_modifier[acceleration_modifier])
	# TERRAIN SPEED:
	for speed_modifier in terrainSpeed:
		terrainSpeed[speed_modifier] = default_terrainSpeed[speed_modifier] + terrainSpeed_modifier[speed_modifier]
	# WIND RESISTANCE:
	windResistance = default_windResistance + windResistance_modifier
	# RAIN RESISTANCE:
	rainResistance = default_windResistance + windResistance_modifier
	# SNOW RESISTANCE:
	snowResistance = default_snowResistance + snowResistance_modifier
	

# Hace saltar al Player cuando un AREA2D entra en la zona especificada
func _on_EnemyDetector_area_entered(_area: Area2D) -> void:
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)
	
# Mata al Player cuando un BODY entra en la zona especificada
func _on_EnemyDetector_body_entered(_body):
	# Mata al player
	die()
	
func weather_changed(new_weather):
	weather = new_weather
	_modified_speed = calculate_modified_speed()
	
func weatherSize_changed(new_weatherSize):
	weatherSize = new_weatherSize
	_modified_speed = calculate_modified_speed()

# Esta funcion se ejecuta y ejecuta la misma funcion del padre una vez por physic frame....
func _physics_process(_delta: float) -> void:
		
		

	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0 # Interrupts jump if button released
	var direction: = get_direction() # Gets input from keyboard / joystick
	_acceleration = set_acceleration() # Defines aceleration based on terrain
	
	# Calcula la velocidad de movimiento del KinematicBody2D y la asigna a la variable _velocity
	_velocity = calculate_move_velocity(_velocity, direction, _modified_speed, is_jump_interrupted)
	
	# Hace moverse el "KinematicBody2D" con lógica de plataformas (colision con plataformas) usando la _velocity calculada anteriormente
		# IMPORTANTE: Se redefine la "_velocity" anulando la gravedad si esta sobre una plataforma...
		# Se podria usar solo el metodo move_and_slide, pero al llegar al fin de una plataforma caeria bruscamente.
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL,
								false, 4,
								1.3, # Slope Angle... standard = PI/4
								false # No Infinite Inertia (for correct interaction with RigidBody2D)
								)


func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		spd: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
		
	var new_velocity: = linear_velocity
	var floor_normal = get_floor_normal()
	
	# new_velocity.x = spd.x * direction.x
	new_velocity.x = spd.x * (direction.x + floor_normal.x/2) # TERRAIN ANGLE AFFECTS SPEED
	
	"""EASY WIND"""
	if (abs(wind) - windResistance) > 0:
		new_velocity.x += spd.x * (wind - (wind/abs(wind) * windResistance))
	"""---------"""
	
	# ACCEL v3.0 vBY DIEGO Aplica una "aceleración" proporcional al cambio de velocidad... Variable publica: -> _acceleration = 0.05 aconsejado
	new_velocity.x = linear_velocity.x + (new_velocity.x - linear_velocity.x) * _acceleration
	
	"""TRUE WIND... TOO STRONG (REPLACED WITH EASY WIND)"""
	# if (wind - windResistance) > 0: new_velocity.x += speed.x * (wind - windResistance)
	"""-----------------------"""
 
	# SALTO (IMPORTANTE: DELTA) 
	new_velocity.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		# new_velocity.y = spd.y * direction.y # (ORIGINAL, no floor normal...)
		new_velocity.y = spd.y * floor_normal.y # Apply floor normal to jump
		
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
	
	if dir.x > 0: player.scale.x = -1
	elif dir.x < 0: player.scale.x = 1

	if is_on_floor():
		if dir.x == 0: state_machine.travel("idle")
		else: state_machine.travel("run")
	
	else: state_machine.travel("run")

	return dir


func set_acceleration():
	
	var accel = terrainAcceleration[get_tile_type()]
	
	# RAIN AFFECTS ACCELERATION
	if weather == "rain":
		accel = accel * (1 - weatherSize * rainResistance)
	

	return accel


func calculate_modified_speed():
	var last_speed = _modified_speed #DEBUG SPEED
	var new_speed = last_speed
	
	if weather == "snow":
		# print_debug("Speed X: ", speed.x, " * (1 - weatherSize ", weatherSize, " * snowResistance: ", snowResistance)
		new_speed.x = speed.x * (1 - weatherSize * snowResistance)
	else: new_speed.x = speed.x
	# print_debug("Speed: ", speed, " / Modified Speed: ", _modified_speed)

	return new_speed


func get_tile_type(): #sets terrain variable and returns tile_type
	var current_tile
	if is_on_floor():
		var collision = get_slide_collision(0)
		if collision.collider is TileMap:
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
				# print_debug("Player tile: ", tile_pos, " / Tile type: ", current_tile)
				
	else: current_tile = "air" # Acceleration on air
	
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

