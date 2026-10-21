/*
===============================================================================
ORDEM DE SERVIÇO: 20691
AUTOR: Frederico Magalhães
DATA ALTEAÇÃO: 21/10/2026
OBJETIVO: Relatório de Notas Fiscais de Saída (Model = 39) com adição das colunas 'Canal' e 'Gerente Regional'.
AMBIENTE: SAP Business One (SAP HANA)
===============================================================================
*/

SELECT DISTINCT
    T0."DocEntry",
    T0."DocNum" AS "Nº Primário",
    T0."Serial" AS "Nº NF",
    T0."NumAtCard" AS "NF Ref. Parceiro",
    T0."DocDate" AS "Data de Emissão",
    T0."Comments",
    T0."NfeValue",
    T7."U_SPS_Canal" AS "Canal",
    CASE
        WHEN T0."U_SPS_Canal" = '0' THEN 'Indireto'
        WHEN T0."U_SPS_Canal" = '1' THEN 'Hospital'
        WHEN T0."U_SPS_Canal" = '2' THEN 'Parceiro'
        WHEN T0."U_SPS_Canal" = '3' THEN 'Direto'
        WHEN T0."U_SPS_Canal" = '4' THEN 'Governo'
        WHEN T0."U_SPS_Canal" = '5' THEN 'Outros'
    END AS "Canal",
    T8."Name" AS "Gerente Regional",
    T3."SlpName" AS "Vendedor",
    T0."CardCode" AS "Código do PN",
    T0."CardName" AS "Razão Social",
    T4."State" AS "UF",
    T4."City" AS "Cidade",
    T1."LineNum" AS "Nº da Linha", 
    T1."ItemCode" AS "Produto",
    T1."Dscription",
    T5."CodeBars" AS "EAN",
    T1."Quantity" AS "Qtde",
    T1."LineTotal" AS "Total por Produto",
    T2."Usage" AS "Utilização",
    T1."U_SPS_ListNum" AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão' 
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto' 
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional' 
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar' 
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro' 
    END AS "Lista de Preço",
    T1."U_SPS_PercTrademarketing" AS "Percentual Trade Marketing",
    T6."Carrier",
    T0."U_SPS_Transportadora",
    CASE 
        WHEN T1."Usage" = 12 AND (T0."U_SPS_BonificaoTrade" = 'Y' OR T0."U_SPS_BonificaoExtra" = 'Y') THEN 'Não' 
        WHEN T1."Usage" = 12 AND (IFNULL(T0."U_SPS_BonificaoTrade", 'N') = 'N' AND IFNULL(T0."U_SPS_BonificaoExtra", 'N') = 'N') THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Talão",
    CASE 
        WHEN T0."U_SPS_BonificaoExtra" = 'Y' THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Extra",
    CASE 
        WHEN T0."U_SPS_BonificaoTrade" = 'Y' THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Trade",
    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado' 
        ELSE 'Aberto' 
    END AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim' 
        ELSE 'Não' 
    END AS "Cancelado"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
LEFT JOIN OCRD T7 ON T0."CardCode" = T7."CardCode"
LEFT JOIN "@GB_GER_CARTEIRA" T8 ON T7."U_GB_GER_CARTEIRA" = T8."Code"
INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'S' AND T4."Address" = T0."ShipToCode"
LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
LEFT JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
WHERE T0."Model" = 39
ORDER BY T0."DocEntry", T1."LineNum";


--

/*
-- CONSULTA ANTIGA

SELECT DISTINCT
    T0."DocEntry",
    T0."DocNum" AS "Nº Primário",
    T0."NumAtCard" AS "NF Ref. Parceiro", -- <-- CAMPO ADICIONADO AQUI
    T1."LineNum" AS "Nº da Linha", 
    T3."SlpName" AS "Vendedor",
    T0."DocDate" AS "Data de Emissão",
    T0."Serial" AS "Nº NF",
    T0."CardCode" AS "Código do PN",
    T0."CardName" AS "Razão Social",
    T1."ItemCode" AS "Produto",
    T1."Dscription",
    T1."U_SPS_ListNum"  AS "Nro Lista Preço",
     CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão' 
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto' 
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional' 
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar' 
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro' 
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
    CASE 
        WHEN T1."Usage" = 12 AND (T0."U_SPS_BonificaoTrade" = 'Y' OR T0."U_SPS_BonificaoExtra" = 'Y') THEN 'Não' 
        WHEN T1."Usage" = 12 AND (IFNULL(T0."U_SPS_BonificaoTrade", 'N') = 'N' OR IFNULL(T0."U_SPS_BonificaoExtra", 'N') = 'N') THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Talão",
    CASE 
        WHEN T0."U_SPS_BonificaoExtra" = 'Y' THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Extra",
    CASE 
        WHEN T0."U_SPS_BonificaoTrade" = 'Y' THEN 'Sim' 
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
    T5."CodeBars" AS "EAN"
FROM 
    OINV T0
    INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
    INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
    LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'B'
    LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
    INNER JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"

WHERE 
    T0."Model" = 39
ORDER BY 
    T0."DocEntry",
    T1."LineNum";

*/


