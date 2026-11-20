extends Control
## Generic menu screen: styles its headline and reveals its parts.

@export var title_label: Label
@export var title_size: int = 36
@export var reveal_nodes: Array[Control] = []

func _ready() -> void:
	if title_label:
		Metro.style_title(title_label, title_size)
	Metro.reveal.call_deferred(reveal_nodes, 0.45)
