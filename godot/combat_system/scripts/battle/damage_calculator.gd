class_name DamageCalculator
extends RefCounted
## Fórmula de daño estilo Gen V+ (simplificada y documentada para fan game).
##
##   base = floor(floor(floor(2*Nivel/5 + 2) * Potencia * A / D) / 50) + 2
##
##   A = Ataque      del atacante  si el movimiento es Físico
##       At. Esp.    del atacante  si es Especial
##   D = Defensa     del objetivo  si es Físico
##       Def. Esp.   del objetivo  si es Especial
##
## Después se aplican, en orden: crítico x1.5, aleatorio 85–100 %, STAB x1.5,
## efectividad de tipos, y quemadura x0.5 (solo a movimientos físicos).
##
## El parámetro `rng` permite forzar valores en tests:
##   {"force_crit": bool, "roll": 0.85..1.0, "other_mult": float}

const CRIT_MULT := 1.5
const STAB_MULT := 1.5
## Probabilidad de crítico por escala 0..3 (Gen VI+).
const CRIT_CHANCE := [1.0 / 24.0, 1.0 / 8.0, 1.0 / 2.0, 1.0]


static func calculate(attacker: Battler, defender: Battler, move: MoveData,
		rng: Dictionary = {}) -> DamageResult:
	var res := DamageResult.new()
	res.category = move.category
	if not move.is_damaging():
		return res

	# --- Efectividad de tipos (si es inmune, terminamos ya) ---
	res.effectiveness = PokeTypes.effectiveness(move.type, defender.get_types())
	if res.is_immune():
		return res

	# --- Crítico ---
	res.critical = _roll_crit(move, rng)

	# --- Estadísticas ofensiva / defensiva según categoría ---
	var atk_id := Stats.Id.ATK if move.uses_physical() else Stats.Id.SPA
	var def_id := Stats.Id.DEF if move.uses_physical() else Stats.Id.SPD
	# El crítico ignora los stages que perjudican al atacante o favorecen al rival.
	var a := attacker.offensive_stat(atk_id, res.critical)
	var d := maxi(1, defender.defensive_stat(def_id, res.critical))

	var level := attacker.level
	var base := floori(floori(floori(2.0 * level / 5.0 + 2.0)
			* move.power * a / float(d)) / 50.0) + 2

	# --- Multiplicadores ---
	res.stab = move.type in attacker.get_types()
	var roll: float = rng.get("roll", randi_range(85, 100) / 100.0)

	var total := float(base)
	total *= CRIT_MULT if res.critical else 1.0
	total *= roll
	total *= STAB_MULT if res.stab else 1.0
	total *= res.effectiveness
	if move.uses_physical() and attacker.status == StatusCond.Id.BURN:
		total *= 0.5
	total *= float(rng.get("other_mult", 1.0))

	res.damage = maxi(1, floori(total))
	return res


static func _roll_crit(move: MoveData, rng: Dictionary) -> bool:
	if rng.has("force_crit"):
		return bool(rng["force_crit"])
	var stage := clampi((1 if move.high_crit_ratio else 0), 0, 3)
	return randf() < CRIT_CHANCE[stage]
