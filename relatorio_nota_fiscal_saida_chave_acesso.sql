/*
===============================================================================
ORDEM DE SERVIÇO: 20691
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 21/10/2026
OBJETIVO: Relatório analítico de Notas Fiscais de Saída (Model = 39) com rastreamento da origem no Pedido de Vendas (ORDR/DLN1), dados de 
          integração SEFAZ (@SKL25NFE), enquadramento fiscal/impostos, regras de bonificação e adição das colunas de segmentação 'Canal' e 'Gerente Regional'.
AMBIENTE: SAP Business One (SAP HANA)
===============================================================================
*/

SELECT DISTINCT
    T0."DocEntry",
    T0."DocNum" AS "Nº Primário",
    COALESCE(T10."NumAtCard", T13."NumAtCard") AS "Nº referência PN do pedido",
    T3."SlpName" AS "Vendedor",
    T0."DocDate" AS "Data de Emissão",
    T0."Serial" AS "Nº NF",
    T1."LineNum" AS "Nº da Linha", 
    T0."CardCode" AS "Código do PN",
    T0."CardName" AS "Razão Social",
    T1."ItemCode" AS "Produto",
    T1."Dscription",
    T1."U_SPS_ListNum" AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão'
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto'
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional'
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar'
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro'
        WHEN T1."U_SPS_ListNum" = '7' THEN 'Nitro Financeiro'
    END AS "Lista de Preço",
    T6."Carrier",
    T0."U_SPS_Transportadora",
    T8."U_SPS_Canal" AS "Cód. Canal",
    CASE
        WHEN T8."U_SPS_Canal" = '0' THEN 'Indireto'
        WHEN T8."U_SPS_Canal" = '1' THEN 'Hospital'
        WHEN T8."U_SPS_Canal" = '2' THEN 'Parceiro'
        WHEN T8."U_SPS_Canal" = '3' THEN 'Direto'
        WHEN T8."U_SPS_Canal" = '4' THEN 'Governo'
        WHEN T8."U_SPS_Canal" = '5' THEN 'Outros'
        ELSE 'Não Definido'
    END AS "Descrição Canal",
    T14."Name" AS "Gerente Regional",
    T1."U_SPS_PercTrademarketing" AS "Percentual Trade Marketing",
    T1."Quantity" AS "Qtde",
    T1."LineTotal" AS "Total por Produto",
    T0."NfeValue",
    T2."Usage" AS "Utilização",
    T0."Comments",
    T5."CodeBars" AS "EAN",
    CASE 
        WHEN T1."Usage" = 12 AND 
             COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade", 'N') = 'N' AND 
             COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra", 'N') = 'N' 
        THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Talão",
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Extra",
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Trade",
    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado'
        ELSE 'Aberto'
    END AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim'
        ELSE 'Não'
    END AS "Cancelado",
    T4."State" AS "UF",
    T4."City" AS "Cidade",
    CAST(T7."U_ChaveAcesso" AS NVARCHAR(100)) AS "Chave de Acesso",
    T7."U_msgSEFAZ" AS "Mensagem de retorno",    
    CASE 
        WHEN T8."U_SPS_Suframa" = 'Y' THEN 'SIM'
        ELSE 'NÃO'
    END AS "Possui Suframa",
    CASE 
        WHEN T8."U_SPS_SuspIPI" = '0' THEN 'SIM'
        ELSE 'NÃO'
    END AS "Possui Suspensão de IPI",
    T1."TaxCode" AS "Código Imposto",
    T9."Name" AS "Descrição Cod. Imposto"
FROM OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
    INNER JOIN OSTC T9 ON T1."TaxCode" = T9."Code"
    INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
    LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'S' AND T4."Address" = T0."ShipToCode"
    LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
    LEFT JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
    LEFT JOIN "SBOGPHARMA"."@SKL25NFE" T7 ON T0."DocEntry" = T7."U_DocEntry" 
    LEFT JOIN OCRD T8 ON T0."CardCode" = T8."CardCode"
    LEFT JOIN "@GB_GER_CARTEIRA" T14 ON T8."U_GB_GER_CARTEIRA" = T14."Code"    
    LEFT JOIN ORDR T10 ON T1."BaseType" = 17 AND T1."BaseEntry" = T10."DocEntry"
    LEFT JOIN DLN1 T12 ON T1."BaseType" = 15 AND T1."BaseEntry" = T12."DocEntry" AND T1."BaseLine" = T12."LineNum"
    LEFT JOIN ORDR T13 ON T12."BaseType" = 17 AND T12."BaseEntry" = T13."DocEntry"
