#database.gd
extends Node

# --- Constantes do Banco de Dados ---
const USER_DATA_DIR = "user://data"

# --- Variáveis ---
var db: SQLite # Variável para a conexão com o banco
var character_creation_data: Dictionary = {}
# Dicionário para guardar como o character do jogador está
var current_equipment: Dictionary = {
	"Roupa": false,
	"Objeto": false
}

#==============================================================================
# FUNÇÕES DO GODOT
#==============================================================================

# CORREÇÃO 1: Adicionada verificação de nulo antes de iterar query_result
func fetch_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if db.query_result == null:
		return result

	for row in db.query_result:
		result.append(row)

	return result

# Chamada quando o nó (e o jogo, por ser AutoLoad) é iniciado.
func _ready() -> void:
	db = SQLite.new()

	print("🎮 Iniciando Database...")

	db.path = "user://game.db"

	if not db.open_db():
		push_error("❌ CRÍTICO: Não foi possível criar banco")
		return

	print("✅ Banco criado em: user://game.db")

	_initialize_schema()
	_populate_initial_data()


# CORREÇÃO 2: Variável atributos inicializada como Array (era Dictionary)
func _value_atributo(nome_classe: String) -> Array:
	var atributos: Array = []
	if nome_classe == "Aristocrata":
		atributos = db.select_rows("classes_ou_itens", "nome == 'Aristocrata'", ["descricao", "forca", "defesa", "inteligencia", "vida"])
	else:
		atributos = db.select_rows("classes_ou_itens", "nome == 'Atleta'", ["descricao", "forca", "defesa", "inteligencia", "vida"])
	return atributos

# Chamada quando o jogo está prestes a ser fechado.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if db:
			db.close_db()
			print("Conexão com o banco de dados fechada.")


#==============================================================================
# FUNÇÕES DE INICIALIZAÇÃO E POPULAÇÃO
#==============================================================================

func _initialize_schema() -> void:
	print("Verificando e inicializando o esquema do banco de dados...")

	var create_salvamentos = "CREATE TABLE IF NOT EXISTS salvamentos (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, data TEXT, dados_json TEXT)"
	var create_classes_ou_itens = "CREATE TABLE IF NOT EXISTS classes_ou_itens (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, descricao TEXT, forca INTEGER, defesa INTEGER, inteligencia INTEGER, vida INTEGER, classe_ou_item BOOLEAN NOT NULL DEFAULT 0 CHECK (classe_ou_item IN (0, 1)))"
	var create_dialogos = "CREATE TABLE IF NOT EXISTS dialogos (id INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT, texto TEXT, ref_audio TEXT)"
	var create_missoes = "CREATE TABLE IF NOT EXISTS missoes (id INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT, descricao TEXT, recompensa TEXT, qtd_recompensa INTEGER)"
	var create_personagens = "CREATE TABLE IF NOT EXISTS personagens (id INTEGER PRIMARY KEY AUTOINCREMENT, id_classe INTEGER NOT NULL, id_dialogo INTEGER, nome TEXT, nivel INTEGER, pontovida_maximo INTEGER, genero TEXT, FOREIGN KEY (id_classe) REFERENCES classes_ou_itens (id), FOREIGN KEY (id_dialogo) REFERENCES dialogos (id))"
	var create_npcs = "CREATE TABLE IF NOT EXISTS npcs (id INTEGER PRIMARY KEY AUTOINCREMENT, id_personagem INTEGER NOT NULL, FOREIGN KEY (id_personagem) REFERENCES personagens (id))"
	var create_configuracoes = "CREATE TABLE IF NOT EXISTS configuracoes (id INTEGER PRIMARY KEY, settings_json TEXT)"

	db.query("PRAGMA foreign_keys = ON;")
	db.query("BEGIN TRANSACTION;")
	db.query(create_salvamentos)
	db.query(create_classes_ou_itens)
	db.query(create_dialogos)
	db.query(create_missoes)
	db.query(create_configuracoes)
	db.query(create_personagens)
	db.query(create_npcs)
	db.query("COMMIT;")
	
	db.query("ALTER TABLE missoes ADD COLUMN recompensa TEXT;")
	db.query("ALTER TABLE missoes ADD COLUMN qtd_recompensa INTEGER;")
		
	# Inserir missão inicial se a tabela estiver vazia
	db.query("SELECT COUNT(*) as total FROM missoes WHERE id = 1;")
	var result = db.get_query_result()
	
	if result.size() > 0 and result[0]["total"] == 0:
		var insert_query = "INSERT INTO missoes (id, titulo, descricao, recompensa, qtd_recompensa) VALUES (1, 'Exploração Inicial', 'Encontre o ponto final no mapa.', 'Ouro', 50);"
		if not db.query(insert_query):
			print("Erro ao inserir missão inicial: ", db.error_message)
		else:
			print("✅ Missão inicial inserida com sucesso!")
	
	print("Esquema do banco de dados pronto.")

