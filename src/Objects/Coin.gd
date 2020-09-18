extends Area2D

# Crea una referencia al nodo "AnimationPlayer" para utilizarlo en el Script
onready var anim_player: AnimationPlayer = get_node("AnimationPlayer")

export var score: int = 50


func _on_body_entered(body: Node) -> void:
	PlayerData.score += score
	anim_player.play("fade_out")
