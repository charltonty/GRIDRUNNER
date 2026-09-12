extends Node

var game
var selected_store:="backpack"
var filter:="All"
var sort_weight:=false
var list: ItemList
var inspect_rows: VBoxContainer
var ids: Array=[]
var selection:=""
var loot_nodes:={}
var spotlight: SpotLight3D
var module_visual: Node3D
var status:=""
var landing_offset:=0.0
var opening_data: Array=[]
const STATIONS={"workbench":Vector3(49.5,1,-100),"battery":Vector3(59,1,-102.2),"generator":Vector3(59,1,-100),"world":Vector3(12,0.8,-180)}

func _ready() -> void:
    game=get_parent()
    FieldStorage.initialize(Session.state)
    opening_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/opening_items.json"))
    spotlight=SpotLight3D.new();spotlight.spot_range=32;spotlight.spot_angle=30;spotlight.light_energy=3
    spotlight.position=Vector3(0,-0.2,-0.3);game.drone.add_child(spotlight)
    rebuild_modules()

func nearby(store: String) -> bool:
    if store=="backpack":return true
    if Session.state.mode=="drone":return false
    var pos: Vector3=game.bike.position if store=="bike" or store=="drone" else game.trailer.position if store=="trailer" else STATIONS.get(store,Vector3(9999,0,0))
    return game.actor().position.distance_to(pos)<5 and (store!="drone" or Session.state.drone_mode=="DOCK") and (store in ["bike","drone","trailer"] or Session.state.leg==1)

func backpack(store: String="backpack") -> void:
    selected_store=store if nearby(store) else "backpack"
    Session.state.slice02.opening.pack=true
    game.show_panel("GRIDRUNNER  /  FIELD PACK     •     EQUIPMENT REGISTER / 02")
    var nav:=HBoxContainer.new();game.rows.add_child(nav)
    for id in FieldStorage.LIMITS:
        var b:=Button.new();b.text=id.capitalize();b.disabled=not nearby(id);nav.add_child(b)
        b.pressed.connect(func():backpack(id))
    var inv:=FieldStorage.contents(Session.state,selected_store)
    game.text("%s  /  %.2f / %.0f kg      HAND: %s      %s" % [selected_store.to_upper(),Session.mass(inv),FieldStorage.LIMITS[selected_store],Session.state.slice02.equipped.get("hand","empty"),status])
    var controls:=HBoxContainer.new();game.rows.add_child(controls)
    var categories:=OptionButton.new();categories.add_theme_constant_override("icon_max_width",18);controls.add_child(categories)
    for c in ["All","electrical","mechanical","tool","material","survival","vehicle","fuel","quest","junk","energy"]:
        var symbol: String={"material":"raw_material","vehicle":"bike","junk":"damaged","energy":"charge","quest":"quest_signal","survival":"food"}.get(c,c)
        if ResourceLoader.exists("res://assets/icons/ui/"+symbol+".svg"):categories.add_icon_item(load("res://assets/icons/ui/"+symbol+".svg"),c)
        else:categories.add_item(c)
        if c==filter:categories.selected=categories.item_count-1
    categories.item_selected.connect(func(i):filter=categories.get_item_text(i);backpack(selected_store))
    var sort:=Button.new();sort.text="Sort: "+("mass" if sort_weight else "name");controls.add_child(sort)
    sort.pressed.connect(func():sort_weight=not sort_weight;backpack(selected_store))
    var body:=HBoxContainer.new();body.custom_minimum_size.y=310;game.rows.add_child(body)
    list=ItemList.new();list.custom_minimum_size=Vector2(440,310);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    list.max_text_lines=2
    list.fixed_icon_size=Vector2i(58,58);list.add_theme_constant_override("v_separation",8);body.add_child(list)
    inspect_rows=VBoxContainer.new();inspect_rows.custom_minimum_size.x=340;inspect_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(inspect_rows)
    ids=[]
    for id in inv:
        if int(inv[id])>0 and (filter=="All" or Session.content.items[id].category==filter):ids.append(id)
    ids.sort_custom(func(a,b):return float(Session.content.items[a].mass)>float(Session.content.items[b].mass) if sort_weight else str(Session.content.items[a].name)<str(Session.content.items[b].name))
    for id in ids:
        var item: Dictionary=Session.content.items[id]
        var tex: Texture2D=load(item.icon) if ResourceLoader.exists(item.icon) else null
        list.add_item("%s  ×%d  |  %.2f kg  /  %s" % [item.name,inv[id],float(item.mass)*int(inv[id]),item.category],tex)
    list.item_selected.connect(func(i):selection=ids[i];inspect(selection))
    if ids.size()>0:
        var index:=maxi(0,ids.find(selection));list.select(index);selection=ids[index];inspect(selection)
    else:detail("EMPTY / No items in this category.")
    game.button("Fabrication / salvage recipes",game.crafting)
    game.button("SCOUT-01 / equipment bay",module_panel)

func detail(value: String) -> void:
    var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inspect_rows.add_child(label)
