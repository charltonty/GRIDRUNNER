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
var message := "Find Mara, then follow the signal. F dismounts; Q launches the drone."
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

func _ready() -> void:
    world = Node3D.new()
    add_child(world)
    pilot = body(Vector3(0.6,1.7,0.6), Color("7b8a78"),2)
    bike = body(Vector3(0.8,1.1,2.1), Color("23373e"),4)
    drone = body(Vector3(0.65,0.25,0.65), Color("548e95"),8)
    drone.collision_mask = 1
    trailer = Node3D.new()
    add_child(trailer)
    box(trailer,Vector3(0,0.65,0),Vector3(1.4,0.9,1.8),Color("535b4d"))
    for x in [-0.75,0.75]: wheel(trailer,Vector3(x,0.45,0),0.42)
    for z in [-0.8,0.8]: wheel(bike,Vector3(0,-0.15,z),0.48)
    box(bike,Vector3(0,0.8,-0.65),Vector3(1.25,0.08,0.12),Color("8da6ab"))
    box(bike,Vector3(0,0.5,0.25),Vector3(0.6,0.2,0.8),Color("11191d"))
    for x in [-0.6,0.6]:
        for z in [-0.6,0.6]:
            box(drone,Vector3(x,0,z),Vector3(0.65,0.03,0.08),Color("adc9c3"))
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
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("879991")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color("b4c7bd")
    environment.environment.ambient_light_energy=0.6
    add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-40,-25,0)
    sun.light_energy=1.4
    add_child(sun)
    build_ui()
    sound=AudioStreamPlayer.new()
    add_child(sound)
    loop_sound=AudioStreamPlayer.new()
    add_child(loop_sound)
    loop_sound.stream=wave(90,1.0,true)
    loop_sound.play()
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
    if solid:
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
    label.font_size=40
    label.pixel_size=0.012
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.visibility_range_end=120
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
    box(world,Vector3(0,0.025,center),Vector3(18,0.05,1850),Color("303a3e"))
    for i in range(36):
        var z:=center+875-i*50
        box(world,Vector3(0,0.065,z),Vector3(0.2,0.03,18),Color("ceb98a"))
        box(world,Vector3(85,12,z),Vector3(0.7,24,0.7),Color("7c8884"),true)
        box(world,Vector3(85,21,z),Vector3(15,0.35,0.35),Color("6f7976"))
    for p in Session.content.settlements:
        if int(p.leg)!=leg: continue
        for j in range(2):
            var x: float=float(p.x)+j*22-11
            var z: float=float(p.z)
            box(world,Vector3(x,2.5,z-15),Vector3(18,5,0.5),ground_color,true)
            for dx in [-9,9]: box(world,Vector3(x+dx,2.5,z-7),Vector3(0.5,5,16),ground_color,true)
            box(world,Vector3(x,5.2,z-7),Vector3(19,0.4,17),Color("39474a"),true)
            box(world,Vector3(x,1,z-9),Vector3(6,2,1.8),Color("625949"),true)
        label3(p.name,Vector3(p.x,7,p.z))
    for n in Session.content.residents:
        var site: Dictionary={}
        for p in Session.content.settlements:
            if p.id==n.site: site=p
        if int(site.leg)!=leg: continue
        var pos:=Vector3(site.x-8,1.1,site.z+4)
        box(world,pos,Vector3(0.65,1.3,0.4),Color("6c7b6a"))
        box(world,pos+Vector3(0,0.95,0),Vector3(0.4,0.4,0.4),Color("ac9680"))
        add_target(n.id,n.name+" / "+n.role,pos,"npc")
    for p in Session.state.field:
        if int(p.leg)!=leg: continue
        var alive: bool=int(p.left)>0 if p.kind=="node" else not p.items.is_empty()
        if not alive: continue
        var pos:=Vector3(p.x,0.8,p.z)
        box(world,pos,Vector3(1.7,1.3,1.5),Color("7d6750") if p.kind=="container" else Color("81917f"))
        add_target(p.id,p.table+" salvage" if p.kind=="container" else p.resource+" deposit",pos,"field")
    var sites: Array=[]
    if leg==1:
        sites=[{"id":"camp","name":"MARA / CAMP","x":54,"y":2,"z":-94},{"id":"ev","name":"STRANDED EV","x":-85,"y":2,"z":-284},{"id":"solar","name":"SOLAR STORAGE","x":90,"y":2,"z":-413},{"id":"grid","name":"SUBSTATION","x":155,"y":2,"z":-730},{"id":"relay","name":"DRONE / RELAY","x":166,"y":15,"z":-778},{"id":"tower","name":"GHOST SIGNAL","x":0,"y":2,"z":-1435}]
    else: sites=Session.content.leg2 if leg==2 else Session.content.leg3
    for p in sites:
        var pos:=Vector3(p.x,p.y,p.z)
        box(world,pos+Vector3(0,-0.8,-3),Vector3(3,2,2),Color("437b80"),true)
        if p.y>5: box(world,Vector3(p.x,p.y/2,p.z-4),Vector3(1,p.y,1),Color("658580"),true)
        add_target(p.id,p.name,pos,"mission")
    if leg==2: box(world,Vector3(115,0.05,-2400),Vector3(22,0.06,600),Color("477f88"))
    if leg==3: box(world,Vector3(0,15,-4650),Vector3(45,30,20),Color("344b55"),true)

