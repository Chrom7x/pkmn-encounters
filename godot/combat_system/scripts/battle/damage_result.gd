class_name DamageResult
extends RefCounted
## Resultado de un intento de ataque. Lo devuelve DamageCalculator y Battler.use_move.

var damage: int = 0
var effectiveness: float = 1.0     ## 0, 0.25, 0.5, 1, 2 o 4
var critical: bool = false
var missed: bool = false
var stab: bool = false
var category: int = MoveData.Category.PHYSICAL
var fainted_target: bool = false


func is_super_effective() -> bool:
	return effectiveness > 1.0


func is_not_very_effective() -> bool:
	return effectiveness < 1.0 and not is_zero_approx(effectiveness)


func is_immune() -> bool:
	return is_zero_approx(effectiveness)


func effectiveness_text() -> String:
	return PokeTypes.effectiveness_label(effectiveness)
