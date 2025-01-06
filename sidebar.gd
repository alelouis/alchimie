extends Control

@onready var element_scene = preload("res://element.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer.add_theme_constant_override("separation", 200)
	add_elements()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_elements():
	for element_value in range(8):
		var element_instance = element_scene.instantiate()
		element_instance.element_value = element_value
		$VBoxContainer.add_child(element_instance)
