extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/EndlessMode2D.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
