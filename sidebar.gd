extends Control

@onready var element_scene = preload("res://element.tscn")

var labels = {}
var elements = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_elements()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_label(element_value, element_count):
	labels[element_value].text = str(element_count) + " "
	var tween = create_tween()
	tween.tween_property(elements[element_value], "rotation", deg_to_rad(10), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(elements[element_value], "rotation", deg_to_rad(0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	

func add_elements():
	var panels = []
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.2)
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_right = 20
	
	for element_value in range(7):

		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(200, 30)
		panel.add_theme_stylebox_override("panel", style)
		panel.show_behind_parent = true
		panel.z_index = element_value
		panels.append(panel)
		
		$VFlowContainer/VBoxContainer.add_child(panels[element_value])
		
		var panel_sep = Panel.new()
		panel_sep.custom_minimum_size = Vector2(230, 100)
		panel_sep.layout_direction = Control.LAYOUT_DIRECTION_RTL
		panel_sep.add_theme_stylebox_override("panel", panel_style)
		
		var label = Label.new()
		label.text = "0 "
		label.add_theme_font_size_override("font_size", 64)
		labels[element_value] = label

		panel_sep.add_child(label)
		$VFlowContainer/VBoxContainer.add_child(panel_sep)
		
	for element_value in range(7):
		var element_instance = element_scene.instantiate()
		element_instance.element_value = element_value
		element_instance.z_index = element_value + 2
		elements[element_value] = element_instance
		panels[element_value].add_child(element_instance)
