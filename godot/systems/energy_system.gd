class_name EnergySystem
extends Node

signal energy_changed(stored_kwh: float, capacity_kwh: float)

@export var capacity_kwh := 12.0
@export var stored_kwh := 8.0

func charge(power_kw: float, delta_seconds: float, efficiency := 1.0) -> float:
    var requested := max(power_kw, 0.0) * delta_seconds / 3600.0 * clamp(efficiency, 0.0, 1.0)
    var accepted := min(requested, capacity_kwh - stored_kwh)
    stored_kwh += accepted
    energy_changed.emit(stored_kwh, capacity_kwh)
    return accepted

func consume(power_kw: float, delta_seconds: float) -> float:
    var requested := max(power_kw, 0.0) * delta_seconds / 3600.0
    var supplied := min(requested, stored_kwh)
    stored_kwh -= supplied
    energy_changed.emit(stored_kwh, capacity_kwh)
    return supplied

func state_of_charge() -> float:
    if capacity_kwh <= 0.0:
        return 0.0
    return stored_kwh / capacity_kwh
