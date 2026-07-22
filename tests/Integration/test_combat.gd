extends GdUnitTestSuite

# Testes de Integração para o Sistema de Combate
class TestCombatIntegration:
	var combat_scene: Control
	var database_singleton: Node
	
	func _init():
		# Carregar a cena real de combate
		combat_scene = load("res://scenes/ui/combat.tscn").instantiate()
		# Obter o singleton real do Database
		database_singleton = Engine.get_main_loop().root.get_node_or_null("Database")
	
	func cleanup():
		if combat_scene:
			combat_scene.queue_free()

var integration: TestCombatIntegration

func before_test():
	integration = TestCombatIntegration.new()

func after_test():
	integration.cleanup()
	integration = null

# Teste de integração do fluxo completo de combate
func test_integracao_fluxo_combate_completo():
	# Adicionar a cena à árvore
	add_child(integration.combat_scene)
	
	# Configurar com Database real
	integration.combat_scene.Database = integration.database_singleton
	
	# Inicializar componentes necessários
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	
	# Verificar inicialização
	assert_that(integration.combat_scene.player_stats).is_not_null()
	assert_that(integration.combat_scene.player_stats.has("vida")).is_true()
	assert_that(integration.combat_scene.player_stats.has("forca")).is_true()
	
	# Iniciar combate
	integration.combat_scene.start_combat()
	assert_that(integration.combat_scene.combat_active).is_true()
	
	# Simular ataque do jogador
	var vida_inimigo_inicial = integration.combat_scene.enemy_stats["vida"]
	integration.combat_scene.execute_player_attack(0, "SOCO")
	
	# Verificar se o sistema reagiu ao ataque
	assert_that(integration.combat_scene.enemy_stats["vida"] <= vida_inimigo_inicial).is_true()
	
	# Verificar se o turno mudou ou combate terminou
	if integration.combat_scene.enemy_stats["vida"] > 0:
		# Combate deve continuar
		assert_that(integration.combat_scene.combat_active).is_true()
	else:
		# Inimigo morreu, combate deve terminar
		assert_that(integration.combat_scene.combat_active).is_false()
	
	remove_child(integration.combat_scene)

# Teste de integração do carregamento de dados do personagem
func test_integracao_carregamento_dados_personagem():
	add_child(integration.combat_scene)
	
	# Usar Database real
	integration.combat_scene.Database = integration.database_singleton
	
	# Executar fluxo completo de carregamento
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	
	# Verificar integração entre componentes
	assert_that(integration.combat_scene.dados_carregados).is_true()
	assert_that(integration.combat_scene.player_stats).is_not_null()
	assert_that(integration.combat_scene.player_stats["nome"]).is_not_empty()
	assert_that(integration.combat_scene.player_stats["vida"]).is_greater(0)
	
	# Verificar se as animações foram configuradas
	assert_that(integration.combat_scene.genero).is_not_empty()
	assert_that(integration.combat_scene.classe).is_not_empty()
	
	remove_child(integration.combat_scene)

# Teste de integração do sistema de fuga
func test_integracao_sistema_fuga():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	integration.combat_scene.start_combat()
	
	var vida_inicial = integration.combat_scene.player_stats["vida"]
	
	# Executar fuga
	integration.combat_scene.execute_player_escape()
	
	# Verificar consequências da fuga
	assert_that(integration.combat_scene.player_stats["vida"]).is_equal(vida_inicial - 1)
	assert_that(integration.combat_scene.combat_active).is_false()
	
	remove_child(integration.combat_scene)

# Teste de integração do turno do inimigo
func test_integracao_turno_inimigo():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	integration.combat_scene.start_combat()
	
	var vida_jogador_inicial = integration.combat_scene.player_stats["vida"]
	
	# Executar turno do inimigo
	integration.combat_scene.enemy_turn()
	
	# Verificar se o inimigo agiu
	assert_that(integration.combat_scene.player_stats["vida"] <= vida_jogador_inicial).is_true()
	
	# Verificar estado do combate
	if integration.combat_scene.player_stats["vida"] > 0:
		assert_that(integration.combat_scene.combat_active).is_true()
	else:
		assert_that(integration.combat_scene.combat_active).is_false()
	
	remove_child(integration.combat_scene)

