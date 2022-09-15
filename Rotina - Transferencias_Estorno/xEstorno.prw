/*--------------------------------------------------------------------------------------\
| {Protheus.doc} U_XESTORNO																|
| @author Vinicius Veras																|
| @version 1.0																			|
\---------------------------------------------------------------------------------------*/
#INCLUDE "PROTHEUS.CH"
#Include "TopConn.ch"
#Define STR_PULA        Chr(13)+ Chr(10)

//TELA INICIAL 
USER FUNCTION XESTORNO()
    DEFINE MSDIALOG oDlg TITLE "Selecione a rotina " FROM 0,0 TO 130,300 PIXEL  // ALTURA X LARGURA
	    @ 015, 030  BUTTON oBtn1 PROMPT "Estorno em data errada" SIZE 100,15 ACTION (U_XUNOEST()) OF oDlg PIXEL
	    @ 035, 030  BUTTON oBtn2 PROMPT "Estorno em duas datas " SIZE 100,15 ACTION (U_XDUOEST()) OF oDlg PIXEL
    ACTIVATE MSDIALOG oDlg CENTERED
Return

//ESTORNO EM DATA ERRADA
USER FUNCTION XUNOEST()
    Local cPerg     :="XUNOEST"//GRUPO DE PERGUNTAS
    Local cNumero   :=""
    Local cParcela  :=""
    Local cCliente  :=""
    Local cFil      :="" //FILIAL DO TITULO
    Local cData     :=STOD("")

    //variaveis de consulta 
    Local cQRYSE5   :="" //MOVIMENTOS BANCARIOS 
    Local cQRYCT2   :="" //CONTABILIZAÇÃO 
    Local cQRYFK5   :="" //AMARRAÇÃO DE MOVIMENTOS 
    Local cQRYFWI   :="" //AMARRAÇÃO DE COBRANÇA
    
    Local cIdOrig   :=""//RETORNO DO MOVIMENTO A SER CORRIGIDO
    Private lMsErroAuto:=.F.//VARIAVEL PADRÃO DE ERRO PROTHEUS 

    Pergunte(cPerg,.T.) //CHAMA O GRP DE PERGUNTAS
    
    //TESTE DE VALIDAÇÃO BASICA + ATRIBUIÇÃO DE VALORES
    IF !EMPTY(MV_PAR01)
        cNumero :=MV_PAR01
    ELSE
        MsgStop("Numero de Titulo não preenchido")
        Return
    ENDIF
    IF !EMPTY(MV_PAR02)
        cParcela :=MV_PAR02
    ENDIF
    IF !EMPTY(MV_PAR03)
        cCliente :=MV_PAR03
    ENDIF
    IF !EMPTY(MV_PAR04)
        cFil :=MV_PAR04
    ENDIF
    IF !EMPTY(MV_PAR05)
        cData :=MV_PAR05
    ENDIF

    //FITRA SE5
    cQRYSE5 +="SELECT E5_IDORIG, * "            +STR_PULA
    cQRYSE5 +="FROM SE5 WHERE "              +STR_PULA
    cQRYSE5 +="E5_NUMERO = '"+cNumero+"'"       +STR_PULA
    cQRYSE5 +="AND E5_PARCELA = '"+cParcela+"'" +STR_PULA
    cQRYSE5 +="AND E5_CLIFOR = '"+cCliente+"'"  +STR_PULA    
    cQRYSE5 +="AND E5_FILORIG = '"+cFil+"'"     +STR_PULA    
    cQRYSE5 +="AND E5_NATUREZ = 'DESCONT'"      +STR_PULA    
    TcQuery cQRYSE5 New Alias "QRYSE5" 

    cIdOrig := QRYSE5->E5_IDORIG //PEGO O IDORIG PARA FILTRAR EM OUTRAS TABELAS
    
    //FILTRA CT2 - PARA VALIDAR SE EXISTE CONTABILIZAÇÃO 
    cQRYCT2 += "SELECT * FROM CT2 WHERE "                        +STR_PULA
    cQRYCT2 += "D_E_L_E_T_ = '' AND "                               +STR_PULA
    cQRYCT2 += "CT2_DTCV3 = '"+(QRYSE5->E5_DATA)+"' AND "           +STR_PULA
    cQRYCT2 += "CT2_FILORI = '"+(QRYSE5->E5_FILORIG)+"' AND "       +STR_PULA
    cQRYCT2 += "CT2_VALOR = '"+cValToChar(QRYSE5->E5_VALOR)+"' AND "+STR_PULA
    cQRYCT2 += "CT2_HIST like '%"+(QRYSE5->E5_NUMERO)+"%' "         +STR_PULA
    TcQuery cQRYCT2 New Alias "QRYCT2" 

    // SE HOUVER RESULTADO NA CONSULTA ELE FECHA / SE NÃO VC PODE FECHAR 
    If QRYCT2->(!EOF())
        if MsgYesNo("EXISTE CONTABILIZAÇÃO: "+QRYCT2->CT2_HIST+""+CRLF+"Exclua o movimento e retorne", "XUNOEST")
        //true = ok
        else
            Return        
        ENDIF
    Else
        if MsgYesNo("Não encontrei contabilização! Ja excluiu? ", "XUNOEST")
        //true = ok
        else 
            return//else = fecha tela 
        ENDIF
    EndIF
    
    //EXECUTA A CORREÇÃO DE DATA NA SE5
    DbSelectArea('SE5') 
    SE5->(dbGoTo(QRYSE5->R_E_C_N_O_))//POSICIONA NO REGISTRO QUE IREI ATUALIZAR
    IF RecLock('SE5',.F.) //TRAVA O REGISTRO PARA ALTERAÇÃO
        SE5->E5_DATA    := cData
        SE5->E5_DTDIGIT := cData
        SE5->E5_DTDISPO := cData
        SE5->E5_LA := " "
        SE5->(MsUnLock())//DESTRAVA O REGISTRO
    ELSE 
        MsgAlert("Não foi possivel corrigir na SE5", "ALERTA")
        IF lMsErroAuto //SE VERDADEIRO
            MostraErro()//FUNÇÃO PADRÃO PARA RETORNAR O ERRO 
        ENDIF
    ENDIF    
    QRYSE5->(dbCloseArea())    

    //FILTRA FK5
    cQRYFK5 +="SELECT * FROM FK5 WHERE FK5_IDMOV = '"+cIdOrig+"'" +STR_PULA
    TcQuery cQRYFK5 New Alias "QRYFK5" 
    
    //EXECXUTA A CORRECAO DE DATA NA FK5
    DbSelectArea('FK5')
    FK5->(dbGoTo(QRYFK5->R_E_C_N_O_))
    IF RecLock('FK5',.F.)
            FK5->FK5_DATA       :=cData
            FK5->FK5_DTDISPO    :=cData
        FK5->(MsUnLock())
    ELSE 
        MsgAlert("Não foi possivel corrigir na FK5", "ALERTA")
        IF lMsErroAuto //SE VERDADEIRO
            MostraErro()//FUNÇÃO PADRÃO PARA RETORNAR O ERRO 
        ENDIF
    ENDIF
    QRYFK5->(DbCloseArea())

    //FILTRA FWI
    cQRYFWI +="SELECT * FROM FWI WHERE FWI_IDMOV ='"+cIdOrig+"'"
    TcQuery cQRYFWI New Alias "QRYFWI"
    
    //EXECUTA A CORREÇÃO DE DATA NA FWI
    DbSelectArea('FWI')
    FWI->(dbGoTo(QRYFWI->R_E_C_N_O_))
    IF RecLock('FWI',.F.)
            FWI->FWI_DTMOVI := cData
        FWI->(MsUnlock())
    ELSE    
        MsgAlert("Não foi possivel corrigir na FWI", "ALERTA")
        IF lMsErroAuto //SE VERDADEIRO
            MostraErro()//FUNÇÃO PADRÃO PARA RETORNAR O ERRO 
        ENDIF
    EndIf
    QRYFWI->(DbCloseArea())

    MsgInfo("Executou a correção da data no titulo: "+cNumero+"","Finalizado")
