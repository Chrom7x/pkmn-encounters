class_name ActionStartDialogue
extends GameAction
## Encadena otra conversación. Equivale a `choice.next`, pero como acción (útil
## cuando quieres correr acciones ANTES del sub-diálogo, o lanzarlo desde una
## cinemática).

@export var dialogue: DialogueData
@export var store_result_key: StringName = &"nested_dialogue"


func execute(ctx: ActionContext) -> void:
	if dialogue == null:
		return
	var res: DialogueResult = await DialogueManager.start(dialogue, ctx.data)
	if store_result_key != &"":
		ctx.data[store_result_key] = res
