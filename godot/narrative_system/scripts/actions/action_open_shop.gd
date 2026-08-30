class_name ActionOpenShop
extends GameAction
## EJEMPLO de acción de juego: abrir una tienda (comprar/vender).
## Delega en el handler "open_shop". Espera a que la tienda se cierre.

@export var shop_id: StringName = &"default"


func execute(_ctx: ActionContext) -> void:
	await GameActions.run(&"open_shop", {"shop_id": shop_id})
