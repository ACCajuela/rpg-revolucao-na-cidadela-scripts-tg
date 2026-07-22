extends Node

# Verifique se este caminho está 100% correto
const SHADER_PATH = "res://front/textures/daltonismo.gdshader"

var canvas_layer: CanvasLayer
var color_rect: ColorRect
var shader_material: ShaderMaterial

func _ready():
	# 1. Carrega o shader
	var shader = load("res://front/textures/daltonismo.gdshader")
	if shader == null:
		print("❌ Erro fatal no Autoload 'daltonismo': Shader não encontrado em ", SHADER_PATH)
		return

	# 2. Cria o material do shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# 3. Cria o ColorRect para cobrir a tela
	# Este ColorRect é o que causa a "tela branca" se o shader estiver errado
	color_rect = ColorRect.new()
	color_rect.material = shader_material
	color_rect.anchors_preset = Control.PRESET_FULL_RECT # Cobre a tela inteira
	color_rect.visible = false # Começa invisível

	# 4. Cria o CanvasLayer para ficar sobre tudo
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128 # Um valor alto para ficar sobre toda a UI
	
	# 5. Adiciona os nós na árvore
	canvas_layer.add_child(color_rect)
	add_child(canvas_layer)
	
	print("✅ Autoload 'daltonismo' pronto com CanvasLayer.")

	# Carrega as configurações assim que o jogo inicia
	var configs = Database.load_settings()
	var tipo = configs.get("filtro_daltonismo", "Normal")
	var intensidade = configs.get("intensidade_daltonismo", 1.0)
	mudar_modo_daltonico(tipo, intensidade)


# Esta é a função que seu script de UI (modoDaltonico.gd) chama
func mudar_modo_daltonico(tipo_selecionado: String, intensidade: float):
	if shader_material == null:
		print("⚠️ Autoload 'daltonismo': Shader material não está pronto.")
		return

	var tipo_id = 0
	match tipo_selecionado:
		"Protanopia":
			tipo_id = 1
		"Deuteranopia":
			tipo_id = 2
		"Tritanopia":
			tipo_id = 3
		_:
			tipo_id = 0 # Normal

	# Otimização: Se for "Normal", apenas esconde o ColorRect.
	if tipo_id == 0:
		color_rect.visible = false
		print("🎨 Filtro daltônico DESLIGADO.")
	else:
		# Aplica os parâmetros e liga o filtro
		shader_material.set_shader_parameter("tipo_daltonismo", tipo_id)
		shader_material.set_shader_parameter("intensidade", intensidade)
		color_rect.visible = true # Mostra o retângulo que aplica o filtro
		
		print("🎨 Filtro daltônico ATIVADO: ", tipo_selecionado, " (", intensidade, ")")
