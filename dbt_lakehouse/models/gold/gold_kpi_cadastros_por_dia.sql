WITH cadastros_diarios AS (
  SELECT
    data_cadastro,
    COUNT(DISTINCT cpf) AS total_cadastros
  FROM {{ ref('silver_cadastros') }}
  GROUP BY data_cadastro
)

SELECT *
FROM cadastros_diarios