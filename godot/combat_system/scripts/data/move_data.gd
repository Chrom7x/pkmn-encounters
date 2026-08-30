class_name MoveData
extends Resource
## Definición modular de un ataque/habilidad. Crea un .tres por movimiento y
## edítalo en el inspector.
##
## Reglas del enunciado:
##  - `type`: UN único tipo elemental por movimiento.
##  - `category`: Físico o Especial (STATUS para movimientos de apoyo sin daño).
##  - El daño escala con Ataque/At. Esp. del atacante y se mitiga con
##    Defensa/Def. Esp. del objetivo según `category` (ver DamageCalculator).

enum Category { PHYSICAL, SPECIAL, STATUS }
enum Target { SINGLE_ENEMY, SELF, ALL_ENEMIES, ALLY, FIELD }

const CATEGORY_NAMES := {
	Category.PHYSICAL: "Físico",
	Category.SPECIAL: "Especial",
	Category.STATUS: "Estado",
}

@export var display_name: String = "Nuevo movimiento"
@export_multiline var description: String = ""

@export_group("Clasificación")
## Único tipo principal del movimiento.
@export var type: PokeTypes.Type = PokeTypes.Type.NORMAL
## Físico -> usa Ataque/Defensa. Especial -> usa At. Esp./Def. Esp.
@export var category: Category = Category.PHYSICAL
@export var target: Target = Target.SINGLE_ENEMY

@export_group("Números")
@export_range(0, 250) var power: int = 40          ## 0 = movimiento sin daño
@export_range(0, 100) var accuracy: int = 100      ## 0 = nunca falla
@export_range(1, 40) var max_pp: int = 20
@export_range(-7, 5) var priority: int = 0
@export var makes_contact: bool = true
## +1 en la escala de crítico (movimientos tipo "Cuchillada").
@export var high_crit_ratio: bool = false

@export_group("Efecto secundario")
@export var effect: MoveEffect
@export_range(0, 100) var effect_chance: int = 100  ## probabilidad de que ocurra


## ¿Este movimiento inflige daño directo?
func is_damaging() -> bool:
	return category != Category.STATUS and power > 0


## ¿Escala con Ataque físico (true) o con Ataque Especial (false)?
func uses_physical() -> bool:
	return category == Category.PHYSICAL


func category_name() -> String:
	return CATEGORY_NAMES.get(category, "???")