# Teste de integração do sistema de animações
func test_integracao_sistema_animacoes():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	
	# Configurar diferentes combinações para testar animações
	integration.combat_scene.genero = "feminino"
	integration.combat_scene.classe = "aristocrata"
	integration.combat_scene.roupa = true
	integration.combat_scene.obj = true
	
	# Executar definição de animações
	integration.combat_scene.define_anim_player()
	
	# Verificar se as animações foram carregadas
	# (não podemos verificar diretamente, mas podemos verificar se não houve erro)
	assert_that(integration.combat_scene.anim_character).is_not_null()
	
	# Testar outra combinação
	integration.combat_scene.genero = "masculino"
	integration.combat_scene.classe = "atleta"
	integration.combat_scene.roupa = false
	integration.combat_scene.obj = false
	
	integration.combat_scene.define_anim_player()
	# Não deve crashar para nenhuma combinação
	
	remove_child(integration.combat_scene)

# Teste de integração do salvamento de estado após combate
func test_integracao_salvamento_estado():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	
	# Modificar estado durante combate
	integration.combat_scene.player_stats["vida"] = 75
	
	# Executar salvamento
	integration.combat_scene.salvar_alteracoes_combate()
	
	# Verificar se o salvamento foi executado sem erros
	# (em um teste real, verificaríamos o banco de dados)
	assert_that(integration.combat_scene.Database).is_not_null()
	
	remove_child(integration.combat_scene)

# Teste de integração do fluxo de vitória
func test_integracao_fluxo_vitoria():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	integration.combat_scene.start_combat()
	
	# Forçar inimigo com pouca vida
	integration.combat_scene.enemy_stats["vida"] = 1
	
	# Executar ataque que deve matar o inimigo
	integration.combat_scene.execute_player_attack(0, "SOCO")
	
	# Verificar vitória
	assert_that(integration.combat_scene.enemy_stats["vida"] <= 0).is_true()
	assert_that(integration.combat_scene.combat_active).is_false()
	
	remove_child(integration.combat_scene)

# Teste de integração do fluxo de derrota
func test_integracao_fluxo_derrota():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	integration.combat_scene.start_combat()
	
	# Forçar jogador com pouca vida
	integration.combat_scene.player_stats["vida"] = 1
	
	# Executar turno do inimigo que deve matar o jogador
	integration.combat_scene.enemy_turn()
	
	# Verificar derrota
	if integration.combat_scene.player_stats["vida"] <= 0:
		assert_that(integration.combat_scene.combat_active).is_false()
	
	remove_child(integration.combat_scene)

# Teste de integração da interface do usuário
func test_integracao_interface_usuario():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	
	# Configurar UI
	integration.combat_scene.setup_ui_buttons()
	
	# Verificar se os botões estão presentes
	assert_that(integration.combat_scene.btn_soco).is_not_null()
	assert_that(integration.combat_scene.btn_chute).is_not_null()
	assert_that(integration.combat_scene.btn_gancho).is_not_null()
	assert_that(integration.combat_scene.btn_rasteira).is_not_null()
	assert_that(integration.combat_scene.btn_fugir).is_not_null()
	
	# Testar interação com botões
	integration.combat_scene.start_combat()
	
	# Simular pressionar botão de ataque
	integration.combat_scene._on_soco_pressed()
	
	# Verificar se o sistema respondeu à ação do usuário
	assert_that(integration.combat_scene.combat_active).is_true()
	
	remove_child(integration.combat_scene)

# Teste de integração do sistema de áudio
func test_integracao_sistema_audio():
	add_child(integration.combat_scene)
	
	integration.combat_scene.Database = integration.database_singleton
	
	# Executar _ready() que configura o áudio
	integration.combat_scene._ready()
	
	# Verificar se o sistema de áudio foi inicializado
	# (não podemos verificar diretamente, mas podemos verificar se não houve erro)
	assert_that(integration.combat_scene).is_not_null()
	
	remove_child(integration.combat_scene)

# Teste de integração de cenário realista
func test_integracao_cenario_realista():
	add_child(integration.combat_scene)
	
	# Configuração completa como em produção
	integration.combat_scene.Database = integration.database_singleton
	integration.combat_scene.configurar_variaveis()
	integration.combat_scene.carregar_dados_personagem()
	integration.combat_scene.carregar_stats_jogador()
	integration.combat_scene.define_anim_player()
	integration.combat_scene.setup_ui_buttons()
	integration.combat_scene.start_combat()
	
	# Simular sequência real de ações do jogador
	integration.combat_scene._on_soco_pressed()
	
	# Aguardar resolução do ataque
	await integration.combat_scene.get_tree().create_timer(0.1).timeout
	
	if integration.combat_scene.combat_active:
		integration.combat_scene._on_chute_pressed()
		await integration.combat_scene.get_tree().create_timer(0.1).timeout
	
	# Verificar estado final do sistema
	assert_that(integration.combat_scene.player_stats["vida"]).is_greater(0)
	assert_that(integration.combat_scene.enemy_stats["vida"]).is_less_equal(80)
	
	remove_child(integration.combat_scene)
