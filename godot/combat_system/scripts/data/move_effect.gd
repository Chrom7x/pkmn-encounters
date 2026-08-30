class_name MoveEffect
extends Resource
## Efecto secundario opcional de un movimiento. Se asigna como subrecurso en
## MoveData.effect y se resuelve en Battler tras aplicar el daño.

enum Kind {
	NONE,            ## sin efecto extra
	INFLICT_STATUS,  ## aplica un estado alterado
	STAT_CHANGE,     ## sube/baja stages de una estadística
	HEAL_USER,       ## cura al usuario un % de sus PS máx.
	RECOIL,          ## el usuario recibe retroceso (% del daño infligido)
}

@export var kind: Kind = Kind.NONE

@export_group("INFLICT_STATUS")
@export var status: StatusCond.Id = StatusCond.Id.NONE

@export_group("STAT_CHANGE")
@export var stat: Stats.Id = Stats.Id.ATK
@export_range(-6, 6) var stages: int = 0

@export_group("HEAL_USER / RECOIL")
@export_range(0.0, 1.0, 0.05) var fraction: float = 0.0

@export_group("Objetivo")
## Si es true, el efecto se aplica sobre el usuario en vez del objetivo.
@export var target_self: bool = false
