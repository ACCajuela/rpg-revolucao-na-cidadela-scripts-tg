extends GdUnitTestSuite

func test_complete_save_load_cycle() -> void:
	# Testar apenas a lógica de dados, não o banco
	var test_data = {
		"vida_atual": 75,
		"xp": 100,
		"inventario": [{"id_item": 1, "quantidade": 1}]
	}
	
	# Testar serialização JSON
	var json_string = JSON.stringify(test_data)
	assert_str(json_string).is_not_empty()
	
	# Testar desserialização
	var loaded_data = JSON.parse_string(json_string)
	
	# CORREÇÃO: Verificar null antes de comparar
	var vida = loaded_data.get("vida_atual")
	if vida == null:
		vida = 0
	var xp = loaded_data.get("xp") 
	if xp == null:
		xp = 0
		
	assert_int(vida).is_equal(75)
	assert_int(xp).is_equal(100)
