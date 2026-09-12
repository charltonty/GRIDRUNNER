@tool
extends EditorScript

# Run from Godot's Script Editor with File > Run.
# Generates reusable starter .tscn assets entirely from native Godot geometry.

const OUT := "res://assets/generated/"

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    make_crate()
    make_barrel()
    make_concrete_barrier()
    make_electrical_cabinet()
    make_utility_pole()
    make_pallet()
    print("GRIDRUNNER starter assets generated in ", OUT)

func mat(color: Color, metallic := 0.0, roughness := 0.85) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

func box(parent: Node3D, name: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    parent.add_child(n)
    n.owner = parent
    return n

func cylinder(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    n.mesh = mesh
    n.position = pos
    n.material_override = material
    parent.add_child(n)
    n.owner = parent
    return n

func collision_box(parent: Node3D, size: Vector3, pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = "Collision"
    parent.add_child(body)
    body.owner = parent
    var c := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    c.shape = shape
    c.position = pos
    body.add_child(c)
    c.owner = parent

func save(root: Node3D, filename: String) -> void:
    var packed := PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, OUT + filename)

func make_crate() -> void:
    var r := Node3D.new(); r.name = "GR_WoodCrate_A"
    var wood := mat(Color("6d5135"))
    box(r,"Body",Vector3(0.9,0.7,0.75),Vector3(0,0.35,0),wood)
    for y in [0.08,0.62]:
        box(r,"Band",Vector3(0.98,0.08,0.82),Vector3(0,y,0),mat(Color("4a3524")))
    collision_box(r,Vector3(0.9,0.7,0.75),Vector3(0,0.35,0)); save(r,"gr_prop_wood_crate_a.tscn")

func make_barrel() -> void:
    var r := Node3D.new(); r.name = "GR_OilDrum_A"
    var rust := mat(Color("6b3324"),0.65,0.72)
    cylinder(r,"Drum",0.29,0.88,Vector3(0,0.44,0),rust)
    cylinder(r,"TopBand",0.305,0.035,Vector3(0,0.84,0),mat(Color("393d3c"),0.8,0.5))
    cylinder(r,"BottomBand",0.305,0.035,Vector3(0,0.05,0),mat(Color("393d3c"),0.8,0.5))
    collision_box(r,Vector3(0.58,0.88,0.58),Vector3(0,0.44,0)); save(r,"gr_prop_oil_drum_a.tscn")

func make_concrete_barrier() -> void:
    var r := Node3D.new(); r.name = "GR_ConcreteBarrier_A"
    box(r,"Barrier",Vector3(2.4,0.8,0.5),Vector3(0,0.4,0),mat(Color("77766f"),0.0,1.0))
    box(r,"Foot",Vector3(2.6,0.18,0.8),Vector3(0,0.09,0),mat(Color("66655f"),0.0,1.0))
    collision_box(r,Vector3(2.4,0.8,0.5),Vector3(0,0.4,0)); save(r,"gr_road_concrete_barrier_a.tscn")

func make_electrical_cabinet() -> void:
    var r := Node3D.new(); r.name = "GR_ElectricalCabinet_A"
    var metal := mat(Color("66706c"),0.75,0.55)
    box(r,"Cabinet",Vector3(1.1,1.55,0.5),Vector3(0,0.775,0),metal)
    box(r,"DoorInset",Vector3(0.94,1.28,0.025),Vector3(0,0.78,-0.263),mat(Color("58615d"),0.7,0.6))
    box(r,"Handle",Vector3(0.04,0.22,0.05),Vector3(0.37,0.78,-0.30),mat(Color("222625"),0.9,0.35))
    collision_box(r,Vector3(1.1,1.55,0.5),Vector3(0,0.775,0)); save(r,"gr_power_electrical_cabinet_a.tscn")

func make_utility_pole() -> void:
    var r := Node3D.new(); r.name = "GR_UtilityPole_A"
    var wood := mat(Color("4c3a2a"),0.0,0.95)
    cylinder(r,"Pole",0.14,8.5,Vector3(0,4.25,0),wood)
    box(r,"Crossarm",Vector3(2.8,0.16,0.18),Vector3(0,7.5,0),wood)
    var ceramic := mat(Color("d7d0b9"),0.05,0.35)
    for x in [-1.05,0.0,1.05]: cylinder(r,"Insulator",0.09,0.34,Vector3(x,7.77,0),ceramic)
    collision_box(r,Vector3(0.28,8.5,0.28),Vector3(0,4.25,0)); save(r,"gr_power_utility_pole_a.tscn")

func make_pallet() -> void:
    var r := Node3D.new(); r.name = "GR_Pallet_A"
    var wood := mat(Color("8a6844"),0.0,0.95)
    for z in [-0.45,-0.225,0.0,0.225,0.45]: box(r,"Slat",Vector3(1.2,0.08,0.16),Vector3(0,0.16,z),wood)
    for x in [-0.48,0.0,0.48]: box(r,"Runner",Vector3(0.13,0.14,1.05),Vector3(x,0.07,0),wood)
    collision_box(r,Vector3(1.2,0.24,1.05),Vector3(0,0.12,0)); save(r,"gr_prop_pallet_a.tscn")
