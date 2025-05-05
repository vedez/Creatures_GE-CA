extends Node3D  

func _ready():
	for child in get_children():
		if child is Node3D:
			FlowerManager.register_flower(child)
