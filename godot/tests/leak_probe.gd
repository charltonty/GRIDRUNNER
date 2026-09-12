extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
    await process_frame
    var g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
    for i in range(5):await process_frame
    g.queue_free()
    for i in range(5):await process_frame
    quit()
