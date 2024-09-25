import duckdb
import polars as pl
import os
from dotenv import load_dotenv
import plotly.graph_objects as go
from taipy.gui import Markdown

# Carrega as variáveis de ambiente para o RDS PostgreSQL
load_dotenv(override=True)

# Variáveis globais
selected_date = None
total_cadastros = 0
total_pedidos = 0
ticket_medio = 0

fig_cadastros = go.Figure()
fig_pedidos = go.Figure()
fig_receita_ticket = go.Figure()

# Função para conectar ao banco de dados PostgreSQL via DuckDB
def connect_duckdb():
    POSTGRES_HOSTNAME = os.getenv('POSTGRES_HOSTNAME')
    POSTGRES_DBNAME = os.getenv('POSTGRES_DBNAME')
    POSTGRES_USER = os.getenv('POSTGRES_USER')
    POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD')
    POSTGRES_PORT = os.getenv('POSTGRES_PORT')

    con = duckdb.connect()
    con.execute("""
        INSTALL postgres_scanner;
        LOAD postgres_scanner;
    """)
    con.execute(f"""
        ATTACH 'dbname={POSTGRES_DBNAME} user={POSTGRES_USER} host={POSTGRES_HOSTNAME} port={POSTGRES_PORT} password={POSTGRES_PASSWORD}' 
        AS postgres_db (TYPE POSTGRES, SCHEMA 'public');
    """)
    return con

# Função para carregar os KPIs de pedidos e cadastros com DuckDB e convertendo para Polars
def load_kpis_faturados_por_dia_estado_regiao():
    conn = connect_duckdb()
    query = """
        SELECT data_pedido, total_pedidos, receita_total, ticket_medio
        FROM postgres_db.gold_kpi_tb_vendas_por_dia
    """
    #FROM postgres_db.gold_kpi_tb_vendas_por_dia
    #FROM postgres_db.gold_kpi_vendas_por_dia
    df = pl.from_arrow(conn.execute(query).arrow())  # Convertendo para Polars
    conn.close()
    return df

def load_kpis_cadastros_por_dia():
    conn = connect_duckdb()
    query = """
        SELECT data_cadastro, total_cadastros
        FROM postgres_db.gold_kpi_tb_cadastros_por_dia
    """
    #FROM postgres_db.gold_kpi_tb_cadastros_por_dia
    #FROM postgres_db.gold_kpi_cadastros_por_dia
    df = pl.from_arrow(conn.execute(query).arrow())  # Convertendo para Polars
    conn.close()
    return df

# Função para filtrar os dados com Polars
def initialize_kpis(df, date_col, selected_date=None):
    if selected_date is None:
        selected_date = pl.lit(pl.datetime("now").date())  # Usa a data atual se não for passada

    # Filtrar os dados usando Polars
    df_filtered = df.filter(pl.col(date_col) >= selected_date)
    return df_filtered

# Função para atualizar os gráficos e KPIs usando Polars
def update_dashboard(state):
    global total_cadastros, total_pedidos, ticket_medio, fig_cadastros, fig_pedidos, fig_receita_ticket

    # Carregar os dados
    df_faturados = load_kpis_faturados_por_dia_estado_regiao()
    df_cadastros = load_kpis_cadastros_por_dia()

    # Filtrar os dados com Polars
    df_filtered_faturados = initialize_kpis(df_faturados, 'data_pedido', state.selected_date)
    df_filtered_cadastros = initialize_kpis(df_cadastros, 'data_cadastro', state.selected_date)

    # Atualizar KPIs
    total_cadastros = int(df_filtered_cadastros['total_cadastros'].sum())
    total_pedidos = int(df_filtered_faturados['total_pedidos'].sum())
    ticket_medio = df_filtered_faturados['ticket_medio'].mean()
    if ticket_medio is not None:
        ticket_medio = round(ticket_medio, 2)  # Corrigir para usar a função `round()
    
    state.total_cadastros = total_cadastros
    state.total_pedidos = total_pedidos
    state.ticket_medio = ticket_medio

    # Agregar cadastros por mês
    df_filtered_cadastros = df_filtered_cadastros.with_columns([
        pl.col('data_cadastro').dt.truncate('1mo').alias('mes_cadastro')
    ])
    df_cadastros_grouped = df_filtered_cadastros.group_by('mes_cadastro').agg(pl.sum('total_cadastros')).sort('mes_cadastro')

    # Criar gráficos
    # Criar o gráfico de cadastros
    fig_cadastros = go.Figure()
    fig_cadastros.add_trace(go.Bar(
        x=df_cadastros_grouped['mes_cadastro'].to_list(), 
        y=df_cadastros_grouped['total_cadastros'].to_list(), 
        name="Cadastros"
    ))
    state.fig_cadastros = fig_cadastros

    # Agregar pedidos por mês
    df_filtered_faturados = df_filtered_faturados.with_columns([
        pl.col('data_pedido').dt.truncate('1mo').alias('mes_pedido')
    ])
    df_pedidos_grouped = df_filtered_faturados.group_by('mes_pedido').agg(pl.sum('total_pedidos')).sort('mes_pedido')

    # Criar o gráfico de pedidos
    fig_pedidos = go.Figure()
    fig_pedidos.add_trace(go.Bar(
        x=df_pedidos_grouped['mes_pedido'].to_list(), 
        y=df_pedidos_grouped['total_pedidos'].to_list(), 
        name="Pedidos"
    ))
    state.fig_pedidos = fig_pedidos

    # Agregar receita e ticket médio por mês
    df_receita_grouped = df_filtered_faturados.group_by('mes_pedido').agg([
        pl.sum('receita_total'),
        pl.mean('ticket_medio')
    ]).sort('mes_pedido')

    # Criar o gráfico de receita e ticket médio
    fig_receita_ticket = go.Figure()
    fig_receita_ticket.add_trace(go.Bar(
        x=df_receita_grouped['mes_pedido'].to_list(), 
        y=df_receita_grouped['receita_total'].to_list(), 
        name="Receita", 
        yaxis='y1'
    ))
    fig_receita_ticket.add_trace(go.Scatter(
        x=df_receita_grouped['mes_pedido'].to_list(), 
        y=df_receita_grouped['ticket_medio'].to_list(), 
        mode='lines+markers', 
        name="Ticket Médio", 
        yaxis='y2'
    ))

    # Configuração dos eixos independentes para o gráfico de receita e ticket médio
    fig_receita_ticket.update_layout(
        title="Receita e Ticket Médio ao Longo dos Meses",
        xaxis_title="Mês",
        yaxis_title="Receita",
        yaxis2=dict(
            title="Ticket Médio",
            overlaying='y',
            side='right',
            showgrid=False
        )
    )
    state.fig_receita_ticket = fig_receita_ticket

