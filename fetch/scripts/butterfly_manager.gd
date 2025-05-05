extends Node

var butterflies := []
var butterfly_scene := preload("res://scenes/butterfly.tscn")

func add_butterfly(node: Node3D):
	if node and node not in butterflies:
		butterflies.append(node)

func remove_butterfly(node: Node3D):
	if node in butterflies:
		butterflies.erase(node)
		node.queue_free()

func get_butterfly_count() -> int:
	return butterflies.size()

func spawn_butterfly(parent: Node, radius: float = 45.0) -> Node3D:
	var butterfly = butterfly_scene.instantiate()
	var x = randf_range(-radius, radius)
	var z = randf_range(-radius, radius)
	butterfly.position = Vector3(x, 3.0, z)
	parent.add_child(butterfly)
	add_butterfly(butterfly)
	return butterfly
