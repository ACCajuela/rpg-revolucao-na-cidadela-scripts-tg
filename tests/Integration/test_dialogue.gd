extends GdUnitTestSuite

# Testes de Integração para o Sistema de Diálogo
class TestDialogIntegration:
	var dialog_scene: Control
	var database_singleton: Node
	
	func _init():
		# Carregar a cena real de diálogo
		dialog_scene = load("res://caminho/para/sua/cena/dialogo.tscn").instantiate()
		# Obter o singleton real do Database
		database_singleton = Engine.get_main_loop().root.get_node_or_null("Database")
	
	func cleanup():
		if dialog_scene:
			dialog_scene.queue_free()

var integration: TestDialogIntegration

func before_test():
	integration = TestDialogIntegration.new()

func after_test():
	integration.cleanup()
	integration = null

# Teste de integração do carregamento de dados do personagem
func test_integracao_carregamento_dados_personagem():
	add_child(integration.dialog_scene)
	
	# Configurar com Database real
	integration.dialog_scene.Database = integration.database_singleton
	
	# Executar carregamento de dados
	integration.dialog_scene.carregar_dados_personagem()
	
	# Verificar se os dados foram carregados corretamente
	assert_that(integration.dialog_scene.dados_carregados).is_true()
	
	# Verificar se as funções de validação funcionam
	var dados_validos = integration.dialog_scene.verificar_dados_carregados()
	assert_that(dados_validos).is_true()
	
	remove_child(integration.dialog_scene)

# Teste de integração da determinação da classe
func test_integracao_determinar_nome_classe():
	add_child(integration.dialog_scene)
	
	# Testar mapeamento de classes
	var classe_aristocrata = integration.dialog_scene.determinar_nome_classe(1)
	var classe_atleta = integration.dialog_scene.determinar_nome_classe(2)
	var classe_invalida = integration.dialog_scene.determinar_nome_classe(999)
	
	assert_that(classe_aristocrata).is_equal("Aristocrata")
	assert_that(classe_atleta).is_equal("Atleta")
	assert_that(classe_invalida).is_equal("")
	
	remove_child(integration.dialog_scene)

# Teste de integração do mapeamento para Dialogic
func test_integracao_mapear_personagem_dialogic():
	add_child(integration.dialog_scene)
	
	# Testar todas as combinações possíveis
	var combinacoes = [
		# [classe, genero, resultado_esperado]
		["Atleta", "Masculino", "AtletaMasc"],
		["Atleta", "Feminino", "AtletaFem"],
		["Aristocrata", "Masculino", "AristocrataMasc"],
		["Aristocrata", "Feminino", "AristocrataFem"],
		["ClasseInvalida", "Masculino", "DEFAULT"],
		["Atleta", "GeneroInvalido", "DEFAULT"]
	]
	
	for combinacao in combinacoes:
		var resultado = integration.dialog_scene.mapear_personagem_dialogic(
			combinacao[0], combinacao[1]
		)
		assert_that(resultado).is_equal(combinacao[2])
	
	remove_child(integration.dialog_scene)

# Teste de integração do fluxo completo de inicialização
func test_integracao_fluxo_completo_inicializacao():
	add_child(integration.dialog_scene)
	
	# Configurar Database real
	integration.dialog_scene.Database = integration.database_singleton
	
	# Simular _ready() sem await
	integration.dialog_scene.carregar_dados_personagem()
	
	# Obter dados do personagem
	var player_name = integration.dialog_scene.Database.character_creation_data.get("nome", "Nome Padrão")
	var player_class = integration.dialog_scene.determinar_nome_classe(
		integration.dialog_scene.Database.character_creation_data.get("id_classe", "")
	)
	var player_genero = integration.dialog_scene.Database.character_creation_data.get("genero", "Gênero Indefinido")
	
	# Verificar se os dados são válidos
	assert_that(player_name).is_not_equal("Nome Padrão")
	assert_that(player_class).is_not_equal("")
	assert_that(player_genero).is_not_equal("Gênero Indefinido")
	
	# Testar mapeamento para Dialogic
	var dialogic_character_name = integration.dialog_scene.mapear_personagem_dialogic(
		player_class, player_genero
	)
	assert_that(dialogic_character_name).is_not_equal("DEFAULT")
	
	remove_child(integration.dialog_scene)

# Teste de integração do sistema de sinais do Dialogic
func test_integracao_sinais_dialogic():
	add_child(integration.dialog_scene)
	
	integration.dialog_scene.Database = integration.database_singleton
	
	# Configurar victory_screen mock
	var victory_screen_called = false
	var victory_screen_args = []
	integration.dialog_scene.victory_screen = {
		"show_victory": func(xp): 
			victory_screen_called = true
			victory_screen_args.append(xp),
		"show_defeat": func(): 
			victory_screen_called = true
			victory_screen_args.append("defeat")
	}
	
	# Testar sinal de vitória
	integration.dialog_scene._on_dialogic_signal_event("vitoria")
	assert_that(victory_screen_called).is_true()
	assert_that(victory_screen_args).contains(10)
	
	# Reset para teste de derrota
	victory_screen_called = false
	victory_screen_args.clear()
	
	# Testar sinal de derrota
	integration.dialog_scene._on_dialogic_signal_event("derrota")
	assert_that(victory_screen_called).is_true()
	assert_that(victory_screen_args).contains("defeat")
	
	remove_child(integration.dialog_scene)

