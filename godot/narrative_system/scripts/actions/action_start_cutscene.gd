class_name ActionStartCutscene
extends GameAction
## Lanza una cinemática. Ejemplo: al aceptar "usar Vuelo", reproducir la
## secuencia de animación + teletransporte.

@export var cutscene: Cutscene
## true = espera a que la cinemática termine antes de seguir con el diálogo.
@export var wait_until_finished: bool = true


func execute(_ctx: ActionContext) -> void:
	if cutscene == null:
		return
	if wait_until_finished:
		await CutsceneManager.play(cutscene)
	else:
		CutsceneManager.play(cutscene)
