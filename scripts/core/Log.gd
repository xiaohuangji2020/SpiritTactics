extends Node

# 定义日志级别
enum LogLevel { INFO, WARNING, ERROR, DEBUG }

# 定义信号，当有新消息时发出，可以给游戏内控制台用
signal new_message(message_text, log_level)

# 是否在Godot控制台打印日志
@export var print_to_console: bool = true
# 最低打印级别（方便在发布时只看错误）
@export var console_log_level: LogLevel = LogLevel.INFO

# --- 公共日志记录函数 ---
func info(message: String):
	_log(message, LogLevel.INFO)

func warning(message: String):
	_log(message, LogLevel.WARNING)

func error(message: String):
	_log(message, LogLevel.ERROR)

# 内部处理函数
func _log(message: String, level: LogLevel):
	var prefix = LogLevel.keys()[level] # 获取枚举的字符串名
	var formatted_message = "[{p}] {m}".format({"p": prefix, "m": message})
	if print_to_console and level >= console_log_level:
		match level:
			LogLevel.WARNING:
				# 使用 print_rich 和 BBCode 来打印黄色警告
				print_rich("[color=yellow]%s[/color]" % [formatted_message])
			LogLevel.ERROR:
				# 使用 print_rich 和 BBCode 来打印红色错误
				print_rich("[color=red]%s[/color]" % [formatted_message])
			_:
				print(formatted_message)
	emit_signal("new_message", formatted_message, level)
