# Dashboard de KPIs

### Esta página oferece uma visão geral dos KPIs do sistema **CRM**{: .color-primary}, como **cadastros**, **pedidos** e **ticket médio**, além de gráficos mostrando a evolução de cada métrica ao longo do tempo.(dados processados com pandas)

<br/>

<|layout|columns=1 1 1|gap=25px|
<|{selected_date}|date|name=selected_date|label=Selecione a Data|on_change=update_dashboard|>
|>

<br/>

<|layout|columns=3 3 3|gap=25px|class_name=fullwidth|

<|card|
**Total Cadastros**{: .color-primary}
<|{(total_cadastros)}|text|class_name=h3|>
|>

<|card|
**Total Pedidos**{: .color-primary}
<|{(total_pedidos)}|text|class_name=h3|>
|>

<|card|
**Ticket Médio**{: .color-primary}
<|{(ticket_medio)}|text|class_name=h3|>
|>

|>
<br/>

<|layout|columns=1|gap=25px|
<|chart|figure={fig_cadastros}|filter=True|title=Cadastros ao longo do tempo|>
<|chart|figure={fig_pedidos}|filter=True|title=Pedidos ao longo do tempo|>
<|chart|figure={fig_receita_ticket}|filter=True|title=Receita e Ticket Médio|>
|>

<br/>
