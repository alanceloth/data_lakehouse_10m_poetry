WITH bronze_pedidos_clean AS (
  -- Inclui os dados da camada bronze de pedidos
  SELECT
    id_pedido,
    cpf,
    valor_pedido,
    valor_frete,
    valor_desconto,
    cupom,
    endereco_entrega_logradouro,
    endereco_entrega_numero,
    endereco_entrega_bairro,
    endereco_entrega_cidade,
    -- Mapeia o nome do estado para a sigla correspondente
    CASE
      WHEN endereco_entrega_estado = 'Acre' THEN 'AC'
      WHEN endereco_entrega_estado = 'Alagoas' THEN 'AL'
      WHEN endereco_entrega_estado = 'Amapá' THEN 'AP'
      WHEN endereco_entrega_estado = 'Amazonas' THEN 'AM'
      WHEN endereco_entrega_estado = 'Bahia' THEN 'BA'
      WHEN endereco_entrega_estado = 'Ceará' THEN 'CE'
      WHEN endereco_entrega_estado = 'Distrito Federal' THEN 'DF'
      WHEN endereco_entrega_estado = 'Espírito Santo' THEN 'ES'
      WHEN endereco_entrega_estado = 'Goiás' THEN 'GO'
      WHEN endereco_entrega_estado = 'Maranhão' THEN 'MA'
      WHEN endereco_entrega_estado = 'Mato Grosso' THEN 'MT'
      WHEN endereco_entrega_estado = 'Mato Grosso do Sul' THEN 'MS'
      WHEN endereco_entrega_estado = 'Minas Gerais' THEN 'MG'
      WHEN endereco_entrega_estado = 'Pará' THEN 'PA'
      WHEN endereco_entrega_estado = 'Paraíba' THEN 'PB'
      WHEN endereco_entrega_estado = 'Paraná' THEN 'PR'
      WHEN endereco_entrega_estado = 'Pernambuco' THEN 'PE'
      WHEN endereco_entrega_estado = 'Piauí' THEN 'PI'
      WHEN endereco_entrega_estado = 'Rio de Janeiro' THEN 'RJ'
      WHEN endereco_entrega_estado = 'Rio Grande do Norte' THEN 'RN'
      WHEN endereco_entrega_estado = 'Rio Grande do Sul' THEN 'RS'
      WHEN endereco_entrega_estado = 'Rondônia' THEN 'RO'
      WHEN endereco_entrega_estado = 'Roraima' THEN 'RR'
      WHEN endereco_entrega_estado = 'Santa Catarina' THEN 'SC'
      WHEN endereco_entrega_estado = 'São Paulo' THEN 'SP'
      WHEN endereco_entrega_estado = 'Sergipe' THEN 'SE'
      WHEN endereco_entrega_estado = 'Tocantins' THEN 'TO'
      ELSE endereco_entrega_estado -- Caso algum estado não esteja mapeado
    END AS endereco_entrega_estado_sigla,  -- Renomeia a coluna para a sigla
    endereco_entrega_pais,
    status_pedido,
    data_pedido,
    -- Adiciona uma coluna booleana que indica se um cupom foi usado
    CASE 
      WHEN cupom IS NOT NULL THEN TRUE 
      ELSE FALSE 
    END AS cupom_usado,
    -- Calcula o valor total do pedido considerando o frete e o desconto
    (valor_pedido + valor_frete - valor_desconto) AS valor_total
  FROM {{ ref('bronze_pedidos') }}
)

-- Seleciona os dados já limpos e adiciona as colunas novas
SELECT
  id_pedido,
  cpf,
  valor_pedido,
  valor_frete,
  valor_desconto,
  valor_total,       -- Novo: Valor total do pedido
  cupom,
  cupom_usado,       -- Novo: Indicador de cupom usado (TRUE/FALSE)
  endereco_entrega_logradouro,
  endereco_entrega_numero,
  endereco_entrega_bairro,
  endereco_entrega_cidade,
  endereco_entrega_estado_sigla AS endereco_entrega_estado,
  endereco_entrega_pais,
  status_pedido,
  data_pedido
FROM bronze_pedidos_clean
