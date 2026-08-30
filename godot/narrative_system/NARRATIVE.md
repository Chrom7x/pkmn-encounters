# Sistema de Diálogos + Cinemáticas (Godot 4 / GDScript)

Arquitectura modular y **desacoplada** para diálogos con decisiones y un
*sequencer* de cinemáticas/eventos. GDScript puro, sin dependencias.

> **Tienda / Mercado y Centro Pokémon:** están documentados aparte en
> [ECONOMY.md](ECONOMY.md) (inventario, dinero, comprar/vender, máquina de
> curar). Se apoyan en la misma arquitectura de abajo.

## Idea central: nadie se conoce a nadie

Los autoloads hacen de intermediarios; los sistemas de juego (equipo, tienda,
mapa, cámara) hablan **solo** con ellos:

| Autoload | Rol | Cómo lo usan los sistemas de juego |
|---|---|---|
| `EventBus` | Señales globales + canal genérico `game_event(id, payload)` | `EventBus.game_event.connect(...)` y filtran por `id` |
| `Flags` | Estado del juego (interruptores/valores) + `flag_changed` | `Flags.set_flag(&"badge_1")`, `Flags.has_flag(...)` |
| `GameActions` | Registro `id -> Callable` (sync o async) | `GameActions.register(&"heal_party", _handler)` |
| `DialogueManager` | Reproduce un `DialogueData`, devuelve `DialogueResult` | `await DialogueManager.start(data)` |
| `CutsceneManager` | Ejecuta una `Cutscene` paso a paso con `await` | `await CutsceneManager.play(cutscene, ctx)` |
| `ItemDatabase` · `Inventory` · `ShopManager` | Objetos, dinero y tiendas | ver [ECONOMY.md](ECONOMY.md) |

Añadir una interacción/tienda/respuesta nueva = **crear un `Resource`** o
**registrar un handler**. La lógica base no se toca.

## Instalación

1. Copia `autoload/`, `scripts/` y `data/` a tu proyecto.
2. Proyecto → Ajustes → Autoload, en este orden: `EventBus`, `Flags`,
   `ItemDatabase`, `GameActions`, `Inventory`, `ShopManager`, `DialogueManager`,
   `CutsceneManager` (ya está en el `project.godot` de esta carpeta).
3. Añade un nodo con `scripts/ui/dialogue_ui.gd` a tu escena principal (se
   registra solo). O usa tu propia UI (ver más abajo).
4. Las acciones de entrada `interact` y `cutscene_skip` se crean solas si no
   existen (teclas E / Enter / Espacio y Esc).

## Diálogos y decisiones

### Recursos (`scripts/data/`)

| Recurso | Campos clave |
|---|---|
| `DialogueData` | `id`, `lines: Array[DialogueLine]`, `next: DialogueData` |
| `DialogueLine` | `speaker`, `text`, `portrait`, `choices: Array[DialogueChoice]`, `auto_advance_delay`, `on_show_event` |
| `DialogueChoice` | `id`, `text`, `required_flags`/`forbidden_flags`, `custom_condition`, **`actions: Array[GameAction]`**, `next: DialogueData` |
| `DialogueCondition` (+ `ConditionFlagValue`) | condición programable reutilizable; sobrescribe `_evaluate()` |
| `DialogueResult` | `choice_id`, `choice_index`, `history`, `data` — lo devuelve `start()` |

### Flujo

```
start(data)
 └─ por cada línea:
      mostrar (UI o auto) ─ await avance
      ¿la línea tiene choices disponibles?
        sí → mostrar opciones ─ await selección
             ejecutar choice.actions (await de las async)
             saltar a choice.next  (o terminar si es null)
        no → siguiente línea
 └─ sin decisión con rama → seguir por data.next
 └─ devolver DialogueResult, emitir EventBus.dialogue_finished
```

### Acciones (`scripts/actions/`)

`GameAction` base con `execute(ctx: ActionContext)` (puede ser `async`).

| Genéricas | Qué hacen |
|---|---|
| `ActionEmitEvent` | `EventBus.dispatch(event, payload)` — avisar y seguir |
| `ActionRunId` | `await GameActions.run(id, params)` — llamar y esperar retorno |
| `ActionSetFlag` | `Flags.set_flag(flag, value)` — recordar la decisión |
| `ActionStartDialogue` | encadenar otra conversación |
| `ActionStartCutscene` | lanzar una cinemática (p. ej. animación de Vuelo) |
| `ActionWait` | pausa N segundos |

| Ejemplos de juego (envolturas finas) | Delegan en |
|---|---|
| `ActionHealParty` | `GameActions.run(&"heal_party", …)` — Centro Pokémon |
| `ActionOpenShop` | abre una `ShopData` (o `shop_id`) — ver [ECONOMY.md](ECONOMY.md) |
| `ActionTeleport` | `GameActions.run(&"teleport_player", {destination_id/position})` |
| `ActionGiveItem` | `Inventory.add_item` / `remove_item` — recompensas, objetos de historia |
| `ActionChangeMoney` | `Inventory.add_money(amount)` — premios, peajes |

