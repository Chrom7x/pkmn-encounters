extends Node2D
## Demo del Centro Pokémon + Poké Mart (comprar/vender).
##
## Escena nueva con un Node2D raíz, este script adjunto, F6. Pulsa E / Espacio
## para avanzar los diálogos; usa ratón o flechas + Enter en la tienda.
## (Requiere los 8 autoloads del project.godot.)

func _ready() -> void:
	add_child(DialogueUI.new())
	add_child(ShopUI.new())
	var healer := HealingStation.new()
	healer.heal_duration = 0.6
	add_child(healer)

	# Sistema de equipo de mentira: aporta la restauración real tras la máquina.
	GameActions.register(&"party_restore",
		func(_p: Dictionary) -> void: print("  > (equipo) PS, PP y estados restaurados"))

	EventBus.item_bought.connect(
		func(id: StringName, q: int, t: int): print("[compra] %s x%d  -%d₽" % [id, q, t]))
	EventBus.item_sold.connect(
		func(id: StringName, q: int, t: int): print("[venta]  %s x%d  +%d₽" % [id, q, t]))
	EventBus.party_healed.connect(func(): print("  > ¡Equipo curado!"))

	print("Objetos en la base de datos: ", ItemDatabase.ids())
	print("Dinero inicial: %d₽" % Inventory.money)

	print("\n--- Centro Pokémon ---")
	await DialogueManager.start(_nurse_dialogue())

	print("\n--- Poké Mart ---")
	Inventory.add_item(&"pocion", 3)   # algo para probar la venta
	await DialogueManager.start(_clerk_dialogue(_build_shop()))

	print("\nDinero final: %d₽" % Inventory.money)
	print("Bolsa final:")
	for e in Inventory.entries():
		print("  %s x%d" % [e["id"], e["count"]])
	print("--- Fin de la demo ---")


# ---------------------------------------------------------------- tienda
func _build_shop() -> ShopData:
	var shop := ShopData.new()
	shop.id = &"mart_ciudad_verde"
	shop.display_name = "Poké Mart de Ciudad Verde"
	shop.greeting = "¡Bienvenido al Poké Mart! ¿Qué necesitas?"
	shop.buys_from_player = true

	var entries: Array[ShopEntry] = []
	for item_id in [&"poke_ball", &"super_ball", &"pocion", &"superpocion", &"antidoto"]:
		var e := ShopEntry.new()
		e.item = ItemDatabase.get_item(item_id)
		e.stock = -1
		entries.append(e)
	shop.stock = entries

	ShopManager.register_shop(shop)
	return shop


# ---------------------------------------------------------------- diálogos
func _nurse_dialogue() -> DialogueData:
	var yes := _data(&"nurse_yes", [
		_line("Enfermera Joy", "¡Gracias por esperar! Tus Pokémon están como nuevos."),
	])
	var no := _data(&"nurse_no", [
		_line("Enfermera Joy", "De acuerdo. ¡Ten cuidado ahí fuera!"),
	])
	return _data(&"nurse", [
		_line("Enfermera Joy", "¡Bienvenido al Centro Pokémon! ¿Quieres que cure a tu equipo?", [
			_choice(&"heal_yes", "Sí, por favor", [ActionHealParty.new()], yes),
			_choice(&"heal_no", "No, gracias", [], no),
		]),
	])


func _clerk_dialogue(shop: ShopData) -> DialogueData:
	var open_shop := ActionOpenShop.new()
	open_shop.shop = shop
	return _data(&"clerk", [
		_line("Dependiente", "¡Hola! ¿Quieres echar un vistazo a nuestros productos?", [
			_choice(&"clerk_buy", "Ver productos", [open_shop]),
			_choice(&"clerk_no", "Ahora no", []),
		]),
	])


# ---------------------------------------------------------------- helpers
func _line(speaker: String, text: String, choices: Array = []) -> DialogueLine:
	var l := DialogueLine.new()
	l.speaker = speaker
	l.text = text
	var typed: Array[DialogueChoice] = []
	for c in choices:
		typed.append(c)
	l.choices = typed
	return l


func _choice(id: StringName, text: String, actions: Array = [],
		next: DialogueData = null) -> DialogueChoice:
	var c := DialogueChoice.new()
	c.id = id
	c.text = text
	var typed: Array[GameAction] = []
	for a in actions:
		typed.append(a)
	c.actions = typed
	c.next = next
	return c


func _data(id: StringName, lines: Array) -> DialogueData:
	var d := DialogueData.new()
	d.id = id
	var typed: Array[DialogueLine] = []
	for l in lines:
		typed.append(l)
	d.lines = typed
	return d
