/*
===============================================================================
ORDEM DE SERVIÇO: 20727
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 22/10/2026
OBJETIVO: Relatório de Notas Fiscais de Entrada com Impostos Pagos, seguindo o padrão de identificação do relatório de NF de Saída (Canal, Gerente Regional, PN, Situação do Documento), sem
          detalhamento dos itens. Consolidação por NF/pagamento.
AMBIENTE: SAP Business One (SAP HANA) - Gerenciador de Consultas
OBSERVAÇÃO: Mantidos os critérios fiscais e o filtro de pagamentos do relatório original. Validar campos UDF no ambiente.
===============================================================================
*/


WITH IMPOSTOS AS (
    SELECT
        "DocEntry",
        SUM(CASE WHEN "staType" = 24
            THEN "BaseSum" ELSE 0 END) AS "BC_ISS",
        MAX(CASE WHEN "staType" = 24
            THEN "TaxRate" END) AS "ALIQ_ISS",
        SUM(CASE WHEN "staType" = 24
            THEN "TaxSum" ELSE 0 END) AS "VAL_ISS",
        SUM(CASE WHEN "staType" IN (19, 20)
            THEN "BaseSum" ELSE 0 END) AS "BC_PIS",
        MAX(CASE WHEN "staType" IN (19, 20)
            THEN "TaxRate" END) AS "ALIQ_PIS",
        SUM(CASE WHEN "staType" IN (19, 20)
            THEN "TaxSum" ELSE 0 END) AS "VAL_PIS",
        SUM(CASE WHEN "staType" IN (21, 22)
            THEN "BaseSum" ELSE 0 END) AS "BC_COFINS",
        MAX(CASE WHEN "staType" IN (21, 22)
            THEN "TaxRate" END) AS "ALIQ_COFINS",
        SUM(CASE WHEN "staType" IN (21, 22)
            THEN "TaxSum" ELSE 0 END) AS "VAL_COFINS"
    FROM "PCH4"
    GROUP BY "DocEntry"
),
RETENCOES AS (
    SELECT
        "AbsEntry",
        SUM(CASE WHEN "WTTypeId" = 8
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_ISS_RET",
        MAX(CASE WHEN "WTTypeId" = 8
            THEN "Rate" END) AS "ALIQ_ISS_RET",
        SUM(CASE WHEN "WTTypeId" = 8
            THEN "WTAmnt" ELSE 0 END) AS "VAL_ISS_RET",
        SUM(CASE WHEN "WTTypeId" = 5
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_INSS_RET",
        MAX(CASE WHEN "WTTypeId" = 5
            THEN "Rate" END) AS "ALIQ_INSS_RET",
        SUM(CASE WHEN "WTTypeId" = 5
            THEN "WTAmnt" ELSE 0 END) AS "VAL_INSS_RET",
        SUM(CASE WHEN "WTTypeId" = 3
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_IRRF_RET",
        MAX(CASE WHEN "WTTypeId" = 3
            THEN "Rate" END) AS "ALIQ_IRRF_RET",
        SUM(CASE WHEN "WTTypeId" = 3
            THEN "WTAmnt" ELSE 0 END) AS "VAL_IRRF_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_PIS_RET",
        MAX(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_PIS_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_PIS_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_COFINS_RET",
        MAX(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_COFINS_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_COFINS_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_CSLL_RET",
        MAX(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_CSLL_RET",
        SUM(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_CSLL_RET"
    FROM "PCH5"
    GROUP BY "AbsEntry"
),
CENTROS_DISTINTOS AS (
    SELECT DISTINCT
        P."DocEntry",
        P."OcrCode",
        C."PrcName"
    FROM "PCH1" P
    LEFT JOIN "OPRC" C
        ON P."OcrCode" = C."PrcCode"
    WHERE P."OcrCode" IS NOT NULL
      AND P."OcrCode" <> ''
),
CENTROS_CUSTO AS (
    SELECT
        "DocEntry",
        STRING_AGG("OcrCode", ', ') AS "COD_CENTROS",
        STRING_AGG(
            IFNULL("PrcName", "OcrCode"), ', '
        ) AS "NOMES_CENTROS"
    FROM CENTROS_DISTINTOS
    GROUP BY "DocEntry"
),
ENDERECOS AS (
    SELECT
        "DocEntry",
        MAX("StateS") AS "UF"
    FROM "PCH12"
    GROUP BY "DocEntry"
)
SELECT
    T1."DocEntry",
    T1."DocNum" AS "Nº Primário",
    T1."DocDate" AS "Data de Lançamento",
    T1."TaxDate" AS "Data de Emissão",
    T1."DocDueDate" AS "Data de Vencimento NF",
    T20."TrsfrDate" AS "Data de Pagamento",
    T20."DocEntry" AS "Código Pagamento",
    T21."SumApplied" AS "Valor Pago",
    T1."DocTotal" AS "Valor Total NF",
    T1."Serial" AS "Nº NF",
    T13."NfmName" AS "Modelo",
    T1."CardCode" AS "Código Fornecedor",
    T1."CardName" AS "Fornecedor",
    T2."U_SPS_CNPJ" AS "CNPJ",
    T3."UF",
    -- CENTRO DE CUSTO CONSOLIDADO
    T30."COD_CENTROS" AS "Código Centro de Custo",
    T30."NOMES_CENTROS" AS "Centro de Custo",
    -- CONDIÇÃO DE PAGAMENTO
    T1."GroupNum" AS "Código Condição Pagamento",
    T31."PymntGroup" AS "Condição de Pagamento",
    -- ISS
    IFNULL(T4."BC_ISS", 0) AS "Val. BC ISS",
    IFNULL(T4."ALIQ_ISS", 0) AS "Aliq. ISS",
    IFNULL(T4."VAL_ISS", 0) AS "Val. ISS",
    -- PIS
    IFNULL(T4."BC_PIS", 0) AS "Val. BC PIS",
    IFNULL(T4."ALIQ_PIS", 0) AS "Aliq. PIS",
    IFNULL(T4."VAL_PIS", 0) AS "Val. PIS",
    -- COFINS
    IFNULL(T4."BC_COFINS", 0) AS "Val. BC COFINS",
    IFNULL(T4."ALIQ_COFINS", 0) AS "Aliq. COFINS",
    IFNULL(T4."VAL_COFINS", 0) AS "Val. COFINS",
    -- ISS RETIDO
    IFNULL(T5."BC_ISS_RET", 0) AS "Val. BC ISS Retido",
    IFNULL(T5."ALIQ_ISS_RET", 0) AS "Aliq. ISS Retido",
    IFNULL(T5."VAL_ISS_RET", 0) AS "Val. ISS Retido",
    -- INSS RETIDO
    IFNULL(T5."BC_INSS_RET", 0) AS "Val. BC INSS Retido",
    IFNULL(T5."ALIQ_INSS_RET", 0) AS "Aliq. INSS Retido",
    IFNULL(T5."VAL_INSS_RET", 0) AS "Val. INSS Retido",
    -- IRRF RETIDO
    IFNULL(T5."BC_IRRF_RET", 0) AS "Val. BC IRRF Retido",
    IFNULL(T5."ALIQ_IRRF_RET", 0) AS "Aliq. IRRF Retido",
    IFNULL(T5."VAL_IRRF_RET", 0) AS "Val. IRRF Retido",
    -- PIS RETIDO
    IFNULL(T5."BC_PIS_RET", 0) AS "Val. BC PIS Retido",
    IFNULL(T5."ALIQ_PIS_RET", 0) AS "Aliq. PIS Retido",
    IFNULL(T5."VAL_PIS_RET", 0) AS "Val. PIS Retido",
    -- COFINS RETIDO
    IFNULL(T5."BC_COFINS_RET", 0) AS "Val. BC COFINS Retido",
    IFNULL(T5."ALIQ_COFINS_RET", 0) AS "Aliq. COFINS Retido",
    IFNULL(T5."VAL_COFINS_RET", 0) AS "Val. COFINS Retido",
    -- CSLL RETIDO
    IFNULL(T5."BC_CSLL_RET", 0) AS "Val. BC CSLL Retido",
    IFNULL(T5."ALIQ_CSLL_RET", 0) AS "Aliq. CSLL Retido",
    IFNULL(T5."VAL_CSLL_RET", 0) AS "Val. CSLL Retido"
FROM "OPCH" T1
INNER JOIN "VPM2" T21
    ON T21."DocEntry" = T1."DocEntry"
   AND T21."InvType" = 18
INNER JOIN "OVPM" T20
    ON T20."DocEntry" = T21."DocNum"
   AND T20."Canceled" = 'N'
INNER JOIN "OCRD" T2
    ON T1."CardCode" = T2."CardCode"
LEFT JOIN ENDERECOS T3
    ON T1."DocEntry" = T3."DocEntry"
LEFT JOIN IMPOSTOS T4
    ON T1."DocEntry" = T4."DocEntry"
LEFT JOIN RETENCOES T5
    ON T1."DocEntry" = T5."AbsEntry"
LEFT JOIN "ONFM" T13
    ON T1."Model" = T13."AbsEntry"
LEFT JOIN CENTROS_CUSTO T30
    ON T1."DocEntry" = T30."DocEntry"
LEFT JOIN "OCTG" T31
    ON T1."GroupNum" = T31."GroupNum"
WHERE T1."CANCELED" = 'N'
  AND T20."TrsfrDate" >= DATE'2026-10-01'
  AND T20."TrsfrDate" < DATE'2026-10-23'
ORDER BY
    "Data de Pagamento",
    "Nº Primário",
    "Código Pagamento";

/*
-- CONSULTA ANTIGA

SELECT DISTINCT
--'Nota fiscal de Serviço' AS "Tipo",
T0."DocEntry",
T1."DocNum" AS "Nº Primário",
CAST (T1."DocDate" AS DATE) AS "Data de Lançamento",
CAST (T1."TaxDate" AS DATE) AS "Data de Emissão",
CAST (T1."DocDueDate" AS DATE) AS "Data de Vencimento NF",
CAST (T20."TrsfrDate" AS DATE) AS "Data de Pagamento",
 T20."TrsfrSumSy" AS "Valor Pago",
T1."Serial" AS "Nº NF",
T13."NfmName" AS "Modelo",
T1."CardName",
T2."U_SPS_CNPJ" AS "CNPJ",
T3."StateS" AS "UF",
T0."LineNum" AS "Nº da Linha",
T0."ItemCode",
T0."Dscription" AS "Descrição do Item",
T0."Quantity",
T0."Price" AS "Preço",
T0."LineTotal" AS "Total da Linha",
T0."CFOPCode",
IFNULL (T4."BaseSum",0) AS "Val. BC ISS",
IFNULL (T4."TaxRate",0) AS "Aliq. ISS",
IFNULL (T4."TaxSum",0) AS "Val. ISS",
IFNULL (T5."BaseSum",0) AS "Val. BC PIS",
IFNULL (T5."TaxRate",0) AS "Aliq. PIS",
IFNULL (T5."TaxSum",0) AS "Val. PIS",
T0."CSTfPIS" AS "CST PIS",
IFNULL (T6."BaseSum",0) AS "Val. BC COFINS",
IFNULL (T6."TaxRate",0) AS "Aliq. COFINS",
IFNULL (T6."TaxSum",0) AS "Val. COFINS",
T0."CSTfPIS" AS "CST COFINS",
IFNULL (T7."TaxbleAmnt",0) AS "Val. BC ISS Retido",
IFNULL (T7."Rate",0) AS "Aliq. ISS Retido",
IFNULL (T7."WTAmnt",0) AS "Val. ISS Retido",
IFNULL (T8."TaxbleAmnt",0) AS "Val. BC INSS Retido",
IFNULL (T8."Rate",0) AS "Aliq. INSS Retido",
IFNULL (T8."WTAmnt",0) AS "Val. INSS Retido",
IFNULL (T9."TaxbleAmnt",0) AS "Val. BC IRRF Retido",
IFNULL (T9."Rate",0) AS "Aliq. IRRF Retido",
IFNULL (T9."WTAmnt",0) AS "Val. IRRF Retido",
IFNULL (T10."TaxbleAmnt",0) AS "Val. BC PIS Retido",
IFNULL (T10."Rate",0) AS "Aliq. PIS Retido",
IFNULL (T10."WTAmnt",0) AS "Val. PIS Retido",
IFNULL (T11."TaxbleAmnt",0) AS "Val. BC COFINS Retido",
IFNULL (T11."Rate",0) AS "Aliq. COFINS Retido",
IFNULL (T11."WTAmnt",0) AS "Val. COFINS Retido",
IFNULL (T12."TaxbleAmnt",0) AS "Val. BC CSLL Retido",
IFNULL (T12."Rate",0) AS "Aliq. CSLL Retido",
IFNULL (T12."WTAmnt",0) AS "Val. CSLL Retido"

FROM PCH1 T0
INNER JOIN OPCH T1 ON T0."DocEntry" = T1."DocEntry"
INNER JOIN OVPM T20 ON T20."DocEntry" = T1."ReceiptNum"
INNER JOIN OCRD T2 ON T1."CardCode" = T2."CardCode"
INNER JOIN PCH12 T3 ON T0."DocEntry" = T3."DocEntry"
LEFT JOIN (SELECT DISTINCT "DocEntry","LineNum","TaxRate", SUM ("BaseSum") AS "BaseSum", SUM ("TaxSum") AS "TaxSum" FROM PCH4 WHERE "staType" = 24 GROUP BY "DocEntry","LineNum","TaxRate") T4 ON T0."DocEntry" = T4."DocEntry" AND T0."LineNum" = T4."LineNum" --ISS
LEFT JOIN (SELECT DISTINCT "DocEntry","LineNum","TaxRate", SUM ("BaseSum") AS "BaseSum", SUM ("TaxSum") AS "TaxSum" FROM PCH4 WHERE "staType" IN (19,20) GROUP BY "DocEntry","LineNum","TaxRate") T5 ON T0."DocEntry" = T5."DocEntry" AND T0."LineNum" = T5."LineNum" -- PIS
LEFT JOIN (SELECT DISTINCT "DocEntry","LineNum","TaxRate", SUM ("BaseSum") AS "BaseSum", SUM ("TaxSum") AS "TaxSum" FROM PCH4 WHERE "staType" IN(21,22) GROUP BY "DocEntry","LineNum","TaxRate") T6 ON T0."DocEntry" = T6."DocEntry" AND T0."LineNum" = T6."LineNum" -- COFINS
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE "WTTypeId" = 8 GROUP BY "AbsEntry","Doc1LineNo","Rate") T7 ON T0."DocEntry" = T7."AbsEntry" AND T0."LineNum" = T7."Doc1LineNo" --ISS
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE "WTTypeId" = 5 GROUP BY "AbsEntry","Doc1LineNo","Rate") T8 ON T0."DocEntry" = T8."AbsEntry" AND T0."LineNum" = T8."Doc1LineNo" --INSS
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE "WTTypeId" = 3 GROUP BY "AbsEntry","Doc1LineNo","Rate") T9 ON T0."DocEntry" = T9."AbsEntry" AND T0."LineNum" = T9."Doc1LineNo" --IRRF
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE (("WTTypeId" = 4) or ("WTTypeId" = 7 and "WTCode"='E003')) AND "Category" = 'P' GROUP BY "AbsEntry","Doc1LineNo","Rate") T12 ON T0."DocEntry" = T12."AbsEntry" AND T0."LineNum" = T12."Doc1LineNo" --CSLL
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE (("WTTypeId" = 1) or  ("WTTypeId" = 7 and "WTCode"='E001')) AND "Category" = 'P' GROUP BY "AbsEntry","Doc1LineNo","Rate") T10 ON T0."DocEntry" = T10."AbsEntry" AND T0."LineNum" = T10."Doc1LineNo" --PIS
LEFT JOIN (SELECT DISTINCT "AbsEntry","Doc1LineNo","Rate", SUM ("TaxbleAmnt") AS "TaxbleAmnt", SUM ("WTAmnt") AS "WTAmnt" FROM PCH5 WHERE (("WTTypeId" = 2) or ("WTTypeId" = 7 and "WTCode"='E002'))  AND "Category" = 'P' GROUP BY "AbsEntry","Doc1LineNo","Rate") T11 ON T0."DocEntry" = T11."AbsEntry" AND T0."LineNum" = T11."Doc1LineNo" --COFINS
LEFT JOIN ONFM T13 ON T1."Model" = T13."AbsEntry"

WHERE 
T1."CANCELED" = 'N'
--AND T1."Model" NOT IN (39,45,56) 
AND (T20."TrsfrDate"  >=[%0])  
AND (T20."TrsfrDate" <=[%1])
*/

-- NOVA CONSULTA - SAP B1

/* SELECT FROM "OVPM" P0
   WHERE P0."TrsfrDate" >= [%0]
     AND P0."TrsfrDate" <= [%1] */

SELECT
    T1."DocEntry",
    T1."DocNum" AS "Nº Primário",

    -- CENTRO DE CUSTO
    T30."COD_CENTROS" AS "Código Centro de Custo",
    T30."NOMES_CENTROS" AS "Centro de Custo",

    T1."DocDate" AS "Data de Lançamento",
    T1."TaxDate" AS "Data de Emissão",
    T1."DocDueDate" AS "Data de Vencimento NF",
    T20."TrsfrDate" AS "Data de Pagamento",

    T20."DocEntry" AS "Código Pagamento",
    T21."SumApplied" AS "Valor Pago",
    T1."DocTotal" AS "Valor Total NF",

    T1."Serial" AS "Nº NF",
    T13."NfmName" AS "Modelo",

    T1."CardCode" AS "Código Fornecedor",
    T1."CardName" AS "Fornecedor",
    T2."U_SPS_CNPJ" AS "CNPJ",
    T3."UF",

    -- CONDIÇÃO DE PAGAMENTO
    T1."GroupNum" AS "Código Condição Pagamento",
    T31."PymntGroup" AS "Condição de Pagamento",

    -- ISS
    IFNULL(T4."BC_ISS", 0) AS "Val. BC ISS",
    IFNULL(T4."ALIQ_ISS", 0) AS "Aliq. ISS",
    IFNULL(T4."VAL_ISS", 0) AS "Val. ISS",

    -- PIS
    IFNULL(T4."BC_PIS", 0) AS "Val. BC PIS",
    IFNULL(T4."ALIQ_PIS", 0) AS "Aliq. PIS",
    IFNULL(T4."VAL_PIS", 0) AS "Val. PIS",

    -- COFINS
    IFNULL(T4."BC_COFINS", 0) AS "Val. BC COFINS",
    IFNULL(T4."ALIQ_COFINS", 0) AS "Aliq. COFINS",
    IFNULL(T4."VAL_COFINS", 0) AS "Val. COFINS",

    -- ISS RETIDO
    IFNULL(T5."BC_ISS_RET", 0) AS "Val. BC ISS Retido",
    IFNULL(T5."ALIQ_ISS_RET", 0) AS "Aliq. ISS Retido",
    IFNULL(T5."VAL_ISS_RET", 0) AS "Val. ISS Retido",

    -- INSS RETIDO
    IFNULL(T5."BC_INSS_RET", 0) AS "Val. BC INSS Retido",
    IFNULL(T5."ALIQ_INSS_RET", 0) AS "Aliq. INSS Retido",
    IFNULL(T5."VAL_INSS_RET", 0) AS "Val. INSS Retido",

    -- IRRF RETIDO
    IFNULL(T5."BC_IRRF_RET", 0) AS "Val. BC IRRF Retido",
    IFNULL(T5."ALIQ_IRRF_RET", 0) AS "Aliq. IRRF Retido",
    IFNULL(T5."VAL_IRRF_RET", 0) AS "Val. IRRF Retido",

    -- PIS RETIDO
    IFNULL(T5."BC_PIS_RET", 0) AS "Val. BC PIS Retido",
    IFNULL(T5."ALIQ_PIS_RET", 0) AS "Aliq. PIS Retido",
    IFNULL(T5."VAL_PIS_RET", 0) AS "Val. PIS Retido",

    -- COFINS RETIDO
    IFNULL(T5."BC_COFINS_RET", 0) AS "Val. BC COFINS Retido",
    IFNULL(T5."ALIQ_COFINS_RET", 0) AS "Aliq. COFINS Retido",
    IFNULL(T5."VAL_COFINS_RET", 0) AS "Val. COFINS Retido",

    -- CSLL RETIDO
    IFNULL(T5."BC_CSLL_RET", 0) AS "Val. BC CSLL Retido",
    IFNULL(T5."ALIQ_CSLL_RET", 0) AS "Aliq. CSLL Retido",
    IFNULL(T5."VAL_CSLL_RET", 0) AS "Val. CSLL Retido"

FROM "OPCH" T1

-- PAGAMENTOS EFETUADOS
INNER JOIN "VPM2" T21
    ON T21."DocEntry" = T1."DocEntry"
   AND T21."InvType" = 18

INNER JOIN "OVPM" T20
    ON T20."DocEntry" = T21."DocNum"
   AND T20."Canceled" = 'N'

-- FORNECEDOR
INNER JOIN "OCRD" T2
    ON T1."CardCode" = T2."CardCode"

-- UF DA NOTA
LEFT JOIN (
    SELECT
        "DocEntry",
        MAX("StateS") AS "UF"
    FROM "PCH12"
    GROUP BY "DocEntry"
) T3
    ON T1."DocEntry" = T3."DocEntry"

-- IMPOSTOS CONSOLIDADOS POR NOTA
LEFT JOIN (
    SELECT
        "DocEntry",

        SUM(CASE WHEN "staType" = 24
            THEN "BaseSum" ELSE 0 END) AS "BC_ISS",
        MAX(CASE WHEN "staType" = 24
            THEN "TaxRate" END) AS "ALIQ_ISS",
        SUM(CASE WHEN "staType" = 24
            THEN "TaxSum" ELSE 0 END) AS "VAL_ISS",

        SUM(CASE WHEN "staType" IN (19, 20)
            THEN "BaseSum" ELSE 0 END) AS "BC_PIS",
        MAX(CASE WHEN "staType" IN (19, 20)
            THEN "TaxRate" END) AS "ALIQ_PIS",
        SUM(CASE WHEN "staType" IN (19, 20)
            THEN "TaxSum" ELSE 0 END) AS "VAL_PIS",

        SUM(CASE WHEN "staType" IN (21, 22)
            THEN "BaseSum" ELSE 0 END) AS "BC_COFINS",
        MAX(CASE WHEN "staType" IN (21, 22)
            THEN "TaxRate" END) AS "ALIQ_COFINS",
        SUM(CASE WHEN "staType" IN (21, 22)
            THEN "TaxSum" ELSE 0 END) AS "VAL_COFINS"

    FROM "PCH4"
    GROUP BY "DocEntry"
) T4
    ON T1."DocEntry" = T4."DocEntry"

-- RETENÇÕES CONSOLIDADAS POR NOTA
LEFT JOIN (
    SELECT
        "AbsEntry",

        SUM(CASE WHEN "WTTypeId" = 8
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_ISS_RET",
        MAX(CASE WHEN "WTTypeId" = 8
            THEN "Rate" END) AS "ALIQ_ISS_RET",
        SUM(CASE WHEN "WTTypeId" = 8
            THEN "WTAmnt" ELSE 0 END) AS "VAL_ISS_RET",

        SUM(CASE WHEN "WTTypeId" = 5
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_INSS_RET",
        MAX(CASE WHEN "WTTypeId" = 5
            THEN "Rate" END) AS "ALIQ_INSS_RET",
        SUM(CASE WHEN "WTTypeId" = 5
            THEN "WTAmnt" ELSE 0 END) AS "VAL_INSS_RET",

        SUM(CASE WHEN "WTTypeId" = 3
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_IRRF_RET",
        MAX(CASE WHEN "WTTypeId" = 3
            THEN "Rate" END) AS "ALIQ_IRRF_RET",
        SUM(CASE WHEN "WTTypeId" = 3
            THEN "WTAmnt" ELSE 0 END) AS "VAL_IRRF_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_PIS_RET",

        MAX(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_PIS_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 1 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E001'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_PIS_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_COFINS_RET",

        MAX(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_COFINS_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 2 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E002'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_COFINS_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "TaxbleAmnt" ELSE 0 END) AS "BC_CSLL_RET",

        MAX(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "Rate" END) AS "ALIQ_CSLL_RET",

        SUM(CASE WHEN
            ("WTTypeId" = 4 OR
             ("WTTypeId" = 7 AND "WTCode" = 'E003'))
            AND "Category" = 'P'
            THEN "WTAmnt" ELSE 0 END) AS "VAL_CSLL_RET"

    FROM "PCH5"
    GROUP BY "AbsEntry"
) T5
    ON T1."DocEntry" = T5."AbsEntry"

-- MODELO DE NOTA FISCAL
LEFT JOIN "ONFM" T13
    ON T1."Model" = T13."AbsEntry"

-- CENTROS DE CUSTO SEM DUPLICAÇÃO
LEFT JOIN (
    SELECT
        X."DocEntry",
        STRING_AGG(
            X."OcrCode", ', '
        ) AS "COD_CENTROS",
        STRING_AGG(
            IFNULL(X."PrcName", X."OcrCode"), ', '
        ) AS "NOMES_CENTROS"

    FROM (
        SELECT DISTINCT
            P."DocEntry",
            P."OcrCode",
            C."PrcName"
        FROM "PCH1" P
        LEFT JOIN "OPRC" C
            ON P."OcrCode" = C."PrcCode"
        WHERE P."OcrCode" IS NOT NULL
          AND P."OcrCode" <> ''
    ) X

    GROUP BY X."DocEntry"
) T30
    ON T1."DocEntry" = T30."DocEntry"

-- CONDIÇÃO DE PAGAMENTO
LEFT JOIN "OCTG" T31
    ON T1."GroupNum" = T31."GroupNum"

WHERE
    T1."CANCELED" = 'N'

    -- PARÂMETROS DE DATA DO SAP B1
    AND T20."TrsfrDate" >= [%0]
    AND T20."TrsfrDate" <= [%1]

ORDER BY
    T20."TrsfrDate",
    T1."DocNum",
    T20."DocEntry"
