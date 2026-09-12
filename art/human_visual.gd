class_name HumanVisual
extends RefCounted
# Shared head asset and modular clothing. Lightweight pivot animation, not a full skeletal rig.
static func make(parent: Node3D,pos: Vector3,mechanic: bool=false) -> Node3D:
    var n:=FieldKit.group(parent,pos);n.add_to_group("field_npcs")
    var cloth: String="canvas" if mechanic else "cloth"
    for x in [-.13,.13]:
        FieldKit.ellipsoid(n,Vector3(x,.11,-.065),Vector3(.2,.21,.35),"rubber")
        FieldKit.box(n,Vector3(x,.055,-.085),Vector3(.21,.07,.35),"dark")
        FieldKit.tube(n,Vector3(x,.23,0),Vector3(x,.72,.015),.105,cloth,.135)
        for j in range(3):FieldKit.tube(n,Vector3(x-.07,.18,-.13+j*.035),Vector3(x+.07,.18,-.13+j*.035),.007,"canvas")
    FieldKit.ellipsoid(n,Vector3(0,.8,0),Vector3(.42,.30,.29),cloth)
    FieldKit.ellipsoid(n,Vector3(0,1.14,0),Vector3(.53,.63,.32),cloth)
    FieldKit.box(n,Vector3(0,.87,-.025),Vector3(.44,.07,.3),"dark")
    FieldKit.box(n,Vector3(0,.88,-.19),Vector3(.08,.065,.025),"steel")
    FieldKit.tube(n,Vector3(0,1.36,0),Vector3(0,1.56,0),.073,"skin")
    var head:=MeshInstance3D.new();head.name="Head";head.mesh=load("res://assets/humans/field_head.obj");head.material_override=FieldKit.mat("skin");head.position.y=1.51;n.add_child(head)
    # Work cap conceals the untextured scalp; geometric ears, nose and lips come from the source mesh.
    FieldKit.ellipsoid(n,Vector3(0,1.755,.013),Vector3(.24,.13,.25),"olive" if mechanic else "dark")
    if mechanic:FieldKit.box(n,Vector3(0,1.725,-.12),Vector3(.24,.028,.18),"olive")
    for x in [-.049,.049]:
        var eye:=FieldKit.ellipsoid(n,Vector3(x,1.654,-.164),Vector3(.031,.013,.012),"dark")
        eye.name="EyeL" if x<0 else "EyeR"
        var brow:=FieldKit.tube(n,Vector3(x-.019,1.677,-.166),Vector3(x+.019,1.681,-.166),.007,"dark")
        brow.name="BrowL" if x<0 else "BrowR"
    for sign_ in [-1,1]:
        var arm:=Node3D.new();arm.name="ArmL" if sign_<0 else "ArmR";arm.position=Vector3(sign_*.25,1.37,0);n.add_child(arm)
        FieldKit.tube(arm,Vector3.ZERO,Vector3(sign_*.06,-.27,0),.10,cloth,.12)
        FieldKit.tube(arm,Vector3(sign_*.06,-.27,0),Vector3(sign_*.045,-.49,-.08),.075,cloth,.09)
        FieldKit.ellipsoid(arm,Vector3(sign_*.045,-.53,-.09),Vector3(.10,.16,.085),"dark")
        FieldKit.box(n,Vector3(sign_*.12,1.2,-.169),Vector3(.16,.17,.025),"canvas")
        FieldKit.tube(n,Vector3(sign_*.16,1.39,-.09),Vector3(sign_*.18,.96,-.15),.023,"dark")
    FieldKit.box(n,Vector3(0,1.16,.20),Vector3(.36,.44,.17),"canvas")
    FieldKit.tube(n,Vector3(0,.96,-.172),Vector3(0,1.4,-.145),.008,"steel")
    if mechanic:
        FieldKit.box(n,Vector3(0,1.03,-.20),Vector3(.34,.48,.028),"rust")
        FieldKit.tube(n,Vector3(.19,.77,-.19),Vector3(.19,1.02,-.19),.02,"steel")
    return n
