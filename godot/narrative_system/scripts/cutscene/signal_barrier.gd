class_name SignalBarrier
extends RefCounted
## Utilidad para esperar a que N corrutinas terminen (usado por StepParallel).
##
##   var b := SignalBarrier.new(tareas.size())
##   for t in tareas:
##       _lanzar(t, b)          # corrutina no-esperada que llama b.one_done() al acabar
##   await b.completed

signal completed

var _remaining: int


func _init(count: int) -> void:
	_remaining = count
	if _remaining <= 0:
		# Nadie va a llamar one_done(): completa en el siguiente frame.
		completed.emit.call_deferred()


func one_done() -> void:
	_remaining -= 1
	if _remaining == 0:
		completed.emit()
