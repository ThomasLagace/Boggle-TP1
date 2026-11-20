class_name LostConnectionUI
extends Control

@onready var return_to_connection_button: Button = $CenterContainer2/ReturnToConnectionButton
const CONNECT_CLIENT_UI = preload("uid://doidx1hat37mv")

func _ready() -> void:
	Metro.style_title($CenterContainer/LostConnectionLabel, 36)
	Metro.reveal.call_deferred([$CenterContainer, $CenterContainer2], 0.5, 0.15)
	Metro.chime_reject()
	return_to_connection_button.pressed.connect(func():
		Metro.go_to_packed(CONNECT_CLIENT_UI)
	)
