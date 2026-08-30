class_name DialogueData
extends Resource
## Una conversación completa. Crea un .tres por conversación y edítala en el
## inspector (o constrúyela por código).
##
## Estructura:  DialogueData → [DialogueLine, DialogueLine, ...]
##              cada DialogueLine puede llevar [DialogueChoice, ...]
##
## Flujo: se muestran las líneas en orden. Si una línea tiene opciones, se
## presentan tras ella; al elegir una se ejecutan sus acciones y se salta a
## `choice.next` (o termina). Si ninguna línea abre una rama, al acabar se
## continúa por `next` (encadenado lineal).

@export var id: StringName = &""
@export var lines: Array[DialogueLine] = []

## Diálogo que se reproduce a continuación si no hubo ninguna decisión con rama.
@export var next: DialogueData
