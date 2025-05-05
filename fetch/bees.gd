extends Node3D

var wing_speed = 10.0
var wing_angle = 0.0

func _process(delta):
	wing_angle = sin(Time.get_ticks_msec() / 100.0) * 30.0  # degrees
	$LeftWing.rotation_degrees = Vector3(0, 0, wing_angle)
	$RightWing.rotation_degrees = Vector3(0, 0, -wing_angle)
