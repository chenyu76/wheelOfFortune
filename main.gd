extends Node2D

var titles = []
var title_contents = {}

# 设置中的默认窗口大小
var window_height = ProjectSettings.get("display/window/size/viewport_height")

var wheel_speed = 0
var wheel_acc = 0
var ok = 1

# 小窗的外部边距
const margin = 64
# 小窗的内部边距
const margin_inner = 64

# 说明的背景目标
var bg_target_position = 0
var bg_speed = 0
# 小窗口中的内容字体大小
var bg_font_size = 60

# 说明的打开后的y位置
const bg_y = margin


# Called when the node enters the scene tree for the first time.
func _ready():
	# populate_md_files()
	$wheel.initialize(["Waiting"])
	$wheel.press_button.connect(_on_wheel_button_pressed.bind())
	$wheel.rotation = randf_range(0, 2*PI)
	
	var viewport_size = get_viewport_rect().size
	bg_target_position = viewport_size.y
	$guideBG.position = Vector2(viewport_size.x * 0.05, viewport_size.y * 1.05)
	
	# 窗口大小变化时激活_on_viewport_resized函数
	get_viewport().size_changed.connect(_on_viewport_resized.bind())
	_on_viewport_resized()
	
	#$rotateButton.size = Vector2(50, 50)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# 转盘
	wheel_speed += wheel_acc
	$wheel.rotation += wheel_speed
	wheel_speed -= wheel_speed * ok * delta
	if wheel_speed < 0.0005 and wheel_speed != 0:
		wheel_speed = 0
		
	# 小窗的移动
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
	$rotateButton.scale = Vector2(wheel_size, wheel_size)
	$rotateButton.position.x = viewport_size.x * 0.7
	$rotateButton.position.y = viewport_size.y * 0.5 - $rotateButton.size.y / 2
	# 更新选择列表按钮位置
	$selectButton.scale = Vector2(wheel_size, wheel_size)
	$selectButton.position.x = viewport_size.x * 0.8
	$selectButton.position.y = viewport_size.y * 0.5 - $selectButton.size.y
	# 粘贴按钮位置
	$pasteButton.scale = Vector2(wheel_size, wheel_size)
	$pasteButton.position.x = viewport_size.x * 0.8
	$pasteButton.position.y = viewport_size.y * 0.5 + $pasteButton.size.y
	# 更新指针位置
	$Point.scale = Vector2(wheel_size, wheel_size)
	$Point.position.x = viewport_size.x * 0.3 + viewport_size.y * 0.35 - $Point.size.x/2
	$Point.position.y = viewport_size.y * 0.5 - $Point.size.y/2
	
	# 弹出小窗的大小
	$guideBG.size = viewport_size - 2 * Vector2(margin, margin)
	$guideBG/Label.size = $guideBG.size - 2 * Vector2(margin_inner, margin_inner)
	$guideBG/Label.position = Vector2(margin_inner, margin_inner)
	$guideBG/TextEdit.size = $guideBG/Label.size
	$guideBG/TextEdit.position = Vector2(margin_inner, margin_inner)
	bg_speed = 0
	$guideBG.position = Vector2(margin, viewport_size.y * 1.05)
	bg_target_position = get_viewport_rect().size.y * 1.05

	$windowControl.position = Vector2(viewport_size.x - $windowControl.size.x, 0)


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

# 读取文件内容为字符串
func read_file_to_string(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("没有文件")
		get_tree().quit()

	var content = file.get_as_text()
	file.close()
	return content

# 处理字符串，解析出 titles 和 title_contents
func parse_titles_from_string(file_content: String):
	titles = []
	title_contents = {}

	var current_title = ""
	var content = []
	var lines = file_content.split("\n")

	for line in lines:
		line = line.strip_edges()
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
	if len(titles) == 0:
		lines = file_content.strip_edges().split("\n")
		for line in lines:
			if line != "":
				titles.append(line)

# 从文件中处理
func parse_titles_from_file(file_path: String):
	parse_titles_from_string(read_file_to_string(file_path))

# 转盘上的文字按钮被按下
func _on_wheel_button_pressed(pName):
	$guideBG/HBoxContainer/fontSizeChanger.visible = true
	$guideBG/Label.visible = true
	$guideBG/HBoxContainer/textConfirmer.visible = false
	$guideBG/TextEdit.visible = false
	print("press " + pName)
	if pName in title_contents.keys():
		$guideBG/Label.text = title_contents[pName].lstrip("\n")
	else:
		$guideBG/Label.text = "no information"
	bg_target_position = bg_y

	
# 小窗的关闭按钮
func _on_texture_button_pressed():
	bg_target_position = get_viewport_rect().size.y * 1.05

# 寻找可使用的文件
# 当前目录里有文件就返回 true, 没有返回false
func populate_md_files():
	var dir = DirAccess.open("./")
	#print(OS.get_executable_path())
	if dir == null:
		dir = DirAccess.open("res://")
	if dir == null:
		$FileDialog.visible = true	
	return process_file(dir)

# 处理一个目录里的所有文件，目录需要是一个DirAccess
# 当前目录里有文件就返回 true, 没有返回false
func process_file(dir):
	#var dir = DirAccess.open(dir_name)
	$selectButton/PopupMenu.clear()
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".md"):
			$selectButton/PopupMenu.add_item(file_name.substr(0,len(file_name)-3))
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# 没有可选项就弹出文件选择框
	if $selectButton/PopupMenu.item_count == 0:
		$FileDialog.visible = true
		return false
	return true
	
	
# 选择目录
func _on_file_dialog_dir_selected(d):
	$FileDialog.visible = false
	process_file(DirAccess.open(d))

# 选择文件
func _on_file_dialog_file_selected(path: String) -> void:
	$FileDialog.visible = false
	parse_titles_from_file(path)
	$wheel.initialize(titles)

func _on_select_button_pressed():
	# 寻找可用文件
	if populate_md_files():
		$selectButton/PopupMenu.popup()  # 展开菜单

func _on_popup_menu_id_pressed(id):
	var file_name = $selectButton/PopupMenu.get_item_text(id)
	print("Selected file: " + file_name)
	
	parse_titles_from_file(file_name+ ".md")
	$wheel.initialize(titles)



func _on_close_button_pressed():
	get_tree().quit()

# 输入文本的按钮被按下
func _on_paste_button_button_down() -> void:
	$guideBG/HBoxContainer/fontSizeChanger.visible = false
	$guideBG/Label.visible = false
	$guideBG/HBoxContainer/textConfirmer.visible = true
	$guideBG/TextEdit.visible = true
	bg_target_position = bg_y

# 输入文本的确认按钮被按下
func _on_confirm_button_button_down() -> void:
	# 关闭窗口
	bg_target_position = get_viewport_rect().size.y * 1.05
	# 处理文本
	parse_titles_from_string($guideBG/TextEdit.text)
	$wheel.initialize(titles)

# 缩小字体
func _on_button_p_button_down() -> void:
	bg_font_size -= 5
	for name in ["bold_italic", "italic", "mono", "normal", "bold"]:
		$guideBG/Label["theme_override_font_sizes/"+name+"_font_size"] = bg_font_size
# 放大字体
func _on_button_m_button_down() -> void:
	bg_font_size += 5
	for name in ["bold_italic", "italic", "mono", "normal", "bold"]:
		$guideBG/Label["theme_override_font_sizes/"+name+"_font_size"] = bg_font_size

# 切换是否最大化
func _on_full_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(4)
		$windowControl/closeButton.visible = true
	else:
		DisplayServer.window_set_mode(0)
		$windowControl/closeButton.visible = false
