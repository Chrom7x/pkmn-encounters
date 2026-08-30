extends Node
## Autoload "Flags" — almacén global de estado del juego (interruptores y valores).
##
## Lo usan las condiciones de diálogo, los pasos de cinemática y el guardado.
## No sabe nada de narrativa: es un diccionario con señal.

signal flag_changed(flag: StringName, value: Variant)

var _data: Dictionary = {}


## Activa/define un flag. `value` puede ser bool, int, String, etc.
func set_flag(flag: StringName, value: Variant = true) -> void:
	if _data.has(flag) and _data[flag] == value:
		return
	_data[flag] = value
	flag_changed.emit(flag, value)


## true si el flag existe y es "verdadero" (bool true, número != 0, String no vacío…).
func has_flag(flag: StringName) -> bool:
	return bool(_data.get(flag, false))


func get_value(flag: StringName, default: Variant = null) -> Variant:
	return _data.get(flag, default)


func erase(flag: StringName) -> void:
	if _data.erase(flag):
		flag_changed.emit(flag, null)


func clear_all() -> void:
	_data.clear()


# --- Guardado -----------------------------------------------------------------
func to_dict() -> Dictionary:
	return _data.duplicate(true)


func from_dict(d: Dictionary) -> void:
	_data = d.duplicate(true)
