extends SceneTree
# Ten wall-clock minutes of automated input, real scene physics and audio mixing.
# Fixture resets between modes are explicit; this is NOT a manual headphone playtest.
var g
var s
var started:=0
var stage:=-1
var frames:=0
var last_report:=0
var path_index:=0
var held: Dictionary={}
var route=[Vector3(57,0,-113),Vector3(64,0,-123),Vector3(72,0,-140),Vector3(68,0,-158),Vector3(53,0,-174),Vector3(35,0,-181),Vector3(16,0,-180)]
func _initialize() -> void:run.call_deferred()
func key(code: int,down: bool) -> void:
    if held.get(code,false)==down:return
    held[code]=down
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event)
func release() -> void:
    for code in held.keys():key(code,false)
func run() -> void:
    await process_frame
    s=root.get_node("Session");s.reset();s.save_path="user://polish_endurance.json"
    g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
    for i in range(12):await physics_frame
    started=Time.get_ticks_msec()
    while Time.get_ticks_msec()-started<600000:
        var seconds: float=(Time.get_ticks_msec()-started)/1000.0
        var next_stage:=int(seconds/120)
        if next_stage!=stage:
            stage=next_stage;release();path_index=0
            g.close_panel();s.state.drone_mode="DOCK";s.state.mode="foot";s.state.drone=1.0
            if stage in [0,3]:g.pilot.position=Vector3(57,1,-113);g.pilot.velocity=Vector3.ZERO
            if stage==1:
                g.pilot.position=g.bike.position+Vector3(2,1,0);g.launch();g.polish.activities.start()
            if stage in [2,4]:
                s.state.mode="bike";g.bike.position=Vector3(0,1,-120);g.bike_heading=0;g.yaw=0;g.speed=0;s.state.battery=2
            print("ENDURANCE stage ",stage," wall_seconds ",seconds)
        if stage in [0,3]:
            var target: Vector3=route[path_index]
            var flat: Vector3=Vector3(g.pilot.position.x,0,g.pilot.position.z)
            if flat.distance_to(target)<1.2:
                if path_index<route.size()-1:path_index+=1
                else:key(KEY_W,false)
            else:
                var dir: Vector3=target-flat;g.yaw=atan2(-dir.x,-dir.z);key(KEY_W,true)
            key(KEY_CTRL,stage==3 and int(seconds)%20<5)
        elif stage==1:
            if s.state.mode=="drone":
                var course: Array=g.polish.activities.COURSE
                var target: Vector3=course[mini(path_index,5)]
                var diff: Vector3=target-g.drone.position
                g.yaw=atan2(-diff.x,-diff.z)
                key(KEY_W,Vector2(diff.x,diff.z).length()>maxf(1.0,g.drone.velocity.length_squared()/24))
                key(KEY_SPACE,diff.y>.6);key(KEY_SHIFT,diff.y<-.6)
                if diff.length()<1.4 and path_index<5:path_index+=1
                if int(seconds)%15==0 and frames%90==0:g.scan()
        else:
            key(KEY_W,g.bike.position.z>-1400)
            if g.bike.position.z<-1400:key(KEY_SPACE,true)
        if int(seconds)/30>last_report:
            last_report=int(seconds)/30
            print("SOAK ",int(seconds),"s mode=",s.state.mode," player=",g.pilot.position," path=",path_index," fps=",Performance.get_monitor(Performance.TIME_FPS)," nodes=",get_node_count()," steps=",g.audio_rig.played_steps)
        frames+=1;await process_frame
    release()
    print("ENDURANCE COMPLETE: 600 wall seconds, ",frames," rendered frames; step events=",g.audio_rig.played_steps," landings=",g.audio_rig.played_landings)
    g.queue_free();await process_frame;quit()
