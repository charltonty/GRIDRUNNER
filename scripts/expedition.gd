extends Node3D

var pilot: CharacterBody3D
var bike: CharacterBody3D
var drone: CharacterBody3D
var trailer: Node3D
var camera: Camera3D
var world: Node3D
var hud: Label
var panel: PanelContainer
var rows: VBoxContainer
var message := "Welcome to Black Creek. Explore the camp; E talks to Mara. F mounts your bike."
var targets: Array = []
var yaw := 0.0
var pitch := 0.0
var speed := 0.0
var drone_origin_mode := "bike"
var clock := 0.0
var autosave := 0.0
var mine_id := ""
var mine_time := 0.0
var current_target: Dictionary = {}
var sound: AudioStreamPlayer
var loop_sound: AudioStreamPlayer
var headlight: SpotLight3D
var materials := {}
var footstep_time := 0.0
var audio_rig: Node
var speed_label: Label
var objective_label: Label
var prompt_label: Label
var drone_frame: Control
var bike_heading := 0.0
var last_safe_bike := Vector3(0,1,15)
var status_timer := 0.0
var traversal:=FieldTraversal.new()
var slice02: Node
var polish: Node
var field_hud: Control
var asset_pass=preload("res://systems/asset_integration.gd").new()

func _ready() -> void:
    world = Node3D.new()
    add_child(world)
    pilot = body(Vector3(0.6,1.7,0.6), Color("7b8a78"),2)
    bike = body(Vector3(0.8,1.1,2.1), Color("23373e"),4)
    drone = body(Vector3(0.65,0.25,0.65), Color("548e95"),8)
    drone.collision_mask = 1
    for vehicle in [pilot,bike,drone]:
        for child in vehicle.get_children():
            if not child is CollisionShape3D: child.queue_free()
    bike.add_child(load("res://scenes/props/Bike.tscn").instantiate())
    drone.add_child(load("res://scenes/props/Drone.tscn").instantiate())
    var person: Node3D = load("res://scenes/props/NPC.tscn").instantiate()
    person.position.y=-0.85
    pilot.add_child(person)
    trailer=load("res://scenes/props/PowerTrailer.tscn").instantiate()
    add_child(trailer)
    bike.floor_snap_length=0.45
    bike.floor_constant_speed=true
    bike.floor_max_angle=deg_to_rad(46)
    pilot.floor_snap_length=0.3
    pilot.floor_max_angle=deg_to_rad(46)
    pilot.floor_constant_speed=true
    camera=Camera3D.new()
    add_child(camera)
    camera.current=true
    camera.far=1800
    headlight=SpotLight3D.new()
    bike.add_child(headlight)
    headlight.position=Vector3(0,0.5,-1.15)
    headlight.light_energy=4
    headlight.spot_range=65
    var environment := WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_curve=0.8
    sky_material.sky_top_color=Color("263e50")
    sky_material.sky_horizon_color=Color("6f8790")
    sky_material.ground_bottom_color=Color("303c3b")
    sky_material.ground_horizon_color=Color("71817e")
    sky_material.sun_angle_max=3.0
    sky.sky_material=sky_material
    environment.environment.sky=sky
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    environment.environment.ambient_light_energy=0.62
    environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    environment.environment.fog_enabled=true
    environment.environment.fog_light_color=Color("72858b")
    environment.environment.fog_density=0.0012
    environment.environment.fog_sky_affect=0.12
    add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-28,-35,0)
    sun.light_color=Color("c9dce6")
    sun.light_energy=0.55
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=80
    sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
    add_child(sun)
    build_ui()
    sound=AudioStreamPlayer.new()
    add_child(sound)
    loop_sound=AudioStreamPlayer.new()
    add_child(loop_sound)
    audio_rig=load("res://systems/field_audio.gd").new()
    add_child(audio_rig)
    slice02=load("res://systems/slice02.gd").new()
    add_child(slice02)
    polish=load("res://systems/polish.gd").new()
    add_child(polish)
    restore_positions()
    build_world()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func body(size: Vector3,color: Color,layer: int) -> CharacterBody3D:
    var b:=CharacterBody3D.new()
    b.collision_layer=layer
    b.collision_mask=1
    add_child(b)
    var collision:=CollisionShape3D.new()
    var shape:=BoxShape3D.new()
    shape.size=size
    collision.shape=shape
    b.add_child(collision)
    box(b,Vector3.ZERO,size,color)
    return b

func box(parent: Node3D,pos: Vector3,size: Vector3,color: Color,solid:=false) -> Node3D:
    var node: Node3D=StaticBody3D.new() if solid else Node3D.new()
    parent.add_child(node)
    node.position=pos
    var m:=MeshInstance3D.new()
    var mesh:=BoxMesh.new()
    mesh.size=size
    m.mesh=mesh
    var key:=color.to_html()
    if not materials.has(key):
        var material:=StandardMaterial3D.new()
        material.albedo_color=color
        material.roughness=0.85
        materials[key]=material
    m.material_override=materials[key]
    node.add_child(m)
    if color==Color("303a3e"): m.material_override=FieldKit.mat("asphalt")
    elif size.y<=1.0 and size.x>100: m.material_override=FieldKit.mat("ground")
    if solid:
        node.set_meta("surface","asphalt" if color==Color("303a3e") else "dirt")
        var c:=CollisionShape3D.new()
        var shape:=BoxShape3D.new()
        shape.size=size
        c.shape=shape
        node.add_child(c)
    return node

