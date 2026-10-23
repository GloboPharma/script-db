/*
===============================================================================
ORDEM DE SERVIÇO: 20726
NOME DO RELATÓRIO: Relatório de Mapeamento Comercial por Nota Fiscal
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 22/10/2026
OBJETIVO: Mapeamento comercial por Nota Fiscal de Saída atrelando o Parceiro de Negócios, Gerente de Contas/Vendedor e Gerente Regional/Canal, para integração e 
          plataforma de gestão de fretes. Consulta consolidada por Documento Fiscal.
AMBIENTE: SAP Business One (SAP HANA) - Gerenciador de Consultas
OBSERVAÇÃO: Sintaxe adaptada para o banco SAP HANA (aspas duplas para identificadores e parâmetros nativos [%0] e [%1]). Validar nome exato das UDFs de Regional/Canal no ambiente.
===============================================================================
*/


SELECT 
    T0."DocNum" AS "Num_Nota_Fiscal",
    T0."DocDate" AS "Data_Emissao",
    T0."CardCode" AS "Codigo_Cliente",
    T0."CardName" AS "Nome_Cliente",
    T1."SlpName" AS "Gerente_Contas_Vendedor",
    T3."Name" AS "Gerente Regional",
    T0."DocTotal" AS "Valor_Total_Nota"
FROM OINV T0
INNER JOIN OSLP T1 ON T0."SlpCode" = T1."SlpCode"
LEFT JOIN OCRD T2 ON T2."CardCode" = T0."CardCode"
LEFT JOIN "@GB_GER_CARTEIRA" T3 ON T3."Code" = T2."U_GB_GER_CARTEIRA"
WHERE T0."CANCELED" = 'N' 
  AND T0."DocDate" >= DATE '2026-10-01'
  AND T0."DocDate" <= DATE '2026-10-23';

-- NOVA CONSULTA

SELECT 
    T0."DocNum" AS "Num_Nota_Fiscal",
    T0."DocDate" AS "Data_Emissao",
    T0."CardCode" AS "Codigo_Cliente",
    T0."CardName" AS "Nome_Cliente",
    T1."SlpName" AS "Gerente_Contas_Vendedor",
    T3."Name" AS "Gerente_Regional",
    -- T0."U_Canal" AS "Canal_Vendas",         -- (Ajustar o nome exato da UDF de Canal)
    T0."DocTotal" AS "Valor_Total_Nota"
FROM OINV T0
INNER JOIN OSLP T1 ON T1."SlpCode" = T0."SlpCode"
INNER JOIN OCRD T2 ON T2."CardCode" = T0."CardCode"
LEFT JOIN "@GB_GER_CARTEIRA" T3 ON T3."Code" = T2."U_GB_GER_CARTEIRA"
WHERE T0."CANCELED" = 'N' 
  AND T0."DocDate" >= [%0] 
  AND T0."DocDate" <= [%1]



