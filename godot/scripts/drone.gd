extends CharacterBody3D

@export var speed := 12.0
@export var vertical_speed := 7.0
@export var acceleration := 20.0
@export var battery_capacity_kwh := 0.45
@export var battery_kwh := 0.45
@export var cruise_draw_kw := 0.32
@export var scan_cost_kwh := 0.002
@export var max_range_m := 450.0
@export var home: Node3D

func _physics_process(delta: float) -> void:
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var desired := Vector3(input.x, 0, input.y) * speed
    if Input.is_action_pressed("drone_up"):
        desired.y += vertical_speed
    if Input.is_action_pressed("drone_down"):
        desired.y -= vertical_speed
    velocity = velocity.move_toward(desired, acceleration * delta)
    move_and_slide()
    battery_kwh = max(0.0, battery_kwh - cruise_draw_kw * delta / 3600.0)
    if Input.is_action_just_pressed("drone_scan") and battery_kwh >= scan_cost_kwh:
        battery_kwh -= scan_cost_kwh
        scan()

func signal_strength() -> float:
    if home == null:
        return 1.0
    return clamp(1.0 - global_position.distance_to(home.global_position) / max_range_m, 0.0, 1.0)

func scan() -> void:
    # Placeholder hook for salvage, energy, structure and Ghost Signal detection.
    print("SCOUT-01 scan pulse | signal ", round(signal_strength() * 100.0), "%")
