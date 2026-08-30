class_name StepWait
extends CutsceneStep
## Pausa la secuencia N segundos.

@export_range(0.0, 60.0, 0.05) var seconds: float = 1.0


func run(ctx: CutsceneContext) -> void:
	if ctx.skipping or seconds <= 0.0 or ctx.tree == null:
		return
	await ctx.tree.create_timer(seconds).timeout
