class_name FuelGenerator
extends Node

signal fuel_changed(liters: float)
signal generator_state_changed(running: bool)

# Fuel is intentionally rare. The payoff is enormous electrical energy.
@export var rated_output_kw := 8.0
@export var fuel_liters := 1.5
@export var fuel_energy_kwh_per_liter := 9.5
@export_range(0.0, 1.0) var electrical_efficiency := 0.32
var running := false

func usable_kwh_per_liter() -> float:
    return fuel_energy_kwh_per_liter * electrical_efficiency

func start() -> bool:
    running = fuel_liters > 0.0
    generator_state_changed.emit(running)
    return running

func stop() -> void:
    running = false
    generator_state_changed.emit(false)

func generate(delta: float, battery: EnergySystem) -> float:
    if not running or fuel_liters <= 0.0:
        stop()
        return 0.0
    var possible_kwh := rated_output_kw * delta / 3600.0
    var fuel_needed := possible_kwh / usable_kwh_per_liter()
    var actual_fuel := min(fuel_needed, fuel_liters)
    var available_kwh := actual_fuel * usable_kwh_per_liter()
    var accepted_kwh := battery.charge(available_kwh * 3600.0 / max(delta, 0.001), delta)
    fuel_liters -= accepted_kwh / usable_kwh_per_liter()
    fuel_changed.emit(fuel_liters)
    if fuel_liters <= 0.0001:
        fuel_liters = 0.0
        stop()
    return accepted_kwh
