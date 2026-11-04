/*
===============================================================================
ORDEM DE SERVIÇO: 20938
AUTOR: Frederico Magalhães
DATA ALTEAÇÃO: 04/11/2026
OBJETIVO: Criação do Relatório de Notas Fiscais de Saída V2.
AMBIENTE: SAP Business One (SAP HANA)
===============================================================================
*/

SELECT DISTINCT
    T0."DocEntry"                                          AS "Nº interno",
    T0."DocNum"                                            AS "Nº Primário",
--    T1."LineNum"                                           AS "Nº Linha",
    T3."SlpName"                                           AS "Vendedor",
    T0."DocDate"                                           AS "Data",
    T0."Serial"                                            AS "Nº NF",
    T0."CardCode"                                          AS "Código do PN",
    T0."CardName"                                          AS "Razão Social",
    T1."ItemCode"                                          AS "Produto",
    T1."Dscription"                                        AS "Descrição do item/serviço",
    T1."U_SPS_ListNum"                                     AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão'
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto'
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional'
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar'
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro'
        WHEN T1."U_SPS_ListNum" = '7' THEN 'Nitro Financeiro'
    END                                                    AS "Lista de Preço",
    T6."Carrier"                                           AS "Código da transportadora",
    T0."U_SPS_Transportadora"                              AS "Razão Social Transportadora",
    T1."U_SPS_PercTrademarketing"                          AS "Percentual Trade Marketing",
    T1."Quantity"                                          AS "Qtde",
    T1."LineTotal"                                         AS "Total por Produto",
    T0."NfeValue"                                          AS "Valor da NF-e",
    T2."Usage"                                             AS "Utilização",
    T0."Comments"                                          AS "Observações",
    T5."CodeBars"                                          AS "EAN",

    -- BONIFICAÇÃO TALÃO
    CASE 
        WHEN T1."Usage" = 12 AND 
             COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade", 'N') = 'N' AND 
             COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra", 'N') = 'N' 
        THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Talão",

    -- BONIFICAÇÃO EXTRA
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Extra",

    -- BONIFICAÇÃO TRADE
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Trade",

    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado'
        ELSE 'Aberto'
    END                                                    AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Cancelado",
    T4."State"                                             AS "UF",
    T4."City"                                              AS "CIDADE",
    CAST(T7."U_ChaveAcesso" AS NVARCHAR(100))              AS "Chave de Acesso",
    T7."U_msgSEFAZ"                                        AS "Mensagem de retorno",
    CASE 
        WHEN T8."U_SPS_Suframa" = 'Y' THEN 'SIM'
        ELSE 'NÃO'
    END                                                    AS "Possui Suframa",
    CASE 
        WHEN T8."U_SPS_SuspIPI" = '0' THEN 'SIM'
        ELSE 'NÃO'
    END                                                    AS "Possui Suspensão de IPI",
    T1."TaxCode"                                           AS "Código Imposto",
    T9."Name"                                          AS "Descrição Cod. Imposto",
    T14."Name"                                             AS "Gerente Regional"

FROM OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
    INNER JOIN OSTC T9 ON T1."TaxCode" = T9."Code"
    INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
    LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'S' AND T4."Address" = T0."ShipToCode"
    LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
    LEFT JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
    LEFT JOIN "@SKL25NFE" T7 ON T0."DocEntry" = T7."U_DocEntry" AND T7."U_tipoDocumento" = 'NS'
    LEFT JOIN OCRD T8 ON T0."CardCode" = T8."CardCode"
    LEFT JOIN ORDR T10 ON T1."BaseType" = 17 AND T1."BaseEntry" = T10."DocEntry"
    LEFT JOIN DLN1 T12 ON T1."BaseType" = 15 AND T1."BaseEntry" = T12."DocEntry" AND T1."BaseLine" = T12."LineNum"
    LEFT JOIN ORDR T13 ON T12."BaseType" = 17 AND T12."BaseEntry" = T13."DocEntry"
    LEFT JOIN "@GB_GER_CARTEIRA" T14 ON T8."U_GB_GER_CARTEIRA" = T14."Code"

WHERE 
    T0."Model" = 39 
    AND T0."DocDate" >= [%0]
    AND T0."DocDate" <= [%1]

ORDER BY 
    T0."DocEntry"
 --   T1."LineNum"