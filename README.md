Gerar dados
- Criar aplicação para gerar os dados do projeto
- Deve gerar 1 milhão de linhas em 2 tabelas (cadastros e pedidos, relacionável entre si) e salvar em .parquet na pasta datasets, onde cada arquivo deve conter 100 mil linhas

- Passa a passo CMD
	- Criar projeto
		- `poetry new crm_taypy`
		- alterar a versão do python no `pyproject.toml` para `^3.12.0`
		- criar o `.gitignore`
		- adicionar a extensão `.parquet` no `.gitignore`
		- `git init`
		- `gh repo create`
	- Usar o Python 3.12.6
		- `pyenv update`
		- `pyenv install 3.12.6`
		- `pyenv local 3.12.6`
		- `poetry env use 3.12.6`
		- `poetry shell`
	- Dependências
		- `poetry add taipy`
		- `poetry add polars`
		- `poetry add faker`
		- `poetry add python-dotenv`
		- `poetry add duckdb`
		- `poetry add dbt-core`
		- `poetry add dbt-postgres`
		- `poetry add psycopg2`
		- `poetry add matplotlib`
		- `poetry add seaborn`
		- `poetry add plotly`
- Setup banco de dados - AWS
	- Criar o banco de dados na Amazon, copiar as credenciais para um arquivo `.env`
		- Entrar no amazon console
		- Escolher a opção Database
		- Escolher o RDS
		- Easy Create
		- Postgres
		- Freetier
		- Deixar publicamente acessível
		- Preencher os campos
	- Configurar a VPC
		- Entrar no grupo de segurança da VPC
		- Editar regras Inbound
		- Liberar acesso Postgres para meu IP 
- Setup bucket S3 - AWS
	- Criar usuário IAM com a política AmazonS3FullAccess
		- Criar a chave de acesso em Security Credentials
		- Exportar a o ID e a Key para o `.env`
	- Criar um bucket com block de acesso público
		- Atribuir a politica
		```
		{
		"Version": "2012-10-17",
		"Id": "Policy1726582006745",
		"Statement": [
			{
				"Sid": "Stmt1726581995058",
				"Effect": "Allow",
				"Principal": {
					"AWS": "ARN DO SEU USUARIO"
				},
				"Action": [
					"s3:GetObject",
					"s3:ListBucket",
					"s3:PutObject"
				],
				"Resource": [
					"arn:aws:s3:::NOME_DO_BUCKET",
					"arn:aws:s3:::NOME_DO_BUCKET/*"
				]
			}
		]
	}
		```
	
- RAW
	- Gerar os arquivos usando o `generate_raw.py`
		- Vai gerar um monte de .parquet na pasta datasets
		- Tempo decorrido: 4110.15 segundos = 1 hora e 8 minutos
	- Gerar a camada raw usando o `local_to_s3_boto3.py`
		- Usando o `duckdb + boto3`, conectar no bucket s3 e subir todos os arquivos `.parquet`
		- Tempo decorrido: 63 min (19s por arquivo aprox)
	- Gerar a camada raw usando o `local_to_s3_duckdb.py`
		- Usando o `duckdb`, conectar no bucket s3 e subir todos os arquivos `.parquet`
		- Tempo decorrido: 27 min (8s por arquivo aprox, redução de 57% no tempo de processamento)
	OU
	- Gerar a camada raw usando o `load_raw_to_postgres.py`
		- Usando o `duckdb`, conectar no banco `postgres` e subir em uma tabela só todos os arquivos `.parquet`
		- Tempo decorrido: 704.02 segundos = 12 minutos
- DBT (Bronze - Silver - Gold)
	- `dbt init crm_taipy`
	- Preencher os dados do banco de dados postgres do render no `dbt init`
	- `cd crm_taipy`
	- `dbt debug` (testar se a conexão e tudo está funcionando)
	- Criar os arquivos na pasta `models/bronze` 
		- `bronze_cadastros.sql`
		- `bronze_pedidos.sql`
		- Opção 1:
			- Raw no RDS para Bronze RDS: 98s + 105 = 3,5 min
				- `dbt run --models bronze_rds`
			- S3 para Bronze RDS: 93s + 84s = 3 min
				- `dbt run --models bronze_s3 --target dev-duckdb`
	- Criar os arquivos na pasta `models/silver`
		- `silver_cadastros.sql`
		- `silver_pedidos.sql`
	- Na pasta `models`
		- `bronze_cadastros_tests.yml`
		- `bronze_pedidos_test.yml`
		- `silver_cadastros_test.yml`
	- Criar os arquivos na pasta `models/gold`
		- `gold_kpi_cadastros_por_dia.sql`
		- `gold_kpi_cancelamento_por_estado_regiao.sql`
		- `gold_kpi_faturados_por_dia_estado_regiao.sql`
		- `gold_kpi_ltv.sql`
		- `gold_kpi_pedidos_por_dia.sql`
		- `gold_kpi_rfm.sql`
		- `gold_kpi_taxa_conversao_estado_regiao.sql`
		- `gold_kpi_ticket_medio_por_dia.sql`
		- `gold_kpi_vendas_por_dia.sql`
		- `gold_kpi_tb_vendas_por_dia.sql`
	- Executar o comando `dbt build` (vai executar os `dbt tests` e o `dbt run` em conjunto)
		- Finished running 4 table models, 6 data tests, 9 view models in 0 hours 14 minutes and 25.78 seconds (865.78s).

Dashboard Taipy
- Criar pasta `dashboard`
	- Criar arquivo `dashboard.py`
	- Criar arquivo `dashboard.md`
- Criar arquivo `main.py`
- Executar comando `poetry run python frontend/main.py`

	Usando view pandas:
		load : 2min e 26s
		filtro: 1 min

	Usando view polars:
		load : 2min e 26s
		filtro: 1 min

	Usando tabela pandas:
		load: 30s
		filtro: 7s

	Usando tabela polars:
		load: 30s
		filtro: 6s



## Terraform

```
terraform plan
```

```
terraform apply
```

```
terraform destroy
```


Descrição dos Arquivos
- provider.tf: Configuração do provedor AWS.
- versions.tf: Definição das versões do Terraform e dos provedores.
- variables.tf: Declaração das variáveis usadas no projeto.
- terraform.tfvars: Atribuição de valores para as variáveis.
- networking.tf: Configuração de VPC, sub-redes, e Internet Gateway.
- security_groups.tf: Definição dos grupos de segurança.
- rds.tf: Configuração da instância RDS PostgreSQL.
- s3.tf: Configuração do bucket S3.
- iam.tf: Configuração de roles e políticas IAM.
- main.tf: Importa todos os módulos e recursos definidos nos outros arquivos.
- outputs.tf: Definição das saídas do Terraform.