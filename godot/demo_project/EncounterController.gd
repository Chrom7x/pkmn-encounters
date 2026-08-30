extends Node
# Ejemplo de uso del nodo nativo RandomEncounters en Godot 4.
# Colócalo en tu escena de mapa y llama a on_player_stepped() cada vez que el
# jugador entra en una casilla nueva.

@onready var enc: RandomEncounters = RandomEncounters.new()

# Bits de progreso — deben coincidir con los que uses en tu GameState.
const FLAG_POKEDEX_NACIONAL := 1 << 0
const FLAG_INSIGNIA_NIEBLA  := 1 << 1
const FLAG_ENJAMBRE_HOY     := 1 << 2

# 0 = Any, 1 = Mañana, 2 = Día, 3 = Noche
var current_zone_id := ""

func _ready() -> void:
	add_child(enc)
	enc.set_seed(randi())
	enc.encounter_started.connect(_on_encounter)

	enc.register_zone({
		"id": "ruta_1",
		"base_step_rate": 0.12,
		"min_steps_between": 4,
		"entries": [
			{ "species_id": 19, "weight": 40, "min_level": 2, "max_level": 4 },
			{ "species_id": 16, "weight": 35, "min_level": 2, "max_level": 5 },
			{ "species_id": 43, "weight": 20, "min_level": 3, "max_level": 5, "time": 3 },
			{ "species_id": 164, "weight": 5, "min_level": 8, "max_level": 12, "time": 3 },
		],
	})

	enc.register_zone({
		"id": "cueva_niebla",
		"base_step_rate": 0.18,
		"zone_required_flags": FLAG_INSIGNIA_NIEBLA,     # zona bloqueada sin la insignia
		"entries": [
			{ "species_id": 41, "weight": 60, "min_level": 6, "max_level": 10 },
			{ "species_id": 42, "weight": 15, "min_level": 12, "max_level": 16 },
			{
				"species_id": 147, "weight": 3, "min_level": 15, "max_level": 18,
				"required_flags": FLAG_POKEDEX_NACIONAL | FLAG_ENJAMBRE_HOY,
			},
		],
	})

	enc.register_zone({
		"id": "lago_surf",
		"base_step_rate": 0.09,
		"entries": [
			{ "species_id": 129, "weight": 90, "min_level": 5, "max_level": 15 },
			{ "species_id": 130, "weight": 5, "min_level": 15, "max_level": 25 },
			{ "species_id": 130, "weight": 8, "min_level": 20, "max_level": 30, "weather": "rain" },
		],
	})


func _build_context() -> Dictionary:
	return {
		"lead_level": Party.leader_level(),
		"time": World.time_of_day,          # 0..3
		"weather": World.weather,           # "", "rain", ...
		"story_flags": GameState.flags,     # int bitmask
		"repel_active": GameState.repel_steps > 0,
		"repel_level": GameState.repel_level,
	}


# Llama a esto desde el controlador del jugador al pisar una casilla nueva.
func on_player_stepped(terrain: String, zone_id: String) -> void:
	if terrain in ["grass", "cave", "water"]:
		enc.set_active_zone(zone_id)
		enc.step(_build_context())          # la señal hace el resto
	else:
		enc.clear_active_zone()


# Dulce Aroma / evento scripteado.
func sweet_scent() -> void:
	enc.force_encounter(_build_context())


func _on_encounter(info: Dictionary) -> void:
	# info = { triggered, species_id, level, zone_id }
	get_tree().call_group("battle", "start_wild_battle", info.species_id, info.level)
