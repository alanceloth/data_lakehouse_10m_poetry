WITH bronze_cadastros_unique AS (
  -- Seleciona apenas o primeiro registro de cada CPF da camada bronze
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cpf ORDER BY id) AS rn  -- Ordena pelo id
  FROM {{ ref('bronze_cadastros') }}
),

cadastros_unicos AS (
  -- Filtra para obter apenas o primeiro registro de cada CPF
  SELECT
    id,
    nome,
    data_nascimento,
    cpf,
    cep,
    cidade,
    estado,
    pais,
    genero,
    telefone,
    email,
    data_cadastro
  FROM bronze_cadastros_unique
  WHERE rn = 1
),

faturados AS (
  -- Seleciona os pedidos faturados da tabela bronze_pedidos
  SELECT
    cpf,
    valor_pedido,
    id_pedido
  FROM {{ ref('bronze_pedidos') }}
  WHERE status_pedido = 'faturado'
),

gastos_aggregated AS (
  -- Agrega as informações de gasto total e número de pedidos por cliente (CPF)
  SELECT
    cpf,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(valor_pedido) AS total_gasto
  FROM faturados
  GROUP BY cpf
)

-- Combina as informações de clientes únicos com os dados agregados de pedidos faturados
SELECT
  c.id,
  c.nome,
  c.data_nascimento,
  c.cpf,
  c.cep,
  c.cidade,
  c.estado,
  c.pais,
  c.genero,
  c.telefone,
  c.email,
  data_cadastro,
  COALESCE(g.total_pedidos, 0) AS total_pedidos,
  COALESCE(g.total_gasto, 0) AS total_gasto
FROM cadastros_unicos c
LEFT JOIN gastos_aggregated g
ON c.cpf = g.cpf
