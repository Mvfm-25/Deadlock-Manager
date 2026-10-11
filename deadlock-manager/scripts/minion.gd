extends Node2D

class_name Minion

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
@export var alcanceVisao = 3.0

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
		aliadosEmRaio.append(outro)
	else :
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
func reavaliaAlvos() -> void :
	listaPrioritariaAlvos = inimigosEmRaio.duplicate()
	listaPrioritariaAlvos.sort_custom(func(a, b): return a.hp_atual > b.hp_atual)
	if listaPrioritariaAlvos.is_empty() :
		$Cadencia.stop()
	elif alvo == null :
		alvo = listaPrioritariaAlvos[0]
		$Cadencia.start()

# Chamada a cada timeout do Timer 'Cadencia', enquanto houver alvo.
func atira() -> void :
	if alvo == null :
		$Cadencia.stop()
		return
	alvo.hp_atual -= 1
	if alvo.hp_atual <= 0 :
		alvo.morre()

# Deixa de ser desenhado e some da visão dos outros minions. Desligar a
# HitBox dispara 'area_exited' em quem o via, tirando-o das listas deles.
func morre() -> void :
	hide()
	alvo = null
	$Cadencia.stop()
	$HitBox.set_deferred("monitorable", false)
	$Visao.set_deferred("monitoring", false)


func _ready() -> void:
	ajustaColisoes()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
