extends Node2D
## Demo autocontenida: crea la UI, un "jugador" y una cámara de mentira, registra
## los handlers de juego y reproduce una cinemática que lanza un diálogo con
## decisión (Centro Pokémon) y luego un menú de Vuelo.
##
## Cómo probar: escena nueva con un Node2D raíz, este script adjunto, F6.
## (Requiere los 5 autoloads del project.godot).

var _player: Node2D
var _cine_camera: Camera2D


func _ready() -> void:
	_build_stage()
	_register_game_systems()
	EventBus.game_event.connect(func(id: StringName, p: Dictionary):
		print("[EventBus] %s %s" % [id, p]))

	var intro := _build_intro_cutscene()
	var fly_menu := _build_fly_dialogue()

	var ctx := CutsceneContext.new()
	ctx.register_actor(&"player", _player)
	ctx.camera = _cine_camera

	print("--- Cinemática de introducción ---")
	await CutsceneManager.play(intro, ctx)

	print("--- Menú de Vuelo ---")
	var res: DialogueResult = await DialogueManager.start(fly_menu)
	print("Resultado del menú de Vuelo: '%s'" % res.choice_id)
	print("--- Fin de la demo ---")


# ---------------------------------------------------------------- escenario
func _build_stage() -> void:
	_player = Node2D.new()
	_player.name = "Player"
	add_child(_player)

	_cine_camera = Camera2D.new()
	_cine_camera.name = "CineCamera"
	add_child(_cine_camera)

	if not get_tree().get_nodes_in_group("dialogue_ui_present").size():
		var ui := DialogueUI.new()
		ui.add_to_group("dialogue_ui_present")
		add_child(ui)


# ------------------------------------------- handlers de sistemas de juego
func _register_game_systems() -> void:
	# El sistema de equipo escucha "heal_party" (async: simula la animación).
	GameActions.register(&"heal_party", func(params: Dictionary) -> void:
		print("  > Curando equipo… (animate=%s)" % params.get("animate", true))
		await get_tree().create_timer(0.4).timeout
		print("  > ¡Equipo curado!"))

	# La tienda.
	GameActions.register(&"open_shop", func(params: Dictionary) -> void:
		print("  > Abriendo tienda '%s'" % params.get("shop_id", "default"))
		await get_tree().create_timer(0.3).timeout
		print("  > Tienda cerrada"))

	# Vuelo: mueve al jugador y hace un "fundido".
	GameActions.register(&"teleport_player", func(params: Dictionary) -> void:
		print("  > Volando a '%s' (fade=%s)" % [params.get("destination_id"), params.get("fade")])
		await get_tree().create_timer(0.3).timeout
		_player.global_position = Vector2(1000, 0)
		print("  > Aterrizaje completado"))


# ---------------------------------------------------------------- diálogos
func _build_center_dialogue() -> DialogueData:
	var yes_branch := _data(&"center_yes", [
		_line("Enfermera Joy", "¡Gracias por la espera! Tus Pokémon están como nuevos."),
	])
	var no_branch := _data(&"center_no", [
		_line("Enfermera Joy", "De acuerdo. ¡Ten cuidado ahí fuera!"),
	])

	var heal := ActionHealParty.new()
	var remember := ActionSetFlag.new()
	remember.flag = &"visito_centro"

	return _data(&"center", [
		_line("Enfermera Joy", "¡Bienvenido al Centro Pokémon! ¿Quieres que cure a tu equipo?", [
			_choice(&"heal_accept", "Sí, por favor", [heal, remember], yes_branch),
			_choice(&"heal_decline", "No, gracias", [remember], no_branch),
		]),
	])


func _build_fly_dialogue() -> DialogueData:
	var to_verde := ActionTeleport.new()
	to_verde.destination_id = &"ciudad_verde"
	var to_paleta := ActionTeleport.new()
	to_paleta.destination_id = &"pueblo_paleta"

	return _data(&"fly", [
		_line("", "¿A dónde quieres volar?", [
			_choice(&"fly_verde", "Ciudad Verde", [to_verde]),
			_choice(&"fly_paleta", "Pueblo Paleta", [to_paleta]),
			_choice(&"fly_cancel", "Cancelar"),
		]),
	])


# --------------------------------------------------------------- cinemática
func _build_intro_cutscene() -> Cutscene:
	var cam := StepMoveCamera.new()
	cam.to_position = Vector2(160, 0)
	cam.duration = 0.8

	var walk := StepMoveActor.new()
	walk.actor = &"player"
	walk.to_position = Vector2(120, 0)
	walk.duration = 0.6

	var talk := StepDialogue.new()
	talk.dialogue = _build_center_dialogue()
	talk.store_result_key = &"center_result"

	var celebrate := Cutscene.new()
	celebrate.lock_input = false
	var confetti := StepEmitEvent.new()
	confetti.event = &"vfx_confetti"
	celebrate.steps = _steps([confetti])

	var branch := StepBranch.new()
	branch.data_key = &"center_result"
	branch.equals = "heal_accept"
	branch.if_true = celebrate

	var c := Cutscene.new()
	c.id = &"intro"
	c.steps = _steps([cam, walk, talk, branch, StepWait.new()])
	return c


# ---------------------------------------------------------------- helpers
func _line(speaker: String, text: String, choices: Array = []) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker = speaker
	l.text = text
	var typed: Array[DialogueChoice] = []
	for c in choices:
		typed.append(c)
	l.choices = typed
	return l


func _choice(id: StringName, text: String, actions: Array = [],
		next: DialogueData = null) -> DialogueChoice:
	var c := DialogueChoice.new()
	c.id = id
	c.text = text
	var typed: Array[GameAction] = []
	for a in actions:
		typed.append(a)
	c.actions = typed
	c.next = next
	return c


func _data(id: StringName, lines: Array) -> DialogueData:
	var d := DialogueData.new()
	d.id = id
	var typed: Array[DialogueLine] = []
	for l in lines:
		typed.append(l)
	d.lines = typed
	return d


func _steps(arr: Array) -> Array[CutsceneStep]:
	var typed: Array[CutsceneStep] = []
	for s in arr:
		typed.append(s)
	return typed
