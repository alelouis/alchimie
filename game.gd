extends Node

const MASTER_BUS = "Master"

var elements_gained = {}
var music_playing = true
var is_muted = false
var can_reset = true
@onready var music_player = $AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var music = load("res://assets/alchimie2.wav")
	music_player.stream.loop_mode = 1
	music_player.stream.loop_begin = 0  # Start of the loop
	music_player.stream.loop_end = music.data.size()  # End of the loop
	music_player.play()
	toggle_mute()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_node_2d_element_gained(element_value) -> void:
	if elements_gained.has(element_value):
		elements_gained[element_value] += 1
	else:
		elements_gained[element_value] = 1
	$Sidebar.change_label(element_value, elements_gained[element_value])


func _on_music_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if music_playing:
				music_player.stop()
				music_playing = false
			else:
				music_player.play()
				music_playing = true


func _on_mute_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle_mute()

func mute_all():
	is_muted = true
	var master_index = AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_mute(master_index, true)

func unmute_all():
	is_muted = false
	var master_index = AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_mute(master_index, false)


func toggle_mute():
	if is_muted:
		unmute_all()
	else:
		mute_all()


func _on_restart_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_reset:
				can_reset = false
				await $Node2D.reset()
				for element_value in elements_gained.keys():
					if elements_gained[element_value] != 0: 
						elements_gained[element_value] = 0
						$Sidebar.change_label(element_value, elements_gained[element_value])
				can_reset = true
