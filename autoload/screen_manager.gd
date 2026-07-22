extends Node

# Estrutura que guarda Nome, Tamanho e o Modo de Janela
# 0 = Janela, 3 = Tela Cheia (DisplayServer.WindowMode)
var opcoes_video = [
	{"nome": "1920x1080 Tela Cheia", "res": Vector2i(1920, 1080), "modo": DisplayServer.WINDOW_MODE_FULLSCREEN},
	{"nome": "1920x1080 Janela",    "res": Vector2i(1920, 1080), "modo": DisplayServer.WINDOW_MODE_WINDOWED},
	{"nome": "1600x900 Janela",     "res": Vector2i(1600, 900),  "modo": DisplayServer.WINDOW_MODE_WINDOWED},
	{"nome": "1366x768 Janela",     "res": Vector2i(1366, 768),  "modo": DisplayServer.WINDOW_MODE_WINDOWED},
	{"nome": "1280x720 Janela",     "res": Vector2i(1280, 720),  "modo": DisplayServer.WINDOW_MODE_WINDOWED},
	{"nome": "800x600 Janela",      "res": Vector2i(800, 600),   "modo": DisplayServer.WINDOW_MODE_WINDOWED}
]

# Mapeamento dos filtros (Nearest é ideal para Pixel Art)
var filtros_pixel = [
	{"nome": "Pixelado (Nearest)", "modo": CanvasItem.TEXTURE_FILTER_NEAREST},
	{"nome": "Suave (Linear)",    "modo": CanvasItem.TEXTURE_FILTER_LINEAR},
	{"nome": "Com Mipmaps",       "modo": CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS}
]

# Funções para aplicação do tamanho da tela
func _aplicar_video(index: int) -> void:
	var dados = opcoes_video[index]
	DisplayServer.window_set_mode(dados["modo"])
	
	if dados["modo"] == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(dados["res"])
		_centralizar_janela()

func _centralizar_janela() -> void:
	# Pequena pausa para o Godot atualizar o tamanho antes de mover
	await get_tree().process_frame
	var screen_id = DisplayServer.window_get_current_screen()
	var screen_rect = DisplayServer.screen_get_usable_rect(screen_id)
	var window_size = DisplayServer.window_get_size()
	
	var nova_pos = screen_rect.position + (screen_rect.size / 2) - (window_size / 2)
	DisplayServer.window_set_position(nova_pos)

# Configurações para filtro do pixel
func _ao_selecionar_filtro(index: int) -> void:
	_aplicar_filtro_pixel(index)
	
	# Salva no Banco de Dados
	var config = Database.load_settings()
	config["pixel_filter_index"] = index
	Database.save_settings(config)

func _aplicar_filtro_pixel(index: int) -> void:
	var modo_filtro = filtros_pixel[index]["modo"]
	
	# Isso altera o filtro padrão de todas as texturas no Canvas (2D)
	get_tree().root.canvas_item_default_texture_filter = modo_filtro

# Configuração de tamanho da fontes
const FONT_OPTIONS = {
	0: {"base": 20, "titulo": 24},
	1: {"base": 24, "titulo": 32},
	2: {"base": 32, "titulo": 45}
}

func apply_font_settings(index: int):
	var theme = load("res://front/themes/fonttheme.tres") as Theme
	if theme:
		var sizes = FONT_OPTIONS[index]
		var base_size = int(sizes["base"])
		var title_size = int(sizes["titulo"])
		
		# Aplica nos tipos base
		theme.set_font_size("font_size", "Label", base_size)
		theme.set_font_size("font_size", "Button", base_size)
		theme.set_font_size("font_size", "ButtonTitle", title_size)
		theme.set_font_size("normal_font_size", "RichTextLabel", base_size)
		theme.set_font_size("font_size", "LineEdit", base_size)
		
		# Notifica o recurso que ele mudou
		theme.emit_changed()
		
		# Sincronizamos a árvore de cenas
		_force_theme_update(theme)
	
# Função auxiliar para forçar o refresh visual	
func _force_theme_update(updated_theme: Theme):
	# Em vez de percorrer nós, vamos reatribuir o tema ao root
	# Isso limpa o cache visual da cena atual imediatamente
	get_tree().root.theme = null # Limpa a referência
	get_tree().root.theme = updated_theme # Reatribui a nova instância)
