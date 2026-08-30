class_name StepParallel
extends CutsceneStep
## Ejecuta varios sub-pasos A LA VEZ y no continúa hasta que TODOS terminan.
## Ej: mover al personaje y a la cámara simultáneamente mientras suena música.

@export var steps: Array[CutsceneStep] = []


func run(ctx: CutsceneContext) -> void:
	if steps.is_empty():
		return
	var barrier := SignalBarrier.new(steps.size())
	for s in steps:
		if s == null:
			barrier.one_done()
		else:
			# Se llama SIN await: arranca como corrutina independiente.
			_run_child(s, ctx, barrier)
	await barrier.completed


func _run_child(step: CutsceneStep, ctx: CutsceneContext, barrier: SignalBarrier) -> void:
	await step.run(ctx)
	barrier.one_done()
