// Sistema de encuentros aleatorios estilo Pokémon.
// C++17, sin dependencias externas, agnóstico del motor.
//
// Uso típico:
//   enc::System sys(semilla);
//   sys.add_zone(...);                 // define todas las zonas al arrancar
//   sys.set_active_zone("ruta_1");     // al pisar hierba / cueva / agua
//   for cada paso del jugador:
//       if (auto r = sys.step(ctx)) start_battle(r.species_id, r.level);
//
#pragma once
#include <cstdint>
#include <functional>
#include <random>
#include <string>
#include <vector>

namespace enc {

enum class Method    { Grass, Water, Fishing, Cave, Custom };
enum class TimeOfDay { Any, Morning, Day, Night };

// Estado del jugador y del mundo en el instante del paso. Lo rellena tu juego.
struct Context {
    int   lead_level   = 1;       // nivel del Pokémon que va primero en el equipo
    bool  repel_active = false;
    int   repel_level  = 0;       // se bloquean encuentros de nivel < repel_level
    float ability_mult = 1.0f;    // habilidad del guía: 0.5 reduce, 2.0 aumenta...
    float item_mult    = 1.0f;    // objeto equipado (amuleto, etc.)
    float speed_mult   = 1.0f;    // bici / correr (ajústalo a tu gusto; 1.0 = igual)
    TimeOfDay   time   = TimeOfDay::Any;
    std::string weather;          // "" = sin clima; "rain", "sandstorm", "fog"...
    uint32_t    story_flags = 0;  // bitmask de progreso de la historia
};

// Una entrada de la tabla de encuentros de una zona.
struct Entry {
    int species_id = 0;
    int weight     = 10;          // peso relativo dentro de la zona
    int min_level  = 2;
    int max_level  = 5;

    // --- Condiciones (todas opcionales; por defecto "siempre") ---
    TimeOfDay   time            = TimeOfDay::Any;   // filtro por franja horaria
    std::string required_weather;                   // "" = cualquier clima
    uint32_t    required_flags  = 0;   // TODOS estos bits deben estar activos
    uint32_t    forbidden_flags = 0;   // NINGUNO de estos bits puede estar activo
    std::function<bool(const Context&)> predicate;  // condición libre extra
};

// Una zona = una tabla de encuentros para un tipo de terreno de un mapa.
// Un mapa con hierba y agua se modela como dos zonas distintas.
struct Zone {
    std::string id;
    Method method           = Method::Grass;
    float  base_step_rate    = 0.10f;  // probabilidad por paso válido (0..1)
    int    min_steps_between = 3;      // pasos de "gracia" tras un combate
    float  rate_multiplier   = 1.0f;   // ajuste fino propio de la zona
    bool   enabled           = true;   // desactívala sin borrarla
    std::vector<Entry> entries;
    std::function<bool(const Context&)> zone_predicate; // habilita la zona entera
};

struct Result {
    bool triggered  = false;
    int  species_id = 0;
    int  level      = 0;
    std::string zone_id;
    explicit operator bool() const { return triggered; }
};

class System {
public:
    explicit System(uint32_t seed = std::random_device{}());

    // --- Configuración (hazla toda antes del primer step) ---
    void  add_zone(Zone zone);
    Zone* find_zone(const std::string& id);
    void  set_seed(uint32_t seed);
    void  set_enabled(bool e) { enabled_ = e; }   // apágalo en cinemáticas

    // --- Runtime ---
    void set_active_zone(const std::string& id);  // al entrar a un terreno
    void clear_active_zone();                     // al salir a zona sin encuentros
    void reset_grace();                           // reinicia el contador de pasos

    // Llamar UNA vez por cada paso del jugador sobre una casilla de encuentro.
    Result step(const Context& ctx);

    // Ignora la acumulación de pasos: Dulce Aroma, eventos scripteados, debug.
    Result force_encounter(const Context& ctx);

    const std::string& active_zone_id() const { return active_id_; }
    int  steps_since_encounter() const { return steps_since_encounter_; }

private:
    std::mt19937 rng_;
    std::vector<Zone> zones_;
    std::string active_id_;
    int  steps_since_encounter_ = 0;
    bool enabled_ = true;

    float unit();                                       // real en [0,1)
    bool  entry_allowed(const Entry&, const Context&) const;
    const Entry* pick_entry(const Zone&, const Context&);
    int   roll_level(const Entry&);
    float effective_rate(const Zone&, const Context&) const;
    Result evaluate(const Context&, bool ignore_grace);
};

} // namespace enc
