/*
==============================================================================
ORDEM DE SERVIÇO: 20637
VIEW SAP HANA: VW_ESTOQUE_COM_E_SEM
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 20/10/2026
OBJETIVO: Posição consolidada de estoque geral com e sem controle de lote, posições de depósito (BIN), rastreabilidade de última
movimentação, custos e status de validade do lote
AMBIENTE: SAP Business One (SAP HANA)
==============================================================================
*/

CREATE OR REPLACE VIEW "SBOGPHARMA"."VW_ESTOQUE_COM_E_SEM" AS

/* 1) DEPÓSITOS COM POSIÇÃO (BIN) + ITENS COM LOTE (OBBQ) */
SELECT
    T0."ItemCode",
    T0."ItemName",
    T3."ItmsGrpNam",
    T0."InvntryUom",
    BQ."WhsCode",
    W."WhsName",
    BIN."BinCode" AS "Posicao",
    BN."DistNumber" AS "Lote",
    BN."MnfDate"     AS "DataFabricacao",
    BN."ExpDate"     AS "DataVencimento",
    BQ."OnHandQty"   AS "Quantidade",
    T1."AvgPrice"    AS "CustoUnitario",
    BQ."OnHandQty" * T1."AvgPrice" AS "Custo Total",
    T0."U_SPS_PROD_CONTRL",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN 'LOTE'
        ELSE 'SEM LOTE'
    END AS "TipoControle",
    COALESCE(LB."LastMovDate", L."LastMovDate") AS "LastMovDate",
    COALESCE(LB."TransType",   L."TransType")   AS "TransType",
    CASE COALESCE(LB."TransType", L."TransType")
        WHEN 59  THEN 'Entrada de Estoque (OIGN)'
        WHEN 60  THEN 'Saída de Estoque (OIGE)'
        WHEN 67  THEN 'Transferência de Estoque (OWTR)'
        WHEN 15  THEN 'Entrega (ODLN)'
        WHEN 16  THEN 'Devolução de Entrega (ORDN)'
        WHEN 13  THEN 'Fatura de Saída (OINV)'
        WHEN 14  THEN 'Nota de Crédito de Saída (ORIN)'
        WHEN 202 THEN 'Ordem de Produção (OWOR)'
        ELSE 'Outro (TransType=' || TO_NVARCHAR(COALESCE(LB."TransType", L."TransType")) || ')'
    END AS "TransTypeDesc",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN
            'BaseType=' || TO_NVARCHAR(LB."TransType") || ' / BaseNum=' || TO_NVARCHAR(LB."BaseNum")
        ELSE
            'TransNum=' || TO_NVARCHAR(L."TransNum")
    END AS "UltimoRef",
    COALESCE(
        GR."DocNum", GI."DocNum", WT."DocNum", DL."DocNum",
        RN."DocNum", AI."DocNum", CN."DocNum", WO."DocNum",
        LB."BaseNum"
    ) AS "LastDocNum",
    DAYS_BETWEEN(
        COALESCE(LB."LastMovDate", L."LastMovDate"),
        CURRENT_DATE
    ) AS "DiasSemMovimentacao",
    CASE
        WHEN BN."ExpDate" IS NULL THEN NULL
        ELSE DAYS_BETWEEN(CURRENT_DATE, BN."ExpDate")
    END AS "DiasParaVencer",
    CASE
        WHEN BN."DistNumber" IS NULL THEN 'SEM LOTE'
        WHEN BN."ExpDate" IS NULL THEN 'SEM VENCIMENTO'
        WHEN BN."ExpDate" < CURRENT_DATE THEN 'VENCIDO'
        WHEN BN."ExpDate" <= ADD_DAYS(CURRENT_DATE, 30) THEN 'A VENCER (<=30d)'
        ELSE 'OK'
    END AS "StatusLote"
FROM "SBOGPHARMA"."OBBQ" BQ
JOIN "SBOGPHARMA"."OBIN" BIN
  ON BIN."AbsEntry" = BQ."BinAbs"
