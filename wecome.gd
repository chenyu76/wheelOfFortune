extends Node2D

# 移动速度和方向
var velocity = Vector2(250, 150)
# label hsv hcolor
var label_h = 0
var label_h_d = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.position = Vector2(randi_range(0, 1000) ,randi_range(0, 500))
	$Label.size = Vector2(randi_range(150, 200), randi_range(150, 200))
	

func _on_viewport_resized():
	pass

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://main.tscn")	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 更新位置
	$Label.position += velocity * delta
	# 检测边界并反弹
	if $Label.position.x < 0:
		velocity.x = abs(velocity.x)
		label_h += delta * label_h_d
	if $Label.position.x > get_viewport_rect().size.x - $Label.size.x:
		velocity.x = -abs(velocity.x)
		label_h += delta * label_h_d
	if $Label.position.y < 0:
		velocity.y = abs(velocity.y)
		label_h += delta * label_h_d
	if $Label.position.y > get_viewport_rect().size.y - $Label.size.y:
		velocity.y = -abs(velocity.y)
		label_h += delta * label_h_d
	
	if label_h > 1:
		label_h -= 1
	$Label.set("theme_override_colors/font_color", Color.from_hsv(label_h, 0.8, 0.8))
	