func wheel(parent: Node3D,pos: Vector3,radius: float) -> void:
    var m:=MeshInstance3D.new()
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=0.15
    mesh.radial_segments=12
    m.mesh=mesh
    m.position=pos
    m.rotation.z=PI/2
    parent.add_child(m)

func label3(text: String,pos: Vector3) -> void:
    var label:=Label3D.new()
    label.text=text
    label.position=pos
    label.font_size=28
    label.pixel_size=0.006
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.visibility_range_end=14
    label.modulate=Color("e5d9b4")
    world.add_child(label)

func build_world() -> void:
    for child in world.get_children():
        world.remove_child(child)
        child.queue_free()
    targets.clear()
    var leg:=int(Session.state.leg)
    var center:= -700.0-float(leg-1)*1600
    var ground_color: Color=[Color("8c7b61"),Color("667d65"),Color("586572")][leg-1]
    box(world,Vector3(0,-0.5,center),Vector3(1200,1,1900),ground_color,true)
    box(world,Vector3(0,0.025,center),Vector3(9,0.05,1850),Color("303a3e"),true)
    for i in range(36):
        var z:=center+875-i*50
        box(world,Vector3(0,0.065,z),Vector3(0.2,0.03,18),Color("ceb98a"))
    for n in Session.content.residents:
        var site: Dictionary={}
        for p in Session.content.settlements:
            if p.id==n.site: site=p
        if int(site.leg)!=leg: continue
        var pos:=Vector3(site.x-8,1.1,site.z+4)
        FieldKit.npc(world,pos-Vector3(0,1.1,0),n.id=="riggs")
        add_target(n.id,n.name+" / "+n.role,pos,"npc")
    for p in Session.state.field:
        if int(p.leg)!=leg: continue
        var alive: bool=int(p.left)>0 if p.kind=="node" else not p.items.is_empty()
        if not alive: continue
        var pos:=Vector3(p.x,0.8,p.z)
        if p.kind=="container": FieldKit.salvage(world,pos-Vector3(0,0.8,0),p.table)
        else: FieldKit.ellipsoid(world,pos-Vector3(0,0.4,0),Vector3(2.1,1.4,1.7),"rock")
        add_target(p.id,p.table+" salvage" if p.kind=="container" else p.resource+" deposit",pos,"field")
    var sites: Array=[]
    if leg==1:
        sites=[{"id":"camp","name":"MARA / CAMP","x":54,"y":2,"z":-94},{"id":"ev","name":"STRANDED EV","x":-85,"y":2,"z":-284},{"id":"solar","name":"SOLAR STORAGE","x":90,"y":2,"z":-413},{"id":"grid","name":"SUBSTATION","x":155,"y":2,"z":-730},{"id":"relay","name":"DRONE / RELAY","x":166,"y":15,"z":-778},{"id":"tower","name":"GHOST SIGNAL","x":0,"y":2,"z":-1435}]
    else: sites=Session.content.leg2 if leg==2 else Session.content.leg3
    for p in sites:
        var pos:=Vector3(p.x,p.y,p.z)
        FieldKit.cabinet(world,pos+Vector3(0,-p.y,-3))
        if p.y>5: box(world,Vector3(p.x,p.y/2,p.z-4),Vector3(1,p.y,1),Color("658580"),true)
        add_target(p.id,p.name,pos,"mission")
    FieldKit.dress_world(world,leg,center)
    if leg==2: box(world,Vector3(115,0.05,-2400),Vector3(22,0.06,600),Color("477f88"))
    if leg==3: box(world,Vector3(0,15,-4650),Vector3(45,30,20),Color("344b55"),true)
    FieldKit.batch_static(world,520)
    if slice02: slice02.dress()
    if polish: polish.dress()
    asset_pass.build(self)

func add_target(id: String,title: String,pos: Vector3,kind: String) -> void:
    targets.append({"id":id,"title":title,"pos":pos,"kind":kind})
    if kind in ["mission","npc"]: label3(title,pos+Vector3(0,2,0))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_ESCAPE:
            if panel.visible: close_panel()
            else: menu()
            return
        if panel.visible: return
        match event.keycode:
            KEY_F: mount()
            KEY_Q: launch()
            KEY_R: scan()
            KEY_E: interact()
            KEY_I: inventory()
            KEY_B: slice02.module_panel()
            KEY_X: slice02.payload_action()
            KEY_L:
                if "spotlight" in Session.state.slice02.modules and Session.state.mode=="drone":slice02.spotlight.visible=not slice02.spotlight.visible
            KEY_M: map_panel()
            KEY_H: cycle_camera()
            KEY_1: command_drone("FOLLOW")
            KEY_2: command_drone("HOLD")
            KEY_3: command_drone("RETURN")
            KEY_T: transfer_power()
            KEY_G: power_panel()
            KEY_F5: save_now()
            KEY_BACKSPACE: recover_bike()
    if event is InputEventMouseMotion and not panel.visible:
        yaw-=event.relative.x*0.002
        pitch=clampf(pitch-event.relative.y*0.002,-1.2,1.2)

