extends Node

signal display_changed

const SAVE_PATH = "user://gridrunner_native.json"
const DESIGN_SIZE:=Vector2i(1280,720)
const DEFAULT_WINDOW_FRACTION:=0.9
var save_path := SAVE_PATH
var content: Dictionary = {}
var state: Dictionary = {}
var load_requested := false
var volume := 0.6
var windowed_step:=1

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    content = JSON.parse_string(FileAccess.get_file_as_string("res://data/port/content.json"))
    reset()
    apply_window_fraction.call_deferred(DEFAULT_WINDOW_FRACTION)

func fit_window_size(usable_size: Vector2i,fraction: float) -> Vector2i:
    if usable_size.x<=0 or usable_size.y<=0:return DESIGN_SIZE
    var available:=Vector2(usable_size)*clampf(fraction,.5,1.0)
    var target:=Vector2(available.x,available.x*float(DESIGN_SIZE.y)/DESIGN_SIZE.x)
    if target.y>available.y:target=Vector2(available.y*float(DESIGN_SIZE.x)/DESIGN_SIZE.y,available.y)
    return Vector2i(maxi(1,roundi(target.x)),maxi(1,roundi(target.y)))

func apply_window_fraction(fraction: float) -> void:
    if DisplayServer.get_name()=="headless":return
    var usable:=DisplayServer.screen_get_usable_rect()
    if usable.size.x<=0 or usable.size.y<=0:return
    var target:=fit_window_size(usable.size,fraction)
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(target)
    DisplayServer.window_set_position(usable.position+Vector2i(roundi((usable.size.x-target.x)*.5),roundi((usable.size.y-target.y)*.5)))
    windowed_step=0 if fraction<.85 else 1
    display_changed.emit()

func is_fullscreen() -> bool:
    var mode:=DisplayServer.window_get_mode()
    return mode==DisplayServer.WINDOW_MODE_FULLSCREEN or mode==DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func toggle_fullscreen() -> void:
    if DisplayServer.get_name()=="headless":return
    if is_fullscreen():apply_window_fraction(.8 if windowed_step==0 else .9)
    else:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN);display_changed.emit()

func cycle_display_mode() -> void:
    if is_fullscreen():apply_window_fraction(.8)
    elif windowed_step==0:apply_window_fraction(.9)
    else:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN);display_changed.emit()

func display_description() -> String:
    if is_fullscreen():return "FULLSCREEN / 100%"
    return "%d%% WINDOW" % (80 if windowed_step==0 else 90)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F11:
        toggle_fullscreen();get_viewport().set_input_as_handled()

func reset() -> void:
    state = {"version":1,"leg":1,"position":[54,1.0,-88],"bike":[48,1.0,-83],"drone_position":[48,2,-83],"mode":"foot","yaw":0.0,"pitch":0.0,"battery":0.54,"reserve":0.496,"fuel":0.15,"drone":1.0,"hp":100.0,"drone_hp":100.0,"drone_mode":"DOCK","generator":"off","inv":{"steel":0,"wire":0,"cells":0,"electronics":0,"screwdriver":1,"wrench":1},"cargo":{},"flags":{},"met":{},"trades":{},"tags":[],"pov":{"walking":0,"bike":0,"drone":0},"field":content.field.world.duplicate(true),"elapsed":0.0}

    FieldStorage.initialize(state)
    ScoutActivities.initialize(state)

func mass(inv: Dictionary) -> float:
    var total := 0.0
    for id in inv:
        total += float(content.items[id].mass) * float(inv[id])
    return total

func transact(inputs: Dictionary, outputs: Dictionary, capacity := 40.0) -> String:
    var next: Dictionary = state.inv.duplicate()
    for id in inputs:
        if int(next.get(id,0)) < int(inputs[id]): return "Missing " + str(id)
        next[id] = int(next.get(id,0)) - int(inputs[id])
    for id in outputs:
        if not content.items.has(id): return "Unknown item"
        next[id] = int(next.get(id,0)) + int(outputs[id])
        if next[id]>int(content.items[id].get("stack",999)): return "Stack limit reached"
    if mass(next) > capacity: return "Pack full; transfer cargo to the trailer"
    state.inv = next
    return ""

func save_game() -> bool:
    var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(state))
    file.close()
    return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK

func load_game() -> bool:
    if not FileAccess.file_exists(save_path): return false
    var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not validate(data): return false
    state = data
    FieldStorage.initialize(state)
    ScoutActivities.initialize(state)
    # Deployed aircraft return safely on loading; a remote pilot never teleports.
    state.mode = "bike" if state.mode == "drone" else state.mode
    state.drone_mode = "DOCK"
    return true

func validate(data) -> bool:
    if not data is Dictionary or data.get("version") != 1: return false
    for key in state:
        if key in ["bike_heading","slice02","polish"]: continue # Optional in older native saves.
        if not data.has(key): return false
    if data.has("polish") and not ScoutActivities.validate(data.polish):return false
    if data.has("slice02") and not FieldStorage.validate(data.slice02,content.items): return false
    if data.has("bike_heading") and (not (data.bike_heading is float or data.bike_heading is int) or not is_finite(float(data.bike_heading))): return false
    if int(data.leg) not in [1,2,3] or data.mode not in ["bike","foot","drone"]: return false
    for key in ["position","bike","drone_position"]:
        if not data[key] is Array or data[key].size()!=3: return false
        for v in data[key]:
            if not (v is float or v is int) or not is_finite(float(v)) or abs(float(v))>10000: return false
    for key in ["battery","reserve","fuel","drone","hp","drone_hp","elapsed","yaw","pitch"]:
        if not (data[key] is float or data[key] is int) or not is_finite(float(data[key])): return false
    if data.battery<0 or data.battery>2 or data.reserve<0 or data.reserve>0.8 or data.fuel<0 or data.fuel>20 or data.drone<0 or data.drone>1 or data.hp<0 or data.hp>100: return false
    if data.generator not in ["off","solar","fuel"]: return false
    for key in ["inv","cargo"]:
        if not data[key] is Dictionary: return false
        for id in data[key]:
            if not content.items.has(id) or not (data[key][id] is float or data[key][id] is int) or float(data[key][id])<0 or float(data[key][id])>99999 or float(data[key][id])!=floor(float(data[key][id])): return false
    if not data.field is Array or data.field.size()!=144: return false
    for i in range(144):
        var p = data.field[i]
        if not p is Dictionary or p.get("id")!=content.field.world[i].id or not p.get("items") is Dictionary: return false
        if not p.has("left") or float(p.left)<0 or float(p.left)>4: return false
        for id in p.items:
            if not content.items.has(id) or float(p.items[id])<0 or float(p.items[id])>999: return false
    if not data.flags is Dictionary or not data.met is Dictionary or not data.trades is Dictionary or not data.pov is Dictionary or not data.tags is Array: return false
    for key in ["walking","bike","drone"]:
        if not data.pov.has(key) or int(data.pov[key])<0 or int(data.pov[key])>=content.profiles[key].size(): return false
    return true
