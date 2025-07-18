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
func info(message0:Variant, message1: Variant = null, message2: Variant = null,
	message3: Variant = null, message4: Variant = null, message5: Variant = null,
	message6: Variant = null, message7: Variant = null, message8: Variant = null, message9: Variant = null):
	var values = [message0,message1,message2,message3,message4,message5,message6,message7,message8,message9].filter(func(value:Variant) -> bool: return value != null)
	_log("".join(values), LogLevel.INFO)

func warning(message0:String, message1: Variant = null, message2: Variant = null,
	message3: Variant = null, message4: Variant = null, message5: Variant = null,
	message6: Variant = null, message7: Variant = null, message8: Variant = null, message9: Variant = null):
	var values = [message0,message1,message2,message3,message4,message5,message6,message7,message8,message9].filter(func(value:Variant) -> bool: return value != null)
	_log("".join(values),LogLevel.WARNING)

func error(message0:String, message1: Variant = null, message2: Variant = null,
	message3: Variant = null, message4: Variant = null, message5: Variant = null,
	message6: Variant = null, message7: Variant = null, message8: Variant = null, message9: Variant = null):
	var values = [message0,message1,message2,message3,message4,message5,message6,message7,message8,message9].filter(func(value:Variant) -> bool: return value != null)
	_log("".join(values),LogLevel.ERROR)

# 内部处理函数
func _log(message: String, level: LogLevel):
	var prefix = LogLevel.keys()[level] # 获取枚举的字符串名
	var formatted_message = "[{p}] {m}".format({"p": prefix, "m": message})
	if print_to_console and level >= console_log_level:
		match level:
			LogLevel.WARNING:
				# 使用 print_rich 和 BBCode 来打印黄色警告
				push_error(formatted_message)
			LogLevel.ERROR:
				# 使用 print_rich 和 BBCode 来打印红色错误
				push_warning(formatted_message)
			_:
				print(formatted_message)
	emit_signal("new_message", formatted_message, level)