func _physics_process(delta: float) -> void:
    clock+=delta
    if panel.visible:
        loop_sound.volume_db=-80
        if audio_rig: audio_rig.update_audio("pause",0,0,Session.volume)
        return
    Session.state.elapsed+=delta
    autosave+=delta
    if autosave>60:
        autosave=0
        save_now()
    var forward:=float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S))
    var side:=float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
    var mode: String=Session.state.mode
    var basis_:=Basis(Vector3.UP,yaw)
    if mode=="bike":
        var pedal: bool=Input.is_physical_key_pressed(KEY_P) or Session.state.battery<=0
        var brake := Input.is_physical_key_pressed(KEY_SPACE)
        var limit := 5.0 if pedal else 25.0
        var acceleration := 7.5 / (1.0+Session.mass(Session.state.cargo)/100.0)
        if brake: speed=move_toward(speed,0,delta*18)
        elif forward>0: speed=move_toward(speed,limit,delta*acceleration)
        elif forward<0: speed=move_toward(speed,-3.0,delta*(14.0 if speed>0 else 3.0))
        else: speed=move_toward(speed,0,delta*(0.6+speed*speed*0.004))
        if absf(bike.position.x)>10: speed=move_toward(speed,0,delta*1.0)
        var turn := side*delta*clampf(absf(speed)/3,0,1)*lerpf(1.65,0.65,clampf(absf(speed)/25,0,1))*signf(speed)
        bike_heading-=turn
        yaw-=turn
        bike.rotation.y=bike_heading
        var vertical := bike.velocity.y
        bike.velocity=-bike.basis.z*speed
        bike.velocity.y=-0.5 if bike.is_on_floor() else vertical-20*delta
        bike.move_and_slide()
        # A floor contact is not an obstacle: only lose speed against walls.
        for i in range(bike.get_slide_collision_count()):
            var hit := bike.get_slide_collision(i)
            if hit.get_normal().dot(Vector3.UP)<0.55:
                speed=bike.get_real_velocity().dot(-bike.basis.z)
        if not pedal and absf(speed)>0.1:
            Session.state.battery=maxf(0,Session.state.battery-(0.15+absf(speed)*0.05+forward*forward*1.2)*delta/300.0*(1+Session.mass(Session.state.cargo)/80))
        pilot.position=bike.position+Vector3(2,0.32,0)
        if bike.is_on_floor() and bike.position.y>0: last_safe_bike=bike.position
        if bike.position.y < -10: recover_bike()
    elif mode=="foot":
        var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)
        var result:=traversal.update(pilot,delta,basis_*Vector3(side,0,-forward).normalized(),sprinting,Input.is_physical_key_pressed(KEY_SPACE),Input.is_physical_key_pressed(KEY_CTRL),Session.mass(Session.state.inv)/40)
        pilot.rotation.y=yaw
        var surface: String=audio_rig.surface_at(pilot)
        if result.jumped:audio_rig.jump(surface)
        if result.landed:
            audio_rig.land(surface,-traversal.impact)
            Session.state.hp=maxf(1,Session.state.hp-float(result.damage))
            if not Session.state.slice02.reduced_motion:slice02.landing_offset=-.08
        if pilot.position.y < -10: pilot.position=bike.position+Vector3(2,1,0)
        audio_rig.locomotion(pilot.get_real_velocity(),delta,pilot.is_on_floor(),traversal.crouched,surface,result.landed)
    slice02.tick(delta)
    update_drone(delta,forward,side,basis_)
    trailer.position=bike.position+bike.basis.z*3.5-Vector3(0,0.5,0)
    trailer.rotation.y=bike.rotation.y
    generate(delta)
    update_camera(delta)
    if not mine_id.is_empty(): update_mining(delta)
    audio_rig.update_audio(mode,absf(speed),drone.velocity.length(),Session.volume)
    for wheel_node in get_tree().get_nodes_in_group("rolling_tires"):
        wheel_node.rotation.x-=speed*delta/float(wheel_node.get_meta("radius"))
    var visual:=bike.get_node_or_null("Bike")
    if visual: visual.rotation.z=lerpf(visual.rotation.z,side*clampf(absf(speed)/25,0,1)*0.14,delta*4)
    for rotor in get_tree().get_nodes_in_group("rotors"):
        if Session.state.drone_mode!="DOCK": rotor.rotation.y+=delta*95
    for person in get_tree().get_nodes_in_group("field_npcs"):
        if person.get_parent()==world and person.global_position.distance_to(pilot.position)<7:
            var aim:=pilot.position; aim.y=person.global_position.y
            if person.global_position.distance_to(aim)>0.1: person.look_at(aim)
    if polish: polish.tick(delta)
    refresh_hud()

func refresh_hud() -> void:
    if field_hud:field_hud.update_view()

