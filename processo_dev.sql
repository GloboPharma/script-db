/*
==============================================================================
ORDEM DE SERVIÇO: 20637
VIEW SAP HANA: VW_PROC_DEVOLUCAO
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 20/10/2026
OBJETIVO: Monitoramento do Processo de Devolução - Rastreamento ponta a ponta (Esboço -> Pedido -> Devolução -> NF Devolução), lead time, dias parado, próxima ação e auditoria de fluxo
AMBIENTE: SAP Business One (SAP HANA)
==============================================================================
*/

CREATE OR REPLACE VIEW "SBOGPHARMA"."VW_PROC_DEVOLUCAO" AS

/* 1) PEDIDO DE DEVOLUÇÃO EM ESBOÇO */
SELECT
    'Pedido de Devolução' AS "Etapa Atual do Fluxo",
    'Em andamento' AS "Situação do Processo",
    IFNULL(U0."Usage", '(Sem utilização)') AS "Utilização",
    'Esboço' AS "Status da Etapa",
    DAYS_BETWEEN(O0."DocDate", CURRENT_DATE) AS "Dias Parado",
    CAST(NULL AS INTEGER) AS "Lead Time Total (dias)",
    'Aguardando Aprovação do pedido (Fiscal)' AS "Próxima Ação",
    'Não' AS "Próximo Documento Gerado?",
    O0."DocNum" AS "Nº Esboço",
    CAST(NULL AS INTEGER) AS "Nº Pedido Devolução",
    O0."DocDate" AS "Data Pedido Devolução",
    CAST(NULL AS INTEGER) AS "Nº Devolução",
    CAST(NULL AS DATE) AS "Data Devolução",
    CAST(NULL AS INTEGER) AS "Nº Doc. NF Devolução",
    CAST(NULL AS DATE) AS "Data NF Devolução",
    O0."Comments" AS "Observação",
    L0."U_SPS_NFOrigem" AS "Nº NF Origem",
    CAST(NULL AS NVARCHAR(100)) AS "Nº NF Devolução",
    O0."CardCode" AS "Cliente",
    O0."CardName" AS "Nome do Cliente",
    L0."ItemCode" AS "Item",
    L0."Dscription" AS "Descrição do Item",
    L0."Quantity" AS "Qtd Documento",
    L0."OpenQty" AS "Qtd Em Aberto",
    L0."Price" AS "Preço Unitário",
    L0."LineTotal" AS "Valor Total",
    'Pedido de devolução ainda em esboço' AS "Observação Auditoria"
FROM "ODRF" O0
INNER JOIN "DRF1" L0 ON O0."DocEntry" = L0."DocEntry"
LEFT JOIN "OUSG" U0 ON U0."ID" = L0."Usage"
WHERE
    O0."ObjType" = 234000031
    AND IFNULL(O0."CANCELED", 'N') = 'N'
    AND O0."DocStatus" = 'O'
    AND O0."DocDate" >= TO_DATE('2024-01-01', 'YYYY-MM-DD')

UNION ALL

