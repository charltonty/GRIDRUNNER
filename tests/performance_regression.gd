extends SceneTree

var checks:=0
var failures:=0

func _initialize() -> void:
    run.call_deferred()

func check(ok: bool,title: String) -> void:
    checks+=1
    if ok:print("PASS: ",title)
    else:failures+=1;push_error(title)

func run() -> void:
    await process_frame
    var started:=Time.get_ticks_msec()
    var session=root.get_node("Session");session.reset();session.save_path="user://performance_regression.json"
    var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
    for i in range(12):await physics_frame
    game.set_physics_process(false)
    var counts:={"geometry":0,"ranged":0,"multimesh":0,"local_foliage":0,"bounded_foliage":0,"static_bodies":0,"concave":0,"boxes":0,"cylinders":0}
    var cells:=get_nodes_in_group("static_render_cells");var all_cells_ranged:=true
    for node in cells:
        if not node is MeshInstance3D or node.visibility_range_end<=0:all_cells_ranged=false
    var pending: Array[Node]=[game.world]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():pending.append(child)
        if node is GeometryInstance3D:
            counts.geometry+=1
            if node.visibility_range_end>0:counts.ranged+=1
            if node is MultiMeshInstance3D:
                counts.multimesh+=1
                if node.name.begins_with("GrassCell") or node.name.begins_with("GroundCover") or node.name.begins_with("Scrub") or node.name.begins_with("Canopy"):
                    counts.local_foliage+=1
                    if node.position.length()>1 and node.multimesh.custom_aabb.size.length()>0:counts.bounded_foliage+=1
        if node is StaticBody3D:counts.static_bodies+=1
        if node is CollisionShape3D:
            if node.shape is ConcavePolygonShape3D:counts.concave+=1
            elif node.shape is BoxShape3D:counts.boxes+=1
            elif node.shape is CylinderShape3D:counts.cylinders+=1
    print("PERFORMANCE METRICS build_ms=",Time.get_ticks_msec()-started," cells=",cells.size()," geometry=",counts.geometry," ranged=",counts.ranged," multimesh=",counts.multimesh," static_bodies=",counts.static_bodies," concave=",counts.concave," boxes=",counts.boxes," cylinders=",counts.cylinders)
    check(cells.size()>20 and all_cells_ranged,"Static geometry is partitioned into distance-culled render cells")
    check(counts.ranged>counts.geometry/2,"Most geometry has an explicit visibility range")
    check(counts.multimesh>70 and counts.local_foliage==counts.bounded_foliage,"Repeated foliage uses locally bounded MultiMesh chunks")
    check(counts.concave<64 and counts.boxes+counts.cylinders>250,"Procedural collision favors primitive shapes over triangle meshes")
    game.queue_free();await process_frame
    print("PERFORMANCE CHECKS: ",checks," / FAILURES: ",failures)
    quit(1 if failures else 0)
