class_name DialogueResult
extends RefCounted
## Lo que devuelve `DialogueManager.start()`. Permite a quien lanzó el diálogo
## (una cinemática, un NPC, un menú) reaccionar a la decisión del jugador.

var completed: bool = true          ## false si el diálogo era null / se canceló
var choice_id: StringName = &""     ## id de la ÚLTIMA opción elegida
var choice_index: int = -1          ## índice de esa opción entre las visibles
var history: Array[StringName] = [] ## todos los choice.id elegidos, en orden
var data: Dictionary = {}           ## scratch: las acciones pueden escribir aquí


func chose(id: StringName) -> bool:
	return choice_id == id


func chose_any(ids: Array) -> bool:
	return choice_id in ids
