WITH pedidos_diarios AS (
  SELECT
    data_pedido,
    COUNT(CASE WHEN status_pedido = 'faturado' THEN id_pedido ELSE NULL END) AS total_faturados,
    COUNT(CASE WHEN status_pedido = 'cancelado' THEN id_pedido ELSE NULL END) AS total_cancelados,
    COUNT(CASE WHEN status_pedido = 'aguardando pagamento' THEN id_pedido ELSE NULL END) AS total_aguardando_pagamento
  FROM {{ ref('silver_pedidos') }}
  GROUP BY data_pedido
)

SELECT *
FROM pedidos_diarios