func _populate_initial_data() -> void:
	print("Populando o banco de dados com dados iniciais...")

	var _check_classes = db.select_rows("classes_ou_itens", "", ["COUNT(*)"])
	if _check_classes and _check_classes[0]["COUNT(*)"] > 0:
		print("Dados iniciais já foram inseridos anteriormente. Pulando...")
		return

	db.query("BEGIN TRANSACTION;")

	db.query("INSERT INTO classes_ou_itens (nome, descricao, forca, defesa, inteligencia, vida, classe_ou_item) VALUES ('Aristocrata', 'Você trabalha com a burocracia da cidadela.', 0, 1, 1, 10, 1);")
	db.query("INSERT INTO classes_ou_itens (nome, descricao, forca, defesa, inteligencia, vida, classe_ou_item) VALUES ('Atleta', 'Honre a cidadela ganhando campeonatos.', 1, 1, 0, 15, 1);")
	db.query("INSERT INTO classes_ou_itens (nome, descricao, forca, defesa, inteligencia, vida, classe_ou_item) VALUES ('Autorização', 'Autorização de passe livre.', 0, 0, 2, 5, 0);")
	db.query("INSERT INTO classes_ou_itens (nome, descricao, forca, defesa, inteligencia, vida, classe_ou_item) VALUES ('Uniforme do Burocrata', 'Sua roupa de trabalho.', 0, 0, 2, 5, 0);")
	db.query("INSERT INTO classes_ou_itens (nome, descricao, forca, defesa, inteligencia, vida, classe_ou_item) VALUES ('Roupas de Atletismo', 'Vista-as com orgulho de seu time.', 0, 0, 2, 5, 0);")

	var default_settings = {
		"volume_total": 80, "volume_dialogo": 100, "volume_musica": 70,
		"filtro_daltonismo": "Nenhum", "tamanho_fonte": 16, "apoio_sonoro": false
	}
	var settings_json = JSON.stringify(default_settings)
	var safe_json = settings_json.replace("\"", "\"\"")
	var settings_query = "INSERT INTO configuracoes (id, settings_json) VALUES (1, '%s');" % safe_json
	db.query(settings_query)

	db.query("COMMIT;")

	print("Dados iniciais inseridos com sucesso.")


#==============================================================================
# FUNÇÕES DE MANIPULAÇÃO DE DADOS (SAVE/LOAD)
#==============================================================================

func create_new_game(nome_personagem: String, genero_personagem: String, id_classe: int) -> int:
	var class_data_query = "SELECT forca, defesa, inteligencia, vida FROM classes_ou_itens WHERE id = %d;" % id_classe

	var query_success = db.query(class_data_query)

	if not query_success:
		push_error("Erro ao buscar dados da classe: %s" % db.error_message)
		return -1
	else:
		print("Sucesso!")

	var result = db.get_query_result()

	print("Verificando se a variavel existe: ", result)

	if result.size() == 0:
		push_error("Classe com ID %d não encontrada." % id_classe)
		return -1

	var classe_data = result[0]
	var vida_maxima = classe_data["vida"]

	var insert_personagem_query = "INSERT INTO personagens (id_classe, nome, nivel, pontovida_maximo, genero) VALUES (%d, '%s', 1, %d, '%s');" % [id_classe, nome_personagem, vida_maxima, genero_personagem]

	if not db.query(insert_personagem_query):
		push_error("Erro ao criar personagem: %s" % db.error_message)
		return -1

	var id_personagem = db.last_insert_rowid

	var initial_save_data = {
		"id_personagem": id_personagem,
		"vida_atual": vida_maxima,
		"xp": 0,
		"inventario": [
			{"id_item": 3, "quantidade": 1},
			{"id_item": 4, "quantidade": 1}
		],
		"missoes": [
			{"id": 1, "completa": false} # Primeira missão ativa por padrão
		],
		"posicao_mapa": {"x": 100, "y": 150},
		"atributos": {
			"forca": classe_data["forca"],
			"defesa": classe_data["defesa"],
			"inteligencia": classe_data["inteligencia"]
		}
	}

	var json_string = JSON.stringify(initial_save_data)

	var insert_save_query = "INSERT INTO salvamentos (nome, data, dados_json) VALUES ('%s', datetime('now', 'localtime'), '%s');" % [nome_personagem, json_string]

	if not db.query(insert_save_query):
		push_error("Erro ao criar save: %s" % db.error_message)
		return -1

	var save_id = db.last_insert_rowid
	print("🎉 Novo jogo criado para '%s' com save ID: %d" % [nome_personagem, save_id])
	print("📊 Personagem: Nível 1, Vida: %d, Força: %d, Defesa: %d, Inteligência: %d" % [
		vida_maxima, classe_data["forca"], classe_data["defesa"], classe_data["inteligencia"]
	])
	return save_id

func save_game(save_id: int, game_data: Dictionary) -> bool:
	var json_string = JSON.stringify(game_data)

	var update_query = "UPDATE salvamentos SET dados_json = '%s', data = datetime('now', 'localtime') WHERE id = %d;" % [json_string, save_id]

	if db.query(update_query):
		print("Jogo salvo com sucesso no slot %d." % save_id)
		return true
	else:
		push_error("Falha ao salvar o jogo. Erro: %s" % db.error_message)
		return false