JOIN "SBOGPHARMA"."OWHS" W
  ON W."WhsCode" = BQ."WhsCode"
 AND W."BinActivat" = 'Y'
JOIN "SBOGPHARMA"."OITM" T0
  ON T0."ItemCode" = BQ."ItemCode"
JOIN "SBOGPHARMA"."OITB" T3
  ON T3."ItmsGrpCod" = T0."ItmsGrpCod"
JOIN "SBOGPHARMA"."OITW" T1
  ON T1."ItemCode" = BQ."ItemCode"
 AND T1."WhsCode"  = BQ."WhsCode"
LEFT JOIN "SBOGPHARMA"."OBTN" BN
  ON BN."AbsEntry" = BQ."SnBMDAbs"
LEFT JOIN (
    SELECT
        X."ItemCode",
        X."WhsCode",
        X."DocDate"     AS "LastMovDate",
        X."TransType",
        X."DocEntryLink",
        X."TransNum"
    FROM (
        SELECT
            M1."ItemCode",
            M1."Warehouse" AS "WhsCode",
            M1."DocDate",
            M1."TransType",
            M1."AppObjAbs" AS "DocEntryLink",
            M1."TransNum",
            ROW_NUMBER() OVER(
                PARTITION BY M1."ItemCode", M1."Warehouse"
                ORDER BY M1."DocDate" DESC, M1."TransNum" DESC
            ) AS rn
        FROM "SBOGPHARMA"."OINM" M1
    ) X
    WHERE X.rn = 1
) L
  ON L."ItemCode" = T1."ItemCode"
 AND L."WhsCode"  = T1."WhsCode"
LEFT JOIN (
    SELECT
        Y."ItemCode",
        Y."WhsCode",
        Y."BatchNum",
        Y."DocDate"   AS "LastMovDate",
        Y."BaseType"  AS "TransType",
        Y."BaseEntry" AS "DocEntryLink",
        Y."BaseNum"
    FROM (
        SELECT
            I."ItemCode",
            I."WhsCode",
            I."BatchNum",
            I."DocDate",
            I."BaseType",
            I."BaseEntry",
            I."BaseNum",
            I."CreateDate",
            I."LineNum",
            ROW_NUMBER() OVER(
                PARTITION BY I."ItemCode", I."WhsCode", I."BatchNum"
                ORDER BY I."DocDate" DESC, I."CreateDate" DESC, I."BaseEntry" DESC, I."LineNum" DESC
            ) AS rn
        FROM "SBOGPHARMA"."IBT1" I
    ) Y
    WHERE Y.rn = 1
) LB
  ON LB."ItemCode" = T1."ItemCode"
 AND LB."WhsCode"  = T1."WhsCode"
 AND LB."BatchNum" = BN."DistNumber"
LEFT JOIN "SBOGPHARMA"."OIGN" GR ON COALESCE(LB."TransType", L."TransType") = 59  AND GR."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OIGE" GI ON COALESCE(LB."TransType", L."TransType") = 60  AND GI."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OWTR" WT ON COALESCE(LB."TransType", L."TransType") = 67  AND WT."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ODLN" DL ON COALESCE(LB."TransType", L."TransType") = 15  AND DL."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ORDN" RN ON COALESCE(LB."TransType", L."TransType") = 16  AND RN."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OINV" AI ON COALESCE(LB."TransType", L."TransType") = 13  AND AI."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ORIN" CN ON COALESCE(LB."TransType", L."TransType") = 14  AND CN."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OWOR" WO ON COALESCE(LB."TransType", L."TransType") = 202 AND WO."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
WHERE BQ."OnHandQty" > 0

UNION ALL

