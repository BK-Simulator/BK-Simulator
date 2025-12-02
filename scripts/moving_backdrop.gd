class_name MovingBackdrop extends SubViewport

@export var buildings: Array[Texture2D]
var active_buildings: Array[TextureRect]
var direction := 1

static func create_building(tex: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size.y = 640
	return rect

func add_building() -> void:
	var building := create_building(buildings.pick_random())
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.screen_entered.connect(func(): notifier.screen_exited.connect(remove_building.bind(building)))
	building.add_child(notifier)
	add_child(building)
	if direction > 0:
		if active_buildings.is_empty():
			building.position.x = -building.size.x
		else:
			var most_recent := active_buildings[-1]
			building.position.x = most_recent.position.x - building.size.x
	else:
		if active_buildings.is_empty():
			building.position.x = 640
		else:
			var most_recent := active_buildings[-1]
			building.position.x = most_recent.position.x + most_recent.size.x
	active_buildings.append(building)

func remove_building(building: TextureRect) -> void:
	active_buildings.erase(building)
	building.queue_free()

func move_by(amount: float) -> void:
	if active_buildings.is_empty(): return
	for b in active_buildings:
		b.position.x += amount
	var most_recent := active_buildings[-1]
	if direction > 0:
		if most_recent.position.x > 0:
			add_building()
	else:
		if most_recent.position.x + most_recent.size.x < 640:
			add_building()

func remove_all_buildings() -> void:
	for b in active_buildings:
		b.queue_free()
	active_buildings.clear()

func populate_buildings() -> void:
	remove_all_buildings()
	add_building()
	var b := active_buildings[0]
	while b.position.x + b.size.x < 640:
		move_by(5)

func swap_direction() -> void:
	active_buildings.reverse()
	direction = -direction
