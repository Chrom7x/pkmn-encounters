class_name StepAction
extends CutsceneStep
## Ejecuta una GameAction dentro de la cinemática (curar, abrir tienda, activar
## flag, teletransportar, emitir evento...). Reutiliza TODO el catálogo de
## acciones del sistema de diálogos.

@export var action: GameAction
@export var wait_until_finished: bool = true


func run(ctx: CutsceneContext) -> void:
	if action == null:
		return
	if wait_until_finished:
		await action.execute(ctx.to_action_context())
	else:
		action.execute(ctx.to_action_context())
