class_name StepMoveCamera
extends CutsceneStep
## Desplaza (y opcionalmente hace zoom de) la cámara de ctx.camera.
## Truco habitual: tener una Camera2D "de cine" aparte y activarla al empezar la
## cinemática (con un StepEmitEvent o StepAction) para no pelear con la del jugador.

@export var to_marker: StringName = &""
@export var to_position: Vector2 = Vector2.ZERO
## (0,0) = no tocar el zoom. Ej: (2,2) para acercar.
@export var zoom: Vector2 = Vector2.ZERO
@export_range(0.0, 20.0, 0.05) var duration: float = 1.0
@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT


func run(ctx: CutsceneContext) -> void:
	var cam := ctx.camera as Node2D
	if cam == null:
		push_warning("StepMoveCamera: ctx.camera no es un Node2D")
		return

	var target := ctx.get_marker_position(to_marker) if to_marker != &"" else to_position
	var change_zoom := zoom != Vector2.ZERO and cam is Camera2D

	if ctx.skipping or duration <= 0.0:
		cam.global_position = target
		if change_zoom:
			(cam as Camera2D).zoom = zoom
		return

	var tw := cam.create_tween().set_parallel(true)
	tw.tween_property(cam, "global_position", target, duration) \
		.set_trans(transition).set_ease(easing)
	if change_zoom:
		tw.tween_property(cam, "zoom", zoom, duration) \
			.set_trans(transition).set_ease(easing)
	await tw.finished
