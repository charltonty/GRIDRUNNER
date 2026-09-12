class_name FieldKit
extends RefCounted
# Original reusable geometry. World textures: ambientCG CC0; see ASSET_CREDITS.
static var cache: Dictionary = {}
const STATIC_CELL_SIZE:=100.0
const STATIC_VISIBILITY_RANGE:=500.0
static func mat(key: String) -> StandardMaterial3D:
    if cache.has(key): return cache[key]
    var m := StandardMaterial3D.new()
    var colors := {"steel":"666f6b","dark":"202624","olive":"545b40","rubber":"151916","rust":"71513a","wood":"776348","ground":"a59a78","rock":"a9a48d","asphalt":"777875","canvas":"747559","glass":"253e40","solar":"142b3a","amber":"e2b46a","red":"b95438","leaf":"4e5833","skin":"a4896c","cloth":"6d6b53","dirt":"827354"}
    m.albedo_color=Color(colors.get(key,"8a8c7c"))
    m.roughness=0.95
    m.metallic_specular=0.25
    m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    if key in ["steel","dark","olive"]: m.metallic=0.65; m.roughness=0.72
    if key in ["glass","solar"]: m.metallic=0.5; m.roughness=0.2
    if key in ["amber","red"]: m.emission_enabled=true; m.emission=m.albedo_color; m.emission_energy_multiplier=1.3
    var maps := {"asphalt":"Asphalt011","ground":"Ground037","rock":"Rock030","wood":"Wood051"}
    if maps.has(key):
        var base: String="res://assets/materials/"+maps[key]+"/"+maps[key]+"_1K-JPG_"
        if ResourceLoader.exists(base+"Color.jpg"):
            m.albedo_texture=load(base+"Color.jpg")
            m.normal_enabled=true
            m.normal_scale=0.28
            m.normal_texture=load(base+"NormalGL.jpg")
            if key=="wood": m.roughness_texture=load(base+"Roughness.jpg")
            m.uv1_triplanar=true
            m.uv1_world_triplanar=true
            m.uv1_scale=Vector3.ONE*(0.32 if key!="wood" else 1.0)
    if key in ["steel","dark","olive","rust","canvas","cloth"]:
        var noise:=FastNoiseLite.new();noise.seed=37;noise.frequency=0.035;noise.fractal_octaves=3
        var tex:=NoiseTexture2D.new();tex.width=256;tex.height=256;tex.noise=noise;tex.seamless=true
        var gradient:=Gradient.new();gradient.set_color(0,m.albedo_color.darkened(0.3));gradient.set_color(1,m.albedo_color.lightened(0.12))
        tex.color_ramp=gradient;m.albedo_texture=tex;m.albedo_color=Color.WHITE
        m.uv1_triplanar=true;m.uv1_scale=Vector3.ONE*2
    cache[key]=m
    return m

