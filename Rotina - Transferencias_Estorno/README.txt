Olá obrigado pela visita! 

- Problema: Uma situação não muito comun mas ocorre onde transfêrencias de "estorno" são informadas em datas incorretas via arquivo de retorno CNAB pelo banco. 
- Solução: Feito via manual, APSDU ou linhas de comando SQL temos que fazer uma alteração em diversas tabelas e executar rotinas para enfim corrigir as datas. 

Falando um pouco sobre esse codigo: 
	xEstorno - Uma tela simples, te dando as opções que podem ser executadas.
	XUNOEST - Valida se o movimento foi contabilizado para permitir que seja tratado, Informamos via parâmetro de perguntas o titulo que devemos alterar e efetuamos as tratativas. 
	XDUOEST - Valida se o movimento foi contabilizado para permitir que seja tratado, Informamos via parâmetro de perguntas o titulo que devemos alterar e efetuamos as tratativas.

No codigo possui maiores comentarios sobre toda a rotina que é executada. Existe espaço para ser melhor otimizado mas no momento atende a necessidade corretamente. 







 
