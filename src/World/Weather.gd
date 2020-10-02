extends Node2D

export (String, 'sun', 'rain', 'snow') var weatherType = 'sun'
export (float, -1, 1) var wind = 0
export (float, 0, 1) var size = 0.3
export (int, 0, 500) var amount = 250

onready var snow = $Snow


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_weather()
	pass
	
func change_weather():
	if weatherType == 'snow': snow.emitting = true
	else: snow.emitting = false

	snow.process_material.set("anim_offset", size)
	snow.amount = amount


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
