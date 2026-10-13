extends Node2D

class_name Minion

# Cor do tracer de tiro de cada equipe (branco para equipes fora da lista).
const CORES_TIRO = {
	"HiddenKing": Color.YELLOW,
	"ArchMother": Color.DODGER_BLUE,
}
const LARGURA_TRACER = 40.0
const DESLOCAMENTO_TRACER = 60.0
const DURACAO_TRACER = 0.3

# Emitido ao morrer; a Onda usa para saber quando re-spawnar.
signal morreu

var hp = 10
var hp_atual = 10

# Valor default
@export var equipe = "Espiritos"

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
	desenhaTracer(alvo.global_position)
	alvo.hp_atual -= 1
	if alvo.hp_atual <= 0 :
		alvo.morre()
		reavaliaAlvos()

# Risco temporário do minion até 'destino', na cor da equipe, que some sozinho.
# Fica deslocado para a direita de quem atira, para que os tiros de ida e de
# volta entre dois minions não se sobreponham.
func desenhaTracer(destino:Vector2) -> void :
	var fim = to_local(destino)
	var lado = fim.normalized().orthogonal() * -DESLOCAMENTO_TRACER
	var tracer = Line2D.new()
	tracer.points = [lado, fim + lado]
	tracer.width = LARGURA_TRACER
	tracer.default_color = CORES_TIRO.get(equipe, Color.WHITE)
	tracer.z_index = 1
	add_child(tracer)
	var tween = tracer.create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, DURACAO_TRACER)
	tween.tween_callback(tracer.queue_free)

# Deixa de ser desenhado e some da visão dos outros minions. Desligar os
# CollisionShape2D dispara 'area_exited' em quem o via (desligar apenas
# 'monitorable' na Area2D não dispara).
func morre() -> void :
	# Já está morto: evita emitir 'morreu' duas vezes se dois minions o matarem no mesmo frame.
	if not visible :
		return
	hide()
	alvo = null
	$Cadencia.stop()
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	$Visao/CollisionShape2D.set_deferred("disabled", true)
	morreu.emit()

# Move para 'posicao' & volta a desenhar o minion com a vida cheia. Quem decide quando é a Onda.
# Religar a Visao dispara 'area_entered' para quem já está no raio, o que reinicia a Cadencia.
func spawn(posicao:Vector2) -> void :
	global_position = posicao
	hp_atual = hp
	show()
	$HitBox/CollisionShape2D.set_deferred("disabled", false)
	$Visao/CollisionShape2D.set_deferred("disabled", false)


func _ready() -> void:
	ajustaColisoes()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
