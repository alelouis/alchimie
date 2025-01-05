extends Node2D


var element_value: int

func _ready():
	$Sprite2D.change_frame(element_value)

func set_element(i):
	element_value = i
	$Sprite2D.change_frame(i)
