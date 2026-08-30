class_name StepPlayAnimation
extends CutsceneStep
## Reproduce una animación de un AnimationPlayer que cuelga de un actor.

@export var actor: StringName = &"player"
## Ruta al AnimationPlayer RELATIVA al nodo del actor.
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var animation: StringName = &""
@export_range(0.1, 8.0, 0.1) var speed_scale: float = 1.0
## true = el paso no termina hasta que acaba la animación. Ponlo en false para
## animaciones en bucle (si no, el paso se queda colgado esperando para siempre).
@export var wait_until_finished: bool = true


func run(ctx: CutsceneContext) -> void:
	var node := ctx.get_actor(actor)
	if node == null:
		push_warning("StepPlayAnimation: no hay actor '%s'" % actor)
		return
	var ap := node.get_node_or_null(animation_player_path) as AnimationPlayer
	if ap == null:
		push_warning("StepPlayAnimation: '%s' no tiene AnimationPlayer en %s" % [actor, animation_player_path])
		return

	ap.play(animation, -1, speed_scale)
	if wait_until_finished and not ctx.skipping:
		await ap.animation_finished
	elif ctx.skipping:
		ap.advance(ap.current_animation_length)
