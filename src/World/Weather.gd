extends Node2D

export (String, 'sun', 'rain', 'snow') var weatherType = 'sun'
export (float, -1, 1) var wind = 0
export (float, 0, 1) var size = 0.3
export (int, 100, 1000) var amount = 250

onready var snow = $Snow

# Defines Player to set wind behaviour
onready var player: Node2D = get_node("../Player")

# Emiter folows position of this node.
onready var follow: Node2D = get_node("../Player")


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_weather() 
	position = get_viewport_transform().get_origin() + Vector2(get_viewport_rect().size.x / 2, 0) # Initially positions the emiter in the top center of the screen
	snow.process_material.emission_box_extents.x = get_viewport_rect().size.x * 1.5 # Sets emiter width to N times the screen size
	
func _physics_process(_delta: float) -> void:
	if follow: position = follow.position + Vector2(0, -get_viewport_rect().size.y) # Follows the position of node in "follow"
	
func change_weather():
	
	if player: player.wind = wind
	
	if weatherType == 'snow':
		snow.emitting = true
		snow.amount = amount + amount * abs(wind)
		snow.process_material.anim_offset = size
		# snow.process_material.set("anim_offset", size) # Alternative way to set property...
	
		# SNOW WIND SETTINGS
		snow.speed_scale = 0.5 + wind / 2
		snow.process_material.direction.x = wind
		snow.process_material.gravity.x = 100 * wind
		snow.process_material.initial_velocity = 100 + 400 * abs(wind)	
		"""
		snow.process_material.set("direction", Vector3(wind, 1, 0))
		snow.process_material.set("gravity", Vector3(100 * wind, 0, 0))
		snow.process_material.set("initial_velocity", 100 + 400 * wind)
		"""
	else: snow.emitting = false


	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
