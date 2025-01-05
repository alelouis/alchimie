extends Sprite2D

# Set these values in the Inspector or via code
@export var sprite_columns = 4  # Number of columns in your sprite sheet
@export var sprite_rows = 4     # Number of rows in your sprite sheet

func _ready():
	# Setup the sprite sheet
	# This assumes your node is already a Sprite2D with a texture assigned
	
	# Calculate frame size based on texture size and number of frames
	var texture_size = texture.get_size()
	var frame_width = texture_size.x / sprite_columns
	var frame_height = texture_size.y / sprite_rows
	
	# Setup texture properties
	hframes = sprite_columns  # Set number of horizontal frames
	vframes = sprite_rows     # Set number of vertical frames
	
	# Start with the first frame
	frame = 0

# Function to change to a specific frame
func change_frame(frame_number: int) -> void:
	# Ensure frame number is valid
	var total_frames = sprite_columns * sprite_rows
	frame = frame_number % total_frames

# Example function to change to a specific frame by row and column
func set_frame_by_position(row: int, column: int) -> void:
	var frame_number = (row * sprite_columns) + column
	change_frame(frame_number)

# Example: Cycle through all frames
func cycle_frames() -> void:
	var next_frame = (frame + 1) % (sprite_columns * sprite_rows)
	change_frame(next_frame)