func objective() -> String:
    var f: Dictionary=Session.state.flags
    if int(Session.state.leg)!=1: return "FOLLOW THE CARRIER  /  M opens route and discoveries"
    if not f.get("mara",false): return "01 / START CAMP  ·  Meet Mara beneath the shelter"
    var opening: Dictionary=Session.state.slice02.opening
    if not opening.get("pack",false):return "02 / PREPARE  ·  I opens Backpack; inspect tools and storage"
    if not opening.get("drone",false):return "03 / EYES ABOVE  ·  Q launches SCOUT-01; B configures equipment"
    if not opening.get("salvage",false):return "04 / SALVAGE  ·  E collects physical supplies around camp"
    if not Session.state.met.get("riggs",false): return "02 / MILEPOST REPAIR  ·  Ride to Riggs, west of the road"
    if not f.get("controller",false): return "03 / FIELD FABRICATION  ·  Scavenge wire and electronics; craft solar controller in I"
    if not f.get("relay",false): return "04 / EYES ABOVE  ·  Fly to the elevated relay behind the substation; press E"
    return "05 / GHOST SIGNAL  ·  Follow the road north to the tower"

func recover_bike() -> void:
    speed=0
    bike.velocity=Vector3.ZERO
    bike.position=Vector3(0,1.1,clampf(last_safe_bike.z,-1550-(int(Session.state.leg)-1)*1600,120-(int(Session.state.leg)-1)*1600))
    bike_heading=0; bike.rotation=Vector3.ZERO; yaw=0
    if Session.state.mode=="bike": pilot.position=bike.position+Vector3(2,0.4,0)
    message="Bike recovered to road. Backspace recovers a stuck bike."

func update_drone(delta: float,forward: float,side: float,basis_: Basis) -> void:
    var dm: String=Session.state.drone_mode
    drone.visible=dm!="DOCK"
    if dm=="DOCK":
        drone.position=bike.position+Vector3(0,1,0)
        drone.velocity=Vector3.ZERO
        return
    var home:=bike.position+Vector3(0,3,0)
    if drone.position.distance_to(home)>400 or Session.state.drone<0.12: command_drone("RETURN")
    dm=Session.state.drone_mode
    var desired:=Vector3.ZERO
    if dm=="MANUAL" and Session.state.mode=="drone" and Session.state.drone>0:
        desired=basis_*Vector3(side,0,-forward)*18
        desired.y=(float(Input.is_physical_key_pressed(KEY_SPACE))-float(Input.is_physical_key_pressed(KEY_SHIFT)))*7
    elif dm=="FOLLOW" or dm=="RETURN": desired=(home-drone.position).limit_length(1)*16
    drone.velocity=drone.velocity.move_toward(desired,delta*12)
    drone.move_and_slide()
    drone.position.y=clampf(drone.position.y,0.4,90)
    Session.state.drone=maxf(0,Session.state.drone-delta*(FieldStorage.draw_kw(Session.state,Session.content.items)/0.4/300.0+drone.velocity.length()*0.000025))
    if drone.get_slide_collision_count()>0: Session.state.drone_hp=maxf(0,Session.state.drone_hp-delta*2)
    if dm=="RETURN" and drone.position.distance_to(home)<1.5:
        Session.state.drone_mode="DOCK"
        if Session.state.mode=="drone": Session.state.mode=drone_origin_mode
        message="Drone docked"
    if Session.state.drone<=0:
        drone.velocity=Vector3(0,-1,0)
        Session.state.drone_mode="HOLD"
        if drone.position.y>0.5: drone.position.y-=delta
        message="Drone battery exhausted. Approach it to recover with Q."

func mount() -> void:
    if Session.state.mode=="drone": return
    if Session.state.mode=="bike":
        var offset := bike.basis.x*1.8
        var query:=PhysicsRayQueryParameters3D.create(bike.position,bike.position+offset,1)
        if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): offset=-offset
        pilot.position=bike.position+offset+Vector3(0,0.4,0)
        Session.state.mode="foot"; speed=0
    elif pilot.position.distance_to(bike.position)<8: Session.state.mode="bike"
    else: message="Approach your bike"

func launch() -> void:
    if Session.state.drone_mode=="DOCK":
        if Session.state.drone<0.1: message="Recharge the drone in G / Power"; return
        drone.position=bike.position+Vector3(0,3,0)
        drone_origin_mode=Session.state.mode
        Session.state.drone_mode="MANUAL"
        Session.state.mode="drone"
        speed=0
        beep(240)
    elif Session.state.drone<=0 and pilot.position.distance_to(drone.position)<8:
        Session.state.drone_mode="DOCK"
    else: command_drone("RETURN")

func command_drone(command: String) -> void:
    if Session.state.drone_mode=="DOCK": return
    Session.state.drone_mode=command
    if Session.state.mode=="drone": Session.state.mode=drone_origin_mode
    message="Drone: "+command

func actor() -> Node3D:
    return drone if Session.state.mode=="drone" else bike if Session.state.mode=="bike" else pilot

func profile() -> Dictionary:
    var key: String="walking" if Session.state.mode=="foot" else Session.state.mode
    return Session.content.profiles[key][int(Session.state.pov[key])]

