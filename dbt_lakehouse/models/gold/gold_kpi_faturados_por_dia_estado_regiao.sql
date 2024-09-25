WITH faturados_por_dia_estado AS (
  -- Seleciona apenas os pedidos faturados da camada silver e agrupa por dia e estado
  SELECT
    data_pedido,
    endereco_entrega_estado AS estado,
    COUNT(DISTINCT id_pedido) AS total_pedidos_faturados,
    SUM(valor_pedido) AS receita_total,
    -- Agrupa os estados por região
    CASE 
      WHEN endereco_entrega_estado IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'Norte'
      WHEN endereco_entrega_estado IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Nordeste'
      WHEN endereco_entrega_estado IN ('GO', 'MT', 'MS', 'DF') THEN 'Centro-Oeste'
      WHEN endereco_entrega_estado IN ('ES', 'MG', 'RJ', 'SP') THEN 'Sudeste'
      WHEN endereco_entrega_estado IN ('PR', 'RS', 'SC') THEN 'Sul'
      ELSE 'Desconhecido'  -- Para tratar qualquer estado que não se enquadre
    END AS regiao
  FROM {{ ref('silver_pedidos') }}
  WHERE status_pedido = 'faturado'
  GROUP BY data_pedido, endereco_entrega_estado
)

SELECT
  data_pedido,
  estado,
  regiao,
  total_pedidos_faturados,
  receita_total,
  -- Calcula o ticket médio por dia, estado e região
  CASE 
    WHEN total_pedidos_faturados > 0 THEN receita_total / total_pedidos_faturados
    ELSE 0
  END AS ticket_medio
FROM faturados_por_dia_estado