/* 2) DEPÓSITOS COM POSIÇÃO (BIN) + ITENS SEM LOTE (OIBQ) */
SELECT
    T0."ItemCode",
    T0."ItemName",
    T3."ItmsGrpNam",
    T0."InvntryUom",
    QB."WhsCode",
    W."WhsName",
    BIN."BinCode" AS "Posicao",
    CAST(NULL AS NVARCHAR(50)) AS "Lote",
    CAST(NULL AS DATE)         AS "DataFabricacao",
    CAST(NULL AS DATE)         AS "DataVencimento",
    QB."OnHandQty" AS "Quantidade",
    T1."AvgPrice"  AS "CustoUnitario",
    QB."OnHandQty" * T1."AvgPrice" AS "Custo Total",
    T0."U_SPS_PROD_CONTRL",
    'SEM LOTE' AS "TipoControle",
    L."LastMovDate",
    L."TransType",
    CASE L."TransType"
        WHEN 59  THEN 'Entrada de Estoque (OIGN)'
        WHEN 60  THEN 'Saída de Estoque (OIGE)'
        WHEN 67  THEN 'Transferência de Estoque (OWTR)'
        WHEN 15  THEN 'Entrega (ODLN)'
        WHEN 16  THEN 'Devolução de Entrega (ORDN)'
        WHEN 13  THEN 'Fatura de Saída (OINV)'
        WHEN 14  THEN 'Nota de Crédito de Saída (ORIN)'
        WHEN 202 THEN 'Ordem de Produção (OWOR)'
        ELSE 'Outro (TransType=' || TO_NVARCHAR(L."TransType") || ')'
    END AS "TransTypeDesc",
    'TransNum=' || TO_NVARCHAR(L."TransNum") AS "UltimoRef",
    COALESCE(
        GR."DocNum", GI."DocNum", WT."DocNum", DL."DocNum",
        RN."DocNum", AI."DocNum", CN."DocNum", WO."DocNum"
    ) AS "LastDocNum",
    DAYS_BETWEEN(L."LastMovDate", CURRENT_DATE) AS "DiasSemMovimentacao",
    CAST(NULL AS INTEGER) AS "DiasParaVencer",
    'SEM LOTE' AS "StatusLote"
FROM "SBOGPHARMA"."OIBQ" QB
JOIN "SBOGPHARMA"."OBIN" BIN
  ON BIN."AbsEntry" = QB."BinAbs"
JOIN "SBOGPHARMA"."OWHS" W
  ON W."WhsCode" = QB."WhsCode"
 AND W."BinActivat" = 'Y'
JOIN "SBOGPHARMA"."OITM" T0
  ON T0."ItemCode" = QB."ItemCode"
JOIN "SBOGPHARMA"."OITB" T3
  ON T3."ItmsGrpCod" = T0."ItmsGrpCod"
JOIN "SBOGPHARMA"."OITW" T1
  ON T1."ItemCode" = QB."ItemCode"
 AND T1."WhsCode"  = QB."WhsCode"
LEFT JOIN (
    SELECT
        X."ItemCode",
        X."WhsCode",
        X."DocDate"     AS "LastMovDate",
        X."TransType",
        X."DocEntryLink",
        X."TransNum"
    FROM (
        SELECT
            M1."ItemCode",
            M1."Warehouse" AS "WhsCode",
            M1."DocDate",
            M1."TransType",
            M1."AppObjAbs" AS "DocEntryLink",
            M1."TransNum",
            ROW_NUMBER() OVER(
                PARTITION BY M1."ItemCode", M1."Warehouse"
                ORDER BY M1."DocDate" DESC, M1."TransNum" DESC
            ) AS rn
        FROM "SBOGPHARMA"."OINM" M1
    ) X
    WHERE X.rn = 1
) L
  ON L."ItemCode" = T1."ItemCode"
 AND L."WhsCode"  = T1."WhsCode"
LEFT JOIN "SBOGPHARMA"."OIGN" GR ON L."TransType" = 59  AND GR."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."OIGE" GI ON L."TransType" = 60  AND GI."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."OWTR" WT ON L."TransType" = 67  AND WT."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."ODLN" DL ON L."TransType" = 15  AND DL."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."ORDN" RN ON L."TransType" = 16  AND RN."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."OINV" AI ON L."TransType" = 13  AND AI."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."ORIN" CN ON L."TransType" = 14  AND CN."DocEntry" = L."DocEntryLink"
LEFT JOIN "SBOGPHARMA"."OWOR" WO ON L."TransType" = 202 AND WO."DocEntry" = L."DocEntryLink"
WHERE QB."OnHandQty" > 0 AND T0."ManBtchNum" = 'N'

