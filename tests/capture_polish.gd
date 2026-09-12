extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func run() -> void:
    await process_frame
    var s=root.get_node("Session");s.reset()
    game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
    for i in range(12):await process_frame
    game.set_physics_process(false)
    game.message="";game.field_hud.previous_message="";game.field_hud.toast_left=0
    game.camera.position=Vector3(58,2.3,-86);game.camera.look_at(Vector3(53,1.5,-106));game.camera.fov=75
    game.refresh_hud();await capture("walk")
    s.state.mode="bike";game.speed=8;game.refresh_hud()
    game.camera.position=Vector3(58,2.0,-114);game.camera.look_at(Vector3(71,1.8,-138))
    await capture("bike")
    s.state.mode="drone";s.state.drone_mode="MANUAL";game.drone.position=Vector3(62,3,-124)
    game.camera.position=Vector3(60,3.1,-122);game.camera.look_at(Vector3(72,2.8,-141));game.refresh_hud()
    await capture("drone")
    s.state.mode="foot";s.state.drone_mode="DOCK";game.close_panel();game.refresh_hud()
    game.camera.position=Vector3(83,12,-120);game.camera.look_at(Vector3(58,0,-160));await capture("loop")
    game.pilot.position=Vector3(49.5,1,-100);s.state.inv.merge({"wire":3,"fuel":1,"water":1,"bandage":2,"multimeter":1},true)
    game.inventory();await capture("inventory")
    game.polish.record_panel();await capture("record")
    game.close_panel();game.pilot.position=Vector3(54,1,-88)
    var model=load("res://art/human_visual.gd").make(game.world,Vector3(55,0,-82),true);model.rotation.y=PI
    game.camera.position=Vector3(55,1.65,-79);game.camera.look_at(Vector3(55,1.45,-82));game.camera.fov=45
    await capture("human")
    print("RENDER METRICS: nodes=",get_node_count()," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
    game.queue_free();await process_frame;quit()
func capture(title: String) -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    var folder:=ProjectSettings.globalize_path("res://docs/polish-screenshots")
    DirAccess.make_dir_recursive_absolute(folder)
    root.get_texture().get_image().save_png(folder+"/"+title+".png")
    print("CAPTURE ",title)
