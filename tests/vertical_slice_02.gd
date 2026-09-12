extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
    checks+=1
    if ok:print("PASS: ",label)
    else:failures+=1;push_error(label)
func key(code: int,down: bool) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event)
func frames(n: int) -> void:
    for i in range(n):await physics_frame
func run() -> void:
    await process_frame
    var s=root.get_node("Session");s.reset();s.save_path="user://vs02_test.json"
    var g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
    await frames(20)
    check(s.content.items.size()>=100,"At least 100 item definitions")
    g.pilot.position=Vector3(0,1,-50);g.pilot.velocity=Vector3.ZERO
    await frames(25)
    var floor_y: float=g.pilot.position.y
    key(KEY_SPACE,true);await frames(12)
    check(g.pilot.position.y>floor_y+.4,"Jump physically clears floor")
    await frames(70)
    check(absf(g.pilot.position.y-floor_y)<.1 and g.pilot.is_on_floor(),"Held jump lands without automatic bounce")
    check(g.traversal.landings>0,"Landing event follows airborne movement")
    key(KEY_SPACE,false);key(KEY_CTRL,true);await frames(3)
    var crouch_y: float=g.pilot.position.y
    check(crouch_y<floor_y-.2,"Crouch physically lowers capsule")
    var ceiling=g.box(g.world,Vector3(0,1.55,-50),Vector3(3,.2,3),Color.GRAY,true)
    await frames(3);key(KEY_CTRL,false);await frames(5)
    check(g.traversal.crouched,"Ceiling prevents standing through collision")
    ceiling.queue_free();await frames(5)
    check(not g.traversal.crouched and absf(g.pilot.position.y-floor_y)<.1,"Stand resumes when clearance returns")
    var wall=g.box(g.world,Vector3(0,1,-53),Vector3(4,2,.3),Color.GRAY,true)
    key(KEY_W,true);await frames(90);key(KEY_W,false)
    check(g.pilot.position.z > -52.6,"Player cannot walk through solid wall")
    wall.queue_free();await frames(3)
    g.pilot.position=Vector3(0,1,-50);g.pilot.velocity=Vector3.ZERO
    var step=g.box(g.world,Vector3(0,.12,-52),Vector3(4,.24,1),Color.GRAY,true)
    await frames(20);key(KEY_W,true);await frames(55);key(KEY_W,false)
    check(g.pilot.position.z < -52.8,"Small step crossed by actual movement")
    step.queue_free();await frames(3)
    var ramp=g.box(g.world,Vector3(0,.65,-55),Vector3(4,.2,6),Color.GRAY,true);ramp.rotation.x=deg_to_rad(12)
    g.pilot.position=Vector3(0,1,-50);g.pilot.velocity=Vector3.ZERO;await frames(15)
    key(KEY_W,true);await frames(55);key(KEY_W,false)
    check(g.pilot.position.z < -53 and g.pilot.position.y>floor_y+.2,"Player climbs a physical slope")
    ramp.queue_free();await frames(3)
    g.set_physics_process(false)
    g.pilot.position=Vector3(53,.9,-89.5)
    check(g.slice02.pickup("opening_00"),"World water pickup succeeds within reach")
    await process_frame
    check(s.state.inv.get("water",0)==1 and not is_instance_valid(g.slice02.loot_nodes["opening_00"]),"Pickup adds inventory and removes world mesh")
    check(not g.slice02.pickup("opening_00") and s.state.inv.water==1,"Depleted object cannot duplicate")
    s.transact({},{"water":1})
    check(s.state.inv.water==2,"Repeated items stack")
    var before: Dictionary=s.state.inv.duplicate()
    check(not s.transact({},{"bike_battery":8}).is_empty() and before==s.state.inv,"Overweight pickup is atomic")
    s.state.slice02.modules=["scanner","cargo"]
    for store in ["bike","drone","trailer","workbench","world"]:
        check(FieldStorage.transfer(s.state,s.content.items,"backpack",store,"water").is_empty(),"Transfer into "+store)
        check(FieldStorage.transfer(s.state,s.content.items,store,"backpack","water").is_empty(),"Retrieve from "+store)
    check(not FieldStorage.transfer(s.state,s.content.items,"backpack","battery","water").is_empty(),"Battery rack rejects incompatible supply")
    s.state.inv.bike_battery=1
    check(not FieldStorage.transfer(s.state,s.content.items,"backpack","drone","bike_battery").is_empty(),"Drone payload rejects excessive mass")
    s.state.inv.erase("bike_battery")
    s.state.drone_mode="DOCK"
    check(FieldStorage.equip(s.state,"cargo").is_empty() and FieldStorage.equip(s.state,"cargo").is_empty(),"Docked module replacement succeeds")
    s.state.mode="drone";s.state.drone_mode="MANUAL";g.drone.position=Vector3(50.5,2,-98)
    check(g.slice02.pickup("opening_10"),"Drone cargo module physically retrieves propeller")
    check(FieldStorage.contents(s.state,"drone").get("propeller",0)==1,"Retrieved object occupies drone storage")
    check(not FieldStorage.equip(s.state,"cargo").is_empty(),"Airborne reconfiguration rejected")
    s.state.slice02.modules=[];s.state.drone_mode="HOLD";s.state.drone=1;g.drone.velocity=Vector3.ZERO;g.drone.position=g.bike.position+Vector3(0,8,0)
    g.update_drone(1,0,0,Basis.IDENTITY);var light_use: float=1-s.state.drone
    s.state.drone=1;s.state.slice02.modules=["spotlight","cargo"];g.update_drone(1,0,0,Basis.IDENTITY)
    check(1-s.state.drone>light_use,"Equipped mass and power increase actual battery consumption")
    s.state.slice02.modules=["scanner","marker"];s.state.drone_mode="MANUAL";s.state.mode="drone";g.camera.position=Vector3(0,10,-50);g.camera.look_at(Vector3(0,0,-51))
    var count: int=g.targets.size();g.slice02.payload_action()
    check(s.state.slice02.payload==2 and g.targets.size()==count+1,"Marker consumes payload and creates world designation")
    g.slice02.payload_action()
    check(s.state.slice02.payload==2,"Cooldown prevents repeated payload consumption")
    s.state.mode="foot";s.state.drone_mode="DOCK";g.pilot.position=Vector3(49.5,1,-100)
    g.slice02.backpack();check(g.slice02.list.item_count>0,"Backpack builds selectable item rows")
    s.state.slice02.cooldown=0;s.state.inv.fuel=1
    FieldStorage.transfer(s.state,s.content.items,"backpack","generator","fuel")
    s.state.fuel=2.5;s.state.slice02.opening.signal=true
    g.save_now();s.state.fuel=0;s.state.slice02.picked=[]
    check(s.load_game(),"Slice 02 save reload accepted")
    check(s.state.fuel==2.5 and FieldStorage.contents(s.state,"generator").get("fuel",0)==1,"Tank and stored fuel persist")
    check("opening_00" in s.state.slice02.picked and FieldStorage.contents(s.state,"drone").get("propeller",0)==1,"Physical loot and drone cargo persist")
    check(s.state.slice02.opening.get("signal",false),"Opening discovery persists")
    var invalid: Dictionary=s.state.duplicate(true);invalid.slice02.stores.drone={"bike_battery":1}
    check(not s.validate(invalid),"Invalid overweight storage save rejected")
    var legacy: Dictionary=s.state.duplicate(true);legacy.erase("slice02")
    check(s.validate(legacy),"Vertical Slice 01 saves remain accepted")
    g.queue_free();await process_frame;await create_timer(.2).timeout
    print("VS02 CHECKS: ",checks," / FAILURES: ",failures);quit(1 if failures else 0)
