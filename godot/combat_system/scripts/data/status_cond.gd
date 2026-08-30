class_name StatusCond
extends RefCounted
## Estados alterados persistentes (los que sobreviven entre turnos).

enum Id { NONE, BURN, POISON, TOXIC, PARALYSIS, SLEEP, FREEZE }

const NAMES := {
	Id.NONE: "",
	Id.BURN: "Quemadura",
	Id.POISON: "Envenenamiento",
	Id.TOXIC: "Envenenamiento grave",
	Id.PARALYSIS: "Parálisis",
	Id.SLEEP: "Sueño",
	Id.FREEZE: "Congelación",
}

## Abreviatura estilo caja de combate.
const TAGS := {
	Id.BURN: "QEM", Id.POISON: "PSN", Id.TOXIC: "PSN",
	Id.PARALYSIS: "PAR", Id.SLEEP: "DRM", Id.FREEZE: "CNG",
}


static func status_name(id: Id) -> String:
	return NAMES.get(id, "")


static func tag(id: Id) -> String:
	return TAGS.get(id, "")
