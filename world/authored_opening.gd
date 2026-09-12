extends RefCounted
# Paths are shared by ground ribbons, foliage exclusion, and regression route checks.
const TRAIL=[Vector3(57,0,-113),Vector3(64,0,-123),Vector3(72,0,-140),Vector3(68,0,-158),Vector3(53,0,-174),Vector3(35,0,-181),Vector3(16,0,-180)]
const RETURN=[Vector3(16,0,-180),Vector3(23,0,-164),Vector3(29,0,-148),Vector3(35,0,-136),Vector3(41,0,-122),Vector3(48,0,-115)]
const SIDE=[Vector3(72,0,-140),Vector3(84,0,-144),Vector3(92,0,-125),Vector3(88,0,-120)]
const CACHE=[Vector3(68,0,-158),Vector3(84,0,-176),Vector3(84,0,-194)]
static func distance_path(pos: Vector3,path: Array) -> float:
    var distance:=10000.0
    for i in range(path.size()-1):
        var a: Vector3=path[i];var b: Vector3=path[i+1]
        var flat:=Vector3(pos.x,0,pos.z)
        var t:=clampf((flat-a).dot(b-a)/(b-a).length_squared(),0,1)
        distance=minf(distance,flat.distance_to(a.lerp(b,t)))
    return distance
static func clear(pos: Vector3) -> bool:
    if AssetLibrary.clear_area(pos):return true
    if absf(pos.x)<11:return true
    if Vector2(pos.x-54,pos.z+100).length()<20:return true
    if pos.z>-115 and pos.z<-77 and pos.x<60 and pos.x>0:return true
    for path in [TRAIL,RETURN,SIDE,CACHE]:
        if distance_path(pos,path)<3.1:return true
    for point in [Vector3(78,0,-170),Vector3(77,0,-151),Vector3(92,0,-121),Vector3(45,0,-184),Vector3(28,0,-177)]:
        if point.distance_to(pos)<3:return true
    return false
static func surface(p: Node3D,pos: Vector3,size: Vector3,material: String,tag: String,yaw: float=0) -> Node3D:
    var n:=FieldKit.box(p,pos,size,material,true);n.rotation.y=yaw
    for child in n.get_children():
        if child is StaticBody3D:child.set_meta("surface",tag)
    return n
static func ribbon(p: Node3D,path: Array,width: float,tag: String="dirt") -> void:
    for i in range(path.size()-1):
        var a: Vector3=path[i];var b: Vector3=path[i+1];var delta:=b-a
        var yaw:=atan2(delta.x,delta.z)
        var mesh:=FieldKit.box(p,(a+b)/2+Vector3.UP*.016,Vector3(width,.03,delta.length()+.5),"ground")
        mesh.rotation.y=yaw
        # Surface-only volumes avoid overlapping coplanar physics faces at trail bends.
        var area:=Area3D.new();area.collision_layer=16;area.collision_mask=0;area.monitoring=false
        area.set_meta("surface",tag);p.add_child(area);area.position=(a+b)/2+Vector3.UP*.07;area.rotation.y=yaw
        var c:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(width,.12,delta.length()+.5);c.shape=shape;area.add_child(c)
