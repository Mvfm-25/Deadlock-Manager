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

# Cor do fundo da barra de hp de cada equipe; o preenchimento usa a cor do tiro.
const CORES_FUNDO_HP = {
	"HiddenKing": Color.BLACK,
	"ArchMother": Color.WHITE,
}
const ALTURA_BARRA_HP = 80.0
const MARGEM_BARRA_HP = 60.0

const LARGURA_DEBUG = 30.0
const PONTA_SETA_DEBUG = 200.0

# Emitido ao morrer; a Onda usa para saber quando re-spawnar.
signal morreu

@export var hp:int = 10
var hp_atual = 10 :
	set(valor) :
		hp_atual = valor
		queue_redraw()

# Quanto de hp cada tiro tira do alvo
@export var dano:int = 1

# Valor default
@export var equipe = "Espiritos"

var aliadosEmRaio = []
var inimigosEmRaio = []

var alvo:Minion = null
var listaPrioritariaAlvos = []

# Quantas vezes o raio da hit box a visão alcança
@export var alcanceVisao:float = 3.0

# Onda a que pertence e o seu lugar na formação dela. Quem preenche é a Onda.
var onda:Onda = null
var indice:int = 0

# Pixels por segundo. Maior que a velocidade da onda, para conseguir alcançá-la.
@export var velocidade:float = 450.0

# Desenho de debug (visão e alvo), ligado e desligado pela tecla 'V'.
var mostraDebug = false
var debug:Node2D = null

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

# Alvos de última opção só levam tiro quando não há outro inimigo à vista.
# O Guardiao sobrescreve.
func alvoDeUltimaOpcao() -> bool :
	return false

# Reordena 'listaPrioritariaAlvos' por hp_atual (maior primeiro), com os alvos
# de última opção no fim, e, caso não esteja atirando em ninguém, começa a
# atirar no primeiro da lista. Quem atira num alvo de última opção troca assim
# que aparece outro inimigo.
# Minions mortos (escondidos) são ignorados e deixam de ser alvo.
func reavaliaAlvos() -> void :
	listaPrioritariaAlvos = inimigosEmRaio.filter(func(m): return m.visible)
	listaPrioritariaAlvos.sort_custom(func(a, b):
		if a.alvoDeUltimaOpcao() != b.alvoDeUltimaOpcao() :
			return b.alvoDeUltimaOpcao()
		return a.hp_atual > b.hp_atual)
	if alvo != null and not alvo.visible :
		alvo = null
	if listaPrioritariaAlvos.is_empty() :
		$Cadencia.stop()
	elif alvo == null :
		alvo = listaPrioritariaAlvos[0]
		$Cadencia.start()
	elif alvo.alvoDeUltimaOpcao() and not listaPrioritariaAlvos[0].alvoDeUltimaOpcao() :
		alvo = listaPrioritariaAlvos[0]

# Chamada a cada timeout do Timer 'Cadencia', enquanto houver alvo.
func atira() -> void :
	# O alvo pode ter sido morto por outro minion desde o último tiro.
	if alvo != null and not alvo.visible :
		reavaliaAlvos()
	if alvo == null :
		$Cadencia.stop()
		return
	desenhaTracer(alvo.global_position)
	alvo.hp_atual -= dano
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


# Barra de hp acima da cabeça, da largura da hit box: o fundo e, por cima, a
# fração de hp que resta, nas cores da equipe.
func _draw() -> void :
	var raio = $HitBox/CollisionShape2D.shape.radius
	var canto = Vector2(-raio, -raio - MARGEM_BARRA_HP - ALTURA_BARRA_HP)
	var fracao = clamp(float(hp_atual) / hp, 0.0, 1.0)
	draw_rect(Rect2(canto, Vector2(raio * 2.0, ALTURA_BARRA_HP)), CORES_FUNDO_HP.get(equipe, Color.DIM_GRAY))
	draw_rect(Rect2(canto, Vector2(raio * 2.0 * fracao, ALTURA_BARRA_HP)), CORES_TIRO.get(equipe, Color.WHITE))


func _ready() -> void:
	# Nó à parte para o desenho de debug, para ficar por cima dos sprites.
	debug = Node2D.new()
	debug.z_index = 2
	debug.draw.connect(desenhaDebug)
	add_child(debug)
	ajustaColisoes()
	hp_atual = hp


# A tecla 'V' liga e desliga o desenho de debug.
func _unhandled_key_input(event: InputEvent) -> void :
	if event.is_pressed() and not event.is_echo() and (event as InputEventKey).keycode == KEY_V :
		mostraDebug = not mostraDebug
		debug.queue_redraw()

# Desenho de debug: o campo de visão, na cor da equipe, e uma seta vermelha até
# a borda do alvo atual.
func desenhaDebug() -> void :
	if not mostraDebug :
		return
	var raioVisao = $Visao/CollisionShape2D.shape.radius
	debug.draw_arc(Vector2.ZERO, raioVisao, 0, TAU, 64, CORES_TIRO.get(equipe, Color.WHITE), LARGURA_DEBUG)
	if alvo == null :
		return
	var direcao = to_local(alvo.global_position).normalized()
	var ponta = to_local(alvo.global_position) - direcao * alvo.get_node("HitBox/CollisionShape2D").shape.radius
	debug.draw_line(Vector2.ZERO, ponta, Color.RED, LARGURA_DEBUG)
	debug.draw_line(ponta, ponta - direcao.rotated(PI / 6) * PONTA_SETA_DEBUG, Color.RED, LARGURA_DEBUG)
	debug.draw_line(ponta, ponta - direcao.rotated(-PI / 6) * PONTA_SETA_DEBUG, Color.RED, LARGURA_DEBUG)


# Com alvo, fica parado atirando. Sem alvo, vai ajudar o colega de onda que
# estiver em combate, até o alvo dele entrar na sua visão; se ninguém estiver,
# anda até o seu lugar na formação da onda.
func _process(delta: float) -> void:
	if mostraDebug :
		debug.queue_redraw()
	if onda == null or not visible or alvo != null :
		return
	var destino = onda.posicaoNaFormacao(indice)
	var alvoDeColega = onda.alvoMaisProximo(global_position)
	if alvoDeColega != null :
		destino = alvoDeColega.global_position
	global_position = global_position.move_toward(destino, velocidade * delta)
