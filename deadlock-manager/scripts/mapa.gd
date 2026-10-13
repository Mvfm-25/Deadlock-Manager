extends Node2D

# Fim de jogo: mostra quem capturou o ponto e congela a partida.
func _on_ponto_controle_capturado(equipe: String) -> void :
	$Interface/FimDeJogo.text = "%s capturou o ponto!" % equipe
	$Interface/FimDeJogo.show()
	get_tree().paused = true
