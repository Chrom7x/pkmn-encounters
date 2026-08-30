class_name ActionRunId
extends GameAction
## Ejecuta una acción registrada en GameActions y ESPERA su resultado (el handler
## puede ser una corrutina: animación de curación, transición de mapa...).

@export var action_id: StringName = &""
@export var params: Dictionary = {}
## Si se indica, guarda el valor devuelto por el handler en ctx.data[esta_clave].
@export var store_result_key: StringName = &""


func execute(ctx: ActionContext) -> void:
	if action_id == &"":
		return
	var value: Variant = await GameActions.run(action_id, params)
	if store_result_key != &"":
		ctx.data[store_result_key] = value