/* 2) PEDIDO DE DEVOLUÇÃO GERADO E ABERTO (PARADO NA EXPEDIÇÃO) */
SELECT
    'Pedido de Devolução' AS "Etapa Atual do Fluxo",
    'Em andamento' AS "Situação do Processo",
    IFNULL(U."Usage", '(Sem utilização)') AS "Utilização",
    CASE
        WHEN O."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN O."DocStatus" = 'O' THEN 'Aberto'
        WHEN O."DocStatus" = 'C' THEN 'Fechado'
        ELSE O."DocStatus"
    END AS "Status da Etapa",
    DAYS_BETWEEN(O."DocDate", CURRENT_DATE) AS "Dias Parado",
    CAST(NULL AS INTEGER) AS "Lead Time Total (dias)",
    'Gerar Documento de Devolução (Expedição)' AS "Próxima Ação",
    'Não' AS "Próximo Documento Gerado?",
    CAST(NULL AS INTEGER) AS "Nº Esboço",
    O."DocNum" AS "Nº Pedido Devolução",
    O."DocDate" AS "Data Pedido Devolução",
    CAST(NULL AS INTEGER) AS "Nº Devolução",
    CAST(NULL AS DATE) AS "Data Devolução",
    CAST(NULL AS INTEGER) AS "Nº Doc. NF Devolução",
    CAST(NULL AS DATE) AS "Data NF Devolução",
    O."Comments" AS "Observação",
    L."U_SPS_NFOrigem" AS "Nº NF Origem",
    CAST(NULL AS NVARCHAR(100)) AS "Nº NF Devolução",
    O."CardCode" AS "Cliente",
    O."CardName" AS "Nome do Cliente",
    L."ItemCode" AS "Item",
    L."Dscription" AS "Descrição do Item",
    L."Quantity" AS "Qtd Documento",
    L."OpenQty" AS "Qtd Em Aberto",
    L."Price" AS "Preço Unitário",
    L."LineTotal" AS "Valor Total",
    'Parado no pedido de devolução' AS "Observação Auditoria"
FROM "ORRR" O
INNER JOIN "RRR1" L ON O."DocEntry" = L."DocEntry"
LEFT JOIN "OUSG" U ON U."ID" = L."Usage"
LEFT JOIN "RDN1" DL
    ON DL."BaseEntry" = L."DocEntry"
   AND DL."BaseLine" = L."LineNum"
   AND DL."BaseType" = O."ObjType"
WHERE
    O."CANCELED" = 'N'
    AND O."DocStatus" = 'O'
    AND L."LineStatus" = 'O'
    AND DL."DocEntry" IS NULL
    AND O."DocDate" >= TO_DATE('2024-01-01', 'YYYY-MM-DD')

UNION ALL

/* 3) DOCUMENTO DE DEVOLUÇÃO GERADO (PARADO NO FISCAL) */
SELECT
    'Documento de Devolução' AS "Etapa Atual do Fluxo",
    'Em andamento' AS "Situação do Processo",
    IFNULL(U2."Usage", '(Sem utilização)') AS "Utilização",
    CASE
        WHEN D."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN D."DocStatus" = 'O' THEN 'Aberto'
        WHEN D."DocStatus" = 'C' THEN 'Fechado'
        ELSE D."DocStatus"
    END AS "Status da Etapa",
    DAYS_BETWEEN(D."DocDate", CURRENT_DATE) AS "Dias Parado",
    CAST(NULL AS INTEGER) AS "Lead Time Total (dias)",
    'Gerar NF de Devolução (Fiscal)' AS "Próxima Ação",
    'Não' AS "Próximo Documento Gerado?",
    CAST(NULL AS INTEGER) AS "Nº Esboço",
    O."DocNum" AS "Nº Pedido Devolução",
    O."DocDate" AS "Data Pedido Devolução",
    D."DocNum" AS "Nº Devolução",
    D."DocDate" AS "Data Devolução",
    CAST(NULL AS INTEGER) AS "Nº Doc. NF Devolução",
    CAST(NULL AS DATE) AS "Data NF Devolução",
    O."Comments" AS "Observação",
    L."U_SPS_NFOrigem" AS "Nº NF Origem",
    TO_NVARCHAR(D."Serial") AS "Nº NF Devolução",
    D."CardCode" AS "Cliente",
    D."CardName" AS "Nome do Cliente",
    DL."ItemCode" AS "Item",
    DL."Dscription" AS "Descrição do Item",
    DL."Quantity" AS "Qtd Documento",
    DL."OpenQty" AS "Qtd Em Aberto",
    DL."Price" AS "Preço Unitário",
    DL."LineTotal" AS "Valor Total",
    'Parado na devolução' AS "Observação Auditoria"