static func build(game,polish) -> void:
    var p: Node3D=game.world
    var props:=Node3D.new();props.name="AuthoredServiceLoop";p.add_child(props)
    ribbon(props,TRAIL,4,"gravel");ribbon(props,RETURN,3.3,"dirt");ribbon(props,SIDE,2,"leaves");ribbon(props,CACHE,1.8,"mud")
    # Raised limestone shelves and fence form readable boundaries; the road stays usable.
    var rng:=RandomNumberGenerator.new();rng.seed=9226
    for path in [TRAIL,RETURN]:
        for i in range(path.size()-1):
            var a: Vector3=path[i];var b: Vector3=path[i+1]
            var across: Vector3=(b-a).normalized().cross(Vector3.UP)
            for j in range(4):
                var pos: Vector3=a.lerp(b,(j+.5)/4)+across*6
                if clear(pos):continue
                var rock_size:=Vector3(5,3.6+rng.randf(),4.5);var rock_yaw:=rng.randf()*TAU
                var rock:=FieldKit.ellipsoid(props,pos+Vector3.UP*1.1,rock_size,"rock")
                rock.rotation.y=rock_yaw
                FieldKit.box_collision(props,pos+Vector3.UP*1.1,rock_size*.82,"rock",rock_yaw)
    # Fence follows the maintenance property, with a motor gate in its actual opening.
    for z in [-118,-122,-126,-130,-142,-146,-150,-154]:
        FieldKit.tube(props,Vector3(35,0,z),Vector3(35,2.7,z),.07,"rust")
        surface(props,Vector3(35,1.25,z),Vector3(.15,2.5,3.9),"steel","metal")
    if not Session.state.polish.gates.get("shortcut",false):
        var gate:=Node3D.new();gate.name="PoweredShortcut";p.add_child(gate)
        surface(gate,Vector3(35,1.25,-136),Vector3(.22,2.5,8),"rust","metal")
        FieldKit.text(gate,"SERVICE / NO POWER",Vector3(35.2,2,-135),.006)
        polish.gate=gate
    FieldKit.cable(props,Vector3(35,2.6,-136),Vector3(28,1,-177),1.0)
    FieldKit.cabinet(props,Vector3(28,0,-177))
    FieldKit.text(props,"04 / GATE FEED",Vector3(28,2,-177.5),.006)
    # Creek culvert: a human can use the trail while an aircraft can cut through the aperture.
    for x in [65.5,70.5]:surface(props,Vector3(x,1.9,-158),Vector3(.6,3.8,5),"rock","concrete")
    surface(props,Vector3(68,3.95,-158),Vector3(5.6,.4,5),"rock","concrete")
    FieldKit.box(props,Vector3(68,.015,-158),Vector3(4.4,.02,5),"dark")
    var water_area:=Area3D.new();water_area.collision_layer=16;water_area.collision_mask=0;water_area.monitoring=false;water_area.set_meta("surface","water");props.add_child(water_area);water_area.position=Vector3(68,.05,-158)
    var water_shape:=CollisionShape3D.new();var water_box:=BoxShape3D.new();water_box.size=Vector3(4.4,.1,5);water_shape.shape=water_box;water_area.add_child(water_shape)
    # Physical field beacons, numbers, direction markings. No free-floating rings.
    for i in range(ScoutActivities.COURSE.size()):
        var c: Vector3=ScoutActivities.COURSE[i]
        var dir: Vector3=(ScoutActivities.COURSE[1]-c).normalized() if i==0 else (c-ScoutActivities.COURSE[i-1]).normalized()
        var side: Vector3=Vector3(dir.z,0,-dir.x).normalized()*1.9
        for sign_ in [-1,1]:
            var base: Vector3=c+side*sign_;base.y=0
            FieldKit.tube(props,base,base+Vector3.UP*(c.y+1.8),.07,"steel")
            var light:=FieldKit.box(p,c+side*sign_,Vector3(.12,.55,.12),"amber")
            if sign_==1:polish.activities.rings.append(light)
        FieldKit.text(props,"SCOUT / %02d →" % (i+1),c+side+Vector3.UP*.65,.005)
    FieldKit.text(props,"SCOUT LEAGUE\nCREEK RUN / 6 BEACONS",Vector3(61,2,-121),.006)
    FieldKit.cabinet(props,Vector3(61,0,-122))
    # Precise elevated drone landing platform.
    surface(props,Vector3(45,1.6,-184),Vector3(2.1,3.2,2.1),"olive","metal")
    surface(props,Vector3(45,3.25,-184),Vector3(1.5,.1,1.5),"steel","metal")
    FieldKit.ring(props,Vector3(45,3.32,-184),.6,.05,"amber")
    # Small composed stories with recoverable supplies rather than random scatter.
    FieldKit.workbench(props,Vector3(77,0,-152))
    FieldKit.cable(props,Vector3(75,.1,-151),Vector3(79,.1,-154),.02)
    FieldKit.crate(props,Vector3(77,0,-150))
    FieldKit.tube(props,Vector3(92,0,-121),Vector3(92,1.6,-121),.09,"wood")
    FieldKit.tube(props,Vector3(91.5,1.1,-121),Vector3(92.5,1.1,-121),.06,"wood")
    for i in range(6):FieldKit.ellipsoid(props,Vector3(91.5+rng.randf(),.12,-120+rng.randf()),Vector3(.4,.3,.5),"rock")
    FieldKit.crate(props,Vector3(84,0,-194))
    FieldKit.tube(props,Vector3(78,.8,-170),Vector3(78,3,-170),.025,"steel")
    FieldKit.box(props,ScoutActivities.SOURCE,Vector3(.4,.3,.22),"olive")
    var lamp:=OmniLight3D.new();lamp.name="BenchLamp";lamp.position=Vector3(59,2,-98);lamp.omni_range=4;lamp.light_energy=1.2;lamp.light_color=Color("ffe1aa");lamp.visible=Session.state.polish.gates.get("lamp",false);p.add_child(lamp)
    FieldKit.box(props,Vector3(55,1,-109),Vector3(.5,.25,.2),"olive")
    FieldKit.text(props,"CREEK SERVICE →\nROAD / CAMP ←",Vector3(60,2.2,-116),.006)
    FieldKit.batch_static(props,280,50)
    vegetation(p)
    game.audio_rig.zones.clear()
    game.audio_rig.spatial(p,"creek",Vector3(68,0,-158),.11,32)
    game.audio_rig.spatial(p,"insects",Vector3(87,1,-128),.025,22)
    game.audio_rig.spatial(p,"leaves_wind",Vector3(51,4,-145),.07,40)
    game.audio_rig.spatial(p,"electrical",Vector3(28,1,-177),.035,12)
    game.audio_rig.spatial(p,"electrical",Vector3(155,2,-730),.08,36)

