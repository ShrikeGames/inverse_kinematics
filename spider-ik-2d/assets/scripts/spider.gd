extends CharacterBody2D
class_name Spider

@export var front_check: RayCast2D
@export var low_mid_check: RayCast2D
@export var high_mid_check: RayCast2D
@export var back_check: RayCast2D
@export var forward_check: RayCast2D

@export var front_legs_node: Node2D
var front_legs: Array
@export var back_legs_node: Node2D
var back_legs: Array

@export var move_to_mouse: bool = true
@export var move_speed: float = 60
@export var x_speed: float = 60
@export var y_speed: float = 120

@export var step_rate: float = 0.2
@export var high_check_distance: float = 86
@export var low_check_distance: float = 24
@export var front_check_distance: float = 128
@export var back_check_distance: float = -8

var time_since_last_step: float = 0
var current_front_leg: int = 0
var current_back_leg: int = 0
var use_front = false

func _on_ready() -> void:
	front_legs = front_legs_node.get_children()
	back_legs = back_legs_node.get_children()
	high_mid_check.target_position.y = high_check_distance
	low_mid_check.target_position.y = low_check_distance
	front_check.position.x = front_check_distance
	back_check.position.x = back_check_distance
	
	forward_check.position.y = high_check_distance
	
	front_check.force_raycast_update()
	back_check.force_raycast_update()
	forward_check.force_raycast_update()
	
	# iterate over it multiple times so it can converge
	for i in range(32):
		step()

func _physics_process(delta: float) -> void:
	var move_vec: Vector2 = Vector2(x_speed, 0)
	if move_to_mouse:
		var mouse_pos: Vector2 = get_global_mouse_position()
		move_vec = (mouse_pos - global_position).normalized() * move_speed
	
	if move_vec.x >= 0:
		front_check.position.x = front_check_distance
		back_check.position.x = back_check_distance
	else:
		front_check.position.x = - back_check_distance
		back_check.position.x = - front_check_distance
	
	if high_mid_check.is_colliding() or forward_check.is_colliding():
		move_vec.y = - y_speed
	elif not low_mid_check.is_colliding():
		move_vec.y = y_speed
	if forward_check.is_colliding():
		move_vec.x *= 0.5
	
	move_and_collide(move_vec * delta)

func _process(delta: float):
	time_since_last_step += delta
	if time_since_last_step >= step_rate:
		time_since_last_step = 0
		if move_to_mouse:
			var mouse_pos: Vector2 = get_global_mouse_position()
			if mouse_pos.distance_to(global_position) < move_speed:
				return
		step()
		
func step():
	var leg: Node2D = null
	var sensor: RayCast2D = null
	
	if use_front:
		leg = front_legs[current_front_leg]
		current_front_leg += 1
		current_front_leg %= front_legs.size()
		sensor = front_check
	else:
		leg = back_legs[current_back_leg]
		current_back_leg += 1
		current_back_leg %= back_legs.size()
		sensor = back_check
		
	use_front = not use_front
	var target = sensor.get_collision_point()
	# leg assumed to be a Leg object
	leg.step(target)
