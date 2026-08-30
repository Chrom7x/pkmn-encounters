extends Node
## Demostración por código de todo el sistema: tipos, físico/especial, escalado
## de stats, daño y subida de nivel. Crea un Node, adjunta este script y ejecuta.
## Salida por consola.

func _ready() -> void:
	randomize()
	_demo_curvas()
	_demo_tipos()
	_demo_combate()


func _demo_curvas() -> void:
	print("\n=== Curvas de experiencia (EXP total para el nivel) ===")
	for f in [GrowthRate.Formula.FAST, GrowthRate.Formula.MEDIUM_FAST,
			GrowthRate.Formula.MEDIUM_SLOW, GrowthRate.Formula.SLOW,
			GrowthRate.Formula.ERRATIC, GrowthRate.Formula.FLUCTUATING]:
		print("  %-14s  Nv50=%8d   Nv100=%9d" % [
			str(GrowthRate.FORMULA_NAMES[f]),
			GrowthRate.total_exp_for_level(f, 50),
			GrowthRate.total_exp_for_level(f, 100)])


func _demo_tipos() -> void:
	print("\n=== Efectividad de tipos ===")
	var casos := [
		[PokeTypes.Type.FIRE, [PokeTypes.Type.GRASS]],
		[PokeTypes.Type.FIRE, [PokeTypes.Type.WATER]],
		[PokeTypes.Type.WATER, [PokeTypes.Type.FIRE, PokeTypes.Type.GROUND]],
		[PokeTypes.Type.ELECTRIC, [PokeTypes.Type.GROUND]],
		[PokeTypes.Type.FIGHTING, [PokeTypes.Type.NORMAL, PokeTypes.Type.FLYING]],
		[PokeTypes.Type.ICE, [PokeTypes.Type.DRAGON, PokeTypes.Type.FLYING]],
	]
	for c in casos:
		var mult: float = PokeTypes.effectiveness(c[0], c[1])
		var defn := ""
		for d in c[1]:
			defn += PokeTypes.type_name(d) + "/"
		print("  %-10s -> %-16s x%s" % [
			PokeTypes.type_name(c[0]), defn.trim_suffix("/"), mult])


func _demo_combate() -> void:
	print("\n=== Combate de ejemplo ===")

	var ember := _move("Ascuas", PokeTypes.Type.FIRE, MoveData.Category.SPECIAL, 40)
	var scratch := _move("Arañazo", PokeTypes.Type.NORMAL, MoveData.Category.PHYSICAL, 40)
	var vine := _move("Látigo Cepa", PokeTypes.Type.GRASS, MoveData.Category.PHYSICAL, 45)
	var water := _move("Pistola Agua", PokeTypes.Type.WATER, MoveData.Category.SPECIAL, 40)

	var charmander := _species(4, "Charmander", PokeTypes.Type.FIRE, PokeTypes.Type.NONE,
		39, 52, 43, 60, 50, 65, GrowthRate.Formula.MEDIUM_SLOW, 62)
	var bulbasaur := _species(1, "Bulbasaur", PokeTypes.Type.GRASS, PokeTypes.Type.POISON,
		45, 49, 49, 65, 65, 45, GrowthRate.Formula.MEDIUM_SLOW, 64)

	var a := _battler(charmander, 12, [ember, scratch])
	var b := _battler(bulbasaur, 12, [vine, water])
	add_child(a)
	add_child(b)

	a.leveled_up.connect(func(l: int): print("   ¡%s subió al Nv %d!" % [a.nickname, l]))

	_print_sheet(a)
	_print_sheet(b)

	var turn := 1
	while not a.is_fainted() and not b.is_fainted() and turn <= 30:
		print("\n-- Turno %d --" % turn)
		# El más rápido ataca primero.
		var first := a if a.speed() >= b.speed() else b
		var second := b if first == a else a
		_do_move(first, second, first.moves[0])
		if not second.is_fainted():
			_do_move(second, first, second.moves[0])
		turn += 1

	var loser := a if a.is_fainted() else b
	var winner := b if loser == a else a
	print("\n%s se debilitó. ¡Gana %s!" % [loser.nickname, winner.nickname])

	var xp := Experience.exp_on_faint(winner, loser, {"participants": 1})
	print("%s gana %d EXP (tenía Nv %d, %d para el siguiente)." % [
		winner.nickname, xp, winner.level, winner.exp_to_next_level()])
	winner.gain_exp(xp)
	Experience.distribute_evs(winner, loser)
	print("Tras el combate: %s Nv %d, %d EXP para el siguiente." % [
		winner.nickname, winner.level, winner.exp_to_next_level()])


# ---------------------------------------------------------------- helpers
func _do_move(user: Battler, target: Battler, move: MoveData) -> void:
	var r := user.use_move(move, target)
	if r.missed:
		print("  %s usó %s… ¡pero falló!" % [user.nickname, move.display_name])
		return
	var extra := ""
	if r.critical:
		extra += "  ¡Crítico!"
	if r.effectiveness_text() != "":
		extra += "  " + r.effectiveness_text()
	print("  %s usó %s: %d de daño.%s  [%s %d/%d]" % [
		user.nickname, move.display_name, r.damage, extra,
		target.nickname, target.current_hp, target.max_hp])


func _print_sheet(bt: Battler) -> void:
	print("  %s Nv %d  PS %d/%d | Atk %d  Def %d  SpA %d  SpD %d  Spe %d" % [
		bt.nickname, bt.level, bt.current_hp, bt.max_hp,
		bt.base_stat(Stats.Id.ATK), bt.base_stat(Stats.Id.DEF),
		bt.base_stat(Stats.Id.SPA), bt.base_stat(Stats.Id.SPD),
		bt.base_stat(Stats.Id.SPE)])


func _move(n: String, type: int, cat: int, power: int) -> MoveData:
	var m := MoveData.new()
	m.display_name = n
	m.type = type
	m.category = cat
	m.power = power
	m.accuracy = 100
	m.max_pp = 20
	return m


func _species(dex: int, n: String, t1: int, t2: int, hp: int, atk: int, df: int,
		spa: int, spd: int, spe: int, growth: int, exp_yield: int) -> SpeciesData:
	var s := SpeciesData.new()
	s.dex_number = dex
	s.display_name = n
	s.type_primary = t1
	s.type_secondary = t2
	s.growth_rate = growth
	s.base_exp_yield = exp_yield
	s.base_stats = StatBlock.new()
	s.base_stats.hp = hp
	s.base_stats.attack = atk
	s.base_stats.defense = df
	s.base_stats.sp_attack = spa
	s.base_stats.sp_defense = spd
	s.base_stats.speed = spe
	return s


func _battler(sp: SpeciesData, lvl: int, mv: Array) -> Battler:
	var bt := Battler.new()
	bt.name = sp.display_name
	bt.species = sp
	bt.level = lvl
	bt.ivs = StatBlock.filled(31)
	bt.evs = StatBlock.new()
	var typed: Array[MoveData] = []
	for x in mv:
		typed.append(x)
	bt.moves = typed
	return bt
