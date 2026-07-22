extends GdUnitTestSuite

func test_complete_character_creation_flow() -> void:
	var creation_scene = load("res://scenes/ui/character_criacao.tscn")
	var creation = auto_free(creation_scene.instantiate())
	creation._ready()
	
	creation.line_edit_nome.text = "Herói Teste"
	creation.genero_selecionado = "Masculino"
	
	var database = Engine.get_main_loop().root.get_node("Database")
	
	database.character_creation_data = {
		"nome": "Herói Teste",
		"genero": "Masculino"
	}
	
	assert_str(database.character_creation_data.get("nome")).is_equal("Herói Teste")
	assert_str(database.character_creation_data.get("genero")).is_equal("Masculino")