static func mesh(p: Node3D, shape: Mesh, pos: Vector3, material: String, solid: bool=false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.mesh=shape; n.material_override=mat(material); n.position=pos
    p.add_child(n)
    if solid:
        n.create_trimesh_collision()
        for child in n.get_children():
            if child is StaticBody3D:child.set_meta("surface",material)
    return n
static func box(p: Node3D, pos: Vector3, size: Vector3, material: String, solid: bool=false) -> MeshInstance3D:
    var s:=BoxMesh.new(); s.size=size
    var n:=mesh(p,s,pos,material)
    if solid:box_collision(n,Vector3.ZERO,size,material)
    return n
static func collision_body(p: Node3D,pos: Vector3,basis_: Basis,shape: Shape3D,surface: String) -> StaticBody3D:
    var body:=StaticBody3D.new();body.name="StaticCollision";body.set_meta("surface",surface);p.add_child(body)
    body.position=pos;body.basis=basis_
    var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
    return body
static func box_collision(p: Node3D,pos: Vector3,size: Vector3,surface: String="dirt",yaw: float=0.0) -> StaticBody3D:
    var shape:=BoxShape3D.new();shape.size=size
    return collision_body(p,pos,Basis(Vector3.UP,yaw),shape,surface)
static func segment_basis(a: Vector3,b: Vector3) -> Basis:
    var up: Vector3=(b-a).normalized()
    var right: Vector3=up.cross(Vector3.FORWARD).normalized()
    if right.length()<0.1:right=Vector3.RIGHT
    return Basis(right,up,right.cross(up)).orthonormalized()
static func cylinder_collision(p: Node3D,a: Vector3,b: Vector3,radius: float,surface: String="wood") -> StaticBody3D:
    var shape:=CylinderShape3D.new();shape.height=a.distance_to(b);shape.radius=radius
    return collision_body(p,(a+b)*.5,segment_basis(a,b),shape,surface)
static func tube(p: Node3D, a: Vector3, b: Vector3, radius: float, material: String, top: float=-1.0) -> MeshInstance3D:
    var s:=CylinderMesh.new(); s.height=a.distance_to(b); s.bottom_radius=radius; s.top_radius=radius if top<0 else top; s.radial_segments=10
    var n:=mesh(p,s,(a+b)*0.5,material)
    n.basis=segment_basis(a,b)
    return n
static func ellipsoid(p: Node3D, pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
    var s:=SphereMesh.new(); s.radius=0.5; s.height=1; s.radial_segments=12; s.rings=6
    var n:=mesh(p,s,pos,material); n.scale=size
    return n
static func ring(p: Node3D,pos: Vector3,radius: float,width: float,material: String) -> MeshInstance3D:
    var s:=TorusMesh.new(); s.inner_radius=radius-width; s.outer_radius=radius; s.rings=24; s.ring_segments=8
    var n:=mesh(p,s,pos,material); n.rotation.z=PI/2
    return n
static func text(p: Node3D, title: String, pos: Vector3, size: float=0.008, color: Color=Color("dfd6af")) -> Label3D:
    var n:=Label3D.new(); n.text=title; n.position=pos; n.pixel_size=size; n.font_size=32; n.modulate=color; n.outline_size=0; n.no_depth_test=false
    p.add_child(n); return n
static func cable(p: Node3D,a: Vector3,b: Vector3,sag: float=1.0) -> void:
    var prev:=a
    for i in range(1,9):
        var t:=float(i)/8
        var next:=a.lerp(b,t)-Vector3.UP*sin(t*PI)*sag
        tube(p,prev,next,0.025,"rubber"); prev=next
static func group(p: Node3D, pos: Vector3) -> Node3D:
    var n:=Node3D.new(); p.add_child(n); n.position=pos; return n

static func tire(p: Node3D, pos: Vector3, r: float) -> void:
    var driven: bool=p.name in ["Bike","PowerTrailer"]
    var assembly:=group(p,pos)
    if driven: assembly.add_to_group("rolling_tires"); assembly.set_meta("radius",r)
    p=assembly; pos=Vector3.ZERO
    ring(p,pos,r,0.12,"rubber")
    ring(p,pos,r-0.12,0.025,"steel")
    tube(p,pos-Vector3(0.15,0,0),pos+Vector3(0.15,0,0),0.085,"dark")
    for i in range(32):
        var t:=TAU*i/32
        tube(p,pos,pos+Vector3(0,sin(t),cos(t))*(r-0.15),0.008,"steel")
        var tread:=box(p,pos+Vector3(0,sin(t),cos(t))*(r-0.025),Vector3(0.19,0.045,0.07),"rubber")
        tread.rotation.x=-t
    ring(p,pos+Vector3(0.1,0,0),r*0.48,0.045,"steel")

static func bike(p: Node3D) -> void:
    for z in [-0.93,0.89]: tire(p,Vector3(0,-0.1,z),0.46)
    for x in [-0.11,0.11]:
        tube(p,Vector3(x,-0.1,-0.93),Vector3(x,0.88,-0.55),0.045,"steel")
        tube(p,Vector3(x,0.35,0.1),Vector3(x,-0.1,0.89),0.05,"dark")
        tube(p,Vector3(x,0.72,-0.55),Vector3(x,-0.03,0.1),0.04,"dark")
        tube(p,Vector3(x,-0.03,0.1),Vector3(x,0.64,0.6),0.04,"dark")
        tube(p,Vector3(x,0.64,0.6),Vector3(x,0.72,-0.55),0.035,"steel")
    var pack:=box(p,Vector3(0,0.29,-0.18),Vector3(0.34,0.58,0.56),"olive"); pack.rotation.x=-0.15
    for y in range(7): box(p,Vector3(0,0.06+y*0.07,-0.476),Vector3(0.29,0.012,0.02),"dark")
    tube(p,Vector3(-0.18,0.01,0.17),Vector3(0.18,0.01,0.17),0.17,"dark")
    box(p,Vector3(0,0.66,0.27),Vector3(0.33,0.14,0.91),"rubber")
    box(p,Vector3(0,0.3,0.86),Vector3(0.75,0.16,0.53),"olive")
    for x in [-0.4,0.4]:
        box(p,Vector3(x,0.34,0.64),Vector3(0.26,0.45,0.53),"canvas")
        for z in [0.45,0.8]: box(p,Vector3(x,0.34,z),Vector3(0.28,0.48,0.03),"dark")
    box(p,Vector3(0,0.48,-0.99),Vector3(0.32,0.06,0.54),"olive")
    tube(p,Vector3(-0.52,0.99,-0.53),Vector3(0.52,0.99,-0.53),0.025,"steel")
    for x in [-0.45,0.45]:
        tube(p,Vector3(x-0.08,0.99,-0.53),Vector3(x+0.08,0.99,-0.53),0.04,"rubber")
        tube(p,Vector3(x,0.99,-0.53),Vector3(x,1.23,-0.61),0.012,"steel")
        ellipsoid(p,Vector3(x,1.24,-0.61),Vector3(0.19,0.1,0.06),"glass")
    box(p,Vector3(0,0.86,-0.64),Vector3(0.29,0.22,0.14),"dark")
    box(p,Vector3(0,0.86,-0.72),Vector3(0.23,0.1,0.02),"amber")
    var screen:=box(p,Vector3(0,1.01,-0.47),Vector3(0.16,0.08,0.14),"glass"); screen.rotation.x=-0.4
    text(p,"GR / 01",Vector3(0,0.47,1.14),0.003)
    cable(p,Vector3(0.16,0.84,-0.48),Vector3(0.19,0.12,0.08),0.07)
    tube(p,Vector3(0,0.06,0.5),Vector3(0,-0.05,1.65),0.035,"steel")

static func drone(p: Node3D) -> void:
    ellipsoid(p,Vector3.ZERO,Vector3(0.47,0.23,0.64),"dark")
    box(p,Vector3(0,0.11,0.05),Vector3(0.3,0.08,0.37),"olive")
    for x in [-0.63,0.63]:
        for z in [-0.52,0.52]:
            tube(p,Vector3(sign(x)*0.12,0,sign(z)*0.16),Vector3(x,0,z),0.04,"dark")
            tube(p,Vector3(x,-0.06,z),Vector3(x,0.11,z),0.075,"steel")
            var rotor:=group(p,Vector3(x,0.14,z)); rotor.add_to_group("rotors")
            ellipsoid(rotor,Vector3.ZERO,Vector3(0.76,0.016,0.065),"rubber")
            ellipsoid(rotor,Vector3.ZERO,Vector3(0.065,0.016,0.76),"rubber")
            box(p,Vector3(x,-0.075,z),Vector3(0.06,0.025,0.05),"red" if z>0 else "amber")
    for x in [-0.2,0.2]:
        tube(p,Vector3(x,0,0.2),Vector3(x,-0.29,0.3),0.022,"steel")
        tube(p,Vector3(x,-0.29,0.3),Vector3(x,-0.29,-0.27),0.025,"rubber")
    ellipsoid(p,Vector3(0,-0.17,-0.25),Vector3(0.18,0.18,0.2),"steel")
    ellipsoid(p,Vector3(0,-0.17,-0.345),Vector3(0.12,0.12,0.04),"glass")
    for x in [-0.15,0.15]: ellipsoid(p,Vector3(x,0,-0.3),Vector3(0.07,0.055,0.03),"amber")
    tube(p,Vector3(0,0.12,0.2),Vector3(0,0.34,0.25),0.012,"rubber")

static func crate(p: Node3D,pos: Vector3=Vector3.ZERO) -> void:
    AssetLibrary.make(p,"GR_FieldStorageCase_02",pos)

static func generator(p: Node3D,pos: Vector3) -> void:
    AssetLibrary.make(p,"GR_Generator_01",pos)

static func solar(p: Node3D,pos: Vector3) -> void:
    AssetLibrary.make(p,"GR_SolarArray_02",pos)

static func trailer(p: Node3D) -> void:
    box(p,Vector3(0,0.44,0),Vector3(1.5,0.14,2),"steel")
    for x in [-0.82,0.82]: tire(p,Vector3(x,0.42,0.1),0.42)
    for z in [-0.94,0.94]: box(p,Vector3(0,0.68,z),Vector3(1.5,0.4,0.045),"olive")
    for x in [-0.72,0.72]: box(p,Vector3(x,0.68,0),Vector3(0.045,0.4,1.9),"olive")
    crate(p,Vector3(-0.25,0.51,0.48)); generator(p,Vector3(0,0.51,-0.43))
    for x in [-0.58,0.58]: box(p,Vector3(x,0.87,0.64),Vector3(0.2,0.58,0.27),"red")
    tube(p,Vector3(0,0.42,-0.9),Vector3(0,0.55,-2),0.04,"steel")
    text(p,"GRIDRUNNER\nMOBILE POWER",Vector3(0,0.68,0.97),0.003)

static func npc(p: Node3D,pos: Vector3,mechanic: bool=false) -> Node3D:
    return load("res://art/human_visual.gd").make(p,pos,mechanic)

static func legacy_npc(p: Node3D,pos: Vector3,mechanic: bool=false) -> Node3D:
    var n:=group(p,pos)
    for x in [-0.14,0.14]:
        ellipsoid(n,Vector3(x,0.12,-0.07),Vector3(0.2,0.24,0.38),"rubber")
        tube(n,Vector3(x,0.2,0),Vector3(x,0.85,0.03),0.115,"cloth",0.14)
    ellipsoid(n,Vector3(0,1.14,0),Vector3(0.52,0.67,0.31),"cloth")
    box(n,Vector3(0,1.14,0.13),Vector3(0.39,0.48,0.12),"canvas")
    ellipsoid(n,Vector3(0,1.69,-0.01),Vector3(0.28,0.34,0.28),"skin")
    ellipsoid(n,Vector3(0,1.84,0),Vector3(0.34,0.12,0.33),"olive")
    box(n,Vector3(0,1.8,-0.13),Vector3(0.3,0.035,0.28),"olive")
    for x in [-0.3,0.3]:
        tube(n,Vector3(x*0.8,1.4,0),Vector3(x*1.25,1.05,-0.02),0.09,"cloth",0.12)
        tube(n,Vector3(x*1.25,1.05,-0.02),Vector3(x*1.1,0.88,-0.12),0.075,"cloth")
        ellipsoid(n,Vector3(x*1.1,0.84,-0.12),Vector3(0.12,0.16,0.1),"skin")
    if mechanic: box(n,Vector3(0,1.1,-0.18),Vector3(0.36,0.65,0.04),"rust")
    n.add_to_group("field_npcs")
    return n

static func cabinet(p: Node3D,pos: Vector3) -> void:
    var n:=AssetLibrary.make(p,"GR_DistributionCabinet_01",pos)
    AssetLibrary.solid_box(n,Vector3(0,1,0),Vector3(.87,2,.62))

static func workbench(p: Node3D,pos: Vector3) -> void:
    var n:=AssetLibrary.make(p,"GR_Workbench_02",pos)
    AssetLibrary.solid_box(n,Vector3(0,.91,0),Vector3(1.9,.13,.85),"wood")

static func shed(p: Node3D,pos: Vector3,title: String) -> void:
    var n:=group(p,pos)
    box(n,Vector3(0,0.1,0),Vector3(12,0.2,9),"rock",true)
    box(n,Vector3(0,2,-4.4),Vector3(12,4,0.2),"wood",true)
    for x in [-5.9,5.9]:
        box(n,Vector3(x,2,0),Vector3(0.2,4,9),"wood",true)
        for z in range(15): box(n,Vector3(x*1.01,2,-4.3+z*0.6),Vector3(0.06,4,0.04),"dark")
    for x in [-1,1]:
        var roof:=box(n,Vector3(x*3.2,4.48,0),Vector3(6.6,0.13,10),"rust",true); roof.rotation.z=-x*0.16
        for z in range(22):
            var rib:=box(n,Vector3(x*3.2,4.58,-4.8+z*0.46),Vector3(6.6,0.06,0.04),"steel"); rib.rotation.z=-x*0.16
    box(n,Vector3(0,3.3,4.5),Vector3(11.8,1.1,0.18),"olive",true)
    text(n,title,Vector3(0,3.3,4.61),0.02)
    workbench(n,Vector3(-3,0,-3))
    cabinet(n,Vector3(4.7,0,-3.7))
    for i in range(4): crate(n,Vector3(3+i%2,0.2+(i/2)*0.78,-1))

static func pole(p: Node3D,pos: Vector3) -> void:
    var n:=group(p,pos)
    tube(n,Vector3.ZERO,Vector3(0,12,0),0.2,"wood",0.12)
    box(n,Vector3(0,10.8,0),Vector3(4.8,0.16,0.2),"wood")
    for x in [-1.8,0,1.8]:
        tube(n,Vector3(x,10.8,0),Vector3(x,11.5,0),0.07,"steel")
        for y in range(4):
            var s:=CylinderMesh.new();s.top_radius=0.13;s.bottom_radius=0.13;s.height=0.065
            mesh(n,s,Vector3(x,10.99+y*0.12,0),"glass")
    tube(n,Vector3(0.5,8.6,0),Vector3(0.5,9.7,0),0.35,"steel")

static func camp(p: Node3D) -> void:
    var n:=group(p,Vector3(54,0,-100))
    # Open courtyard faces south toward the player's arrival.
    shed(n,Vector3(0,0,-8),"BLACK CREEK / FIELD STATION")
    for x in [-7.0,7.0]:
        for z in [-2.0,7.0]: tube(n,Vector3(x,0,z),Vector3(x,3.1,z),0.055,"steel")
    var tarp:=box(n,Vector3(0,3.25,2.6),Vector3(14.4,0.04,9.6),"canvas"); tarp.rotation.z=0.035
    workbench(n,Vector3(-4.5,0,0))
    generator(n,Vector3(5,0,0))
    for i in range(3):barrel(n,Vector3(8.5,0,-3+i*0.8))
    for i in range(3):pallet(n,Vector3(-8,0.27*i,4))
    cabinet(n,Vector3(5,0,-2.2))
    for i in range(3): solar(n,Vector3(-11-i*2.2,0,-2))
    for i in range(6): crate(n,Vector3(-5+(i%3)*1.05,0.8*floor(i/3.0),-2.6))
    for x in [-5,5]:
        box(n,Vector3(x,0.51,5),Vector3(0.55,0.06,0.55),"canvas")
        box(n,Vector3(x,0.88,5.24),Vector3(0.55,0.72,0.04),"canvas")
        for dx in [-0.23,0.23]:
            tube(n,Vector3(x+dx,0,4.72),Vector3(x+dx,0.65,5.23),0.018,"steel")
            tube(n,Vector3(x+dx,0,5.23),Vector3(x+dx,0.65,4.72),0.018,"steel")
    cable(n,Vector3(-13,0.14,-2),Vector3(5,0.14,-2.2),0)
    cable(n,Vector3(5,0.14,-2.2),Vector3(5,0.14,0),0)
    cable(n,Vector3(-7,3,6),Vector3(7,3,6),0.45)
    for x in range(-6,7,2):
        ellipsoid(n,Vector3(x,2.65,6),Vector3(0.09,0.14,0.09),"amber")
    var light:=OmniLight3D.new(); light.position=Vector3(0,2.7,1); light.light_color=Color("ffd19a");light.light_energy=2;light.omni_range=12;n.add_child(light)
    npc(n,Vector3(0,0,6),false)
    text(n,"SMALL POWER.\nBIG FREEDOM.",Vector3(5,1.6,7.1),0.004)
    tube(n,Vector3(5,0,7),Vector3(5,2.4,7),0.055,"wood")

static func substation(p: Node3D,pos: Vector3) -> void:
    var n:=group(p,pos)
    box(n,Vector3(0,0.07,0),Vector3(30,0.14,35),"rock",true)
    for x in [-10,0,10]:
        for z in [-10,0,10]:
            AssetLibrary.make(n,"GR_PadTransformer_01",Vector3(x,.14,z))
            AssetLibrary.solid_box(n,Vector3(x,1,z),Vector3(2,2,1.5))
            tube(n,Vector3(x-1,1,z-2),Vector3(x-1,4,z-2),0.5,"steel")
            for y in range(12): box(n,Vector3(x-1,1+y*0.18,z-2),Vector3(1.4,0.04,0.8),"steel")
            tube(n,Vector3(x-1,4,z-2),Vector3(x-1,5,z-2),0.14,"glass")
    for x in [-14,14]:
        for z in range(-16,18,4): tube(n,Vector3(x,0,z),Vector3(x,2.3,z),0.04,"steel")
        for y in [0.5,1.1,1.7,2.3]: cable(n,Vector3(x,y,-16),Vector3(x,y,16),0.05)
    for z in [-14,14]:
        for x in [-11,11]: tube(n,Vector3(x,0,z),Vector3(x,8,z),0.14,"steel")
        tube(n,Vector3(-11,8,z),Vector3(11,8,z),0.14,"steel")
        for x in [-9,0,9]: cable(n,Vector3(x,8,-14),Vector3(x,8,14),1.8)

static func tree_mesh(seed_value: int) -> ArrayMesh:
    var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
    var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Wind-shaped, branching live-oak silhouette, with individual leaf sprays.
    for i in range(145):
        var a:=rng.randf()*TAU; var r:=sqrt(rng.randf())*3.5
        var c:=Vector3(cos(a)*r,4.0+rng.randf()*2.0-r*0.22,sin(a)*r)
        for j in range(3):
            var angle:=rng.randf()*TAU
            var w:=Vector3(cos(angle),0,sin(angle))*rng.randf_range(0.14,0.36)
            var h:=Vector3(0,rng.randf_range(0.14,0.32),0)
            var vertices: Array[Vector3]=[c-w-h,c-w+h,c+w+h,c-w-h,c+w+h,c+w-h]
            var uvs: Array[Vector2]=[Vector2(0,1),Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1)]
            var color:=Color("3e492b").lerp(Color("859058"),rng.randf()*0.8)
            for k in range(6):
                st.set_uv(uvs[k]);st.set_color(color);st.add_vertex(vertices[k])
    st.generate_normals(); return st.commit()

static func grass_mesh() -> ArrayMesh:
    var rng:=RandomNumberGenerator.new();rng.seed=19
    var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(9):
        var a:=rng.randf()*TAU;var c:=Vector3(cos(a),0,sin(a))*rng.randf()*0.35
        var side:=Vector3(cos(a),0,sin(a))*0.035
        var tip:=c+Vector3(0.17,rng.randf_range(0.25,0.75),0)
        for v in [c-side,tip,c+side]:
            st.set_color(Color("776f42").lerp(Color("c0ac71"),rng.randf()));st.add_vertex(v)
    st.generate_normals();return st.commit()

static func foliage(p: Node3D,center: float,leg: int) -> void:
    var rng:=RandomNumberGenerator.new();rng.seed=900+leg
    var leaf:=StandardMaterial3D.new();leaf.vertex_color_use_as_albedo=true;leaf.vertex_color_is_srgb=true;leaf.cull_mode=BaseMaterial3D.CULL_DISABLED;leaf.roughness=1
    var gm:=grass_mesh();gm.surface_set_material(0,leaf)
    var foliage_mat:=ShaderMaterial.new();foliage_mat.shader=load("res://art/foliage.gdshader")
    var tm:=tree_mesh(12);tm.surface_set_material(0,foliage_mat)
    # Two-dimensional chunks are the acceleration structure for ground cover.
    # MultiMesh culling is all-or-nothing, so narrow cells keep off-screen strips off the GPU.
    for iz in range(19):
        for ix in range(4):
            var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=gm;mm.instance_count=175
            var x0:=-200.0+ix*100.0;var z0:=center+850.0-iz*100.0;var cell_origin:=Vector3(x0+50,0,z0+50)
            for i in range(mm.instance_count):
                var x:=rng.randf_range(x0,x0+100)
                if absf(x)<12:x+=24*signf(x)
                var z:=rng.randf_range(z0,z0+100)
                var courtyard: bool=(Vector2(x-54,z+100).length()<27 or AssetLibrary.clear_area(Vector3(x,0,z))) if leg==1 else false
                var scale_: float=0.01 if courtyard else rng.randf_range(0.7,1.9)
                mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_),Vector3(x,0.04,z)-cell_origin))
            mm.custom_aabb=AABB(Vector3(-52,-.1,-52),Vector3(104,2,104))
            var node:=MultiMeshInstance3D.new();node.name="GrassCell_%02d_%02d" % [ix,iz];node.multimesh=mm;node.position=cell_origin;node.visibility_range_end=115;node.visibility_range_end_margin=20;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;p.add_child(node)
    for i in range(250):
        var x:=rng.randf_range(-440,440); var z:=center+rng.randf_range(-930,930)
        if leg==1 and i>=230:
            var a:=TAU*float(i-230)/20
            x=54+cos(a)*rng.randf_range(24,40);z=-103+sin(a)*rng.randf_range(22,35)
        if absf(x)<20 or (leg==1 and (Vector2(x-54,z+100).length()<20 or AssetLibrary.clear_area(Vector3(x,0,z)))): continue
        if absf(x)<180 and i%3!=0 and i<230: continue
        var n:=group(p,Vector3(x,height_at(x,z),z)); var s:=rng.randf_range(0.8,2.1);n.scale=Vector3(s,s,s)
        tube(n,Vector3.ZERO,Vector3(0.3,4,0),0.32,"wood",0.12)
        cylinder_collision(n,Vector3.ZERO,Vector3(0.3,4,0),.27,"wood")
        for a in [0,2,4]: tube(n,Vector3(0.1,2,0),Vector3(cos(a)*2.4,4.6,sin(a)*2.4),0.14,"wood",0.025)
        var leaves:=MeshInstance3D.new();leaves.mesh=tm;n.add_child(leaves);leaves.visibility_range_end=480
    for i in range(170):
        var x:=rng.randf_range(-400,400);var z:=center+rng.randf_range(-900,900)
        if absf(x)<23 or (leg==1 and AssetLibrary.clear_area(Vector3(x,0,z))):continue
        var n:=ellipsoid(p,Vector3(x,height_at(x,z)+0.3,z),Vector3(rng.randf_range(1,4),rng.randf_range(0.6,2),rng.randf_range(1,3)),"rock")
        n.rotation.y=rng.randf()*TAU;n.visibility_range_end=250

