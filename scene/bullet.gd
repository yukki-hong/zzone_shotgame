extends Area2D
class_name Bullet

const  WORLD_COLLISION_MASK := 1

@export var speed: float = 320.0
@export var max_lifetime: float = 2.0

var	direction: Vector2 = Vector2.RIGHT
var remaining_lifetime: float = 0

# bullet场景加载就绪后进行lifetime初始化，回调函数设置
# 回调函数： 正常是我们调用库函数，现在是写函数被引擎内置功能调用
func _ready() -> void:
	remaining_lifetime = max_lifetime	
	area_entered.connect(_on_area_entered)
	
# 用于外部调用，初始化发射方向
func setup(initial_direction: Vector2) -> void:
	if initial_direction != Vector2.ZERO:
		# normalized 归一化，只保留方向
		direction = initial_direction.normalized()
	
	rotation = initial_direction.angle()

func _physics_process(delta: float) -> void:
	
	# 返回当前节点的2d世界坐标;
	var current_position = global_position
	var next_positioin = current_position + direction * speed * delta
	
	if _will_hit_world(current_position, next_positioin):
		# 用于引擎决定什么时候消除，queue_free标记需要清除
		queue_free()
		return
		
	global_position = next_positioin
	
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0 :
		queue_free()
		
	
# 兜底碰撞检测，防止bullet速度过快导致没有检测到
func _will_hit_world(from_position: Vector2, to_position: Vector2) -> bool:
	#get_world_2d返回当前节点的所在2d世界节点;direct_space_state提供访问世界物理状态，用于检测碰撞等
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return false
		
	# 创建2D世界射线信息
	var query := PhysicsRayQueryParameters2D.create(
		from_position,
		to_position,
		WORLD_COLLISION_MASK		
	)
	
	# 设置射线与世界碰撞检测的范围：
	# bodies 检测PhysicsBody2D
	# areas 检测Area2D
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	# space_state检测射线和当前2D世界的碰撞检测情况，返回结果以字典形式体现
	# 无碰撞返回空字典
	var hit_result: Dictionary = space_state.intersect_ray(query)
	return not hit_result.is_empty()	

# 与其他区域碰撞消除子弹
func _on_area_entered(area: Area2D) -> void:
	# 如果与其他子弹碰撞，不计入碰撞检测
	if area is Bullet:
		return 
	
	queue_free()
