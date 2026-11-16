/*
===============================================================================
ORDEM DE SERVIÇO: 21113
NOME DO RELATÓRIO: Relatório de Lotes Excluídos (OPs Beas excluídas)
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 16/11/2026
OBJETIVO: Identificar Ordens de Produção do Beas que possuem apontamentos no SAP (Entrada de Mercadorias OIGN/IGN1 e
          Saída de Mercadorias OIGE/IGE1 via U_beas_belnrid), mas não existem mais na BEAS_FTPOS, listando o acabado,
          o lote, as etapas de granel (Manipulação, Compressão, Revestimento, Encapsulamento) e a situação do acabado.
          Layout de colunas alinhado ao relatório de OPs para permitir consolidação.
AMBIENTE: SAP Business One (SAP HANA) - Gerenciador de Consultas
OBSERVAÇÃO: Como a OP não existe mais, as colunas de planejamento/rendimento/custo/versão retornam NULL e a "Data Criação"
            corresponde ao primeiro apontamento no SAP. Considera apenas OPs cujo acabado não foi produzido
            (sem apontamento ou quantidade líquida <= 0). Acabado = grupo 102 ou U_SPS_GRP_N2 = 'IT'; granel = grupo 133.
          Evidências de OP excluída:
          A) Número de lote pulado na sequência (OP excluída antes de qualquer
              apontamento - não deixa documento no SAP).
              Formato do lote: 4 car. produto + 3 dígitos seq + 2 dígitos ano
              (A92A|005|25). Lotes usados = OBTN + BEAS_FTPOS.CHARGE_ID (itens 'P%').
          B) Lote com apontamento (Entrada 59 / Saída 60) ligado a OP que não
              existe mais na BEAS_FTPOS. Hoje retorna vazio (o Beas não deixa
              excluir OP com apontamento); fica como controle.
              O Beas grava a OP negativa nos estornos: usa-se ABS(U_beas_belnrid).
   ===================================================================== */

/* ---------- A) Números de lote pulados ---------- */
SELECT
    P."Ano",
    P."Prefixo"                                                        AS "Produto (prefixo)",
    P."Prefixo" || LPAD(TO_NVARCHAR(P."Seq" + 1), 3, '0') || P."Ano"  AS "Primeiro lote faltando",
    P."Prefixo" || LPAD(TO_NVARCHAR(P."Prox" - 1), 3, '0') || P."Ano" AS "Último lote faltando",
    P."Prox" - P."Seq" - 1                                             AS "Qtd lotes",
    'Número de lote pulado (OP excluída sem apontamento)'              AS "Evidência",
    CAST(NULL AS INTEGER)                                              AS "OP",
    P."Lote"                                                           AS "Lote anterior",
    P."ProxLote"                                                       AS "Lote seguinte",
    (SELECT MIN(B1."InDate") FROM "OBTN" B1 WHERE B1."DistNumber" = P."Lote")     AS "Data inicial",
    (SELECT MIN(B2."InDate") FROM "OBTN" B2 WHERE B2."DistNumber" = P."ProxLote") AS "Data final",
    CAST(NULL AS NVARCHAR(5000))                                       AS "Documentos"
FROM (
    SELECT S."Lote", S."Prefixo", S."Ano", S."Seq",
           LEAD(S."Seq")  OVER (PARTITION BY S."Prefixo", S."Ano" ORDER BY S."Seq") AS "Prox",
           LEAD(S."Lote") OVER (PARTITION BY S."Prefixo", S."Ano" ORDER BY S."Seq") AS "ProxLote"
      FROM (
            SELECT DISTINCT
                   L."Lote",
                   LEFT(L."Lote", 4)                     AS "Prefixo",
                   RIGHT(L."Lote", 2)                    AS "Ano",
                   TO_INTEGER(SUBSTRING(L."Lote", 5, 3)) AS "Seq"
              FROM (
                    SELECT B."DistNumber" AS "Lote"
                      FROM "OBTN" B
                     WHERE B."ItemCode" LIKE 'P%'
                    UNION
                    SELECT F."CHARGE_ID"
                      FROM "BEAS_FTPOS" F
                     WHERE F."ItemCode" LIKE 'P%'
                       AND F."CHARGE_ID" IS NOT NULL
                   ) L
             WHERE L."Lote" LIKE_REGEXPR '^[A-Z][A-Z0-9]{3}[0-9]{5}$'
           ) S
) P
WHERE P."Prox" - P."Seq" > 1
UNION ALL
/* ---------- B) Lotes com apontamento em OP que não existe mais ---------- */
SELECT
    RIGHT(M."Lote", 2)                                  AS "Ano",
    LEFT(M."Lote", 4)                                   AS "Produto (prefixo)",
    M."Lote"                                            AS "Primeiro lote faltando",
    M."Lote"                                            AS "Último lote faltando",
    1                                                   AS "Qtd lotes",
    'Apontamento em OP excluída'                        AS "Evidência",
    M."OP",
    CAST(NULL AS NVARCHAR(36))                          AS "Lote anterior",
    CAST(NULL AS NVARCHAR(36))                          AS "Lote seguinte",
    MIN(M."DocDate")                                    AS "Data inicial",
    MAX(M."DocDate")                                    AS "Data final",
    STRING_AGG(M."Tipo" || TO_NVARCHAR(M."DocNum") || ' ' || M."ItemCode", ', ' ORDER BY M."DocDate")
                                                        AS "Documentos"
FROM (
    SELECT ABS(G."U_beas_belnrid") AS "OP", L."BatchNum" AS "Lote", G."ItemCode",
           'E' AS "Tipo", H."DocNum", H."DocDate"
      FROM "IBT1" L
     INNER JOIN "IGN1" G ON G."DocEntry" = L."BaseEntry" AND G."LineNum" = L."BaseLinNum" AND G."ItemCode" = L."ItemCode"
     INNER JOIN "OIGN" H ON H."DocEntry" = G."DocEntry"
     WHERE L."BaseType" = 59 AND G."U_beas_belnrid" IS NOT NULL
    UNION ALL
    SELECT ABS(G."U_beas_belnrid"), L."BatchNum", G."ItemCode",
           'S', H."DocNum", H."DocDate"
      FROM "IBT1" L
     INNER JOIN "IGE1" G ON G."DocEntry" = L."BaseEntry" AND G."LineNum" = L."BaseLinNum" AND G."ItemCode" = L."ItemCode"
     INNER JOIN "OIGE" H ON H."DocEntry" = G."DocEntry"
     WHERE L."BaseType" = 60 AND G."U_beas_belnrid" IS NOT NULL
) M
WHERE NOT EXISTS (SELECT 1 FROM "BEAS_FTPOS" F WHERE F."BELNR_ID" = M."OP")
GROUP BY M."OP", M."Lote"
ORDER BY 1 DESC, 2, 3;