static func dress_world(p: Node3D,leg: int,center: float) -> void:
    for side in [-1,1]: box(p,Vector3(side*6,0.013,center),Vector3(3,0.024,1850),"dirt")
    if leg==1:
        box(p,Vector3(29,0.019,-86),Vector3(46,0.024,5),"dirt")
        box(p,Vector3(-54,0.019,-143),Vector3(100,0.024,5),"dirt")
    terrain(p,center)
    foliage(p,center,leg)
    for i in range(36):
        var z:=center+875-i*50
        pole(p,Vector3(23,0,z))
        if i<35:
            for x in [-1.8,0,1.8]: cable(p,Vector3(23+x,11.5,z),Vector3(23+x,11.5,z-50),1.3)
    if leg==1:
        camp(p)
        for i in range(6): solar(p,Vector3(90+(i%3)*2.3,0,-421-floor(i/3.0)*3.5))
        substation(p,Vector3(155,0,-746))
        shed(p,Vector3(166,0,-778),"RELAY / AUTHORIZED PERSONNEL")
        for x in [-4,4]: tube(p,Vector3(166+x,0,-779),Vector3(166+x,15,-779),0.12,"steel")
        box(p,Vector3(166,14.4,-779),Vector3(9,0.15,3),"steel",true)
        # Stranded electric utility vehicle.
        var ev:=group(p,Vector3(-85,0,-287))
        box(ev,Vector3(0,0.85,0),Vector3(1.9,0.65,4.1),"rust",true)
        box(ev,Vector3(0,1.43,0.4),Vector3(1.7,0.7,2.1),"dark")
        box(ev,Vector3(0,1.49,-0.68),Vector3(1.52,0.52,0.04),"glass")
        for x in [-0.96,0.96]:
            for z in [-1.3,1.3]: tire(ev,Vector3(x,0.46,z),0.43)
    for settlement in Session.content.settlements:
        if int(settlement.leg)==leg: shed(p,Vector3(settlement.x,0,settlement.z-10),settlement.name)

