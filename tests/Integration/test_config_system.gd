extends GdUnitTestSuite

class TestConfigIntegration:
	var config_system: Node
	var database_singleton: Node
	
	func _init():
		# Carregar o sistema de configuração real
		config_system = load("res://caminho/para/seu/config_system.tscn").instantiate()
		database_singleton = Engine.get_main_loop().root.get_node_or_null("Database")
	
	func cleanup():
		if config_system:
			config_system.queue_free()

var integration: TestConfigIntegration

func before_test():
	integration = TestConfigIntegration.new()

func after_test():
	integration.cleanup()
	integration = null

func test_settings_persistence():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	# Dados de teste para configurações
	var test_settings = {
		"volume_total": 85,
		"volume_dialogo": 90,
		"volume_musica": 75,
		"tamanho_fonte": 18,
		"filtro_daltonismo": "Protanopia",
		"apoio_sonoro": true
	}
	
	# Salvar configurações
	var save_success = integration.config_system.Database.save_settings(test_settings)
	assert_that(save_success).is_true()
	
	# Carregar configurações
	var loaded_settings = integration.config_system.Database.load_settings()
	
	# VERIFICAÇÕES CORRIGIDAS
	assert_that(loaded_settings).is_not_null()
	assert_that(loaded_settings.has("volume_total")).is_true()
	assert_that(loaded_settings.has("tamanho_fonte")).is_true()
	
	# SOLUÇÃO: Usar float diretamente para comparação
	assert_that(loaded_settings["volume_total"]).is_equal(85.0)
	assert_that(loaded_settings["tamanho_fonte"]).is_equal(18.0)
	
	# Verificar outros valores
	assert_that(loaded_settings["volume_dialogo"]).is_equal(90.0)
	assert_that(loaded_settings["volume_musica"]).is_equal(75.0)
	assert_that(loaded_settings["filtro_daltonismo"]).is_equal("Protanopia")
	assert_that(loaded_settings["apoio_sonoro"]).is_true()
	
	remove_child(integration.config_system)

# Teste adicional para verificar tipos de dados
func test_settings_data_types():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	var test_settings = {
		"volume_total": 100,      # int
		"volume_dialogo": 85.5,   # float
		"tamanho_fonte": 16       # int
	}
	
	# Salvar e carregar
	integration.config_system.Database.save_settings(test_settings)
	var loaded_settings = integration.config_system.Database.load_settings()
	
	# Verificar tipos dos dados carregados
	assert_that(loaded_settings["volume_total"] is float or loaded_settings["volume_total"] is int).is_true()
	assert_that(loaded_settings["volume_dialogo"] is float).is_true()
	assert_that(loaded_settings["tamanho_fonte"] is float or loaded_settings["tamanho_fonte"] is int).is_true()
	
	# Verificar valores independentemente do tipo
	assert_that(float(loaded_settings["volume_total"])).is_equal(100.0)
	assert_that(float(loaded_settings["volume_dialogo"])).is_equal(85.5)
	assert_that(float(loaded_settings["tamanho_fonte"])).is_equal(16.0)
	
	remove_child(integration.config_system)

# Teste para configurações padrão
func test_default_settings():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	# Carregar configurações (pode ser a primeira vez)
	var settings = integration.config_system.Database.load_settings()
	
	# Verificar se as configurações têm estrutura básica
	assert_that(settings).is_not_null()
	
	# Se estiver vazio, pode ser a primeira execução
	if settings.is_empty():
		print("Configurações vazias - primeira execução?")
		# Não falha o teste, apenas registra
	else:
		# Verificar tipos dos valores existentes
		for key in settings:
			var value = settings[key]
			# Verificar se os valores numéricos podem ser convertidos para float
			if value is int or value is float:
				assert_that(float(value)).is_greater_equal(0.0)
	
	remove_child(integration.config_system)

# Teste de persistência após múltiplas salvagens
func test_settings_multiple_saves():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	# Primeiro salvamento
	var settings1 = {
		"volume_total": 50,
		"tamanho_fonte": 14
	}
	integration.config_system.Database.save_settings(settings1)
	
	# Segundo salvamento
	var settings2 = {
		"volume_total": 75,
		"tamanho_fonte": 16,
		"novo_setting": "valor_novo"
	}
	integration.config_system.Database.save_settings(settings2)
	
	# Carregar e verificar
	var loaded = integration.config_system.Database.load_settings()
	
	# Deve ter os valores mais recentes
	assert_that(float(loaded["volume_total"])).is_equal(75.0)
	assert_that(float(loaded["tamanho_fonte"])).is_equal(16.0)
	assert_that(loaded["novo_setting"]).is_equal("valor_novo")
	
	remove_child(integration.config_system)

# Teste de configurações com valores extremos
func test_settings_edge_cases():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	var edge_settings = {
		"volume_total": 0,        # valor mínimo
		"volume_dialogo": 100.0,  # valor máximo como float
		"tamanho_fonte": 1,       # valor mínimo
		"texto_vazio": "",
		"valor_nulo": null
	}
	
	var save_success = integration.config_system.Database.save_settings(edge_settings)
	assert_that(save_success).is_true()
	
	var loaded = integration.config_system.Database.load_settings()
	
	# Verificar valores extremos
	assert_that(float(loaded["volume_total"])).is_equal(0.0)
	assert_that(float(loaded["volume_dialogo"])).is_equal(100.0)
	assert_that(float(loaded["tamanho_fonte"])).is_equal(1.0)
	assert_that(loaded["texto_vazio"]).is_equal("")
	
	remove_child(integration.config_system)

# Teste adicional para verificar precisão dos floats
func test_float_precision():
	add_child(integration.config_system)
	
	integration.config_system.Database = integration.database_singleton
	
	var precise_settings = {
		"volume_total": 85.123456,  # Float com alta precisão
		"volume_dialogo": 50.5,     # Float com .5
		"tamanho_fonte": 12.0       # Float explícito
	}
	
	integration.config_system.Database.save_settings(precise_settings)
	var loaded = integration.config_system.Database.load_settings()
	
	# Para floats com alta precisão, podemos verificar se estão próximos
	# usando uma função helper se necessário
	assert_that(loaded["volume_total"]).is_equal(85.123456)
	assert_that(loaded["volume_dialogo"]).is_equal(50.5)
	assert_that(loaded["tamanho_fonte"]).is_equal(12.0)
	
	remove_child(integration.config_system)
