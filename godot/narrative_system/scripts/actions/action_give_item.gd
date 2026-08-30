class_name ActionGiveItem
extends GameAction
## Da (o quita) objetos al jugador. Sirve para recompensas de NPC, objetos de
## historia, o para descontar en una compra scripteada.

@export var item_id: StringName = &""
@export var quantity: int = 1
## true = quitar en vez de dar.
@export var remove: bool = false
## Si se indica, guarda en ctx.data[esta_clave] cuántas unidades se movieron.
@export var store_result_key: StringName = &""


func execute(ctx: ActionContext) -> void:
	if item_id == &"" or quantity <= 0:
		return
	var moved := 0
	if remove:
		moved = quantity if Inventory.remove_item(item_id, quantity) else 0
	else:
		moved = Inventory.add_item(item_id, quantity)
	if store_result_key != &"":
		ctx.data[store_result_key] = moved
