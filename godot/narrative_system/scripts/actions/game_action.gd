class_name GameAction
extends Resource
## Base de todas las acciones que se pueden disparar desde una opción de diálogo
## o desde un paso de cinemática (StepAction).
##
## Sobrescribe `execute()`. Puede ser asíncrona (usar await): quien la lanza la
## espera con `await action.execute(ctx)`.
##
## Acciones genéricas incluidas:
##   ActionEmitEvent      -> EventBus.dispatch(id, payload)          (fire & forget)
##   ActionRunId          -> GameActions.run(id, params)            (espera retorno)
##   ActionSetFlag        -> Flags.set_flag(...)
##   ActionStartDialogue  -> DialogueManager.start(...)
##   ActionStartCutscene  -> CutsceneManager.play(...)
##   ActionWait           -> pausa N segundos
## Ejemplos de acción de juego (finas envolturas sobre lo anterior):
##   ActionHealParty, ActionOpenShop, ActionTeleport

## Nota para el inspector; no afecta a la lógica.
@export var comment: String = ""


func execute(_ctx: ActionContext) -> void:
	push_warning("GameAction sin implementar: %s" % [comment if comment else resource_path])
	# Mantiene a `execute` como corrutina para el analizador estático.
	await (Engine.get_main_loop() as SceneTree).process_frame
