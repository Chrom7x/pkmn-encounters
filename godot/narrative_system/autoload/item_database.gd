extends Node
## Autoload "ItemDatabase" — catálogo global de objetos (id -> ItemData).
##
## Al arrancar escanea res://data/items/ y carga todos los .tres. También puedes
## registrar objetos a mano con register().

## Carpetas a escanear en _ready(). Añade las tuyas si usas otra ruta.
const SCAN_DIRS := ["res://data/items"]

var _items: Dictionary = {}   # StringName -> ItemData


func _ready() -> void:
	for dir in SCAN_DIRS:
		load_directory(dir)


func register(item: ItemData) -> void:
	if item and item.id != &"":
		_items[item.id] = item


func get_item(id: StringName) -> ItemData:
	return _items.get(id)


func has(id: StringName) -> bool:
	return _items.has(id)


func all() -> Array:
	return _items.values()


func ids() -> Array:
	return _items.keys()


## Carga todos los recursos de una carpeta que sean ItemData.
func load_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and (file.ends_with(".tres") or file.ends_with(".res")):
			var res: Resource = load(path.path_join(file))
			if res is ItemData:
				register(res)
		file = dir.get_next()
	dir.list_dir_end()