WHERE 
    T0."Model" = 39 
    AND T0."DocDate" >= TO_DATE('01/10/2026', 'DD/MM/YYYY')
    AND T0."DocDate" <= TO_DATE('31/10/2026', 'DD/MM/YYYY')
ORDER BY 
    T0."DocEntry",
    T1."LineNum";


/*
-- CONSULTA ANTIGA

SELECT
    T0."DocEntry",
    T0."DocNum" AS "Nº Primário",
    COALESCE(T10."NumAtCard", T13."NumAtCard") AS "Nº referência PN do pedido",
    T3."SlpName" AS "Vendedor",
    T0."DocDate" AS "Data de Emissão",
    T0."Serial" AS "Nº NF",
    T0."CardCode" AS "Código do PN",
    T0."CardName" AS "Razão Social",
    T1."ItemCode" AS "Produto",
    T1."Dscription",
    T1."U_SPS_ListNum" AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão'
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto'
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional'
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar'
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro'
        WHEN T1."U_SPS_ListNum" = '7' THEN 'Nitro Financeiro'
    END AS "Lista de Preço",
    T6."Carrier",
    T0."U_SPS_Transportadora",
    T1."U_SPS_PercTrademarketing" AS "Percentual Trade Marketing",
    T1."Quantity" AS "Qtde",
    T1."LineTotal" AS "Total por Produto",
    T0."NfeValue",
    T2."Usage" AS "Utilização",
    T0."Comments",
    T5."CodeBars" AS "EAN",

    -- COLUNA: BONIFICAÇÃO TALÃO
    CASE 
        WHEN T1."Usage" = 12 AND 
             COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade", 'N') = 'N' AND 
             COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra", 'N') = 'N' 
        THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Talão",

    -- COLUNA: BONIFICAÇÃO EXTRA
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Extra",

    -- COLUNA: BONIFICAÇÃO TRADE
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END AS "Bonificação Trade",

    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado'
        ELSE 'Aberto'
    END AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim'
        ELSE 'Não'
    END AS "Cancelado",
    T4."State" AS UF,
    T4."City" AS Cidade,
    CAST(T7."U_ChaveAcesso" AS NVARCHAR(100)) AS "Chave de Acesso",
    T7."U_msgSEFAZ" AS "Mensagem de retorno",
    
    CASE 
        WHEN T8."U_SPS_Suframa" ='Y' THEN 'SIM'
        ELSE 'NÃO'
    END AS "Possui Suframa",

    CASE 
        WHEN T8."U_SPS_SuspIPI" ='0' THEN 'SIM'
        ELSE 'NÃO'
    END AS "Possui Suspensão de IPI",
    T1."TaxCode" AS "Código Imposto",
    T9."Name" AS "Descrição Cod. Imposto"
   
FROM  
    OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
    INNER JOIN OSTC T9 ON T1."TaxCode" = T9."Code"
    INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
    LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'B'
    LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
    INNER JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
    INNER JOIN "SBOGPHARMA"."@SKL25NFE" T7 ON T0."DocEntry" = T7."U_DocEntry" 
    INNER JOIN OCRD T8 ON T0."CardCode" = T8."CardCode"
    
    -- Joins para rastrear a origem no Pedido de Venda
    LEFT JOIN ORDR T10 ON T1."BaseType" = 17 AND T1."BaseEntry" = T10."DocEntry"
    LEFT JOIN DLN1 T12 ON T1."BaseType" = 15 AND T1."BaseEntry" = T12."DocEntry" AND T1."BaseLine" = T12."LineNum"
    LEFT JOIN ORDR T13 ON T12."BaseType" = 17 AND T12."BaseEntry" = T13."DocEntry"

WHERE  
    T0."Model" = 39 
    AND T0."DocDate" >= [%0] 
    AND T0."DocDate" <= [%1]

ORDER BY  
    T0."DocEntry";
*/

-- NOVA CONSULTA - SAP B1

