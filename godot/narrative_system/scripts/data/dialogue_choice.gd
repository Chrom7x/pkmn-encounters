class_name DialogueChoice
extends Resource
## Una opción de decisión. Ejemplos: "Sí, cura a mi equipo" / "No, gracias",
## "Volar a Ciudad Verde", "Comprar", "Vender".
##
## Al elegirla se ejecutan sus `actions` en orden (esperando a las asíncronas) y
## luego se salta a `next` (otro DialogueData) o termina el diálogo.
##
## Añadir una respuesta nueva = crear otro DialogueChoice y arrastrarle acciones.
## No hay que tocar código del manager.

@export var id: StringName = &""
@export var text: String = "Opción"

@export_group("Disponibilidad")
## Debe cumplirse TODO esto para que la opción se muestre.
@export var required_flags: Array[StringName] = []
## Si alguno de estos flags está activo, la opción se oculta.
@export var forbidden_flags: Array[StringName] = []
## Condición extra programable (subclase de DialogueCondition). Opcional.
@export var custom_condition: DialogueCondition

@export_group("Al elegir")
## Acciones a ejecutar (GameAction). Se corren en orden, esperando a las async.
@export var actions: Array[GameAction] = []
## Rama de diálogo que sigue tras las acciones (null = termina la conversación).
@export var next: DialogueData


## ¿Se puede mostrar esta opción ahora mismo?
func is_available() -> bool:
	for f in required_flags:
		if not Flags.has_flag(f):
			return false
	for f in forbidden_flags:
		if Flags.has_flag(f):
			return false
	if custom_condition and not custom_condition.is_met():
		return false
	return true
