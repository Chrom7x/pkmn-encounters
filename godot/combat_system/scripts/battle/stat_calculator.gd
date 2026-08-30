class_name StatCalculator
extends RefCounted
## Fórmula de estadísticas de la saga (Gen III en adelante).
##
##   PS   = floor((2*Base + IV + floor(EV/4)) * Nivel / 100) + Nivel + 10
##   Otra = floor((floor((2*Base + IV + floor(EV/4)) * Nivel / 100) + 5) * Nat)
##
## donde Nat es 1.1 / 1.0 / 0.9 según la naturaleza.


static func calc_hp(base: int, iv: int, ev: int, level: int) -> int:
	if base <= 1:  # línea tipo Shedinja: siempre 1 PS
		return 1
	return floori((2 * base + iv + floori(ev / 4.0)) * level / 100.0) + level + 10


static func calc_other(base: int, iv: int, ev: int, level: int, nature_mult: float) -> int:
	var core := floori((2 * base + iv + floori(ev / 4.0)) * level / 100.0) + 5
	return floori(core * nature_mult)


## Calcula las 6 estadísticas finales y las devuelve en un StatBlock nuevo.
static func calc_all(species: SpeciesData, ivs: StatBlock, evs: StatBlock,
		level: int, nature: int) -> StatBlock:
	assert(species != null and species.base_stats != null,
		"SpeciesData necesita base_stats asignado")

	var b := species.base_stats
	var iv := ivs if ivs else StatBlock.new()
	var ev := evs if evs else StatBlock.new()

	var out := StatBlock.new()
	out.hp = calc_hp(b.hp, iv.hp, ev.hp, level)
	out.attack = calc_other(b.attack, iv.attack, ev.attack, level,
		Natures.multiplier(nature, Stats.Id.ATK))
	out.defense = calc_other(b.defense, iv.defense, ev.defense, level,
		Natures.multiplier(nature, Stats.Id.DEF))
	out.sp_attack = calc_other(b.sp_attack, iv.sp_attack, ev.sp_attack, level,
		Natures.multiplier(nature, Stats.Id.SPA))
	out.sp_defense = calc_other(b.sp_defense, iv.sp_defense, ev.sp_defense, level,
		Natures.multiplier(nature, Stats.Id.SPD))
	out.speed = calc_other(b.speed, iv.speed, ev.speed, level,
		Natures.multiplier(nature, Stats.Id.SPE))
	return out
