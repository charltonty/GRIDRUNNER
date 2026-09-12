class_name AssetLibrary
extends RefCounted
static var scenes: Dictionary={}
static var records: Dictionary={}
const ROOT="res://assets/packs/"
const BUILDINGS=[
 {"id":"GR05_01_UtilityHouse","pos":Vector3(18,0,-199),"yaw":0.0,"half":Vector2(5,8),"title":"Creek service office","depth":9.0},
 {"id":"GR05_02_RoadsideStore","pos":Vector3(-23,0,-154),"yaw":PI/2,"half":Vector2(8,8),"title":"Roadside supply store","depth":9.0},
 {"id":"GR05_03_TexasHouse","pos":Vector3(105,0,-269),"yaw":0.0,"half":Vector2(9,10),"title":"Hill Country house","depth":12.0},
 {"id":"GR05_04_Maintenance","pos":Vector3(48,0,-236),"yaw":0.0,"half":Vector2(10,8),"title":"Maintenance workshop","depth":9.0},
 {"id":"GR05_05_CreekPump","pos":Vector3(101,0,-208),"yaw":0.0,"half":Vector2(8,8),"title":"Creek pump station","depth":9.0}]
const PATHS=[
 [Vector3(16,0,-180),Vector3(18,0,-192)],
 [Vector3(0,0,-154),Vector3(-16,0,-154)],
 [Vector3(53,0,-174),Vector3(52,0,-215),Vector3(48,0,-229)],
 [Vector3(84,0,-194),Vector3(101,0,-201)],
 [Vector3(101,0,-215),Vector3(115,0,-234),Vector3(115,0,-252),Vector3(105,0,-260)]]
static func clear_area(pos: Vector3) -> bool:
    for b in BUILDINGS:
        if absf(pos.x-b.pos.x)<b.half.x+2 and absf(pos.z-b.pos.z)<b.half.y+2:return true
    for path in PATHS:
        for i in range(path.size()-1):
            var a: Vector3=path[i];var v: Vector3=path[i+1]-a;var flat:=Vector3(pos.x,0,pos.z)
            if flat.distance_to(a+v*clampf((flat-a).dot(v)/v.length_squared(),0,1))<2.8:return true
    return false
static func info(id: String) -> Dictionary:
    if not records.has(id):records[id]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+id+".json"))
    return records[id]
static func make(parent: Node3D,id: String,pos: Vector3=Vector3.ZERO,yaw: float=0,scale_: float=1) -> Node3D:
    if not scenes.has(id):scenes[id]=load(ROOT+id+".glb")
    var n: Node3D=scenes[id].instantiate();n.name=id;n.add_to_group("pack_assets");n.set_meta("pack_id",id)
    parent.add_child(n);n.position=pos;n.rotation.y=yaw;n.scale=Vector3.ONE*scale_
    var pending: Array[Node]=[n]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for c in node.get_children():pending.append(c)
        if node is GeometryInstance3D:
            node.visibility_range_end=350 if id.begins_with("GR05") else 120;node.visibility_range_end_margin=12
    return n
static func solid_box(parent: Node3D,pos: Vector3,size_: Vector3,surface: String="metal") -> void:
    var b:=StaticBody3D.new();b.set_meta("surface",surface);parent.add_child(b);b.position=pos
    var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size_;c.shape=shape;b.add_child(c)
static func structural(parent: Node3D,values: Array,surface: String="concrete") -> void:
    if values.is_empty():return
    var faces:=PackedVector3Array()
    for i in range(0,values.size(),3):faces.append(Vector3(values[i],values[i+1],values[i+2]))
    var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
    var b:=StaticBody3D.new();b.set_meta("surface",surface);parent.add_child(b)
    var c:=CollisionShape3D.new();c.shape=shape;b.add_child(c)
const ITEMS={"multimeter":"GR_DigitalMultimeter_04","drill":"GR_CordlessDrill_04","pliers":"GR_CombinationPliers_04","screwdriver":"GR_ScrewdriverSet_04","wrench":"GR_RingSpannerSet_04","motor":"GR_SalvagedMotor_04","alternator":"GR_Alternator_04","pump":"GR_UtilityPump_04","relay":"GR_DINContactor_04","fuse":"GR_FuseTray_04","electronics":"GR_ControlBoard_04","copper":"GR_CopperTubeCoil_04","solder":"GR_TapeSolder_04","tire":"GR_SpareTires_04","battery_module":"GR_BatteryCase_02","radio":"GR_FieldRadio_02","repair_kit":"GR_SocketRail_04"}
