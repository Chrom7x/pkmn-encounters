class_name CutsceneContext
extends RefCounted
## Todo lo que los pasos necesitan del mundo real, en un solo objeto. Lo rellena
## quien lanza la cinemática (una escena, un Interactable) antes de llamar a
## CutsceneManager.play().
##
##   var ctx := CutsceneContext.new()
##   ctx.register_actor(&"player", $Player)
##   ctx.register_actor(&"rival", $Rival)
##   ctx.register_marker(&"puerta", $Marcadores/Puerta)
##   ctx.camera = $Camera2D
##   await CutsceneManager.play(intro, ctx)

var manager: Node = null            ## el CutsceneManager (lo pone play())
var tree: SceneTree = null          ## para timers / esperar frames
var camera: Node = null             ## normalmente un Camera2D

var actors: Dictionary = {}         ## StringName -> Node
var markers: Dictionary = {}        ## StringName -> Node2D | Vector2
var data: Dictionary = {}           ## scratch: resultados de diálogo, sub-estados

## Lo pone a true CutsceneManager cuando se pulsa "cutscene_skip". Los pasos
## largos deben consultarlo para acortar (ir directos al estado final).
var skipping: bool = false


func register_actor(name: StringName, node: Node) -> void:
	actors[name] = node


func get_actor(name: StringName) -> Node:
	return actors.get(name)


func register_marker(name: StringName, marker: Variant) -> void:
	markers[name] = marker


func get_marker_position(name: StringName) -> Vector2:
	var m: Variant = markers.get(name)
	if m is Vector2:
		return m
	if m is Node2D:
		return (m as Node2D).global_position
	return Vector2.ZERO


## Convierte este contexto en el que esperan las GameAction (para StepAction).
func to_action_context() -> ActionContext:
	var a := ActionContext.new()
	a.source = manager
	a.tree = tree
	a.data = data
	return a
