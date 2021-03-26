extends Node

func _process(_delta):
	$Health/ProgressBar.value = PlayerGlobal.health
	$Stamina/ProgressBar.value = PlayerGlobal.stamina
