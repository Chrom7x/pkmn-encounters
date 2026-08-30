class_name StepEmitEvent
extends CutsceneStep
## Atajo para lanzar un evento por EventBus sin crear un recurso GameAction.
## Ideal para "activar cámara de cine", "encender luces", "sonar fanfarria"...

@export var event: StringName = &""
@export var payload: Dictionary = {}


func run(_ctx: CutsceneContext) -> void:
	if event != &"":
		EventBus.dispatch(event, payload)
