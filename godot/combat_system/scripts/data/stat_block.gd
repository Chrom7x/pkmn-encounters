class_name StatBlock
extends Resource
## Bloque reutilizable de 6 estadísticas. Sirve para las estadísticas base de una
## especie, para los IV, para los EV y para el rendimiento de EV al derrotar.
## Editable en el inspector como subrecurso.

@export_range(0, 255) var hp: int = 0
@export_range(0, 255) var attack: int = 0
@export_range(0, 255) var defense: int = 0
@export_range(0, 255) var sp_attack: int = 0
@export_range(0, 255) var sp_defense: int = 0
@export_range(0, 255) var speed: int = 0


## Crea un bloque con el mismo valor en las 6 (p. ej. IV perfectos: filled(31)).
static func filled(value: int) -> StatBlock:
	var s := StatBlock.new()
	s.hp = value
	s.attack = value
	s.defense = value
	s.sp_attack = value
	s.sp_defense = value
	s.speed = value
	return s


## Acceso por índice 0..5 según Stats.BLOCK_KEYS.
func get_index(i: int) -> int:
	return get(Stats.BLOCK_KEYS[i])


func set_index(i: int, value: int) -> void:
	set(Stats.BLOCK_KEYS[i], value)


func total() -> int:
	return hp + attack + defense + sp_attack + sp_defense + speed


func clone() -> StatBlock:
	var s := StatBlock.new()
	for i in 6:
		s.set_index(i, get_index(i))
	return s
