extends Control

@onready var main_panel: Control = $MainPanel
@onready var new_game_panel: Control = $NewGamePanel
@onready var settings_panel: Control = $SettingsPanel
@onready var status: Label = $Status

func _ready() -> void:
    theme=load("res://systems/field_hud.gd").make_theme()
    build_showcase()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    show_main()
    $MainPanel/Buttons/Load.pressed.connect(_on_continue_pressed)
    $MainPanel/Buttons/FieldManual.pressed.connect(func(): info("Field manual", "WASD move, mouse look, F mount/dismount. P pedals. Q deploy/recall drone. Space rises, Shift descends. R scans. E interacts. H changes camera. 1 follow, 2 hold, 3 return. I Backpack, B drone modules, X payload, L spotlight, Ctrl crouch, G power, M route map, F5 saves. Escape opens menus.

Meet Mara at the starting camp. Restore tools, scavenge energy and activate the rooftop relay. Complete the tower to travel to the Spillway; then reach Black Start. Trader advice stays on the route screen."))
    $MainPanel/Buttons/Accessibility.pressed.connect(func(): info("Accessibility", "All dialogue is text. Reduced motion is available in the expedition pause menu. H cycles close and distant cameras. Audio can be muted in Settings. Native gamepad, touch and rebinding are not implemented yet."))
    $NewGamePanel/Buttons/Explorer.pressed.connect(func(): start_variant(1.4,1.0))
    $NewGamePanel/Buttons/Survival.pressed.connect(func(): start_variant(0.35,0.05))
    $NewGamePanel/Buttons/Custom.disabled=true
    $NewGamePanel/Buttons/Custom.text="CUSTOM / not implemented"
    $SettingsPanel/Buttons/Audio.pressed.connect(func(): Session.volume=fmod(Session.volume+0.2,1.2); status.text="AUDIO %d%%" % int(Session.volume*100))
    $SettingsPanel/Buttons/Display.pressed.connect(func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
    $SettingsPanel/Buttons/Controls.pressed.connect(func(): info("Controls", "WASD · Mouse look · F bike · P pedal · Q drone · Space/Shift altitude · 1/2/3 drone commands · R scan · E use · H camera · I Backpack · B modules · X payload · L light · Ctrl crouch · G power · M route · F5 save · Escape pause"))
    $SettingsPanel/Buttons/Gameplay.pressed.connect(func(): info("Native port", "Three campaign legs, finite salvage and NPC stock. Saves are native to this build; browser saves cannot be imported. Explorer/Survival adjust the initial supplies."))

func show_main() -> void:
    main_panel.visible = true
    new_game_panel.visible = false
    settings_panel.visible = false
    status.text = "BLACK CREEK FRONTIER // LINK OFFLINE"

func _on_continue_pressed() -> void:
    if Session.load_game():
        get_tree().change_scene_to_file("res://scenes/main.tscn")
    else:
        status.text = "NO EXPEDITION SAVE FOUND"

func _on_new_game_pressed() -> void:
    main_panel.visible = false
    new_game_panel.visible = true

func _on_start_standard_pressed() -> void:
    Session.reset()
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
    main_panel.visible = false
    settings_panel.visible = true

func _on_back_pressed() -> void:
    show_main()

func _on_quit_pressed() -> void:
    get_tree().quit()

func info(title: String,body: String) -> void:
    var dialog:=AcceptDialog.new()
    dialog.title=title
    dialog.dialog_text=body
    add_child(dialog)
    dialog.popup_centered(Vector2i(760,380))
    dialog.confirmed.connect(dialog.queue_free)

func start_variant(charge: float,fuel: float) -> void:
    Session.reset()
    Session.state.battery=charge
    Session.state.fuel=fuel
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func build_showcase() -> void:
    var container:=SubViewportContainer.new()
    container.position=Vector2(470,200)
    container.size=Vector2(750,425)
    container.stretch=true
    container.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(container)
    move_child(container,1)
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(750,425)
    viewport.own_world_3d=true
    container.add_child(viewport)
    var scene:=Node3D.new()
    viewport.add_child(scene)
    var environment:=WorldEnvironment.new()
    environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("111a19")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color("b8c5bd")
    environment.environment.ambient_light_energy=0.7
    scene.add_child(environment)
    var light:=DirectionalLight3D.new()
    light.rotation_degrees=Vector3(-45,-35,0)
    light.light_color=Color("ffe2b3")
    light.light_energy=1.0
    light.shadow_enabled=true
    scene.add_child(light)
    FieldKit.box(scene,Vector3(0,-0.1,1),Vector3(10,0.2,12),"dark")
    var machine:=load("res://scenes/props/Bike.tscn").instantiate() as Node3D
    machine.position=Vector3(-0.4,0.56,0)
    scene.add_child(machine)
    var aircraft:=load("res://scenes/props/Drone.tscn").instantiate() as Node3D
    aircraft.position=Vector3(1.1,1.9,0.5)
    aircraft.rotation.y=-0.4
    scene.add_child(aircraft)
    FieldKit.crate(scene,Vector3(1.4,0,2.4))
    var camera:=Camera3D.new()
    scene.add_child(camera)
    camera.position=Vector3(4,2.5,-4.5)
    camera.look_at(Vector3(0,0.9,0.3))
    camera.fov=48
    camera.current=true
