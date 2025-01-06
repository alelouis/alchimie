extends Node

var elements_gained = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_node_2d_element_gained(element_value) -> void:
	if elements_gained.has(element_value):
		elements_gained[element_value] += 1
	else:
		elements_gained[element_value] = 1
	$Sidebar.change_label(element_value, elements_gained[element_value])
