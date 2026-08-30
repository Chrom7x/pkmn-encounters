class_name ActionContext
extends RefCounted
## Contexto que recibe GameAction.execute(). Le da a la acción acceso al árbol
## y al "scratch" compartido con el diálogo o la cinemática que la lanzó.

var source: Object = null      ## quién dispara: DialogueManager, CutsceneManager, un NPC...
var tree: SceneTree = null     ## para timers, esperar frames, buscar nodos
var data: Dictionary = {}      ## datos libres compartidos (resultados, banderas locales)
