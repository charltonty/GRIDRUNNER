class_name ItemVisual
extends RefCounted

static func make(parent: Node3D,id: String,item: Dictionary) -> Node3D:
    var n:=FieldKit.group(parent,Vector3.ZERO)
    n.name="Item_"+id
    if AssetLibrary.ITEMS.has(id):
        AssetLibrary.make(n,AssetLibrary.ITEMS[id]);return n
    var f: String=item.get("family","device")
    match f:
        "coil":
            for i in range(4):
                var ring:=FieldKit.ring(n,Vector3(0,0.03+i*0.025,0),0.2,0.03,"rubber" if id!="copper" else "rust");ring.rotation=Vector3.ZERO
            FieldKit.tube(n,Vector3(0.14,0.08,0.12),Vector3(0.33,0.08,0.17),0.018,"steel")
        "battery":
            FieldKit.box(n,Vector3(0,0.14,0),Vector3(0.24,0.28,0.17),"olive")
            for x in [-0.07,0.07]:FieldKit.box(n,Vector3(x,0.29,0),Vector3(0.045,0.035,0.055),"steel")
            for y in range(4):FieldKit.box(n,Vector3(0,0.045+y*0.05,0.091),Vector3(0.2,0.013,0.015),"dark")
            FieldKit.box(n,Vector3(0,0.23,0.092),Vector3(0.08,0.03,0.012),"amber")
        "ring":
            var ring:=FieldKit.ring(n,Vector3(0,0.06,0),0.19,0.065,"rubber" if "tire" in id else "steel");ring.rotation=Vector3.ZERO
            if "gear" in id or "sprocket" in id:
                for i in range(12):
                    var a:=i*TAU/12;var tooth:=FieldKit.box(n,Vector3(cos(a)*0.19,0.06,sin(a)*0.19),Vector3(0.05,0.07,0.05),"steel");tooth.rotation.y=-a
        "bottle":
            FieldKit.tube(n,Vector3(0,0.06,0),Vector3(0,0.3,0),0.08,"glass")
            FieldKit.tube(n,Vector3(0,0.3,0),Vector3(0,0.38,0),0.033,"steel")
            FieldKit.box(n,Vector3(0,0.18,0.081),Vector3(0.095,0.1,0.009),"canvas")
        "canister":
            FieldKit.box(n,Vector3(0,0.18,0),Vector3(0.28,0.36,0.18),"rust")
            FieldKit.tube(n,Vector3(-0.09,0.36,0),Vector3(-0.09,0.4,0),0.033,"dark")
            FieldKit.tube(n,Vector3(0.03,0.4,0),Vector3(0.11,0.4,0),0.027,"steel")
            for x in [0.03,0.11]:FieldKit.tube(n,Vector3(x,0.35,0),Vector3(x,0.4,0),0.02,"steel")
            for side in [-1,1]:
                FieldKit.tube(n,Vector3(-0.1,0.07,side*0.095),Vector3(0.1,0.29,side*0.095),0.013,"steel")
        "tool":
            FieldKit.tube(n,Vector3(0,0.04,-0.2),Vector3(0,0.04,0.18),0.022,"steel")
            FieldKit.tube(n,Vector3(0,0.04,-0.21),Vector3(0,0.04,-0.05),0.038,"olive")
            if id in ["hammer","pickaxe"]:FieldKit.box(n,Vector3(0,0.06,0.18),Vector3(0.25,0.085,0.08),"steel")
            elif id=="wrench":
                for x in [-0.04,0.04]:FieldKit.box(n,Vector3(x,0.04,0.2),Vector3(0.035,0.04,0.11),"steel")
            elif id in ["cutters","pliers"]:
                FieldKit.tube(n,Vector3(0.09,0.04,-0.18),Vector3(-0.02,0.04,0.18),0.024,"steel")
        "board":
            FieldKit.box(n,Vector3(0,0.025,0),Vector3(0.32,0.04,0.24),"olive")
            for x in range(3):
                for z in range(2):FieldKit.box(n,Vector3(-0.1+x*0.1,0.06,-0.07+z*0.13),Vector3(0.065,0.035,0.05),"dark")
            for x in range(8):FieldKit.box(n,Vector3(-0.13+x*0.035,0.052,0.12),Vector3(0.012,0.01,0.045),"steel")
        "motor":
            FieldKit.tube(n,Vector3(0,0.14,-0.12),Vector3(0,0.14,0.12),0.13,"steel")
            FieldKit.tube(n,Vector3(0,0.14,-0.21),Vector3(0,0.14,-0.12),0.03,"dark")
            for i in range(6):FieldKit.box(n,Vector3(0,0.28,-0.1+i*0.04),Vector3(0.17,0.02,0.012),"dark")
        "propeller":
            FieldKit.ellipsoid(n,Vector3(0,0.04,0),Vector3(0.5,0.02,0.065),"rubber")
            FieldKit.tube(n,Vector3.ZERO,Vector3(0,0.08,0),0.04,"steel")
        "instrument":
            FieldKit.box(n,Vector3(0,0.13,0),Vector3(0.2,0.26,0.13),"dark")
            FieldKit.box(n,Vector3(0,0.19,0.07),Vector3(0.15,0.08,0.015),"glass")
            FieldKit.tube(n,Vector3(0,0.08,0.06),Vector3(0,0.08,0.085),0.035,"steel")
            for x in [-0.06,0.06]:FieldKit.box(n,Vector3(x,0.12,0.075),Vector3(0.015,0.018,0.015),"amber")
        _:
            FieldKit.box(n,Vector3(0,0.08,0),Vector3(0.3,0.16,0.21),"canvas" if f=="supply" else "steel")
            for x in [-0.1,0.1]:FieldKit.box(n,Vector3(x,0.085,0),Vector3(0.025,0.18,0.23),"dark")
    return n
