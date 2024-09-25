from taipy.gui import Gui
import taipy as tp
import taipy.gui.builder as tgb

# Importando o conteúdo das páginas
from dashboard.dashboard import dashboard_md  # Conteúdo Markdown para a página principal


# Definição das páginas
pages = {
    '/': dashboard_md,  # Página principal
   
}

if __name__ == '__main__':
    # Inicializando o GUI com as páginas definidas
    gui = Gui(pages=pages)

    # Inicializando o core do Taipy
    tp.Core().run()

    # Executando o servidor do Taipy com múltiplas páginas
    gui.run(title="Dashboard de KPIs", use_reloader=True)
