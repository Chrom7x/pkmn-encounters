class_name ActionSetFlag
extends GameAction
## Define un flag en `Flags`. Útil para recordar decisiones ("rechazó la ayuda",
## "compró la poción", "desbloqueó Vuelo").

@export var flag: StringName = &""
## Interruptor on/off (lo más habitual). Para guardar un número o un texto en su
## lugar, rellena `number_value` / `string_value` y sube `value_kind`.
@export var value: bool = true

enum ValueKind { BOOL, NUMBER, STRING }
@export var value_kind: ValueKind = ValueKind.BOOL
@export var number_value: float = 0.0
@export var string_value: String = ""


func execute(_ctx: ActionContext) -> void:
	if flag == &"":
		return
	match value_kind:
		ValueKind.NUMBER:
			Flags.set_flag(flag, number_value)
		ValueKind.STRING:
			Flags.set_flag(flag, string_value)
		_:
			Flags.set_flag(flag, value)
