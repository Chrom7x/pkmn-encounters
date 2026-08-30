#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include "enc/encounter_system.h"

// Nodo Godot que envuelve enc::System.
//
// GDScript:
//   var enc := RandomEncounters.new()
//   enc.register_zone({ "id": "ruta_1", "base_step_rate": 0.12, "entries": [...] })
//   enc.set_active_zone("ruta_1")
//   var r := enc.step({ "lead_level": 12, "time": 3, "story_flags": GameState.flags })
//   if r.triggered: start_battle(r.species_id, r.level)
//   # o conéctate a la señal:
//   enc.encounter_started.connect(_on_encounter)
class RandomEncounters : public godot::Node {
    GDCLASS(RandomEncounters, godot::Node);

    enc::System system_;

protected:
    static void _bind_methods();

public:
    RandomEncounters() : system_(0) {}

    void set_seed(int64_t seed);
    void set_active_zone(const godot::String &id);
    void clear_active_zone();
    void set_encounters_enabled(bool enabled);
    void reset_grace();

    // Registra una zona. Formato del Dictionary:
    //   id: String
    //   base_step_rate: float          (def 0.1)
    //   min_steps_between: int         (def 3)
    //   rate_multiplier: float         (def 1.0)
    //   zone_required_flags: int       (def 0; bitmask que debe cumplirse entero)
    //   entries: Array[Dictionary] con:
    //     species_id:int, weight:int, min_level:int, max_level:int,
    //     time:int (0=Any 1=Mañana 2=Día 3=Noche), weather:String,
    //     required_flags:int, forbidden_flags:int
    void register_zone(const godot::Dictionary &data);

    // Devuelven { triggered:bool, species_id:int, level:int, zone_id:String }
    // y, si hay combate, emiten la señal "encounter_started" con ese mismo dict.
    godot::Dictionary step(const godot::Dictionary &ctx);
    godot::Dictionary force_encounter(const godot::Dictionary &ctx);
};
