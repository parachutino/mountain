extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL: = Vector2.UP

# Define MAX velocidad en X y en Y...
export var speed: = Vector2(300.0, 1000.0)

# Gravedad. Se agrega el .0 para decir que es numero decimal
# EXPORT: hace visible la variable en el editor
export var gravity: = 4000.0

# Velocidad de movimiento 300px por segundo en X, 0px en Y
var _velocity: = Vector2.ZERO

