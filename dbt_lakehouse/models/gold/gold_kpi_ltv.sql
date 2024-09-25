WITH total_gasto_clientes AS (
  SELECT
    cpf,
    SUM(valor_pedido) AS total_gasto
  FROM {{ ref('silver_pedidos') }}
  WHERE status_pedido = 'faturado'
  GROUP BY cpf
)

SELECT
  c.cpf,
  c.nome,
  c.data_cadastro,
  t.total_gasto,
  -- LTV pode ser usado como indicador para segmentar os clientes
  CASE 
    WHEN t.total_gasto > 5000 THEN 'Alto'
    WHEN t.total_gasto BETWEEN 1000 AND 5000 THEN 'Médio'
    ELSE 'Baixo'
  END AS categoria_ltv
FROM {{ ref('silver_cadastros') }} c
LEFT JOIN total_gasto_clientes t
ON c.cpf = t.cpf
