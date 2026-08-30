class_name StatStages
extends RefCounted
## Multiplicadores de los "stages" de combate (-6 .. +6), como en la saga.

const MIN := -6
const MAX := 6


## Para Ataque, Defensa, At. Esp., Def. Esp. y Velocidad.
static func multiplier(stage: int) -> float:
	stage = clampi(stage, MIN, MAX)
	if stage >= 0:
		return (2.0 + stage) / 2.0
	return 2.0 / (2.0 - stage)


## Para Precisión y Evasión (usan base 3 en vez de 2).
static func accuracy_multiplier(stage: int) -> float:
	stage = clampi(stage, MIN, MAX)
	if stage >= 0:
		return (3.0 + stage) / 3.0
	return 3.0 / (3.0 - stage)
