# pkmn-encounters

Sistema de **encuentros aleatorios estilo Pokémon** en C++17, sin dependencias
externas y **agnóstico del motor**. El núcleo (`include/` + `src/`) compila en
cualquier sitio; en `godot/` hay una GDExtension lista para Godot 4.

## Qué hace

- Tirada por paso con **tasa configurable por zona**.
- **Pasos de gracia** tras cada combate (evita encuentros encadenados).
- Tablas de encuentro con **peso**, rango de nivel y **condiciones por entrada**:
  franja horaria, clima, flags de historia (bitmask) y un `predicate` libre.
- **Condición a nivel de zona entera** (p. ej. cueva bloqueada hasta cierta medalla).
- **Repelente**, multiplicadores por habilidad / objeto / velocidad.
- `force_encounter()` para Dulce Aroma, eventos scripteados o debug.
- RNG **determinista y seedeable** (fácil de testear).

## Estructura

```
include/enc/encounter_system.h   API pública del núcleo
src/encounter_system.cpp         implementación
examples/zones.hpp               zonas de ejemplo (ruta, cueva, lago)
examples/demo.cpp                demo de consola
tests/test_encounter_system.cpp  tests sin framework (CTest)
godot/                           GDExtension para Godot 4 + proyecto de ejemplo
CMakeLists.txt
```

## Compilar y probar (núcleo)

```bash
cmake -S . -B build
cmake --build build
./build/enc_demo            # (Windows: build\Debug\enc_demo.exe)
ctest --test-dir build --output-on-failure
```

Sin CMake:

```bash
c++ -std=c++17 -Iinclude -Iexamples examples/demo.cpp src/encounter_system.cpp -o demo
```

## Uso mínimo (C++)

```cpp
#include "enc/encounter_system.h"

enc::System sys(1234);

enc::Zone ruta;
ruta.id = "ruta_1";
ruta.base_step_rate = 0.12f;      // 12% por paso
ruta.min_steps_between = 4;       // 4 pasos de gracia
ruta.entries = {
    { /*species*/ 19, /*weight*/ 40, /*min*/ 2, /*max*/ 4 },
    { 43, 20, 3, 5, enc::TimeOfDay::Night },              // solo de noche
};
sys.add_zone(std::move(ruta));

sys.set_active_zone("ruta_1");

enc::Context ctx;
ctx.lead_level = 10;
ctx.time = enc::TimeOfDay::Night;

// una vez por cada casilla que pisa el jugador:
if (auto r = sys.step(ctx))
    start_battle(r.species_id, r.level);
```

## Cómo se ajusta

| Quieres… | Toca esto |
|---|---|
| Más / menos encuentros en una zona | `Zone::base_step_rate` (0.05 tranquilo · 0.20 agobiante) |
| Que no salgan combates seguidos | `Zone::min_steps_between` |
| Un Pokémon solo de noche / con lluvia | `Entry::time`, `Entry::required_weather` |
| Contenido que se desbloquea con la historia | `Entry::required_flags` / `forbidden_flags`, o `Zone::zone_predicate` |
| Regla rara y específica (racha, día, sub-zona…) | `Entry::predicate` (lambda libre) |
| Repelente / habilidades / objetos | campos de `Context` (`repel_*`, `ability_mult`, `item_mult`) |
| Encuentro garantizado por evento | `force_encounter()` |
| Desactivar todo en una cinemática | `System::set_enabled(false)` |

## Godot

Ver [`godot/README.md`](godot/README.md). RPG Maker no admite C++ nativo
(MV/MZ usan JavaScript, VX Ace usa Ruby), por eso la integración de motor se
muestra solo en Godot; el núcleo sirve igual para un motor propio con SDL/raylib.

## Modelo de la tirada

Por cada `step()` sobre una casilla de encuentro:

1. Si no hay zona activa, está deshabilitada o el `zone_predicate` falla → nada.
2. Si `steps_since_encounter < min_steps_between` → suma 1 y termina (gracia).
3. `rand[0,1) >= base_step_rate * rate_multiplier * ability_mult * item_mult * speed_mult` → nada.
4. Elige una entrada por peso entre las que cumplen hora/clima/flags/predicate.
5. Nivel aleatorio uniforme en `[min_level, max_level]`.
6. Si el repelente está activo y `nivel < repel_level` → se anula el combate.
7. Combate: se emite el resultado y se reinicia el contador de gracia.
