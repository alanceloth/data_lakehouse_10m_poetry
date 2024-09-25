WITH cancelamentos_por_dia_regiao AS (
  SELECT
    data_pedido,
    endereco_entrega_estado AS estado,
    COUNT(id_pedido) AS total_cancelados,
    -- Agrupa os estados por região
    CASE 
      WHEN endereco_entrega_estado IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'Norte'
      WHEN endereco_entrega_estado IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Nordeste'
      WHEN endereco_entrega_estado IN ('GO', 'MT', 'MS', 'DF') THEN 'Centro-Oeste'
      WHEN endereco_entrega_estado IN ('ES', 'MG', 'RJ', 'SP') THEN 'Sudeste'
      WHEN endereco_entrega_estado IN ('PR', 'RS', 'SC') THEN 'Sul'
      ELSE 'Desconhecido'
    END AS regiao
  FROM {{ ref('silver_pedidos') }}
  WHERE status_pedido = 'cancelado'
  GROUP BY data_pedido, endereco_entrega_estado
)

SELECT
  data_pedido,
  estado,
  regiao,
  total_cancelados
FROM cancelamentos_por_dia_regiao