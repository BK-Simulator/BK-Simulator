class_name MovingBackdrop extends SubViewportContainer

@export var buildings: Array[Building]
@export var bk_buildings: Array[Building]
@export_group("Nodes")
@export var subvp: SubViewport
@export var moving_nodes: Array[Control]
@export var drifting_nodes: Dictionary[TextureRect, float]
@export var sunny_nodes: Array[Control]
@export var rainy_nodes: Array[Control]
@export var snowy_nodes: Array[Control]
@export_group("")
var active_buildings: Array[TextureRect]
var bk_building: TextureRect
var direction := -1
var bk_mode := false

func add_building() -> void:
	var blueprint: Building = (bk_buildings if bk_mode else buildings).pick_random() as Building
	var building := blueprint.instantiate()
	if bk_mode:
		bk_building = building
	bk_mode = false
	building.reset_size()
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(Vector2.ZERO, building.texture.get_size())
	notifier.screen_entered.connect(func(): notifier.screen_exited.connect(remove_building.bind(building)))
	building.add_child(notifier)
	subvp.add_child(building)
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
	if building == bk_building:
		bk_building = null
	active_buildings.erase(building)
	building.queue_free()

func move_by(amount: float) -> void:
	amount = abs(amount) * direction
	for node in moving_nodes:
		node.position.x += amount
		if node.position.x > 0:
			node.position.x -= 640
		elif node.position.x < -640:
			node.position.x += 640
	if active_buildings.is_empty(): return
	for b in active_buildings:
		b.position.x += amount
	var most_recent := active_buildings[-1]
	if direction > 0:
		while most_recent.position.x > 0:
			add_building()
			most_recent = active_buildings[-1]
	else:
		while most_recent.position.x + most_recent.size.x < 640:
			add_building()
			most_recent = active_buildings[-1]

func remove_all_buildings() -> void:
	for b in active_buildings:
		b.queue_free()
	bk_building = null
	active_buildings.clear()

func populate_buildings() -> void:
	remove_all_buildings()
	add_building()
	var b := active_buildings[0]
	if direction > 0:
		while b.position.x + b.size.x < 640:
			move_by(5)
	else:
		while b.position.x > 0:
			move_by(-5)

func swap_direction() -> void:
	active_buildings.reverse()
	direction = -direction

func _process(delta: float) -> void:
	for node in drifting_nodes:
		var speed := drifting_nodes[node]
		node.position.x += delta * speed
		if node.position.x > 0:
			node.position.x -= 640
		elif node.position.x < -640:
			node.position.x += 640
