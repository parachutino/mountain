extends KinematicBody2D
class_name Player

const FLOOR_NORMAL: = Vector2.UP

# Define MAX velocidad en X y en Y...
export var speed: = Vector2(200.0, 350.0)
export var gravity: = 1000.0
export var stomp_impulse = 1000.0

# Da inercia al movimiento (by Diego)
export var terrainAcceleration = {
	"air" : 0.05,
	"unknown" : 0.25,
	"grass" : 0.25,
	"stone" : 0.1,
	"ice": 0.02
	}

export (float, 0, 1) var windResistance = 0.3
export (float, 0, 1) var rainResistance = 0.5
export (float, 0, 1) var snowResistance = 0.5

var weather = 'clear' setget weather_changed
var weatherSize: float = 0 setget weatherSize_changed
var wind: float = 0

var _velocity: = Vector2.ZERO
var _acceleration: = 0.25
var modified_speed: Vector2 = speed

var terrain = ""
var last_terrain = "normal"
var player_tile_position: Vector2

var state_machine
var player

func _ready():
	state_machine = $AnimationTree.get("parameters/playback")
	player = $player

# Hace saltar al Player cuando un AREA2D entra en la zona especificada
func _on_EnemyDetector_area_entered(_area: Area2D) -> void:
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)
	
# Mata al Player cuando un BODY entra en la zona especificada
func _on_EnemyDetector_body_entered(_body):
	# Mata al player
	die()
	
func weather_changed(new_weather):
	weather = new_weather
	calculate_modified_speed()
	
func weatherSize_changed(new_weatherSize):
	weatherSize = new_weatherSize
	calculate_modified_speed()

# Esta funcion se ejecuta y ejecuta la misma funcion del padre una vez por physic frame....
func _physics_process(_delta: float) -> void:
		
		

	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0 # Interrupts jump if button released
	var direction: = get_direction() # Gets input from keyboard / joystick
	_acceleration = set_acceleration() # Defines aceleration based on terrain
	
	# Calcula la velocidad de movimiento del KinematicBody2D y la asigna a la variable _velocity
	_velocity = calculate_move_velocity(_velocity, direction, modified_speed, is_jump_interrupted)
	
	# Hace moverse el "KinematicBody2D" con lógica de plataformas (colision con plataformas) usando la _velocity calculada anteriormente
		# IMPORTANTE: Se redefine la "_velocity" anulando la gravedad si esta sobre una plataforma...
		# Se podria usar solo el metodo move_and_slide, pero al llegar al fin de una plataforma caeria bruscamente.
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL,
								false, 4,
								PI/3, # Slope Angle... standard = PI/4
								false # No Infinite Inertia (for correct interaction with RigidBody2D)
								)



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
	
	# TERRAIN ANGLE AFFECTS ACCELERATION
	# accel = accel * (1 + get_floor_normal().x) # NO!!
	
	# RAIN AFFECTS ACCELERATION
	if weather == "rain":
		accel = accel * (1 - weatherSize * rainResistance)
	

	return accel



func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		spd: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
		
	var new_velocity: = linear_velocity
	new_velocity.x = spd.x * direction.x
	
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
		new_velocity.y = spd.y * get_floor_normal().y # Apply floor normal to jump
		new_velocity.x = new_velocity.x + spd.x * get_floor_normal().x # Apply floor normal to jump in x
	
	if is_jump_interrupted:
		new_velocity.y = sqrt(spd.y)
	

	return new_velocity


func calculate_modified_speed():
	if weather == "snow":
		# print_debug("Speed X: ", speed.x, " * (1 - weatherSize ", weatherSize, " * snowResistance: ", snowResistance)
		modified_speed.x = speed.x * (1 - weatherSize * snowResistance)
	else: modified_speed.x = speed.x
	# print_debug("Speed: ", speed, " / Modified Speed: ", modified_speed)
	
	# TERRAIN ANGLE AFFECTS X.SPEED
	modified_speed.x = modified_speed.x + gravity * get_floor_normal().x

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

