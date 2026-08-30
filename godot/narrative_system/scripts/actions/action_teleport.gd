class_name ActionTeleport
extends GameAction
## EJEMPLO de acción de juego: teletransportar al jugador ("Vuelo").
## Delega en el handler "teleport_player" (que hará el fundido y el cambio de
## mapa). Si el jugador RECHAZA volar, simplemente no pongas esta acción en la
## opción: no hay que programar nada para "cancelar".

@export var destination_id: StringName = &""   ## id de un punto de aparición
@export var position: Vector2 = Vector2.ZERO   ## alternativa: coordenada directa
@export var with_fade: bool = true


func execute(_ctx: ActionContext) -> void:
	await GameActions.run(&"teleport_player", {
		"destination_id": destination_id,
		"position": position,
		"fade": with_fade,
	})
