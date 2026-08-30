# pkmn-encounters

Repositorio con varios sistemas para un fan game estilo Pokémon:

1. **Encuentros aleatorios** — C++17, sin dependencias, agnóstico del motor
   (`include/` + `src/`, con GDExtension para Godot 4 en `godot/`).
2. **Combate** — GDScript (Godot 4): tipos, físico/especial, escalado de stats,
   daño y curvas de nivel. Ver [`godot/combat_system/`](godot/combat_system/COMBAT.md).
3. **Diálogos y cinemáticas** — GDScript (Godot 4): diálogos con decisiones que
   disparan acciones, y un *sequencer* de cinemáticas con `await`. Modular y
   desacoplado (EventBus / GameActions / Flags). Ver
   [`godot/narrative_system/`](godot/narrative_system/NARRATIVE.md).

---

## 1) Encuentros aleatorios (C++)

Sistema de encuentros aleatorios estilo Pokémon en C++17, sin dependencias
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

---

## 2) Combate (GDScript / Godot 4)

Carpeta [`godot/combat_system/`](godot/combat_system/) — proyecto Godot 4.3
independiente (GDScript puro, sin la GDExtension). Cubre:

- **Tipos:** enum `PokeTypes.Type` con los 18 tipos oficiales + tabla de
  efectividad completa. Cada `MoveData` tiene **un único** tipo.
- **Físico vs Especial:** `MoveData.Category`. El daño escala con Ataque o
  Ataque Especial del atacante y se mitiga con la Defensa o Defensa Especial
  correspondiente del objetivo (`DamageCalculator`).
- **Escalado de stats:** `StatCalculator` con la fórmula Gen III+ (base, IV, EV,
  naturaleza) y stages −6…+6 en combate.
- **Nivel y EXP:** `GrowthRate` implementa las **6 curvas clásicas**; `Battler`
  gestiona la subida de nivel y el aprendizaje de movimientos; `Experience`
  reparte EXP y EV al derrotar.
- **Recursos modulares:** `MoveData`, `SpeciesData`, `StatBlock`, `MoveEffect` y
  `LearnsetEntry` son `Resource`, editables en el inspector. Hay `.tres` de
  ejemplo en `godot/combat_system/data/moves/`.

Detalle completo y fórmulas en [`godot/combat_system/COMBAT.md`](godot/combat_system/COMBAT.md).

---

## 3) Diálogos y cinemáticas (GDScript / Godot 4)

Carpeta [`godot/narrative_system/`](godot/narrative_system/) — proyecto Godot 4.3
independiente, GDScript puro. Todo gira en torno a 5 autoloads que mantienen los
sistemas **desacoplados**: `EventBus` (señales globales + canal genérico),
`Flags` (estado), `GameActions` (registro `id → Callable`), `DialogueManager`,
`CutsceneManager`.

- **Diálogos con decisión:** `DialogueData` → `DialogueLine` → `DialogueChoice`
  (todos `Resource`). Cada opción lleva `actions: Array[GameAction]` y una rama
  `next`. Acciones listas: emitir evento, llamar acción registrada (async),
  activar flag, abrir tienda, curar equipo, teletransportar (Vuelo), lanzar otra
  cinemática/diálogo. "Rechazar" = opción sin acciones.
- **Sequencer de cinemáticas:** `Cutscene` → `Array[CutsceneStep]`. El
  `CutsceneManager` hace `await step.run(ctx)` en orden. Pasos: mover actor,
  mover/zoom cámara, animación, **diálogo con espera de respuesta**, acción,
  emitir evento, bifurcación (`StepBranch`) y paralelo (`StepParallel`).
- **Interacción en el mundo:** `Interactable` (`Area2D`, se le arrastra un
  diálogo o cinemática) + `Interactor` (en el jugador).
- **UI incluida y reemplazable:** `DialogueUI` se auto-registra; puedes poner la
  tuya con `DialogueManager.register_ui()`. Sin UI, el diálogo se resuelve solo.

Estructura de nodos, flujo y guía de extensión en
[`godot/narrative_system/NARRATIVE.md`](godot/narrative_system/NARRATIVE.md).
