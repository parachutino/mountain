extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

onready var shoes_label = $ShoesLabel
onready var acccesory_label = $AccesoryLabel	

onready var player = get_parent()

export (String, "Nothing", "Climbing Shoes", "Ice Crampons", "Snow Rackets") onready var shoes = "Nothing" setget shoes_changed
export (String, "Nothing", "Rain Coat", "Jumping Tool", "Parachute") onready var accesory = "Nothing" setget accesory_changed

var shoesInventory = ["Nothing", "Climbing Shoes", "Ice Crampons", "Snow Rackets"]
var accesoryInventory =  ["Nothing", "Rain Coat", "Jumping Tool", "Parachute"]

var item: Dictionary 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generate_item_list()


class player_item:
	
	var name = "nothing"
	var description = "<< No description >>"
	
	# Main Modifiers
	var speed_modifier = Vector2(1, 1) # DEFAULT (1, 1) # Multiply
	var gravity_modifier = 1.0 # DEFAULT 1 # Multiply
	var acceleration_modifier = 1.0 # DEFAULT 1 # Multiply
	var windResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.3) # Add
	var rainResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.5) # Add
	var snowResistance_modifier = 0.0 # DEFAULT 0 (Default resistance: 0.5)# Add
	
	
	var terrainAcceleration_modifier: Dictionary = { # Add
	"air" : 0.0,
	"unknown" : 0.0,
	"grass" : 0.0,
	"stone" : 0.0,
	"ice": 0.0,
	"snow": 0.0
	}
	
	var terrainSpeed_modifier: Dictionary = { # Add
	"air" : Vector2(0.0, 0.0),
	"unknown" : Vector2(0.0, 0.0),
	"grass" : Vector2(0.0, 0.0),
	"stone" : Vector2(0.0, 0.0),
	"ice": Vector2(0.0, 0.0),
	"snow": Vector2(0.0, 0.0)
	}
	

func _generate_item_list():
	
	# Nothing equiped
	item["Nothing"] = player_item.new()
	item["Nothing"].name = ""
	item["Nothing"].description = ""
	
	# Climbing Shoes
	item["Climbing Shoes"] = player_item.new()
	item["Climbing Shoes"].name = "Climbing Shoes"
	item["Climbing Shoes"].description = "Better grip on rocks, but slightly slows down speed. Warning: Do not use on ice!!"
	item["Climbing Shoes"].terrainAcceleration_modifier["stone"] = 0.2
	item["Climbing Shoes"].terrainAcceleration_modifier["ice"] = -0.02
	item["Climbing Shoes"].speed_modifier = Vector2(0.8, 1)
	
	# Snow Shoes
	item["Snow Rackets"] = player_item.new()
	item["Snow Rackets"].name = "Snow Rackets"
	item["Snow Rackets"].description = "Gives normal speed on snow and snowy weather. Warning! Don't use on rocks!"
	item["Snow Rackets"].terrainSpeed_modifier["snow"] = Vector2(0.5,0.5)
	item["Snow Rackets"].snowResistance_modifier = 0.5
	item["Snow Rackets"].terrainAcceleration_modifier["stone"] = -0.05
	
	# Ice Crampons
	item["Ice Crampons"] = player_item.new()
	item["Ice Crampons"].name = "Ice Crampons"
	item["Ice Crampons"].description = "Allows climbing on ice. Slows down speed on grass and rocks."
	item["Ice Crampons"].terrainAcceleration_modifier["ice"] = 0.2
	item["Ice Crampons"].terrainSpeed_modifier["stone"] = Vector2(-0.5, 0)
	item["Ice Crampons"].terrainSpeed_modifier["grass"] = Vector2(-0.3, 0)
	
	# Rain Coat
	item["Rain Coat"] = player_item.new()
	item["Rain Coat"].name = "Rain Coat"
	item["Rain Coat"].description = "Allows to walk normally under rain, but it can be dangerous to use under on windy weather."
	item["Rain Coat"].rainResistance_modifier = 0.5
	item["Rain Coat"].windResistance_modifier = -0.2
	
		# Parachute
	item["Jumping Tool"] = player_item.new()
	item["Jumping Tool"].name = "Jumping Tool"
	item["Jumping Tool"].description = "Allows to jump very high! But it's almost impossible to walk while using it."
	item["Jumping Tool"].speed_modifier = Vector2(0.5, 1.5)
	item["Jumping Tool"].terrainSpeed_modifier["air"] = Vector2(0.5, 0) # Gives normal acceleration on air
#	item["Jumping Tool"].acceleration_modifier = 0.5
	
	# Parachute
	item["Parachute"] = player_item.new()
	item["Parachute"].name = "Parachute"
	item["Parachute"].description = "Allows to fall down slowly, but it makes very difficult moving and jumping while equipped. Be careful with the wind!!"
	item["Parachute"].gravity_modifier = 0.4 # Parachute
	item["Parachute"].speed_modifier = Vector2(0.25, 0.25) # Parachute speed
	item["Parachute"].terrainSpeed_modifier["air"] = Vector2(2, 0) # Gives normal acceleration on air
	item["Parachute"].windResistance_modifier = -0.2
	
	# LIST ALL OBJECTS:
#	for object in item:
#		print_debug(
#			"OBJECT: ", item[object].name,
#			" / Speed: ", item[object].speed_modifier,
#			" / Gravity: ", item[object].gravity_modifier,
#			" / Wind Res: ", item[object].windResistance_modifier,
#			" / Rain Res: ", item[object].rainResistance_modifier,
#			" / Snow Res: ", item[object].snowResistance_modifier,
#			" / Terrain Acceleration: ", item[object].terrainAcceleration_modifier,
#			" / Speed Acceleration: ", item[object].terrainSpeed_modifier
#			)
	
	
func shoes_changed(new_shoes):
	if shoes:
		shoes = new_shoes
		print_debug(player)
		player.shoes = shoes
		shoes_label.text = item[shoes].name
	else:
		shoes = "Nothing"
	
	
	
func accesory_changed(new_accesory):
	if accesory:
		accesory = new_accesory
		print_debug(player)
		player.accesory = accesory
		acccesory_label.text = item[accesory].name
	else: accesory = "Nothing"
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
