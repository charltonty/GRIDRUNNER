class_name ScoutActivities
extends RefCounted
const COURSE=[Vector3(62,2.8,-125),Vector3(72,2.6,-140),Vector3(68,2.2,-158),Vector3(53,2.8,-174),Vector3(35,3.5,-187),Vector3(20,2.8,-181)]
const SOURCE=Vector3(78,1.1,-170)
var game
var active:=false
var armed:=false
var checkpoint:=0
var elapsed:=0.0
var reception:=0.0
var last_pos:=Vector3.ZERO
var flight_length:=0.0
var was_flying:=false
var rings: Array=[]
var result:=""
var signal_time:=0.0

static func initialize(s: Dictionary) -> void:
    if not s.has("polish"):s.polish={}
    var defaults:={"best":0.0,"medal":"—","flight_time":0.0,"distance":0.0,"longest":0.0,"scans":0,"signals":[],"gates":{},"discoveries":[],"landings":0,"crashes":0,"recoveries":0,"density":1}
    for key in defaults:
        if not s.polish.has(key):s.polish[key]=defaults[key]
static func validate(d) -> bool:
    if not d is Dictionary:return false
    if d.has("density"):
        if not (d.density is int or d.density is float):return false
        if not is_finite(float(d.density)) or float(d.density)!=floor(float(d.density)) or int(d.density) not in [0,1]:return false
    for key in ["best","flight_time","distance","longest","scans","landings","crashes","recoveries"]:
        if d.has(key) and (not (d[key] is float or d[key] is int) or not is_finite(float(d[key])) or float(d[key])<0):return false
    for key in ["signals","discoveries"]:
        if d.has(key):
            if not d[key] is Array or d[key].size()>200:return false
            for v in d[key]:
                if not v is String:return false
    if d.has("gates"):
        if not d.gates is Dictionary:return false
        for v in d.gates.values():
            if not v is bool:return false
    if d.has("medal") and d.medal not in ["—","BRONZE","SILVER","GOLD"]:return false
    return true
func start() -> void:
    active=false;armed=true;checkpoint=0;elapsed=0;result="";last_pos=game.drone.position
    game.message="CREEK RUN armed. Fly through beacon 01 to start. J restarts; Q leaves flight."
    colors()
func cancel() -> void:
    if active or armed:result="TRIAL ABORTED";game.message="Creek Run aborted. No record changed."
    active=false;armed=false;colors()
func medal(time: float) -> String:
    return "GOLD" if time<=35 else "SILVER" if time<=50 else "BRONZE"
func finish() -> void:
    active=false;armed=false
    var p: Dictionary=Session.state.polish
    if p.best==0 or elapsed<p.best:p.best=elapsed;p.medal=medal(elapsed)
    result="%s  /  %.2fs" % [medal(elapsed),elapsed]
    game.message="CREEK RUN / "+result+"  •  BEST %.2fs" % p.best
    game.slice02.sfx("module");game.save_now();game.message="CREEK RUN / "+result+"  •  BEST %.2fs" % p.best
    colors()
func colors() -> void:
    for i in range(rings.size()):
        if is_instance_valid(rings[i]):rings[i].material_override=FieldKit.mat("amber" if i==checkpoint and (active or armed) else "steel")
func crosses(a: Vector3,b: Vector3,index: int) -> bool:
    var center: Vector3=COURSE[index]
    var direction: Vector3=(COURSE[1]-COURSE[0]).normalized() if index==0 else (COURSE[index]-COURSE[index-1]).normalized()
    direction.y=0;direction=direction.normalized()
    var da: float=(a-center).dot(direction);var db: float=(b-center).dot(direction)
    if da>=0 or db<0 or is_equal_approx(da,db):return false
    var point: Vector3=a.lerp(b,-da/(db-da))
    return point.distance_to(center)<=1.65
func tick(delta: float) -> void:
    var s: Dictionary=Session.state
    var flying: bool=s.drone_mode!="DOCK"
    var pos: Vector3=game.drone.position
    if flying:
        s.polish.flight_time+=delta
        if was_flying:
            var distance:=pos.distance_to(last_pos)
            if distance<30:s.polish.distance+=distance;flight_length+=distance
        s.polish.longest=maxf(s.polish.longest,flight_length)
    elif was_flying:
        s.polish.recoveries+=1;flight_length=0
    if s.mode!="drone" or s.drone_mode!="MANUAL":
        if active or armed:cancel()
    elif armed or active:
        if active:elapsed+=delta
        if crosses(last_pos,pos,checkpoint):
            if armed:armed=false;active=true;elapsed=0
            checkpoint+=1
            game.slice02.sfx("module")
            if checkpoint>=COURSE.size():finish()
            else:colors()
    if s.mode=="drone" and s.leg==1:
        var direction: Vector3=-Basis(Vector3.UP,game.yaw).z
        reception=signal_strength(pos,direction)
        signal_time+=delta
        if reception>.78 and signal_time>3:game.audio_rig.signal_ping(reception);signal_time=0
    else:reception=0
    last_pos=pos;was_flying=flying
func signal_strength(pos: Vector3,direction: Vector3) -> float:
    var distance:=pos.distance_to(SOURCE)
    var facing:=.65+.35*maxf(0,direction.normalized().dot((SOURCE-pos).normalized()))
    var altitude:=1.0-.35*clampf((pos.y-8)/40,0,1)
    var interference:=.86+.14*sin(pos.x*.23+pos.z*.13)
    return clampf((1-distance/100)*facing*altitude*interference,0,1)
func record_scan(count: int) -> void:
    if Session.state.mode!="drone":return
    Session.state.polish.scans+=count
    if game.drone.position.distance_to(SOURCE)<5 and reception>.65 and not "creek_repeater" in Session.state.polish.signals:
        Session.state.polish.signals.append("creek_repeater")
        game.add_target("repeater_cache","Repeater / recovered field battery",SOURCE,"polish")
        game.message="Carrier resolved. Old survey repeater; a field battery is stashed beneath it."
func readout() -> String:
    if armed:return "CREEK RUN / ARMED • GATE 01"
    if active:return "CREEK RUN / %d OF 6 • %.2fs" % [checkpoint+1,elapsed]
    return "SCOUT LEAGUE / "+result if not result.is_empty() else "SURVEY RECEIVER / SEARCHING"
