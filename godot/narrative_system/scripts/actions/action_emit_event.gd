class_name ActionEmitEvent
extends GameAction
## Lanza un evento genérico por EventBus. No espera a nadie: úsalo para avisar
## a sistemas que reaccionan solos (efectos, logros, sonido...).

@export var event: StringName = &""
@export var payload: Dictionary = {}


func execute(_ctx: ActionContext) -> void:
	if event != &"":
		EventBus.dispatch(event, payload)
