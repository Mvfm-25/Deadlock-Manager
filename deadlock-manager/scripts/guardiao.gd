extends Minion

class_name Guardiao

# Minion buffado e imóvel que barra o avanço das ondas inimigas. Não pertence a
# nenhuma Onda: por isso não anda e, depois de morto, não volta.

# Os minions só atiram no guardião quando não há minion inimigo à vista.
func alvoDeUltimaOpcao() -> bool :
	return true
