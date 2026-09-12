class_name OpeningWorld
extends RefCounted

static func prop(p: Node3D,id: String,pos: Vector3,scale_: float=3,material: String="canvas",yaw: float=0) -> Node3D:
    var n: Node3D=load("res://assets/kenney/"+id+".glb").instantiate()
    p.add_child(n);n.position=pos;n.scale=Vector3.ONE*scale_;n.rotation.y=yaw
    var pending: Array[Node]=[n]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():pending.append(child)
        if node is MeshInstance3D:
            node.material_override=FieldKit.mat(material);node.visibility_range_end=130
    return n

static func build(p: Node3D) -> void:
    # Camp sleeping area, water station and repair benches. Keep spawn and exit clear.
    AssetLibrary.make(p,"GR_TarpShelter_02",Vector3(63,0,-107),PI/2)
    AssetLibrary.make(p,"GR_CampCot_02",Vector3(63,0,-107),PI/2)
    prop(p,"bedroll-packed",Vector3(60.5,0.04,-106),3,"canvas")
    prop(p,"bucket",Vector3(62,0,-96),2.2,"steel")
    prop(p,"box-large-open",Vector3(52.5,0,-90),2,"wood")
    prop(p,"tool-shovel",Vector3(59.5,0,-104),4,"steel",.4)
    prop(p,"resource-planks",Vector3(44,0,-104),4,"wood")
    FieldKit.workbench(p,Vector3(50.5,0,-98))
    FieldKit.text(p,"SCOUT-01 / SERVICE BAY",Vector3(50.5,1.45,-98.4),.005)
    for x in [45.0,46.3]:
        for y in [.3,.95,1.6]:
            FieldKit.box(p,Vector3(x,y,-109),Vector3(1.15,.07,.6),"wood")
            prop(p,"box-open",Vector3(x,y+.04,-109),1.4,"olive")
        for dx in [-.53,.53]:FieldKit.tube(p,Vector3(x+dx,0,-109),Vector3(x+dx,2,-109),.03,"steel")
    for i in range(8):
        var item_id: String=["charger","inverter","battery_module","drill","pliers","relay","capacitor","repair_kit"][i]
        var item: Node3D=ItemVisual.make(p,item_id,Session.content.items[item_id]);item.position=Vector3(45+(i%4)*.36,.4+floor(i/4.0)*.65,-109)
    FieldKit.cable(p,Vector3(49,1.03,-100),Vector3(59,.08,-102),.08)
    FieldKit.cable(p,Vector3(50,.08,-98),Vector3(59,.08,-100),0)
    # Traversal pocket: low edging, a jumpable broken barrier, and a footpath.
    FieldKit.box(p,Vector3(40,.12,-93),Vector3(3,.24,.35),"rock",true)
    FieldKit.box(p,Vector3(39,.33,-95),Vector3(2.5,.66,.3),"wood",true)
    prop(p,"metal-panel-screws",Vector3(39,0,-98),3,"rust",.2)
    FieldKit.text(p,"CHECK BOOTS / CHECK PACK",Vector3(40,1.5,-95.1),.004)
    # Authored roadside service pocket: low culvert channel, cabinet, service table.
    FieldKit.box(p,Vector3(12,.12,-180),Vector3(8,.24,10),"rock",true)
    FieldKit.box(p,Vector3(12,.77,-180),Vector3(2,.14,.7),"wood",true)
    for x in [11.2,12.8]:FieldKit.tube(p,Vector3(x,.25,-180),Vector3(x,.7,-180),.05,"steel")
    FieldKit.cabinet(p,Vector3(14,.24,-182))
    FieldKit.text(p,"BLACK CREEK / SERVICE 04\nCARRIER DETECTED",Vector3(12,2,-183.5),.007)
    for z in [-170,-190]:
        FieldKit.box(p,Vector3(9,.3,z),Vector3(5,.6,.5),"rock",true)
        FieldKit.tube(p,Vector3(9,.35,z-.28),Vector3(9,.35,z+.28),.22,"dark")
    for i in range(13):
        var z:=-130-i*13.0
        FieldKit.tube(p,Vector3(-11,0,z),Vector3(-11,1.25,z),.05,"wood")
        if i%5!=3:
            for y in [.45,.9]:FieldKit.cable(p,Vector3(-11,y,z),Vector3(-11,y,z-13),.06)
    for i in range(6):
        prop(p,"rock-flat",Vector3(8+i*.45,0,-171-i*.9),1.2,"rock",i*.7)
    prop(p,"box-large-open",Vector3(-6.5,0,-155),2,"steel")
    prop(p,"tree-log-small",Vector3(-9,0,-156),3,"wood",PI/2)
    # Grouped rock shelves and scrub follow drainage rather than a uniform grid.
    var rng:=RandomNumberGenerator.new();rng.seed=202
    for cluster in [Vector3(-18,0,-160),Vector3(18,0,-210),Vector3(-24,0,-255),Vector3(35,0,-300),Vector3(72,0,-400)]:
        for i in range(7):
            prop(p,"rock-"+["a","b","c"][i%3],cluster+Vector3(rng.randf_range(-5,5),0,rng.randf_range(-7,7)),rng.randf_range(1.2,3.4),"rock",rng.randf()*TAU)
    for i in range(9):
        var z:=-120-i*31.0
        prop(p,"metal-panel-screws",Vector3(21,.04,z),1.3,"rust",i*.8)
        prop(p,"resource-planks",Vector3(21.7,.02,z-2),1.4,"wood",i*.4)
    FieldKit.text(p,"MILEPOST REPAIR  ←\nSUBSTATION  ↑",Vector3(5,2.3,-143),.009)
    FieldKit.tube(p,Vector3(5,0,-143.1),Vector3(5,2.7,-143.1),.04,"steel")
