extends Node2D

export (String, 'clear', 'rain', 'snow') var weatherType = 'sun'
export (float, -1, 1) var wind = 0
export (float, 0, 1) var size = 0.3
export (int, 100, 3000) var amount = 1500
export (float, 0, 1) var light = 1
export (float, 0, 1) var snow_darkness = 0.2
export (float, 0, 1) var rain_darkness = 0.3
export (float, 0, 10) var weatherChangeTime = 2

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
		change_light(nightColor.darkened(light - snow_darkness * size))
		yield(tween, "tween_completed") # Waits light change to change weather
		
		# SNOW SETTINGS
		change_size(snow, size)
		# snow.process_material.anim_offset = size
		
		if last_amount != amount: # PROBLEM!! Changing amount resets particle emitter!!!
			if snow.emitting == true: snow.preprocess = snow.lifetime * 2
			snow.amount = amount
		else: snow.preprocess = 0
		# snow.amount = amount + amount * abs(wind) # Adds particles for stronger wind... deleted for 
		
		# SNOW WIND SETTINGS
		change_wind_speed(snow, 0.5 + abs(wind) / 2) # snow.speed_scale = 0.5 + abs(wind) / 2
		
		change_wind_direction(snow, wind) # snow.process_material.direction.x = wind
		
		snow.process_material.gravity.x = 70 * wind
		
		snow.emitting = true
		
	else: snow.emitting = false


	if weatherType == 'rain':
		
		# DARKEN DAY
		change_light(nightColor.darkened(light - rain_darkness * size))
		yield(tween, "tween_completed") # Waits light change to change weather
		
		# RAIN SETTINGS
		rain.process_material.anim_offset = size
		if last_amount != amount: # PROBLEM!! Changing amount resets particle emiter!!!
			if rain.emitting == true: rain.preprocess = rain.lifetime * 2
			rain.amount = amount
		else: rain.preprocess = 0
		# snow.process_material.set("anim_offset", size) # Alternative way to set a property...
	
		# RAIN WIND SETTINGS
		rain.speed_scale = 0.5 + abs(wind) / 2 + size / 2
		rain.process_material.direction.x = wind
		rain.process_material.gravity.x = 100 * wind
		rain.process_material.initial_velocity = 200 + 400 * abs(wind)	
		
		rain.emitting = true
		
	else: rain.emitting = false


	if weatherType == 'clear':
		change_light(nightColor.darkened(light))
		yield(tween, "tween_completed") # Waits light change to change weather

	# CHANGE PLAYER WEATHER VARIABLES
	if player:
		change_player_wind(wind) # player.wind = wind
		change_player_weatherSize(size) # player.weatherSize = size
		player.weather = weatherType # IMPORTANT: Set weatherType after size, or player won't use size to modify velocity...
	
	# SETS LAST_AMOUNT FOR CHANGE CHECK
	last_amount = amount


func change_light(new_color: Color):
	
	# Animation for darkness change
	tween.interpolate_property(darkness, "color",
	darkness.color, new_color, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func change_size(weather, new_size):
	
	tween.interpolate_property(weather, "process_material:anim_offset",
	weather.process_material.anim_offset, new_size, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func change_wind_direction(weather, new_wind):
	
	tween.interpolate_property(weather, "process_material:direction:x",
	weather.process_material.direction.x, new_wind, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func change_wind_speed(weather, new_speed):
	
	tween.interpolate_property(weather, "speed_scale",
	weather.speed_scale, new_speed, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func change_player_wind(new_wind):
	
	tween.interpolate_property(player, "wind",
	player.wind, new_wind, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func change_player_weatherSize(new_weatherSize):
	
	tween.interpolate_property(player, "weatherSize",
	player.weatherSize, new_weatherSize, weatherChangeTime,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func darkness_position():
	
	# DARKNESS 4 TIMES VIEWPORT SIZE AND CENTERED... I THINK
	darkness.rect_size = get_viewport_rect().size * 4
	darkness.rect_position = get_viewport_rect().position - Vector2(get_viewport_rect().size.x*2, get_viewport_rect().size.y)
