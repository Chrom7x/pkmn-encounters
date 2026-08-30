class_name StepBranch
extends CutsceneStep
## Bifurca la cinemática según una condición: reproduce una sub-Cutscene u otra.
## Permite el clásico "si el jugador aceptó -> escena A; si rechazó -> escena B".
##
## La condición se evalúa en este orden:
##  1. Si `flag` != "": se mira Flags.has_flag(flag).
##  2. Si `data_key` != "": se compara ctx.data[data_key] con `equals`.
##     - Si el valor es un DialogueResult, se compara su choice_id.
##     - Si no, se compara str(valor).

@export var flag: StringName = &""
@export var data_key: StringName = &"last_dialogue"
@export var equals: String = ""

@export var if_true: Cutscene
@export var if_false: Cutscene


func run(ctx: CutsceneContext) -> void:
	var branch := if_true if _evaluate(ctx) else if_false
	if branch:
		# Mismo ctx -> reentrante; el manager no re-bloquea el input.
		await ctx.manager.play(branch, ctx)


func _evaluate(ctx: CutsceneContext) -> bool:
	if flag != &"":
		return Flags.has_flag(flag)
	if data_key != &"":
		var v: Variant = ctx.data.get(data_key)
		if v is DialogueResult:
			return String((v as DialogueResult).choice_id) == equals
		return str(v) == equals
	return false
