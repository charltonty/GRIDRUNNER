extends SceneTree
var failures := 0

func _initialize() -> void:
    run.call_deferred()

func check(ok: bool,description: String) -> void:
    if not ok: failures+=1; push_error(description)
    else: print("PASS: "+description)

func click(game,label: String) -> void:
    for child in game.rows.get_children():
        if child is Button and child.text==label:
            child.pressed.emit()
            return
    check(false,"Button exists: "+label)

func key(code: int,pressed: bool) -> void:
    var event:=InputEventKey.new()
    event.physical_keycode=code
    event.keycode=code
    event.pressed=pressed
    Input.parse_input_event(event)

func run() -> void:
    await process_frame
    var session=root.get_node("Session")
    session.save_path="user://gridrunner_regression_test.json"
    session.reset()
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await physics_frame
    check(game.targets.size()>40,"Native scene builds campaign, NPC and salvage targets")
    check(session.state.mode=="foot","New game starts on foot at camp")
    for i in range(20): await physics_frame
    var walking_start: Vector3=game.pilot.position
    key(KEY_W,true)
    for i in range(30): await physics_frame
    key(KEY_W,false)
    check(walking_start.distance_to(game.pilot.position)>1,"Walking physically moves the player")
    var jump_start: float=game.pilot.position.y
    key(KEY_SPACE,true)
    for i in range(10): await physics_frame
    key(KEY_SPACE,false)
    check(game.pilot.position.y>jump_start+0.2,"Walking jump leaves the floor")
    game.bike.position=Vector3(0,1.1,-30)
    game.pilot.position=Vector3(2,1.3,-30)
    game.mount()
    check(session.state.mode=="bike","Mount nearby bike")
    for i in range(30): await physics_frame
    var start: Vector3=game.bike.position
    key(KEY_W,true)
    for i in range(120): await physics_frame
    key(KEY_W,false)
    check(start.distance_to(game.bike.position)>8,"Bike physically travels over 8 metres in two seconds")
    check(game.speed>8,"Ground contacts do not suppress bike acceleration")
    key(KEY_SPACE,true)
    for i in range(80): await physics_frame
    key(KEY_SPACE,false)
    check(absf(game.speed)<0.1,"Brake stops bike")
    var reverse_start: Vector3=game.bike.position
    key(KEY_S,true)
    for i in range(90): await physics_frame
    key(KEY_S,false)
    check(game.bike.position.z>reverse_start.z+1,"Reverse physically moves bike backwards")
    game.recover_bike()
    check(game.bike.position.x==0 and game.speed==0,"Recovery resets safely to road")
    game.speed=0
    game.mount()
    check(session.state.mode=="foot","Dismount")
    game.launch()
    check(session.state.mode=="drone","Drone launch")
    var initial_alt: float=game.drone.position.y
    key(KEY_SPACE,true)
    for i in range(30): await physics_frame
    key(KEY_SPACE,false)
    check(game.drone.position.y>initial_alt,"Space ascends")
    var high: float=game.drone.position.y
    key(KEY_SHIFT,true)
    for i in range(90): await physics_frame
    key(KEY_SHIFT,false)
    check(game.drone.position.y<high,"Shift descends")
    game.scan()
    check(session.state.tags.size()>0,"Scan persists nearby discoveries")
    game.command_drone("FOLLOW")
    check(session.state.mode=="foot" and session.state.drone_mode=="FOLLOW","Follow restores physical pilot mode")
    game.command_drone("HOLD")
    check(session.state.drone_mode=="HOLD","Hold command")
    game.drone.position=game.bike.position+Vector3(0,3,0)
    game.command_drone("RETURN")
    game.update_drone(0.02,0,0,Basis.IDENTITY)
    check(session.state.drone_mode=="DOCK","Physical return docks")
    game.cycle_camera()
    check(session.state.pov.walking==1 and session.state.pov.bike==0,"Independent POV preferences")
    session.state.inv.steel=3
    check(session.transact({"steel":2},{"wire":1}).is_empty(),"Atomic recipe transaction")
    check(session.state.inv.steel==1 and session.state.inv.wire==1,"Transaction counts")
    check(not session.transact({"steel":99},{}).is_empty() and session.state.inv.steel==1,"Missing inputs preserve inventory")
    var before: Dictionary=session.state.inv.duplicate()
    check(not session.transact({},{"steel":999}).is_empty() and session.state.inv==before,"Capacity failure is atomic")
    session.state.inv.pickaxe=1
    for record in session.state.field:
        if record.kind!="node":continue
        game.pilot.position=Vector3(record.x,1,record.z)
        var units: int=int(record.left)
        var held: int=int(session.state.inv.get(record.resource,0))
        game.mine_id=record.id
        game.mine_time=4
        game.update_mining(4.1)
        check(int(record.left)==units-1 and int(session.state.inv.get(record.resource,0))==held+1,"Mining yields one finite resource")
        break
    session.state.reserve=0
    session.state.fuel=1
    session.state.generator="fuel"
    game.generate(10)
    check(abs(session.state.reserve-0.4)<0.0001,"12 kW generator / accelerated game time")
    session.state.reserve=0.8
    var fuel: float=session.state.fuel
    game.generate(10)
    check(session.state.fuel==fuel,"Full reserve consumes no fuel")
    session.state.field[0].items.clear()
    game.save_now()
    session.state.battery=0
    check(session.load_game(),"Native save reload")
    check(session.state.battery>0 and session.state.field[0].items.is_empty(),"Energy and depleted loot restored")
    var invalid: Dictionary=session.state.duplicate(true)
    invalid.battery=-1
    check(not session.validate(invalid),"Malformed save rejected")
    var legacy: Dictionary=session.state.duplicate(true)
    legacy.erase("bike_heading")
    check(session.validate(legacy),"Older saves without independent bike heading remain valid")
    session.state.mode="bike"
    game.mission("camp")
    session.state.mode="drone"
    game.mission("relay")
    session.state.mode="bike"
    session.state.battery=2
    game.mission("tower")
    click(game,"Travel to Leg 2")
    check(session.state.leg==2,"Leg 1 completion travels to Leg 2")
    game.mission("l2cal")
    session.state.mode="drone"
    game.mission("l2intake")
    session.state.mode="bike"
    game.mission("l2note")
    game.mission("l2phase")
    click(game,"B"); click(game,"A"); click(game,"C")
    check(session.state.flags.get("l2phase",false),"Breaker sequence restores waterworks")
    session.state.battery=2
    game.mission("l2archive")
    click(game,"Travel to Leg 3")
    check(session.state.leg==3,"Leg 2 completion travels to Leg 3")
    session.state.flags.engineer=true
    session.state.mode="drone"
    game.mission("l3security")
    session.state.mode="bike"
    game.mission("l3key")
    game.mission("l3antenna")
    click(game,"3"); click(game,"1"); click(game,"4")
    check(session.state.flags.get("l3antenna",false),"Antenna bearing accepted")
    session.state.battery=2
    game.mission("l3capacitor")
    game.mission("l3core")
    click(game,"restore")
    check(session.state.flags.get("ending","")=="restore","Final campaign decision")
    game.close_panel()
    session.state.mode="foot"
    game.pilot.position=game.trailer.position+Vector3(40,0,0)
    game.power_panel()
    check(not game.panel.visible,"Power controls reject remote operation")
    game.pilot.position=game.trailer.position
    game.inventory(); game.power_panel(); game.map_panel(); game.menu()
    check(game.panel.visible,"Native menu screens render")
    session.state.mode="drone"
    session.state.drone_mode="MANUAL"
    session.state.drone=0.1
    game.drone_origin_mode="foot"
    game.drone.position=game.bike.position+Vector3(50,10,0)
    game.close_panel()
    game.update_drone(0.1,1,1,Basis.IDENTITY)
    check(session.state.drone_mode=="RETURN" and session.state.mode=="foot","Low battery forces return out of manual mode")
    game.queue_free()
    await process_frame
    # Allow the audio mixer to release stopped loop playback before shutdown.
    await create_timer(0.2).timeout
    print("NATIVE TEST FAILURES: ",failures)
    quit(1 if failures else 0)
