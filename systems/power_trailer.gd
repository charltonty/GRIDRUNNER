class_name PowerTrailer
extends Node3D

signal source_changed(source: String)

@export var battery_capacity_kwh := 24.0
@export var battery_kwh := 10.0
@export var solar_peak_kw := 2.4
@export var water_peak_kw := 3.5
@export var grid_input_peak_kw := 12.0
@export var fuel_liters := 0.0
@export var generator_output_kw := 8.0
@export var generator_kwh_per_liter := 3.0
var active_source := "OFF"

func set_source(source: String) -> void:
    active_source = source
    source_changed.emit(active_source)

func _process(delta: float) -> void:
    var input_kw: float = 0.0
    match active_source:
        "SOLAR": input_kw = solar_peak_kw
        "WATER": input_kw = water_peak_kw
        "GRID": input_kw = grid_input_peak_kw
        "FUEL":
            if fuel_liters > 0.0:
                input_kw = generator_output_kw
                var generated: float = input_kw * delta / 3600.0
                var burn: float = generated / generator_kwh_per_liter
                fuel_liters = maxf(0.0, fuel_liters - burn)
            else:
                active_source = "OFF"
    battery_kwh = minf(battery_capacity_kwh, battery_kwh + input_kw * delta / 3600.0)

func transfer_to(target: EnergySystem, power_kw: float, delta: float) -> float:
    var available: float = minf(power_kw * delta / 3600.0, battery_kwh)
    var accepted: float = target.charge(available * 3600.0 / maxf(delta, 0.001), delta)
    battery_kwh -= accepted
    return accepted
