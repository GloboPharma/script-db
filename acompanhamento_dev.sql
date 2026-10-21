/*
==============================================================================
ORDEM DE SERVIÇO: 20637
VIEW SAP HANA: VW_ACOMPANHAMENTO_DEVOLUCAO
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 20/10/2026
OBJETIVO: Acompanhamento do fluxo de devolução - Rastreamento dos documentos (Pedido -> Devolução -> NF) e cálculo de tempos 
de permanência por etapa (Expedição, Fiscal e Cobrança/Garantia)
AMBIENTE: SAP Business One (SAP HANA)
==============================================================================
*/

CREATE OR REPLACE VIEW "SBOGPHARMA"."VW_ACOMPANHAMENTO_DEVOLUCAO" AS
SELECT DISTINCT 
    T0."DocNum" AS "Número do Pedido de Devolução",
    T0."DocDate" AS "Data do Pedido de Devolução",
    T0."CardCode" AS "Código do Cliente",
    T0."CardName" AS "Nome do Cliente",
    T0."DocTotal" AS "Valor Total do Pedido de Devolução",
    T0."NumAtCard" AS "N° de Referência PN",
    T2."DocNum" AS "Número da Devolução",
    T2."DocDate" AS "Data da Devolução",
    T2."DocTotal" AS "Valor Total da Devolução",
    T4."DocNum" AS "Número da Nota Fiscal",
    T4."DocDate" AS "Data da Nota Fiscal",
    T4."DocTotal" AS "Valor Total da Nota Fiscal",
    CASE 
        WHEN T4."DocNum" IS NOT NULL THEN 'Cobrança/Garantia'
        WHEN T2."DocNum" IS NOT NULL THEN 'Fiscal'
        ELSE 'Expedição'
    END AS "Status do Processo",
    CASE 
        WHEN T2."DocDate" IS NOT NULL THEN DAYS_BETWEEN(T0."DocDate", T2."DocDate")
        ELSE DAYS_BETWEEN(T0."DocDate", CURRENT_DATE)
    END AS "Dias na Expedição",
    CASE 
        WHEN T2."DocDate" IS NULL THEN NULL 
        WHEN T4."DocDate" IS NOT NULL THEN DAYS_BETWEEN(T2."DocDate", T4."DocDate")
        ELSE DAYS_BETWEEN(T2."DocDate", CURRENT_DATE)
    END AS "Dias no Fiscal",
    CASE 
        WHEN T4."DocDate" IS NOT NULL THEN DAYS_BETWEEN(T4."DocDate", CURRENT_DATE)
        ELSE NULL
    END AS "Dias na Cobrança/Garantia",
    CASE 
        WHEN T4."DocDate" IS NOT NULL THEN DAYS_BETWEEN(T0."DocDate", T4."DocDate")
        ELSE DAYS_BETWEEN(T0."DocDate", CURRENT_DATE)
    END AS "Tempo Total (Dias)"
FROM "ORRR" T0 
INNER JOIN "RRR1" T1 ON T0."DocEntry" = T1."DocEntry"
LEFT JOIN
    (SELECT 
        X0."DocEntry", X0."BaseEntry", X0."LineNum", X0."BaseLine"
        FROM "RDN1" X0 
        INNER JOIN "ORDN" X1 ON X0."DocEntry" = X1."DocEntry" 
        WHERE X1."CANCELED" = 'N'
    ) T22 ON T1."DocEntry" = T22."BaseEntry" AND T1."LineNum" = T22."BaseLine"
LEFT JOIN "ORDN" T2 ON T22."DocEntry" = T2."DocEntry" AND T2."CANCELED" = 'N'
LEFT JOIN
    (SELECT 
        X0."DocEntry", X0."BaseEntry", X0."BaseLine" 
        FROM "RIN1" X0 
        INNER JOIN "ORIN" X1 ON X0."DocEntry" = X1."DocEntry" 
        WHERE X1."CANCELED" = 'N'
    ) T44 ON T2."DocEntry" = T44."BaseEntry" AND T22."LineNum" = T44."BaseLine"
LEFT JOIN "ORIN" T4 ON T44."DocEntry" = T4."DocEntry" AND T4."CANCELED" = 'N'
WHERE 
    (T2."DocDate" IS NULL OR DAYS_BETWEEN(T0."DocDate", T2."DocDate") >= 0)
    AND (T4."DocDate" IS NULL OR T4."DocDate" >= T0."DocDate")
    AND T0."CANCELED" = 'N';

-- ==============================================================================
-- EXEMPLO DE CONSULTA COM A ORDENAÇÃO ORIGINAL:
-- ==============================================================================
-- SELECT * 
-- FROM "SBOGPHARMA"."VW_ACOMPANHAMENTO_DEVOLUCAO"
-- ORDER BY "Data do Pedido de Devolução" DESC;