class_name OpponentDisconnectedUI
extends Control

@onready var return_to_connection_button: Button = $CenterContainer2/ReturnToConnectionButton
const CONNECT_CLIENT_UI = preload("uid://doidx1hat37mv")

func _ready() -> void:
	return_to_connection_button.pressed.connect(func():
		get_tree().change_scene_to_packed(CONNECT_CLIENT_UI)
	)
