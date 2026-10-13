extends Node2D

class_name Minion

# Ponto de re-spawn da equipe: o nó do mapa que está no grupo "spawn_<equipe>".
var spawnPoint:Node2D = null

var hp = 10
var hp_atual = 10

# Valor default
@export var equipe = "Espiritos"
var tempoRespawn = 5.0

var aliadosEmRaio = []
var inimigosEmRaio = []

var alvo:Minion = null
var listaPrioritariaAlvos = []

# Quantas vezes o raio da hit box a visão alcança
@export var alcanceVisao:float = 3.0

# Ajusta a hit box e a visão ao tamanho da textura do Sprite2D
func ajustaColisoes() -> void :
	var tamanho = ($Sprite2D.get_rect().size * $Sprite2D.scale).abs()
	var raio = min(tamanho.x, tamanho.y) / 2.0
	$HitBox/CollisionShape2D.shape.radius = raio
	$Visao/CollisionShape2D.shape.radius = raio * alcanceVisao
	
# Funções de visão do minion, vendo quem entrou e saiu do seu escopo.
func _on_visao_area_entered(area: Area2D) -> void:
	var outro = area.get_parent() as Minion
	if outro == null or outro == self or area.name != "HitBox" :
		return
	if outro.equipe == equipe :
		if not aliadosEmRaio.has(outro) :
			aliadosEmRaio.append(outro)
	else :
		if not inimigosEmRaio.has(outro) :
			inimigosEmRaio.append(outro)
		reavaliaAlvos()

func _on_visao_area_exited(area : Area2D) -> void :
	var outro = area.get_parent() as Minion
	if outro == null or outro == self or area.name != "HitBox" :
		return
	aliadosEmRaio.erase(outro)
	inimigosEmRaio.erase(outro)
	if outro == alvo :
		alvo = null
	reavaliaAlvos()

# Reordena 'listaPrioritariaAlvos' por hp_atual (maior primeiro) e, caso não
# esteja atirando em ninguém, começa a atirar no primeiro da lista.
# Minions mortos (escondidos) são ignorados e deixam de ser alvo.
func reavaliaAlvos() -> void :
	listaPrioritariaAlvos = inimigosEmRaio.filter(func(m): return m.visible)
	listaPrioritariaAlvos.sort_custom(func(a, b): return a.hp_atual > b.hp_atual)
	if alvo != null and not alvo.visible :
		alvo = null
	if listaPrioritariaAlvos.is_empty() :
		$Cadencia.stop()
	elif alvo == null :
		alvo = listaPrioritariaAlvos[0]
		$Cadencia.start()

# Chamada a cada timeout do Timer 'Cadencia', enquanto houver alvo.
func atira() -> void :
	# O alvo pode ter sido morto por outro minion desde o último tiro.
	if alvo != null and not alvo.visible :
		reavaliaAlvos()
	if alvo == null :
		$Cadencia.stop()
		return
	alvo.hp_atual -= 1
	if alvo.hp_atual <= 0 :
		alvo.morre()
		reavaliaAlvos()

# Deixa de ser desenhado e some da visão dos outros minions. Quem o via só
# recebe 'area_exited' quando ele se move no re-spawn; até lá, é ignorado
# por estar escondido (ver 'reavaliaAlvos').
func morre() -> void :
	# Já está morto: evita re-spawn duplicado se dois minions o matarem no mesmo frame.
	if not visible :
		return
	hide()
	alvo = null
	$Cadencia.stop()
	$HitBox.set_deferred("monitorable", false)
	$Visao.set_deferred("monitoring", false)
	spawn()

# Move para o spawn point da equipe & volta a desenhar minion após seu tempo determinado de re-spawn.
# Religar a Visao dispara 'area_entered' para quem já está no raio, o que reinicia a Cadencia.
func spawn() -> void :
	await get_tree().create_timer(tempoRespawn).timeout
	if spawnPoint != null :
		global_position = spawnPoint.global_position
	hp_atual = hp
	show()
	$HitBox.set_deferred("monitorable", true)
	$Visao.set_deferred("monitoring", true)


func _ready() -> void:
	ajustaColisoes()
	spawnPoint = get_tree().get_first_node_in_group("spawn_" + equipe) as Node2D
	if spawnPoint == null :
		push_warning("Minion '%s': nenhum spawn point no grupo 'spawn_%s'." % [name, equipe])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
