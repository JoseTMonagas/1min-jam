extends Control

func _ready() -> void:
	$DifficultySelector.visible = false
	


func _on_CreditsButton_pressed() -> void:
	get_tree().change_scene("res://src/Credits.tscn")


func _on_ExitButton_pressed() -> void:
	get_tree().quit(0)


func _on_StartButton_pressed() -> void:
	$VBoxContainer.visible = false
	$DifficultySelector.visible = true


func _on_Easy_pressed():
	Singleton.action_limit = Singleton.DIFFICULTY_LEVELS.EASY
	get_tree().change_scene("res://src/Escape.tscn")


func _on_Normal_pressed():
	Singleton.action_limit = Singleton.DIFFICULTY_LEVELS.MEDIUM
	get_tree().change_scene("res://src/Escape.tscn")

func _on_Hard_pressed():
	Singleton.action_limit = Singleton.DIFFICULTY_LEVELS.HARD
	Singleton.quantum_on = true
	get_tree().change_scene("res://src/Escape.tscn")
