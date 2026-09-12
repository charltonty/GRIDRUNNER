extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
    await process_frame
    var session=root.get_node("Session")
    var viewport:=SubViewport.new();viewport.size=Vector2i(128,128);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.transparent_bg=false;root.add_child(viewport)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("202723");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("ddd8c6");env.environment.ambient_light_energy=.65;viewport.add_child(env)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-30,0);sun.light_energy=1.4;viewport.add_child(sun)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.66;camera.position=Vector3(.65,.6,.8);viewport.add_child(camera);camera.look_at(Vector3(0,.14,0));camera.current=true
    var factory=load("res://art/item_visual.gd")
    var stage:=Node3D.new();viewport.add_child(stage)
    for id in session.content.items:
        var model: Node3D=factory.make(stage,id,session.content.items[id])
        for i in range(2):await process_frame
        await RenderingServer.frame_post_draw
        viewport.get_texture().get_image().save_png("res://assets/icons/items/"+id+".png")
        model.queue_free();await process_frame
    print("ICONS: ",session.content.items.size());quit()
