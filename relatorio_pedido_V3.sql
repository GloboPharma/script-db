/*
==============================================================================
ORDEM DE SERVIÇO: 20637
VIEW SAP HANA: VW_RELATORIO_PEDIDOS_V3
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 20/10/2026
OBJETIVO: Relatório de Pedidos de Devolução V3 - Fluxo de aprovação de esboços (OWDD/ODRF), efetivação do pedido (ORRR) e status do processo (Expedição -> Fiscal -> Cobrança)
AMBIENTE: SAP Business One (SAP HANA)
==============================================================================
*/

CREATE OR REPLACE VIEW "SBOGPHARMA"."VW_RELATORIO_PEDIDOS_V3" AS    
SELECT 
    IFNULL(T2."DocEntry", T1."DocEntry") AS "Key1", 
    CASE WHEN T2."DocEntry" IS NOT NULL THEN '234' ELSE '112' END AS "Obj1",
    T5."SlpName" AS "Nome do vendedor",
    T7."Name" AS "Gerente de Contas", 
    T2."DocNum" AS "Nº documento",
    T1."DocEntry" AS "Key2",
    '112' AS "Obj2",
    T1."DocEntry" AS "Chave do esboço",
    IFNULL(
        (SELECT MAX(A."U_SPS_NFOrigem") FROM "RRR1" A WHERE A."DocEntry" = T2."DocEntry"),
        (SELECT MAX(B."U_SPS_NFOrigem") FROM "DRF1" B WHERE B."DocEntry" = T1."DocEntry")
    ) AS "SPS - NF de Origem",
    CASE 
        WHEN T0."Status" = 'C' THEN 'Cancelado'
        WHEN T0."Status" = 'N' THEN 'Recusado'
        WHEN T0."Status" = 'P' THEN 'Gerado'
        WHEN T2."DocEntry" IS NOT NULL THEN 'Gerado'
        WHEN T0."Status" = 'W' THEN 'Pendente'
        WHEN T0."Status" = 'Y' THEN 'Autorizado'
        ELSE T0."Status"
    END AS "Status Aprovação",
    T1."NumAtCard" AS "NF Ref. Parceiro",
    T1."CardName" AS "Nome do PN",
    T1."CardCode" AS "Código do Cliente", 
    T1."DocTotal" AS "Valor Total",
    T1."DocCur" AS "Moeda",
    T3."U_NAME" AS "Autor",
    T1."DocDate" AS "Data de Lançamento Esboço",
    T1."Comments" AS "Observações do Esboço",
    T4."Descr" AS "Motivo de Devolução",
    T2."DocDate" AS "Data de Lançamento",
    CASE 
        WHEN T2."DocEntry" IS NULL THEN 'Esboço (Não Gerado)'
        WHEN T2."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN T2."DocStatus" = 'O' THEN 'Aberto' 
        WHEN T2."DocStatus" = 'C' THEN 'Fechado' 
        ELSE T2."DocStatus" 
    END AS "Status do Pedido",
    CASE 
        WHEN T2."DocEntry" IS NULL THEN 'Esboço (Não Gerado)'
        WHEN T2."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN T8."TemNF" = 1 THEN 'Cobrança'
        WHEN T8."TemDev" = 1 THEN 'Fiscal'
        ELSE 'Expedição'
    END AS "Status do Processo"
FROM "OWDD" T0
INNER JOIN "ODRF" T1 ON T0."DraftEntry" = T1."DocEntry"
LEFT JOIN "ORRR" T2 ON T0."DocEntry" = T2."DocEntry" 
INNER JOIN "OUSR" T3 ON T0."UserSign" = T3."USERID"
LEFT JOIN "UFD1" T4 ON T4."TableID" = 'ORRR' 
                 AND T4."FieldID" = (SELECT "FieldID" FROM "CUFD" WHERE "TableID" = 'ORRR' AND "AliasID" = 'SPS_MotivoDev')
                 AND T4."FldValue" = T2."U_SPS_MotivoDev"
LEFT JOIN "OSLP" T5 ON T5."SlpCode" = IFNULL(T2."SlpCode", T1."SlpCode")
LEFT JOIN "OCRD" T6 ON T6."CardCode" = T1."CardCode"
LEFT JOIN "@GB_GER_CARTEIRA" T7 ON T7."Code" = T6."U_GB_GER_CARTEIRA"
LEFT JOIN (
    SELECT 
        P0."DocEntry",
        MAX(CASE WHEN P2."DocEntry" IS NOT NULL THEN 1 ELSE 0 END) AS "TemDev",
        MAX(CASE WHEN P4."DocEntry" IS NOT NULL THEN 1 ELSE 0 END) AS "TemNF"
    FROM "ORRR" P0
    INNER JOIN "RRR1" P1 ON P0."DocEntry" = P1."DocEntry"
    LEFT JOIN
        (SELECT X0."DocEntry", X0."BaseEntry", X0."LineNum", X0."BaseLine"
           FROM "RDN1" X0 
          INNER JOIN "ORDN" X1 ON X0."DocEntry" = X1."DocEntry" 
          WHERE X1."CANCELED" = 'N'
        ) P22 ON P1."DocEntry" = P22."BaseEntry" AND P1."LineNum" = P22."BaseLine"
    LEFT JOIN "ORDN" P2 ON P22."DocEntry" = P2."DocEntry" AND P2."CANCELED" = 'N'
    LEFT JOIN
        (SELECT X0."DocEntry", X0."BaseEntry", X0."BaseLine" 
           FROM "RIN1" X0 
          INNER JOIN "ORIN" X1 ON X0."DocEntry" = X1."DocEntry" 
          WHERE X1."CANCELED" = 'N'
        ) P44 ON P2."DocEntry" = P44."BaseEntry" AND P22."LineNum" = P44."BaseLine"
    LEFT JOIN "ORIN" P4 ON P44."DocEntry" = P4."DocEntry" AND P4."CANCELED" = 'N'
    WHERE 
        (P2."DocDate" IS NULL OR DAYS_BETWEEN(P0."DocDate", P2."DocDate") >= 0)
        AND (P4."DocDate" IS NULL OR P4."DocDate" >= P0."DocDate")
    GROUP BY P0."DocEntry"
) T8 ON T8."DocEntry" = T2."DocEntry"
WHERE T1."ObjType" = '234000031';

-- ==============================================================================
-- EXEMPLO DE CONSULTA COM A ORDENAÇÃO ORIGINAL:
-- ==============================================================================
-- SELECT * 
-- FROM "SBOGPHARMA"."VW_RELATORIO_PEDIDOS_V3"
-- ORDER BY "Data de Lançamento Esboço" DESC, "Key2" DESC;