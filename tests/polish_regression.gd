extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,title: String) -> void:
    checks+=1
    if ok:print("PASS: ",title)
    else:failures+=1;push_error(title)
func frames(n: int) -> void:
    for i in range(n):await physics_frame
func run() -> void:
    await process_frame
    var s=root.get_node("Session");s.reset();s.save_path="user://polish_regression.json"
    var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await frames(10);g.set_physics_process(false)
    for mode in ["foot","bike","drone"]:
        s.state.mode=mode;g.refresh_hud();check(g.field_hud.mode==mode,"HUD operating mode "+mode)
    g.menu();g.field_hud.update_view();check(not g.field_hud.visible,"HUD hidden under pause panel")
    g.close_panel();check(g.field_hud.visible,"HUD returns after pause")
    var a=g.audio_rig
    for surface in a.SURFACES:
        check(a.banks[surface].size()==5 and a.banks["land_"+surface].size()==5,"Five step and landing variants / "+surface)
        var hashes: Array=[]
        for sample in a.banks[surface]:
            var hash_: int=hash(sample.data)
            if not hash_ in hashes:hashes.append(hash_)
        check(hashes.size()==5,"Distinct sample bytes / "+surface)
        var previous:=-1;var repeated:=false
        for i in range(30):
            a.choose(surface)
            if previous==a.last_sample:repeated=true
            previous=a.last_sample
        check(not repeated,"No adjacent sample repeat / "+surface)
    var before: int=a.played_steps
    a.locomotion(Vector3(8,0,0),1,false,false,"grass")
    check(a.played_steps==before,"No airborne footsteps")
    a.locomotion(Vector3.ZERO,1,true,false,"grass")
    check(a.played_steps==before,"No idle footsteps")
    a.locomotion(Vector3(5,0,0),.4,true,false,"grass")
    check(a.played_steps==before+1,"Distance-driven cadence produces step")
    a.locomotion(Vector3(8,0,0),1,true,false,"grass",true)
    check(a.played_steps==before+1,"Landing frame suppresses ordinary step")
    a.step_surface("grass",1);var loud: float=a.steps.volume_db
    a.step_surface("grass",.3);check(a.steps.volume_db<loud-7,"Crouch intensity substantially quieter")
    a.land("metal",3);var small: float=a.landing.volume_db
    a.land("metal",15);check(a.landing.volume_db>small+3,"Landing intensity follows fall velocity")
    check(a.canonical("rust")=="metal" and a.canonical("unknown")=="dirt","Metadata aliases and safe surface fallback")
    g.pilot.position=Vector3(0,1,-60);await frames(3)
    check(a.surface_at(g.pilot)=="asphalt","Road physics metadata supplies asphalt surface")
    s.state.mode="drone";s.state.drone_mode="MANUAL"
    var trial=g.polish.activities
    trial.start();check(trial.armed and not trial.active,"Trial arms before timing starts")
    check(not trial.crosses(trial.COURSE[0]+Vector3.UP*5,trial.COURSE[0]-Vector3.UP*5,0),"Wrong plane approach rejected")
    for i in range(trial.COURSE.size()):
        var center: Vector3=trial.COURSE[i]
        var dir: Vector3=(trial.COURSE[1]-center).normalized() if i==0 else (center-trial.COURSE[i-1]).normalized()
        check(not trial.crosses(center+dir,center-dir,i),"Reverse crossing rejected / "+str(i))
        trial.last_pos=center-dir;g.drone.position=center+dir;trial.tick(4)
    check(not trial.active and trial.checkpoint==6,"All six ordered crossings complete course")
    check(s.state.polish.best>0 and s.state.polish.medal=="GOLD","Best time and medal recorded")
    var best: float=s.state.polish.best
    trial.elapsed=best+20;trial.finish();check(s.state.polish.best==best,"Slower finish preserves personal best")
    trial.start();s.state.mode="foot";trial.tick(.1);check(not trial.armed and not trial.active,"Leaving FPV cancels trial")
    check(trial.signal_strength(trial.SOURCE+Vector3(1,0,0),Vector3.LEFT)>trial.signal_strength(trial.SOURCE+Vector3(80,0,0),Vector3.LEFT),"Signal rises on approach")
    check(trial.signal_strength(trial.SOURCE+Vector3(30,0,0),Vector3.LEFT)>trial.signal_strength(trial.SOURCE+Vector3(30,0,0),Vector3.RIGHT),"Signal responds to antenna heading")
    check(not g.targets.any(func(t):return t.id=="repeater_cache"),"Hidden carrier is not a scan waypoint")
    s.state.mode="drone";g.drone.position=trial.SOURCE+Vector3(1,1,0);trial.reception=.9;trial.record_scan(2)
    check("creek_repeater" in s.state.polish.signals,"Close recon resolves signal")
    trial.record_scan(2);check(s.state.polish.signals.size()==1,"Signal discovery cannot duplicate")
    s.state.mode="foot";s.state.inv.wire=0
    g.polish.interact("breaker");check(not s.state.polish.gates.get("power",false),"Gate repair requires resource")
    g.polish.interact("shortcut");check(not s.state.polish.gates.get("shortcut",false),"Unpowered shortcut stays closed")
    s.state.inv.wire=1;g.polish.interact("breaker");check(s.state.polish.gates.power and s.state.inv.wire==0,"Repair consumes one wire once")
    g.polish.interact("shortcut");await process_frame;check(s.state.polish.gates.shortcut and not is_instance_valid(g.polish.gate),"Powered shortcut removes physical gate")
    g.polish.interact("cache");var count: int=s.state.inv.get("water",0);g.polish.interact("cache")
    check(s.state.inv.water==count and count>0,"Micro-POI loot is finite")
    check(g.polish.npcs.size()>0,"Ambient residents registered")
    check(g.world.get_node_or_null("OpeningEcology")!=null,"Chunked opening ecology exists")
    check(s.save_game() and s.load_game(),"New state saves and loads")
    check(s.state.polish.best==best and s.state.polish.gates.shortcut and s.state.polish.signals.size()==1,"Records, shortcut and carrier persist")
    var old: Dictionary=s.state.duplicate(true);old.erase("polish");check(s.validate(old),"Pre-polish saves remain compatible")
    var bad: Dictionary=s.state.duplicate(true);bad.polish.best=-1;check(not s.validate(bad),"Malformed negative record rejected")
    bad=s.state.duplicate(true);bad.polish.gates="invalid";check(not s.validate(bad),"Malformed gate state rejected")
    # Actual CharacterBody movement down the service trail, not just metadata inspection.
    s.state.mode="foot";g.pilot.position=Vector3(57,1,-113);g.pilot.velocity=Vector3.ZERO
    var route=load("res://world/authored_opening.gd").TRAIL
    for index in range(1,route.size()):
        var target: Vector3=route[index]
        for i in range(420):
            var flat:=Vector3(g.pilot.position.x,0,g.pilot.position.z)
            if flat.distance_to(target)<1.3:break
            var dir: Vector3=(target-flat).normalized()
            g.traversal.update(g.pilot,1.0/60,dir,false,false,false,0)
            await physics_frame
        check(Vector2(g.pilot.position.x-target.x,g.pilot.position.z-target.z).length()<1.5,"Physical service path segment "+str(index)+" at "+str(g.pilot.position))
        if index==6:
            for j in range(g.pilot.get_slide_collision_count()):
                var hit=g.pilot.get_slide_collision(j)
                print("PATH CONTACT ",hit.get_collider().get_path()," at ",hit.get_position()," normal ",hit.get_normal())
    # Same aircraft body physically flies each aperture; no teleport between course gates.
    s.state.mode="drone";s.state.drone_mode="MANUAL";s.state.drone=1
    var first_direction: Vector3=(trial.COURSE[1]-trial.COURSE[0]).normalized()
    g.drone.position=trial.COURSE[0]-first_direction*4;g.drone.velocity=Vector3.ZERO;trial.start()
    for index in range(trial.COURSE.size()):
        var dir: Vector3=first_direction if index==0 else (trial.COURSE[index]-trial.COURSE[index-1]).normalized()
        var target: Vector3=trial.COURSE[index]+dir*1.5
        for i in range(420):
            if g.drone.position.distance_to(target)<.15:break
            g.drone.velocity=(target-g.drone.position).normalized()*5
            g.drone.move_and_slide();trial.tick(1.0/60);await physics_frame
        check(trial.checkpoint>index,"Physical drone aperture "+str(index))
    check(not trial.active and trial.checkpoint==6,"Actual flight completes Creek Run")
    g.drone.position=Vector3(45,3.5,-184)
    for i in range(60):
        g.drone.velocity=Vector3.DOWN*.2;g.drone.move_and_slide();await physics_frame
    g.drone.velocity=Vector3.ZERO
    var perches: int=s.state.polish.landings
    for i in range(130):g.polish.tick(1.0/60)
    check(s.state.polish.landings==perches+1,"Stable precision perch records once")
    check(g.polish.npcs[0].node.get_node_or_null("Head")!=null,"Resident uses imported anatomical head")
    check(g.polish.npcs[0].node.get_node_or_null("EyeL")!=null and g.polish.npcs[0].node.get_node_or_null("EyeR")!=null,"Resident eyes remain visible face geometry")
    print("POLISH CHECKS: ",checks," / FAILURES: ",failures)
    g.queue_free();await process_frame;quit(1 if failures else 0)
