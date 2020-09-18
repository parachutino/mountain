extends "res://src/Actors/Actor.gd"

export var score: int = 100

func _ready() -> void:
	# Desactiva el "Physics Process" al inicio, para no hacerlo calcular ni moverse si el "Enemy" no está visible
	set_physics_process(false)
		
	# Inicializa el movimiento del "Enemy" hacia la izquierda
	_velocity.x = -speed.x


func _physics_process(delta: float) -> void:
		
		# Hace que el "Enemy" caiga con la gravedad
		_velocity.y += gravity * delta
		
		# Invierte el movimiento en X cuando choca con un muro
		if is_on_wall():
			_velocity.x *= -1.0
			
		# Hace moverse al "Enemy" en base alla "Velocity" con la lógica de Slide (plataformas)
			# Modifica la Y del vector de velocidad en base a la lógica de move_and_slide, anulandola si está sobre una plataforma.
			
		_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y


func _on_StompDetector_body_entered(body: Node) -> void:
	# Se asegura que el "Player" no llegue desde abajo
	# get_node hace referencia a un nodo externo en la escena!!
	if body.global_position.y > get_node("StompDetector").global_position.y:
		return
	# Desactiva la colision antes de desaparecer para no desviar al "Player"
	get_node("CollisionShape2D").disabled = true
	# Hace desaparecer el "Enemy"
	die()


# Funcion de cuando muere el Enemy
func die() -> void:
	PlayerData.score += score
	queue_free()

