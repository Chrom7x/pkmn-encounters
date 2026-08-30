class_name HealingStation
extends Node
## Centro Pokémon: la "máquina de curar" de la Enfermera Joy.
##
## Pon este nodo en la escena del Centro Pokémon (o como autoload propio).
## Registra el handler "heal_party" en GameActions, así ActionHealParty y
## GameActions.run(&"heal_party") funcionan sin más.
##
## La restauración REAL del equipo la hace tu sistema de combate/equipo, que se
## conecta de una de estas dos formas (desacople):
##   - registra el handler "party_restore" en GameActions, o
##   - escucha la señal EventBus.party_healed.

@export var action_id: StringName = &"heal_party"
## Duración de la animación de la máquina (las bolas subiendo y bajando).
@export_range(0.0, 10.0, 0.1) var heal_duration: float = 1.2
@export var auto_register: bool = true


func _ready() -> void:
	if auto_register and not GameActions.has(action_id):
		GameActions.register(action_id, _heal)


func _exit_tree() -> void:
	if auto_register and GameActions.has(action_id):
		GameActions.unregister(action_id)


func _heal(params: Dictionary) -> void:
	EventBus.party_heal_started.emit()
	EventBus.dispatch(&"pokemon_center_heal_started", params)

	if heal_duration > 0.0:
		await get_tree().create_timer(heal_duration).timeout

	# Restauración concreta (PS, PP, estados): la aporta quien la registre.
	if GameActions.has(&"party_restore"):
		await GameActions.run(&"party_restore", params)

	EventBus.party_healed.emit()
	EventBus.dispatch(&"pokemon_center_heal_done", params)
