class_name SpeciesData
extends Resource
## Datos base de una especie de Pokémon. Un .tres por especie, editable en el
## inspector. Es solo DATOS: la instancia jugable en combate es un Battler.

@export_group("Identidad")
@export var dex_number: int = 0
@export var display_name: String = "Nueva especie"
## Tipo principal (obligatorio).
@export var type_primary: PokeTypes.Type = PokeTypes.Type.NORMAL
## Tipo secundario (NONE si es mono-tipo).
@export var type_secondary: PokeTypes.Type = PokeTypes.Type.NONE

@export_group("Estadísticas base")
@export var base_stats: StatBlock

@export_group("Crecimiento")
@export var growth_rate: GrowthRate.Formula = GrowthRate.Formula.MEDIUM_FAST
## EXP base que otorga al ser derrotado (valor "b" de la fórmula).
@export var base_exp_yield: int = 64
## Puntos de esfuerzo que reparte al ser derrotado.
@export var ev_yield: StatBlock

@export_group("Aprendizaje")
@export var learnset: Array[LearnsetEntry] = []


## Devuelve [tipo_primario] o [tipo_primario, tipo_secundario].
func get_types() -> Array:
	var out: Array = [type_primary]
	if type_secondary != PokeTypes.Type.NONE and type_secondary != type_primary:
		out.append(type_secondary)
	return out


## Movimientos que se aprenden EXACTAMENTE a ese nivel.
func moves_learned_at(level: int) -> Array[MoveData]:
	var out: Array[MoveData] = []
	for e in learnset:
		if e and e.move and e.level == level:
			out.append(e.move)
	return out


## Los últimos <count> movimientos aprendibles hasta <level> (moveset inicial).
func default_moveset(level: int, count: int = 4) -> Array[MoveData]:
	var pool: Array[MoveData] = []
	for e in learnset:
		if e and e.move and e.level <= level and e.move not in pool:
			pool.append(e.move)
	return pool.slice(maxi(0, pool.size() - count))
