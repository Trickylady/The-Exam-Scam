extends Control


func _ready() -> void:
	update()


func clear_list() -> void:
	for entry: EntryLeaderboard in %vb_entry.get_children():
		entry.queue_free()


func update() -> void:
	pass
