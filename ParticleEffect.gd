# ParticleEffect.gd
extends GPUParticles2D

func _ready():
	# Start emitting particles
	emitting = true
	await get_tree().create_timer(lifetime).timeout
	queue_free()
