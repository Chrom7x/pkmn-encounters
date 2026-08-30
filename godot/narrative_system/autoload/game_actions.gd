extends Node
## Autoload "GameActions" — registro de acciones nombradas.
##
## Es el otro pilar del desacople: los sistemas de juego REGISTRAN un handler
## para un id ("heal_party", "open_shop", "teleport_player"…), y los diálogos y
## cinemáticas lo INVOCAN por nombre sin conocer quién lo implementa.
##
## El handler recibe un Dictionary de parámetros y puede ser síncrono o async
## (una corrutina): `run()` lo espera igualmente.
##
## Ejemplo (en el sistema de equipo):
##   func _ready():
##       GameActions.register(&"heal_party", _on_heal_party)
##   func _on_heal_party(params: Dictionary) -> void:
##       await _play_heal_animation()
##       party.heal_all()

var _handlers: Dictionary = {}   # StringName -> Callable


func register(id: StringName, handler: Callable) -> void:
	if _handlers.has(id):
		push_warning("GameActions: se sobrescribe el handler de '%s'" % id)
	_handlers[id] = handler


func unregister(id: StringName) -> void:
	_handlers.erase(id)


func has(id: StringName) -> bool:
	return _handlers.has(id)


## Ejecuta la acción y devuelve su retorno (o null). Espera si el handler es async.
func run(id: StringName, params: Dictionary = {}) -> Variant:
	var cb: Callable = _handlers.get(id, Callable())
	if not cb.is_valid():
		push_warning("GameActions: no hay handler registrado para '%s'" % id)
		return null
	# `await` sobre un valor normal lo devuelve tal cual; sobre una corrutina, espera.
	return await cb.call(params)