# Função para converter valores para texto
def to_text(value):
    return f"{value:,.2f}"

# Função para inicializar e processar os dados (sem filtro)
def initialize_dashboard_data():
    global total_cadastros, total_pedidos, ticket_medio, fig_cadastros, fig_pedidos, fig_receita_ticket
    
    # Carregar os dados
    df_faturados = load_kpis_faturados_por_dia_estado_regiao()
    df_cadastros = load_kpis_cadastros_por_dia()

    # Atualizar KPIs
    total_cadastros = int(df_cadastros['total_cadastros'].sum())
    total_pedidos = int(df_faturados['total_pedidos'].sum())
    
    # Corrigindo a obtenção da média do ticket médio
    ticket_medio = df_faturados['ticket_medio'].mean()  # Isso já retorna um float
    if ticket_medio is not None:
        ticket_medio = round(ticket_medio, 2)  # Use a função `round` do Python diretamente
    
    # Agregar cadastros por mês
    df_cadastros = df_cadastros.with_columns([
        pl.col('data_cadastro').dt.truncate('1mo').alias('mes_cadastro')
    ])
    df_cadastros_grouped = df_cadastros.group_by('mes_cadastro').agg(pl.sum('total_cadastros')).sort('mes_cadastro')
    
    # Criar gráficos
    # Criar o gráfico de cadastros
    fig_cadastros = go.Figure()
    fig_cadastros.add_trace(go.Bar(
        x=df_cadastros_grouped['mes_cadastro'].to_list(), 
        y=df_cadastros_grouped['total_cadastros'].to_list(), 
        name="Cadastros"
    ))

    # Agregar pedidos por mês
    df_faturados = df_faturados.with_columns([
        pl.col('data_pedido').dt.truncate('1mo').alias('mes_pedido')
    ])
    df_pedidos_grouped = df_faturados.group_by('mes_pedido').agg(pl.sum('total_pedidos')).sort('mes_pedido')

    # Criar o gráfico de pedidos
    fig_pedidos = go.Figure()
    fig_pedidos.add_trace(go.Bar(
        x=df_pedidos_grouped['mes_pedido'].to_list(), 
        y=df_pedidos_grouped['total_pedidos'].to_list(), 
        name="Pedidos"
    ))

    # Agregar receita e ticket médio por mês
    df_receita_grouped = df_faturados.group_by('mes_pedido').agg([
        pl.sum('receita_total'),
        pl.mean('ticket_medio')
    ]).sort('mes_pedido')

    # Criar o gráfico de receita e ticket médio
    fig_receita_ticket = go.Figure()
    fig_receita_ticket.add_trace(go.Bar(
        x=df_receita_grouped['mes_pedido'].to_list(), 
        y=df_receita_grouped['receita_total'].to_list(), 
        name="Receita", 
        yaxis='y1'
    ))
    fig_receita_ticket.add_trace(go.Scatter(
        x=df_receita_grouped['mes_pedido'].to_list(), 
        y=df_receita_grouped['ticket_medio'].to_list(), 
        mode='lines+markers', 
        name="Ticket Médio", 
        yaxis='y2'
    ))

    # Configuração dos eixos independentes para o gráfico de receita e ticket médio
    fig_receita_ticket.update_layout(
        title="Receita e Ticket Médio ao Longo dos Meses",
        xaxis_title="Mês",
        yaxis_title="Receita",
        yaxis2=dict(
            title="Ticket Médio",
            overlaying='y',
            side='right',
            showgrid=False
        )
    )

# Ler o arquivo .md com a codificação correta
def load_markdown_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.read()

# pré-carregar os dados
initialize_dashboard_data()

dashboard_md_content = load_markdown_file("frontend/dashboard/dashboard_polars.md")
dashboard_md_polars = Markdown(dashboard_md_content)
