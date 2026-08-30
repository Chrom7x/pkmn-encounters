class_name DialogueLine
extends Resource
## Una línea de diálogo: quién habla, qué dice y (opcionalmente) qué opciones
## se ofrecen después.

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var portrait: Texture2D

## Si tiene elementos, se muestran como decisión tras esta línea.
@export var choices: Array[DialogueChoice] = []

## 0 = espera a que el jugador pulse "interact". > 0 = avanza sola tras N segundos
## (útil para líneas de ambiente en cinemáticas).
@export_range(0.0, 10.0, 0.1) var auto_advance_delay: float = 0.0

## Nombre de evento que EventBus.dispatch lanzará al mostrar la línea (opcional:
## sirve para sincronizar retratos, sonidos, sacudidas de cámara...).
@export var on_show_event: StringName = &""
