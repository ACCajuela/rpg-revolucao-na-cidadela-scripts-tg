extends CanvasLayer

@onready var loading_ui = $"."
@onready var anim_dots = $AnimationPlayer
var next_scene_path = ""

# --- 1. A CORREÇÃO PRINCIPAL ESTÁ AQUI ---
# O nome do seu nó é "TipsText", não "Texto".
@onready var label_do_texto = $TipsText 

var dicas_de_loading = [
	"Nas Cidadelas, a propaganda holográfica substituiu a arte.",
	"Os Oligarcas não morrem. Suas mentes são transferidas para novos 'Vasos'.",
	"O 'Ciclo de Crescimento' foi cancelado. Agora, a ordem é cavar túneis.",
	"A 'Transição' garante a imortalidade. Mas o que acorda é apenas uma cópia perfeita.",
	"Dentro das Cidadelas, o ar é limpo, a luz é constante e não há noite.",
	"Para ter um filho na Cidadela, você precisa de autorização expressa dos Oligarcas.",
	"Dizem que 'gangues nômades' atacam as cargas fora dos muros da Cidadela.",
	"Os 'Hospedeiros' são mantidos em estado vegetativo para servir de receptáculo."
]

func _ready():
	hide()
	randomize()

func change_scene_with_loading(path: String):
	next_scene_path = path
	loading_ui.show()

	# --- 2. LÓGICA DE SORTEIO ---
	# Agora a variável 'label_do_texto' não será nula.
	# A verificação 'is_instance_valid' é uma boa prática
	# para evitar "race conditions".
	if is_instance_valid(label_do_texto):
		var texto_sorteado = dicas_de_loading[randi() % dicas_de_loading.size()]
		label_do_texto.text = texto_sorteado
	else:
		# Se você vir esta mensagem, algo muito estranho aconteceu
		print("ERRO no loading.gd: $TipsText AINDA é nulo, verifique o nome.")
	# ------------------------------------------------
	
	anim_dots.play("UpDown") 
	
	var error = ResourceLoader.load_threaded_request(next_scene_path)
	
	if error != OK:
		print("ERRO: Não foi possível iniciar o carregamento.")
		loading_ui.hide()
		await  Transitioner.fade_in()
		return
		
	while ResourceLoader.load_threaded_get_status(next_scene_path) != ResourceLoader.THREAD_LOAD_LOADED:
			await get_tree().process_frame
			await get_tree().create_timer(6.0).timeout 
			
	var new_scene_resource = ResourceLoader.load_threaded_get(next_scene_path)
	get_tree().change_scene_to_packed(new_scene_resource)
	
	anim_dots.stop()
	loading_ui.hide()
	await Transitioner.fade_in()
	
func change_scene(path: String):
	next_scene_path = path
	
	var error = ResourceLoader.load_threaded_request(next_scene_path)
	
	if error != OK:
		print("ERRO: Não foi possível iniciar o carregamento.")
		loading_ui.hide()
		await  Transitioner.fade_in()
		return
		
	while ResourceLoader.load_threaded_get_status(next_scene_path) != ResourceLoader.THREAD_LOAD_LOADED:
			await get_tree().process_frame
			await get_tree().create_timer(6.0).timeout 
			
	var new_scene_resource = ResourceLoader.load_threaded_get(next_scene_path)
	get_tree().change_scene_to_packed(new_scene_resource)
	
	await Transitioner.fade_in()
	
	
	
