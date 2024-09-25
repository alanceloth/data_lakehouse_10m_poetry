-- models/bronze/bronze_cadastros.sql
WITH raw_data AS (
  SELECT * 
  FROM {{ source('raw_data', 'raw_cadastros') }}  -- Referenciando a tabela raw_cadastros
)
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
FROM raw_data
