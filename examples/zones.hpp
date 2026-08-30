// Definiciones de zonas de ejemplo, compartidas por el demo y los tests.
#pragma once
#include "enc/encounter_system.h"

namespace demo {

// Bits de progreso de la historia (ejemplo).
enum StoryFlag : uint32_t {
    FLAG_POKEDEX_NACIONAL = 1u << 0,
    FLAG_INSIGNIA_NIEBLA  = 1u << 1,
    FLAG_ENJAMBRE_HOY     = 1u << 2,
};

// IDs de especie (números de la Pokédex, a modo de ejemplo).
enum Species {
    RATATA = 19, PIDGEY = 16, ODDISH = 43, ZUBAT = 41, GOLBAT = 42,
    MAGIKARP = 129, GYARADOS = 130, DRATINI = 147, NOCTOWL = 164,
};

// Ruta con hierba: mezcla básica; algunos bichos solo de noche.
inline enc::Zone ruta_1() {
    enc::Zone z;
    z.id = "ruta_1";
    z.method = enc::Method::Grass;
    z.base_step_rate    = 0.12f;
    z.min_steps_between = 4;
    z.entries = {
        { RATATA, 40, 2, 4 },
        { PIDGEY, 35, 2, 5 },
        { ODDISH, 20, 3, 5, enc::TimeOfDay::Night },     // solo de noche
        { NOCTOWL, 5, 8, 12, enc::TimeOfDay::Night },
    };
    return z;
}

// Cueva bloqueada: la zona entera no existe sin la Insignia Niebla.
inline enc::Zone cueva_niebla() {
    enc::Zone z;
    z.id = "cueva_niebla";
    z.method = enc::Method::Cave;
    z.base_step_rate    = 0.18f;
    z.min_steps_between = 3;
    z.zone_predicate = [](const enc::Context& c) {
        return (c.story_flags & FLAG_INSIGNIA_NIEBLA) != 0;
    };
    z.entries = {
        { ZUBAT,  60,  6, 10 },
        { GOLBAT, 15, 12, 16 },
        // Dratini: raro, y solo con Pokédex Nacional Y durante un enjambre.
        { DRATINI, 3, 15, 18, enc::TimeOfDay::Any, "",
          FLAG_POKEDEX_NACIONAL | FLAG_ENJAMBRE_HOY, 0 },
    };
    return z;
}

// Agua (surf): Magikarp por todas partes; Gyarados más probable con lluvia.
inline enc::Zone lago_surf() {
    enc::Zone z;
    z.id = "lago_surf";
    z.method = enc::Method::Water;
    z.base_step_rate = 0.09f;
    z.entries = {
        { MAGIKARP, 90,  5, 15 },
        { GYARADOS,  5, 15, 25 },
        { GYARADOS,  8, 20, 30, enc::TimeOfDay::Any, "rain" },
    };
    return z;
}

} // namespace demo
