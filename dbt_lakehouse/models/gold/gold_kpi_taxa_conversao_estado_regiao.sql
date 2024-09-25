WITH clientes_com_pedidos AS (
  SELECT DISTINCT cpf
  FROM {{ ref('silver_pedidos') }}
  WHERE status_pedido = 'faturado'
),

cadastros AS (
  SELECT
    cpf,
    endereco_entrega_estado AS estado,
    CASE 
      WHEN endereco_entrega_estado IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'Norte'
      WHEN endereco_entrega_estado IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Nordeste'
      WHEN endereco_entrega_estado IN ('GO', 'MT', 'MS', 'DF') THEN 'Centro-Oeste'
      WHEN endereco_entrega_estado IN ('ES', 'MG', 'RJ', 'SP') THEN 'Sudeste'
      WHEN endereco_entrega_estado IN ('PR', 'RS', 'SC') THEN 'Sul'
      ELSE 'Desconhecido'
    END AS regiao
  FROM {{ ref('silver_pedidos') }}
)

SELECT
  estado,
  regiao,
  COUNT(DISTINCT c.cpf) AS total_cadastros,
  COUNT(DISTINCT cp.cpf) AS total_com_pedidos,
  CASE 
    WHEN COUNT(DISTINCT c.cpf) > 0 THEN COUNT(DISTINCT cp.cpf) * 100.0 / COUNT(DISTINCT c.cpf)
    ELSE 0
  END AS taxa_conversao
FROM cadastros c
LEFT JOIN clientes_com_pedidos cp
ON c.cpf = cp.cpf
GROUP BY estado, regiao