SELECT DISTINCT
    -- Identificação do Documento de Saída (Cabeçalho)
    T0."DocEntry",
    T0."DocNum"                                            AS "Nº Primário",
    T0."Serial"                                            AS "Nº NF",
    COALESCE(T10."NumAtCard", T13."NumAtCard")             AS "Nº referência PN do pedido",
    T0."DocDate"                                           AS "Data de Emissão",
    T0."Comments"                                          AS "Observações",
    T0."NfeValue"                                          AS "Valor NF-e",

    -- Segmentação e Carteira de Clientes
    T8."U_SPS_Canal"                                       AS "Cód. Canal",
    CASE
        WHEN T8."U_SPS_Canal" = '0' THEN 'Indireto'
        WHEN T8."U_SPS_Canal" = '1' THEN 'Hospital'
        WHEN T8."U_SPS_Canal" = '2' THEN 'Parceiro'
        WHEN T8."U_SPS_Canal" = '3' THEN 'Direto'
        WHEN T8."U_SPS_Canal" = '4' THEN 'Governo'
        WHEN T8."U_SPS_Canal" = '5' THEN 'Outros'
        ELSE 'Não Definido'
    END                                                    AS "Descrição Canal",
    T14."Name"                                             AS "Gerente Regional",
    T3."SlpName"                                           AS "Vendedor",

    -- Parceiro de Negócios e Localização
    T0."CardCode"                                          AS "Código do PN",
    T0."CardName"                                          AS "Razão Social",
    T4."State"                                             AS "UF",
    T4."City"                                              AS "Cidade",
    CASE 
        WHEN T8."U_SPS_Suframa" = 'Y' THEN 'SIM'
        ELSE 'NÃO'
    END                                                    AS "Possui Suframa",
    CASE 
        WHEN T8."U_SPS_SuspIPI" = '0' THEN 'SIM'
        ELSE 'NÃO'
    END                                                    AS "Possui Suspensão de IPI",

    -- Detalhes das Linhas do Documento (Itens)
    T1."LineNum"                                           AS "Nº da Linha", 
    T1."ItemCode"                                          AS "Produto",
    T1."Dscription"                                        AS "Descrição do Produto",
    T5."CodeBars"                                          AS "EAN",
    T1."Quantity"                                          AS "Qtde",
    T1."LineTotal"                                         AS "Total por Produto",
    T2."Usage"                                             AS "Utilização",

    -- Tributação e Impostos
    T1."TaxCode"                                           AS "Código Imposto",
    T9."Name"                                              AS "Descrição Cod. Imposto",

    -- Tabelas de Preço e Trade Marketing
    T1."U_SPS_ListNum"                                     AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão'
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto'
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional'
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar'
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro'
        WHEN T1."U_SPS_ListNum" = '7' THEN 'Nitro Financeiro'
    END                                                    AS "Lista de Preço",
    T1."U_SPS_PercTrademarketing"                          AS "Percentual Trade Marketing",

    -- Logística e Transporte
    T6."Carrier"                                           AS "Transportadora (NF-e)",
    T0."U_SPS_Transportadora"                              AS "Transportadora (Inserção)",

    -- Regras de Bonificação
    CASE 
        WHEN T1."Usage" = 12 AND 
             COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade", 'N') = 'N' AND 
             COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra", 'N') = 'N' 
        THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Talão",
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoExtra", T13."U_SPS_BonificaoExtra") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Extra",
    CASE 
        WHEN COALESCE(T10."U_SPS_BonificaoTrade", T13."U_SPS_BonificaoTrade") = 'Y' THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Bonificação Trade",

    -- Status e Dados de Integração SEFAZ
    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado'
        ELSE 'Aberto'
    END                                                    AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim'
        ELSE 'Não'
    END                                                    AS "Cancelado",
    CAST(T7."U_ChaveAcesso" AS NVARCHAR(100))             AS "Chave de Acesso",
    T7."U_msgSEFAZ"                                        AS "Mensagem de retorno"

FROM OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
    INNER JOIN OSTC T9 ON T1."TaxCode" = T9."Code"
    INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
    LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'S' AND T4."Address" = T0."ShipToCode"
    LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
    LEFT JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
    LEFT JOIN "@SKL25NFE" T7 ON T0."DocEntry" = T7."U_DocEntry" 
    LEFT JOIN OCRD T8 ON T0."CardCode" = T8."CardCode"
    LEFT JOIN "@GB_GER_CARTEIRA" T14 ON T8."U_GB_GER_CARTEIRA" = T14."Code"    
    LEFT JOIN ORDR T10 ON T1."BaseType" = 17 AND T1."BaseEntry" = T10."DocEntry"
    LEFT JOIN DLN1 T12 ON T1."BaseType" = 15 AND T1."BaseEntry" = T12."DocEntry" AND T1."BaseLine" = T12."LineNum"
    LEFT JOIN ORDR T13 ON T12."BaseType" = 17 AND T12."BaseEntry" = T13."DocEntry"

WHERE 
    T0."Model" = 39 
    AND T0."DocDate" >= [%0]
    AND T0."DocDate" <= [%1]

ORDER BY 
    T0."DocEntry",
    T1."LineNum";