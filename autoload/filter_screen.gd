extends Node

var _world_env: WorldEnvironment = null

func loading_settings(world_env: WorldEnvironment):
	_world_env = world_env
	var config = Database.load_settings()
	var brilho = config.get("brilho", 1.0)
	var contraste = config.get("contraste", 1.0)
	apply_brightness(brilho)
	apply_contrast(contraste)
		
func apply_brightness(value):
	if _world_env and _world_env.environment:
		_world_env.environment.adjustment_brightness = value

func apply_contrast(value):
	if _world_env and _world_env.environment:
		_world_env.environment.adjustment_contrast = value