func cycle_camera() -> void:
    var key: String="walking" if Session.state.mode=="foot" else Session.state.mode
    Session.state.pov[key]=(int(Session.state.pov[key])+1)%Session.content.profiles[key].size()
    beep(500)

func update_camera(_delta: float) -> void:
    var p:=profile()
    var anchor: Vector3=actor().position+Vector3(0,1.2 if Session.state.mode=="bike" else 0.7 if Session.state.mode=="foot" else 0,0)
    var offset:=Vector3(float(p.get("side",0)),float(p.height),float(p.distance)-float(p.get("front",0)))
    var desired:=anchor+Basis(Vector3.UP,yaw)*offset
    var query:=PhysicsRayQueryParameters3D.create(anchor,desired,1)
    var hit:=get_world_3d().direct_space_state.intersect_ray(query) if offset.length()>0.1 else {}
    camera.position=hit.position.lerp(anchor,0.08) if not hit.is_empty() else desired
    camera.rotation=Vector3(pitch,yaw,0)
    if p.distance>0: camera.look_at(anchor+Basis.from_euler(Vector3(pitch,yaw,0))*Vector3(0,0,-12))
    if p.id=="overhead": camera.look_at(anchor)
    if Session.state.mode=="foot":camera.position.y+=(-.3 if traversal.crouched else 0)+slice02.landing_offset
    camera.fov=clampf(72+float(p.fov)+(absf(speed)*0.25 if Session.state.mode=="bike" else 0),45,105)
    pilot.visible=Session.state.mode=="foot" and p.distance>0
    bike.visible=true
    if Session.state.mode=="drone": drone.visible=p.distance>0

func nearest() -> Dictionary:
    var result: Dictionary={}
    var best:=8.0
    for t in targets:
        var d: float=actor().position.distance_to(t.pos)
        var range_: float=3.0 if t.kind in ["pickup","storage","modules","polish","architecture"] else 8.0
        if d<best and d<range_:
            var ray:=PhysicsRayQueryParameters3D.create(actor().position+Vector3.UP*.4,t.pos+Vector3.UP*.15,1)
            if t.kind in ["pickup","storage"] and not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
            if t.kind in ["polish","architecture"]:
                var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
                if not hit.is_empty() and hit.position.distance_to(t.pos)>1.5:continue
            best=d; result=t
    return result

func scan() -> void:
    if Session.state.mode=="drone" and not "scanner" in Session.state.slice02.modules:message="Scanner module required";return
    if Session.state.drone<0.03 and Session.state.mode=="drone": return
    if Session.state.mode=="drone": Session.state.drone-=0.03
    var found:=0
    for t in targets:
        if actor().position.distance_to(t.pos)<160 and not t.id in Session.state.tags:
            Session.state.tags.append(t.id)
            found+=1
    message="Scan: %d new contacts recorded in M / Map" % found
    if polish:polish.activities.record_scan(found)
    beep(700)

func interact() -> void:
    current_target=nearest()
    if current_target.is_empty(): return
    if current_target.kind=="architecture":asset_pass.interact(current_target.id);return
    if current_target.kind=="polish":polish.interact(current_target.id);return
    if current_target.kind=="pickup":slice02.pickup(current_target.id);return
    if current_target.kind=="storage":slice02.backpack(current_target.id.trim_prefix("storage_"));return
    if current_target.kind=="modules":slice02.module_panel();return
    if current_target.kind=="marker":message="SCOUT-01 designated surface";return
    if current_target.kind=="mission": mission(current_target.id); return
    if Session.state.mode=="drone": message="Return to rider to handle supplies or talk"; return
    if current_target.kind=="npc": resident(current_target.id)
    else: field_panel(current_target.id)

func build_ui() -> void:
    var layer:=CanvasLayer.new()
    add_child(layer)
    field_hud=load("res://systems/field_hud.gd").new()
    field_hud.game=self
    layer.add_child(field_hud)
    field_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # Compatibility references retained for old capture tools; presentation lives in FieldHUD.
    hud=Label.new();speed_label=Label.new();objective_label=Label.new();prompt_label=Label.new();drone_frame=Control.new()
    for old in [hud,speed_label,objective_label,prompt_label,drone_frame]:layer.add_child(old);old.hide()
    panel=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left=110
    panel.offset_right=-110
    panel.offset_top=40
    panel.offset_bottom=-40
    layer.add_child(panel)
    var scroll:=ScrollContainer.new()
    panel.add_child(scroll)
    rows=VBoxContainer.new()
    rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override("separation",10)
    scroll.add_child(rows)
    var style:=StyleBoxFlat.new();style.bg_color=Color("17201e");style.border_color=Color("91846a");style.set_border_width_all(1)
    style.content_margin_left=24;style.content_margin_top=18;style.content_margin_right=24;style.content_margin_bottom=18
    panel.add_theme_stylebox_override("panel",style)
    panel.theme=field_hud.make_theme()
    style.bg_color=Color("0a1a20");style.border_color=Color("385156");style.border_width_top=3
    panel.hide()

func show_panel(title: String) -> void:
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    panel.show()
    field_hud.hide()
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    text(title)
    rows.get_child(0).add_theme_font_override("font",field_hud.heading_font)
    rows.get_child(0).add_theme_font_size_override("font_size",30)
    rows.get_child(0).add_theme_color_override("font_color",Color("e4ed98"))
    button("Resume / Escape",close_panel)

