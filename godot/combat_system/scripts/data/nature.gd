class_name Natures
extends RefCounted
## Naturalezas: 25 en total. Cada una sube una estadística un 10 % y baja otra
## un 10 % (5 son neutras). El orden del enum reproduce la rejilla oficial
## (fila = stat que sube, columna = stat que baja), así el cálculo es aritmético.

enum Nature {
	HARDY, LONELY, ADAMANT, NAUGHTY, BRAVE,      # sube Ataque
	BOLD, DOCILE, IMPISH, LAX, RELAXED,          # sube Defensa
	MODEST, MILD, BASHFUL, RASH, QUIET,          # sube At. Esp.
	CALM, GENTLE, CAREFUL, QUIRKY, SASSY,        # sube Def. Esp.
	TIMID, HASTY, JOLLY, NAIVE, SERIOUS,         # sube Velocidad
}

const NAMES := {
	Nature.HARDY: "Fuerte", Nature.LONELY: "Huraña", Nature.ADAMANT: "Firme",
	Nature.NAUGHTY: "Pícara", Nature.BRAVE: "Audaz", Nature.BOLD: "Osada",
	Nature.DOCILE: "Dócil", Nature.IMPISH: "Agitada", Nature.LAX: "Floja",
	Nature.RELAXED: "Plácida", Nature.MODEST: "Modesta", Nature.MILD: "Afable",
	Nature.BASHFUL: "Tímida", Nature.RASH: "Alocada", Nature.QUIET: "Mansa",
	Nature.CALM: "Serena", Nature.GENTLE: "Amable", Nature.CAREFUL: "Cauta",
	Nature.QUIRKY: "Rara", Nature.SASSY: "Grosera", Nature.TIMID: "Miedosa",
	Nature.HASTY: "Activa", Nature.JOLLY: "Alegre", Nature.NAIVE: "Ingenua",
	Nature.SERIOUS: "Seria",
}


static func nature_name(nature: Nature) -> String:
	return NAMES.get(nature, "???")


## Multiplicador de naturaleza para una estadística: 1.1, 0.9 o 1.0.
## HP nunca se ve afectado.
static func multiplier(nature: int, stat: int) -> float:
	var s := stat - 1  # Stats.Id.ATK(1)..SPE(5) -> 0..4
	if s < 0 or s > 4:
		return 1.0
	var up := nature / 5
	var down := nature % 5
	if up == down:
		return 1.0
	if s == up:
		return 1.1
	if s == down:
		return 0.9
	return 1.0


## Estadística que sube / baja (Stats.Id), o -1 si es neutra.
static func raised_stat(nature: int) -> int:
	if nature / 5 == nature % 5:
		return -1
	return (nature / 5) + 1


static func lowered_stat(nature: int) -> int:
	if nature / 5 == nature % 5:
		return -1
	return (nature % 5) + 1


static func random_nature() -> Nature:
	return (randi() % Nature.values().size()) as Nature