func action(title: String,callback: Callable) -> void:
    var b:=Button.new();b.text=title;b.custom_minimum_size.y=32;inspect_rows.add_child(b);b.pressed.connect(callback)
func inspect(id: String) -> void:
    for child in inspect_rows.get_children():inspect_rows.remove_child(child);child.queue_free()
    var item: Dictionary=Session.content.items[id]
    detail(str(item.name).to_upper()+"\n"+str(item.description))
    detail("%.2f kg each  •  %s\nCondition %d%%  •  %s  •  Value %d" % [item.mass,item.category,item.condition,item.get("rarity","common"),item.value])
    var specs:=""
    if item.has("voltage"):specs+="%.1f V   " % item.voltage
    if item.has("energyKWh"):specs+="%.2f kWh   " % item.energyKWh
    if item.has("powerKW"):specs+="%.2f kW   " % item.powerKW
    if not specs.is_empty():detail(specs)
    var dest:=OptionButton.new();inspect_rows.add_child(dest)
    var stores: Array=[]
    for store in FieldStorage.LIMITS:
        if store!=selected_store and nearby(store):stores.append(store);dest.add_item(store.capitalize())
    if stores.size()>0:
        action("Transfer one",func():
            if not nearby(selected_store) or not nearby(stores[dest.selected]):status="Approach container"
            else:status=FieldStorage.transfer(Session.state,Session.content.items,selected_store,stores[dest.selected],id)
            if status.is_empty():status="Transferred "+str(item.name);sfx("container")
            backpack(selected_store))
    if selected_store!="backpack":return
    if item.has("heal"):
        action("Use",func():
            if Session.state.hp>=100:status="Health already full"
            elif Session.transact({id:1},{}).is_empty():Session.state.hp=minf(100,Session.state.hp+float(item.heal));status="Used "+str(item.name);sfx("pickup")
            backpack())
    if item.category=="tool":action("Equip in hand",func():Session.state.slice02.equipped.hand=id;backpack())
    if item.has("salvage"):
        action("Disassemble → "+str(item.salvage),func():
            if item.has("tool") and Session.state.inv.get(item.tool,0)<1:status="Requires "+str(item.tool)
            else:status=Session.transact({id:1},item.salvage)
            backpack())
    if item.has("liters"):
        action("Pour into generator",func():
            if not nearby("trailer"):status="Approach trailer"
            elif Session.state.fuel+float(item.liters)>5:status="Tank capacity 5 L"
            else:
                status=Session.transact({id:1},{})
                if status.is_empty():Session.state.fuel+=float(item.liters);sfx("container")
            backpack())

func module_panel() -> void:
    game.show_panel("SCOUT-01  /  MODULAR EQUIPMENT BAY")
    game.text("Two slots · equipment provided at the field station\nDock at the bike to configure. Marker rounds: %d / 3\nFlight draw: %.2f kW · cargo %.2f / 2 kg\n%s" % [Session.state.slice02.payload,FieldStorage.draw_kw(Session.state,Session.content.items),Session.mass(FieldStorage.contents(Session.state,"drone")),status])
    for id in FieldStorage.MODULES:
        var d: Dictionary=FieldStorage.MODULES[id]
        game.button(("REMOVE " if id in Session.state.slice02.modules else "INSTALL ")+id.to_upper()+"  /  %.2f kg · %.2f kW" % [d.mass,d.draw],func():
            status=FieldStorage.equip(Session.state,id) if nearby("drone") else "Approach the docked aircraft"
            rebuild_modules();module_panel())
    game.text("Scanner: R records contacts. Spotlight: L toggles light.\nMarker: X designates the aimed surface, consuming a marker.\nCargo: E retrieves loose salvage within 3 m into a 2 kg tray.\nUtility: X operates a nearby elevated mission switch.\nPayload and module mass increase flight power; two slots force a choice.")
    game.button("Rearm markers / 1 steel + 1 plastic → 3",func():
        if not nearby("workbench") or Session.state.drone_mode!="DOCK":status="Dock aircraft and approach camp workbench"
        elif Session.state.slice02.payload==3:status="Already rearmed"
        else:
            status=Session.transact({"steel":1,"plastic":1},{})
            if status.is_empty():Session.state.slice02.payload=3;sfx("module")
        module_panel())
    game.button("Open drone cargo",func():backpack("drone"))

func rebuild_modules() -> void:
    if is_instance_valid(module_visual):module_visual.queue_free()
    module_visual=Node3D.new();game.drone.add_child(module_visual)
    var i:=0
    for id in Session.state.slice02.modules:
        var item_id: String={"scanner":"sensor","marker":"marker_pod","cargo":"cargo_hook","utility":"utility_module","spotlight":"spotlight"}[id]
        var n:=ItemVisual.make(module_visual,item_id,Session.content.items[item_id]);n.scale=Vector3.ONE*0.7;n.position=Vector3(-0.14+i*0.28,-0.36,0.05);i+=1
    spotlight.visible=false

