class_name DialogueCondition
extends Resource
## Base para condiciones programables reutilizables (disponibilidad de opciones,
## ramas de cinemática...). Sobrescribe `is_met()`.
##
## Crea subclases para tus necesidades: "tiene objeto X", "nivel >= N",
## "es de noche", "medalla obtenida"... Ver conditions/condition_flag_value.gd.

@export var negate: bool = false   ## invierte el resultado


func is_met() -> bool:
	return _evaluate() != negate


## Sobrescribir en la subclase.
func _evaluate() -> bool:
	return true
