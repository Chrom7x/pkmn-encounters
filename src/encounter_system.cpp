#include "enc/encounter_system.h"
#include <algorithm>

namespace enc {

System::System(uint32_t seed) : rng_(seed) {}

void System::add_zone(Zone zone) { zones_.push_back(std::move(zone)); }

Zone* System::find_zone(const std::string& id) {
    for (auto& z : zones_) if (z.id == id) return &z;
    return nullptr;
}

void System::set_seed(uint32_t s) { rng_.seed(s); }

void System::set_active_zone(const std::string& id) {
    if (active_id_ != id) { active_id_ = id; steps_since_encounter_ = 0; }
}
void System::clear_active_zone() { active_id_.clear(); }
void System::reset_grace()       { steps_since_encounter_ = 0; }

float System::unit() {
    return std::uniform_real_distribution<float>(0.0f, 1.0f)(rng_);
}

bool System::entry_allowed(const Entry& e, const Context& ctx) const {
    if (e.time != TimeOfDay::Any && e.time != ctx.time)                   return false;
    if (!e.required_weather.empty() && e.required_weather != ctx.weather) return false;
    if ((ctx.story_flags & e.required_flags)  != e.required_flags)        return false;
    if ((ctx.story_flags & e.forbidden_flags) != 0)                      return false;
    if (e.predicate && !e.predicate(ctx))                               return false;
    return true;
}

// Selección ponderada entre las entradas que cumplen las condiciones actuales.
const Entry* System::pick_entry(const Zone& z, const Context& ctx) {
    long total = 0;
    for (const auto& e : z.entries)
        if (e.weight > 0 && entry_allowed(e, ctx)) total += e.weight;
    if (total <= 0) return nullptr;

    long r = std::uniform_int_distribution<long>(0, total - 1)(rng_);
    for (const auto& e : z.entries) {
        if (e.weight <= 0 || !entry_allowed(e, ctx)) continue;
        if (r < e.weight) return &e;
        r -= e.weight;
    }
    return nullptr; // inalcanzable si total > 0
}

int System::roll_level(const Entry& e) {
    int lo = std::min(e.min_level, e.max_level);
    int hi = std::max(e.min_level, e.max_level);
    return std::uniform_int_distribution<int>(lo, hi)(rng_);
}

float System::effective_rate(const Zone& z, const Context& ctx) const {
    float r = z.base_step_rate * z.rate_multiplier
            * ctx.ability_mult * ctx.item_mult * ctx.speed_mult;
    return std::clamp(r, 0.0f, 1.0f);
}

Result System::evaluate(const Context& ctx, bool ignore_grace) {
    Result out;
    if (!enabled_ || active_id_.empty()) return out;

    Zone* z = find_zone(active_id_);
    if (!z || !z->enabled)                            return out;
    if (z->zone_predicate && !z->zone_predicate(ctx)) return out;

    if (!ignore_grace) {
        // Pasos de gracia: nada de combates justo después de otro.
        if (steps_since_encounter_ < z->min_steps_between) {
            ++steps_since_encounter_;
            return out;
        }
        // Tirada de la tasa por paso.
        if (unit() >= effective_rate(*z, ctx)) {
            ++steps_since_encounter_;
            return out;
        }
    }

    const Entry* e = pick_entry(*z, ctx);
    if (!e) { if (!ignore_grace) ++steps_since_encounter_; return out; }

    int level = roll_level(*e);

    // Repelente: anula el combate pero consume la tirada.
    if (ctx.repel_active && level < ctx.repel_level) {
        steps_since_encounter_ = 0;
        return out;
    }

    out.triggered  = true;
    out.species_id = e->species_id;
    out.level      = level;
    out.zone_id    = z->id;
    steps_since_encounter_ = 0;
    return out;
}

Result System::step(const Context& ctx)            { return evaluate(ctx, false); }
Result System::force_encounter(const Context& ctx) { return evaluate(ctx, true);  }

} // namespace enc
