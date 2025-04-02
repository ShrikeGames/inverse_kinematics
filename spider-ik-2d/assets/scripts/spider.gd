extends CharacterBody2D
class_name Spider

@export var front_check: RayCast2D
@export var back_check: RayCast2D
@export var ground_check: RayCast2D

@export var front_legs_node: Node2D
var front_legs: Array
@export var back_legs_node: Node2D
var back_legs: Array

@export var move_to_mouse: bool = true
@export var move_speed: float = 80
@export var x_speed: float = 60
@export var y_speed: float = 120


@export var step_rate: float = 0.1
@export var ground_check_distance:float = 78
@export var front_check_distance: float = 128
@export var back_check_distance: float = -8

var time_since_last_step: float = 0
var current_front_leg: int = 0
var current_back_leg: int = 0
var use_front = false
func _on_ready() -> void:
	front_legs = front_legs_node.get_children()
	back_legs = back_legs_node.get_children()
	front_check.position.x = front_check_distance
	back_check.position.x = back_check_distance
	ground_check.target_position.y = ground_check_distance
	
	front_check.force_raycast_update()
	back_check.force_raycast_update()
	
	# iterate over it multiple times so it can converge
	for i in range(6):
		step()
	
func _physics_process(delta: float) -> void:
	
	var move_vec: Vector2 = Vector2(x_speed, 0)
	if move_to_mouse:
		var mouse_pos: Vector2 = get_global_mouse_position()
		move_vec = (mouse_pos - global_position).normalized() * move_speed
	
	var leg:Leg = null
	
	if move_vec.x > 0:
		front_check.position.x = front_check_distance
		back_check.position.x = back_check_distance
		if front_legs[current_front_leg].hand.global_position.y > back_legs[current_back_leg].hand.global_position.y:
			# going up
			leg = get_highest_leg()
		else:
			# going down
			leg = get_lowest_leg()
	else:
		front_check.position.x = - back_check_distance
		back_check.position.x = - front_check_distance
		if front_legs[current_front_leg].hand.global_position.y > back_legs[current_back_leg].hand.global_position.y:
			# going down
			leg = get_lowest_leg()
		else:
			# going up
			leg = get_highest_leg()
	if leg and not ground_check.is_colliding():
		if global_position.y > leg.joint1.global_position.y:
			move_vec.y = - y_speed
		elif global_position.y < leg.joint1.global_position.y:
			move_vec.y = y_speed
	elif ground_check.is_colliding():
		move_vec.y = - y_speed
		
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
		current_front_leg = wrapi(current_front_leg+1, 0, front_legs.size())
		sensor = front_check
	else:
		leg = back_legs[current_back_leg]
		current_back_leg = wrapi(current_back_leg+1, 0, back_legs.size())
		sensor = back_check
		
	use_front = not use_front
	var target_pos:Vector2 = sensor.get_collision_point()
	# leg assumed to be a Leg object
	leg.step(target_pos)
	
func get_lowest_leg() -> Leg:
	var lowest_leg:Leg = null
	var lowest_y:float = -INF
	for leg in front_legs:
		if leg.joint1.global_position.y > lowest_y:
			lowest_y = leg.joint1.global_position.y
			lowest_leg = leg
	for leg in back_legs:
		if leg.joint1.global_position.y > lowest_y:
			lowest_y = leg.joint1.global_position.y
			lowest_leg = leg
	return lowest_leg

func get_highest_leg() -> Leg:
	var highest_leg:Leg = null
	var highest_y:float = INF
	for leg in front_legs:
		if leg.joint1.global_position.y < highest_y:
			highest_y = leg.joint1.global_position.y
			highest_leg = leg
	for leg in back_legs:
		if leg.joint1.global_position.y > highest_y:
			highest_y = leg.joint1.global_position.y
			highest_leg = leg
	return highest_leg
