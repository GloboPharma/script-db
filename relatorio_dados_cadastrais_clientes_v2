/*
===============================================================================
ORDEM DE SERVIÇO: 20940
AUTOR: Frederico Magalhães
DATA ALTEAÇÃO: 03/11/2026
OBJETIVO: Criação do Relatório Dados Cadastrais Clientes - v2 com a correção das tabelas.
AMBIENTE: SAP Business One (SAP HANA)
===============================================================================
*/

SELECT 
    T0."CreateDate" AS "Data Criação",
    T2."SlpName" AS "Nome do vendedor",  
    T1."U_SPS_CNPJ" AS "CNPJ",
    T1."CardCode" AS "Código do PN",
    T1."CardName" AS "Nome do PN",
    T1."E_Mail" AS "E-mail", 
    T1."Phone2" AS "DDD", 
    T1."Phone1" AS "Telefone", 
    CASE 
        WHEN T1."U_SPS_Canal" = '0' THEN 'Indireto'
        WHEN T1."U_SPS_Canal" = '1' THEN 'Hosp'
        WHEN T1."U_SPS_Canal" = '2' THEN 'Parceiro'
        WHEN T1."U_SPS_Canal" = '3' THEN 'Direto'
        WHEN T1."U_SPS_Canal" = '4' THEN 'Governo'
        WHEN T1."U_SPS_Canal" = '5' THEN 'Outros'
        ELSE 'Não Informado'
    END AS "Canal",
    T0."Street" AS "Rua", 
    T0."Block" AS "Bairro", 
    T0."ZipCode" AS "CEP", 
    T0."City" AS "Cidade", 
    T0."State" AS "Estado", 
    T0."Country" AS "País/região",
    CASE
        WHEN T1."validFor" = 'N' THEN 'Inativo'
        WHEN T1."validFor" = 'Y' THEN 'Ativo'
        ELSE 'Outro'
    END AS "Status"
FROM CRD1 T0
INNER JOIN OCRD T1 ON T0."CardCode" = T1."CardCode"
INNER JOIN OSLP T2 ON T1."SlpCode" = T2."SlpCode"
WHERE T1."CardType" = 'C' 
  AND T0."AdresType" = 'S'