func load_game(save_id: int) -> Dictionary:
	var select_query = "SELECT dados_json FROM salvamentos WHERE id = %d;" % save_id

	if not db.query(select_query):
		push_error("Erro ao carregar save: %s" % db.error_message)
		return {}

	# CORREÇÃO 3: era db.fetch_array() — fetch_array() é uma função local, não do db
	var result = fetch_array()

	if not result.is_empty():
		var json_string = result[0]["dados_json"]
		var parse_result = JSON.parse_string(json_string)
		if parse_result is Dictionary:
			print("Jogo carregado do slot %d." % save_id)
			return parse_result
		else:
			push_error("Falha ao parsear o JSON do save %d." % save_id)
			return {}
	else:
		push_error("Save com ID %d não encontrado." % save_id)
		return {}

# CORREÇÃO 4: era db.fetch_array() — mesma correção aplicada aqui
func get_all_saves() -> Array[Dictionary]:
	var query = "SELECT id, nome, data FROM salvamentos ORDER BY data DESC;"

	if not db.query(query):
		push_error("Erro ao buscar saves: %s" % db.error_message)
		return []

	var result = fetch_array()
	print("Encontrados %d saves." % result.size())
	return result

func save_settings(settings_data: Dictionary) -> bool:
	var json_string = JSON.stringify(settings_data)

	var update_query = "INSERT OR REPLACE INTO configuracoes (id, settings_json) VALUES (1, '%s');" % json_string

	if db.query(update_query):
		print("Configurações salvas com sucesso.")
		return true
	else:
		push_error("Erro ao salvar configurações: %s" % db.error_message)
		return false

func load_settings() -> Dictionary:
	var result = db.select_rows("configuracoes", "id = 1", ["settings_json"])

	if result and result.size() > 0:
		var json_string = result[0]["settings_json"]
		var json = JSON.new()

		if json.parse(json_string) == OK:
			var data = json.get_data()
			var font_val = data.get("tamanho_fonte_index", 1)

			if font_val is Dictionary:
				font_val = 1

			ScreenManager.apply_font_settings(int(font_val))
			return data

	var default_settings = {
		"volume_total": 80,
		"volume_dialogo": 100,
		"volume_musica": 70,
		"filtro_daltonismo": "Nenhum",
		"apoio_sonoro": false,
		"video_index": 1,
		"vsync_index": 1,
		"pixel_filter_index": 0,
		"brilho": 1.0,
		"contraste": 1.0,
		"daltonismo_intensidade": 1.0,
		"tamanho_fonte_index": 1
	}

	save_settings(default_settings)
	ScreenManager.apply_font_settings(default_settings["tamanho_fonte_index"])

	return default_settings

func reset_database() -> void:
	print("Limpando dados do banco e resetando IDs...")

	db.query("BEGIN TRANSACTION;")
	db.query("DELETE FROM salvamentos;")
	db.query("DELETE FROM npcs;")
	db.query("DELETE FROM personagens;")
	db.query("DELETE FROM missoes;")
	db.query("DELETE FROM sqlite_sequence WHERE name IN ('salvamentos', 'personagens', 'npcs');")
	db.query("COMMIT;")

	print("Dados limpos e IDs resetados com sucesso!")

func equip_item(slot_name: String, item: bool) -> void:
	current_equipment[slot_name] = item
	print("Item equipado na slot %s: %s" % [slot_name, item])

func get_equipped_item(slot_name: String):
	return current_equipment.get(slot_name, null)

func carregar_e_iniciar_game(id_do_save: int) -> void:
	var dados = load_game(id_do_save)
	if not dados.is_empty():
		GameState.current_save_id = id_do_save 
		GameState.dados_do_jogador = dados

func load_character_stats(character_id: int) -> Dictionary:
	var query = """
	SELECT
		p.id,
		p.nome as nome,
		p.nivel as nivel,
		p.pontovida_maximo as vida_maxima,
		p.genero as genero,
		c.nome as classe,
		c.descricao as descricao_classe,
		c.forca as forca,
		c.defesa as defesa,
		c.inteligencia as inteligencia,
		c.vida as vida_base
	FROM personagens p
	JOIN classes_ou_itens c ON p.id_classe = c.id
	WHERE p.id = %d
	""" % character_id

	if not db.query(query):
		push_error("Erro ao carregar stats do personagem: %s" % db.error_message)
		return {}

	var result = db.get_query_result()

	if result.is_empty():
		push_error("Personagem com ID %d não encontrado." % character_id)
		return {}

	var character_data = result[0]

	return {
		"nome": character_data["nome"],
		"vida_atual": character_data["vida_base"],
		"vida_maxima": character_data["vida_maxima"],
		"forca": character_data["forca"],
		"defesa": character_data["defesa"],
		"inteligencia": character_data["inteligencia"],
		"nivel": character_data["nivel"]
	}
