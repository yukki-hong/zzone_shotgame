extends Resource
class_name PickupConfig

enum PickupType{
	SPEED,
	RAPID,
	SPIRAL,
}

enum PlayerFormMode{
	NORMAL,
	ARMED,
}

enum ShotPattern{
	NORMAL,
	SPIRAL,
}

# @export_group分组显示，@export_range限制范围
@export_group("基础信息")

@export var pickup_type :PickupType = PickupType.SPEED
@export var display_name : String = "移速道具"
# or_greater 可以实现按住拖拽数字实现超过上限max，or_less同理是下限min
@export_range(0.0, 1000.0, 0.1, "or_greater")  var drop_weight: float = 1.0

@export_group("显示资源")
@export var icon_texture : Texture2D

@export_group("Buff 效果")
@export_range(0.0, 120.0, 0.1, "or_greater") var duration: float = 5.0
@export_range(0.1, 5.0, 0.1, "or_greater") var move_speed_multiplier = 1.0
@export_range(0.1, 5.0, 0.1, "or_greater") var fire_rate_multiplier = 1.0

@export_group("形态与弹幕")
@export var player_form_mode : PlayerFormMode = PlayerFormMode.NORMAL
@export var shot_pattern: ShotPattern = ShotPattern.NORMAL
