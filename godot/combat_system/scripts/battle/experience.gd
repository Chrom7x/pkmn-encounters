class_name Experience
extends RefCounted
## Reparto de EXP y EV al derrotar a un Pokémon (fórmula clásica Gen I–V).
##
##   exp = floor( a * t * e * b * L / (7 * s) )
##
##   a = 1.0 salvaje / 1.5 combate contra Entrenador
##   t = 1.0 propio  / 1.5 Pokémon intercambiado
##   e = 1.0         / 1.5 con Huevo Suerte
##   b = EXP base de la especie derrotada
##   L = nivel del Pokémon derrotado
##   s = nº de Pokémon que participaron


static func exp_on_faint(_winner: Battler, loser: Battler, opts: Dictionary = {}) -> int:
	var b := loser.species.base_exp_yield if loser.species else 0
	var a := 1.5 if opts.get("trainer_battle", false) else 1.0
	var t := 1.5 if opts.get("traded", false) else 1.0
	var e := 1.5 if opts.get("lucky_egg", false) else 1.0
	var s := maxi(1, int(opts.get("participants", 1)))
	var l := loser.level
	return maxi(1, floori(a * t * e * b * l / (7.0 * s)))


## Suma los EV que reparte `loser` a `winner`, respetando el tope de 252 por
## estadística y 510 en total. Recalcula las stats del ganador.
static func distribute_evs(winner: Battler, loser: Battler) -> void:
	if loser.species == null or loser.species.ev_yield == null:
		return
	if winner.evs == null:
		winner.evs = StatBlock.new()

	var yield_block := loser.species.ev_yield
	for i in 6:
		var gain: int = yield_block.get_index(i)
		if gain <= 0:
			continue
		var current: int = winner.evs.get_index(i)
		var room_stat := 252 - current
		var room_total := 510 - winner.evs.total()
		var add := clampi(gain, 0, mini(room_stat, room_total))
		if add > 0:
			winner.evs.set_index(i, current + add)

	winner.recalculate_stats()
