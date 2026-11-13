/*
===============================================================================
ORDEM DE SERVIÇO: 21113
NOME DO RELATÓRIO: Relatório de Lotes Excluídos (OPs Beas excluídas)
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 13/11/2026
OBJETIVO: Identificar Ordens de Produção do Beas que possuem apontamentos no SAP (Entrada de Mercadorias OIGN/IGN1 e
          Saída de Mercadorias OIGE/IGE1 via U_beas_belnrid), mas não existem mais na BEAS_FTPOS, listando o acabado,
          o lote, as etapas de granel (Manipulação, Compressão, Revestimento, Encapsulamento) e a situação do acabado.
          Layout de colunas alinhado ao relatório de OPs para permitir consolidação.
AMBIENTE: SAP Business One (SAP HANA) - Gerenciador de Consultas
OBSERVAÇÃO: Como a OP não existe mais, as colunas de planejamento/rendimento/custo/versão retornam NULL e a "Data Criação"
            corresponde ao primeiro apontamento no SAP. Considera apenas OPs cujo acabado não foi produzido
            (sem apontamento ou quantidade líquida <= 0). Acabado = grupo 102 ou U_SPS_GRP_N2 = 'IT'; granel = grupo 133.
===============================================================================
*/

SELECT
    X."OP",
    AC."ItemCode",
    I."ItemName",
    COALESCE(AC."Lote", GR."Lote")                    AS "Lote",
    /* Dados do granel, por etapa */
    GR."Etapa"                                        AS "Etapa Granel",
    GR."ItemCode"                                     AS "SKU Granel",
    GR."ItemName"                                     AS "Descrição Granel",
    GR."Lote"                                         AS "Lote Granel",
    NULL                                              AS "Qtd Planejada",
    IFNULL(AC."Qtd Produzida", 0)                     AS "Qtd Produzida",
    NULL                                              AS "Qtd Planejada Granel",
    IFNULL(GR."Qtd Produzida", 0)                     AS "Qtd Produzida Granel",
    NULL                                              AS "% Rendimento Granel",
    NULL                                              AS "% Rendimento Acabado",
    'Excluída'                                        AS "Status",
    CASE
        WHEN AC."ItemCode" IS NULL      THEN 'Sem apontamento do acabado'
        WHEN AC."Qtd Entrada" > 0       THEN 'Produção do acabado estornada'
        ELSE                                 'Acabado só com saídas'
    END                                               AS "Situação",
    NULL                                              AS "Data Conclusão",
    NULL                                              AS "Data Início Plan",
    NULL                                              AS "Data Fim Plan",
    /* Sem a OP, "criação" = primeiro apontamento no SAP */
    TO_DATE(LEFT(X."PrimKey", 10))                    AS "Data Criação",
    SUBSTRING(X."PrimKey", 11, 2) || ':' || SUBSTRING(X."PrimKey", 13, 2)
                                                      AS "Hora Criação",
    NULL                                              AS "Data Impressão",
    NULL                                              AS "Hora Impressão",
    LEFT(X."PrimKey", 10) || ' ' || SUBSTRING(X."PrimKey", 11, 2) || ':' || SUBSTRING(X."PrimKey", 13, 2)
                                                      AS "Data/Hora Criação",
    NULL                                              AS "Data/Hora Impressão",
    NULL                                              AS "Custo do Material",
    NULL                                              AS "Versão",
    NULL                                              AS "Variante",
    /* Colunas extras para auditoria */
    TO_DATE(LEFT(X."UltKey", 10))                     AS "Último Apontamento",
    X."Documentos"                                    AS "Documentos (E=Entrada 59 / S=Saída 60)"
