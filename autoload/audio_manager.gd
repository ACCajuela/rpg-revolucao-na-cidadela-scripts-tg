extends Node

# Signals (sem mudanças)
signal music_changed(music_name)
signal music_stopped()
signal sfx_played(sfx_name)

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music: String = ""
var fade_tween: Tween

# Bibliotecas (sem mudanças)
var music_library = {
	"menu_principal": "res://front/sounds/trilha_sonora/music_background.mp3",
	"bedroom": "res://front/sounds/trilha_sonora/bedroom_sound.mp3",
	"combat": "res://front/sounds/trilha_sonora/final_boss_battle__rod_kim.mp3",
	"end": "res://front/sounds/trilha_sonora/Impending Boom - Kevin MacLeod.mp3",
}
var sfx_library = {
	"ui_click": "res://front/sounds/sfx/click_blocks.mp3",
	"op_sound": "res://front/sounds/sfx/opening_sound.mp3",
	"hover_btn": "res://front/sounds/sfx/hover_btn.mp3"
}

func _ready():
	setup_audio_players()
	print("AudioManager carregado!")

# Função para carregar as configurações anteriores salvas de áudio
func carregar_configuracoes_globais():
	var configs = Database.load_settings()
	
	# Aplica os volumes diretamente nos Buses da Godot
	set_master_volume(configs.get("volume_master", 80.0))
	set_music_volume(configs.get("volume_musica", 70.0))
	set_sfx_volume(configs.get("volume_sfx", 90.0))
	set_dialogue_volume(configs.get("volume_dialogo", 100.0))
	
	# Configuração de tipo de saída de áudio
	var modo_salvo = configs.get("config_audio", "Estéreo")
	# Converte String para o Índice do seu OptionButton
	var indices = {"Estéreo": 0, "Mono": 1, "Som Surround": 2, "Som Espacial": 3}
	definir_modo_saida(indices.get(modo_salvo, 0))

# Função para definir a 'configuração de som' do jogo
func definir_modo_saida(indice: int):
	match indice:
		0: # Estéreo (Padrão)
			_configurar_efeito_mono(false)
			print("Modo de áudio: Estéreo")
		1: # Mono
			_configurar_efeito_mono(true)
			print("Modo de áudio: Mono")
		2: # Som Surround
			_configurar_efeito_mono(false)
			# Na Godot 4, o surround é automático. Se o hardware permitir, 
			# a Godot enviará os canais extras.
			print("Modo de áudio: Surround (Depende do Hardware)")
		3: # Som Espacial (HRTF)
			_configurar_efeito_mono(false)
			# Para ativar HRTF globalmente na Godot 4, alteramos a configuração de projeto.
			# Nota: Pode exigir reinicialização do áudio ou da cena para aplicar totalmente.
			ProjectSettings.set_setting("audio/general/3d_panning_model", 1) # 1 é o modelo HRTF
			print("Modo de áudio: Espacial (HRTF ativado nas configurações)")

func _configurar_efeito_mono(ativar: bool):
	var master_bus_idx = AudioServer.get_bus_index("Master")
	
	# Procuramos se já existe um efeito de StereoEnhance para fazer o downmix
	var efeito_idx = -1
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectStereoEnhance:
			efeito_idx = i
			break
	
	if ativar:
		if efeito_idx == -1:
			var mono_effect = AudioEffectStereoEnhance.new()
			mono_effect.surround = 0.0 # Reduz a separação estéreo
			AudioServer.add_bus_effect(master_bus_idx, mono_effect)
	else:
		if efeito_idx != -1:
			AudioServer.remove_bus_effect(master_bus_idx, efeito_idx)
	
func setup_audio_players():
	# Configurar player de música
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" # <-- MUDANÇA IMPORTANTE
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	# Configurar players de SFX (pool de 10 players)
	for i in range(10):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_" + str(i)
		sfx_player.bus = "SFX" # <-- MUDANÇA IMPORTANTE
		add_child(sfx_player)
		sfx_players.append(sfx_player)

# === FUNÇÕES DE MÚSICA ===
# play_music_by_name e stop_music NÃO PRECISAM MUDAR
# O fade_tween (music_player.volume_db) vai funcionar 
# independentemente do volume do Bus!
func play_music_by_name(music_name: String, fade_duration: float = 1.0):
	if music_name == "stop":
		stop_music(fade_duration)
		return
	
	if not music_name in music_library:
		push_error("Música não encontrada: " + music_name)
		return
	
	if current_music == music_name and music_player.playing:
		return
	
	var music_path = music_library[music_name]
	var music = load(music_path)
	
	if music:
		current_music = music_name
		music_player.stream = music
		
		if fade_duration > 0:
			if fade_tween and fade_tween.is_valid():
				fade_tween.kill()
			
			# Este volume é do PLAYER, o fade continua funcionando
			music_player.volume_db = -80.0 
			music_player.play()
			fade_tween = create_tween()
			fade_tween.tween_property(music_player, "volume_db", 0.0, fade_duration)
		else:
			music_player.volume_db = 0.0
			music_player.play()
		
		music_changed.emit(music_name)

func stop_music(fade_duration: float = 1.0):
	if fade_duration > 0 and music_player.playing:
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		await fade_tween.finished
		music_player.stop()
	else:
		music_player.stop()
	
	current_music = ""
	music_stopped.emit()

# === FUNÇÕES DE SFX ===
# play_sfx e get_available_sfx_player NÃO PRECISAM MUDAR
func play_sfx(sfx_name: String, volume: float = 1.0, pitch: float = 1.0):
	if not sfx_name in sfx_library:
		push_error("SFX não encontrado: " + sfx_name)
		return
	
	var sfx_path = sfx_library[sfx_name]
	var sfx = load(sfx_path)
	
	if sfx:
		var available_player = get_available_sfx_player()
		if available_player:
			available_player.stream = sfx
			available_player.volume_db = linear_to_db(volume)
			available_player.pitch_scale = pitch
			available_player.play()
			sfx_played.emit(sfx_name)

func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	var new_player = AudioStreamPlayer.new()
	new_player.name = "SFXPlayer_" + str(sfx_players.size())
	new_player.bus = "SFX" # <-- MUDANÇA (para novos players)
	add_child(new_player)
	sfx_players.append(new_player)
	return new_player

# === NOVAS FUNÇÕES DE CONTROLE DE BUS ===
# (Você também pode chamar Database.save_settings() aqui)

func set_bus_volume(bus_name: String, value_percent: float):
	# Converte 0-100 para decibéis (-80 a 0)
	# O valor 0.0001 é para evitar -infinito (log(0))
	var db = linear_to_db(clamp(value_percent / 100.0, 0.0001, 1.0))
	
	# Encontra o índice do bus pelo nome e aplica o volume
	var bus_idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_idx, db)

# Funções que seu menu de configurações vai chamar
func set_master_volume(percent: float):
	set_bus_volume("Master", percent)

func set_music_volume(percent: float):
	set_bus_volume("Music", percent)

func set_sfx_volume(percent: float):
	set_bus_volume("SFX", percent)

func set_dialogue_volume(percent: float):
	set_bus_volume("Dialogue", percent)

# Funções para carregar as configurações e aplicar nos sliders
func get_bus_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	var db = AudioServer.get_bus_volume_db(bus_idx)
	# Converte de decibéis para 0-100
	return db_to_linear(db) * 100.0

# === OUTRAS FUNÇÕES ===
func _on_music_finished():
	if music_player.stream and current_music != "":
		music_player.play()

func cleanup():
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
