extends Node2D
class_name Leg

const MIN_DISTANCE: float = 64

@export var joint1:Node2D
@export var upper_leg_sprite:Sprite2D
@export var joint2:Node2D
@export var mid_leg_sprite:Sprite2D
@export var hand:Node2D
@export var hand_sprite:Sprite2D
@export var flipped:bool = true
@export var point_at_mouse:bool = false

var len_upper:float = 0
var len_middle:float = 0
var len_lower:float = 0

var goal_pos:Vector2 = Vector2()
var int_pos:Vector2 = Vector2()
var start_pos:Vector2 = Vector2()
var step_height:float = 40
var step_rate:float = 0.5
var step_time:float = 0.0

func _on_ready():
	# joints are laid out horizontally left to right
	len_upper = joint1.position.x
	len_middle = joint2.position.x
	len_lower = hand.position.x
	upper_leg_sprite.flip_h = flipped
	mid_leg_sprite.flip_h = flipped
	hand_sprite.flip_h = flipped
	
func step(g_pos:Vector2):
	if goal_pos == g_pos:
		return

	goal_pos = g_pos
	var hand_pos:Vector2 = hand.global_position

	var highest:float = goal_pos.y
	if hand_pos.y < highest:
		highest = hand_pos.y

	var mid:float = (goal_pos.x + hand_pos.x) / 2.0
	start_pos = hand_pos
	int_pos = Vector2(mid, highest - step_height)
	step_time = 0.0
	
func _process(delta: float) -> void:
	step_time += delta
	var target_pos:Vector2 = global_position
	if point_at_mouse:
		target_pos = get_global_mouse_position()
		if target_pos < global_position:
			flipped = false
		else:
			flipped = true
		
		upper_leg_sprite.flip_h = flipped
		mid_leg_sprite.flip_h = flipped
		hand_sprite.flip_h = flipped
	else:
		var t:float = step_time / step_rate
		if t < 0.5:
			target_pos = start_pos.lerp(int_pos, t / 0.5)
		elif t < 1.0:
			target_pos = int_pos.lerp(goal_pos, (t - 0.5) / 0.5)
		else:
			target_pos = goal_pos
	
	
	update_ik(target_pos)
	

func update_ik(target_pos:Vector2):
	var offset:Vector2 = target_pos - global_position
	var dis_to_tar:float = offset.length()
	if dis_to_tar < MIN_DISTANCE:
		offset = (offset / dis_to_tar) * MIN_DISTANCE
		dis_to_tar = MIN_DISTANCE
 
	var base_r:float = offset.angle()
	var len_total:float = len_upper + len_middle + len_lower
	var len_dummy_side:float = (len_upper + len_middle) * clampf(dis_to_tar / len_total, 0.0, 1.0)
 
	var base_angles:Dictionary = three_side_calc(len_dummy_side, len_lower, dis_to_tar)
	var next_angles:Dictionary = three_side_calc(len_upper, len_middle, len_dummy_side)
 
	global_rotation = base_angles.B + next_angles.B + base_r
	joint1.rotation = next_angles.C
	joint2.rotation = base_angles.C + next_angles.A
	
func three_side_calc(side_a:float, side_b:float, side_c:float):
	if side_c >= side_a + side_b:
		return {"A": 0, "B": 0, "C": 0}
	var angle_a:float = law_of_cos(side_b, side_c, side_a)
	var angle_b:float = law_of_cos(side_c, side_a, side_b) + PI
	var angle_c:float = PI - angle_a - angle_b
 
	if flipped:
		angle_a = -angle_a
		angle_b = -angle_b
		angle_c = -angle_c
 
	return {"A": angle_a, "B": angle_b, "C": angle_c}
 
func law_of_cos(a, b, c) -> float:
	if a == 0 or b == 0:
		return 0
	return acos( (pow(a, 2) + pow(b, 2) - pow(c, 2)) / ( 2 * a * b) )
