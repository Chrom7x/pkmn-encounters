class_name CutsceneStep
extends Resource
## Base de todos los pasos de cinemática. Sobrescribe `run(ctx)`.
## `run` PUEDE ser asíncrono: el CutsceneManager hace `await step.run(ctx)`, así
## que un paso solo "termina" cuando su corrutina retorna.
##
## Pasos incluidos: StepWait, StepMoveActor, StepMoveCamera, StepPlayAnimation,
## StepDialogue, StepAction, StepEmitEvent, StepBranch, StepParallel.
## Añadir uno nuevo = crear una subclase con su `run()`; el manager no cambia.

@export var comment: String = ""   ## etiqueta para el inspector


func run(_ctx: CutsceneContext) -> void:
	push_warning("CutsceneStep sin implementar: %s" % [comment if comment else resource_path])
	await (Engine.get_main_loop() as SceneTree).process_frame
