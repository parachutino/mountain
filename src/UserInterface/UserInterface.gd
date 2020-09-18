extends Control

onready var scene_tree: = get_tree()
onready var pause_overlay: ColorRect = $PauseOverlay
onready var score: Label = get_node("Label")
onready var pause_title: Label = get_node("PauseOverlay/Title")

var paused: = false setget set_paused
var player_is_dead: bool = false


func _ready() -> void:
	#CONNECT conecta la señal "Score Updated" con la funcion "update_interface" en el target object SELF
	PlayerData.connect("score_updated", self, "update_interface")
	PlayerData.connect("player_died", self, "_on_PlayerData_player_died")
	update_interface()


func _on_PlayerData_player_died() -> void:
	self.paused = true
	self.player_is_dead = true
	# Cambia el "TITULO" de la interfaz de Pausa a "You Died!"
	pause_title.text = "You died!"
	
	

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("pause") and not player_is_dead:
			# Cambia el estado de al opuesto del estado actual
			# SELF es necesario en este caso para activar el SETGET (Por que? Yo no lo se)
			self.paused = not paused
			# Hace que el "Escape" sea utilizado solo en este punto y no en otros puntos del programa
			scene_tree.set_input_as_handled()


func update_interface() -> void:
	score.text = "Score: %s" % PlayerData.score
	


func set_paused(value: bool) -> void:
	paused = value
	scene_tree.paused = value
	pause_overlay.visible = value
	# IMPORTANTE: En el nodo principal UserInterface, Inspector > Pause > Mode Process
	# IMPORTANTE: sin el cambio anterior, se bloquea la UI con la pausa...