FROM "ORRR" O
INNER JOIN "RRR1" L ON O."DocEntry" = L."DocEntry"
INNER JOIN "RDN1" DL
    ON DL."BaseEntry" = L."DocEntry"
   AND DL."BaseLine" = L."LineNum"
   AND DL."BaseType" = O."ObjType"
INNER JOIN "ORDN" D ON D."DocEntry" = DL."DocEntry"
LEFT JOIN "OUSG" U2 ON U2."ID" = DL."Usage"
LEFT JOIN "RIN1" CML
    ON CML."BaseEntry" = DL."DocEntry"
   AND CML."BaseLine" = DL."LineNum"
   AND CML."BaseType" = DL."ObjType"
WHERE
    O."CANCELED" = 'N'
    AND D."CANCELED" = 'N'
    AND D."DocStatus" = 'O'
    AND CML."DocEntry" IS NULL
    AND O."DocDate" >= TO_DATE('2024-01-01', 'YYYY-MM-DD')

UNION ALL

/* 4) NF DE DEVOLUÇÃO GERADA (EM ANDAMENTO OU CONCLUÍDA) */
SELECT
    'NF de Devolução' AS "Etapa Atual do Fluxo",
    CASE
        WHEN CM."DocStatus" = 'C' THEN 'Concluído'
        ELSE 'Em andamento'
    END AS "Situação do Processo",
    IFNULL(U3."Usage", '(Sem utilização)') AS "Utilização",
    CASE
        WHEN CM."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN CM."DocStatus" = 'O' THEN 'Aberto'
        WHEN CM."DocStatus" = 'C' THEN 'Fechado'
        ELSE CM."DocStatus"
    END AS "Status da Etapa",
    CASE
        WHEN CM."DocStatus" = 'C' THEN 0
        ELSE DAYS_BETWEEN(CM."DocDate", CURRENT_DATE)
    END AS "Dias Parado",
    CASE
        WHEN CM."DocStatus" = 'C'
        THEN DAYS_BETWEEN(O."DocDate", CM."DocDate")
        ELSE CAST(NULL AS INTEGER)
    END AS "Lead Time Total (dias)",
    CASE
        WHEN CM."DocStatus" = 'C' THEN 'Nenhuma - processo encerrado'
        ELSE 'Aguardando Baixa Financeiro'
    END AS "Próxima Ação",
    '-' AS "Próximo Documento Gerado?",
    CAST(NULL AS INTEGER) AS "Nº Esboço",
    O."DocNum" AS "Nº Pedido Devolução",
    O."DocDate" AS "Data Pedido Devolução",
    D."DocNum" AS "Nº Devolução",
    D."DocDate" AS "Data Devolução",
    CM."DocNum" AS "Nº Doc. NF Devolução",
    CM."DocDate" AS "Data NF Devolução",
    O."Comments" AS "Observação",
    L."U_SPS_NFOrigem" AS "Nº NF Origem",
    TO_NVARCHAR(D."Serial") AS "Nº NF Devolução",
    CM."CardCode" AS "Cliente",
    CM."CardName" AS "Nome do Cliente",
    CML."ItemCode" AS "Item",
    CML."Dscription" AS "Descrição do Item",
    CML."Quantity" AS "Qtd Documento",
    CML."OpenQty" AS "Qtd Em Aberto",
    CML."Price" AS "Preço Unitário",
    CML."LineTotal" AS "Valor Total",
    CASE
        WHEN CM."DocStatus" = 'C'
        THEN 'Processo concluído - NF de devolução encerrada'
        ELSE 'NF gerada, aguardando encerramento financeiro'
    END AS "Observação Auditoria"
FROM "ORRR" O
INNER JOIN "RRR1" L ON O."DocEntry" = L."DocEntry"
INNER JOIN "RDN1" DL
    ON DL."BaseEntry" = L."DocEntry"
   AND DL."BaseLine" = L."LineNum"
   AND DL."BaseType" = O."ObjType"