static func vegetation(p: Node3D) -> void:
    var rng:=RandomNumberGenerator.new();rng.seed=9261
    var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=1
    var grass:=FieldKit.grass_mesh();grass.surface_set_material(0,material)
    var leaf:=ShaderMaterial.new();leaf.shader=load("res://art/foliage.gdshader")
    var shrub:=FieldKit.tree_mesh(91);shrub.surface_set_material(0,leaf)
    var root:=Node3D.new();root.name="OpeningEcology";p.add_child(root)
    for iz in range(9):
        for ix in range(7):
            var center:=Vector3(-10+ix*20,0,-75-iz*20)
            var transforms: Array[Transform3D]=[]
            var bushes: Array[Transform3D]=[]
            for i in range(420):
                var pos:=center+Vector3(rng.randf_range(-10,10),.04,rng.randf_range(-10,10))
                if clear(Vector3(pos.x,0,pos.z)):continue
                var cluster:=sin(pos.x*.19+cos(pos.z*.08))*cos(pos.z*.15)
                if cluster<-.2 and rng.randf()<.85:continue
                var scale_: float=rng.randf_range(.7,1.8)
                transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_),pos))
                if i%28==0:
                    var scale_b:=rng.randf_range(.18,.4)
                    bushes.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(scale_b,scale_b*.75,scale_b)),pos-Vector3.UP*(scale_b*2.5)))
            batch(root,grass,transforms,95,"GroundCover");batch(root,shrub,bushes,135,"Scrub")
    # Tall canopy screens eastward POIs, leaving named routes and camp clear.
    var crowns: Array[Transform3D]=[]
    for i in range(100):
        var pos:=Vector3(rng.randf_range(18,122),0,rng.randf_range(-230,-108))
        if clear(pos):continue
        var scale_: float=rng.randf_range(.8,1.45)
        crowns.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_),pos))
        var trunk:=FieldKit.tube(root,pos,pos+Vector3(.1,4.1*scale_,0),.2*scale_,"wood",.07)
        trunk.visibility_range_end=180
        var body:=StaticBody3D.new();root.add_child(body);body.position=pos+Vector3.UP*2*scale_;body.set_meta("surface","wood")
        var c:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.height=4*scale_;shape.radius=.22*scale_;c.shape=shape;body.add_child(c)
    batch(root,shrub,crowns,240,"Canopy")
static func batch(p: Node3D,mesh: Mesh,transforms: Array[Transform3D],distance: float,title: String) -> void:
    if transforms.is_empty():return
    var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms.size()
    var bounds:=AABB(transforms[0].origin,Vector3.ZERO)
    for transform_ in transforms:bounds=bounds.expand(transform_.origin)
    var cell_origin:=bounds.get_center();var local_bounds:=AABB(transforms[0].origin-cell_origin,Vector3.ZERO)
    for i in range(transforms.size()):
        var transform_: Transform3D=transforms[i];transform_.origin-=cell_origin
        mm.set_instance_transform(i,transform_);local_bounds=local_bounds.expand(transform_.origin)
    mm.custom_aabb=local_bounds.grow(8 if title=="Canopy" else 3 if title=="Scrub" else 2)
    var n:=MultiMeshInstance3D.new();n.name=title;n.multimesh=mm;n.position=cell_origin;n.visibility_range_end=distance;n.visibility_range_end_margin=15;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;p.add_child(n)
