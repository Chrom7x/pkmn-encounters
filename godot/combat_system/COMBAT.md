# Sistema de combate (Godot 4 / GDScript)

Arquitectura modular para un fan game estilo Pokémon: tipos, clasificación
físico/especial, escalado de estadísticas, fórmula de daño y curvas de nivel.
Todo en GDScript puro, sin dependencias.

## Cómo usarlo

Abre esta carpeta con **Godot 4.3+**, o copia `scripts/` a tu proyecto. Los
scripts con `class_name` quedan disponibles globalmente al instante.

Demo por consola: crea una escena con un `Node`, adjústale `battle_demo.gd` y
ejecútala (F6).

## Ficheros

### `scripts/data/` — Recursos (`Resource`), editables en el inspector

| Script | `class_name` | Qué define |
|---|---|---|
| `poke_types.gd` | `PokeTypes` | Enum `Type` con los **18 tipos oficiales** + tabla de efectividad completa (Gen VI). Todo estático. |
| `stats.gd` | `Stats` | Enum `Id` (HP, ATK, DEF, SPA, SPD, SPE, ACC, EVA) y nombres. |
| `stat_block.gd` | `StatBlock` | Bloque de 6 stats reutilizable (base / IV / EV / rendimiento EV). |
| `status_cond.gd` | `StatusCond` | Estados: quemadura, veneno, tóxico, parálisis, sueño, congelación. |
| `growth_rate.gd` | `GrowthRate` | Las **6 curvas de EXP clásicas** (Errático, Rápido, Medio rápido, Medio lento, Lento, Fluctuante). |
| `nature.gd` | `Natures` | Las 25 naturalezas (+10 % / −10 %). |
| `move_effect.gd` | `MoveEffect` | Efecto secundario opcional de un movimiento (estado, cambio de stat, cura, retroceso). |
| `move_data.gd` | `MoveData` | **Un ataque**: 1 tipo, categoría Físico/Especial/Estado, potencia, precisión, PP, prioridad, efecto. |
| `learnset_entry.gd` | `LearnsetEntry` | Fila "a nivel N se aprende el movimiento X". |
| `species_data.gd` | `SpeciesData` | **Una especie**: nº Pokédex, 1–2 tipos, stats base, curva, EXP base, rendimiento EV, learnset. |

### `scripts/battle/` — Lógica

| Script | `class_name` | Qué hace |
|---|---|---|
| `stat_stages.gd` | `StatStages` | Multiplicadores de los stages −6…+6. |
| `stat_calculator.gd` | `StatCalculator` | Fórmula de stats Gen III+ (base, IV, EV, naturaleza). |
| `damage_result.gd` | `DamageResult` | Resultado de un ataque (daño, efectividad, crítico, fallo…). |
| `damage_calculator.gd` | `DamageCalculator` | **Fórmula de daño** Gen V+. Elige Atk/SpA según categoría, mitiga con Def/SpD, aplica STAB, tipos, crítico, quemadura y aleatorio. |
| `battler.gd` | `Battler` (`Node`) | **Instancia jugable**. Adjúntalo a un nodo. Calcula stats, gestiona PS/estados/stages, `use_move()`, `gain_exp()` y subida de nivel con aprendizaje de movimientos. |
| `experience.gd` | `Experience` | EXP y EV que se reparten al derrotar (fórmula clásica). |

## Requisitos del enunciado — dónde están

| Requisito | Implementación |
|---|---|
| Lista/enum de todos los tipos | `PokeTypes.Type` (18) + `PokeTypes.CHART` |
| 1 solo tipo por movimiento | `MoveData.type: PokeTypes.Type` (campo único) |
| Movimientos Físico vs Especial | `MoveData.Category { PHYSICAL, SPECIAL, STATUS }` |
| Daño escala con Atk físico o especial | `DamageCalculator`: `atk_id = ATK if move.uses_physical() else SPA` |
| Mitigación con Def física o especial del objetivo | `def_id = DEF if move.uses_physical() else SPD` |
| Curvas de nivel tradicionales | `GrowthRate` — las 6 fórmulas exactas de Bulbapedia |
| `Resource` modular en el inspector | `MoveData`, `SpeciesData`, `StatBlock`, `MoveEffect`, `LearnsetEntry` |

## Fórmulas

**Estadística** (Gen III+):

```
PS   = floor((2·Base + IV + floor(EV/4)) · Nivel / 100) + Nivel + 10
Otra = floor((floor((2·Base + IV + floor(EV/4)) · Nivel / 100) + 5) · Naturaleza)
```

**Daño** (Gen V+, simplificado):

```
base = floor(floor(floor(2·Nivel/5 + 2) · Potencia · A / D) / 50) + 2
daño = base · crítico(1.5) · aleatorio(0.85–1.0) · STAB(1.5) · tipos · quemadura(0.5)
```

`A` = Ataque o At. Esp. del atacante · stages; `D` = Defensa o Def. Esp. del
objetivo · stages, según `move.category`.

## Ejemplo mínimo

```gdscript
var pikachu := Battler.new()
pikachu.species = load("res://data/species/pikachu.tres")
pikachu.level = 15
pikachu.ivs = StatBlock.filled(31)
add_child(pikachu)   # _ready() -> initialize()

var res := pikachu.use_move(pikachu.moves[0], enemigo)
print("%d de daño. %s" % [res.damage, res.effectiveness_text()])

pikachu.leveled_up.connect(func(nivel): print("¡Nivel %d!" % nivel))
pikachu.gain_exp(Experience.exp_on_faint(pikachu, enemigo))
```

## Crear datos en el editor

1. `FileSystem` → clic derecho → *New Resource* → `SpeciesData` / `MoveData`.
2. Rellena los campos en el inspector. Para el `learnset`, añade elementos
   `LearnsetEntry` (nivel + arrastrar un `MoveData`).
3. En `data/moves/` hay 5 movimientos de ejemplo (`.tres`) como plantilla,
   incluido uno con efecto de quemadura (`ascuas.tres`) y uno de estado
   (`gruñido.tres`).

## Qué NO incluye (por diseño)

El **bucle de turnos** (orden de acciones, cambio de Pokémon, IA, menús, animación)
es el punto de integración: se apoya en `Battler.use_move()`,
`Battler.speed()`, `Battler.end_of_turn_status_damage()` y las señales.
Tampoco incluye habilidades pasivas, objetos equipados ni clima; hay ganchos
(`rng["other_mult"]`, `MoveEffect`) para añadirlos.
