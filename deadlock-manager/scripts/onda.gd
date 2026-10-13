extends Node2D

class_name Onda

const CENA_MINION = preload("res://cenas/minion.tscn")

# Valor default
@export var equipe = "Espiritos"
@export var quantidade:int = 3
@export var tempoRespawn:float = 5.0

# Distância entre os minions na linha de formação
@export var espacamento:float = 700.0

# Ponto de spawn da equipe: o nó do mapa que está no grupo "spawn_<equipe>".
var spawnPoint:Node2D = null

var minions = []
var vivos = 0

# Posição do i-ésimo minion: uma linha horizontal centrada no spawn point.
func posicaoNaFormacao(indice:int) -> Vector2 :
	var centro = spawnPoint.global_position if spawnPoint != null else global_position
	var deslocamento = (indice - (quantidade - 1) / 2.0) * espacamento
	return centro + Vector2(deslocamento, 0)

# Cria os minions da onda, já em formação.
func criaMinions() -> void :
	for i in quantidade :
		var minion = CENA_MINION.instantiate() as Minion
		minion.equipe = equipe
		minion.morreu.connect(_on_minion_morreu)
		add_child(minion)
		minion.global_position = posicaoNaFormacao(i)
		minions.append(minion)
	vivos = quantidade

# A onda só começa a contar o re-spawn quando o último minion morre.
func _on_minion_morreu() -> void :
	vivos -= 1
	if vivos <= 0 :
		$Respawn.start(tempoRespawn)

# Chamada no timeout do Timer 'Respawn': a onda inteira volta de uma vez.
func respawna() -> void :
	for i in minions.size() :
		minions[i].spawn(posicaoNaFormacao(i))
	vivos = minions.size()


func _ready() -> void:
	spawnPoint = get_tree().get_first_node_in_group("spawn_" + equipe) as Node2D
	if spawnPoint == null :
		push_warning("Onda '%s': nenhum spawn point no grupo 'spawn_%s'." % [name, equipe])
	criaMinions()