UNION ALL

/* 3) DEPÓSITOS SEM POSIÇÃO (SEM BIN) (OBTQ / OITW) */
SELECT
    T0."ItemCode",
    T0."ItemName",
    T3."ItmsGrpNam",
    T0."InvntryUom",
    T1."WhsCode",
    T2."WhsName",
    CAST(NULL AS NVARCHAR(254)) AS "Posicao",
    BN."DistNumber" AS "Lote",
    BN."MnfDate"     AS "DataFabricacao",
    BN."ExpDate"     AS "DataVencimento",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN B."Quantity"
        ELSE T1."OnHand"
    END AS "Quantidade",
    T1."AvgPrice" AS "CustoUnitario",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN B."Quantity"
        ELSE T1."OnHand"
    END * T1."AvgPrice" AS "Custo Total",
    T0."U_SPS_PROD_CONTRL",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN 'LOTE'
        ELSE 'SEM LOTE'
    END AS "TipoControle",
    COALESCE(LB."LastMovDate", L."LastMovDate") AS "LastMovDate",
    COALESCE(LB."TransType",   L."TransType")   AS "TransType",
    CASE COALESCE(LB."TransType", L."TransType")
        WHEN 59  THEN 'Entrada de Estoque (OIGN)'
        WHEN 60  THEN 'Saída de Estoque (OIGE)'
        WHEN 67  THEN 'Transferência de Estoque (OWTR)'
        WHEN 15  THEN 'Entrega (ODLN)'
        WHEN 16  THEN 'Devolução de Entrega (ORDN)'
        WHEN 13  THEN 'Fatura de Saída (OINV)'
        WHEN 14  THEN 'Nota de Crédito de Saída (ORIN)'
        WHEN 202 THEN 'Ordem de Produção (OWOR)'
        ELSE 'Outro (TransType=' || TO_NVARCHAR(COALESCE(LB."TransType", L."TransType")) || ')'
    END AS "TransTypeDesc",
    CASE
        WHEN BN."DistNumber" IS NOT NULL THEN
            'BaseType=' || TO_NVARCHAR(LB."TransType") || ' / BaseNum=' || TO_NVARCHAR(LB."BaseNum")
        ELSE
            'TransNum=' || TO_NVARCHAR(L."TransNum")
    END AS "UltimoRef",
    COALESCE(
        GR."DocNum", GI."DocNum", WT."DocNum", DL."DocNum",
        RN."DocNum", AI."DocNum", CN."DocNum", WO."DocNum",
        LB."BaseNum"
    ) AS "LastDocNum",
    DAYS_BETWEEN(
        COALESCE(LB."LastMovDate", L."LastMovDate"),
        CURRENT_DATE
    ) AS "DiasSemMovimentacao",
    CASE
        WHEN BN."ExpDate" IS NULL THEN NULL
        ELSE DAYS_BETWEEN(CURRENT_DATE, BN."ExpDate")
    END AS "DiasParaVencer",
    CASE
        WHEN BN."DistNumber" IS NULL THEN 'SEM LOTE'
        WHEN BN."ExpDate" IS NULL THEN 'SEM VENCIMENTO'
        WHEN BN."ExpDate" < CURRENT_DATE THEN 'VENCIDO'
        WHEN BN."ExpDate" <= ADD_DAYS(CURRENT_DATE, 30) THEN 'A VENCER (<=30d)'
        ELSE 'OK'
    END AS "StatusLote"
FROM "SBOGPHARMA"."OITM" T0
JOIN "SBOGPHARMA"."OITW" T1
  ON T0."ItemCode" = T1."ItemCode"
JOIN "SBOGPHARMA"."OWHS" T2
  ON T1."WhsCode" = T2."WhsCode"
 AND (T2."BinActivat" IS NULL OR T2."BinActivat" <> 'Y')
