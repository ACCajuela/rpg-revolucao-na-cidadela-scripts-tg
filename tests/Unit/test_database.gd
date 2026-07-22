extends GdUnitTestSuite

func test_fade_animations() -> void:
	var transitioner = Engine.get_main_loop().root.get_node("Transitioner")
	assert_object(transitioner).is_not_null()
	
	# Testar se as funções existem
	transitioner.fade_out()
	transitioner.fade_in()
	
	# Verificar se o AnimationPlayer existe
	assert_object(transitioner.anim_player).is_not_null()
