extends Node2D

export (String, 'clear', 'rain', 'snow') var weatherType = 'sun'
export (float, -1, 1) var wind = 0
export (float, 0, 1) var size = 0.3
export (int, 100, 3000) var amount = 1000
export (float, 0, 1) var light = 1
export (float, 0, 1) var snow_darkness = 0.2
export (float, 0, 1) var rain_darkness = 0.3
export (float, 0, 10) var lightChangeTime = 2

export var playerNode: NodePath = "../Player"
export var followNode: NodePath = "../Player"

var nightColor: Color = Color.white # color SUBTRACTED to 

onready var snow = $Snow
onready var rain = $Rain
onready var darkness = $Darkness
onready var tween = $Tween

# Defines Player to set wind behaviour
onready var player: Node2D = get_node(playerNode)

# Emiter folows position of this node.
onready var follow: Node2D = get_node(followNode)

# Set from WeatherControl to ignores last weather change
var last_control: Control
var last_amount: int

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_weather()
	darkness_position()
	position = get_viewport_transform().get_origin() + Vector2(get_viewport_rect().size.x / 2, 0) # Initially positions the emiter in the top center of the screen
	snow.process_material.emission_box_extents.x = get_viewport_rect().size.x * 2 # Sets emiter width to N times the screen size
	rain.process_material.emission_box_extents.x = get_viewport_rect().size.x * 2 # Sets emiter width to N times the screen size
	
func _physics_process(_delta: float) -> void:
	if follow:
		position = follow.position + Vector2(0, -get_viewport_rect().size.y) # Weather follows the position of node in "follow"
		darkness_position() # Darkness follows the viewport
	
func change_weather():
	
	if weatherType == 'snow':
		
		# DARKEN DAY
		set_darkness(nightColor.darkened(light - snow_darkness * size))
		yield(tween, "tween_completed") # Waits light change to change weather
		
		# SNOW SETTINGS
		snow.process_material.anim_offset = size
		if last_amount != amount: # PROBLEM!! Changing amount resets particle emiter!!!
			if snow.emitting == true: snow.preprocess = snow.lifetime
			snow.amount = amount
		else: snow.preprocess = 0
		# snow.amount = amount + amount * abs(wind) # Adds particles for stronger wind... deleted for 
		
		# SNOW WIND SETTINGS
		snow.speed_scale = 0.5 + abs(wind) / 2
		snow.process_material.direction.x = wind
		snow.process_material.gravity.x = 100 * wind
		snow.process_material.initial_velocity = 100 + 400 * abs(wind)	
		
		snow.emitting = true
		
	else: snow.emitting = false


	if weatherType == 'rain':
		
		# DARKEN DAY
		set_darkness(nightColor.darkened(light - rain_darkness * size))
		yield(tween, "tween_completed") # Waits light change to change weather
		
		# RAIN SETTINGS
		rain.process_material.anim_offset = size
		if last_amount != amount: # PROBLEM!! Changing amount resets particle emiter!!!
			if rain.emitting == true: rain.preprocess = rain.lifetime
			rain.amount = amount
		else: snow.preprocess = 0
		# snow.process_material.set("anim_offset", size) # Alternative way to set a property...
	
		# RAIN WIND SETTINGS
		rain.speed_scale = 0.5 + abs(wind) / 2
		rain.process_material.direction.x = wind # / 2
		rain.process_material.gravity.x = 100 * wind
		rain.process_material.initial_velocity = 200 + 400 * abs(wind)	
		
		rain.emitting = true
		
	else: rain.emitting = false


	if weatherType == 'clear':
		set_darkness(nightColor.darkened(light))
		yield(tween, "tween_completed") # Waits light change to change weather

	# CHANGE PLAYER WIND VARIABLE
	if player:
		player.wind = wind
		player.weather = weatherType
	
	# SETS LAST_AMOUNT FOR CHANGE CHECK
	last_amount = amount


func set_darkness(new_color: Color):
	
	# Animation for darkness change
	tween.interpolate_property(darkness, "color",
	darkness.color, new_color, lightChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func darkness_position():
	
	# DARKNESS 4 TIMES VIEWPORT SIZE AND CENTERED... I THINK
	darkness.rect_size = get_viewport_rect().size * 4
	darkness.rect_position = get_viewport_rect().position - Vector2(get_viewport_rect().size.x*2, get_viewport_rect().size.y)
