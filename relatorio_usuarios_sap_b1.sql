/*
===============================================================================
ORDEM DE SERVIÇO: (informar)
NOME DO RELATÓRIO: Relatório de Usuários Cadastrados no SAP Business One
AUTOR: Frederico Magalhães
DATA ALTERAÇÃO: 27/10/2026
OBJETIVO: Listagem dos usuários cadastrados no SAP B1 (OUSR) com situação de acesso (Ativo/Bloqueado), perfil de superusuário, departamento,
          filial e vínculo com o cadastro de colaboradores (OHEM), para apoio à auditoria de acessos.
AMBIENTE: SAP Business One (SAP HANA) - Gerenciador de Consultas
OBSERVAÇÃO: Validar no ambiente os campos "CreateDate" e "UpdateDate" da OUSR.
===============================================================================
*/

SELECT
    T0."USERID" AS "ID Interno",
    T0."USER_CODE" AS "Código do Usuário",
    T0."U_NAME" AS "Nome do Usuário",
    T0."E_Mail" AS "E-mail",
    T0."PortNum" AS "Celular",
    CASE
        WHEN T0."Locked" = 'Y' THEN 'Bloqueado'
        ELSE 'Ativo'
    END AS "Situação",
    CASE
        WHEN T0."SUPERUSER" = 'Y' THEN 'Sim'
        ELSE 'Não'
    END AS "Superusuário",
    T0."Department" AS "Cód. Departamento",
    T1."Name" AS "Departamento",
    T0."Branch" AS "Cód. Filial",
    T2."Name" AS "Filial",
    T3."empID" AS "Cód. Colaborador",
    NULLIF(TRIM(IFNULL(T3."firstName", '') || ' ' || IFNULL(T3."lastName", '')), '') AS "Nome do Colaborador"
FROM "OUSR" T0
LEFT JOIN "OUDP" T1 ON T1."Code" = T0."Department"
LEFT JOIN "OUBR" T2 ON T2."Code" = T0."Branch"
LEFT JOIN "OHEM" T3 ON T3."userId" = T0."USERID"
ORDER BY
    "Situação",
    T0."U_NAME";
