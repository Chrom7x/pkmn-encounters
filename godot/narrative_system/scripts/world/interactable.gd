class_name Interactable
extends Area2D
## Componente para NPCs, carteles, máquinas del Centro Pokémon, etc.
## Arrástrale un DialogueData o una Cutscene en el inspector y listo: añadir
## interacciones NO requiere programar.
##
## Estructura de nodos sugerida:
##   NPC (CharacterBody2D)
##   └── Interactable (Area2D, este script)
##       └── CollisionShape2D   (el "radio de interacción")
##
## El jugador (ver interactor.gd) detecta el Interactable solapado y llama a
## interact().

signal interaction_started
signal interaction_finished

@export var dialogue: DialogueData
@export var cutscene: Cutscene

@export_group("Reglas")
## Solo se puede usar una vez por partida.
@export var one_shot: bool = false
## Solo disponible si este flag está activo ("" = sin requisito).
@export var require_flag: StringName = &""
## Activa este flag al terminar la interacción ("" = ninguno).
@export var set_flag_on_finish: StringName = &""
## Contexto extra que se pasa al diálogo (y como ctx.data en la cinemática).
@export var context: Dictionary = {}

var _used: bool = false
var _busy: bool = false


func can_interact() -> bool:
	if _busy:
		return false
	if one_shot and _used:
		return false
	if require_flag != &"" and not Flags.has_flag(require_flag):
		return false
	return dialogue != null or cutscene != null


## Llamado por el jugador. Es asíncrono: `await npc.interact()` si quieres
## esperar a que acabe.
func interact() -> void:
	if not can_interact():
		return
	_busy = true
	_used = true
	interaction_started.emit()

	if cutscene:
		var ctx := CutsceneContext.new()
		ctx.data = context.duplicate()
		await CutsceneManager.play(cutscene, ctx)
	elif dialogue:
		await DialogueManager.start(dialogue, context)

	if set_flag_on_finish != &"":
		Flags.set_flag(set_flag_on_finish)

	_busy = false
	interaction_finished.emit()
