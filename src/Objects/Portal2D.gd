# Indica que hay partes del codigo que se ejecutan en el editor de Godot (no solo con el juego en funcionamiento).
# Especificamente para el "Warning" si la next_scene no está configurada
tool
extends Area2D

# Referencia externa al nodo "AnimationPlayer"
onready var anim_player: AnimationPlayer = $AnimationPlayer

# Variable publica para definir la siguiente Escena
export var next_scene: PackedScene

func _on_body_entered(body: Node) -> void:
	teleport()

# Función para crear un WARNING en el editor de Godot si la NEXT SCENE no está definida...
func _get_configuration_warning() -> String:
	return "The next scene property is empty!" if not next_scene else ""

# Teletransporto a la siguiente escena...
func teleport() -> void:
	# Play a la animación "fade_to_black" en el animation player
	anim_player.play("fade_to_black")
	# yield espera a que el "Animation Player" emita la SIGNAL "animation_finished"
	yield(anim_player, "animation_finished")
	# get_tree objeto que importa el "Tree" completo de todo el juego
	# method de get_tree que cambia la escena a la escena especificada
	get_tree().change_scene_to(next_scene)	

