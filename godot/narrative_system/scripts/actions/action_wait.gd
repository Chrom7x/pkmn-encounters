class_name ActionWait
extends GameAction
## Pausa entre acciones (dar tiempo a una animación, un fundido, etc.).

@export_range(0.0, 30.0, 0.05) var seconds: float = 0.5


func execute(ctx: ActionContext) -> void:
	if seconds > 0.0 and ctx.tree:
		await ctx.tree.create_timer(seconds).timeout
