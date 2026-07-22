extends GdUnitTestSuite

var transitioner: CanvasLayer

func before_test() -> void:
	transitioner = auto_free(load("res://Transitioner.gd").new())

func test_fade_animations() -> void:
	# CORREÇÃO: Acessar o AutoLoad, não instanciar
	var transitioner = Engine.get_main_loop().root.get_node("Transitioner")
	assert_object(transitioner).is_not_null()
	
	transitioner.fade_out()  # ← AGORA FUNCIONA
	transitioner.fade_in()
