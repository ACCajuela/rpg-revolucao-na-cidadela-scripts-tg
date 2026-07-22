extends Node

const SAVE_PATH = "user://character_data.json"
var character_data: Dictionary = {
	"nome": "",
	"genero": "",
	"classe": "",
}

# Função para SALVAR os dados no arquivo JSON
func save_character_data(data: Dictionary) -> void:
	# 1. Atualiza os dados internos
	character_data = data
	
	# 2. Converte o Dicionário para uma string JSON
	var json_string = JSON.stringify(character_data)
	
	# 3. Salva a string no arquivo
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Dados salvos com sucesso em: " + SAVE_PATH)
	else:
		push_error("Erro ao abrir arquivo para salvar.")

# Função para CARREGAR os dados do arquivo JSON
func load_character_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Arquivo de salvamento não encontrado. Retornando dados padrão.")
		return character_data # Retorna os dados padrão se não houver arquivo

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json_result = JSON.parse_string(json_string)
		
		if json_result is Dictionary:
			character_data = json_result
			print("Dados carregados com sucesso.")
			return character_data
		else:
			push_error("Erro ao analisar JSON. Retornando dados padrão.")
			return character_data
	else:
		push_error("Erro ao abrir arquivo para carregar.")
		return character_data # Retorna dados padrão em caso de erro

# Função para VERIFICAR se o arquivo de save existe
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _ready():
	load_character_data()