static func terrain(p: Node3D,center: float) -> void:
    # Flat mission corridor transitions to rideable undulating shoulders and hills.
    var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for iz in range(100):
        for ix in range(70):
            var x: float=-700+ix*20;var z: float=center-1000+iz*20
            var a:=Vector3(x,height_at(x,z),z)
            var b:=Vector3(x+20,height_at(x+20,z),z)
            var c:=Vector3(x,height_at(x,z+20),z+20)
            var d:=Vector3(x+20,height_at(x+20,z+20),z+20)
            for v in [a,b,c,b,d,c]:st.add_vertex(v)
    st.generate_normals()
    var m:=st.commit();var n:=mesh(p,m,Vector3.ZERO,"ground",true)
    n.name="RideableTerrain"
static func height_at(x: float,z: float) -> float:
    var edge:=smoothstep(185.0,400.0,absf(x))
    return -0.025+edge*(26+sin(x*0.021+z*0.003)*12+cos(z*0.019)*10+sin(x*0.037-z*0.013)*4)

static func batch_static(root: Node3D,visibility_end: float=STATIC_VISIBILITY_RANGE,cell_size: float=STATIC_CELL_SIZE) -> void:
    var buckets: Dictionary={}
    var pending: Array[Node]=[root]
    var remove: Array[Node]=[]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        if node.is_in_group("field_npcs") or node.is_in_group("pack_assets"): continue
        for child in node.get_children(): pending.append(child)
        if not node is MeshInstance3D or node.name=="RideableTerrain":continue
        var source: MeshInstance3D=node
        if source.mesh==null:continue
        var transform_: Transform3D=root.global_transform.affine_inverse()*source.global_transform
        var bounds: AABB=transform_*source.mesh.get_aabb()
        # Roads, terrain slabs and other macro geometry should keep their own AABB.
        if bounds.size.x>cell_size*1.5 or bounds.size.z>cell_size*1.5:continue
        var cell:=Vector2i(floori(bounds.get_center().x/cell_size),floori(bounds.get_center().z/cell_size))
        var cell_origin:=Vector3((cell.x+.5)*cell_size,0,(cell.y+.5)*cell_size)
        transform_.origin-=cell_origin
        var source_range:=visibility_end if source.visibility_range_end<=0 else minf(visibility_end,source.visibility_range_end)
        var appended:=false
        for surface in range(source.mesh.get_surface_count()):
            var material: Material=source.material_override if source.material_override else source.mesh.surface_get_material(surface)
            if material==null:continue
            var key: String=str(material.get_instance_id())+":"+str(cell)
            if not buckets.has(key):
                var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
                buckets[key]={"st":st,"material":material,"cell":cell,"origin":cell_origin,"sources":0,"shadow":source.cast_shadow,"range":source_range}
            buckets[key].st.append_from(source.mesh,surface,transform_)
            buckets[key].sources+=1;appended=true
            buckets[key].range=maxf(buckets[key].range,source_range)
            if source.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:buckets[key].shadow=source.cast_shadow
        if not appended:continue
        for child in source.get_children():
            if child is StaticBody3D: child.reparent(root,true)
        remove.append(source)
    for key in buckets:
        var bucket: Dictionary=buckets[key];var cell: Vector2i=bucket.cell
        var n:=MeshInstance3D.new();n.name="StaticCell_%d_%d_%s" % [cell.x,cell.y,str(bucket.material.get_instance_id())]
        n.mesh=bucket.st.commit();n.material_override=bucket.material;n.position=bucket.origin;n.cast_shadow=bucket.shadow
        n.visibility_range_end=bucket.range;n.visibility_range_end_margin=minf(40,bucket.range*.1);n.set_meta("source_surfaces",bucket.sources);n.add_to_group("static_render_cells")
        root.add_child(n)
    for node in remove: node.queue_free()

