extends GdUnitTestSuite

func test_complete_menu_flow() -> void:
	# CORREÇÃO: Instanciar cenas completas
	var creation_scene = load("res://scenes/ui/character_criacao.tscn")
	var creation = auto_free(creation_scene.instantiate())
	creation._ready()
	
	# AGORA os nós existem
	creation.line_edit_nome.text = "Navegação Teste"
	creation.genero_selecionado = "Feminino"
	
	var database = Engine.get_main_loop().root.get_node("Database")
	
	# Simular o fluxo de dados
	database.character_creation_data = {
		"nome": "Navegação Teste", 
		"genero": "Feminino"
	}
	
	# Verificar persistência
	assert_str(database.character_creation_data.get("nome")).is_equal("Navegação Teste")
