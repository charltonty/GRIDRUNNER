extends Node
var game
var activities:=ScoutActivities.new()
var gate: Node3D
var bike_draw:=0.0
var npcs: Array=[]
var tick_time:=0.0
var landing_hold:=0.0
var landing_scored:=false
const POIS={
    "trial":{"pos":Vector3(61,1,-121),"title":"SCOUT LEAGUE / Creek Run","note":"Survey crew timing route. Six paired beacons follow the drainage. Gold 35s / Silver 50s / Bronze finish. Start in FPV; cross beacon 01 in the arrow direction."},
    "breaker":{"pos":Vector3(28,1,-177),"title":"Service breaker / restore gate motor","note":"The gate feed was cut during the evacuation. A short wire bridge will restore its motor."},
    "shortcut":{"pos":Vector3(35,1,-136),"title":"Maintenance gate / inspect drive","note":"Gate motor has no power. Its cable follows the creek to the service breaker."},
    "worksite":{"pos":Vector3(77,1,-151),"title":"Abandoned repair / tool roll","note":"An open splice, a cold thermos. The crew left before finishing."},
    "grave":{"pos":Vector3(92,1,-121),"title":"Stone marker / inspect","note":"A lineman's gloves hang from the crossarm. No name."},
    "radio":{"pos":Vector3(55,1,-109),"title":"Camp radio / tune carrier","note":"Eleven seconds between bursts. The survey receiver in SCOUT-01 can follow the faint carrier along the creek."},
    "lamp":{"pos":Vector3(59,1,-98),"title":"Bench lamp / toggle","note":"A low-voltage task lamp at the repair bench."},
    "cache":{"pos":Vector3(84,1,-194),"title":"Flooded culvert / salvage tin","note":"The high-water mark is above the lid. Whoever hid this expected to return."},
    "landing":{"pos":Vector3(45,3.4,-184),"title":"Survey pad / precision perch","note":"Set SCOUT-01 down gently on the marked service cabinet for two seconds."}}
func _ready() -> void:
    game=get_parent();ScoutActivities.initialize(Session.state);activities.game=game
func dress() -> void:
    activities.cancel();activities.rings.clear();npcs.clear();landing_scored=false
    ScoutActivities.initialize(Session.state)
    if Session.state.leg!=1:return
    load("res://world/authored_opening.gd").build(game,self)
    apply_quality()
    for id in POIS:game.add_target(id,POIS[id].title,POIS[id].pos,"polish")
    if "creek_repeater" in Session.state.polish.signals:game.add_target("repeater_cache","Repeater / recovered field battery",ScoutActivities.SOURCE,"polish")
    for person in get_tree().get_nodes_in_group("field_npcs"):
        if person.get_parent()==game.world or person.global_position.distance_to(Vector3(54,0,-100))<20:
            npcs.append({"node":person,"origin":person.position,"phase":float(npcs.size())*2.7,"yaw":person.rotation.y})
func interact(id: String) -> void:
    var s: Dictionary=Session.state
    if id=="trial":
        if s.mode=="drone":activities.start();return
        game.show_panel("SCOUT LEAGUE / CREEK RUN")
        game.text(POIS.trial.note+"\nBest %.2fs • %s\nLaunch Q near the paired timing poles, then E at this beacon. J restarts the course in flight." % [s.polish.best,s.polish.medal])
        game.button("Pilot record",record_panel);return
    if s.mode=="drone":game.message="Land and approach on foot to handle equipment.";return
    if id=="breaker":
        if s.polish.gates.get("power",false):game.message="Service feed restored.";return
        if s.inv.get("screwdriver",0)<1:game.message="A screwdriver is needed to open the service terminal.";return
        var error:=Session.transact({"wire":1},{})
        if not error.is_empty():game.message="Gate feed damaged / requires 1 wire and your screwdriver.";return
        s.polish.gates.power=true;game.message="Gate drive powered. Follow the cable back to the maintenance gate.";game.slice02.sfx("module");return
    if id=="shortcut":
        if not s.polish.gates.get("power",false):game.message=POIS.shortcut.note;return
        s.polish.gates.shortcut=true
        if is_instance_valid(gate):gate.queue_free()
        game.message="Maintenance shortcut opened / a direct route back to camp.";game.slice02.sfx("container");return
    if id=="lamp":
        s.polish.gates.lamp=not s.polish.gates.get("lamp",false)
        var light=game.world.get_node_or_null("BenchLamp")
        if light:light.visible=s.polish.gates.lamp
        game.message="Bench lamp "+("on" if s.polish.gates.lamp else "off");return
    if id in ["cache","worksite","repeater_cache"]:
        if id in s.polish.discoveries:game.message="Already searched.";return
        var reward: Dictionary={"wire":2,"electronics":1} if id=="worksite" else {"cells":1} if id=="repeater_cache" else {"water":1,"steel":1}
        var error:=Session.transact({},reward)
        if not error.is_empty():game.message=error;return
        s.polish.discoveries.append(id);game.message="Recovered / "+str(reward);game.slice02.sfx("pickup");return
    if POIS.has(id):
        if not id in s.polish.discoveries:s.polish.discoveries.append(id)
        game.show_panel(POIS[id].title.to_upper());game.text(POIS[id].note)
