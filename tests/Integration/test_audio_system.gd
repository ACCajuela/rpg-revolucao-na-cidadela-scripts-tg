extends GdUnitTestSuite

func test_audio_manager_persists_across_scenes() -> void:
	var audio_manager = Engine.get_main_loop().root.get_node("AudioManager")
	
	# Tocar música no menu
	audio_manager.play_music_by_name("menu_principal")
	
	# Simular troca para cena de gameplay
	var bedroom = auto_free(load("res://scenes/ui/bedroom.gd").new())
	
	# Verificar se áudio continua
	assert_str(audio_manager.current_music).is_equal("menu_principal")
	assert_bool(audio_manager.music_player.playing).is_true()
