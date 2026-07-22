extends GdUnitTestSuite

func test_database_persists_across_scenes() -> void:
	var database = Engine.get_main_loop().root.get_node("Database")
	
	# Salvar dados
	database.character_creation_data = {
		"nome": "Teste Integração",
		"genero": "Feminino", 
		"id_classe": 2
	}
	
	# Simular troca de cena (recriar objetos)
	var bedroom = auto_free(load("res://scenes/ui/bedroom.gd").new())
	bedroom.carregar_dados_personagem()
	
	# Verificar se os dados persistiram
	var loaded_data = database.character_creation_data
	assert_str(loaded_data.get("nome", "")).is_equal("Teste Integração")