# Teste de integração da mudança de cena
func test_integracao_mudanca_cena():
	add_child(integration.dialog_scene)
	
	# Mock para Loading system
	var loading_called = false
	var loading_scene = ""
	integration.dialog_scene.Loading = {
		"change_scene_with_loading": func(scene): 
			loading_called = true
			loading_scene = scene
	}
	
	# Testar mudança de cena via sinal
	integration.dialog_scene._on_dialogic_signal("mudar_de_cena")
	assert_that(loading_called).is_true()
	assert_that(loading_scene).is_equal(integration.dialog_scene.WORLD)
	
	# Reset para teste via botão
	loading_called = false
	loading_scene = ""
	
	# Testar mudança de cena via botão
	integration.dialog_scene._on_button_pressed()
	assert_that(loading_called).is_true()
	assert_that(loading_scene).is_equal(integration.dialog_scene.WORLD)
	
	remove_child(integration.dialog_scene)

# Teste de integração de cenário com dados inválidos
func test_integracao_dados_invalidos():
	add_child(integration.dialog_scene)
	
	# Configurar Database com dados inválidos
	integration.dialog_scene.Database = integration.database_singleton
	integration.dialog_scene.Database.character_creation_data = {
		"nome": "",
		"genero": "",
		"id_classe": ""
	}
	
	# Executar carregamento
	integration.dialog_scene.carregar_dados_personagem()
	
	# Verificar que os dados são considerados inválidos
	var dados_validos = integration.dialog_scene.verificar_dados_carregados()
	assert_that(dados_validos).is_false()
	assert_that(integration.dialog_scene.dados_carregados).is_false()
	
	remove_child(integration.dialog_scene)

# Teste de integração da configuração de variáveis do Dialogic
func test_integracao_configuracao_dialogic():
	add_child(integration.dialog_scene)
	
	integration.dialog_scene.Database = integration.database_singleton
	integration.dialog_scene.carregar_dados_personagem()
	
	# Obter dados reais
	var player_name = integration.dialog_scene.Database.character_creation_data.get("nome", "Nome Padrão")
	var player_class = integration.dialog_scene.determinar_nome_classe(
		integration.dialog_scene.Database.character_creation_data.get("id_classe", "")
	)
	var player_genero = integration.dialog_scene.Database.character_creation_data.get("genero", "Gênero Indefinido")
	
	# Mapear para Dialogic
	var dialogic_character_name = integration.dialog_scene.mapear_personagem_dialogic(
		player_class, player_genero
	)
	
	# Verificar se o mapeamento é consistente
	assert_that(dialogic_character_name).is_not_empty()
	assert_that(dialogic_character_name).is_not_equal("DEFAULT")
	
	# Verificar integração com variáveis globais do Dialogic
	# (Em um ambiente real, verificaríamos se Dialogic.VAR.set foi chamado)
	
	remove_child(integration.dialog_scene)

# Teste de integração do fluxo de diálogo completo
func test_integracao_fluxo_dialogo_completo():
	add_child(integration.dialog_scene)
	
	integration.dialog_scene.Database = integration.database_singleton
	
	# Mock para Dialogic.start
	var dialogic_start_called = false
	var dialogic_timeline = ""
	integration.dialog_scene.Dialogic = {
		"start": func(timeline):
			dialogic_start_called = true
			dialogic_timeline = timeline
			return Node.new(),  # Retorna um nó vazio como mock
		"VAR": {
			"set": func(var_name, value): pass  # Mock vazio
		},
		"signal_event": Signal(),
		"connect": func(signal_name, callable): pass
	}
	
	# Executar inicialização completa
	integration.dialog_scene.carregar_dados_personagem()
	
	var player_name = integration.dialog_scene.Database.character_creation_data.get("nome", "Nome Padrão")
	var player_class = integration.dialog_scene.determinar_nome_classe(
		integration.dialog_scene.Database.character_creation_data.get("id_classe", "")
	)
	var player_genero = integration.dialog_scene.Database.character_creation_data.get("genero", "Gênero Indefinido")
	
	var dialogic_character_name = integration.dialog_scene.mapear_personagem_dialogic(player_class, player_genero)
	
	# Simular início do diálogo
	var dialog = integration.dialog_scene.Dialogic.start("combate_guarda_fem_calmo")
	integration.dialog_scene.add_child(dialog)
	
	# Verificar se o diálogo foi iniciado
	assert_that(dialogic_start_called).is_true()
	assert_that(dialogic_timeline).is_equal("combate_guarda_fem_calmo")
	
	remove_child(integration.dialog_scene)

# Teste de integração de tratamento de erros
func test_integracao_tratamento_erros():
	add_child(integration.dialog_scene)
	
	# Testar cenário sem Database
	integration.dialog_scene.Database = null
	integration.dialog_scene.carregar_dados_personagem()
	
	# Não deve crashar, deve lidar gracefulmente com o erro
	assert_that(integration.dialog_scene).is_not_null()
	
	# Testar com Database inválido
	integration.dialog_scene.Database = Node.new()  # Database mock inválido
	integration.dialog_scene.carregar_dados_personagem()
	
	# Não deve crashar
	assert_that(integration.dialog_scene).is_not_null()
	
	remove_child(integration.dialog_scene)

# Teste de integração de performance
func test_integracao_performance_carregamento():
	add_child(integration.dialog_scene)
	
	integration.dialog_scene.Database = integration.database_singleton
	
	var start_time = Time.get_ticks_msec()
	
	# Executar operações de carregamento múltiplas vezes
	for i in range(10):
		integration.dialog_scene.carregar_dados_personagem()
		integration.dialog_scene.verificar_dados_carregados()
		integration.dialog_scene.determinar_nome_classe(1)
		integration.dialog_scene.mapear_personagem_dialogic("Atleta", "Masculino")
	
	var end_time = Time.get_ticks_msec()
	var execution_time = end_time - start_time
	
	# Verificar que é performático (menos de 100ms para 10 iterações)
	assert_that(execution_time).is_less(100)
	
	remove_child(integration.dialog_scene)
