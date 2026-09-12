extends Node
const SURFACES=["dirt","dry_soil","grass","leaves","gravel","rock","concrete","asphalt","wood","metal","mud","water","interior"]
const ALIASES={"ground":"dirt","steel":"metal","rust":"metal","olive":"metal","dark":"metal","floor":"interior"}
var wind: AudioStreamPlayer
var motor: AudioStreamPlayer
var rotors: AudioStreamPlayer
var steps: AudioStreamPlayer
var landing: AudioStreamPlayer
var equipment: AudioStreamPlayer
var tires: AudioStreamPlayer
var freewheel: AudioStreamPlayer
var banks: Dictionary={}
var last: Dictionary={}
var stride:=0.0
var played_steps:=0
var played_landings:=0
var last_surface:="dirt"
var last_sample:=-1
var rng:=RandomNumberGenerator.new()
var zones: Array=[]
var quiet:=false
func _ready() -> void:
    rng.randomize()
    for bus in ["Ambience","Music","Footsteps","Bike","Drone","Electrical","World SFX","Radio","UI","Dialogue"]:
        if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
    for surface in SURFACES:
        for prefix in ["","land_"]:
            var key: String=prefix+surface;banks[key]=[]
            for i in range(5):banks[key].append(load("res://assets/audio/polish/%s_%d.wav" % [key,i]))
    wind=player("wind","Ambience",true)
    motor=player("motor","Bike",true);rotors=player("rotors","Drone",true)
    steps=player("polish/dirt_0","Footsteps",false)
    landing=player("polish/land_dirt_0","Footsteps",false)
    equipment=player("polish/equipment_0","Footsteps",false)
    tires=player("polish/tire","Bike",true);freewheel=player("polish/freewheel","Bike",true)
func player(file: String,bus: String,looped: bool) -> AudioStreamPlayer:
    var n:=AudioStreamPlayer.new();n.bus=bus;n.stream=load("res://assets/audio/"+file+".wav");add_child(n);n.volume_db=-80
    if looped:
        n.stream=n.stream.duplicate();n.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;n.stream.loop_end=n.stream.data.size()/2;n.play()
    return n
func canonical(surface: String) -> String:
    var s: String=ALIASES.get(surface,surface)
    return s if s in SURFACES else "dirt"
func surface_at(body: CharacterBody3D) -> String:
    var volume_query:=PhysicsRayQueryParameters3D.create(body.global_position,body.global_position-Vector3.UP*1.6,16)
    volume_query.collide_with_areas=true;volume_query.collide_with_bodies=false
    var tagged:=body.get_world_3d().direct_space_state.intersect_ray(volume_query)
    var q:=PhysicsRayQueryParameters3D.create(body.global_position,body.global_position-Vector3.UP*1.6,1)
    var hit:=body.get_world_3d().direct_space_state.intersect_ray(q)
    if hit.is_empty():return last_surface
    if not tagged.is_empty() and hit.position.y<tagged.position.y:return canonical(str(tagged.collider.get_meta("surface","dirt")))
    return canonical(str(hit.collider.get_meta("surface","dirt")))
func choose(key: String) -> AudioStream:
    var index:=rng.randi_range(0,3)
    if index>=int(last.get(key,-1)):index+=1
    index=clampi(index,0,4);last[key]=index;last_sample=index
    return banks[key][index]
func locomotion(velocity: Vector3,delta: float,grounded: bool,crouched: bool,surface: String,just_landed: bool=false) -> void:
    var speed:=Vector2(velocity.x,velocity.z).length()
    if not grounded or just_landed:stride=0;return
    if speed<.35:stride=0;return
    stride+=speed*delta
    var length:=.9 if crouched else lerpf(1.5,2.1,clampf((speed-5.5)/3,0,1))
    if stride>=length:
        stride=fmod(stride,length)
        step_surface(surface,.3 if crouched else lerpf(.65,1.0,clampf(speed/8.5,0,1)))
func step_surface(surface: String,intensity: float=0.8) -> void:
    last_surface=canonical(surface);steps.stream=choose(last_surface)
    steps.pitch_scale=rng.randf_range(.96,1.04)
    steps.volume_db=linear_to_db(maxf(Session.volume*.24*intensity*rng.randf_range(.9,1.04),.0001));steps.play();played_steps+=1
    if played_steps%4==0:
        equipment.pitch_scale=rng.randf_range(.94,1.06);equipment.volume_db=linear_to_db(maxf(Session.volume*.04*intensity,.0001));equipment.play()
func step(asphalt: bool) -> void:step_surface("asphalt" if asphalt else "dirt")
func land(surface: String,velocity: float) -> void:
    last_surface=canonical(surface);landing.stream=choose("land_"+last_surface)
    landing.pitch_scale=lerpf(1,.86,clampf(velocity/20,0,1))
    landing.volume_db=linear_to_db(maxf(Session.volume*lerpf(.10,.40,clampf((velocity-2)/15,0,1)),.0001));landing.play();played_landings+=1;stride=0
func jump(_surface: String) -> void:
    stride=0;equipment.volume_db=linear_to_db(maxf(Session.volume*.055,.0001));equipment.play()
func signal_ping(strength: float) -> void:
    if quiet:return
    equipment.volume_db=linear_to_db(maxf(Session.volume*.03*strength,.0001));equipment.play()
func update_audio(mode: String,speed: float,flight_speed: float,volume: float) -> void:
    if wind==null:return
    quiet=mode=="pause"
    var master:=maxf(volume,.0001)
    wind.volume_db=linear_to_db(master*(.035 if not quiet else .004))
    var load_: float=1.0 if Input.is_physical_key_pressed(KEY_W) else .18
    motor.volume_db=linear_to_db(master*minf(speed/25,1)*.09*load_) if mode=="bike" and speed>.2 else -80
    motor.pitch_scale=lerpf(motor.pitch_scale,.75+speed/45,.06)
    tires.volume_db=linear_to_db(master*minf(speed/18,1)*.055) if mode=="bike" else -80
    tires.pitch_scale=.8+speed/55
    freewheel.volume_db=linear_to_db(master*.025*minf(speed/15,1)) if mode=="bike" and load_<.5 else -80
    freewheel.pitch_scale=.7+speed/35
    var game=get_parent()
    var deployed: bool=Session.state.drone_mode!="DOCK"
    var distance: float=game.drone.position.distance_to(game.pilot.position)
    var gain:=.042 if mode=="drone" else .1/(1+distance*.22)
    rotors.volume_db=linear_to_db(master*gain*(.7+minf(flight_speed/25,.3))) if deployed and not quiet else -80
    rotors.pitch_scale=lerpf(rotors.pitch_scale,.82+flight_speed/70,.08)
    for entry in zones:
        if is_instance_valid(entry.node):entry.node.volume_db=-80 if quiet else linear_to_db(master*entry.gain)
func spatial(parent: Node3D,file: String,pos: Vector3,gain: float=0.12,distance: float=30) -> void:
    var n:=AudioStreamPlayer3D.new();n.stream=load("res://assets/audio/polish/"+file+".wav").duplicate()
    n.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;n.stream.loop_end=n.stream.data.size()/2
    n.bus="Ambience";n.max_distance=distance;n.unit_size=6;n.volume_db=linear_to_db(maxf(Session.volume*gain,.0001))
    parent.add_child(n);n.position=pos;n.play(rng.randf()*n.stream.get_length());zones.append({"node":n,"gain":gain})
func _exit_tree() -> void:
    for n in [wind,motor,rotors,steps,landing,equipment,tires,freewheel]:
        if is_instance_valid(n):n.stop();n.stream=null