func text(value: String) -> void:
    var label:=Label.new()
    label.text=value
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    rows.add_child(label)

func button(title: String,callback: Callable) -> void:
    var b:=Button.new()
    b.text=title
    b.custom_minimum_size.y=38
    b.pressed.connect(callback)
    rows.add_child(b)

func close_panel() -> void:
    panel.hide()
    field_hud.show()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func menu() -> void:
    show_panel("GRIDRUNNER // EXPEDITION PAUSED")
    button("Backpack",inventory)
    button("Reduced motion: "+str(Session.state.slice02.reduced_motion),func():Session.state.slice02.reduced_motion=not Session.state.slice02.reduced_motion;menu())
    button("Foliage: "+("STANDARD" if Session.state.polish.density else "PERFORMANCE"),polish.toggle_quality)
    button("SCOUT / pilot record",polish.record_panel)
    button("Map / discoveries",map_panel)
    button("Power trailer",power_panel)
    button("Save expedition",func(): save_now(); text(message))
    button("Load expedition",func():
        if Session.load_game(): restore_positions(); build_world(); close_panel()
        else: text("No valid native save found"))
    button("Camera view: "+str(profile().label),func(): cycle_camera(); menu())
    button("Audio: %d%%" % int(Session.volume*100),func(): Session.volume=fmod(Session.volume+0.2,1.2); menu())
    text("Controls: WASD / mouse. F mount. P pedal. Q launch/recall. Space/Shift drone altitude. 1 follow, 2 hold, 3 return. E use. R scan. H camera. I inventory. G power. M map. F5 save.\nNative save files are separate from browser saves.\nThe three-leg campaign route is available; Backspace recovers the bike to the road.")
    button("Main menu",func(): save_now(); get_tree().change_scene_to_file("res://scenes/frontend.tscn"))

func inventory() -> void:
    slice02.backpack()

func crafting() -> void:
    show_panel("PACK / %.1f kg of 40 kg" % Session.mass(Session.state.inv))
    text(message)
    button("Backpack / inspect and disassemble items",inventory)
    text("FIELD FABRICATION")
    for id in Session.content.recipes:
        var r: Dictionary=Session.content.recipes[id]
        button(str(r.name)+" / "+str(r.inputs),func():
            if int(Session.state.inv.get(r.tool,0))<1: message="Requires "+str(r.tool)
            elif r.station=="trailer" and actor().position.distance_to(trailer.position)>8: message="Approach trailer workbench"
            elif Session.state.battery<float(r.energy)*0.02: message="Insufficient energy"
            else:
                message=Session.transact(r.inputs,r.output)
                if message.is_empty(): Session.state.battery-=float(r.energy)*0.02
            crafting())
    for r in [{"id":"engineer","name":"Engineer drone module","cost":{"wire":1,"electronics":1,"steel":1}},{"id":"controller","name":"Solar controller","cost":{"wire":2,"electronics":2}},{"id":"coupler","name":"Grid coupler","cost":{"wire":2,"electronics":1}}]:
        if not Session.state.flags.get(r.id,false): button(str(r.name)+" / "+str(r.cost),func():
            message=Session.transact(r.cost,{})
            if message.is_empty(): Session.state.flags[r.id]=true
            crafting())
    button("Recondition cells: 2 cells + 1 electronics → 0.44 kWh",func():
        if Session.state.battery<=1.56:
            message=Session.transact({"cells":2,"electronics":1},{})
            if message.is_empty(): Session.state.battery+=0.44
        crafting())

func field_record(id: String) -> Dictionary:
    for p in Session.state.field:
        if p.id==id: return p
    return {}

func field_panel(id: String) -> void:
    var p:=field_record(id)
    show_panel("SALVAGE / "+id)
    text(message)
    if p.kind=="node":
        text("%d units remaining / pickaxe required" % p.left)
        button("Mine / stay nearby for four seconds",func():
            if int(Session.state.inv.get("pickaxe",0))<1: message="Craft a pickaxe first"; field_panel(id)
            else: mine_id=id; mine_time=4; close_panel())
    else:
        for item in p.items.keys():
            if int(p.items[item])<=0: continue
            button("Take %s (%d)" % [Session.content.items[item].name,p.items[item]],func():
                message=Session.transact({},{item:1})
                if message.is_empty():
                    p.items[item]-=1
                    if p.items[item]<=0: p.items.erase(item)
                field_panel(id))

func update_mining(delta: float) -> void:
    var p:=field_record(mine_id)
    if Session.state.mode=="drone" or actor().position.distance_to(Vector3(p.x,1,p.z))>8: mine_id=""; message="Mining interrupted"; return
    mine_time-=delta
    message="Mining %s / %.1f seconds remaining" % [p.resource,maxf(0,mine_time)]
    if mine_time<=0:
        message=Session.transact({},{p.resource:1}) if int(p.left)>0 else "Deposit depleted"
        if message.is_empty(): p.left-=1; message="Extracted "+str(p.resource); beep(320)
        mine_id=""

