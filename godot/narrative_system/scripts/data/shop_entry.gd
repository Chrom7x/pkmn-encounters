class_name ShopEntry
extends Resource
## Una línea del catálogo de una tienda: qué objeto vende, a qué precio y con
## qué límite/condición.

@export var item: ItemData
## 0 = usar item.buy_price. > 0 = precio propio de esta tienda (ofertas, etc.).
@export var price_override: int = 0
## Unidades disponibles. -1 = ilimitado. 0 = agotado.
@export var stock: int = -1
## Solo aparece en el catálogo si este flag está activo ("" = siempre).
@export var require_flag: StringName = &""


func price() -> int:
	if price_override > 0:
		return price_override
	return item.buy_price if item else 0


func is_available() -> bool:
	if item == null or stock == 0:
		return false
	if require_flag != &"" and not Flags.has_flag(require_flag):
		return false
	return true
