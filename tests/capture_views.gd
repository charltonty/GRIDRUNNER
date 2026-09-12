extends SceneTree
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    await process_frame
    var session:=root.get_node("Session")
    session.reset()
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    for i in range(12):await process_frame
    game.set_physics_process(false)
    game.camera.position=Vector3(58,2.3,-86)
    game.camera.look_at(Vector3(53,1.6,-106))
    game.camera.fov=65
    await capture("camp")
    for child in game.get_children():
        if child is CanvasLayer: child.hide()
    game.bike.visible=true
    game.bike.position=Vector3(48,0.56,-83)
    game.trailer.position=Vector3(48,0,-79.5)
    game.camera.position=Vector3(51,2.0,-86)
    game.camera.look_at(Vector3(48,0.9,-82.5))
    game.camera.fov=65
    await capture("bike")
    game.drone.visible=true;game.drone.position=Vector3(48,2,-85)
    game.camera.position=Vector3(49.5,2.8,-87)
    game.camera.look_at(Vector3(48,2,-85))
    await capture("drone")
    game.camera.position=Vector3(133,8,-715)
    game.camera.look_at(Vector3(157,3,-752))
    await capture("substation")
    for child in game.get_children():
        if child is CanvasLayer:child.show()
    game.pilot.position=Vector3(49.5,1,-100)
    session.state.inv.merge({"wire":3,"battery_module":1,"fuel":1,"multimeter":1,"propeller":2,"bandage":2,"water":1},true)
    game.inventory()
    await capture("backpack")
    game.slice02.module_panel()
    await capture("modules")
    game.close_panel()
    game.camera.position=Vector3(18,3,-168)
    game.camera.look_at(Vector3(11,1,-181))
    await capture("corridor")
    game.queue_free()
    for i in range(3):await process_frame
    var menu=load("res://scenes/frontend.tscn").instantiate()
    root.add_child(menu)
    await capture("menu")
    menu.queue_free()
    for i in range(3):await process_frame
    quit()
func capture(title: String) -> void:
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    var folder:=ProjectSettings.globalize_path("res://docs/screenshots")
    DirAccess.make_dir_recursive_absolute(folder)
    root.get_texture().get_image().save_png(folder+"/"+title+".png")
    print("CAPTURE ",title)
