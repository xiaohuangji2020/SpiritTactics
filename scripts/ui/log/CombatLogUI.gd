extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready():
	Log.new_message.connect(on_new_log_message)

func on_new_log_message(message_text, log_level):
	# 可以根据log_level给文字设置不同颜色
	# rich_text_label.push_color(Color.YELLOW if log_level == Log.LogLevel.WARNING else Color.WHITE)
	rich_text_label.add_text(message_text + "\n")
	# rich_text_label.pop()
	# 自动滚动到底部
	rich_text_label.scroll_to_line(rich_text_label.get_line_count())
