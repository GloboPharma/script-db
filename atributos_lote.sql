/*
==============================================================================
ORDEM DE SERVIÇO: 20637
VIEW SAP HANA: VW_ATRIBUTOS_LOTE_VEICULOS
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 20/10/2026
OBJETIVO: Atributos de Lote (Veículos - Grupo 102) - Dados de estoque em lote (OBTQ/OBTN), status de liberação, atributos automotivos (Skill) e controle de qualidade/quarentena (SPS)
AMBIENTE: SAP Business One (SAP HANA)
==============================================================================
*/

CREATE OR REPLACE VIEW "SBOGPHARMA"."VW_ATRIBUTOS_LOTE_VEICULOS" AS
SELECT 
    T0."ItemCode" AS "Nº do item",
    T2."ItemName" AS "Descrição do item",
    T1."DistNumber" AS "Lote",
    T0."WhsCode" AS "Depósito",
    T0."Quantity" AS "Quantidade",
    T0."CommitQty" AS "Atribuído",
    T1."MnfSerial" AS "Atributo do lote 1",
    T1."LotNumber" AS "Atributo lote 2",    
    CASE T1."Status" 
        WHEN 0 THEN 'Liberado' 
        WHEN 1 THEN 'Não Acessível' 
        WHEN 2 THEN 'Bloqueado' 
        ELSE TO_VARCHAR(T1."Status") 
    END AS "Status",
    T1."ExpDate" AS "Data de vencimento",
    T1."MnfDate" AS "Data de fabricação",
    T1."InDate" AS "Data de admissão",
    T1."Location" AS "Localização",
    T1."SysNumber" AS "Nº do sistema",
    T1."Notes" AS "Detalhes",
    T1."U_tpOp" AS "Skill - Tipo da Operação",
    T1."U_chassi" AS "Skill - Chassi",
    T1."U_cCor" AS "Skill - Cód. Cor - Montadora",
    T1."U_xCor" AS "Skill - Descrição da Cor",
    T1."U_pot" AS "Skill - Potência do Motor",
    T1."U_CM3" AS "Skill - CM3 (Potência)",
    T1."U_pesoL" AS "Skill - Peso Líquido",
    T1."U_pesoB" AS "Skill - Peso Bruto",
    T1."U_nSerie" AS "Skill - Serial (Série)",
    T1."U_tpComb" AS "Skill - Tipo de Combustível",
    T1."U_nMotor" AS "Skill - Número do Motor",
    T1."U_CMKG" AS "Skill - CMKG",
    T1."U_dist" AS "Skill - Distância entre eixos",
    T1."U_RENAVAM" AS "Skill - RENAVAM",
    T1."U_anoMod" AS "Skill - Ano Modelo Fabric.",
    T1."U_anoFab" AS "Skill - Ano de Fabricação",
    T1."U_tpPint" AS "Skill - Tipo de Pintura",
    T1."U_tpVeic" AS "Skill - Tipo de Veículo",
    T1."U_espVeic" AS "Skill - Espécie do Veículo",
    T1."U_VIN" AS "Skill - Condição do VIN",
    T1."U_condVeic" AS "Skill - Condição do Veículo",
    T1."U_cMod" AS "Skill - Código Marca Modelo",
    T1."U_cCorDNT" AS "Skill - Cor DENATRAN",
    T1."U_lota" AS "Skill - Capac. Máx de lotação",
    T1."U_tpRest" AS "Skill - Restrição",
    T1."U_SKILL_INDOPEVEI" AS "Skill - Ind. Oper. Veículo",
    T1."U_SKILL_CNPJCONC" AS "Skill - CNPJ Concessionária",
    T1."U_SKILL_UFCONC" AS "Skill - UF Concessionária",
    T1."U_beas_ver" AS "U_beas_ver",
    T1."U_beas_selfprod" AS "U_beas_selfprod",
    T1."U_SPS_Volumes" AS "U_SPS_Volumes",
    T1."U_SPS_Amostra" AS "U_SPS_Amostra",
    CASE TRIM(T1."U_SPS_Motivo")
        WHEN '01' THEN 'Quarentena'
        WHEN '1' THEN 'Quarentena'
        WHEN '04' THEN 'Aprovado'
        WHEN '4' THEN 'Aprovado'
        WHEN '02' THEN 'Reprovado'
        WHEN '2' THEN 'Reprovado'
        ELSE T1."U_SPS_Motivo"
    END AS "U_SPS_Motivo",
    T1."U_SPS_TiposDeVolume" AS "U_SPS_TiposDeVolume",
    CASE T1."U_SPS_VencCurto"
        WHEN 'Y' THEN 'Sim'
        WHEN 'N' THEN 'Não'
        ELSE T1."U_SPS_VencCurto"
    END AS "U_SPS_VencCurto",
    T1."U_SPS_CodFab" AS "U_SPS_CodFab",
    T1."U_SPS_NomeFab" AS "U_SPS_NomeFab",
    T1."U_SPS_Divergence" AS "U_SPS_Divergence",
    T1."U_SPS_StatusRevision" AS "U_SPS_StatusRevision",
    T1."U_SPS_RNC" AS "U_SPS_RNC",
    T1."U_RNC_Cad" AS "U_RNC_Cad",
    T1."U_Obs" AS "U_Obs",
    T1."U_OBSL" AS "U_OBSL"
FROM 
    "SBOGPHARMA"."OBTQ" T0
INNER JOIN 
    "SBOGPHARMA"."OBTN" T1 ON T0."ItemCode" = T1."ItemCode" AND T0."SysNumber" = T1."SysNumber"
INNER JOIN 
    "SBOGPHARMA"."OITM" T2 ON T0."ItemCode" = T2."ItemCode"
WHERE 
    T0."Quantity" > 0
    AND T2."ItmsGrpCod" = 102;

-- ==============================================================================
-- EXEMPLO DE CONSULTA:
-- ==============================================================================
-- SELECT * 
-- FROM "SBOGPHARMA"."VW_ATRIBUTOS_LOTE_VEICULOS";