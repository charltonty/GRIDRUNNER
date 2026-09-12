extends RefCounted
var game
var doors: Dictionary={}
const CACHES={
 "office":{"pos":Vector3(20,.9,-201.7),"title":"Office stores / electrical spares","reward":{"wire":2,"fuse":1}},
 "store":{"pos":Vector3(-25,.9,-156.5),"title":"Store shelf / emergency supplies","reward":{"water":2,"bandage":1}},
 "house":{"pos":Vector3(102,4.2,-271),"title":"Upstairs kit / former occupant","reward":{"cells":1,"electronics":1}},
 "workshop":{"pos":Vector3(45,.9,-238),"title":"Workshop bench / service parts","reward":{"steel":2,"wire":1}},
 "pump":{"pos":Vector3(102,.9,-210.5),"title":"Pump crew locker / reserve fuel","reward":{"fuel":1}}}
func build(g) -> void:
    game=g;doors.clear()
    if Session.state.leg!=1:return
    var root:=Node3D.new();root.name="IntegratedPackWorld";game.world.add_child(root)
    for b in AssetLibrary.BUILDINGS:
        var n:=AssetLibrary.make(root,b.id,b.pos,b.yaw);var data:=AssetLibrary.info(b.id)
        AssetLibrary.structural(n,data.collision.get("Static",[]))
        for box in data.get("floor_boxes",[]):
            AssetLibrary.solid_box(n,Vector3(box.center[0],box.center[1],box.center[2]),Vector3(box.size[0],box.size[1],box.size[2]),"concrete")
        if "TexasHouse" in b.id:
            AssetLibrary.structural(n,[3.82,.2,3,5.02,.2,3,5.02,3.4,-2.6,3.82,.2,3,5.02,3.4,-2.6,3.82,3.4,-2.6],"wood")
        for d in data.asset.doors:
            var mesh: Node3D=n.find_child(d.name,true,false)
            if mesh==null:continue
            AssetLibrary.structural(mesh,data.collision.get(d.name,[]),"wood")
            if not d.walk_door:continue
            var id: String=b.id+"/"+d.name
            var opened: bool=Session.state.polish.gates.get(id,absf(d.angle)>.2)
            mesh.rotation.y=(deg_to_rad(float(d.open)) if opened else 0.0)-float(d.angle)
            doors[id]={"node":mesh,"data":d,"opened":opened}
            game.add_target(id,"Door / "+("release latch" if d.locked else "open or close"),mesh.global_position+Vector3.UP,"architecture")
        lamp(n,Vector3(0,2.6,0),Color("ffd4a0"),1.5,7)
        if "TexasHouse" in b.id:lamp(n,Vector3(0,5.4,0),Color("a8c9d0"),1.1,7)
        lamp(n,Vector3(0,2.4,b.depth/2+.2),Color("ffc578"),1.5,5)
    for path in AssetLibrary.PATHS:load("res://world/authored_opening.gd").ribbon(root,path,2.5,"gravel")
    for id in CACHES:
        var c: Dictionary=CACHES[id];AssetLibrary.make(root,"GR_FieldStorageCase_02",c.pos-Vector3.UP*.65)
        game.add_target("cache/"+id,c.title,c.pos,"architecture")
    var placements=[
 ["GR_DroneHardCase_02",Vector3(50.6,1.04,-98)], ["GR_FieldRadio_02",Vector3(55,.85,-109)],
 ["GR_BikeRepairStand_02",Vector3(57,0,-105)], ["GR_WaterFilter_02",Vector3(63,0,-95)],
 ["GR_RainCollector_02",Vector3(65,0,-111)], ["GR_CampStove_02",Vector3(62,.1,-103)],
 ["GR_SupplyLocker_02",Vector3(44,0,-109)], ["GR_ChargingStation_02",Vector3(59,0,-104)],
 ["GR_Toolboard_02",Vector3(49,1,-111)], ["GR_ExtensionReel_02",Vector3(59.5,0,-101)],
 ["GR_SolderStation_04",Vector3(49.7,1.04,-100)], ["GR_ControlBoard_04",Vector3(48.8,1.04,-100)],
 ["GR_FastenerPot_04",Vector3(51.3,1.04,-98)], ["GR_WorkLight_01",Vector3(48,0,-97)],
 ["GR_CableSpool_01",Vector3(78,0,-153)], ["GR_SalvagedMotor_04",Vector3(77,.98,-152)],
 ["GR_UtilityPump_04",Vector3(99,.2,-208)], ["GR_Switchgear_01",Vector3(99,.2,-211)],
 ["GR_BreakerPanel_01",Vector3(20,.2,-200)], ["GR_CreekSign_03",Vector3(8,0,-143)],
 ["GR_TrailMarker_03",Vector3(85,0,-195)], ["GR_FoldingBarricade_03",Vector3(8,0,-166)],
 ["GR_ConcreteCulvert_03",Vector3(90,0,-220)], ["GR_DrainageGrate_03",Vector3(-12,.03,-158)],
 ["GR_ChainlinkPanel_03",Vector3(37,0,-221)], ["GR_Guardrail_03",Vector3(-8,0,-171)],
 ["GR_ConeSet_03",Vector3(9,0,-177)], ["GR_AccessHatch_03",Vector3(96,.03,-205)],
 ["GR_SpareTires_04",Vector3(43,.2,-239)], ["GR_BicycleWheel_04",Vector3(44,.2,-238)],
 ["GR_Alternator_04",Vector3(46,.2,-239)]]
    for row in placements:AssetLibrary.make(root,row[0],row[1])
    lamp(root,Vector3(48,2,-97),Color("ffd29c"),1.3,6)
    lamp(root,Vector3(77,2,-152),Color("a6ccd4"),1.1,6)
func lamp(p: Node3D,pos: Vector3,color_: Color,energy: float,range_: float) -> void:
    var l:=OmniLight3D.new();l.position=pos;l.light_color=color_;l.light_energy=energy;l.omni_range=range_;l.omni_attenuation=1.4;l.distance_fade_enabled=true;l.distance_fade_begin=70;l.distance_fade_length=15;p.add_child(l)
func interact(id: String) -> void:
    if Session.state.mode!="foot":game.message="Approach on foot to handle doors and supplies.";return
    if id.begins_with("cache/"):
        var key:=id.trim_prefix("cache/");var stamp:="architecture/"+key
        if stamp in Session.state.polish.discoveries:game.message="Already searched.";return
        var error:=Session.transact({},CACHES[key].reward)
        if not error.is_empty():game.message=error;return
        Session.state.polish.discoveries.append(stamp);game.message="Recovered / "+str(CACHES[key].reward);game.slice02.sfx("pickup");return
    if not doors.has(id):return
    var d: Dictionary=doors[id]
    if d.data.locked and not Session.state.polish.gates.get(id+"/unlatched",false):
        if Session.state.inv.get("screwdriver",0)<1:game.message="Seized service latch / needs a screwdriver.";return
        Session.state.polish.gates[id+"/unlatched"]=true
    if d.opened and game.pilot.position.distance_to(d.node.global_position+Vector3.UP)<1.45:
        game.message="Step back from the door before closing it.";return
    d.opened=not d.opened;d.node.rotation.y=(deg_to_rad(float(d.data.open)) if d.opened else 0.0)-float(d.data.angle)
    Session.state.polish.gates[id]=d.opened;game.message="Door opened." if d.opened else "Door closed.";game.slice02.sfx("container")