JOIN "SBOGPHARMA"."OITB" T3
  ON T0."ItmsGrpCod" = T3."ItmsGrpCod"
LEFT JOIN "SBOGPHARMA"."OBTQ" B
  ON B."ItemCode" = T1."ItemCode"
 AND B."WhsCode"  = T1."WhsCode"
 AND B."Quantity" > 0
LEFT JOIN "SBOGPHARMA"."OBTN" BN
  ON BN."ItemCode"  = B."ItemCode"
 AND BN."SysNumber" = B."SysNumber"
LEFT JOIN (
    SELECT
        X."ItemCode",
        X."WhsCode",
        X."DocDate"     AS "LastMovDate",
        X."TransType",
        X."DocEntryLink",
        X."TransNum"
    FROM (
        SELECT
            M1."ItemCode",
            M1."Warehouse" AS "WhsCode",
            M1."DocDate",
            M1."TransType",
            M1."AppObjAbs" AS "DocEntryLink",
            M1."TransNum",
            ROW_NUMBER() OVER(
                PARTITION BY M1."ItemCode", M1."Warehouse"
                ORDER BY M1."DocDate" DESC, M1."TransNum" DESC
            ) AS rn
        FROM "SBOGPHARMA"."OINM" M1
    ) X
    WHERE X.rn = 1
) L
  ON L."ItemCode" = T1."ItemCode"
 AND L."WhsCode"  = T1."WhsCode"
LEFT JOIN (
    SELECT
        Y."ItemCode",
        Y."WhsCode",
        Y."BatchNum",
        Y."DocDate"   AS "LastMovDate",
        Y."BaseType"  AS "TransType",
        Y."BaseEntry" AS "DocEntryLink",
        Y."BaseNum"
    FROM (
        SELECT
            I."ItemCode",
            I."WhsCode",
            I."BatchNum",
            I."DocDate",
            I."BaseType",
            I."BaseEntry",
            I."BaseNum",
            I."CreateDate",
            I."LineNum",
            ROW_NUMBER() OVER(
                PARTITION BY I."ItemCode", I."WhsCode", I."BatchNum"
                ORDER BY I."DocDate" DESC, I."CreateDate" DESC, I."BaseEntry" DESC, I."LineNum" DESC
            ) AS rn
        FROM "SBOGPHARMA"."IBT1" I
    ) Y
    WHERE Y.rn = 1
) LB
  ON LB."ItemCode" = T1."ItemCode"
 AND LB."WhsCode"  = T1."WhsCode"
 AND LB."BatchNum" = BN."DistNumber"
LEFT JOIN "SBOGPHARMA"."OIGN" GR ON COALESCE(LB."TransType", L."TransType") = 59  AND GR."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OIGE" GI ON COALESCE(LB."TransType", L."TransType") = 60  AND GI."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OWTR" WT ON COALESCE(LB."TransType", L."TransType") = 67  AND WT."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ODLN" DL ON COALESCE(LB."TransType", L."TransType") = 15  AND DL."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ORDN" RN ON COALESCE(LB."TransType", L."TransType") = 16  AND RN."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OINV" AI ON COALESCE(LB."TransType", L."TransType") = 13  AND AI."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."ORIN" CN ON COALESCE(LB."TransType", L."TransType") = 14  AND CN."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
LEFT JOIN "SBOGPHARMA"."OWOR" WO ON COALESCE(LB."TransType", L."TransType") = 202 AND WO."DocEntry" = COALESCE(LB."DocEntryLink", L."DocEntryLink")
WHERE T1."OnHand" > 0;

-- ==============================================================================
-- EXEMPLO DE CONSULTA COM ORDENAÇÃO:
-- ==============================================================================
-- SELECT * 
-- FROM "SBOGPHARMA"."VW_ESTOQUE_COM_E_SEM"
-- ORDER BY
--     "ItemCode",
--     "StatusLote",
--     "DiasSemMovimentacao" DESC,
--     "WhsCode",
--     "Posicao",
--     "Lote";