**"Rechazar" no necesita código:** una opción sin `actions` y sin `next`
simplemente cierra el diálogo.

## Cinemáticas / Sequencer

### Recursos (`scripts/cutscene/`)

- `Cutscene` — `id`, `steps: Array[CutsceneStep]`, `lock_input`.
- `CutsceneStep` (base) — `run(ctx: CutsceneContext)` sobrescribible y `async`.
- `CutsceneContext` (RefCounted) — `actors` (por nombre), `markers`, `camera`,
  `data` (scratch), `skipping`. Lo rellena quien lanza la cinemática.
- `SignalBarrier` — utilidad para esperar N corrutinas (usada por `StepParallel`).

### Pasos incluidos (`scripts/cutscene/steps/`)

| Paso | Acción | Espera a… |
|---|---|---|
| `StepWait` | pausa | timer |
| `StepMoveActor` | tween de un actor a marcador/posición | `tween.finished` |
| `StepMoveCamera` | tween de posición + zoom de la cámara | `tween.finished` |
| `StepPlayAnimation` | `AnimationPlayer.play()` | `animation_finished` (opcional) |
| `StepDialogue` | lanza un `DialogueData` **y espera la respuesta** | `DialogueManager.start` |
| `StepAction` | ejecuta una `GameAction` cualquiera | la acción (opcional) |
| `StepEmitEvent` | `EventBus.dispatch` sin crear recurso | — |
| `StepBranch` | reproduce una sub-`Cutscene` u otra según flag / `ctx.data` | la rama elegida |
| `StepParallel` | corre varios sub-pasos a la vez | todos (`SignalBarrier`) |

### Flujo

```
play(cutscene, ctx)
 └─ (nivel superior) EventBus.cutscene_started + gameplay_input_locked(true)
 └─ por cada step:  await step.run(ctx)
 └─ (nivel superior) gameplay_input_locked(false) + EventBus.cutscene_finished
```

`Esc` (`cutscene_skip`) pone `ctx.skipping = true`; cada paso decide cómo
acortar (ir al estado final sin tween).

## Interacción en el mundo (`scripts/world/`)

- `Interactable` (`Area2D`) — arrástrale un `DialogueData` **o** una `Cutscene`.
  `one_shot`, `require_flag`, `set_flag_on_finish`, `context`.
- `Interactor` (`Area2D`, en el jugador) — detecta el `Interactable` más
  cercano y al pulsar `interact` llama a `interact()`. Se desactiva solo
  mientras hay diálogo/cinemática o `gameplay_input_locked`.

## Estructura de nodos recomendada

```
Main (Node2D)
├── World
│   ├── Player (CharacterBody2D)
│   │   ├── AnimationPlayer
│   │   └── Interactor (Area2D)          # scripts/world/interactor.gd
│   │       └── CollisionShape2D
│   ├── NurseJoy (StaticBody2D)
│   │   └── Interactable (Area2D)        # scripts/world/interactable.gd  (dialogue = centro.tres)
│   │       └── CollisionShape2D
│   └── Markers (Node2D)
│       ├── FrenteMostrador (Marker2D)
│       └── CamaraCine (Marker2D)
├── Camera2D                              # cámara del jugador
├── CineCamera (Camera2D)                 # cámara de cinemáticas (se activa al empezar)
└── DialogueUI (CanvasLayer)              # scripts/ui/dialogue_ui.gd  (se auto-registra)
```

Autoloads (invisibles): `EventBus`, `Flags`, `GameActions`, `DialogueManager`,
`CutsceneManager`.

## Usar tu propia interfaz

`DialogueUI` es reemplazable. Crea un nodo con:

```gdscript
signal line_advanced
signal choice_selected(index: int)
func show_line(line: DialogueLine) -> void
func show_choices(labels: Array) -> void
func hide_dialogue() -> void
```

y llama a `DialogueManager.register_ui(self)` en `_ready()`. Sin UI registrada,
el manager resuelve el diálogo solo (tests / modo rápido).

## Ejemplo

`examples/demo_narrative.gd` — escena `Node2D` + este script + F6. Registra los
handlers (`heal_party`, `open_shop`, `teleport_player`), reproduce una cinemática
(cámara → andar → diálogo del Centro con Sí/No → rama de confeti si aceptó) y
después un menú de Vuelo con `ActionTeleport`. Todo construido por código para
que sea 100 % reproducible; en tu juego harías los `.tres` en el inspector.

## Puntos de extensión (sin tocar la base)

- **Nueva respuesta / rama:** otro `DialogueChoice` con sus `actions`.
- **Nueva acción de juego:** `GameActions.register(&"mi_id", handler)` +
  `ActionRunId` (o una subclase de 5 líneas de `GameAction`).
- **Nuevo tipo de paso:** subclase de `CutsceneStep` con su `run()`.
- **Nueva condición:** subclase de `DialogueCondition`.
- **Nuevo sistema que reacciona a la narrativa:** conéctate a `EventBus`.