INNER JOIN "ORDN" D ON D."DocEntry" = DL."DocEntry"
INNER JOIN "RIN1" CML
    ON CML."BaseEntry" = DL."DocEntry"
   AND CML."BaseLine" = DL."LineNum"
   AND CML."BaseType" = DL."ObjType"
INNER JOIN "ORIN" CM ON CM."DocEntry" = CML."DocEntry"
LEFT JOIN "OUSG" U3 ON U3."ID" = CML."Usage"
WHERE
    O."CANCELED" = 'N'
    AND D."CANCELED" = 'N'
    AND CM."CANCELED" = 'N'
    AND O."DocDate" >= TO_DATE('2024-01-01', 'YYYY-MM-DD')

UNION ALL

/* 5) PEDIDO ENCERRADO SEM DEVOLUÇÃO (CANCELADO/FECHADO) */
SELECT
    'Pedido de Devolução' AS "Etapa Atual do Fluxo",
    'Encerrado sem devolução' AS "Situação do Processo",
    IFNULL(U4."Usage", '(Sem utilização)') AS "Utilização",
    CASE
        WHEN O."CANCELED" = 'Y' THEN 'Cancelado'
        WHEN O."DocStatus" = 'C' THEN 'Fechado'
        ELSE O."DocStatus"
    END AS "Status da Etapa",
    0 AS "Dias Parado",
    CAST(NULL AS INTEGER) AS "Lead Time Total (dias)",
    'Verificar motivo do encerramento sem devolução' AS "Próxima Ação",
    'Não' AS "Próximo Documento Gerado?",
    CAST(NULL AS INTEGER) AS "Nº Esboço",
    O."DocNum" AS "Nº Pedido Devolução",
    O."DocDate" AS "Data Pedido Devolução",
    CAST(NULL AS INTEGER) AS "Nº Devolução",
    CAST(NULL AS DATE) AS "Data Devolução",
    CAST(NULL AS INTEGER) AS "Nº Doc. NF Devolução",
    CAST(NULL AS DATE) AS "Data NF Devolução",
    O."Comments" AS "Observação",
    L."U_SPS_NFOrigem" AS "Nº NF Origem",
    CAST(NULL AS NVARCHAR(100)) AS "Nº NF Devolução",
    O."CardCode" AS "Cliente",
    O."CardName" AS "Nome do Cliente",
    L."ItemCode" AS "Item",
    L."Dscription" AS "Descrição do Item",
    L."Quantity" AS "Qtd Documento",
    L."OpenQty" AS "Qtd Em Aberto",
    L."Price" AS "Preço Unitário",
    L."LineTotal" AS "Valor Total",
    'Pedido encerrado sem geração de devolução' AS "Observação Auditoria"
FROM "ORRR" O
INNER JOIN "RRR1" L ON O."DocEntry" = L."DocEntry"
LEFT JOIN "OUSG" U4 ON U4."ID" = L."Usage"
LEFT JOIN "RDN1" DL
    ON DL."BaseEntry" = L."DocEntry"
   AND DL."BaseLine" = L."LineNum"
   AND DL."BaseType" = O."ObjType"
WHERE
    DL."DocEntry" IS NULL
    AND (O."CANCELED" = 'Y' OR O."DocStatus" = 'C' OR L."LineStatus" = 'C')
    AND O."DocDate" >= TO_DATE('2024-01-01', 'YYYY-MM-DD');

-- ==============================================================================
-- EXEMPLO DE CONSULTA COM A ORDENAÇÃO ORIGINAL:
-- ==============================================================================
-- SELECT * 
-- FROM "SBOGPHARMA"."VW_PROC_DEVOLUCAO"
-- ORDER BY
--     "Situação do Processo",
--     "Data Pedido Devolução",
--     "Nº Esboço",
--     "Nº Pedido Devolução",
--     "Nº Devolução",
--     "Nº Doc. NF Devolução",
--     "Item";