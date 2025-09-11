extends VBoxContainer


func _ready() -> void:
	_populate()


func _populate() -> void:
	$lb_score.text = "[wave]%s[/wave]" % Mng.score
