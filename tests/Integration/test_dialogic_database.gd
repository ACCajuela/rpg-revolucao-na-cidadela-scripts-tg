extends GdUnitTestSuite

func test_dialogic_character_mapping() -> void:
	var bedroom_scene = load("res://scenes/ui/bedroom.tscn")
	var bedroom = auto_free(bedroom_scene.instantiate())
	var database = Engine.get_main_loop().root.get_node("Database")
	
	database.character_creation_data = {
		"nome": "Luna",
		"genero": "Feminino",
		"id_classe": 1
	}
	
	var dialogic_name = bedroom.mapear_personagem_dialogic("Aristocrata", "Feminino")
	
	print("Debug - dialogic_name: ", dialogic_name)
	
	assert_str(dialogic_name).is_equal("AristocrataFem")
	
	var player_name = database.character_creation_data.get("nome")
	print("Debug - player_name: ", player_name)
	assert_str(player_name).is_equal("Luna")