func tick(delta: float) -> void:
    activities.tick(delta);tick_time+=delta
    bike_draw=0.0 if Session.state.mode!="bike" or Session.state.battery<=0 or Input.is_physical_key_pressed(KEY_P) else (0.15+absf(game.speed)*.05+(1.2 if Input.is_physical_key_pressed(KEY_W) else 0)) * 12 * (1+Session.mass(Session.state.cargo)/80)
    # Draw reflects the preserved simulation's accelerated energy time scale.
    for entry in npcs:
        var n: Node3D=entry.node
        if not is_instance_valid(n) or n.global_position.distance_to(game.pilot.position)>55:continue
        var t:=tick_time+float(entry.phase)
        var working: bool=int(entry.phase)%2==0
        n.rotation.z=sin(t*1.2)*.018 if working else 0
        for arm in n.get_children():
            if arm.name.begins_with("Arm"):arm.rotation.x=.6+sin(t*1.5)*.14 if working else sin(t)*.08
        var focus: Vector3=game.drone.position if Session.state.drone_mode!="DOCK" and n.global_position.distance_to(game.drone.position)<7 else game.pilot.position
        if n.global_position.distance_to(focus)<5:
            var aim:=focus;aim.y=n.global_position.y
            if aim.distance_to(n.global_position)>.2:n.look_at(aim)
        elif not working:n.rotation.y=float(entry.yaw)+sin(t*.17)*.5
    if Session.state.mode=="drone" and Session.state.leg==1:
        var pos: Vector3=game.drone.position
        var centered: bool=Vector2(pos.x-45,pos.z+184).length()<.6
        if centered and pos.y>3.2 and pos.y<3.85 and game.drone.velocity.length()<.3 and touching_pad():
            landing_hold+=delta
            if landing_hold>2 and not landing_scored:
                landing_scored=true;Session.state.polish.landings+=1;game.message="PRECISION PERCH / stable contact recorded";game.slice02.sfx("module")
        else:landing_hold=0

func touching_pad() -> bool:
    var pos: Vector3=game.drone.global_position
    var query:=PhysicsRayQueryParameters3D.create(pos,pos-Vector3.UP*.14,1)
    var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.normal.y>.9
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_J and Session.state.mode=="drone" and not game.panel.visible:
        if activities.active or activities.armed or game.drone.position.distance_to(ScoutActivities.COURSE[0])<12:activities.start()
func record_panel() -> void:
    var p: Dictionary=Session.state.polish
    game.show_panel("SCOUT-01 / FIELD LOG")
    game.text("SCOUT LEAGUE • CREEK RUN\nBest %.2fs  /  %s\nGold ≤35s · Silver ≤50s · Bronze completion" % [p.best,p.medal])
    game.text("Flight %.1f min   /   Distance %.0f m\nLongest flight %.0f m\nContacts scanned %d   /   Carriers resolved %d\nPrecision perches %d   /   Returns %d" % [p.flight_time/60,p.distance,p.longest,p.scans,p.signals.size(),p.landings,p.recoveries])
    game.text("Maintenance shortcut: "+("OPEN" if p.gates.get("shortcut",false) else "UNPOWERED"))

func apply_quality() -> void:
    var ecology=game.world.get_node_or_null("OpeningEcology")
    if ecology==null:return
    var low: bool=Session.state.polish.density==0
    for n in ecology.get_children():
        if n is MultiMeshInstance3D and not n.name.begins_with("Canopy"):
            n.multimesh.visible_instance_count=int(n.multimesh.instance_count*.45) if low else -1
            n.visibility_range_end=65 if low else 135 if n.name.begins_with("Scrub") else 95

func toggle_quality() -> void:
    Session.state.polish.density=1-int(Session.state.polish.density);apply_quality();game.menu()
