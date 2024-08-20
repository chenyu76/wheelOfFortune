extends Node2D

var titles = []
var title_contents = {}

# 设置中的默认窗口大小
var window_height = ProjectSettings.get("display/window/size/viewport_height")

var wheel_speed = 0
var wheel_acc = 0
var ok = 1

# 说明的背景目标
var bg_target_position = 0
var bg_speed = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	populate_md_files()
	$wheel.initialize(["等待加载"])
	$wheel.press_button.connect(_on_wheel_button_pressed.bind())
	$wheel.rotation = randf_range(0, 2*PI)
	
	var viewport_size = get_viewport_rect().size
	bg_target_position = viewport_size.y
	$guideBG.position = Vector2(viewport_size.x * 0.05, viewport_size.y * 1.05)
	
	get_viewport().size_changed.connect(_on_viewport_resized.bind())
	_on_viewport_resized()
	
	$rotateButton.size = Vector2(50, 50)
	
	# 最大化和关闭
	$windowControl.position = Vector2(viewport_size.x, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 转盘
	wheel_speed += wheel_acc
	$wheel.rotation += wheel_speed
	wheel_speed -= wheel_speed * ok * delta
	if wheel_speed < 0.0005 and wheel_speed != 0:
		wheel_speed = 0
	# 每一帧更新位置，确保始终居中
	#_on_viewport_resized()
	$guideBG.position.y += bg_speed
	bg_speed = (bg_target_position - $guideBG.position.y) * delta * 8
	if get_viewport_rect().size.y < $guideBG.position.y:
		$guideBG.position.y = get_viewport_rect().size.y
		bg_speed = 0	
	#if bg_speed < 0.00000005 and bg_speed != 0:
		#bg_speed = 0


func _on_viewport_resized():
	# 获取视窗的大小
	var viewport_size = get_viewport_rect().size
	# 更新圆盘位置
	$wheel.position.x = viewport_size.x * 0.3
	$wheel.position.y = viewport_size.y * 0.5
	var wheel_size = viewport_size.y / window_height
	$wheel.scale = Vector2(wheel_size, wheel_size)
	$wheel.queue_redraw()
	# 更新旋转按钮位置
	$rotateButton.position.x = viewport_size.x * 0.7
	$rotateButton.position.y = viewport_size.y * 0.5 - $rotateButton.size.y / 2
	$rotateButton.scale = Vector2(wheel_size, wheel_size)
	# 更新选择列表按钮位置
	$selectButton.position.x = viewport_size.x * 0.8
	$selectButton.position.y = viewport_size.y * 0.5 - $selectButton.size.y / 2
	$selectButton.scale = Vector2(wheel_size, wheel_size)
	# 更新指针位置
	$Point.position.x = viewport_size.x * 0.3 + viewport_size.y * 0.35 - $Point.size.x/2
	$Point.position.y = viewport_size.y * 0.5 - $Point.size.y/2
	$Point.scale = Vector2(wheel_size, wheel_size)
	
	$guideBG.size = viewport_size * 0.9
	$guideBG/Label.size = viewport_size * 0.9
	bg_speed = 0
	$guideBG.position = Vector2(viewport_size.x * 0.05, viewport_size.y * 1.05)
	bg_target_position = get_viewport_rect().size.y * 1.05

	$windowControl.position = Vector2(viewport_size.x, 0)


func _on_rotate_button_pressed():
	wheel_speed += pow(2, randf_range(0, 4)) / 2

func _on_rotate_button_button_down():
	wheel_acc = 0.005
	
func _on_rotate_button_button_up():
	wheel_acc = 0

# 没有join函数，写个简陋一点的
func array_join(c: Array, s: String):
	var r = ""
	for i in c:
		r += s + i
	return r

func parse_titles_from_file(file_path):
	titles = []
	title_contents = {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("没有文件")
		get_tree().quit()

	var current_title = ""
	var content = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("# "):
			if current_title != "":
				title_contents[current_title] = array_join(content, "\n")
				titles.append(current_title)
				content = []
			current_title = line.substr(2).strip_edges()
		else:
			content.append(line)
	if current_title != "":
		title_contents[current_title] = array_join(content, "\n")
		titles.append(current_title)
	
	# 如果没有添加到东西，采用第二种模式，将每行都添加到列表
	if len(titles) != 0:
		file.close()
		return
	file.seek(0)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			titles.append(line)
	file.close()

func _on_wheel_button_pressed(pName):
	print("press " + pName)
	if pName in title_contents.keys():
		$guideBG/Label.text = title_contents[pName]
	else:
		$guideBG/Label.text = "\nno information"
	bg_target_position = get_viewport_rect().size.y * 0.05
	

func _on_texture_button_pressed():
	bg_target_position = get_viewport_rect().size.y * 1.05

func populate_md_files():
	var dir = DirAccess.open("./")
	#print(OS.get_executable_path())
	if dir == null:
		dir = DirAccess.open("res://")
	if dir == null:
		$FileDialog.visible = true
	else:	
		process_file(dir)

func process_file(dir):
	#var dir = DirAccess.open(dir_name)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".md"):
			$selectButton/PopupMenu.add_item(file_name.substr(0,len(file_name)-3))
		file_name = dir.get_next()
	dir.list_dir_end()
		
		
func _on_file_dialog_dir_selected(dir):
	$FileDialog.visible = false
	process_file(DirAccess.open(dir))
		
func _on_select_button_pressed():
	$selectButton/PopupMenu.popup()  # 展开菜单

func _on_popup_menu_id_pressed(id):
	var file_name = $selectButton/PopupMenu.get_item_text(id)
	print("Selected file: " + file_name)
	# 在这里添加处理文件选择的逻辑
	parse_titles_from_file(file_name+ ".md")
	$wheel.initialize(titles)



func _on_close_button_pressed():
	get_tree().quit()
