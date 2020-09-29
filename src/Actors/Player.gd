extends Actor

export var stomp_impulse = 1000.0

# Da inercia al movimiento (by Diego)
export var acceleration: = 0.05

var terrain = ""

# Hace saltar al Player cuando un AREA2D entra en la zona especificada
func _on_EnemyDetector_area_entered(area: Area2D) -> void:
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)
	
# Mata al Player cuando un BODY entra en la zona especificada
func _on_EnemyDetector_body_entered(body):
	# Mata al player
	die()

func _on_GroundDetector_body_entered(body: Node) -> void:
	pass
"""
	# Confirm the colliding body is a TileMap
	print_debug(body)
	if body is TileMap:
		print_debug("BODY: "+str(body))
		# Find the character's position in tile coordinates
		var tile_pos = body.world_to_map(position)
		# Find the colliding tile position
		tile_pos += (Vector2.DOWN)
		print_debug("Position:" + str(position) + "/ Tile Position: "+ str(tile_pos))
		# Get the tile id
		#var tile_id = body.get_cellv(Vector2(0,16))
		var tile_id = body.get_cellv(tile_pos)
		print_debug("Tile"+str(tile_id))
		terrain = body.tile_set.tile_get_name(tile_id)
		print_debug(terrain)
	"""

# Esta funcion se ejecuta y ejecuta la misma funcion del padre una vez por physic frame....
func _physics_process(delta: float) -> void:
		
		
	# Variable para hacer el salto mas corto si se suelta el boton...
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0
	var direction: = get_direction()
	#acceleration = set_acceleration(terrain)
	# Calcula la velocidad de movimiento del KinematicBody2D y la asigna a la variable _velocity
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)
	
	# Hace moverse el "KinematicBody2D" con lógica de plataformas (colision con plataformas) usando la _velocity calculada anteriormente
		# IMPORTANTE: Se redefine la "_velocity" anulando la gravedad si esta sobre una plataforma...
		# Se podria usar solo el metodo move_and_slide, pero al llegar al fin de una plataforma caeria brucamente.
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	acceleration = set_acceleration()


func get_direction() -> Vector2:
	return Vector2(	
		# La dirección en X será 1 si aprieta derecha y -1 si aprieta izquierda
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0
		)

func set_acceleration():
	if is_on_floor():
		
		var collision = get_slide_collision(0)
		if collision.collider is TileMap:
			# Find the character's position in tile coordinates
			var tile_pos = collision.collider.world_to_map(position)
			# Find the colliding tile position
			#tile_pos -= collision.normal
			#print_debug(tile_pos)
			var tile_id = collision.collider.get_cellv(tile_pos) # Get the tile id
			if not tile_id == TileMap.INVALID_CELL:
				terrain = collision.collider.tile_set.tile_get_name(tile_id)
			#print_debug(tile_id)
			#print_debug(terrain)
	
	else: return 0.05 # Acceleration on air
	if terrain == "grass": return 0.5 # Acceleration on grass
	elif terrain == "stone": return 0.1 # Acceleration on stone
	elif terrain == "ice": return 0.02 # Acceleration on ice
	else:
		return 0.5
		print_debug(terrain)

	
func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		speed: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var new_velocity: = linear_velocity
	new_velocity.x = speed.x * direction.x
	
	# ACCEL v3.0 vBY DIEGO Aplica una "aceleración" proporcional al cambio de velocidad... Variable publica: -> acceleration = 0.05 aconsejado
	new_velocity.x = linear_velocity.x + (new_velocity.x - linear_velocity.x) * acceleration
	
#	# ACCEL v.2.0 BY DIEGO Aplica una "aceleración" lineal en proporción a la velocidad máxima... Variable publica: -> acceleration = 0.05 aconsejado
#	if linear_velocity.x - new_velocity.x > acceleration:
#		new_velocity.x = (linear_velocity.x - speed.x * acceleration)
#	elif new_velocity.x - linear_velocity.x > speed.x * acceleration:
#		new_velocity.x = (linear_velocity.x + speed.x * acceleration)	
	
#	# ACCEL v1.0 BY DIEGO Aplica una "aceleración" lineal predefinida... Variable publica: -> acceleration = 50 aconsejado
#	if linear_velocity.x - new_velocity.x > acceleration:
#		new_velocity.x = (linear_velocity.x - acceleration)
#	elif new_velocity.x - linear_velocity.x > acceleration:
#		new_velocity.x = (linear_velocity.x + acceleration)
	
	# DELTA sirve para mantener constante fuera del 
	new_velocity.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		new_velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		new_velocity.y = sqrt(speed.y)
	return new_velocity
		

# Calcula la velocidad del salto
func calculate_stomp_velocity(linear_velocity: Vector2, impulse: float) -> Vector2:
	var out: = 	linear_velocity
	out.y = -impulse
	return out

# Funcion de cuando muere el Player
func die() -> void:
	queue_free()
	PlayerData.deaths += 1
	
	
#	# Indica que el MAX de "_velocity.y" es = "speed.y"
#	_velocity.y = max(_velocity.y, speed.y)

