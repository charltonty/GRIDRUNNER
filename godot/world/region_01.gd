class_name Region01
extends Node3D

const SITE_DATA := [
    ["START CAMP", Vector3(0, 0, 0)],
    ["MILEPOST 09", Vector3(-55, 0, -180)],
    ["DRY CREEK", Vector3(75, -4, -210)],
    ["REDLINE SALVAGE", Vector3(-115, 2, -330)],
    ["QUARRY CUT", Vector3(95, 5, -390)],
    ["BLACK CREEK SUBSTATION", Vector3(0, 3, -480)],
    ["RELAY HILL", Vector3(35, 8, -560)]
]

func _ready() -> void:
    _build_road()
    _build_power_line()
    _build_site_markers()

func _box(parent: Node3D, name_: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_
    var mesh := BoxMesh.new()
    mesh.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    mesh.material = mat
    node.mesh = mesh
    node.position = pos
    parent.add_child(node)
    return node

func _build_road() -> void:
    var roads := Node3D.new()
    roads.name = "RoadNetwork"
    add_child(roads)
    _box(roads, "CountyRoad", Vector3(0, -0.08, -285), Vector3(8, 0.16, 570), Color(0.12,0.12,0.11))
    _box(roads, "MilepostSpur", Vector3(-28, -0.04, -180), Vector3(56, 0.08, 5), Color(0.16,0.14,0.11))
    _box(roads, "SubstationSpur", Vector3(18, 2.9, -480), Vector3(36, 0.08, 5), Color(0.16,0.14,0.11))

func _build_power_line() -> void:
    var infra := Node3D.new()
    infra.name = "Infrastructure"
    add_child(infra)
    for i in range(11):
        var z := -40.0 - float(i) * 50.0
        var x := -14.0 if i % 3 != 0 else -18.0
        _box(infra, "Pole_%02d" % i, Vector3(x, 4.2, z), Vector3(0.32, 8.4, 0.32), Color(0.22,0.15,0.09))
        _box(infra, "Crossarm_%02d" % i, Vector3(x, 7.7, z), Vector3(4.2, 0.22, 0.22), Color(0.20,0.14,0.08))

func _build_site_markers() -> void:
    var sites := Node3D.new()
    sites.name = "Sites"
    add_child(sites)
    for site in SITE_DATA:
        var root := Node3D.new()
        root.name = String(site[0]).replace(" ", "_")
        root.position = site[1]
        sites.add_child(root)
        _box(root, "Placeholder", Vector3(0, 1.5, 0), Vector3(8, 3, 8), Color(0.28,0.25,0.20))
