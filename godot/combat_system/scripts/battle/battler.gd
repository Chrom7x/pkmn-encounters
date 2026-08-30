class_name Battler
extends Node
## Instancia jugable de un Pokémon (en equipo o en combate).
##
## Adjunta este script a un Node. Configúralo en el inspector (arrastra un
## SpeciesData, pon nivel, IVs, EVs, naturaleza y hasta 4 MoveData) o por código:
##
##   var b := Battler.new()
##   b.species = load("res://data/species/charmander.tres")
##   b.level = 12
##   add_child(b)          # _ready() llama a initialize()
##
## Después:  b.use_move(b.moves[0], enemigo)  /  b.gain_exp(xp)

signal stats_recalculated
signal hp_changed(current: int, maximum: int)
signal fainted
signal leveled_up(new_level: int)
signal move_learned(move: MoveData)
signal wants_to_learn_move(move: MoveData)   ## ya tiene 4; decide la UI
signal status_changed(status: StatusCond.Id)
signal exp_gained(amount: int, total: int)

const MAX_MOVES := 4

@export var species: SpeciesData
@export_range(1, 100) var level: int = 5
@export var nickname: String = ""
@export var nature: Natures.Nature = Natures.Nature.HARDY
@export var ivs: StatBlock
@export var evs: StatBlock
@export var moves: Array[MoveData] = []

var exp_total: int = 0
var current_hp: int = 0
var status: StatusCond.Id = StatusCond.Id.NONE
## Stats.Id -> stage (-6..6). Solo ATK/DEF/SPA/SPD/SPE/ACC/EVA.
var stages: Dictionary = {}

var _stats: StatBlock


var max_hp: int:
	get: return _stats.hp if _stats else 0


func _ready() -> void:
	if species and _stats == null:
		initialize()


## Prepara el Battler: fija EXP acorde al nivel, calcula stats y rellena PS.
func initialize(to_level: int = -1) -> void:
	assert(species != null, "Battler necesita un SpeciesData en 'species'")
	if to_level > 0:
		level = clampi(to_level, 1, GrowthRate.MAX_LEVEL)
	if ivs == null:
		ivs = StatBlock.new()
	if evs == null:
		evs = StatBlock.new()
	if nickname.is_empty():
		nickname = species.display_name

	exp_total = GrowthRate.total_exp_for_level(species.growth_rate, level)
	reset_stages()
	recalculate_stats()
	current_hp = max_hp
	if moves.is_empty():
		moves = species.default_moveset(level, MAX_MOVES)
	hp_changed.emit(current_hp, max_hp)


# ---------------------------------------------------------------- Estadísticas
func recalculate_stats() -> void:
	_stats = StatCalculator.calc_all(species, ivs, evs, level, nature)
	stats_recalculated.emit()


## Estadística permanente sin stages (para pantallas de resumen).
func base_stat(id: Stats.Id) -> int:
	match id:
		Stats.Id.HP: return _stats.hp
		Stats.Id.ATK: return _stats.attack
		Stats.Id.DEF: return _stats.defense
		Stats.Id.SPA: return _stats.sp_attack
		Stats.Id.SPD: return _stats.sp_defense
		Stats.Id.SPE: return _stats.speed
		_: return 0


func get_stage(id: Stats.Id) -> int:
	return stages.get(id, 0)


## Cambia un stage y devuelve cuántos niveles cambió realmente (0 si topó).
func change_stage(id: Stats.Id, delta: int) -> int:
	var before: int = get_stage(id)
	var after := clampi(before + delta, StatStages.MIN, StatStages.MAX)
	stages[id] = after
	return after - before


func reset_stages() -> void:
	stages = {
		Stats.Id.ATK: 0, Stats.Id.DEF: 0, Stats.Id.SPA: 0, Stats.Id.SPD: 0,
		Stats.Id.SPE: 0, Stats.Id.ACC: 0, Stats.Id.EVA: 0,
	}


## Ataque/At.Esp. efectivo. Si es crítico, ignora stages negativos del atacante.
func offensive_stat(id: Stats.Id, crit: bool = false) -> int:
	var stage: int = get_stage(id)
	if crit and stage < 0:
		stage = 0
	var v := roundi(base_stat(id) * StatStages.multiplier(stage))
	if id == Stats.Id.SPE and status == StatusCond.Id.PARALYSIS:
		v = floori(v * 0.5)
	return maxi(1, v)


## Defensa/Def.Esp. efectiva. Si es crítico, ignora stages positivos del objetivo.
func defensive_stat(id: Stats.Id, crit: bool = false) -> int:
	var stage: int = get_stage(id)
	if crit and stage > 0:
		stage = 0
	return maxi(1, roundi(base_stat(id) * StatStages.multiplier(stage)))


func speed() -> int:
	return offensive_stat(Stats.Id.SPE)


func get_types() -> Array:
	return species.get_types() if species else []


