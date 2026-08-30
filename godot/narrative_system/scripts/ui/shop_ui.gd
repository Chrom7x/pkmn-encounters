class_name ShopUI
extends CanvasLayer
## Interfaz de tienda por defecto (Comprar / Vender / Salir). Construida por
## código: no necesita escena. SE REGISTRA SOLA con ShopManager.
##
## Es "tonta": solo pinta y llama a ShopManager.try_buy() / try_sell(); las
## reglas (dinero, stock, límite de bolsa) están en ShopManager. Para usar tu
## propia UI, crea un nodo con:
##   func open_shop(shop: ShopData) -> void
##   signal shop_closed
## y llama a ShopManager.register_ui(self) en _ready().

signal shop_closed

enum State { MAIN, BUY, SELL, QUANTITY }

var _shop: ShopData
var _state: int = State.MAIN

# Estado del selector de cantidad
var _qty: int = 1
var _qty_max: int = 1
var _buying: bool = true
var _cur_entry: ShopEntry
var _cur_item_id: StringName = &""

# Nodos
var _root: Control
var _money_label: Label
var _title: Label
var _list: VBoxContainer
var _info: Label
var _qty_bar: HBoxContainer
var _qty_label: Label
var _total_label: Label


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()
	Inventory.money_changed.connect(_on_money_changed)
	ShopManager.register_ui(self)


func _exit_tree() -> void:
	ShopManager.unregister_ui(self)


# --- API que consume ShopManager ---------------------------------------
func open_shop(shop: ShopData) -> void:
	_shop = shop
	_root.show()
	_on_money_changed(Inventory.money)
	_go_main()


# --- Estados ------------------------------------------------------------
func _go_main() -> void:
	_state = State.MAIN
	_hide_qty()
	_title.text = _shop.display_name
	_info.text = _shop.greeting
	_clear_list()
	_add_button("Comprar", _go_buy)
	if _shop.buys_from_player:
		_add_button("Vender", _go_sell)
	_add_button("Salir", _close)
	_focus_first()


func _go_buy() -> void:
	_state = State.BUY
	_hide_qty()
	_title.text = "Comprar"
	_clear_list()
	var entries := _shop.available_entries()
	if entries.is_empty():
		_info.text = "No hay nada a la venta ahora mismo."
	for e in entries:
		var entry := e
		_add_button("%s%s%d₽" % [entry.item.display_name, _pad(entry.item.display_name), entry.price()],
			func() -> void: _begin_quantity(true, entry, &""))
	_add_button("Volver", _go_main)
	_focus_first()


func _go_sell() -> void:
	_state = State.SELL
	_hide_qty()
	_title.text = "Vender"
	_clear_list()
	var sellables := 0
	for it in Inventory.entries():
		var data: ItemData = it["data"]
		if data == null or not data.can_be_sold():
			continue
		sellables += 1
		var id: StringName = it["id"]
		var n: int = it["count"]
		_add_button("%s%sx%d   %d₽" % [data.display_name, _pad(data.display_name), n, ShopManager.sell_unit_price(id)],
			func() -> void: _begin_quantity(false, null, id))
	if sellables == 0:
		_info.text = "No tienes nada que pueda comprarte."
	_add_button("Volver", _go_main)
	_focus_first()


func _begin_quantity(buying: bool, entry: ShopEntry, item_id: StringName) -> void:
	_buying = buying
	_cur_entry = entry
	_cur_item_id = item_id
	_qty = 1

	if buying:
		var unit: int = entry.price()
		var by_money: int = 99 if unit <= 0 else int(Inventory.money / float(unit))
		var by_room: int = Inventory.room_for(entry.item.id, 99)
		var by_stock: int = 99 if entry.stock < 0 else entry.stock
		_qty_max = clampi(mini(by_money, mini(by_room, by_stock)), 0, 99)
		if _qty_max <= 0:
			_info.text = "No puedes comprar más (dinero o espacio)."
			return
	else:
		_qty_max = Inventory.count(item_id)
		if _qty_max <= 0:
			return

	_state = State.QUANTITY
	_qty_bar.show()
	_update_qty()
	(_qty_bar.get_node("Accept") as Button).grab_focus()