FROM (
    /* ---- OPs excluídas: apontadas no SAP e ausentes na BEAS_FTPOS ---- */
    SELECT D."OP",
           MIN(D."Chave") AS "PrimKey",
           MAX(D."Chave") AS "UltKey",
           STRING_AGG(D."Tipo" || TO_NVARCHAR(D."DocNum"), ', ' ORDER BY D."Chave") AS "Documentos"
      FROM (
            SELECT DISTINCT G."U_beas_belnrid" AS "OP", 'E' AS "Tipo", H."DocNum",
                   TO_NVARCHAR(H."CreateDate", 'YYYY-MM-DD') || LPAD(TO_NVARCHAR(H."DocTime"), 4, '0') AS "Chave"
              FROM "IGN1" G
             INNER JOIN "OIGN" H ON H."DocEntry" = G."DocEntry"
             WHERE G."U_beas_belnrid" IS NOT NULL
            UNION
            SELECT DISTINCT G."U_beas_belnrid", 'S', H."DocNum",
                   TO_NVARCHAR(H."CreateDate", 'YYYY-MM-DD') || LPAD(TO_NVARCHAR(H."DocTime"), 4, '0')
              FROM "IGE1" G
             INNER JOIN "OIGE" H ON H."DocEntry" = G."DocEntry"
             WHERE G."U_beas_belnrid" IS NOT NULL
           ) D
     WHERE NOT EXISTS (SELECT 1 FROM "BEAS_FTPOS" F WHERE F."BELNR_ID" = D."OP")
     GROUP BY D."OP"
) X
LEFT JOIN (
    /* ---- Acabado da OP (grupo 102 ou U_SPS_GRP_N2 = 'IT') ---- */
    SELECT M."OP", M."ItemCode",
           SUM(CASE WHEN M."Mov" = 'ENT' THEN M."Qtd" ELSE 0 END)                                   AS "Qtd Entrada",
           SUM(CASE WHEN M."Mov" = 'ENT' THEN M."Qtd" WHEN M."Mov" = 'SAI' THEN -M."Qtd" ELSE 0 END) AS "Qtd Produzida",
           MAX(M."Lote")                                                                            AS "Lote"
      FROM (
            SELECT G."U_beas_belnrid" AS "OP", G."ItemCode",
                   CASE WHEN IFNULL(G."U_beas_basetype", 'X') = 'E' THEN 'EST' ELSE 'ENT' END AS "Mov",
                   G."Quantity" AS "Qtd",
                   L."BatchNum" AS "Lote"
              FROM "IGN1" G
              LEFT JOIN "IBT1" L ON L."BaseType" = 59
                                AND L."BaseEntry" = G."DocEntry"
                                AND L."BaseLinNum" = G."LineNum"
                                AND L."ItemCode" = G."ItemCode"
             WHERE G."U_beas_belnrid" IS NOT NULL
            UNION ALL
            SELECT G."U_beas_belnrid", G."ItemCode", 'SAI', G."Quantity", NULL
              FROM "IGE1" G
             WHERE G."U_beas_belnrid" IS NOT NULL
           ) M
     INNER JOIN "OITM" B ON B."ItemCode" = M."ItemCode"
     WHERE B."ItmsGrpCod" = 102 OR B."U_SPS_GRP_N2" IN ('IT')
     GROUP BY M."OP", M."ItemCode"
) AC ON AC."OP" = X."OP"
LEFT JOIN "OITM" I ON I."ItemCode" = AC."ItemCode"
LEFT JOIN (
    /* ---- Uma linha por etapa de granel apontada na OP ---- */
    SELECT Q."BELNR_ID", Q."ItemCode", B."ItemName",
           CASE LEFT(Q."ItemCode", 2)
               WHEN 'PM' THEN 'Manipulação'
               WHEN 'PC' THEN 'Compressão'
               WHEN 'PR' THEN 'Revestimento'
               WHEN 'PE' THEN 'Encapsulamento'
           END AS "Etapa",
           LT."Lote",
           Q."Qtd Produzida"
      FROM (
            SELECT G."U_beas_belnrid" AS "BELNR_ID", G."ItemCode", SUM(G."Quantity") AS "Qtd Produzida"
              FROM "IGN1" G
             WHERE LEFT(G."ItemCode", 2) IN ('PR', 'PC', 'PE', 'PM')
               AND IFNULL(G."U_beas_basetype", 'X') NOT IN ('E')
               AND G."U_beas_belnrid" IS NOT NULL
             GROUP BY G."U_beas_belnrid", G."ItemCode"
           ) Q
     INNER JOIN "OITM" B ON B."ItemCode" = Q."ItemCode" AND B."ItmsGrpCod" = 133
      LEFT JOIN (
            SELECT G."U_beas_belnrid" AS "BELNR_ID", G."ItemCode", MAX(L."BatchNum") AS "Lote"
              FROM "IGN1" G
             INNER JOIN "IBT1" L ON L."BaseType" = 59
                                AND L."BaseEntry" = G."DocEntry"
                                AND L."BaseLinNum" = G."LineNum"
                                AND L."ItemCode" = G."ItemCode"
             WHERE LEFT(G."ItemCode", 2) IN ('PR', 'PC', 'PE', 'PM')
               AND IFNULL(G."U_beas_basetype", 'X') NOT IN ('E')
             GROUP BY G."U_beas_belnrid", G."ItemCode"
           ) LT ON LT."BELNR_ID" = Q."BELNR_ID" AND LT."ItemCode" = Q."ItemCode"
) GR ON GR."BELNR_ID" = X."OP"
/* Só OPs em que o acabado não foi produzido (sem apontamento ou líquido <= 0) */
WHERE IFNULL(AC."Qtd Produzida", 0) <= 0
ORDER BY X."UltKey" DESC, X."OP", GR."Etapa";
