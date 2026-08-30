class_name ConditionFlagValue
extends DialogueCondition
## Se cumple si un flag de `Flags` tiene un valor concreto.
## Ejemplos: flag "badges" >= 3, flag "starter" == "charmander".

enum Op { EQUALS, NOT_EQUALS, GREATER_EQUAL, LESS_EQUAL, IS_TRUE }

@export var flag: StringName = &""
@export var op: Op = Op.IS_TRUE
## Valor de comparación (se ignora con IS_TRUE). Escríbelo como texto o número.
@export var value: String = ""


func _evaluate() -> bool:
	var current: Variant = Flags.get_value(flag)
	match op:
		Op.IS_TRUE:
			return bool(current)
		Op.EQUALS:
			return str(current) == value
		Op.NOT_EQUALS:
			return str(current) != value
		Op.GREATER_EQUAL:
			return float(current) >= float(value)
		Op.LESS_EQUAL:
			return float(current) <= float(value)
	return false
