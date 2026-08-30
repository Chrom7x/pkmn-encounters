class_name PokeTypes
extends RefCounted
## Sistema elemental: los 18 tipos oficiales (Gen VI+) y la tabla de efectividad.
##
## Uso:
##   var t := PokeTypes.Type.FIRE
##   var mult := PokeTypes.effectiveness(PokeTypes.Type.FIRE, [PokeTypes.Type.GRASS])  # 2.0
##
## Todo es estático: no se instancia.

enum Type {
	NONE = -1,      ## sin tipo (para el segundo tipo de un Pokémon mono-tipo)
	NORMAL, FIRE, WATER, ELECTRIC, GRASS, ICE,
	FIGHTING, POISON, GROUND, FLYING, PSYCHIC, BUG,
	ROCK, GHOST, DRAGON, DARK, STEEL, FAIRY,
}

## Nombres legibles (es-ES).
const NAMES := {
	Type.NONE: "—",
	Type.NORMAL: "Normal", Type.FIRE: "Fuego", Type.WATER: "Agua",
	Type.ELECTRIC: "Eléctrico", Type.GRASS: "Planta", Type.ICE: "Hielo",
	Type.FIGHTING: "Lucha", Type.POISON: "Veneno", Type.GROUND: "Tierra",
	Type.FLYING: "Volador", Type.PSYCHIC: "Psíquico", Type.BUG: "Bicho",
	Type.ROCK: "Roca", Type.GHOST: "Fantasma", Type.DRAGON: "Dragón",
	Type.DARK: "Siniestro", Type.STEEL: "Acero", Type.FAIRY: "Hada",
}

## Multiplicadores distintos de 1.0. Estructura:
##   { tipo_atacante: { tipo_defensor: multiplicador } }
## Lo que no aparece se asume 1.0 (daño neutro).
const CHART := {
	Type.NORMAL: {Type.ROCK: 0.5, Type.GHOST: 0.0, Type.STEEL: 0.5},
	Type.FIRE: {Type.FIRE: 0.5, Type.WATER: 0.5, Type.GRASS: 2.0, Type.ICE: 2.0, Type.BUG: 2.0, Type.ROCK: 0.5, Type.DRAGON: 0.5, Type.STEEL: 2.0},
	Type.WATER: {Type.FIRE: 2.0, Type.WATER: 0.5, Type.GRASS: 0.5, Type.GROUND: 2.0, Type.ROCK: 2.0, Type.DRAGON: 0.5},
	Type.ELECTRIC: {Type.WATER: 2.0, Type.ELECTRIC: 0.5, Type.GRASS: 0.5, Type.GROUND: 0.0, Type.FLYING: 2.0, Type.DRAGON: 0.5},
	Type.GRASS: {Type.FIRE: 0.5, Type.WATER: 2.0, Type.GRASS: 0.5, Type.POISON: 0.5, Type.GROUND: 2.0, Type.FLYING: 0.5, Type.BUG: 0.5, Type.ROCK: 2.0, Type.DRAGON: 0.5, Type.STEEL: 0.5},
	Type.ICE: {Type.FIRE: 0.5, Type.WATER: 0.5, Type.GRASS: 2.0, Type.ICE: 0.5, Type.GROUND: 2.0, Type.FLYING: 2.0, Type.DRAGON: 2.0, Type.STEEL: 0.5},
	Type.FIGHTING: {Type.NORMAL: 2.0, Type.ICE: 2.0, Type.POISON: 0.5, Type.FLYING: 0.5, Type.PSYCHIC: 0.5, Type.BUG: 0.5, Type.ROCK: 2.0, Type.GHOST: 0.0, Type.DARK: 2.0, Type.STEEL: 2.0, Type.FAIRY: 0.5},
	Type.POISON: {Type.GRASS: 2.0, Type.POISON: 0.5, Type.GROUND: 0.5, Type.ROCK: 0.5, Type.GHOST: 0.5, Type.STEEL: 0.0, Type.FAIRY: 2.0},
	Type.GROUND: {Type.FIRE: 2.0, Type.ELECTRIC: 2.0, Type.GRASS: 0.5, Type.POISON: 2.0, Type.FLYING: 0.0, Type.BUG: 0.5, Type.ROCK: 2.0, Type.STEEL: 2.0},
	Type.FLYING: {Type.ELECTRIC: 0.5, Type.GRASS: 2.0, Type.FIGHTING: 2.0, Type.BUG: 2.0, Type.ROCK: 0.5, Type.STEEL: 0.5},
	Type.PSYCHIC: {Type.FIGHTING: 2.0, Type.POISON: 2.0, Type.PSYCHIC: 0.5, Type.DARK: 0.0, Type.STEEL: 0.5},
	Type.BUG: {Type.FIRE: 0.5, Type.GRASS: 2.0, Type.FIGHTING: 0.5, Type.POISON: 0.5, Type.FLYING: 0.5, Type.PSYCHIC: 2.0, Type.GHOST: 0.5, Type.DARK: 2.0, Type.STEEL: 0.5, Type.FAIRY: 0.5},
	Type.ROCK: {Type.FIRE: 2.0, Type.ICE: 2.0, Type.FIGHTING: 0.5, Type.GROUND: 0.5, Type.FLYING: 2.0, Type.BUG: 2.0, Type.STEEL: 0.5},
	Type.GHOST: {Type.NORMAL: 0.0, Type.PSYCHIC: 2.0, Type.GHOST: 2.0, Type.DARK: 0.5},
	Type.DRAGON: {Type.DRAGON: 2.0, Type.STEEL: 0.5, Type.FAIRY: 0.0},
	Type.DARK: {Type.FIGHTING: 0.5, Type.PSYCHIC: 2.0, Type.GHOST: 2.0, Type.DARK: 0.5, Type.FAIRY: 0.5},
	Type.STEEL: {Type.FIRE: 0.5, Type.WATER: 0.5, Type.ELECTRIC: 0.5, Type.ICE: 2.0, Type.ROCK: 2.0, Type.STEEL: 0.5, Type.FAIRY: 2.0},
	Type.FAIRY: {Type.FIRE: 0.5, Type.FIGHTING: 2.0, Type.POISON: 0.5, Type.DRAGON: 2.0, Type.DARK: 2.0, Type.STEEL: 0.5},
}


static func type_name(t: Type) -> String:
	return NAMES.get(t, "???")


## Multiplicador de un tipo atacante contra un único tipo defensor.
static func single_effectiveness(attacking: Type, defending: Type) -> float:
	if attacking == Type.NONE or defending == Type.NONE:
		return 1.0
	var row: Dictionary = CHART.get(attacking, {})
	return float(row.get(defending, 1.0))


## Multiplicador total contra un Pokémon (1 o 2 tipos). Devuelve 0, 0.25, 0.5,
## 1, 2 o 4.
static func effectiveness(attacking: Type, defender_types: Array) -> float:
	var mult := 1.0
	for dt in defender_types:
		mult *= single_effectiveness(attacking, dt)
	return mult


## Texto para el cuadro de combate.
static func effectiveness_label(mult: float) -> String:
	if is_zero_approx(mult):
		return "No afecta al objetivo..."
	if mult >= 2.0:
		return "¡Es supereficaz!"
	if mult < 1.0:
		return "No es muy eficaz..."
	return ""
