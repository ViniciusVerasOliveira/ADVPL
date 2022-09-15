/*--------------------------------------------------------------------------------------------------\
| {Protheus.doc} U_Rotina_Transferencia  												                                    |
| @author Vinicius Veras																                                            |
| @version 1.0																			                                                |
| @Obs: Todos os nomes e valores estão mascarados devido a ser um fonte de testes e aprendizado.    |
\--------------------------------------------------------------------------------------------------*/
#include "Totvs.ch"
#include "protheus.ch"
#include "topconn.ch"

#Define STR_PULA        Chr(13)+ Chr(10)

USER FUNCTION U_Rotina_Transferencia()
//Local cPerg     :="GrpPerg"//grupo de perguntas 

//Dados do titulo passado via grupo de perguntas
Local cFil      := ''
Local cPrefixo  := ''
Local cNumero   := ''
Local cParcela  := ''
Local cTipo     := ''
//parametros de banco
Local cNumBco   := ''
Local cBanco    := ''
Local cAgencia  := ''
Local cConta    := ''
Local cNaturez  := ''
Local cSituaca  := ''
Local dData     := CTOD('  /  /    ')
Local aTransf   := {}
Local nValCred  := 0
Local nValDesc  := 0
Local nValIof   := 0

Private lMsErroAuto := .F.
    //Entro na tabela de contas a receber
    DbSelectArea('SE1')
    SE1->(DbSetOrder(1))
    If SE1->(DbSeek(    PadR(Alltrim(cFil),     TamSX3("E1_FILIAL")[1]) +;
                        PadR(Alltrim(cPrefixo), TamSX3("E1_PREFIXO")[1])+;
                        PadR(Alltrim(cNumero),  TamSX3("E1_NUM")[1])    +;
                        PadR(Alltrim(cParcela), TamSX3("E1_PARCELA")[1])
                    )
            )
    EndIf
    //Informo um array para efetuar o msexecauto
    aAdd(aTransf,{"E1_FILIAL",  PadR(Alltrim(cFil), TamSX3("E1_FILIAL")[1]),Nil})
    aAdd(aTransf,{"E1_PREFIXO", PadR(Alltrim(cPrefixo), TamSX3("E1_PREFIXO")[1]),Nil})
    aAdd(aTransf,{"E1_NUM",     PadR(Alltrim(cNumero), TamSX3("E1_NUM")[1]),Nil})
    aAdd(aTransf,{"E1_PARCELA", PadR(Alltrim(cParcela),TamSX3("E1_PARCELA")[1]),Nil})
    aAdd(aTransf,{"E1_TIPO",    PadR(Alltrim(cTipo),TamSX3("E1_TIPO")[1]),Nil})

    //Data do movimento
    dDataBase := dData
    aAdd(aTransf,{"AUTDATAMOV", dData, Nil })   
    
    aAdd(aTransf,{"AUTBANCO",   PadR(Alltrim(cBanco),TamSX3("A6_COD")[1]),Nil})
    aAdd(aTransf,{"AUTAGENCIA", PadR(Alltrim(cAgencia),TamSX3("A6_AGENCIA")[1]),Nil})
    aAdd(aTransf,{"AUTCONTA",   PadR(Alltrim(cConta),TamSX3("A6_NUMCON")[1]),Nil})
    //valido a situaca destino 
    if cSituaca = "1"
		  aAdd(aTransf, {"E5_NATUREZ" , PadR("DESCONTO" , TamSX3("E1_NATUREZ")[1]) ,Nil})
		  aAdd(aTransf, {"E1_NATUREZ" , PadR("DESCONTO" , TamSX3("E1_NATUREZ")[1]) ,Nil})
	  EndIF

    aAdd(aTransf,{"AUTSITUACA", PadR(Alltrim(cSituaca),TamSX3("E1_SITUACA")[1]),Nil})
    aAdd(aTransf,{"AUTNUMBCO" , PadR(Alltrim(cNumBco ),TamSX3("E1_NUMBCO")[1]) ,Nil})

    aAdd(aTransf, {"AUTDESCONT" , nValDesc ,Nil})
    aAdd(aTransf, {"AUTCREDIT"  , nValCred ,Nil})
	  aAdd(aTransf, {"AUTIOF" 	, nValIof  ,Nil})
    
    //Executa o MSExecAuto na rotina FINA060 - Transferencia de situação
    MSExecAuto({|a, b| FINA060(a, b)},  2, aTransf)
    
    //se apresentar algum erro na execução deve mostrar aqui
    if lMsErroAuto
        mostraerro()
        lMsErroAuto := .F.
    endif

    SE1->(DBCloseArea())

Return
