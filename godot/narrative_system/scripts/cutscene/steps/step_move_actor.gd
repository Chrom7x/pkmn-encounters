class_name StepMoveActor
extends CutsceneStep
## Mueve un actor (Node2D) hasta un marcador o una posición, con tween.

@export var actor: StringName = &"player"      ## clave en ctx.actors
@export var to_marker: StringName = &""        ## si se indica, tiene prioridad
@export var to_position: Vector2 = Vector2.ZERO
@export_range(0.0, 20.0, 0.05) var duration: float = 0.6
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT
## Si el actor tiene un método `face_towards(Vector2)`, se llama antes de moverse.
@export var face_target: bool = true


func run(ctx: CutsceneContext) -> void:
	var node := ctx.get_actor(actor) as Node2D
	if node == null:
		push_warning("StepMoveActor: no hay actor '%s'" % actor)
		return

	var target := ctx.get_marker_position(to_marker) if to_marker != &"" else to_position
	if face_target and node.has_method(&"face_towards"):
		node.call(&"face_towards", target)

	if ctx.skipping or duration <= 0.0:
		node.global_position = target
		return

	var tw := node.create_tween()
	tw.tween_property(node, "global_position", target, duration) \
		.set_trans(transition).set_ease(easing)
	await tw.finished
