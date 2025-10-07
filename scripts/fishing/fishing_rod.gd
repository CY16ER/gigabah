extends Node3D

@onready var bobber: CharacterBody3D = %Bobber
@onready var fishing_line_starter_marker: Marker3D = %FishingLineStarterMarker
@onready var bobber_start_marker: Marker3D = %BobberStartMarker
@onready var fishing_line: MeshInstance3D = %FishingLine

func _ready() -> void:
	bobber.set_physics_process(false)
	fishing_line.hide()
	
func _physics_process(_delta: float) -> void:
	_refresh_line()
	
func _refresh_line() -> void:
	var centerPosition: Vector3 = (fishing_line_starter_marker.global_position + bobber.global_position) / 2
	var distance: float = fishing_line_starter_marker.global_position.distance_to(bobber.global_position)

	fishing_line.global_position = centerPosition
	fishing_line.mesh.height = distance

	var direction: Vector3 = fishing_line_starter_marker.global_position - fishing_line.global_position
	var up_vector: Vector3 = Vector3.UP
	if direction.normalized().cross(Vector3.UP).length() < 0.001:
		up_vector = Vector3.RIGHT

	fishing_line.look_at(fishing_line_starter_marker.global_position, up_vector)
	fishing_line.rotation_degrees.x -= 90

func start_fishing() -> void:
	fishing_line.show()
	_cast_rod()

func _cast_rod() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", -30, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees:x", 45, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation_degrees:x", 0, 0.1)
	await tween.finished
	_throw_bobber()

func _throw_bobber() -> void:
	var camera: Camera3D = get_node("/root/Index3d/Camera3D")
	var from: Vector3 = camera.project_ray_origin(get_viewport().get_mouse_position())
	var dir: Vector3 = camera.project_ray_normal(get_viewport().get_mouse_position())
	var plane: Plane = Plane(Vector3.UP, 0)
	var target_pos: Variant = plane.intersects_ray(from, dir)

	if target_pos:
		var direction: Vector3 = (target_pos - bobber.global_position).normalized()
		var speed: float = 10.0
		bobber.velocity = direction * speed
		bobber.velocity.y += 5  # Add upward component for arc
	else:
		# Fallback to old behavior
		bobber.velocity = global_basis * Vector3(1,1,0) * 5
		bobber.velocity.y = 6

	bobber.set_physics_process(true)
	# Reparent bobber to scene root so it doesn't follow player rotation
	bobber.reparent(get_tree().current_scene)

func stop_fishing() -> void:
	bobber.set_physics_process(false)
	# Reparent bobber back to fishing_rod
	bobber.reparent(self)

	var tween: Tween = create_tween()
	tween.tween_property(bobber, "global_position", bobber_start_marker.global_position, 0.5)
	await tween.finished
	fishing_line.hide()
