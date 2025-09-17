extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var hpbar = $hpbar  # only this node is lowercase

var speed = 100
var direction = Vector2.LEFT
var health = 3
var is_hit = false
var hit_timer = 0.0
var hit_duration = 0.5

func _ready():
	update_hp_bar()

func _physics_process(delta):
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
			anim.play("fly")
		return

	# Move left and right
	velocity.x = speed * direction.x
	move_and_slide()

	# Patrol between x=100 and x=500
	if position.x < 100:
		direction = Vector2.RIGHT
	elif position.x > 500:
		direction = Vector2.LEFT

	# Flip sprite based on direction
	anim.flip_h = direction.x > 0

	# Play fly animation
	if anim.animation != "fly":
		anim.play("fly")


func take_hit():
	health -= 1
	update_hp_bar()
	if health <= 0:
		queue_free()
	else:
		is_hit = true
		hit_timer = hit_duration
		anim.play("hit")
		velocity = Vector2.ZERO

func update_hp_bar():
	if hpbar:
		hpbar.max_value = 3
		hpbar.value = health
