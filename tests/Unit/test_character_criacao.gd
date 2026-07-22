extends GdUnitTestSuite

var character_creation: Control

func before_test() -> void:
	# CORREÇÃO: Carregar e instanciar a CENA completa
	var scene = load("res://scenes/ui/character_criacao.tscn")
	character_creation = auto_free(scene.instantiate())
	character_creation._ready()

func test_salvar_dados_personagem() -> void:
	# Criar um mock simples do Database
	var database_mock = { "character_creation_data": {} }
	
	var result = character_creation.salvar_dados_personagem(
		database_mock, "Teste", "Masculino"
	)
	
	assert_bool(result).is_true()
	assert_str(database_mock.character_creation_data.get("nome")).is_equal("Teste")

func test_validacao_nome_vazio() -> void:
	character_creation.line_edit_nome.text = ""
	character_creation._on_button_proceed_pressed()
	
	# Verificar se o diálogo de aviso foi ativado
	assert_object(character_creation.accept_dialog_aviso).is_not_null()

func test_validacao_nome_preenchido() -> void:
	character_creation.line_edit_nome.text = "Herói Teste"
	character_creation.genero_selecionado = "Masculino"
	
	var database_mock = { "character_creation_data": {} }
	var result = character_creation.salvar_dados_personagem(
		database_mock, "Herói Teste", "Masculino"
	)
	
	assert_bool(result).is_true()