func payload_action() -> void:
    if Session.state.mode!="drone":return
    if Session.state.slice02.cooldown>0:game.message="Payload cooling down";return
    if "utility" in Session.state.slice02.modules:
        var t: Dictionary=game.nearest()
        if t.get("kind","")=="mission" and t.id in ["relay","l2intake","l3security"]:
            game.mission(t.id);Session.state.slice02.cooldown=2;sfx("module");return
    if not "marker" in Session.state.slice02.modules:game.message="Install marker or utility module";return
    if Session.state.slice02.payload<=0:game.message="No markers. Rearm at camp workbench.";return
    var q:=PhysicsRayQueryParameters3D.create(game.camera.global_position,game.camera.global_position-game.camera.global_basis.z*100,1)
    var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(q)
    if hit.is_empty():game.message="Aim at a surface within 100 m";return
    Session.state.slice02.payload-=1;Session.state.slice02.cooldown=1.5
    var marker_id:="marker_%d" % Session.state.tags.size()
    game.add_target(marker_id,"SCOUT / DESIGNATED",hit.position,"marker");Session.state.tags.append(marker_id)
    var marker:=FieldKit.ellipsoid(game.world,hit.position+Vector3.UP*.08,Vector3(.16,.16,.16),"amber")
    marker.visibility_range_end=100
    game.message="Surface designated. %d markers left." % Session.state.slice02.payload;sfx("module")

func pickup(uid: String) -> bool:
    var record: Dictionary={}
    for r in opening_data:
        if r.uid==uid:record=r;break
    if record.is_empty() or uid in Session.state.slice02.picked:return false
    var pos:=Vector3(record.pos[0],record.pos[1],record.pos[2])
    if game.actor().position.distance_to(pos)>3:return false
    var ray:=PhysicsRayQueryParameters3D.create(game.actor().position+Vector3.UP*.4,pos+Vector3.UP*.15,1)
    if not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return false
    var id: String=record.item;var n:=int(record.get("count",1))
    if Session.state.mode=="drone":
        if not "cargo" in Session.state.slice02.modules:game.message="Install a cargo tray to retrieve objects";return false
        var dest:=FieldStorage.contents(Session.state,"drone")
        if Session.mass(dest)+float(Session.content.items[id].mass)*n>2:game.message="Payload too heavy";return false
        if int(dest.get(id,0))+n>int(Session.content.items[id].stack):game.message="Payload stack full";return false
        dest[id]=int(dest.get(id,0))+n
    else:
        var error:=Session.transact({},{id:n})
        if not error.is_empty():game.message=error;return false
    Session.state.slice02.picked.append(uid);Session.state.slice02.opening.salvage=true
    if is_instance_valid(loot_nodes.get(uid)):loot_nodes[uid].queue_free()
    game.targets=game.targets.filter(func(t):return t.id!=uid)
    game.message="+ %s ×%d  /  %.2f kg" % [Session.content.items[id].name,n,float(Session.content.items[id].mass)*n]
    sfx("pickup");return true

func dress() -> void:
    loot_nodes.clear()
    if Session.state.leg!=1:return
    var decor:=Node3D.new();decor.name="OpeningCampDecor";game.world.add_child(decor)
    OpeningWorld.build(decor)
    FieldKit.batch_static(decor)
    for key in STATIONS:game.add_target("storage_"+key,key.capitalize()+" / storage",STATIONS[key],"storage")
    game.add_target("drone_bay","SCOUT-01 / EQUIPMENT BAY",Vector3(50,1,-98),"modules")
    for r in opening_data:
        if r.uid in Session.state.slice02.picked:continue
        var id: String=r.item
        var n:=ItemVisual.make(game.world,id,Session.content.items[id]);n.position=Vector3(r.pos[0],r.pos[1],r.pos[2]);n.rotation.y=float(r.get("yaw",0))
        loot_nodes[r.uid]=n;n.add_to_group("physical_loot")
        game.add_target(r.uid,str(Session.content.items[id].name)+" / collect",n.position+Vector3.UP*.1,"pickup")

func sfx(id: String) -> void:
    var p:=AudioStreamPlayer.new();p.stream=load("res://assets/audio/"+id+".wav");p.volume_db=linear_to_db(maxf(.0001,Session.volume*.3));add_child(p);p.finished.connect(p.queue_free);p.play()
func tick(delta: float) -> void:
    Session.state.slice02.cooldown=maxf(0,Session.state.slice02.cooldown-delta)
    landing_offset=move_toward(landing_offset,0,delta*.8)
    spotlight.rotation=Vector3(game.pitch,game.yaw-game.drone.rotation.y,0)
    if Session.state.drone_mode=="DOCK":spotlight.visible=false
    if Session.state.mode=="drone":Session.state.slice02.opening.drone=true
    if Session.state.mode=="bike" and game.bike.position.z < -135:Session.state.slice02.opening.ride=true
    if Session.state.leg==1 and game.actor().position.distance_to(Vector3(12,1,-180))<12 and not Session.state.slice02.opening.get("signal",false):
        Session.state.slice02.opening.signal=true;game.message="UNKNOWN CARRIER / eleven seconds, then silence. Riggs marked the substation on your route.";sfx("signal")