func add_target(id: String,title: String,pos: Vector3,kind: String) -> void:
    targets.append({"id":id,"title":title,"pos":pos,"kind":kind})
    if kind!="field": label3(title,pos+Vector3(0,2,0))

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
            KEY_M: map_panel()
            KEY_H: cycle_camera()
            KEY_1: command_drone("FOLLOW")
            KEY_2: command_drone("HOLD")
            KEY_3: command_drone("RETURN")
            KEY_T: transfer_power()
            KEY_G: power_panel()
            KEY_F5: save_now()
    if event is InputEventMouseMotion and not panel.visible:
        yaw-=event.relative.x*0.002
        pitch=clampf(pitch-event.relative.y*0.002,-1.2,1.2)

func _physics_process(delta: float) -> void:
    clock+=delta
    if panel.visible:
        loop_sound.volume_db=-80
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
        speed=move_toward(speed,forward*(5.0 if pedal else 25.0),delta*8)
        yaw-=side*delta*minf(1.5,absf(speed)*0.1)
        bike.rotation.y=yaw
        bike.velocity=-bike.basis.z*speed
        bike.velocity.y=-4
        bike.move_and_slide()
        if bike.get_slide_collision_count()>0: speed*=0.7
        if not pedal:
            Session.state.battery=maxf(0,Session.state.battery-absf(speed)*delta*0.0013*(1+Session.mass(Session.state.cargo)/80))
        pilot.position=bike.position+Vector3(2,0.2,0)
    elif mode=="foot":
        pilot.velocity=basis_*Vector3(side,0,-forward).normalized()*5.5
        pilot.velocity.y=-5
        pilot.move_and_slide()
    update_drone(delta,forward,side,basis_)
    trailer.position=bike.position+bike.basis.z*3.5-Vector3(0,0.5,0)
    trailer.rotation.y=bike.rotation.y
    generate(delta)
    update_camera(delta)
    if not mine_id.is_empty(): update_mining(delta)
    loop_sound.pitch_scale=0.7+(drone.velocity.length()/20 if mode=="drone" else absf(speed)/20)
    loop_sound.volume_db=linear_to_db(maxf(0.001,Session.volume*(0.08 if mode=="drone" else 0.045 if mode=="bike" else 0.005)))
    var near:=nearest()
    var link:=maxf(0,100.0-drone.position.distance_to(bike.position)/4.5)
    hud.text="GRIDRUNNER // GODOT NATIVE\nLEG %d  %s  %s\nBIKE %.2f / 2 kWh  RESERVE %.2f / 0.8 kWh  FUEL %.2f L\nDRONE %s  BAT %d%%  ALT %.1f m  LINK %d%%\n%s\n%s\nWASD / Mouse · F bike · Q drone · Space/Shift altitude · R scan · H view\n1 follow · 2 hold · 3 dock · I pack · G power · M map · F5 save · Esc menu" % [Session.state.leg,mode.to_upper(),profile().label,Session.state.battery,Session.state.reserve,Session.state.fuel,Session.state.drone_mode,int(Session.state.drone*100),drone.position.y,int(link),message,"E / "+near.title if not near.is_empty() else "Explore the road and settlements"]

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
    if Session.state.mode=="drone":
        desired=basis_*Vector3(side,0,-forward)*18
        desired.y=(float(Input.is_physical_key_pressed(KEY_SPACE))-float(Input.is_physical_key_pressed(KEY_SHIFT)))*7
    elif dm=="FOLLOW" or dm=="RETURN": desired=(home-drone.position).limit_length(1)*16
    drone.velocity=drone.velocity.move_toward(desired,delta*12)
    drone.move_and_slide()
    drone.position.y=clampf(drone.position.y,0.4,90)
    Session.state.drone=maxf(0,Session.state.drone-delta*(0.0005+drone.velocity.length()*0.000025))
    if drone.get_slide_collision_count()>0: Session.state.drone_hp=maxf(0,Session.state.drone_hp-delta*2)
    if dm=="RETURN" and drone.position.distance_to(home)<1.5:
        Session.state.drone_mode="DOCK"
        message="Drone docked"
    if Session.state.drone<=0:
        drone.velocity=Vector3(0,-1,0)
        Session.state.drone_mode="HOLD"
        if drone.position.y>0.5: drone.position.y-=delta
        message="Drone battery exhausted. Approach it to recover with Q."

