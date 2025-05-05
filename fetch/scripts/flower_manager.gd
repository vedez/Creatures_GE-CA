extends Node

var flowers: Array = []

func register_flower(flower_node: Node3D):
	if flower_node not in flowers:
		flowers.append(flower_node)

func get_random_flower() -> Node3D:
	if flowers.size() > 0:
		return flowers.pick_random()
	return null
