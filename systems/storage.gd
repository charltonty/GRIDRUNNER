class_name FieldStorage
extends RefCounted

const LIMITS={"backpack":40.0,"bike":18.0,"drone":2.0,"trailer":60.0,"workbench":80.0,"battery":60.0,"generator":20.0,"world":30.0}
const MODULES={"scanner":{"mass":0.2,"draw":0.05,"slots":1},"spotlight":{"mass":0.35,"draw":0.12,"slots":1},"marker":{"mass":0.3,"draw":0.03,"slots":1},"cargo":{"mass":0.4,"draw":0.02,"slots":1},"utility":{"mass":0.5,"draw":0.08,"slots":1}}
static func initialize(s: Dictionary) -> void:
    if not s.has("slice02"):
        s.slice02={"stores":{},"modules":["scanner","marker"],"payload":3,"cooldown":0.0,"picked":[],"reduced_motion":false,"opening":{},"equipped":{"hand":"wrench"}}
    for id in LIMITS:
        if id not in ["backpack","trailer"] and not s.slice02.stores.has(id): s.slice02.stores[id]={}
static func contents(s: Dictionary,id: String) -> Dictionary:
    initialize(s)
    if id=="backpack": return s.inv
    if id=="trailer": return s.cargo
    return s.slice02.stores.get(id,{})
static func mass(inv: Dictionary,items: Dictionary) -> float:
    var total:=0.0
    for id in inv: total+=float(items[id].mass)*int(inv[id])
    return total
static func accepts(store: String,id: String,items: Dictionary) -> bool:
    if store=="battery": return items[id].get("family","")=="battery"
    if store=="generator": return items[id].has("liters")
    return true
static func transfer(s: Dictionary,items: Dictionary,from: String,to: String,id: String,count: int=1) -> String:
    if from==to or not LIMITS.has(from) or not LIMITS.has(to) or count<=0 or not items.has(id): return "Invalid transfer"
    if to=="drone" and not "cargo" in s.slice02.modules: return "Install cargo module first"
    var source:=contents(s,from);var dest:=contents(s,to)
    if int(source.get(id,0))<count: return "Item no longer available"
    if not accepts(to,id,items): return "This rack cannot hold that item"
    if mass(dest,items)+float(items[id].mass)*count>float(LIMITS[to])+0.00001: return "Destination capacity exceeded"
    if int(dest.get(id,0))+count>int(items[id].get("stack",999)): return "Stack limit reached"
    source[id]-=count
    if source[id]==0: source.erase(id)
    dest[id]=int(dest.get(id,0))+count
    return ""
static func equip(s: Dictionary,id: String) -> String:
    if not MODULES.has(id): return "Unknown module"
    if s.drone_mode!="DOCK": return "Dock SCOUT-01 before changing modules"
    var modules: Array=s.slice02.modules
    if id in modules:
        if id=="cargo" and not contents(s,"drone").is_empty(): return "Unload cargo before removing its tray"
        modules.erase(id);return ""
    if modules.size()>=2: return "Two equipment slots. Remove a module first."
    modules.append(id)
    return ""
static func draw_kw(s: Dictionary,items: Dictionary) -> float:
    var draw:=0.32
    var weight:=mass(contents(s,"drone"),items)
    for id in s.slice02.modules:
        draw+=float(MODULES[id].draw);weight+=float(MODULES[id].mass)
    return draw+weight*0.16
static func validate(data,items: Dictionary) -> bool:
    if not data is Dictionary:return false
    for key in ["stores","modules","payload","cooldown","picked","reduced_motion","opening","equipped"]:
        if not data.has(key):return false
    if not data.stores is Dictionary or not data.modules is Array or data.modules.size()>2:return false
    var seen:=[]
    for id in data.modules:
        if not MODULES.has(id) or id in seen:return false
        seen.append(id)
    if not data.payload is float and not data.payload is int:return false
    if data.payload<0 or data.payload>3 or float(data.payload)!=floor(float(data.payload)):return false
    if not (data.cooldown is float or data.cooldown is int) or not is_finite(float(data.cooldown)) or data.cooldown<0:return false
    if not data.picked is Array or not data.opening is Dictionary or not data.equipped is Dictionary or not data.reduced_motion is bool:return false
    for id in data.picked:
        if not id is String:return false
    for key in data.stores:
        if not LIMITS.has(key) or not data.stores[key] is Dictionary:return false
        for id in data.stores[key]:
            var n=data.stores[key][id]
            if not items.has(id) or not (n is float or n is int):return false
            if not is_finite(float(n)) or n<0 or n>items[id].get("stack",999) or n!=floor(n):return false
        if mass(data.stores[key],items)>float(LIMITS[key])+0.001:return false
    return true