func mount() -> void:
    if Session.state.mode=="drone": return
    if Session.state.mode=="bike": Session.state.mode="foot"; speed=0
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
    var anchor: Vector3=actor().position+Vector3(0,0.7 if Session.state.mode!="drone" else 0,0)
    var offset:=Vector3(float(p.get("side",0)),float(p.height),float(p.distance)-float(p.get("front",0)))
    var desired:=anchor+Basis(Vector3.UP,yaw)*offset
    var query:=PhysicsRayQueryParameters3D.create(anchor,desired,1)
    var hit:=get_world_3d().direct_space_state.intersect_ray(query) if offset.length()>0.1 else {}
    camera.position=hit.position.lerp(anchor,0.08) if not hit.is_empty() else desired
    camera.rotation=Vector3(pitch,yaw,0)
    if p.distance>0: camera.look_at(anchor+Basis.from_euler(Vector3(pitch,yaw,0))*Vector3(0,0,-12))
    if p.id=="overhead": camera.look_at(anchor)
    camera.fov=clampf(72+float(p.fov)+(absf(speed)*0.25 if Session.state.mode=="bike" else 0),45,105)
    pilot.visible=Session.state.mode=="foot" and p.distance>0
    bike.visible=Session.state.mode!="bike" or p.distance>0 or p.id=="bars"
    if Session.state.mode=="drone": drone.visible=p.distance>0

func nearest() -> Dictionary:
    var result: Dictionary={}
    var best:=8.0
    for t in targets:
        var d: float=actor().position.distance_to(t.pos)
        if d<best: best=d; result=t
    return result

func scan() -> void:
    if Session.state.drone<0.03 and Session.state.mode=="drone": return
    if Session.state.mode=="drone": Session.state.drone-=0.03
    var found:=0
    for t in targets:
        if actor().position.distance_to(t.pos)<160 and not t.id in Session.state.tags:
            Session.state.tags.append(t.id)
            found+=1
    message="Scan: %d new contacts recorded in M / Map" % found
    beep(700)

func interact() -> void:
    current_target=nearest()
    if current_target.is_empty(): return
    if current_target.kind=="mission": mission(current_target.id); return
    if Session.state.mode=="drone": message="Return to rider to handle supplies or talk"; return
    if current_target.kind=="npc": resident(current_target.id)
    else: field_panel(current_target.id)

func build_ui() -> void:
    var layer:=CanvasLayer.new()
    add_child(layer)
    hud=Label.new()
    hud.position=Vector2(20,20)
    hud.add_theme_color_override("font_color",Color("d3e5dc"))
    layer.add_child(hud)
    panel=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left=110
    panel.offset_right=-110
    panel.offset_top=80
    panel.offset_bottom=-60
    layer.add_child(panel)
    var scroll:=ScrollContainer.new()
    panel.add_child(scroll)
    rows=VBoxContainer.new()
    rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override("separation",10)
    scroll.add_child(rows)
    panel.hide()

