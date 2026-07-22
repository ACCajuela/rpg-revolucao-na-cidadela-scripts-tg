# game_state.gd
extends Node

var current_save_id: int = -1
var dados_do_jogador: Dictionary = {}

func completar_missao(id_missao: int) -> void:
	if dados_do_jogador.has("missoes"):
		for m in dados_do_jogador["missoes"]:
			if m["id"] == id_missao:
				m["completa"] = true
				print("Missão ", id_missao, " marcada como completa no GameState.")
				Database.save_game(current_save_id, dados_do_jogador)
				break

func aplicar_efeito_item(item: Dictionary) -> void:
	print("💾 current_save_id: ", current_save_id)

	if dados_do_jogador.is_empty():
		print("❌ dados_do_jogador vazio!")
		return

	var tipo: String = item.get("item_type", "")
	if tipo == "Equipamento":
		print("⚔️ Equipamento — bônus calculado pelo StatusMenu")
		return

	var efeito: String = item.get("effect", "")
	if efeito.is_empty():
		print("⚠️ Item sem efeito: ", item.get("name", "?"))
		return

	var partes = efeito.split(" ")
	if partes.size() < 2:
		print("⚠️ Formato de efeito inválido: ", efeito)
		return

	var valor: int = int(partes[0])
	var stat: String = partes[1].to_lower()

	match stat:
		"vida":
			var vida_atual = dados_do_jogador.get("vida_atual", 0)
			var vida_max = dados_do_jogador.get("vida_maxima", 100)
			dados_do_jogador["vida_atual"] = clamp(vida_atual + valor, 0, vida_max)
			print("❤️ Vida: %d → %d" % [vida_atual, dados_do_jogador["vida_atual"]])
		_:
			print("ℹ️ Stat ignorado no GameState: ", stat)
			return

	if current_save_id >= 0:
		Database.save_game(current_save_id, dados_do_jogador)
		print("✅ Salvo: ", dados_do_jogador.get("vida_atual", 0))
	else:
		print("⚠️ current_save_id inválido")
