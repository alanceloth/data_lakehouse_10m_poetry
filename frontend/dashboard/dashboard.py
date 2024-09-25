import duckdb
import pandas as pd
from taipy.gui import Markdown
import os
from dotenv import load_dotenv
import plotly.graph_objects as go

# Carrega as variáveis de ambiente para o RDS PostgreSQL
load_dotenv(override=True)

# Variáveis globais
selected_date = None
df_filtered = None
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

# Função para carregar os KPIs de pedidos e cadastros
def load_kpis_faturados_por_dia():
    conn = connect_duckdb()
    query = """
        SELECT data_pedido, total_pedidos, receita_total, ticket_medio
        FROM postgres_db.gold_kpi_tb_vendas_por_dia
    """
    #FROM postgres_db.gold_kpi_tb_vendas_por_dia
    #FROM postgres_db.gold_kpi_vendas_por_dia
    df = conn.execute(query).fetchdf()
    conn.close()
    return df

def load_kpis_cadastros_por_dia():
    conn = connect_duckdb()
    query = """
        SELECT data_cadastro, total_cadastros
        FROM postgres_db.gold_kpi_tb_cadastros_por_dia
    """
    #FROM postgres_db.gold_kpi_tb_cadastros_por_dia #TABELA
    #FROM postgres_db.gold_kpi_cadastros_por_dia #VIEW
    df = conn.execute(query).fetchdf()
    conn.close()
    return df

# Função para inicializar e filtrar os dados
def initialize_kpis(df, date_col, selected_date=None):
    # Usar a data atual como valor padrão se `selected_date` for None
    if selected_date is None:
        selected_date = pd.Timestamp('today').normalize()  # Normaliza para remover a parte da hora

    # Filtrar os dados usando a coluna de data passada (date_col)
    df_filtered = df[df[date_col] >= pd.to_datetime(selected_date)]
    
    return df_filtered

