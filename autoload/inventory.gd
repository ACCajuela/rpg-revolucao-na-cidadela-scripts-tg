extends Node

# Array do Inventário de Itens
var inventory = []

# Manda um sinal para atualizar o inventário
signal inventory_updated

#
var character_node: Node = null

func _ready():
	# Inicializa o inventório com 24 espaços
	inventory.resize(24)

#Adiciona um item ao inventário, retorna true se tiver sucesso
func add_item(item):
	print("📦 add_item() chamado com: ", item)
	print("📦 Tamanho do inventário: ", inventory.size())
	
	# Verifica se o item existe no inventário 
	for i in range(inventory.size()):
		print("📦 Slot %d: " % i, inventory[i])
		if inventory[i] != null and inventory[i]["item_type"] == item["item_type"] and inventory[i]["effect"] == item["effect"]:
			inventory[i]["quantity"] += item["quantity"] 
			inventory_updated.emit()
			print("✅ Item stackado no slot ", i)
			return true
		elif inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			print("✅ Item adicionado no slot ", i)
			return true
	print("❌ Inventário cheio!")
	return false
	
#Remove um item do inventário
func remove_item():
	inventory_updated.emit()
	
#Aumenta o tamanho do inventário de maneira dinâmica	
func increase_inventory():
	inventory_updated.emit()
