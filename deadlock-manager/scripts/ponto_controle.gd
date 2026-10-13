extends Area2D

class_name PontoControle

const LARGURA_BORDA = 40.0
const LARGURA_PROGRESSO = 100.0

# Emitido quando uma equipe completa a captura; o Mapa usa para encerrar o jogo.
signal capturado(equipe:String)

# Segundos seguidos que uma equipe precisa ficar sozinha no ponto para capturá-lo
@export var tempoCaptura:float = 30.0

var minionsNaArea = []

var equipeCapturando = ""
var tempo = 0.0

# Funções de presença no ponto, vendo quem entrou e saiu da área.
# Minions mortos saem sozinhos: 'morre()' desliga a HitBox, o que dispara 'area_exited'.
func _on_area_entered(area: Area2D) -> void :
	var minion = area.get_parent() as Minion
	if minion == null or area.name != "HitBox" :
		return
	if not minionsNaArea.has(minion) :
		minionsNaArea.append(minion)

func _on_area_exited(area: Area2D) -> void :
	var minion = area.get_parent() as Minion
	if minion == null or area.name != "HitBox" :
		return
	minionsNaArea.erase(minion)

# Equipe que está sozinha no ponto, ou "" se ele está vazio ou disputado.
func equipeSozinha() -> String :
	var equipe = ""
	for minion in minionsNaArea :
		if equipe == "" :
			equipe = minion.equipe
		elif minion.equipe != equipe :
			return ""
	return equipe

# Círculo do ponto e, por cima, um arco na cor de quem captura que se fecha com o tempo.
func _draw() -> void :
	var raio = $CollisionShape2D.shape.radius
	draw_circle(Vector2.ZERO, raio, Color(1, 1, 1, 0.15))
	draw_arc(Vector2.ZERO, raio, 0, TAU, 64, Color.WHITE, LARGURA_BORDA)
	if tempo > 0.0 :
		var cor = Minion.CORES_TIRO.get(equipeCapturando, Color.WHITE)
		var fim = -PI / 2 + TAU * tempo / tempoCaptura
		draw_arc(Vector2.ZERO, raio, -PI / 2, fim, 64, cor, LARGURA_PROGRESSO)


# A contagem só anda enquanto a mesma equipe segue sozinha no ponto; se ele
# esvazia, é disputado ou troca de mãos, volta ao zero.
func _process(delta: float) -> void:
	var equipe = equipeSozinha()
	if equipe == "" or equipe != equipeCapturando :
		equipeCapturando = equipe
		tempo = 0.0
	else :
		tempo += delta
		if tempo >= tempoCaptura :
			set_process(false)
			capturado.emit(equipe)
	queue_redraw()