-- NOVA CONSULTA - SAP B1

SELECT DISTINCT
    T0."DocEntry",
    T0."DocNum" AS "Nº Primário",
    T0."Serial" AS "Nº NF",
    T0."NumAtCard" AS "NF Ref. Parceiro",
    T0."DocDate" AS "Data de Emissão",
    T0."Comments",
    T0."NfeValue",
    T7."U_SPS_Canal" AS "Cód. Canal",
    CASE
        WHEN T7."U_SPS_Canal" = '0' THEN 'Indireto'
        WHEN T7."U_SPS_Canal" = '1' THEN 'Hospital'
        WHEN T7."U_SPS_Canal" = '2' THEN 'Parceiro'
        WHEN T7."U_SPS_Canal" = '3' THEN 'Direto'
        WHEN T7."U_SPS_Canal" = '4' THEN 'Governo'
        WHEN T7."U_SPS_Canal" = '5' THEN 'Outros'
        ELSE 'Não Definido'
    END AS "Descrição Canal",
    T8."Name" AS "Gerente Regional",
    T3."SlpName" AS "Vendedor",
    T0."CardCode" AS "Código do PN",
    T0."CardName" AS "Razão Social",
    T4."State" AS "UF",
    T4."City" AS "Cidade",
    T1."LineNum" AS "Nº da Linha", 
    T1."ItemCode" AS "Produto",
    T1."Dscription",
    T5."CodeBars" AS "EAN",
    T1."Quantity" AS "Qtde",
    T1."LineTotal" AS "Total por Produto",
    T2."Usage" AS "Utilização",
    T1."U_SPS_ListNum" AS "Nro Lista Preço",
    CASE 
        WHEN T1."U_SPS_ListNum" = '1' THEN 'Padrão' 
        WHEN T1."U_SPS_ListNum" = '2' THEN 'Vencimento Curto' 
        WHEN T1."U_SPS_ListNum" = '3' THEN 'Promocional' 
        WHEN T1."U_SPS_ListNum" = '5' THEN 'Hospitalar' 
        WHEN T1."U_SPS_ListNum" = '6' THEN 'Nitro' 
    END AS "Lista de Preço",
    T1."U_SPS_PercTrademarketing" AS "Percentual Trade Marketing",
    T6."Carrier",
    T0."U_SPS_Transportadora",
    CASE 
        WHEN T1."Usage" = 12 AND (T0."U_SPS_BonificaoTrade" = 'Y' OR T0."U_SPS_BonificaoExtra" = 'Y') THEN 'Não' 
        WHEN T1."Usage" = 12 AND (IFNULL(T0."U_SPS_BonificaoTrade", 'N') = 'N' AND IFNULL(T0."U_SPS_BonificaoExtra", 'N') = 'N') THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Talão",
    CASE 
        WHEN T0."U_SPS_BonificaoExtra" = 'Y' THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Extra",
    CASE 
        WHEN T0."U_SPS_BonificaoTrade" = 'Y' THEN 'Sim' 
        ELSE 'Não' 
    END AS "Bonificação Trade",
    CASE 
        WHEN T0."DocStatus" = 'C' THEN 'Fechado' 
        ELSE 'Aberto' 
    END AS "Status do Documento",
    CASE 
        WHEN T0."CANCELED" IN ('Y', 'C') THEN 'Sim' 
        ELSE 'Não' 
    END AS "Cancelado"
FROM OINV T0
INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry"
LEFT JOIN OCRD T7 ON T0."CardCode" = T7."CardCode"
LEFT JOIN "@GB_GER_CARTEIRA" T8 ON T7."U_GB_GER_CARTEIRA" = T8."Code"
INNER JOIN OUSG T2 ON T1."Usage" = T2."ID"
INNER JOIN OSLP T3 ON T0."SlpCode" = T3."SlpCode"
LEFT JOIN CRD1 T4 ON T4."CardCode" = T0."CardCode" AND T4."AdresType" = 'S' AND T4."Address" = T0."ShipToCode"
LEFT JOIN OITM T5 ON T1."ItemCode" = T5."ItemCode"
LEFT JOIN INV12 T6 ON T0."DocEntry" = T6."DocEntry"
WHERE T0."Model" = 39
ORDER BY T0."DocEntry", T1."LineNum";
