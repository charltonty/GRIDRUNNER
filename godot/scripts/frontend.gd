extends Control

@onready var main_panel: Control = $MainPanel
@onready var new_game_panel: Control = $NewGamePanel
@onready var settings_panel: Control = $SettingsPanel
@onready var status: Label = $Status

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    show_main()

func show_main() -> void:
    main_panel.visible = true
    new_game_panel.visible = false
    settings_panel.visible = false
    status.text = "BLACK CREEK FRONTIER // LINK OFFLINE"

func _on_continue_pressed() -> void:
    if FileAccess.file_exists("user://gridrunner_save.json"):
        get_tree().change_scene_to_file("res://scenes/main.tscn")
    else:
        status.text = "NO EXPEDITION SAVE FOUND"

func _on_new_game_pressed() -> void:
    main_panel.visible = false
    new_game_panel.visible = true

func _on_start_standard_pressed() -> void:
    var save := FileAccess.open("user://gridrunner_save.json", FileAccess.WRITE)
    save.store_string(JSON.stringify({"difficulty":"standard","region":"black_creek","tutorial":true}))
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
    main_panel.visible = false
    settings_panel.visible = true

func _on_back_pressed() -> void:
    show_main()

func _on_quit_pressed() -> void:
    get_tree().quit()
