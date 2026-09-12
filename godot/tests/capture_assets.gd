extends SceneTree
var game
func _initialize() -> void:run.call_deferred()
func run() -> void:
    await process_frame
    var s=root.get_node("Session");s.reset();game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
    for i in range(12):await process_frame
    game.set_physics_process(false);game.close_panel();game.message="";game.field_hud.toast_left=0
    for view in [
 ["camp",Vector3(58,2.2,-89),Vector3(52,1.1,-102)],
 ["workbench",Vector3(48,1.9,-97),Vector3(49.6,1.0,-100)],
 ["store",Vector3(-10,2.3,-142),Vector3(-23,1.6,-154)],
 ["utility_interior",Vector3(18,1.85,-195.5),Vector3(18,1.5,-201)],
 ["house",Vector3(94,3,-253),Vector3(105,2.3,-269)],
 ["house_upstairs",Vector3(109,5,-272),Vector3(102,4.7,-270)],
 ["workshop",Vector3(39,3,-223),Vector3(48,2,-236)],
 ["pump",Vector3(91,2.8,-196),Vector3(101,1.6,-208)],
 ["route_overview",Vector3(30,24,-170),Vector3(61,0,-214)]]:
        game.camera.position=view[1];game.camera.look_at(view[2]);game.camera.fov=70;game.refresh_hud();await capture(view[0])
    print("RENDER METRICS draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
    game.queue_free();await process_frame;quit()
func capture(title: String) -> void:
    for i in range(4):await process_frame
    await RenderingServer.frame_post_draw
    var folder:=ProjectSettings.globalize_path("res://docs/asset-screenshots")
    DirAccess.make_dir_recursive_absolute(folder);root.get_texture().get_image().save_png(folder+"/"+title+".png");print("CAPTURE ",title)
