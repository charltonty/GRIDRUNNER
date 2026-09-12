class_name GridrunnerBike
extends CharacterBody3D

@export var max_speed_mps := 24.0
@export var reverse_speed_mps := 5.0
@export var acceleration_mps2 := 9.0
@export var braking_mps2 := 16.0
@export var steering_rate := 1.6
@export var motor_peak_kw := 11.0
@export var idle_draw_kw := 0.04
@export var battery_capacity_kwh := 6.2
@export var battery_kwh := 5.0
@export var regen_kw := 2.5
var speed_mps := 0.0
var occupied := false

func _physics_process(delta: float) -> void:
    if not occupied:
        return
    var throttle := Input.get_axis("move_back", "move_forward")
    var steer := Input.get_axis("move_right", "move_left")
    if throttle > 0.0 and battery_kwh > 0.0:
        speed_mps = move_toward(speed_mps, max_speed_mps, acceleration_mps2 * throttle * delta)
        consume_energy(motor_peak_kw * throttle, delta)
    elif throttle < 0.0:
        speed_mps = move_toward(speed_mps, -reverse_speed_mps, braking_mps2 * -throttle * delta)
    else:
        speed_mps = move_toward(speed_mps, 0.0, 2.0 * delta)
        consume_energy(idle_draw_kw, delta)
    if abs(speed_mps) > 0.2:
        rotate_y(steer * steering_rate * delta * clamp(abs(speed_mps) / 5.0, 0.25, 1.0))
    velocity = -transform.basis.z * speed_mps
    velocity.y += get_gravity().y * delta
    move_and_slide()

func consume_energy(power_kw: float, delta: float) -> void:
    battery_kwh = max(0.0, battery_kwh - power_kw * delta / 3600.0)

func state_of_charge() -> float:
    return battery_kwh / battery_capacity_kwh
