# Tienda / Mercado + Centro Pokémon

Extensión del [sistema narrativo](NARRATIVE.md): inventario, dinero, tiendas
(comprar/vender) y la máquina de curar del Centro Pokémon. Mismo principio:
**todo desacoplado** vía `EventBus` / `GameActions`, y los datos son `Resource`.

## Autoloads nuevos

| Autoload | Rol |
|---|---|
| `ItemDatabase` | catálogo `id → ItemData`. Escanea `res://data/items/` al arrancar; `register()` a mano también. |
| `Inventory` | dinero + bolsa del jugador. Señales `money_changed`, `item_changed`. `to_dict()`/`from_dict()` para guardado. |
| `ShopManager` | reglas de compra/venta. Registra el handler `open_shop`. Escanea `res://data/shops/`. |

Orden en `project.godot`: `EventBus, Flags, ItemDatabase, GameActions, Inventory,
ShopManager, DialogueManager, CutsceneManager`.

## Recursos

### `ItemData` (`scripts/data/item_data.gd`)

`id`, `display_name`, `description`, `icon`, `category` (MEDICINE, POKEBALLS,
BATTLE_ITEMS, BERRIES, TMS, KEY_ITEMS, OTHER), `buy_price`, `sell_price`
(-1 = automático, la mitad), `max_stack`, `consumable`, `usable_in_field`,
`usable_in_battle`, `key_item`, `use_action_id` (acción de GameActions que
ejecuta tu sistema de combate al usar el objeto — desacople).

Hay 6 objetos de ejemplo en `data/items/`: Poción, Superpoción, Poké Ball,
Super Ball, Antídoto, Revivir.

### `ShopData` (`scripts/data/shop_data.gd`) + `ShopEntry`

`ShopData`: `id`, `display_name`, `greeting`, `farewell`,
`stock: Array[ShopEntry]`, `buys_from_player`, `sell_multiplier`.

`ShopEntry`: `item: ItemData`, `price_override` (0 = usa `buy_price`),
`stock` (-1 = ilimitado), `require_flag` (aparece solo si el flag está activo →
ofertas por progreso de historia, tienda que crece con las medallas, etc.).

## Flujo de la tienda

```
ActionOpenShop / GameActions.run("open_shop", {shop | shop_id})
  └─ ShopManager.open(shop)
       EventBus.shop_opened + gameplay_input_locked(true)
       ShopUI.open_shop(shop)          # menú Comprar / Vender / Salir
         Comprar → lista de ShopEntry disponibles → selector de cantidad
                   → ShopManager.try_buy(entry, qty)
         Vender  → objetos vendibles de la bolsa → cantidad
                   → ShopManager.try_sell(item_id, qty)
       await ShopUI.shop_closed
       EventBus.shop_closed + gameplay_input_locked(false)
```

`try_buy` / `try_sell` devuelven `{ ok, reason, quantity, total }` y aplican
todo: comprueban dinero (`Inventory.can_afford`), hueco en la bolsa
(`Inventory.room_for`, respeta `max_stack`), stock de la tienda, objetos clave
no vendibles, y emiten `EventBus.item_bought` / `item_sold`.

La `ShopUI` es "tonta" (solo pinta y llama a esos métodos) y **reemplazable**:
crea un nodo con `func open_shop(shop)` + `signal shop_closed` y llama a
`ShopManager.register_ui(self)`. Sin UI, `open()` abre y cierra al instante.

## Comprar desde un diálogo (el patrón normal)

El dependiente es un `Interactable` con un `DialogueData`:

```
Dependiente: "¿Quieres ver la tienda?"
  ├─ "Ver productos"  → actions: [ ActionOpenShop(shop = mart.tres) ]
  └─ "Ahora no"       → (sin acciones: cierra el diálogo)
```

Añadir una tienda nueva = crear un `ShopData.tres` con sus `ShopEntry` y
arrastrarlo a un `ActionOpenShop`. Cero código.

### Otras acciones de economía

| Acción | Qué hace |
|---|---|
| `ActionOpenShop` | abre una tienda (`shop` o `shop_id`) |
| `ActionGiveItem` | da o quita objetos (`item_id`, `quantity`, `remove`) — recompensas, objetos de historia |
| `ActionChangeMoney` | suma/resta dinero (`amount`) — premios, peajes |

## Centro Pokémon

`HealingStation` (`scripts/economy/healing_station.gd`) — nodo que pones en la
escena del Centro (o como autoload propio). Registra el handler `heal_party`:

```
heal_party
  └─ EventBus.party_heal_started
     await (animación de la máquina, `heal_duration` s)
     GameActions.run("party_restore")     # ← tu sistema de equipo lo implementa
     EventBus.party_healed
```

La restauración concreta de PS/PP/estados la aporta **tu** proyecto de combate,
registrando `party_restore` o escuchando `EventBus.party_healed`. Así el Centro
no depende del sistema de equipo.

El diálogo de la Enfermera Joy es un `DialogueData` normal cuya opción "Sí"
lleva `actions: [ ActionHealParty ]` (que llama a `heal_party`).

## Estructura de nodos

```
CentroPokemon (Node2D)
├── HealingStation                     # scripts/economy/healing_station.gd
├── EnfermeraJoy (StaticBody2D)
│   └── Interactable (Area2D)          # dialogue = enfermera.tres
│       └── CollisionShape2D
PokeMart (Node2D)
└── Dependiente (StaticBody2D)
    └── Interactable (Area2D)          # dialogue = dependiente.tres  (opción → ActionOpenShop)
        └── CollisionShape2D
Main
├── DialogueUI (CanvasLayer)
└── ShopUI (CanvasLayer)               # scripts/ui/shop_ui.gd  (se auto-registra)
```

## Ejemplo

`examples/demo_shop.gd` — `Node2D` + este script + F6. Registra un
`party_restore` de mentira, cura en el Centro y luego abre el Poké Mart de
Ciudad Verde (5 productos) para comprar y vender. Imprime dinero y bolsa al
final.

## Guardado

`Inventory.to_dict()` / `from_dict()` — `{ money, bag }`.
`Flags.to_dict()` / `from_dict()` para el estado (`require_flag` de ofertas,
"ya visité el Centro", etc.).
