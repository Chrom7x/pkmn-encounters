class_name Interactor
extends Area2D
## Se añade al jugador. Mantiene la lista de Interactable solapados y, al pulsar
## "interact", activa el más cercano. También bloquea la interacción mientras hay
## un diálogo o cinemática en curso, y escucha EventBus.gameplay_input_locked.
##
## Estructura de nodos:
##   Player (CharacterBody2D)
##   └── Interactor (Area2D, este script)   -> monitoring = true
##       └── CollisionShape2D               (alcance del jugador)
##
## Requisitos: los Interactable deben tener monitorable = true y estar en una
## capa que este Area2D vigile (mask).

@export var input_action: StringName = &"interact"

var _candidates: Array[Interactable] = []
var _locked: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	EventBus.gameplay_input_locked.connect(_on_input_locked)


func _on_input_locked(locked: bool) -> void:
	_locked = locked


func _unhandled_input(event: InputEvent) -> void:
	if _locked or DialogueManager.is_running or CutsceneManager.is_playing:
		return
	if not event.is_action_pressed(input_action):
		return
	var target := _closest()
	if target:
		get_viewport().set_input_as_handled()
		target.interact()


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _candidates.has(area):
		_candidates.append(area as Interactable)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_candidates.erase(area)


func _closest() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for it in _candidates:
		if not is_instance_valid(it) or not it.can_interact():
			continue
		var d := global_position.distance_squared_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	return best
