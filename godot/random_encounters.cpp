#include "random_encounters.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

static enc::Context ctx_from_dict(const Dictionary &d) {
    enc::Context c;
    c.lead_level   = (int)d.get("lead_level", 1);
    c.repel_active = (bool)d.get("repel_active", false);
    c.repel_level  = (int)d.get("repel_level", 0);
    c.ability_mult = (double)d.get("ability_mult", 1.0);
    c.item_mult    = (double)d.get("item_mult", 1.0);
    c.speed_mult   = (double)d.get("speed_mult", 1.0);
    c.time         = (enc::TimeOfDay)(int)d.get("time", 0);
    c.weather      = String(d.get("weather", "")).utf8().get_data();
    c.story_flags  = (uint32_t)(int64_t)d.get("story_flags", 0);
    return c;
}

static Dictionary result_to_dict(const enc::Result &r) {
    Dictionary o;
    o["triggered"]  = r.triggered;
    o["species_id"] = r.species_id;
    o["level"]      = r.level;
    o["zone_id"]    = String(r.zone_id.c_str());
    return o;
}

void RandomEncounters::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_seed", "seed"), &RandomEncounters::set_seed);
    ClassDB::bind_method(D_METHOD("set_active_zone", "id"), &RandomEncounters::set_active_zone);
    ClassDB::bind_method(D_METHOD("clear_active_zone"), &RandomEncounters::clear_active_zone);
    ClassDB::bind_method(D_METHOD("set_encounters_enabled", "enabled"), &RandomEncounters::set_encounters_enabled);
    ClassDB::bind_method(D_METHOD("reset_grace"), &RandomEncounters::reset_grace);
    ClassDB::bind_method(D_METHOD("register_zone", "data"), &RandomEncounters::register_zone);
    ClassDB::bind_method(D_METHOD("step", "ctx"), &RandomEncounters::step);
    ClassDB::bind_method(D_METHOD("force_encounter", "ctx"), &RandomEncounters::force_encounter);

    ADD_SIGNAL(MethodInfo("encounter_started",
        PropertyInfo(Variant::DICTIONARY, "info")));
}

void RandomEncounters::set_seed(int64_t seed) { system_.set_seed((uint32_t)seed); }
void RandomEncounters::set_active_zone(const String &id) { system_.set_active_zone(id.utf8().get_data()); }
void RandomEncounters::clear_active_zone() { system_.clear_active_zone(); }
void RandomEncounters::set_encounters_enabled(bool e) { system_.set_enabled(e); }
void RandomEncounters::reset_grace() { system_.reset_grace(); }

void RandomEncounters::register_zone(const Dictionary &d) {
    enc::Zone z;
    z.id               = String(d.get("id", "")).utf8().get_data();
    z.base_step_rate    = (double)d.get("base_step_rate", 0.1);
    z.min_steps_between = (int)d.get("min_steps_between", 3);
    z.rate_multiplier   = (double)d.get("rate_multiplier", 1.0);

    Array entries = d.get("entries", Array());
    for (int i = 0; i < entries.size(); ++i) {
        Dictionary e = entries[i];
        enc::Entry ent;
        ent.species_id      = (int)e.get("species_id", 0);
        ent.weight          = (int)e.get("weight", 10);
        ent.min_level       = (int)e.get("min_level", 2);
        ent.max_level       = (int)e.get("max_level", 5);
        ent.time            = (enc::TimeOfDay)(int)e.get("time", 0);
        ent.required_weather = String(e.get("weather", "")).utf8().get_data();
        ent.required_flags  = (uint32_t)(int64_t)e.get("required_flags", 0);
        ent.forbidden_flags = (uint32_t)(int64_t)e.get("forbidden_flags", 0);
        z.entries.push_back(std::move(ent));
    }

    uint32_t zf = (uint32_t)(int64_t)d.get("zone_required_flags", 0);
    if (zf) {
        z.zone_predicate = [zf](const enc::Context &c) {
            return (c.story_flags & zf) == zf;
        };
    }
    system_.add_zone(std::move(z));
}

Dictionary RandomEncounters::step(const Dictionary &ctx) {
    enc::Result r = system_.step(ctx_from_dict(ctx));
    Dictionary o = result_to_dict(r);
    if (r.triggered) emit_signal("encounter_started", o);
    return o;
}

Dictionary RandomEncounters::force_encounter(const Dictionary &ctx) {
    enc::Result r = system_.force_encounter(ctx_from_dict(ctx));
    Dictionary o = result_to_dict(r);
    if (r.triggered) emit_signal("encounter_started", o);
    return o;
}
