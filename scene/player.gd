extends CharacterBody2D

const BULLET_SCENE := preload("res://scene/bullet.tscn")
const ARMED_ANIMATINO_PREFIX := &"armed"
const DEFAULT_FIRE_RATE_MULTIPLIER := 1.0
const SPIRAL_PHASE_STEP := PI/12

const PLAYER_FORM_MODE_NORMAL := 0
const PLAYER_FORM_MODE_ARMED := 1
const SHOT_PATTERN_NORMAL := 1
const SHOT_PATTERN_SPIRAL := 0

@export var fire_interval : float =  0.18
@export var bullet_spawn_distance: float = 18.0

# 常量规范：大写_组成;& 表示"normal"为字符串常量； := 用于自动识别变量类型 不需要像：写明
const NORMAL_ANIMATION_PREFIX := &"normal"
var facing_suffix: StringName = &"right"

var rapid_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER
var form_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER
var current_form_mode: int = PLAYER_FORM_MODE_NORMAL
var current_shot_pattern: int = SHOT_PATTERN_NORMAL
var spiral_phase: float = 0.0

# @export将对应变量进行暴露，可以在检查器面板进行修改
@export var move_speed : float = 120.0
# 可以通过拖拽对应节点按住ctrl后松开左键实现
@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var armed_effect_sprite: AnimatedSprite2D = $ArmedEffectSprite
@onready var shooting_timer: Timer = $ShootingTimer

func _ready() -> void:
	#form_fire_rate_multiplier= 20.0
	#current_form_mode= PLAYER_FORM_MODE_ARMED
	#current_shot_pattern = SHOT_PATTERN_SPIRAL
	#spiral_phase = 0.0
	# 设置计时器为单词触发不循环，计时结束停止不循环
	shooting_timer.one_shot = true
	# 设置计时器计时时间
	shooting_timer.wait_time = _get_effective_fire_interval()
	_update_animation()
	_update_armed_effect()

# _开头函数为godot内置函数
func _physics_process(delta: float) -> void:
	
	var move_input = Input.get_vector("move_left","move_right","move_up","move_down")
	var shoot_input = Input.get_vector("shot_left","shot_right","shot_up","shot_down")
	
	# CharacterBody2D内置成员变量
	velocity = move_speed * move_input;	
	# CharacterBody2D内置的移动函数，根据velocity进行移动更新
	move_and_slide()
	
	# 更新facing_suffix，即后缀动画名，动画名格式normal_right
	# facing_suffix用于更新对应朝向， if 条件判定防止松开方向键输入后跳回默认动画
	# 即只有在有按下按键时才会更新facing_suffix后缀进而实现动画更新
	#if move_input != Vector2.ZERO:
		#facing_suffix = _vector_to_facing_suffix(move_input)
		#
	#_update_animation()
	
	# 射击方向影响朝向需要重新射击 
	# 判断射击模式
	if current_shot_pattern == SHOT_PATTERN_SPIRAL:
		_try_auto_spiral_shoot()
	elif shoot_input != Vector2.ZERO:
		_try_shoot(shoot_input)
	
	_update_facing(move_input, shoot_input)
	_update_animation()
	_update_armed_effect()
	
func _update_animation():
	var animation_name := StringName("%s_%s" %[NORMAL_ANIMATION_PREFIX, facing_suffix])
	
	# 为什么直接替换为armed前缀
	if not body_sprite.sprite_frames.has_animation(animation_name):
		var fallback_animation_name := StringName("%s_%s" %[ARMED_ANIMATINO_PREFIX, facing_suffix])
		if not body_sprite.sprite_frames.has_animation(fallback_animation_name):		
			push_warning("Missing player animation: %s" % animation_name)
			return 
		animation_name = fallback_animation_name
					
	if body_sprite.animation != animation_name:
		body_sprite.play(animation_name)
	
func _update_facing(move_input: Vector2, shoot_input: Vector2)	-> void:
	if current_shot_pattern == SHOT_PATTERN_SPIRAL:
		if move_input != Vector2.ZERO:
			facing_suffix = _vector_to_facing_suffix(move_input)
			return 
		
	if shoot_input != Vector2.ZERO:
		facing_suffix = _vector_to_facing_suffix(shoot_input)
	elif move_input != Vector2.ZERO:
		facing_suffix = _vector_to_facing_suffix(move_input)		
	
func _get_effective_fire_interval() -> float:
	return maxf(fire_interval / _get_effective_fire_rate_multiplier(), 0.01)
	
func _get_effective_fire_rate_multiplier():
	if _has_active_form_override():
		return maxf(form_fire_rate_multiplier, 0.01)
		
	return maxf(rapid_fire_rate_multiplier, 0.01)

func _update_armed_effect() -> void:
	var is_armed := current_form_mode == PLAYER_FORM_MODE_ARMED
	
	if not is_armed:
		if armed_effect_sprite.visible:
			armed_effect_sprite.visible = false
		if armed_effect_sprite.is_playing():			
			armed_effect_sprite.stop()
		return 			
			
	if not armed_effect_sprite.visible:
		armed_effect_sprite.visible = true
	if armed_effect_sprite.is_playing():
		return
	if armed_effect_sprite.sprite_frames == null:
		return 
		
	if armed_effect_sprite.sprite_frames.has_animation(&"default"):
		armed_effect_sprite.play(&"default")
	

func _has_active_form_override() -> bool:
	return (
		current_form_mode != PLAYER_FORM_MODE_NORMAL
		or current_shot_pattern != SHOT_PATTERN_NORMAL
	)

func _get_animation_prefix() -> StringName:
	if current_form_mode == PLAYER_FORM_MODE_NORMAL:
		return ARMED_ANIMATINO_PREFIX
		
	return NORMAL_ANIMATION_PREFIX		


		
func _try_auto_spiral_shoot() -> void:
	if not shooting_timer.is_stopped():
		return 

	var spiral_direction := Vector2.RIGHT.rotated(spiral_phase)
	var has_spawned_bullet := _fire_bullets(spiral_direction)
	if has_spawned_bullet:
		shooting_timer.start(_get_effective_fire_interval())
			
			
func _try_shoot(shoot_input: Vector2) -> void:
	if not shooting_timer.is_stopped():
		return 
	
	var shoot_direction := shoot_input.normalized()
	var has_spawned_bullet := _fire_bullets(shoot_direction)
	if has_spawned_bullet :
		shooting_timer.start(_get_effective_fire_interval())
		
func _fire_bullets(base_direction: Vector2) -> bool:
	if current_shot_pattern == SHOT_PATTERN_SPIRAL:
		var has_spawned_forward_bullet = _spawn_bullet(base_direction)
		var has_spawned_backward_bullet = _spawn_bullet(base_direction.rotated(PI))
		# 作用？
		spiral_phase = wrapf(spiral_phase + SPIRAL_PHASE_STEP, 0, TAU)		
		return has_spawned_forward_bullet or has_spawned_backward_bullet
	
	return _spawn_bullet(base_direction)		
	
func _spawn_bullet(shoot_direction: Vector2) -> bool:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	if bullet == null:
		return false
		
	bullet.top_level = true
	bullet.setup(shoot_direction)
	
	# 获得当前子弹实力所在世界场景，并挂载在上面，而不是角色场景（不能基于会移动的角色）
	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		return false
	spawn_parent.add_child(bullet)
	
	# 设置子弹生成位置偏移
	bullet.global_position = global_position + shoot_direction * bullet_spawn_distance
	return true
	
		
func _vector_to_facing_suffix(direction: Vector2) -> StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
		
	return &"down" if direction.y > 0.0 else &"up"
	
