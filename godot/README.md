# Integración con Godot 4 (GDExtension)

Envuelve el núcleo `enc::System` en un nodo `RandomEncounters` usable desde GDScript.

## Compilar

```bash
cd godot
git clone -b 4.3 https://github.com/godotengine/godot-cpp   # o la rama de tu Godot
scons target=template_debug            # genera la .dll/.so/.framework
scons target=template_release
```

La biblioteca se copia a `godot/demo_project/bin/`. Junto a ella está
`encounters.gdextension`, que Godot carga automáticamente al abrir un proyecto
cuyo `res://bin/` contenga ambos archivos.

## Usar en tu proyecto

1. Copia `bin/encounters.gdextension` y la biblioteca compilada a `res://bin/`
   de tu juego.
2. Abre Godot: la clase `RandomEncounters` ya aparece como nodo/tipo.
3. Mira `demo_project/EncounterController.gd` para el patrón de uso:
   - `register_zone({...})` una vez por zona al arrancar el mapa.
   - `set_active_zone(id)` al entrar en hierba/cueva/agua, `clear_active_zone()` al salir.
   - `step(ctx)` una vez por casilla nueva que pisa el jugador.
   - Conéctate a la señal `encounter_started(info)`.
   - `force_encounter(ctx)` para Dulce Aroma o eventos.

## API del nodo

| Método | Descripción |
|---|---|
| `set_seed(int)` | Semilla del RNG. |
| `register_zone(Dictionary)` | Define una zona y su tabla (formato en `random_encounters.h`). |
| `set_active_zone(String)` / `clear_active_zone()` | Zona activa. |
| `set_encounters_enabled(bool)` | Apaga todo (cinemáticas). |
| `reset_grace()` | Reinicia los pasos de gracia. |
| `step(Dictionary) -> Dictionary` | Una tirada por paso. |
| `force_encounter(Dictionary) -> Dictionary` | Tirada inmediata sin gracia. |
| señal `encounter_started(info)` | Se emite cuando hay combate. |

`time`: `0` cualquiera · `1` mañana · `2` día · `3` noche.
