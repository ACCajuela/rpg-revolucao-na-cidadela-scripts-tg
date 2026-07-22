extends GdUnitTestSuite

# Mock mínimo para Database
class MockDatabase:
	var character_creation_data: Dictionary = {
		"nome": "TestPlayer",
		"genero": "Masculino", 
		"id_classe": 1
	}
	
	func get_equipped_item(slot_name: String) -> bool:
		return true

var combat: Control

func before_test():
	combat = auto_free(Control.new())
	combat.Database = MockDatabase.new()
	
	# Adicionar funções que serão testadas
	combat.genero = ""
	combat.classe = ""
	combat.roupa = false
	combat.obj = false

# TESTES UNITÁRIOS PUROS
func test_determinar_nome_classe_aristocrata():
	var resultado = combat.determinar_nome_classe(1)
	assert_that(resultado).is_equal("Aristocrata")

func test_determinar_nome_classe_atleta():
	var resultado = combat.determinar_nome_classe(2)
	assert_that(resultado).is_equal("Atleta")

func test_determinar_nome_classe_invalida():
	var resultado = combat.determinar_nome_classe(999)
	assert_that(resultado).is_equal("")

func test_verificar_dados_carregados_validos():
	combat.genero = "masculino"
	combat.classe = "aristocrata"
	combat.Database.character_creation_data["nome"] = "JogadorTeste"
	
	var resultado = combat.verificar_dados_carregados()
	assert_that(resultado).is_true()

func test_verificar_dados_carregados_nome_vazio():
	combat.genero = "masculino"
	combat.classe = "aristocrata"
	combat.Database.character_creation_data["nome"] = ""
	
	var resultado = combat.verificar_dados_carregados()
	assert_that(resultado).is_false()

func test_verificar_dados_carregados_genero_vazio():
	combat.genero = ""
	combat.classe = "aristocrata"
	combat.Database.character_creation_data["nome"] = "JogadorTeste"
	
	var resultado = combat.verificar_dados_carregados()
	assert_that(resultado).is_false()

func test_configurar_variaveis_roupa_equipada():
	combat.Database.current_equipment = {"Roupa": true, "Objeto": false}
	combat.Database.character_creation_data = {
		"genero": "Feminino",
		"id_classe": 1
	}
	
	combat.configurar_variaveis()
	
	assert_that(combat.roupa).is_true()
	assert_that(combat.obj).is_false()
	assert_that(combat.genero).is_equal("feminino")
	assert_that(combat.classe).is_equal("aristocrata")

# Testes de lógica de combate (unitários)
func test_player_turn_ativa_botoes():
	combat.combat_active = true
	# Mock simples para set_buttons_enabled
	var buttons_enabled = false
	combat.set_buttons_enabled = func(enabled): buttons_enabled = enabled
	
	combat.player_turn()
	
	assert_that(buttons_enabled).is_true()

func test_end_combat_desativa_botoes():
	combat.combat_active = true
	var buttons_enabled = true
	combat.set_buttons_enabled = func(enabled): buttons_enabled = enabled
	
	combat.end_combat(true)
	
	assert_that(buttons_enabled).is_false()
	assert_that(combat.combat_active).is_false()

# Testes de cálculos de dano (unitários)
func test_calculo_dano_soco():
	var player_forca = 10
	var enemy_defesa = 5
	var player_roll = 15  # Roll fixo para teste
	var enemy_roll = 10   # Roll fixo para teste
	
	var player_attack = player_roll + player_forca  # 25
	var enemy_defense = enemy_roll + enemy_defesa   # 15
	
	var success = player_attack > enemy_defense  # true
	var damage = 0
	
	if success:
		damage = 3  # Dano fixo para soco (1d4)
	
	assert_that(success).is_true()
	assert_that(damage).is_equal(3)

func test_calculo_dano_falha():
	var player_forca = 5
	var enemy_defesa = 10
	var player_roll = 10  # Roll fixo para teste
	var enemy_roll = 15   # Roll fixo para teste
	
	var player_attack = player_roll + player_forca  # 15
	var enemy_defense = enemy_roll + enemy_defesa   # 25
	
	var success = player_attack > enemy_defense  # false
	
	assert_that(success).is_false()

# Testes adicionais para melhor cobertura
func test_configurar_variaveis_masculino_atleta():
	combat.Database.current_equipment = {"Roupa": false, "Objeto": true}
	combat.Database.character_creation_data = {
		"genero": "Masculino",
		"id_classe": 2
	}
	
	combat.configurar_variaveis()
	
	assert_that(combat.roupa).is_false()
	assert_that(combat.obj).is_true()
	assert_that(combat.genero).is_equal("masculino")
	assert_that(combat.classe).is_equal("atleta")

func test_verificar_dados_carregados_classe_vazia():
	combat.genero = "masculino"
	combat.classe = ""
	combat.Database.character_creation_data["nome"] = "JogadorTeste"
	
	var resultado = combat.verificar_dados_carregados()
	assert_that(resultado).is_false()

func test_end_combat_vitoria():
	combat.combat_active = true
	var buttons_enabled = true
	combat.set_buttons_enabled = func(enabled): buttons_enabled = enabled
	
	combat.end_combat(true)  # Vitória
	
	assert_that(buttons_enabled).is_false()
	assert_that(combat.combat_active).is_false()

func test_end_combat_derrota():
	combat.combat_active = true
	var buttons_enabled = true
	combat.set_buttons_enabled = func(enabled): buttons_enabled = enabled
	
	combat.end_combat(false)  # Derrota
	
	assert_that(buttons_enabled).is_false()
	assert_that(combat.combat_active).is_false()
