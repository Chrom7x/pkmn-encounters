class_name StepDialogue
extends CutsceneStep
## Lanza un diálogo (con o sin decisión) DESDE la cinemática y espera la
## respuesta. El resultado queda en ctx.data[store_result_key] para que un
## StepBranch posterior decida el rumbo.

@export var dialogue: DialogueData
@export var store_result_key: StringName = &"last_dialogue"


func run(ctx: CutsceneContext) -> void:
	if dialogue == null:
		return
	var res: DialogueResult = await DialogueManager.start(dialogue, ctx.data)
	if store_result_key != &"":
		ctx.data[store_result_key] = res
