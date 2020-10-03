extends Control


export (String, 'clear', 'rain', 'snow') var weatherType = 'sun'
export (float, -1, 1) var wind = 0
export (float, 0, 1) var size = 0.3
export (int, 100, 3000) var amount = 1000
export (bool) var setLight = false
export (float, 0, 1) var light = 1
export var weatherNode: NodePath = "../Weather"
var weather: Node2D

onready var collisionShape2D = $Area2D/CollisionShape2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	weather = get_node(weatherNode)
	collisionShape2D.position = rect_size / 2
	collisionShape2D.shape.extents = rect_size/2



func _process(delta: float) -> void:
	pass



func _on_Area2D_body_entered(body: Node) -> void:
	# print_debug("CHANGE WEATHER!!")
	if weather.last_control != self:
		weather.last_control = self
		weather.weatherType = weatherType
		weather.wind = wind
		weather.size = size
		weather.amount = amount
		
		if setLight == true: weather. light = light
		
		weather.change_weather()

