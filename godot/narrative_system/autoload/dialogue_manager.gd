extends Node
## Autoload "DialogueManager" — reproduce un DialogueData y devuelve el resultado.
##
## Está DESACOPLADO de la interfaz: la UI (DialogueUI) se registra sola con
## `register_ui()`. Si no hay UI (tests, servidor, modo rápido) el diálogo se
## resuelve solo: las líneas avanzan al instante y se elige la primera opción
## disponible.
##
## Uso:
##   var res: DialogueResult = await DialogueManager.start(mi_dialogo)
##   if res.choice_id == &"accept": ...

signal started(data: DialogueData)
signal finished(data: DialogueData, result: DialogueResult)

var _ui: Node = null
var is_running: bool = false


func register_ui(ui: Node) -> void:
	_ui = ui


func unregister_ui(ui: Node) -> void:
	if _ui == ui:
		_ui = null


## Reproduce el diálogo. `context` es un diccionario de scratch compartido con
## las acciones (y devuelto dentro de DialogueResult.data).
func start(data: DialogueData, context: Dictionary = {}) -> DialogueResult:
	var result := DialogueResult.new()
	result.data = context.duplicate()
	if data == null:
		result.completed = false
		return result

	var was_running := is_running
	is_running = true
	started.emit(data)
	EventBus.dialogue_started.emit(data)

	var current: DialogueData = data
	while current != null:
		var jumped := false
		for line in current.lines:
			if line == null:
				continue
			await _present_line(line)
			var choices := _available_choices(line.choices)
			if choices.is_empty():
				continue
			# Hay decisión: mostrarla, esperar respuesta, ejecutar acciones.
			var index: int = await _present_choices(choices)
			var choice: DialogueChoice = choices[index]
			result.choice_index = index
			result.choice_id = choice.id
			result.history.append(choice.id)
			await _run_actions(choice.actions, result)
			current = choice.next          # saltar a la rama (o terminar si es null)
			jumped = true
			break
		if not jumped:
			current = current.next         # cadena lineal (o terminar)

	if _ui and _ui.has_method(&"hide_dialogue"):
		_ui.hide_dialogue()

	is_running = was_running
	finished.emit(data, result)
	EventBus.dialogue_finished.emit(data, result)
	return result


# --- Presentación (con o sin UI) --------------------------------------------
func _present_line(line: DialogueLine) -> void:
	EventBus.dialogue_line_shown.emit(line)
	if line.on_show_event != &"":
		EventBus.dispatch(line.on_show_event, {"line": line})
	if _ui and _ui.has_method(&"show_line"):
		_ui.show_line(line)
		if line.auto_advance_delay > 0.0:
			await get_tree().create_timer(line.auto_advance_delay).timeout
		else:
			await _ui.line_advanced
	elif line.auto_advance_delay > 0.0:
		await get_tree().create_timer(line.auto_advance_delay).timeout
	else:
		await get_tree().process_frame


func _present_choices(choices: Array) -> int:
	if _ui and _ui.has_method(&"show_choices"):
		var labels: Array[String] = []
		for c in choices:
			labels.append(c.text)
		_ui.show_choices(labels)
		return await _ui.choice_selected
	# Sin UI: elegir la primera opción disponible.
	return 0


func _available_choices(choices: Array) -> Array:
	var out: Array = []
	for c in choices:
		if c and c.is_available():
			out.append(c)
	return out


func _run_actions(actions: Array, result: DialogueResult) -> void:
	var ctx := ActionContext.new()
	ctx.source = self
	ctx.tree = get_tree()
	ctx.data = result.data
	for a in actions:
		if a:
			await a.execute(ctx)
