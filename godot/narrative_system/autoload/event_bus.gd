extends Node
## Autoload "EventBus" — bus global de señales.
##
## Es el pegamento que mantiene todo DESACOPLADO: los sistemas de juego
## (equipo, tienda, mapa, cámara…) se conectan aquí y no se conocen entre sí ni
## conocen a los managers de narrativa.
##
## Dos formas de usarlo:
##  1. Señales concretas y tipadas (dialogue_started, cutscene_finished…).
##  2. Señal genérica `game_event(id, payload)` para máxima extensibilidad:
##     añadir una interacción nueva NO requiere tocar este archivo.

# --- Narrativa ------------------------------------------------------------------
signal dialogue_started(data: DialogueData)
signal dialogue_finished(data: DialogueData, result: DialogueResult)
signal dialogue_line_shown(line: DialogueLine)

signal cutscene_started(cutscene: Cutscene)
signal cutscene_finished(cutscene: Cutscene)
signal cutscene_step_started(index: int, step: CutsceneStep)

## El jugador/mapa escucha esto para bloquear el control durante cinemáticas.
signal gameplay_input_locked(locked: bool)

# --- Economía / Centro Pokémon ---------------------------------------------
signal shop_opened(shop_id: StringName)
signal shop_closed(shop_id: StringName)
signal item_bought(item_id: StringName, quantity: int, total_price: int)
signal item_sold(item_id: StringName, quantity: int, total_price: int)
signal money_changed(amount: int)
signal party_heal_started
signal party_healed

# --- Canal genérico ----------------------------------------------------------
## Cualquier acción o paso puede lanzar un evento con nombre y datos libres.
## Los sistemas de juego filtran por `id`.
signal game_event(id: StringName, payload: Dictionary)


func _ready() -> void:
	_ensure_action(&"interact", [KEY_E, KEY_ENTER, KEY_SPACE])
	_ensure_action(&"cutscene_skip", [KEY_ESCAPE])


## Lanza un evento genérico. Azúcar sobre `game_event.emit`.
func dispatch(id: StringName, payload: Dictionary = {}) -> void:
	game_event.emit(id, payload)


## Crea una acción de entrada con teclas por defecto si el proyecto no la define.
func _ensure_action(action: StringName, physical_keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in physical_keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
