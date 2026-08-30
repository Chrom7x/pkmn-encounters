class_name Stats
extends RefCounted
## Identificadores de estadística compartidos por todo el sistema de combate.

enum Id {
	HP,   ## Puntos de Salud
	ATK,  ## Ataque (físico)
	DEF,  ## Defensa (física)
	SPA,  ## Ataque Especial
	SPD,  ## Defensa Especial
	SPE,  ## Velocidad
	ACC,  ## Precisión (solo como stage en combate)
	EVA,  ## Evasión (solo como stage en combate)
}

## Las 6 estadísticas permanentes, en el orden en que viven dentro de StatBlock.
const BLOCK_KEYS: Array[StringName] = [
	&"hp", &"attack", &"defense", &"sp_attack", &"sp_defense", &"speed",
]

const NAMES := {
	Id.HP: "PS", Id.ATK: "Ataque", Id.DEF: "Defensa",
	Id.SPA: "At. Esp.", Id.SPD: "Def. Esp.", Id.SPE: "Velocidad",
	Id.ACC: "Precisión", Id.EVA: "Evasión",
}


static func stat_name(id: Id) -> String:
	return NAMES.get(id, "???")
