WITH ticket_medio_diario AS (
  SELECT
    data_pedido,
    -- Soma dos pedidos faturados
    SUM(CASE WHEN status_pedido = 'faturado' THEN valor_pedido ELSE 0 END) AS receita_total,
    -- Contagem de pedidos faturados
    COUNT(DISTINCT CASE WHEN status_pedido = 'faturado' THEN id_pedido ELSE NULL END) AS total_pedidos_faturados
  FROM {{ ref('silver_pedidos') }}
  GROUP BY data_pedido
)

SELECT
  data_pedido,
  receita_total,
  total_pedidos_faturados,
  -- Calcula o ticket médio apenas se houver pedidos faturados
  CASE 
    WHEN total_pedidos_faturados > 0 THEN receita_total / total_pedidos_faturados
    ELSE 0
  END AS ticket_medio
FROM ticket_medio_diario