Return

//ESTORNO EM DUAS DATAS 
USER FUNCTION XDUOEST()
    //variaveis constantes | Se tratando de casos onde sei que os valores destas variaveis não se alteram eu mantive fixado
    Local cNaturez  :='DESCONTO'
    Local nAutDes   := 0
    Local nAutCred  := 0
    Local nAutIof   := 0
    Local cPerg := "XDUOEST"

    //variaveis por parametro 
    Local cNumero   :=''
    Local cParcela  :=''
    Local cCliente  :=''
    Local cFil      :=''
    Local dPriData  :=CTOD('  /  /    ')
    Local cPriValor :=''
    Local dSegData  :=CTOD('  /  /    ')  
    Local cSegValor :=''
    
    //variaveis de Backup
    Local cIdmov            :=""
    Local cNumBco           :=""
    Local cBanco            :=""
    Local cAgencia          :=""
    Local cConta            :=""
    Local cVlOriginal       :=""
    Local cSaldoOriginal    :=""
    Local cSituacaOriginal  :=""
    Local cEstPri           :=""

    
    Local aBaixa        := {}//Recebe o que for filtrado = FK1 assim posso dar um recall depois nestes E5_IDORIG | Recebe := cQrySE5_FK1 ->E5_IDORIG
    Local ncontBaixa    := 0 //Recebe o numero de registros adicionado ao array aBaixa
    Local nIncremento   := 1 

    //Variaves de Consulta
    Local cQRYCT2       :=""
    Local cQrySE5       :=""//
    Local cQryFK5       :=""//
    Local cQryFWI       :=""//
    Local cQrySE1       :=""//
    Local cQrySE5_FK1   :=""//QRY_SE5FK1 - MOVIMENTO DE BAIXA DELETE
    Local cQrySE5_FK1REC:=""//MOVIMENTO DE BAIXA PARA RECALL
    Local cQrySE5_DES   :=""//MOVIMENTO DE DESCONTO
    Local cQrySE5_EST   :=""//MOVIMENTO DE ESTORNO
    
    private aEstorna :={}//RECEBE OS DADOS PARA UTILIZAR O MSEXECAUTO

    Pergunte(cPerg,.T.)
    IF !EMPTY(MV_PAR01)
        cNumero :=MV_PAR01
    ELSE
        MsgStop("Numero de Titulo não preenchido")
        Return
    ENDIF
    IF !EMPTY(MV_PAR02)
        cParcela := MV_PAR02
    ENDIF
    IF !EMPTY(MV_PAR03)
        cCliente := MV_PAR03
    ENDIF
    IF !EMPTY(MV_PAR04)
        cFil := MV_PAR04
    ENDIF
    IF !EMPTY(MV_PAR05)
        dPriData  := MV_PAR05
    ENDIF
    IF !EMPTY(MV_PAR06)
        cPriValor := MV_PAR06
    ENDIF
    IF !EMPTY(MV_PAR07)
        dSegData  := MV_PAR07
    ENDIF
    IF !EMPTY(MV_PAR08)
        cSegValor := MV_PAR08
    ENDIF

    //FILTRA TODOS OS MOVIMENTOS NA SE5 DO TITULO QUE SERA ALTERADO
    cQrySE5 +="SELECT * "                       +STR_PULA
    cQrySE5 +="FROM SE5 WHERE "              +STR_PULA
    cQrySE5 +="E5_NUMERO = '"+cNumero+"'"       +STR_PULA
    cQrySE5 +="AND E5_PARCELA = '"+cParcela+"'" +STR_PULA
    cQrySE5 +="AND E5_CLIFOR = '"+cCliente+"'"  +STR_PULA
    cQrySE5 +="AND E5_FILORIG = '"+cFil+"'"     +STR_PULA

    //FILTRA A BAIXAS 
    cQrySE5_FK1 += cQrySE5                      +STR_PULA
    cQrySE5_FK1 += "AND D_E_L_E_T_ =''"         +STR_PULA
    cQrySE5_FK1 += "AND E5_TABORI  ='FK1'"      +STR_PULA
   
    TcQuery cQrySE5_FK1 New Alias "QRY_SE5FK1"
    
    //SE5_FK1 ARMAZENOS OS IDORIGS - MOVIMENTO DE BAIXA ORIGINAL
    DbSelectArea("QRY_SE5FK1")
    WHILE !QRY_SE5FK1->(EOF())
        AAdd(aBaixa,QRY_SE5FK1-> E5_IDORIG)
        QRY_SE5FK1->(dbSkip())
    EndDo

    //VOLTO AO TOP DOS REGISTROS 
    QRY_SE5FK1->(DBGoTop())  

    //ABRO A SE5 E DENTRO DE CADA LOOP ATE O EOF - VOU ATE O RECNO/ TRAVO E EXCLUO
    DbSelectArea('SE5')
    WHILE QRY_SE5FK1->(!EOF())
        SE5->(DBGoTo(QRY_SE5FK1->R_E_C_N_O_))
        IF RecLock('SE5',.F.)
            DBDelete()
            SE5->(MsUnlock())
        else
            MsgInfo("Não excluido","XDUOEST")
        ENDIF
        QRY_SE5FK1->(DBSkip())
    EndDo    
    QRY_SE5FK1->(DBCloseArea())
    SE5->(DBCloseArea())

    //FILTRA O MOVIMENTO ORIGINAL PARA EXCLUSÃO
    cQrySE5_EST += cQrySE5+""+STR_PULA
    cQrySE5_EST += "AND D_E_L_E_T_ =''" +STR_PULA
    cQrySE5_EST += "AND E5_HISTOR LIKE '%Estorno%'" +STR_PULA
    TcQuery cQrySE5_EST New Alias "QRY_SE5EST"

    //ARMAZENO O IDORIG, BANCO, AGENCIA, CONTA, DE ESTORNO PARA REUTILIZAR MANTENDO OS DADOS CORRETOS 
    cIdmov   := QRY_SE5EST -> E5_IDORIG 
    cBanco   := QRY_SE5EST -> E5_BANCO
    cAgencia := QRY_SE5EST -> E5_AGENCIA 
    cConta   := QRY_SE5EST -> E5_CONTA
    
    //FILTRA AS SUBTABELAS 
    cQryFK5 = "SELECT * FROM FK5 WHERE FK5_IDMOV = '"+cIdMov+"'"
    TcQuery cQryFK5 New Alias "QRY_SE5FK5"    

    cQryFWI = "SELECT * FROM FWI WHERE FWI_IDMOV = '"+cIdMov+"'"
    TcQuery cQryFWI New Alias "QRY_SE5FWI" 

    //FILTRA CT2 - PARA VALIDAR SE EXISTE CONTABILIZAÇÃO 
    cQRYCT2 += "SELECT * FROM CT2 WHERE "                            +STR_PULA
    cQRYCT2 += "D_E_L_E_T_ = '' AND "                                   +STR_PULA
    cQRYCT2 += "CT2_DTCV3 = '"+(QRY_SE5EST->E5_DATA)+"' AND "           +STR_PULA
    cQRYCT2 += "CT2_FILORI = '"+(QRY_SE5EST->E5_FILORIG)+"' AND "       +STR_PULA
    cQRYCT2 += "CT2_VALOR = '"+cValToChar(QRY_SE5EST->E5_VALOR)+"' AND "+STR_PULA
    cQRYCT2 += "CT2_HIST like '%"+(QRY_SE5EST->E5_NUMERO)+"%' "         +STR_PULA

    TcQuery cQRYCT2 New Alias "QRYCT2" 

    // SE HOUVER RESULTADO NA CONSULTA ELE FECHA / SE NÃO VC PODE FECHAR 
    If QRYCT2->(!EOF())
        if MsgYesNo("EXISTE CONTABILIZAÇÃO: "+QRYCT2->CT2_HIST+""+CRLF+"Exclua o movimento e retorne", "ALERTA")
        //true = ok
        else
            Return        
        ENDIF
    Else
        if MsgYesNo("Não encontrei contabilização! Ja excluiu? ", "ALERTA")
        //true = ok
        else 
            return//else = fecha tela 
        ENDIF
    EndIF
    
    //EXCLUINDO NA SE5
    DbSelectArea('SE5')
    SE5->(DbGoto(QRY_SE5EST->R_E_C_N_O_))
    IF RecLock('SE5',.F.)
        DBDelete()
    else
        MsgInfo("Não excluido: "+QRY_SE5EST->R_E_C_N_O_,"XDUOEST")      
    EndIf
    SE5->(MsUnlock())
    SE5->(DBCloseArea())

    //EXCLUINDO NA FK5
    DbSelectArea('FK5')
    FK5->(DBgoTo(QRY_SE5FK5->R_E_C_N_O_))
    If RecLock('FK5',.F.)
        DBDelete()
    Else
        MsgInfo("Não excluido: "+QRY_SE5FK5->R_E_C_N_O_,"XDUOEST")      
    EndIf
    FK5->(MsUnlock())
    FK5->(DBCloseArea())

    //EXCLUINDO NA FWI
    DbSelectArea('FWI')
    FWI->(DbGoTo(QRY_SE5FWI->R_E_C_N_O_))
    If RecLock('FWI',.F.)
        DBDelete()
    Else
        MsgInfo("Não excluido: "+QRY_SE5FWI->R_E_C_N_O_,"XDUOEST") 
    EndIf
    FWI->(MsUnlock())
    FWI->(DBCloseArea())

    //FILTRA O MOVIMENTO DE IDA PARA DESCONTADA
    cQrySE5_DES += cQrySE5 +STR_PULA 
    cQrySE5_DES += "AND D_E_L_E_T_ =''" +STR_PULA
    cQrySE5_DES += "AND E5_NATUREZ ='DESCONT'" +STR_PULA
    
    TcQuery cQrySE5_DES New Alias "QRY_SE5DES"

    //FILTRA O TITULO EM SI NA SE1 
    cQrySE1 += "SELECT * FROM SE1 WHERE"+STR_PULA
    cQrySE1 += "D_E_L_E_T_ ='' " +STR_PULA
    cQrySE1 += "AND E1_NUM ='"+cNumero+"'" +STR_PULA
    cQrySE1 += "AND E1_PARCELA ='"+cParcela+"'" +STR_PULA
    cQrySE1 += "AND E1_CLIENTE ='"+cCliente+"'" +STR_PULA   
    cQrySE1 += "AND E1_FILIAL ='"+cFil+"'" +STR_PULA   
    
    TcQuery cQrySE1 New Alias "QRY_SE1"

    cVlOriginal     := QRY_SE5DES -> E5_VALOR 
    cSaldoOriginal  := QRY_SE1    -> E1_SALDO
    cSituacaOriginal:= QRY_SE1    -> E1_SITUACA
    cNumBco         := QRY_SE1    -> E1_NUMBCO

    //EFETUA A ALTERÇÃO DE VALORES PRIMEIRO DIA 
    DbSelectArea('SE5')
    SE5->(DbGoTo(QRY_SE5DES->R_E_C_N_O_))
        IF RecLock('SE5',.F.)
            E5_VALOR := VAL(cPriValor)
        ELSE    
            MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
        ENDIF
    SE5->(MsUnlock())
    SE5->(DBCloseArea())
    
    QRY_SE1->(DbGotoTop())
    DbSelectArea('SE1')
    SE1->(DbGoTo(QRY_SE1->R_E_C_N_O_))
        If RecLock('SE1',.F.)
            E1_SITUACA   :='2'
            E1_VALOR     := VAL(cPriValor)
            E1_SALDO     := VAL(cPriValor)
        Else
            MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
        EndIf 
    SE1->(MsUnlock())
    SE1->(DbCloseArea())
    
    QRY_SE1->(DbGotoTop())
    DbSelectArea('SE1')
    SE1->(DbGoTo(QRY_SE1->R_E_C_N_O_))
        //AO VOLTAR PARA CARTEIRA TEM QUE REMOVER OS PARAMETROS DE BANCO
        If cSituacaOriginal ="0"
		    cBanco    := ""
	    	cAgencia  := ""
    		cConta    := ""
		    cNumBco   := ""
	    EndIf
        
        //PRIMEIRO RECEBO OS VALORES DO TITULO QUE IREMOS EXECUTAR 
        aAdd(aEstorna, {"E1_FILIAL"  , PadR(Alltrim(SE1->E1_FILIAL)  , TamSX3("E1_FILIAL")[1])  ,Nil})
        aAdd(aEstorna, {"E1_PREFIXO" , PadR(Alltrim(SE1->E1_PREFIXO) , TamSX3("E1_PREFIXO")[1]) ,Nil})
        aAdd(aEstorna, {"E1_NUM" 	 , PadR(Alltrim(SE1->E1_NUM)	 , TamSX3("E1_NUM")[1])     ,Nil})
        aAdd(aEstorna, {"E1_PARCELA" , PadR(Alltrim(SE1->E1_PARCELA) , TamSX3("E1_PARCELA")[1]) ,Nil})
        aAdd(aEstorna, {"E1_TIPO"    , PadR(Alltrim(SE1->E1_TIPO)	 , TamSX3("E1_TIPO")[1])    ,Nil})
        
        //SEGUNDO RECEBO A DATA QUE IRA MOVIMENTAR 
        dDataBase := dPriData
        aAdd(aEstorna, {"AUTDATAMOV" , dPriData,Nil})

        //TERCEIRO RECEBO OS DADOS DE BANCO 
		aAdd(aEstorna, {"AUTBANCO" 	 , PadR(Alltrim(cBanco),     TamSX3("A6_COD")[1])          ,Nil})
		aAdd(aEstorna, {"AUTAGENCIA" , PadR(Alltrim(cAgencia),   TamSX3("A6_AGENCIA")[1])      ,Nil})
		aAdd(aEstorna, {"AUTCONTA"   , PadR(Alltrim(cConta),     TamSX3("A6_NUMCON")[1])       ,Nil})
        
        If cSituacaOriginal = "1"
		    aAdd(aEstorna, {"E5_NATUREZ" , PadR(cNaturez , TamSX3("E1_NATUREZ")[1]) ,Nil})
		    aAdd(aEstorna, {"E1_NATUREZ" , PadR(cNaturez , TamSX3("E1_NATUREZ")[1]) ,Nil})
        Else 
            aAdd(aEstorna, {"E1_NATUREZ" , PadR(cNaturez , TamSX3("E1_NATUREZ")[1]) ,Nil})
        EndIf
        
        //QUARTO RECEBO OS DADOS DE CARTEIRA
        aAdd(aEstorna, {"AUTSITUACA", PadR(Alltrim(cSituacaOriginal),TamSX3("E1_SITUACA")[1]) ,Nil})
        aAdd(aEstorna, {"AUTNUMBCO" , PadR(Alltrim(cNumBco),         TamSX3("E1_NUMBCO")[1])  ,Nil})

        //QUINTO RECEBO OS DADOS DE ESTORNO AUXILIARES
        aAdd(aEstorna, {"AUTDESCONT"    , nAutDes   ,Nil})
        aAdd(aEstorna, {"AUTCREDIT"     , nAutCred  ,Nil})
	    aAdd(aEstorna, {"AUTIOF" 	    , nAutIof   ,Nil})

        //EFETUA A TRANSFERENCIA DE CARTEIRA DESCONTADA PARA SIMPLES 
        MSExecAuto({|a, b| FINA060(a, b)}, 2,aEstorna)    
        
        if lMsErroAuto
            MostraErro()
        else
            msgALert("Efetuado o primeiro estono","XDUOEST")
        EndIf

    SE1->(DBCloseArea())

    TcQuery cQrySE5_EST New Alias 'QRY_SE5ESTPRI'
    
    //CHAMO E EXCLUO TEMPORARIAMENTE O PRIMEIRO MOVIMENTO
    DbSelectArea('SE5')        
        SE5->(DbGoTo(QRY_SE5ESTPRI->R_E_C_N_O_))
            IF RecLock('SE5',.F.)
                cEstPri := QRY_SE5ESTPRI->R_E_C_N_O_
                DBDelete()
                SE5->(MsUnlock())
            ELSE    
                MsgAlert("Deu erro ao excluir temporariamente", "XDUOEST")
            ENDIF
    SE5->(DBCloseArea())

    QRY_SE1->(DbGotoTop())
    //EFETUA A ALTERÇÃO DE VALORES SEGUNDO DIA
    DbSelectArea('SE1')
    SE1->(DbGoTo(QRY_SE1->R_E_C_N_O_))
        If RecLock('SE1',.F.)
            SE1->E1_SITUACA   :='2'
            SE1->E1_VALOR     := VAL(cSegValor)
            SE1->E1_SALDO     := VAL(cSegValor)
            SE1->(MsUnlock())
        Else
            MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
        EndIf 
    SE1->(DbCloseArea())

    DbSelectArea('SE5')
        SE5->(DbGoTo(QRY_SE5DES->R_E_C_N_O_))
            IF RecLock('SE5',.F.)
                SE5->E5_VALOR := VAL(cSegValor)
                SE5->(MsUnlock())
            ELSE    
                MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
            ENDIF
    SE5->(DBCloseArea())

    //EFETUA A SEG TRANSFERENCIA DE CARTEIRA DESCONTADA PARA SIMPLES
    dDataBase := dSegData
    aEstorna[6,2] := dSegData
    
    MSExecAuto({|a, b| FINA060(a, b)}, 2,aEstorna)    
            
    if lMsErroAuto
        MostraErro()
    else
        msgALert("Efetuado o segundo estono ","XDUOEST")
    EndIf

    SE1->(DBCloseArea())

    //POSIBILITA RECALAR OS REGISTROS DELETADOS 
    Set Deleted off
    QRY_SE5DES->(DbGotoTop())
    //VOLTA OS VALORES AO ORIGINAL - 
    DbSelectArea('SE5')
        SE5->(DbGoTo(QRY_SE5DES->R_E_C_N_O_))
            IF RecLock('SE5',.F.)
                SE5->E5_VALOR := cVlOriginal
                SE5->(MsUnlock())
            ELSE    
                MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
            ENDIF
    SE5->(DBCloseArea())
    
    QRY_SE1->(DbGotoTop())
    DbSelectArea('SE1')
    SE1->(DbGoTo(QRY_SE1->R_E_C_N_O_))
        If RecLock('SE1',.F.)
            SE1-> E1_SITUACA   := cSituacaOriginal
            SE1-> E1_VALOR     := cVlOriginal
            SE1-> E1_SALDO     := cSaldoOriginal
            SE1->(MsUnlock())
        Else
            MsgAlert("Deu erro ao alterar Valor", "XDUOEST")
        EndIf 
    SE1->(DbCloseArea())
    
    //VOLTA O MOVIMENTO DE ESTORNO NO PRIMEIRO DIA
    DbSelectArea('SE5')
        SE5->(DbGoTo(cEstPri))  
            IF RecLock('SE5',.F.)
                 DBRecall()
                 SE5->(MsUnlock())
            EndIf
    SE5->(DBCloseArea())

    //CONTO QUANTOS REGISTROS NO ARRAY / MONTO O FILTRO  
    nContBaixa := LEN(aBaixa)
    cQrySE5_FK1REC:= cQrySE5 +" "+ STR_PULA
    WHILE nIncremento <= nContBaixa
        IF(nIncremento == 1)
            cQrySE5_FK1REC+="AND (E5_IDORIG ='"+aBaixa[nIncremento]+"'"+STR_PULA    
        ELSE  
            cQrySE5_FK1REC+="OR E5_IDORIG ='"+aBaixa[nIncremento]+"'"+STR_PULA
        ENDIF
        nIncremento++
    EndDo
    cQrySE5_FK1REC+=")" +STR_PULA
    
    TcQuery cQrySE5_FK1REC New Alias "QRY_SE5FK1REC"
    
    // RETORNO OS DADOS EXCLUIDOS IDORIGS - SE5_FK1
    DBSelectArea("QRY_SE5FK1REC")
    QRY_SE5FK1REC->(DBGoTop())

    //ABRO A SE5 E DENTRO DE CADA LOOP ATE O EOF - VOU ATE O RECNO/ TRAVO E RESTAURO
    DbSelectArea('SE5')
    While QRY_SE5FK1REC->(!EOF())
        SE5->(DbGoTo(QRY_SE5FK1REC->R_E_C_N_O_))
        IF RecLock('SE5',.F.)
            DBRecall()
        else
            MsgInfo("Não foi possivel efetuar recall ","cTitulo")
        ENDIF
        SE5->(MsUnlock())
        QRY_SE5FK1REC->(DBSkip())
    ENDDO
    QRY_SE5FK1REC->(DBCloseArea())
    SE5->(DBCloseArea())

    //CORRIJO A NATUREZA PARA DESCONTO
    TcQuery cQrySE5_EST New Alias 'QRY_SE5ESTSEG'
    DbSelectArea('SE5')        
        While QRY_SE5ESTSEG->(!EOF())
            SE5->(DbGoTo(QRY_SE5ESTSEG->R_E_C_N_O_))
            IF RecLock('SE5',.F.)
                SE5->E5_NATUREZ := cNaturez
                SE5->(MsUnlock())
            Endif
            QRY_SE5ESTSEG->(DBSkip())
        ENDDO
    Set Deleted on

    MsgAlert("Finalizado", "XDUOEST")
   
RETURN
