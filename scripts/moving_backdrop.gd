class_name MovingBackdrop extends SubViewportContainer

@export var buildings: Array[Building]
@export var bk_buildings: Array[Building]
@export var cars: Array[Car]
@export_group("Nodes")
@export var subvp: SubViewport
@export var killer_car_horn: FadeSFXPlayer
@export var moving_nodes: Array[Control]
@export var drifting_nodes: Dictionary[TextureRect, float]
@export var sunny_nodes: Array[Control]
@export var rainy_nodes: Array[Control]
@export var snowy_nodes: Array[Control]
@export_group("")
var active_buildings: Array[TextureRect]
var bk_building: TextureRect
var killer_car: TextureRect
var direction := -1
var bk_mode := false
var weather: BKSim_Game.Weather
const WIDTH := 640
const CAR_SPEED := 480.0
const ROAD_Y := 308.0

func random_building(bk: bool) -> Building:
	var arr: Array[Building] = (bk_buildings if bk else buildings)
	var total_weight: int = 0
	for b in arr:
		total_weight += b.weight
	var picked: int = randi_range(0, total_weight-1)
	for b in arr:
		if picked < b.weight:
			return b
		picked -= b.weight
	push_error("Didn't find the picked building?")
	return arr[0]

func random_car() -> Car:
	var arr: Array[Car] = cars
	var total_weight: int = 0
	for c in arr:
		total_weight += c.weight
	var picked: int = randi_range(0, total_weight-1)
	for c in arr:
		if picked < c.weight:
			return c
		picked -= c.weight
	push_error("Didn't find the picked car?")
	return arr[0]

func add_exit_notifier(rect: TextureRect) -> void:
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(Vector2.ZERO, rect.texture.get_size())
	notifier.screen_entered.connect(func(): notifier.screen_exited.connect(remove_object.bind(rect)))
	rect.add_child(notifier)
func add_car(killer: bool) -> void:
	assert(killer) # no cars other than killers (yet)
	var car := random_car().instantiate()
	car.reset_size()
	add_exit_notifier(car)
	subvp.add_child(car)
	car.position.y = ROAD_Y - car.size.y
	if direction > 0:
		car.position.x = -car.size.x
		car.flip_h = true
	else:
		car.position.x = WIDTH
	if killer:
		killer_car = car
func add_building() -> void:
	var building := random_building(bk_mode).instantiate(weather == BKSim_Game.Weather.SNOW)
	if bk_mode:
		bk_building = building
	bk_mode = false
	building.reset_size()
	add_exit_notifier(building)
	subvp.add_child(building)
	if direction > 0:
		if active_buildings.is_empty():
			building.position.x = -building.size.x
		else:
			var most_recent := active_buildings[-1]
			building.position.x = most_recent.position.x - building.size.x
	else:
		if active_buildings.is_empty():
			building.position.x = WIDTH
		else:
			var most_recent := active_buildings[-1]
			building.position.x = most_recent.position.x + most_recent.size.x
	active_buildings.append(building)

func remove_object(object: TextureRect) -> void:
	if object == bk_building:
		bk_building = null
	if object == killer_car:
		killer_car = null
	active_buildings.erase(object)
	object.queue_free()

func move_by(amount: float) -> void:
	# minimum 0.5 magnitude, otherwise it visually jitters
	var min_magnitude: float = 1.0 if weather == BKSim_Game.Weather.SUN else 0.5
	amount = max(min_magnitude, abs(amount) / 2) * direction
	for node in moving_nodes:
		node.position.x += amount
		if node.position.x > 0:
			node.position.x -= WIDTH
		elif node.position.x < -WIDTH:
			node.position.x += WIDTH
	if killer_car:
		killer_car.position.x += amount
	if active_buildings.is_empty(): return
	for b in active_buildings:
		b.position.x += amount
	var most_recent := active_buildings[-1]
	if direction > 0:
		while most_recent.position.x > 0:
			add_building()
			most_recent = active_buildings[-1]
	else:
		while most_recent.position.x + most_recent.size.x < WIDTH:
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
		while b.position.x + b.size.x < WIDTH:
			move_by(5)
	else:
		while b.position.x > 0:
			move_by(-5)

func swap_direction() -> void:
	active_buildings.reverse()
	direction = -direction

func _process(delta: float) -> void:
	if killer_car:
		killer_car.position.x += direction * CAR_SPEED * delta
		var cx := killer_car.get_rect().get_center().x
		var diff := cx - (WIDTH / 2.0)
		var diff_scl := clampf(diff / (WIDTH / 2.0), -1.0, 1.0)
		var car_side := int(signf(diff))
		if not car_side: car_side = 1
		killer_car_horn.volume_linear = Tween.interpolate_value(0.05, 0.0, absf(diff_scl), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		if not killer_car_horn.playing:
			killer_car_horn.playing = true
		if direction != car_side: # towards you
			killer_car_horn.pitch_scale = Tween.interpolate_value(2.0, -1.0, 1.0 - absf(diff_scl), 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		else: # away from you
			killer_car_horn.pitch_scale = Tween.interpolate_value(1.0, -0.5, absf(diff_scl), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	else: killer_car_horn.fade_end()
	for node in drifting_nodes:
		var speed := drifting_nodes[node]
		node.position.x += delta * speed
		if node.position.x > 0:
			node.position.x -= WIDTH
		elif node.position.x < -WIDTH:
			node.position.x += WIDTH
