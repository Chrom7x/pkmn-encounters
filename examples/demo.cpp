// Demo de consola: simula 40 pasos en la ruta 1 y fuerza un encuentro.
#include "enc/encounter_system.h"
#include "zones.hpp"
#include <cstdio>

int main() {
    enc::System sys(/*semilla*/ 1234);
    sys.add_zone(demo::ruta_1());
    sys.add_zone(demo::cueva_niebla());
    sys.add_zone(demo::lago_surf());

    enc::Context ctx;
    ctx.lead_level  = 10;
    ctx.time        = enc::TimeOfDay::Night;
    ctx.story_flags = demo::FLAG_INSIGNIA_NIEBLA;

    std::puts("=== Ruta 1 (noche), 40 pasos ===");
    sys.set_active_zone("ruta_1");
    for (int paso = 1; paso <= 40; ++paso) {
        if (auto r = sys.step(ctx)) {
            std::printf("  paso %2d | %-12s -> especie %3d, Nv %d\n",
                        paso, r.zone_id.c_str(), r.species_id, r.level);
        }
    }

    std::puts("\n=== Cueva Niebla sin la insignia (bloqueada) ===");
    enc::Context sin_insignia = ctx;
    sin_insignia.story_flags = 0;
    sys.set_active_zone("cueva_niebla");
    int combates = 0;
    for (int i = 0; i < 200; ++i) if (sys.step(sin_insignia)) ++combates;
    std::printf("  combates en 200 pasos: %d (esperado 0)\n", combates);

    std::puts("\n=== Dulce Aroma (encuentro forzado) en el lago con lluvia ===");
    enc::Context lluvia = ctx;
    lluvia.weather = "rain";
    sys.set_active_zone("lago_surf");
    if (auto f = sys.force_encounter(lluvia)) {
        std::printf("  forzado -> especie %d, Nv %d\n", f.species_id, f.level);
    }
    return 0;
}
