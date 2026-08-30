extends Node
## Autoload "ShopManager" — lógica de tienda/mercado (comprar y vender).
##
## - Registra el handler "open_shop" en GameActions, así ActionOpenShop y
##   GameActions.run(&"open_shop", ...) funcionan sin configurar nada.
## - Las REGLAS (dinero, stock, límites de bolsa) viven aquí; la ShopUI solo
##   pinta y llama a try_buy()/try_sell().
## - Sin UI registrada, open() abre y cierra al instante (útil en tests).

signal opened(shop: ShopData)
signal closed(shop: ShopData)
signal bought(item_id: StringName, quantity: int, total: int)
signal sold(item_id: StringName, quantity: int, total: int)
signal transaction_failed(reason: StringName)

const SCAN_DIRS := ["res://data/shops"]

var current_shop: ShopData = null
var is_open: bool = false

var _ui: Node = null
var _shops: Dictionary = {}   # StringName -> ShopData


func _ready() -> void:
	GameActions.register(&"open_shop", _on_open_shop_action)
	for dir in SCAN_DIRS:
		_load_shop_dir(dir)


# --- Registro de UI y de tiendas ------------------------------------------
func register_ui(ui: Node) -> void:
	_ui = ui


func unregister_ui(ui: Node) -> void:
	if _ui == ui:
		_ui = null


func register_shop(shop: ShopData) -> void:
	if shop and shop.id != &"":
		_shops[shop.id] = shop


func get_shop(id: StringName) -> ShopData:
	return _shops.get(id)


# --- Apertura --------------------------------------------------------------
func _on_open_shop_action(params: Dictionary) -> void:
	var shop: ShopData = params.get("shop")
	if shop == null:
		shop = get_shop(params.get("shop_id", &""))
	if shop == null:
		push_warning("ShopManager: no se encontró la tienda '%s'" % params.get("shop_id"))
		return
	await open(shop)


func open(shop: ShopData) -> void:
	if shop == null or is_open:
		return
	current_shop = shop
	is_open = true
	opened.emit(shop)
	EventBus.shop_opened.emit(shop.id)
	EventBus.gameplay_input_locked.emit(true)

	if _ui and _ui.has_method(&"open_shop"):
		_ui.open_shop(shop)
		await _ui.shop_closed

	EventBus.gameplay_input_locked.emit(false)
	is_open = false
	var closed_shop := current_shop
	current_shop = null
	closed.emit(closed_shop)
	EventBus.shop_closed.emit(closed_shop.id)


# --- Transacciones ------------------------------------------------------
## Devuelve { ok: bool, reason: StringName, quantity: int, total: int }.
func try_buy(entry: ShopEntry, quantity: int) -> Dictionary:
	if entry == null or not entry.is_available() or entry.item == null:
		return _fail(&"no_disponible")
	quantity = maxi(1, quantity)

	var unit := entry.price()
	var room := Inventory.room_for(entry.item.id, quantity)
	if room <= 0:
		return _fail(&"bolsa_llena")
	quantity = mini(quantity, room)
	if entry.stock > 0:
		quantity = mini(quantity, entry.stock)

	var total := unit * quantity
	if not Inventory.can_afford(total):
		return _fail(&"sin_dinero")

	Inventory.spend_money(total)
	Inventory.add_item(entry.item.id, quantity)
	if entry.stock > 0:
		entry.stock -= quantity

	bought.emit(entry.item.id, quantity, total)
	EventBus.item_bought.emit(entry.item.id, quantity, total)
	return {"ok": true, "reason": &"", "quantity": quantity, "total": total}


func try_sell(item_id: StringName, quantity: int) -> Dictionary:
	if current_shop == null or not current_shop.buys_from_player:
		return _fail(&"no_compra")
	var item := ItemDatabase.get_item(item_id)
	if item == null or not item.can_be_sold():
		return _fail(&"no_vendible")
	quantity = clampi(quantity, 1, Inventory.count(item_id))
	if quantity <= 0:
		return _fail(&"no_tienes")

	var unit := int(round(item.get_sell_price() * current_shop.sell_multiplier))
	var total := unit * quantity
	Inventory.remove_item(item_id, quantity)
	Inventory.add_money(total)

	sold.emit(item_id, quantity, total)
	EventBus.item_sold.emit(item_id, quantity, total)
	return {"ok": true, "reason": &"", "quantity": quantity, "total": total}


## Precio de venta unitario real en la tienda actual (para pintar en la UI).
func sell_unit_price(item_id: StringName) -> int:
	var item := ItemDatabase.get_item(item_id)
	if item == null or current_shop == null:
		return 0
	return int(round(item.get_sell_price() * current_shop.sell_multiplier))


func _fail(reason: StringName) -> Dictionary:
	transaction_failed.emit(reason)
	return {"ok": false, "reason": reason, "quantity": 0, "total": 0}


func _load_shop_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and (file.ends_with(".tres") or file.ends_with(".res")):
			var res: Resource = load(path.path_join(file))
			if res is ShopData:
				register_shop(res)
		file = dir.get_next()
	dir.list_dir_end()
