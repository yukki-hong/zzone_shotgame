extends Area2D
class_name Pickup

const BLINK_ENABLED_SHADER_PATAMETER := &"blink_enabled"

@export var pickup_config: PickupConfig 
@export_range(0.0, 10.0, 0.1, "or_greater") var blink_before_expire: float = 1.2

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer

var is_expiring: bool = false

func _ready() -> void:	
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.one_shot = true
	if lifetime_timer.wait_time > 0.0:
		lifetime_timer.start()
	_set_blink_enabled(false)
	_apply_config_to_visual()

func _set_blink_enabled(enabled:bool) -> void:
	var  sprite_material := sprite_2d.material as ShaderMaterial
	if sprite_material != null:
		sprite_material.set_shader_parameter(BLINK_ENABLED_SHADER_PATAMETER, enabled)
		
func _apply_config_to_visual():
	if pickup_config == null:
		push_warning("Pickup config is missing.")
		return
	
	sprite_2d.texture = pickup_config.icon_texture

func _process(delta: float) -> void:
	if is_expiring :
		return 
	if lifetime_timer.is_stopped():
		return
	if lifetime_timer.time_left > blink_before_expire:
		return 
	
	# 只有在道具还有效，并且道具持续时间还没结束，剩余时间进入闪烁时刻才执行
	_set_blink_enabled(true)
	
func _on_body_entered(body: Node2D) -> void:
	if pickup_config == null:
		return 
	
	var player := body as Player  
	if player == null:
		return 
		
	if player.apply_pickup(pickup_config):
		queue_free()
	
func _on_lifetime_timer_timeout() -> void:
	queue_free()
		
