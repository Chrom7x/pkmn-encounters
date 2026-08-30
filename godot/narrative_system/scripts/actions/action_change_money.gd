class_name ActionChangeMoney
extends GameAction
## Suma o resta dinero al jugador (premio, soborno, peaje, propina...).

## Positivo suma, negativo resta. Nunca baja de 0.
@export var amount: int = 0


func execute(_ctx: ActionContext) -> void:
	if amount != 0:
		Inventory.add_money(amount)
