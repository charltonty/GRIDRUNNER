extends Node

const SAVE_PATH = "user://gridrunner_native.json"
var content: Dictionary = {}
var state: Dictionary = {}
var load_requested := false
var volume := 0.6

func _ready() -> void:
    content = JSON.parse_string(FileAccess.get_file_as_string("res://data/port/content.json"))
    reset()

func reset() -> void:
    state = {"version":1,"leg":1,"position":[0,1.5,15],"bike":[0,1.0,15],"drone_position":[0,2,15],"mode":"bike","yaw":0.0,"pitch":0.0,"battery":0.54,"reserve":0.496,"fuel":0.15,"drone":1.0,"hp":100.0,"drone_hp":100.0,"drone_mode":"DOCK","generator":"off","inv":{"steel":0,"wire":0,"cells":0,"electronics":0,"screwdriver":1,"wrench":1},"cargo":{},"flags":{},"met":{},"trades":{},"tags":[],"pov":{"walking":0,"bike":0,"drone":0},"field":content.field.world.duplicate(true),"elapsed":0.0}

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
    if mass(next) > capacity: return "Pack full; transfer cargo to the trailer"
    state.inv = next
    return ""

func save_game() -> bool:
    var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(state))
    file.close()
    return DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) == OK

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH): return false
    var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
    if not validate(data): return false
    state = data
    # Deployed aircraft return safely on loading; a remote pilot never teleports.
    state.mode = "bike" if state.mode == "drone" else state.mode
    state.drone_mode = "DOCK"
    return true

func validate(data) -> bool:
    if not data is Dictionary or data.get("version") != 1: return false
    for key in state:
        if not data.has(key): return false
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
