extends CanvasLayer

@onready var anim_player = $ColorRect/AnimationPlayer
var next_scene_path = ""

func change_scene_to(path: String):
	next_scene_path = path
	
	anim_player.play("FadeOut") # Escurece a cena atual
	await anim_player.animation_finished # Espera o FadeOut terminar
	# Em vez de mudar direto, usamos o call_deferred para segurança
	get_tree().call_deferred("change_scene_to_file", next_scene_path) # Muda a cena
	
	await  get_tree().process_frame
	anim_player.play("FadeIn") # Clarea para a próxima cena
	if next_scene_path == "quit": get_tree().quit() # Se for sair do jogo

func fade_out():
	anim_player.play("FadeOut")
	await anim_player.animation_finished
	
func fade_in():
	anim_player.play("FadeIn")
	await anim_player.animation_finished
