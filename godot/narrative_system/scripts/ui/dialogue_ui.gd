class_name DialogueUI
extends CanvasLayer
## Interfaz por defecto del sistema de diálogos. Construye sus controles por
## código (no necesita escena .tscn) y SE REGISTRA SOLA con DialogueManager.
##
## Para usarla: añade un nodo con este script a tu escena principal (o a un
## autoload propio). Para usar TU interfaz en su lugar, crea un nodo con estos
## métodos y señales y llama a DialogueManager.register_ui(self):
##   - show_line(line: DialogueLine) -> void
##   - show_choices(labels: Array) -> void
##   - hide_dialogue() -> void
##   - signal line_advanced
##   - signal choice_selected(index: int)

signal line_advanced
signal choice_selected(index: int)

@export var characters_per_second: float = 45.0   ## 0 = sin efecto máquina de escribir
@export var advance_action: StringName = &"interact"

var _panel: PanelContainer
var _name_label: Label
var _portrait: TextureRect
var _text_label: RichTextLabel
var _choices_box: VBoxContainer
var _continue_hint: Label

var _revealing: bool = false
var _choosing: bool = false
var _reveal_tween: Tween


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_dialogue()
	DialogueManager.register_ui(self)


func _exit_tree() -> void:
	DialogueManager.unregister_ui(self)


# --- API que consume DialogueManager --------------------------------------
func show_line(line: DialogueLine) -> void:
	_choosing = false
	_clear_choices()
	_panel.show()

	_name_label.text = line.speaker
	_name_label.visible = not line.speaker.is_empty()
	if line.portrait:
		_portrait.texture = line.portrait
		_portrait.visible = true
	else:
		_portrait.visible = false

	_text_label.text = line.text
	_start_reveal()


func show_choices(labels: Array) -> void:
	_choosing = true
	_continue_hint.visible = false
	_clear_choices()
	for i in labels.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index := i
		b.pressed.connect(func() -> void: _on_choice_pressed(index))
		_choices_box.add_child(b)
	if _choices_box.get_child_count() > 0:
		(_choices_box.get_child(0) as Button).grab_focus()


func hide_dialogue() -> void:
	_choosing = false
	_revealing = false
	_kill_tween()
	_clear_choices()
	if _panel:
		_panel.hide()


# --- Máquina de escribir --------------------------------------------------
func _start_reveal() -> void:
	_kill_tween()
	_continue_hint.visible = false
	var total := _text_label.get_total_character_count()
	if characters_per_second <= 0.0 or total == 0:
		_text_label.visible_ratio = 1.0
		_on_reveal_done()
		return
	_revealing = true
	_text_label.visible_ratio = 0.0
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_text_label, "visible_ratio", 1.0,
		float(total) / characters_per_second)
	_reveal_tween.finished.connect(_on_reveal_done)


func _finish_reveal() -> void:
	_kill_tween()
	_text_label.visible_ratio = 1.0
	_on_reveal_done()


func _on_reveal_done() -> void:
	_revealing = false
	if not _choosing:
		_continue_hint.visible = true


func _kill_tween() -> void:
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = null


# --- Entrada ------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _panel == null or not _panel.visible or _choosing:
		return
	if event.is_action_pressed(advance_action):
		get_viewport().set_input_as_handled()
		if _revealing:
			_finish_reveal()
		else:
			line_advanced.emit()


# --- Construcción de la interfaz -------------------------------------------
func _on_choice_pressed(index: int) -> void:
	_choosing = false
	_clear_choices()
	choice_selected.emit(index)


func _clear_choices() -> void:
	if _choices_box == null:
		return
	for c in _choices_box.get_children():
		c.queue_free()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 24
	_panel.offset_right = -24
	_panel.offset_top = -190
	_panel.offset_bottom = -24
	root.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(72, 72)
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.visible = false
	header.add_child(_portrait)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 20)
	header.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(0, 72)
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_label)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_choices_box)

	_continue_hint = Label.new()
	_continue_hint.text = "▼  " + String(advance_action).capitalize()
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(_continue_hint)
