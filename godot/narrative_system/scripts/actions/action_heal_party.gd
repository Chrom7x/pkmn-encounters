class_name ActionHealParty
extends GameAction
## EJEMPLO de acción de juego: curar el equipo (Centro Pokémon).
##
## No cura nada por sí misma: delega en el handler "heal_party" que registre tu
## sistema de equipo en GameActions. Así el sistema de diálogos no conoce al de
## equipo (desacople).
##
##   # En tu PartyManager:
##   GameActions.register(&"heal_party", func(p):
##       await animacion_curacion()
##       party.restore_all())

@export var play_animation: bool = true


func execute(_ctx: ActionContext) -> void:
	await GameActions.run(&"heal_party", {"animate": play_animation})
