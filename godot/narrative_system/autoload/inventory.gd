extends Node
## Autoload "Inventory" — dinero y bolsa del jugador.
##
## No sabe nada de tiendas ni de diálogos: es un almacén con señales. La tienda
## (ShopManager) y las acciones (ActionGiveItem, ActionChangeMoney) lo usan.

signal money_changed(amount: int)
## Se emite al cambiar la cantidad de un objeto. count == 0 => se agotó.
signal item_changed(item_id: StringName, count: int)

const DEFAULT_MAX_STACK := 99

@export var starting_money: int = 3000

var money: int = 0
var _bag: Dictionary = {}   # StringName -> int (cantidad)


func _ready() -> void:
	money = maxi(0, starting_money)


# --- Dinero -----------------------------------------------------------------
func can_afford(cost: int) -> bool:
	return money >= cost


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)
	EventBus.money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if amount < 0 or amount > money:
		return false
	money -= amount
	money_changed.emit(money)
	EventBus.money_changed.emit(money)
	return true


# --- Objetos --------------------------------------------------------------
func count(item_id: StringName) -> int:
	return _bag.get(item_id, 0)


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return count(item_id) >= quantity


## Espacio libre para `wanted` unidades de un objeto (respeta max_stack).
func room_for(item_id: StringName, wanted: int) -> int:
	var item := ItemDatabase.get_item(item_id)
	var cap := item.max_stack if item else DEFAULT_MAX_STACK
	return clampi(wanted, 0, maxi(0, cap - count(item_id)))


## Añade objetos. Devuelve cuántos se pudieron añadir (puede ser < quantity si
## la bolsa está a tope).
func add_item(item_id: StringName, quantity: int = 1) -> int:
	if item_id == &"" or quantity <= 0:
		return 0
	var added := room_for(item_id, quantity)
	if added > 0:
		_bag[item_id] = count(item_id) + added
		item_changed.emit(item_id, _bag[item_id])
	return added


## Quita objetos. Devuelve true si había suficientes.
func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	var current := count(item_id)
	if quantity <= 0 or current < quantity:
		return false
	var left := current - quantity
	if left <= 0:
		_bag.erase(item_id)
	else:
		_bag[item_id] = left
	item_changed.emit(item_id, left)
	return true


## Lista [{id, count, data}] de una categoría (o de toda la bolsa si cat < 0).
func entries(category: int = -1) -> Array:
	var out: Array = []
	for id in _bag:
		var data: ItemData = ItemDatabase.get_item(id)
		if category >= 0 and (data == null or data.category != category):
			continue
		out.append({"id": id, "count": _bag[id], "data": data})
	return out


# --- Guardado --------------------------------------------------------------
func to_dict() -> Dictionary:
	return {"money": money, "bag": _bag.duplicate()}


func from_dict(d: Dictionary) -> void:
	money = int(d.get("money", starting_money))
	_bag = (d.get("bag", {}) as Dictionary).duplicate()
	money_changed.emit(money)