static func barrel(p: Node3D,pos: Vector3) -> void:
    AssetLibrary.make(p,"GR_WaterBarrel_02",pos)

static func pallet(p: Node3D,pos: Vector3) -> void:
    for x in [-0.5,0,0.5]:box(p,pos+Vector3(x,0.1,0),Vector3(0.1,0.2,1.1),"wood")
    for z in range(6):box(p,pos+Vector3(0,0.22,-0.5+z*0.2),Vector3(1.2,0.055,0.14),"wood")
static func salvage(p: Node3D,pos: Vector3,kind: String) -> void:
    var n:=group(p,pos)
    crate(n)
    match kind:
        "garage":
            tire(n,Vector3(0.8,0.35,-0.3),0.35)
            tube(n,Vector3(-0.7,0.2,0),Vector3(-0.7,0.2,-0.5),0.22,"dark")
            pallet(n,Vector3(0,0,-1.0))
        "electrical":
            box(n,Vector3(0.9,0.5,-0.25),Vector3(0.5,1,0.45),"steel")
            for i in range(5):box(n,Vector3(0.9,0.26+i*0.1,-0.015),Vector3(0.37,0.025,0.03),"dark")
            cable(n,Vector3(0.8,0.05,0.1),Vector3(-0.7,0.05,0.8),0)
        "industrial":
            barrel(n,Vector3(-0.9,0,0))
            for i in range(3):tube(n,Vector3(0.7+i*0.16,0.12,-0.7),Vector3(0.7+i*0.16,0.12,0.7),0.07,"rust")
        _:
            box(n,Vector3(-0.65,0.21,0),Vector3(0.3,0.42,0.33),"steel")
            box(n,Vector3(-0.65,0.43,0),Vector3(0.24,0.02,0.08),"dark")
            for i in range(3):tube(n,Vector3(0.7+i*0.14,0,0),Vector3(0.7+i*0.14,0.19,0),0.055,"glass")
