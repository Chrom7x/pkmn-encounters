// Tests sin framework: cada CHECK que falla imprime y suma al contador.
// Devuelve 0 si todo pasa (lo usa CTest).
#include "enc/encounter_system.h"
#include "../examples/zones.hpp"
#include <cstdio>

static int g_failed = 0;
#define CHECK(cond)                                                        \
    do {                                                                  \
        if (!(cond)) {                                                    \
            std::printf("FALLO  %s:%d  %s\n", __FILE__, __LINE__, #cond); \
            ++g_failed;                                                   \
        }                                                                 \
    } while (0)

// Zona mínima: una entrada, tasa 100%, para aislar reglas concretas.
static enc::Zone always_zone() {
    enc::Zone z;
    z.id = "test";
    z.base_step_rate    = 1.0f;
    z.min_steps_between = 0;
    z.entries = { { /*species*/ 7, /*weight*/ 100, /*min*/ 10, /*max*/ 10 } };
    return z;
}

static void test_determinismo() {
    auto run = [](uint32_t seed) {
        enc::System s(seed);
        s.add_zone(demo::ruta_1());
        s.set_active_zone("ruta_1");
        enc::Context c; c.time = enc::TimeOfDay::Night;
        std::string trace;
        for (int i = 0; i < 300; ++i)
            if (auto r = s.step(c))
                trace += std::to_string(r.species_id) + "@" + std::to_string(r.level) + ";";
        return trace;
    };
    CHECK(run(42) == run(42));
    CHECK(run(42) != run(43));
}

static void test_pasos_de_gracia() {
    enc::System s(1);
    enc::Zone z = always_zone();
    z.min_steps_between = 5;   // 5 pasos sin nada, el 6º ya puede
    s.add_zone(z);
    s.set_active_zone("test");
    enc::Context c;
    for (int i = 0; i < 5; ++i) CHECK(!s.step(c));
    CHECK(s.step(c));          // 6º paso
}

static void test_tasa_cero_nunca() {
    enc::System s(1);
    enc::Zone z = always_zone();
    z.base_step_rate = 0.0f;
    s.add_zone(z);
    s.set_active_zone("test");
    enc::Context c;
    int hits = 0;
    for (int i = 0; i < 1000; ++i) if (s.step(c)) ++hits;
    CHECK(hits == 0);
}

static void test_gate_de_zona() {
    enc::System s(1);
    enc::Zone z = always_zone();
    z.zone_predicate = [](const enc::Context& c) { return c.story_flags & 1u; };
    s.add_zone(z);
    s.set_active_zone("test");

    enc::Context sin; int a = 0;
    for (int i = 0; i < 200; ++i) if (s.step(sin)) ++a;
    CHECK(a == 0);

    enc::Context con; con.story_flags = 1u; int b = 0;
    for (int i = 0; i < 200; ++i) if (s.step(con)) ++b;
    CHECK(b > 0);
}

static void test_filtro_horario() {
    enc::System s(1);
    enc::Zone z = always_zone();
    z.entries[0].time = enc::TimeOfDay::Night;   // única entrada: solo noche
    s.add_zone(z);
    s.set_active_zone("test");

    enc::Context dia; dia.time = enc::TimeOfDay::Day;
    int d = 0;
    for (int i = 0; i < 200; ++i) if (s.step(dia)) ++d;
    CHECK(d == 0);                               // sin candidatos válidos

    enc::Context noche; noche.time = enc::TimeOfDay::Night;
    CHECK(s.step(noche));
}

static void test_repelente() {
    enc::System s(1);
    enc::Zone z = always_zone();                 // nivel fijo 10
    s.add_zone(z);
    s.set_active_zone("test");

    enc::Context rep; rep.repel_active = true; rep.repel_level = 20;
    int blocked = 0;
    for (int i = 0; i < 200; ++i) if (!s.step(rep)) ++blocked;
    CHECK(blocked == 200);

    enc::Context ok; ok.repel_active = true; ok.repel_level = 5;
    CHECK(s.step(ok));
}

static void test_force_ignora_gracia() {
    enc::System s(1);
    enc::Zone z = always_zone();
    z.min_steps_between = 999;
    s.add_zone(z);
    s.set_active_zone("test");
    enc::Context c;
    CHECK(!s.step(c));                 // gracia lo bloquea
    CHECK(s.force_encounter(c));       // forzado lo salta
}

static void test_pesos_distribucion() {
    enc::System s(12345);
    enc::Zone z;
    z.id = "w";
    z.base_step_rate = 1.0f;
    z.min_steps_between = 0;
    z.entries = {
        { /*A*/ 1, /*weight*/ 75, 5, 5 },
        { /*B*/ 2, /*weight*/ 25, 5, 5 },
    };
    s.add_zone(z);
    s.set_active_zone("w");
    enc::Context c;
    int a = 0, b = 0;
    for (int i = 0; i < 20000; ++i) {
        auto r = s.step(c);
        if (r.species_id == 1) ++a; else if (r.species_id == 2) ++b;
    }
    double ratio = double(a) / double(a + b);
    CHECK(ratio > 0.70 && ratio < 0.80);   // ~0.75
}

int main() {
    test_determinismo();
    test_pasos_de_gracia();
    test_tasa_cero_nunca();
    test_gate_de_zona();
    test_filtro_horario();
    test_repelente();
    test_force_ignora_gracia();
    test_pesos_distribucion();

    if (g_failed == 0) { std::puts("OK: todos los tests pasan"); return 0; }
    std::printf("TESTS FALLIDOS: %d\n", g_failed);
    return 1;
}
