extends Node
## Autoload "CutsceneManager" — ejecutor de secuencias (sequencer).
##
## Recibe un recurso Cutscene (lista de CutsceneStep) y ejecuta los pasos EN
## ORDEN, esperando (`await`) a que cada uno termine antes de lanzar el siguiente.
## Los pasos que lo necesiten pueden ser asíncronos (tweens, diálogos, timers).
##
## Uso:
##   var ctx := CutsceneContext.new()
##   ctx.register_actor(&"player", $Player)
##   ctx.camera = $Camera2D
##   await CutsceneManager.play(mi_cinematica, ctx)

signal started(cutscene: Cutscene)
signal finished(cutscene: Cutscene)
signal step_started(index: int, step: CutsceneStep)

var is_playing: bool = false
var current_context: CutsceneContext = null


## Reproduce la cinemática. Si `ctx` es null se crea uno vacío. Reentrante:
## un StepBranch/StepParallel puede volver a llamar a play() con el mismo ctx.
func play(cutscene: Cutscene, ctx: CutsceneContext = null) -> void:
	if cutscene == null:
		return
	if ctx == null:
		ctx = CutsceneContext.new()
	ctx.manager = self
	ctx.tree = get_tree()

	var is_top_level := not is_playing
	if is_top_level:
		is_playing = true
		current_context = ctx
		started.emit(cutscene)
		EventBus.cutscene_started.emit(cutscene)
		if cutscene.lock_input:
			EventBus.gameplay_input_locked.emit(true)

	for i in cutscene.steps.size():
		var step: CutsceneStep = cutscene.steps[i]
		if step == null:
			continue
		step_started.emit(i, step)
		EventBus.cutscene_step_started.emit(i, step)
		await step.run(ctx)

	if is_top_level:
		if cutscene.lock_input:
			EventBus.gameplay_input_locked.emit(false)
		is_playing = false
		current_context = null
		finished.emit(cutscene)
		EventBus.cutscene_finished.emit(cutscene)


func _unhandled_input(event: InputEvent) -> void:
	if is_playing and current_context and event.is_action_pressed(&"cutscene_skip"):
		current_context.skipping = true
		get_viewport().set_input_as_handled()
