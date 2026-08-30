class_name ActionOpenShop
extends GameAction
## Abre una tienda (comprar/vender) y espera a que el jugador la cierre.
## Ejemplo: opción de diálogo "Ver productos" del dependiente del Poké Mart.

## Arrastra aquí el recurso ShopData de la tienda...
@export var shop: ShopData
## ...o, si la tienda está registrada en ShopManager, indica solo su id.
@export var shop_id: StringName = &""


func execute(_ctx: ActionContext) -> void:
	if shop:
		await ShopManager.open(shop)
	elif shop_id != &"":
		await GameActions.run(&"open_shop", {"shop_id": shop_id})
