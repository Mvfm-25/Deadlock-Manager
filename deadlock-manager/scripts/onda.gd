extends Node2D

class_name Onda

const CENA_MINION = preload("res://cenas/minion.tscn")

# Valor default
@export var equipe = "Espiritos"
@export var quantidade:int = 3
@export var tempoRespawn:float = 5.0

# Segundos a mais de re-spawn para cada vez que a onda já foi eliminada antes
@export var pesoRespawn:float = 3.0

# Distância entre os minions na linha de formação
@export var espacamento:float = 700.0

# Velocidade com que a onda avança pela lane, em pixels por segundo
@export var velocidade:float = 300.0

# Ponto de spawn da equipe: o nó do mapa que está no grupo "spawn_<equipe>".
var spawnPoint:Node2D = null

# Fim da lane: o spawn point inimigo, o nó do grupo "spawn" que não é o da equipe.
var destino:Node2D = null

# Quanto a onda já andou pela lane, em pixels a partir do spawn point.
var avanco = 0.0

var minions = []
var vivos = 0

# Quantas vezes a onda inteira já foi eliminada.
var mortes = 0

# Início da lane.
func origem() -> Vector2 :
	return spawnPoint.global_position if spawnPoint != null else global_position

# Vetor do início ao fim da lane: uma reta do spawn point ao spawn point inimigo.
func lane() -> Vector2 :
	return destino.global_position - origem() if destino != null else Vector2.ZERO

# Onde a onda está na lane. Os minions se movem sozinhos, cada um buscando o
# seu lugar na formação em volta deste ponto.
func ancora() -> Vector2 :
	return origem() + lane().normalized() * avanco

# Posição do i-ésimo minion: uma linha centrada na âncora, atravessada na lane.
func posicaoNaFormacao(indice:int) -> Vector2 :
	var lado = lane().normalized().orthogonal() if destino != null else Vector2.RIGHT
	var deslocamento = (indice - (quantidade - 1) / 2.0) * espacamento
	return ancora() + lado * deslocamento

# A onda está em combate enquanto algum minion vivo dela tiver alvo.
func emCombate() -> bool :
	return minions.any(func(m): return m.visible and m.alvo != null)

# Cria os minions da onda, já em formação.
func criaMinions() -> void :
	for i in quantidade :
		var minion = CENA_MINION.instantiate() as Minion
		minion.equipe = equipe
		minion.onda = self
		minion.indice = i
		minion.morreu.connect(_on_minion_morreu)
		add_child(minion)
		minion.global_position = posicaoNaFormacao(i)
		minions.append(minion)
	vivos = quantidade

# A onda só começa a contar o re-spawn quando o último minion morre, e demora
# mais a cada eliminação: a primeira espera 'tempoRespawn', as seguintes somam 'pesoRespawn'.
func _on_minion_morreu() -> void :
	vivos -= 1
	if vivos <= 0 :
		$Respawn.start(tempoRespawn + pesoRespawn * mortes)
		mortes += 1

# Chamada no timeout do Timer 'Respawn': a onda inteira volta de uma vez, do início da lane.
func respawna() -> void :
	avanco = 0.0
	for i in minions.size() :
		minions[i].spawn(posicaoNaFormacao(i))
	vivos = minions.size()


func _ready() -> void:
	spawnPoint = get_tree().get_first_node_in_group("spawn_" + equipe) as Node2D
	if spawnPoint == null :
		push_warning("Onda '%s': nenhum spawn point no grupo 'spawn_%s'." % [name, equipe])
	for spawn in get_tree().get_nodes_in_group("spawn") :
		if spawn != spawnPoint :
			destino = spawn as Node2D
			break
	if destino == null :
		push_warning("Onda '%s': nenhum spawn point inimigo no grupo 'spawn'." % name)
	criaMinions()


# A onda avança até o fim da lane, mas para enquanto estiver em combate.
func _process(delta: float) -> void:
	if vivos <= 0 or emCombate() :
		return
	avanco = min(avanco + velocidade * delta, lane().length())
