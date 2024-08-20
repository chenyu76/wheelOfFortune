extends Node2D

var titles = ["等待载入数据"]

signal press_button(name: String)

#var titles = ["Title 1", "Title 2", "Title 3", "Title 4"] # 假设有4个标题
var colors = [Color.from_hsv(0.613, 0.5, 0.9),
				Color.from_hsv(0.603, 0.5, 0.8),
				Color.from_hsv(0.593, 0.5, 0.7),
				Color.from_hsv(0.583, 0.5, 0.6),] # 每个扇形的颜色
var font_size = 40	# 字体尺寸
var radius = 400 	# 圆盘半径

# Called when the node enters the scene tree for the first time.
func _ready():
	#update() # 请求重新绘制节点
	# print(titles)
	# print(title_contents)
	queue_redraw()
	pass

func initialize(t):
	titles = t
	for child in get_children():
		child.queue_free()
	queue_redraw()

func _draw():
	# 创建一个新的Theme实例
	var theme = Theme.new()

	# 创建一个StyleBoxFlat实例用于按钮的正常状态
	var normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = Color(0, 0, 0, 0)  # 设置背景颜色
	normal_stylebox.border_width_top = 0  # 设置边框宽度
	normal_stylebox.border_color = Color(0.1, 0.1, 0.1, 0)  # 设置边框颜色

	# 将StyleBoxFlat应用于按钮的正常状态
	theme.set_stylebox("normal", "Button", normal_stylebox)
	theme.set_color("font", "Button", Color.WHITE)
		
	var num_titles = titles.size()
	var angle_per_title = 360.0 / num_titles # 每个扇形的角度

	for i in range(num_titles):
		var start_angle = deg_to_rad(i * angle_per_title)
		var end_angle = deg_to_rad((i + 1) * angle_per_title)
		var points = [Vector2(0, 0)] # 扇形的顶点，开始于圆心

		# 生成扇形的边缘点
		var angle = start_angle
		while angle < end_angle:
			var point = Vector2(cos(angle), sin(angle)) * radius
			points.append(point)
			angle += deg_to_rad(1) # 以1度的步进绘制扇形的边缘

		# 添加终点以闭合扇形
		points.append(Vector2(cos(end_angle), sin(end_angle)) * radius)

		# 绘制扇形
		# 最后一个颜色不能和第一个一样
		draw_colored_polygon(points, 
			colors[1 if i == num_titles - 1 and num_titles%len(colors) == 1 else i%len(colors)])
			
		# 绘制游戏名称
		var text_layer = Button.new()
		var text_angle = deg_to_rad((i+0.5) * angle_per_title)
		add_child(text_layer)
		
		# 按钮大小
		text_layer.size = Vector2(100, 50)
		
		text_layer.text = titles[i]
		text_layer.position = Vector2(radius * cos(text_angle) * 0.6, radius * sin(text_angle)*0.6)
		# 使按钮居中，额外需要的角度
		var size_angle = atan(text_layer.size.y / float(text_layer.size.x))
		text_layer.position.x -= text_layer.size.x * cos(text_angle + size_angle) / 2.0
		text_layer.position.y -= text_layer.size.y * sin(text_angle + size_angle)
		
		text_layer.rotation = text_angle
		
		# 设置按钮样式
		text_layer.set_theme(theme)
		text_layer.set("theme_override_font_sizes/font_size", font_size)
		text_layer.set("theme_override_colors/font_color", Color.WHITE)
		#text_layer.set("theme_override_fonts/font", "res://art/SourceHanSansCN-Regular.otf")
		
		# 连接信号
		text_layer.pressed.connect(wheel_button_press.bind(titles[i]))
		
func wheel_button_press(pName:String):
	press_button.emit(pName)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
