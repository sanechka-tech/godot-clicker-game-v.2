extends CharacterBody2D

const FLIPPED_ANIMATION := &"moves_left"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_update_animation_flip()
	animated_sprite.animation_changed.connect(_on_animation_changed)


func _on_animation_changed() -> void:
	_update_animation_flip()


func _update_animation_flip() -> void:
	if animated_sprite == null:
		return

	animated_sprite.flip_h = animated_sprite.animation == FLIPPED_ANIMATION
