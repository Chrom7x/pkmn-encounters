class_name Cutscene
extends Resource
## Una secuencia de cinemática/evento: lista ordenada de pasos (CutsceneStep).
## Crea un .tres, añade pasos y arrástralos en el inspector.

@export var id: StringName = &""
@export var steps: Array[CutsceneStep] = []

## Emite EventBus.gameplay_input_locked mientras se reproduce (bloquea al jugador).
@export var lock_input: bool = true
