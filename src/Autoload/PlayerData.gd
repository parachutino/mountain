extends Node

signal score_updated
signal player_died

#setget -> Define una funcion para que cada vez que cambie il valor de esta variable envia un valor a esa funcion y la procesa

var score: = 0 setget set_score
var deaths: = 0 setget set_deaths

func reset() -> void:
	score = 0
	deaths = 0

# Funcion se ejecuta automaticamente cuando se cambia el valor de la variable
func set_score(value: int) -> void:
	
		# Asigna el valor entregado a la variable (no lo hace automaticamente)
		score = value
		# Emite signal
		emit_signal("score_updated")
	
	
# Funcion se ejecuta automaticamente cuando se cambia el valor de la variable
func set_deaths(value: int) -> void:
		# Asigna el valor entregado a la variable (no lo hace automaticamente)
		deaths = value
		emit_signal("player_died")
#		reset()