func resident(id: String) -> void:
    for n in Session.content.residents:
        if n.id!=id: continue
        Session.state.met[id]=true
        show_panel(n.name+" / "+n.role)
        text(n.line+"\n\n"+n.rumor)
        text(message)
        var remaining: int=int(n.limit)-int(Session.state.trades.get(id,0))
        text("%d trades remain" % remaining)
        if remaining>0: button("Trade "+str(n.cost)+" → "+str(n.reward),func():
            message=Session.transact(n.cost,n.reward)
            if message.is_empty(): Session.state.trades[id]=int(Session.state.trades.get(id,0))+1; beep(500)
            resident(id))

func map_panel() -> void:
    show_panel("ROUTE / LEG %d / NORTH IS -Z" % Session.state.leg)
    text("Position: "+str(actor().position)+"\n"+message)
    for t in targets:
        if t.kind=="mission" or t.id in Session.state.tags:
            text("%s · %d m · x %d z %d" % [t.title,actor().position.distance_to(t.pos),t.pos.x,t.pos.z])
    for n in Session.content.residents:
        if Session.state.met.get(n.id,false): text(n.name+": "+n.rumor)

func power_panel() -> void:
    if actor().position.distance_to(trailer.position)>8:
        message="Approach your power trailer to operate equipment"
        return
    show_panel("MOBILE POWER / kW rate · kWh energy")
    text("Fuel %.2f L = %.2f kWh. Generator 12 kW; game hour = 5 minutes.\n%s" % [Session.state.fuel,Session.state.fuel*3,message])
    for mode in ["off","fuel","solar"]: button("Generation: "+mode,func(): Session.state.generator=mode; power_panel())
    button("Transfer reserve → bike",func(): transfer_power(); power_panel())
    button("Recharge docked drone: 0.2 kWh → 50%",func():
        if Session.state.drone_mode=="DOCK" and Session.state.battery>=0.2 and Session.state.drone<1:
            Session.state.battery-=0.2; Session.state.drone=minf(1,Session.state.drone+0.5)
        power_panel())
    button("Pour 1 L from pack into fuel tank",func():
        if actor().position.distance_to(trailer.position)>8: message="Approach trailer"
        elif int(Session.state.inv.get("fuel",0))>0 and Session.state.fuel<=4: Session.state.inv.fuel-=1; Session.state.fuel+=1
        power_panel())

func transfer_power() -> void:
    if actor().position.distance_to(trailer.position)>8: message="Approach trailer"; return
    var amount:=minf(0.2,minf(Session.state.reserve,2-Session.state.battery))
    Session.state.reserve-=amount
    Session.state.battery+=amount
    message="Transferred %.2f kWh" % amount

func generate(delta: float) -> void:
    if absf(speed)>0.3 or Session.state.mode=="drone": return
    var fuel: bool=Session.state.generator=="fuel" and Session.state.fuel>0
    var amount:=minf(0.8-Session.state.reserve,delta*(0.04 if fuel else 0.0026 if Session.state.generator=="solar" else 0))
    if fuel: amount=minf(amount,Session.state.fuel*3); Session.state.fuel-=amount/3
    Session.state.reserve+=amount

func spend(kwh: float) -> bool:
    if Session.state.battery<kwh: message="Need %.2f kWh; recharge with trailer or power sites" % kwh; return false
    Session.state.battery-=kwh
    return true

