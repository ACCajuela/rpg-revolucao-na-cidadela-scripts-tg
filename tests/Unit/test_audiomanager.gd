extends GdUnitTestSuite

func test_audio_manager_setup() -> void:
	# AudioManager é AutoLoad, acesse diretamente
	var audio_manager = Engine.get_main_loop().root.get_node("AudioManager")
	assert_object(audio_manager).is_not_null()
	assert_object(audio_manager.music_player).is_not_null()
	assert_array(audio_manager.sfx_players).is_not_empty()

func test_play_music() -> void:
	var audio_manager = Engine.get_main_loop().root.get_node("AudioManager")
	# Testar se a função existe e não quebra
	audio_manager.play_music_by_name("menu_principal")
	# Verificar se a música atual foi definida
	assert_str(audio_manager.current_music).is_equal("menu_principal")

func test_play_sfx() -> void:
	var audio_manager = Engine.get_main_loop().root.get_node("AudioManager")
	# Testar se a função existe
	audio_manager.play_sfx("ui_click")
	# Não podemos verificar facilmente se tocou, mas pelo menos testa que não quebra
