{{ config(
    materialized='table'  
) }}

WITH vendas_diarias AS (
  SELECT
    data_pedido,
    SUM(CASE WHEN status_pedido = 'faturado' THEN valor_pedido ELSE 0 END) AS receita_total,
    COUNT(DISTINCT id_pedido) AS total_pedidos
  FROM {{ ref('silver_pedidos') }}
  GROUP BY data_pedido
)

SELECT *, 
  CASE 
    WHEN total_pedidos > 0 THEN receita_total / total_pedidos
    ELSE 0
  END AS ticket_medio
FROM vendas_diarias
