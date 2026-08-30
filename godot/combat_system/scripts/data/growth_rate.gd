class_name GrowthRate
extends RefCounted
## Curvas de experiencia clásicas de la saga (Bulbapedia: "Experience").
## Cada especie usa una de las 6 fórmulas. Todo es estático.

enum Formula { ERRATIC, FAST, MEDIUM_FAST, MEDIUM_SLOW, SLOW, FLUCTUATING }

const MAX_LEVEL := 100

const FORMULA_NAMES := {
	Formula.ERRATIC: "Errático",
	Formula.FAST: "Rápido",
	Formula.MEDIUM_FAST: "Medio rápido",
	Formula.MEDIUM_SLOW: "Medio lento",
	Formula.SLOW: "Lento",
	Formula.FLUCTUATING: "Fluctuante",
}


## EXP total acumulada necesaria para ESTAR en `level`.
static func total_exp_for_level(formula: Formula, level: int) -> int:
	level = clampi(level, 1, MAX_LEVEL)
	if level == 1:
		return 0

	var n := float(level)
	var n3 := n * n * n
	var e := 0.0

	match formula:
		Formula.ERRATIC:
			if level < 50:
				e = n3 * (100.0 - n) / 50.0
			elif level < 68:
				e = n3 * (150.0 - n) / 100.0
			elif level < 98:
				e = n3 * float(floori((1911.0 - 10.0 * n) / 3.0)) / 500.0
			else:
				e = n3 * (160.0 - n) / 100.0
		Formula.FAST:
			e = 0.8 * n3
		Formula.MEDIUM_FAST:
			e = n3
		Formula.MEDIUM_SLOW:
			e = 1.2 * n3 - 15.0 * n * n + 100.0 * n - 140.0
		Formula.SLOW:
			e = 1.25 * n3
		Formula.FLUCTUATING:
			if level < 15:
				e = n3 * ((float(floori((n + 1.0) / 3.0)) + 24.0) / 50.0)
			elif level < 36:
				e = n3 * ((n + 14.0) / 50.0)
			else:
				e = n3 * ((float(floori(n / 2.0)) + 32.0) / 50.0)

	return maxi(0, floori(e))


## Nivel correspondiente a una cantidad de EXP total.
static func level_for_exp(formula: Formula, exp: int) -> int:
	var lvl := 1
	while lvl < MAX_LEVEL and exp >= total_exp_for_level(formula, lvl + 1):
		lvl += 1
	return lvl


## EXP que falta para el siguiente nivel (0 si ya está al máximo).
static func exp_to_next_level(formula: Formula, level: int, exp: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return maxi(0, total_exp_for_level(formula, level + 1) - exp)


## Progreso [0..1] dentro del nivel actual, para barras de EXP.
static func level_progress(formula: Formula, level: int, exp: int) -> float:
	if level >= MAX_LEVEL:
		return 1.0
	var lo := total_exp_for_level(formula, level)
	var hi := total_exp_for_level(formula, level + 1)
	if hi <= lo:
		return 1.0
	return clampf(float(exp - lo) / float(hi - lo), 0.0, 1.0)
