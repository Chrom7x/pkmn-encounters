class_name ItemData
extends Resource
## Definición de un objeto. Crea un .tres por objeto en data/items/ y edítalo en
## el inspector. ItemDatabase los carga solos al arrancar.

enum Category {
	MEDICINE,      ## Pociones, antídotos, revivir...
	POKEBALLS,     ## Poké Ball, Super Ball...
	BATTLE_ITEMS,  ## Objetos de combate (X Ataque, etc.)
	BERRIES,       ## Bayas
	TMS,           ## MT/MO
	KEY_ITEMS,     ## Objetos clave (no se venden ni tiran)
	OTHER,
}

const CATEGORY_NAMES := {
	Category.MEDICINE: "Pociones", Category.POKEBALLS: "Poké Balls",
	Category.BATTLE_ITEMS: "Combate", Category.BERRIES: "Bayas",
	Category.TMS: "MT/MO", Category.KEY_ITEMS: "Objetos clave",
	Category.OTHER: "Otros",
}

@export var id: StringName = &""
@export var display_name: String = "Objeto"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.OTHER

@export_group("Economía")
## Precio de compra en tienda. 0 = no se vende en tiendas normales.
@export var buy_price: int = 0
## Precio de venta. -1 = automático (buy_price / 2).
@export var sell_price: int = -1
## Máximo que se puede acumular de este objeto en la bolsa.
@export var max_stack: int = 99

@export_group("Uso")
@export var consumable: bool = true
@export var usable_in_field: bool = false
@export var usable_in_battle: bool = false
@export var key_item: bool = false
## Acción registrada en GameActions al usar el objeto (la implementa el sistema
## de equipo/combate). Recibe {"item_id", "target", ...}.
@export var use_action_id: StringName = &""


func get_sell_price() -> int:
	if key_item:
		return 0
	if sell_price >= 0:
		return sell_price
	return int(buy_price / 2.0)


func can_be_sold() -> bool:
	return not key_item and get_sell_price() > 0


func category_name() -> String:
	return CATEGORY_NAMES.get(category, "Otros")
