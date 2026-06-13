extends CharacterBody2D

# 常量规范：大写_组成;& 表示"normal"为字符串常量； := 用于自动识别变量类型 不需要像：写明
const NORMAL_ANIMATION_PREFIX := &"normal"
var facing_suffix: StringName = &"right"

@export var move_speed : float = 120.0
# 可以通过拖拽对应节点按住ctrl后松开左键实现
@onready var body_sprite: AnimatedSprite2D = $BodySprite

func _ready() -> void:
	_update_animation()

func _physics_process(delta: float) -> void:
	
	var move_input = Input.get_vector("move_left","move_right","move_up","move_down")
		
	velocity = move_speed * move_input;	
	move_and_slide()
	
	# 更新facing_suffix，即后缀动画名，动画名格式normal_right
	# facing_suffix用于更新对应朝向， if 条件判定防止松开方向键输入后跳回默认动画
	# 即只有在有按下按键时才会更新facing_suffix后缀进而实现动画更新
	if move_input != Vector2.ZERO:
		facing_suffix = _vector_to_facing_suffix(move_input)
		
	_update_animation()
	
func _update_animation():
	var animation_name := StringName("%s_%s" %[NORMAL_ANIMATION_PREFIX, facing_suffix])
	
	if not body_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Missing player animation: %s" % animation_name)
		return 
		
	if body_sprite.animation != animation_name:
		body_sprite.play(animation_name)
	
func _vector_to_facing_suffix(direction: Vector2) -> StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x > 0.0 else &"left"
		
	return &"down" if direction.y > 0.0 else &"up"
	
