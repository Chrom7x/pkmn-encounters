class_name ShopData
extends Resource
## Una tienda / mercado (tienda del pueblo, Poké Mart, mercadillo, gran almacén...).
## Crea un .tres, arrástrale entradas ShopEntry y regístrala (ShopManager la
## carga sola desde data/shops/ o la añades con ShopManager.register_shop()).

@export var id: StringName = &""
@export var display_name: String = "Tienda"
@export_multiline var greeting: String = "¡Bienvenido! ¿En qué puedo ayudarte?"
@export_multiline var farewell: String = "¡Gracias por tu compra! Vuelve pronto."

@export var stock: Array[ShopEntry] = []

@export_group("Compra al jugador")
## ¿La tienda acepta que el jugador venda objetos?
@export var buys_from_player: bool = true
## Multiplicador sobre el precio de venta base del objeto (1.0 = normal).
@export_range(0.0, 2.0, 0.05) var sell_multiplier: float = 1.0


## Entradas visibles ahora mismo (filtradas por stock y flags).
func available_entries() -> Array[ShopEntry]:
	var out: Array[ShopEntry] = []
	for e in stock:
		if e and e.is_available():
			out.append(e)
	return out