func mission(id: String) -> void:
    var f: Dictionary=Session.state.flags
    if Session.state.mode=="drone" and id not in ["relay","l2intake","l3security"]: message="Return to rider for this task"; return
    match id:
        "camp":
            if not f.get("mara",false):
                var error:=Session.transact({},{"steel":2,"wire":2,"electronics":2})
                if not error.is_empty(): message=error; return
                f.mara=true
            message="Mara: Restore your tools. The rooftop relay unlocks the substation and tower."
        "ev","solar","grid":
            if id=="solar" and not f.get("controller",false): message="Craft solar controller"; return
            if id=="grid" and not (f.get("relay",false) and f.get("coupler",false)): message="Need rooftop relay and grid coupler"; return
            var left: float=float(f.get(id+"_energy",0.72 if id=="ev" else 0.96 if id=="solar" else 1.4))
            var amount:=minf(left,2-Session.state.battery)
            Session.state.battery+=amount; f[id+"_energy"]=left-amount; message="Harvested %.2f kWh" % amount
        "relay","l2intake","l3security":
            if Session.state.mode!="drone": message="Fly the drone to this elevated switch"; return
            if id=="l3security" and not f.get("engineer",false): message="Engineer module required"; return
            f[id]=true; message="Remote switch activated"; beep(700)
        "tower":
            if not f.get("relay",false): message="Activate rooftop relay before decoding"; return
            if spend(0.16): f.tower=true; chapter_prompt(2)
        "l2cal":
            if not f.get(id,false):
                var error:=Session.transact({},{"wire":2,"electronics":2})
                if not error.is_empty(): message=error; return
                f[id]=true
            message="Cal: Release the drone intake. The maintenance lunchbox has the breaker sequence."
        "l2note": f[id]=true; message="Maintenance note: B → A → C"
        "l2phase":
            if not f.get("l2intake",false) or not f.get("l2note",false): message="Release intake and find note"; return
            show_panel("WATERWORKS / BREAKER SEQUENCE")
            for phase in ["A","B","C"]: button(phase,func():
                var index: int=int(f.get("phase_index",0))
                if phase==["B","A","C"][index]: index+=1
                else: index=0; message="Wrong phase; start again"
                if index==3:
                    message=Session.transact({"wire":1,"electronics":1},{})
                    if message.is_empty(): f.l2phase=true; message="Waterworks restored"
                    index=0
                    close_panel()
                f.phase_index=index)
        "l2hydro":
            if f.get("l2intake",false) and f.get("l2cal",false): Session.state.reserve=0.8; message="Hydro charged trailer"
            else: message="Meet Cal and release intake"
        "l2cache":
            if not f.get(id,false):
                message=Session.transact({},{"cells":2,"electronics":2})
                if message.is_empty(): f[id]=true; Session.state.fuel+=1
        "l2archive":
            if not f.get("l2phase",false): message="Restore waterworks first"; return
            if spend(0.4): f.l2archive=true; chapter_prompt(3)
        "l3key":
            if not f.get("l3security",false): message="Disable security relay first"; return
            f[id]=true; message="Technician bearing: 3 / 1 / 4"
        "l3antenna":
            if not f.get("l3key",false): message="Recover technician key"; return
            show_panel("ANTENNA / ENTER THREE BEARINGS")
            for digit in range(6): button(str(digit),func():
                var sequence: Array=f.get("digits",[])
                sequence.append(digit)
                f.digits=sequence
                if sequence.size()==3:
                    f.l3antenna=sequence==[3,1,4]
                    message="Antenna aligned" if f.l3antenna else "Wrong bearing"
                    f.digits=[]; close_panel())
        "l3supply":
            if not f.get(id,false) and Session.state.battery<=1.3: Session.state.battery+=0.7; Session.state.fuel+=1; f[id]=true; message="Emergency pack recovered"
        "l3capacitor":
            if not f.get("l3antenna",false): message="Align antenna first"; return
            if not f.get(id,false) and spend(0.3): f[id]=true; message="Capacitor primed"
        "l3core":
            if not f.get("l3capacitor",false): message="Prime capacitor first"; return
            show_panel("GHOST SIGNAL / ONE RESERVE, TWO FUTURES")
            if f.has("ending"): text("Completed: "+str(f.ending)); return
            for choice in ["restore","transmit"]: button(choice,func():
                if spend(0.4 if choice=="restore" else 0.16):
                    f.ending=choice; message="Campaign complete: "+choice; save_now(); close_panel())

func chapter_prompt(leg: int) -> void:
    show_panel("LEG COMPLETE / THE SIGNAL CONTINUES")
    button("Travel to Leg %d" % leg,func():
        Session.state.leg=leg; Session.state.mode="bike"; Session.state.drone_mode="DOCK"; speed=0
        bike.position=Vector3(0,1.2,-1735 if leg==2 else -3240)
        bike_heading=0; yaw=0; last_safe_bike=bike.position
        pilot.position=bike.position+Vector3(2,0,0)
        build_world(); save_now(); close_panel())

func save_now() -> void:
    Session.state.position=[pilot.position.x,pilot.position.y,pilot.position.z]
    Session.state.bike=[bike.position.x,bike.position.y,bike.position.z]
    Session.state.drone_position=[drone.position.x,drone.position.y,drone.position.z]
    Session.state.yaw=yaw; Session.state.pitch=pitch
    Session.state.bike_heading=bike_heading
    message="Expedition saved" if Session.save_game() else "Save failed"
    beep(800)

func restore_positions() -> void:
    mine_id=""
    current_target={}
    if slice02:slice02.rebuild_modules()
    var s: Dictionary=Session.state
    pilot.position=Vector3(s.position[0],s.position[1],s.position[2])
    bike.position=Vector3(s.bike[0],s.bike[1],s.bike[2])
    drone.position=Vector3(s.drone_position[0],s.drone_position[1],s.drone_position[2])
    yaw=s.yaw; pitch=s.pitch; speed=0
    bike_heading=float(s.get("bike_heading",s.yaw))
    bike.rotation.y=bike_heading
    last_safe_bike=bike.position

func wave(hz: float,duration: float,repeat:=false) -> AudioStreamWAV:
    var stream:=AudioStreamWAV.new()
    stream.mix_rate=22050
    stream.format=AudioStreamWAV.FORMAT_16_BITS
    var count:=int(22050*duration)
    var data:=PackedByteArray()
    data.resize(count*2)
    for i in range(count):
        var envelope:=1.0 if repeat else sin(PI*float(i)/count)
        var sample:=sin(TAU*hz*float(i)/22050)*envelope*0.3
        data.encode_s16(i*2,int(sample*32767))
    stream.data=data
    if repeat: stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; stream.loop_end=count
    return stream

func beep(hz: float) -> void:
    if sound==null: return
    sound.stream=wave(hz,0.045)
    sound.volume_db=linear_to_db(maxf(0.001,Session.volume*0.045))
    sound.play()