# Função para atualizar os gráficos e KPIs
def update_dashboard(state):
    global total_cadastros, total_pedidos, ticket_medio, fig_cadastros, fig_pedidos, fig_receita_ticket
    df_filtered_faturados_por_dia = initialize_kpis(load_kpis_faturados_por_dia(), 'data_pedido', state.selected_date)
    df_filtered_cadastros_por_dia = initialize_kpis(load_kpis_cadastros_por_dia(), 'data_cadastro', state.selected_date)
    
    # Atualizar KPIs
    total_cadastros = int(df_filtered_cadastros_por_dia['total_cadastros'].sum())  # Garantir que seja um número inteiro
    total_pedidos = int(df_filtered_faturados_por_dia['total_pedidos'].sum())  # Converter para inteiro
    ticket_medio = round(df_filtered_faturados_por_dia['ticket_medio'].mean(), 2) if not df_filtered_faturados_por_dia['ticket_medio'].isna().all() else 0  # Ticket médio arredondado para 2 casas decimais
    state.total_cadastros = total_cadastros
    state.total_pedidos = total_pedidos
    state.ticket_medio = ticket_medio

    # Criação dos gráficos
    fig_cadastros = go.Figure()
    df_cadastros = df_filtered_cadastros_por_dia.groupby(df_filtered_cadastros_por_dia['data_cadastro'].dt.to_period('M'))['total_cadastros'].sum().reset_index()
    fig_cadastros.add_trace(go.Bar(x=df_cadastros['data_cadastro'].astype(str), y=df_cadastros['total_cadastros'], name="Cadastros"))
    state.fig_cadastros = fig_cadastros

    fig_pedidos = go.Figure()
    df_pedidos = df_filtered_faturados_por_dia.groupby(df_filtered_faturados_por_dia['data_pedido'].dt.to_period('M'))['total_pedidos'].sum().reset_index()
    fig_pedidos.add_trace(go.Bar(x=df_pedidos['data_pedido'].astype(str), y=df_pedidos['total_pedidos'], name="Pedidos"))
    state.fig_pedidos = fig_pedidos

    fig_receita_ticket = go.Figure()
    df_receita = df_filtered_faturados_por_dia.groupby(df_filtered_faturados_por_dia['data_pedido'].dt.to_period('M'))[['receita_total', 'ticket_medio']].sum().reset_index()
    fig_receita_ticket.add_trace(go.Bar(x=df_receita['data_pedido'].astype(str), y=df_receita['receita_total'], name="Receita", yaxis='y1'))
    fig_receita_ticket.add_trace(go.Scatter(x=df_receita['data_pedido'].astype(str), y=df_receita['ticket_medio'], mode='lines+markers', name="Ticket Médio", yaxis='y2'))
    
    # Configuração dos eixos independentes para o gráfico de receita e ticket médio
    fig_receita_ticket.update_layout(
        title="Receita e Ticket Médio ao Longo dos Meses",
        xaxis_title="Mês",
        yaxis_title="Receita",
        yaxis2=dict(
            title="Ticket Médio",
            overlaying='y',  # Sobrepõe o eixo y principal
            side='right',    # Eixo à direita
            showgrid=False   # Remove a grid do segundo eixo
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
    df_faturados_por_dia_estado_regiao = load_kpis_faturados_por_dia()
    df_cadastros_por_dia = load_kpis_cadastros_por_dia()

    # Atualizar KPIs
    total_cadastros = int(df_cadastros_por_dia['total_cadastros'].sum())  
    total_pedidos = int(df_faturados_por_dia_estado_regiao['total_pedidos'].sum()) 
    ticket_medio = round(df_faturados_por_dia_estado_regiao['ticket_medio'].mean(), 2) if not df_faturados_por_dia_estado_regiao['ticket_medio'].isna().all() else 0  # Ticket médio arredondado para 2 casas decimais

    # Criação dos gráficos
    fig_cadastros = go.Figure()
    df_cadastros = df_cadastros_por_dia.groupby(df_cadastros_por_dia['data_cadastro'].dt.to_period('M'))['total_cadastros'].sum().reset_index()
    fig_cadastros.add_trace(go.Bar(x=df_cadastros['data_cadastro'].astype(str), y=df_cadastros['total_cadastros'], name="Cadastros"))

    fig_pedidos = go.Figure()
    df_pedidos = df_faturados_por_dia_estado_regiao.groupby(df_faturados_por_dia_estado_regiao['data_pedido'].dt.to_period('M'))['total_pedidos'].sum().reset_index()
    fig_pedidos.add_trace(go.Bar(x=df_pedidos['data_pedido'].astype(str), y=df_pedidos['total_pedidos'], name="Pedidos"))

    fig_receita_ticket = go.Figure()
    # Gráfico de receita ao longo dos meses e ticket médio com dois eixos y
    df_receita = df_faturados_por_dia_estado_regiao.groupby(df_faturados_por_dia_estado_regiao['data_pedido'].dt.to_period('M'))[['receita_total', 'ticket_medio']].sum().reset_index()
    fig_receita_ticket.add_trace(go.Bar(x=df_receita['data_pedido'].astype(str), y=df_receita['receita_total'], name="Receita", yaxis='y1'))
    fig_receita_ticket.add_trace(go.Scatter(x=df_receita['data_pedido'].astype(str), y=df_receita['ticket_medio'], mode='lines+markers', name="Ticket Médio", yaxis='y2'))
    # Configuração dos eixos independentes para o gráfico de receita e ticket médio
    fig_receita_ticket.update_layout(
        title="Receita e Ticket Médio ao Longo dos Meses",
        xaxis_title="Mês",
        yaxis_title="Receita",
        yaxis2=dict(
            title="Ticket Médio",
            overlaying='y',  # Sobrepõe o eixo y principal
            side='right',    # Eixo à direita
            showgrid=False   # Remove a grid do segundo eixo
        )
    )

# Ler o arquivo .md com a codificação correta
def load_markdown_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.read()
    

# pré-carregar os dados
initialize_dashboard_data()

dashboard_md_content = load_markdown_file("frontend/dashboard/dashboard.md")
dashboard_md = Markdown(dashboard_md_content)