func _update_qty() -> void:
	_qty = clampi(_qty, 1, maxi(1, _qty_max))
	_qty_label.text = "x%d" % _qty
	var unit := _cur_entry.price() if _buying else ShopManager.sell_unit_price(_cur_item_id)
	_total_label.text = "%d₽" % (unit * _qty)


func _confirm_quantity() -> void:
	var result: Dictionary
	if _buying:
		result = ShopManager.try_buy(_cur_entry, _qty)
	else:
		result = ShopManager.try_sell(_cur_item_id, _qty)

	_info.text = _result_text(result)
	_hide_qty()
	if _buying:
		_go_buy()
	else:
		_go_sell()


func _result_text(r: Dictionary) -> String:
	if r.get("ok", false):
		if _buying:
			return "Aquí tienes. Has comprado %d." % r["quantity"]
		return "Vendido: %d por %d₽." % [r["quantity"], r["total"]]
	match String(r.get("reason", "")):
		"sin_dinero": return "No tienes suficiente dinero."
		"bolsa_llena": return "No te cabe en la bolsa."
		"no_disponible": return "Eso no está a la venta."
		"no_compra": return "Aquí no compramos objetos."
		"no_vendible": return "No puedo comprarte eso."
		"no_tienes": return "No tienes de eso."
		_: return "No se pudo completar la operación."


func _close() -> void:
	_hide_qty()
	_root.hide()
	shop_closed.emit()


# --- Entrada -------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		match _state:
			State.QUANTITY:
				_cancel_quantity()
			State.BUY, State.SELL:
				_go_main()
			_:
				_close()


func _cancel_quantity() -> void:
	_hide_qty()
	if _buying:
		_go_buy()
	else:
		_go_sell()


# --- Construcción de la UI --------------------------------------------
func _on_money_changed(amount: int) -> void:
	if _money_label:
		_money_label.text = "Dinero: %d₽" % amount


func _hide_qty() -> void:
	if _qty_bar:
		_qty_bar.hide()


func _clear_list() -> void:
	for c in _list.get_children():
		c.queue_free()


func _add_button(text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(on_pressed)
	_list.add_child(b)


func _focus_first() -> void:
	await get_tree().process_frame
	for c in _list.get_children():
		if c is Button:
			(c as Button).grab_focus()
			return


func _pad(_s: String) -> String:
	return "   "   # separación simple entre nombre y precio


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_money_label = Label.new()
	_money_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_money_label.offset_left = -220
	_money_label.offset_top = 16
	_money_label.offset_right = -16
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_money_label)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 360)
	panel.offset_left = -210
	panel.offset_right = 210
	panel.offset_top = -180
	panel.offset_bottom = 180
	_root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	_qty_bar = HBoxContainer.new()
	_qty_bar.add_theme_constant_override("separation", 6)
	_qty_bar.hide()
	vbox.add_child(_qty_bar)
	_qty_bar.add_child(_make_label("Cantidad:"))
	_add_qty_button("◀", -1)
	_qty_label = _make_label("x1")
	_qty_bar.add_child(_qty_label)
	_add_qty_button("▶", 1)
	_total_label = _make_label("0₽")
	_total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qty_bar.add_child(_total_label)
	var accept := Button.new()
	accept.name = "Accept"
	accept.text = "Aceptar"
	accept.pressed.connect(_confirm_quantity)
	_qty_bar.add_child(accept)
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(_cancel_quantity)
	_qty_bar.add_child(cancel)

	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_info)


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _add_qty_button(text: String, delta: int) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(_qty_step.bind(delta))
	_qty_bar.add_child(b)


func _qty_step(delta: int) -> void:
	_qty += delta
	_update_qty()
