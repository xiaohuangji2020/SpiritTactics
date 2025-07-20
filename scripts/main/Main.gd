extends Control

func _on_start_button_pressed() -> void:
	GameManager.on_start()

# 如果你还有一个退出按钮，可以这样实现
func _on_quit_button_pressed():
	get_tree().quit()
