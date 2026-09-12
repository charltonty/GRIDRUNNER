extends SceneTree
var checks:=0
var failures:=0
var g
var s
func _initialize() -> void:run.call_deferred()
func check(ok: bool,title: String) -> void:
    checks+=1
    if ok:print("PASS: ",title)
    else:failures+=1;push_error(title)
func frames(n: int) -> void:
    for i in range(n):await physics_frame
func walk(target: Vector3) -> bool:
    for i in range(300):
        var delta: Vector3=target-g.pilot.position;delta.y=0
        if delta.length()<.35:return true
        g.traversal.update(g.pilot,1.0/60,delta.normalized(),false,false,false,0)
        await physics_frame
    print("STUCK ",g.pilot.position," TARGET ",target)
    for i in range(g.pilot.get_slide_collision_count()):
        var c=g.pilot.get_slide_collision(i);print("CONTACT ",c.get_collider().get_path()," ",c.get_position()," ",c.get_normal())
    return false
func run() -> void:
    await process_frame;s=root.get_node("Session");s.reset();s.save_path="user://asset_integration_regression.json"
    g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await frames(10);g.set_physics_process(false)
    check(g.world.has_node("IntegratedPackWorld"),"Integrated world present")
    var sources: Dictionary={};var count:=0
    for n in get_nodes_in_group("pack_assets"):count+=1;sources[n.get_meta("pack_id")]=true
    check(count>90,"More than ninety world instances")
    for id in ["GR_DistributionCabinet_01","GR_Workbench_02","GR_CreekSign_03","GR_SalvagedMotor_04","GR05_03_TexasHouse"]:check(sources.has(id),"Live world uses "+id)
    for b in AssetLibrary.BUILDINGS:
        g.pilot.position=b.pos+Basis(Vector3.UP,b.yaw)*Vector3(0,1,b.depth/2+4);g.pilot.velocity=Vector3.ZERO;g.traversal=FieldTraversal.new();await frames(2)
        check(await walk(b.pos+Vector3(0,1,4 if "TexasHouse" in b.id else 0)),"Walk through entrance / "+b.title)
        check(g.pilot.position.y>.98,"Interior floor / "+b.title)
    g.pilot.position=Vector3(109.42,1.1,-265.4);g.pilot.velocity=Vector3.ZERO;g.traversal=FieldTraversal.new();await frames(3)
    check(await walk(Vector3(109.42,4.3,-271.8)),"Climb twenty house stair treads")
    check(g.pilot.position.y>4.1,"Player physically reaches upper floor")
    var entry: Dictionary=g.asset_pass.doors.values()[0];var id: String=g.asset_pass.doors.keys()[0]
    g.pilot.position=entry.node.global_position+Vector3(2,1,0);s.state.mode="foot";var initial: bool=entry.opened
    g.asset_pass.interact(id);check(entry.opened!=initial,"Door hinge interaction")
    check(s.state.polish.gates[id]==entry.opened,"Door state stored")
    var locked_key:=""
    for key in g.asset_pass.doors:
        if g.asset_pass.doors[key].data.locked:locked_key=key;break
    s.state.inv.erase("screwdriver");g.asset_pass.interact(locked_key)
    check(not s.state.polish.gates.has(locked_key+"/unlatched"),"Seized latch requires tool")
    s.state.inv.screwdriver=1;g.asset_pass.interact(locked_key)
    check(s.state.polish.gates.get(locked_key+"/unlatched",false),"Screwdriver releases latch")
    for key in g.asset_pass.CACHES:
        s.state.inv={"screwdriver":1};g.asset_pass.interact("cache/"+key)
        check("architecture/"+key in s.state.polish.discoveries,"Building cache / "+key)
        var before: String=JSON.stringify(s.state.inv);g.asset_pass.interact("cache/"+key)
        check(before==JSON.stringify(s.state.inv),"No duplicate reward / "+key)
    s.save_game();check(s.load_game(),"Asset save accepted")
    g.build_world();await frames(3)
    check(g.asset_pass.doors[id].opened==s.state.polish.gates[id],"Door pose restored")
    check("architecture/pump" in s.state.polish.discoveries,"Salvage persists")
    print("ASSET CHECKS: ",checks," / FAILURES: ",failures)
    g.queue_free();await process_frame;quit(failures)
