WITH rfm_data AS (
  SELECT
    cpf,
    MAX(data_pedido) AS ultima_compra,   -- Recência
    COUNT(id_pedido) AS frequencia,      -- Frequência
    SUM(valor_pedido) AS valor_total     -- Valor monetário
  FROM {{ ref('silver_pedidos') }}
  WHERE status_pedido = 'faturado'
  GROUP BY cpf
)

SELECT
  c.cpf,
  c.nome,
  r.ultima_compra,
  r.frequencia,
  r.valor_total,
  -- Atribuição de categorias RFM com base nos critérios
  CASE
    WHEN r.frequencia > 10 THEN 'Cliente Frequente'
    ELSE 'Cliente Ocasional'
  END AS categoria_frequencia,
  CASE
    WHEN r.valor_total > 5000 THEN 'Alto Valor'
    WHEN r.valor_total BETWEEN 1000 AND 5000 THEN 'Valor Médio'
    ELSE 'Baixo Valor'
  END AS categoria_valor
FROM {{ ref('silver_cadastros') }} c
LEFT JOIN rfm_data r
ON c.cpf = r.cpf