func show_panel(title: String) -> void:
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    panel.show()
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    text(title)
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
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func menu() -> void:
    show_panel("GRIDRUNNER // EXPEDITION PAUSED")
    button("Inventory / craft",inventory)
    button("Map / discoveries",map_panel)
    button("Power trailer",power_panel)
    button("Save expedition",func(): save_now(); text(message))
    button("Load expedition",func():
        if Session.load_game(): restore_positions(); build_world(); close_panel()
        else: text("No valid native save found"))
    button("Camera view: "+str(profile().label),func(): cycle_camera(); menu())
    button("Audio: %d%%" % int(Session.volume*100),func(): Session.volume=fmod(Session.volume+0.2,1.2); menu())
    text("Controls: WASD / mouse. F mount. P pedal. Q launch/recall. Space/Shift drone altitude. 1 follow, 2 hold, 3 return. E use. R scan. H camera. I inventory. G power. M map. F5 save.\nNative save files are separate from browser saves.\nThe three-leg campaign route is available; this native port still uses procedural art.")
    button("Main menu",func(): save_now(); get_tree().change_scene_to_file("res://scenes/frontend.tscn"))

func inventory() -> void:
    show_panel("PACK / %.1f kg of 40 kg" % Session.mass(Session.state.inv))
    text(message)
    for id in Session.state.inv:
        if int(Session.state.inv[id])<=0: continue
        var item: Dictionary=Session.content.items[id]
        text("%s × %d" % [item.name,Session.state.inv[id]])
        if item.has("salvage"):
            button("Salvage "+str(item.name),func():
                if item.has("tool") and int(Session.state.inv.get(item.tool,0))<1: message="Requires "+str(item.tool)
                else: message=Session.transact({id:1},item.salvage)
                inventory())
        button("Store one "+str(item.name)+" in trailer",func():
            if actor().position.distance_to(trailer.position)>8: message="Approach trailer"
            elif Session.mass(Session.state.cargo)+float(item.mass)>60: message="Trailer cargo full"
            else: Session.state.inv[id]-=1; Session.state.cargo[id]=int(Session.state.cargo.get(id,0))+1
            inventory())
    for id in Session.state.cargo:
        if int(Session.state.cargo[id])<=0: continue
        button("Retrieve "+id+" (%d)" % Session.state.cargo[id],func():
            if actor().position.distance_to(trailer.position)<8:
                var error:=Session.transact({},{id:1})
                if error.is_empty(): Session.state.cargo[id]-=1
                else: message=error
            inventory())
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
            inventory())
    for r in [{"id":"engineer","name":"Engineer drone module","cost":{"wire":1,"electronics":1,"steel":1}},{"id":"controller","name":"Solar controller","cost":{"wire":2,"electronics":2}},{"id":"coupler","name":"Grid coupler","cost":{"wire":2,"electronics":1}}]:
        if not Session.state.flags.get(r.id,false): button(str(r.name)+" / "+str(r.cost),func():
            message=Session.transact(r.cost,{})
            if message.is_empty(): Session.state.flags[r.id]=true
            inventory())
    button("Recondition cells: 2 cells + 1 electronics → 0.44 kWh",func():
        if Session.state.battery<=1.56:
            message=Session.transact({"cells":2,"electronics":1},{})
            if message.is_empty(): Session.state.battery+=0.44
        inventory())

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
            if not f.get("mara",false): Session.transact({},{"steel":2,"wire":2,"electronics":2}); f.mara=true
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
            if not f.get(id,false): Session.transact({},{"wire":2,"electronics":2}); f[id]=true
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
        pilot.position=bike.position+Vector3(2,0,0)
        build_world(); save_now(); close_panel())

func save_now() -> void:
    Session.state.position=[pilot.position.x,pilot.position.y,pilot.position.z]
    Session.state.bike=[bike.position.x,bike.position.y,bike.position.z]
    Session.state.drone_position=[drone.position.x,drone.position.y,drone.position.z]
    Session.state.yaw=yaw; Session.state.pitch=pitch
    message="Expedition saved" if Session.save_game() else "Save failed"
    beep(800)

func restore_positions() -> void:
    var s: Dictionary=Session.state
    pilot.position=Vector3(s.position[0],s.position[1],s.position[2])
    bike.position=Vector3(s.bike[0],s.bike[1],s.bike[2])
    drone.position=Vector3(s.drone_position[0],s.drone_position[1],s.drone_position[2])
    yaw=s.yaw; pitch=s.pitch; speed=0

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
    sound.stream=wave(hz,0.12)
    sound.volume_db=linear_to_db(maxf(0.001,Session.volume*0.2))
    sound.play()