# ---------------------------------------------------------------- PS y daño
func apply_damage(amount: int) -> void:
	amount = maxi(0, amount)
	current_hp = clampi(current_hp - amount, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		set_status(StatusCond.Id.NONE)
		fainted.emit()


func heal(amount: int) -> void:
	if is_fainted():
		return
	current_hp = clampi(current_hp + maxi(0, amount), 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func full_restore() -> void:
	current_hp = max_hp
	set_status(StatusCond.Id.NONE)
	reset_stages()
	hp_changed.emit(current_hp, max_hp)


func is_fainted() -> bool:
	return current_hp <= 0


func set_status(new_status: StatusCond.Id) -> void:
	if status == new_status:
		return
	status = new_status
	status_changed.emit(status)


# ---------------------------------------------------------------- Usar movimiento
## Ejecuta `move` contra `target`. Comprueba precisión, calcula daño y resuelve
## el efecto secundario. Devuelve un DamageResult.
func use_move(move: MoveData, target: Battler, rng: Dictionary = {}) -> DamageResult:
	var res := DamageResult.new()
	res.category = move.category

	if not _accuracy_check(move, target, rng):
		res.missed = true
		return res

	if move.is_damaging():
		res = DamageCalculator.calculate(self, target, move, rng)
		if not res.missed and res.damage > 0:
			target.apply_damage(res.damage)
			res.fainted_target = target.is_fainted()
			_apply_recoil(move, res.damage)

	if not res.missed:
		_resolve_effect(move, target, rng)
	return res


func _apply_recoil(move: MoveData, damage_dealt: int) -> void:
	var fx := move.effect
	if fx and fx.kind == MoveEffect.Kind.RECOIL and fx.fraction > 0.0:
		apply_damage(maxi(1, floori(damage_dealt * fx.fraction)))


func _accuracy_check(move: MoveData, target: Battler, rng: Dictionary) -> bool:
	if rng.get("force_hit", false):
		return true
	if move.accuracy <= 0:
		return true
	var net := clampi(get_stage(Stats.Id.ACC) - target.get_stage(Stats.Id.EVA),
			StatStages.MIN, StatStages.MAX)
	var chance := move.accuracy * StatStages.accuracy_multiplier(net)
	return randf() * 100.0 < chance


func _resolve_effect(move: MoveData, target: Battler, rng: Dictionary) -> void:
	var fx := move.effect
	if fx == null or fx.kind == MoveEffect.Kind.NONE:
		return
	var roll: int = rng.get("effect_roll", randi_range(1, 100))
	if roll > move.effect_chance:
		return

	var who: Battler = self if fx.target_self else target
	match fx.kind:
		MoveEffect.Kind.INFLICT_STATUS:
			if who.status == StatusCond.Id.NONE and not who.is_fainted():
				who.set_status(fx.status)
		MoveEffect.Kind.STAT_CHANGE:
			who.change_stage(fx.stat, fx.stages)
		MoveEffect.Kind.HEAL_USER:
			heal(floori(max_hp * fx.fraction))
		# RECOIL se resuelve en _apply_recoil (necesita el daño ya infligido).


# ---------------------------------------------------------------- Daño residual
## Llamar al final del turno desde el motor de combate. Devuelve el daño aplicado.
func end_of_turn_status_damage() -> int:
	var dmg := 0
	match status:
		StatusCond.Id.BURN, StatusCond.Id.POISON:
			dmg = maxi(1, floori(max_hp / 16.0))
		StatusCond.Id.TOXIC:
			dmg = maxi(1, floori(max_hp / 8.0))
	if dmg > 0:
		apply_damage(dmg)
	return dmg


# ---------------------------------------------------------------- EXP y nivel
func gain_exp(amount: int) -> void:
	if level >= GrowthRate.MAX_LEVEL:
		return
	amount = maxi(0, amount)
	exp_total += amount
	exp_gained.emit(amount, exp_total)
	_check_level_up()


func _check_level_up() -> void:
	var formula := species.growth_rate
	while level < GrowthRate.MAX_LEVEL \
			and exp_total >= GrowthRate.total_exp_for_level(formula, level + 1):
		var hp_before := max_hp
		level += 1
		recalculate_stats()
		# Los PS actuales suben lo mismo que subió el máximo.
		current_hp += max_hp - hp_before
		hp_changed.emit(current_hp, max_hp)
		leveled_up.emit(level)
		for m in species.moves_learned_at(level):
			try_learn_move(m)

	if level >= GrowthRate.MAX_LEVEL:
		exp_total = GrowthRate.total_exp_for_level(formula, GrowthRate.MAX_LEVEL)


func exp_to_next_level() -> int:
	return GrowthRate.exp_to_next_level(species.growth_rate, level, exp_total)


func level_progress() -> float:
	return GrowthRate.level_progress(species.growth_rate, level, exp_total)


# ---------------------------------------------------------------- Movimientos
func try_learn_move(move: MoveData) -> void:
	if move == null or move in moves:
		return
	if moves.size() < MAX_MOVES:
		moves.append(move)
		move_learned.emit(move)
	else:
		wants_to_learn_move.emit(move)


func replace_move(index: int, move: MoveData) -> void:
	if index >= 0 and index < moves.size():
		moves[index] = move
		move_learned.emit(move)
