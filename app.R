# =============================================================================
# app.R - Interface (Shiny) da Ferramenta de Modelagem dos Ipes
# -----------------------------------------------------------------------------
# COMO ABRIR: no RStudio, com o projeto FerramentaIpes.Rproj aberto, abra este
#             arquivo e clique em "Run App" (ou rode shiny::runApp()).
# A interface apenas CHAMA as funcoes dos scripts numerados em R/. Tudo que ela
# faz pode ser reproduzido rodando os scripts sem o app.
# =============================================================================

source("R/01_CONFIGURACAO_E_FUNCOES.R", encoding = "UTF-8")
source("R/02_CARREGAR_DADOS.R", encoding = "UTF-8")
source("R/03_DIAGNOSTICO_DADOS.R", encoding = "UTF-8")
suppressPackageStartupMessages({ library(shiny); library(bslib); library(DT) })

caixa_ajuda <- function(...) div(class = "alert alert-info", style = "font-size:0.92em", ...)
tabela <- function(df) datatable(df, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE))

ui <- page_navbar(
  title = "Modelagem dos Ipês – TCC UFRA",
  theme = bs_theme(bootswatch = "flatly"),
  sidebar = sidebar(
    width = 260,
    radioButtons("especie", "Espécie (fluxo separado)",
                 choices = c("Ipê-roxo" = "roxo", "Ipê-amarelo" = "amarelo")),
    helpText("Cada espécie tem suas próprias escolhas e sua própria pasta em resultados/."),
    hr(), helpText("Dados lidos de:"), tags$small(PASTA_DADOS)
  ),

  nav_panel("1. Diagnóstico",
    caixa_ajuda(
      strong("O que esta etapa faz? "),
      "Olha como as presenças estão espalhadas entre propriedades, UPAs e folds, antes de qualquer modelo. ",
      "Mostra se poucas propriedades concentram os pontos, se algum fold é pequeno demais e se a validação ",
      "tem condições ambientais que o treino não viu. Esses são os motivos mais comuns de AUC baixa e omissão alta."),
    actionButton("rodar_diag", "Rodar diagnóstico", class = "btn-primary"),
    br(), br(),
    uiOutput("diag_pasta"),
    navset_card_tab(
      nav_panel("Explicação", verbatimTextOutput("diag_texto")),
      nav_panel("Por propriedade", plotOutput("g01", height = 550), DTOutput("t01")),
      nav_panel("Por UPA", DTOutput("t02")),
      nav_panel("Concentração", layout_columns(plotOutput("g02"), DTOutput("t03"))),
      nav_panel("Folds", layout_columns(plotOutput("g03"), plotOutput("g06")), DTOutput("t04"),
                h6("Novidade ambiental (% de presenças de validação fora da amplitude do treino)"), DTOutput("t05"),
                h6("Solo por fold"), DTOutput("t06")),
      nav_panel("Mapa", plotOutput("g04", height = 550)),
      nav_panel("Ambiente", plotOutput("g05", height = 500), DTOutput("t07"),
                caixa_ajuda("KS_D: diferença entre as distribuições de presença e background (0 = iguais, 1 = totalmente diferentes). ",
                            "Com milhares de pontos o p-valor quase sempre é baixo; olhe o tamanho do D.")),
      nav_panel("Agrupamento", DTOutput("t08"))
    )
  ),
  nav_panel("2. Treino / Validação", caixa_ajuda("Em construção (etapa E2).")),
  nav_panel("3. Variáveis", caixa_ajuda("Em construção (etapa E3).")),
  nav_panel("4. Background e parâmetros", caixa_ajuda("Em construção (etapa E4).")),
  nav_panel("5. Treinamento", caixa_ajuda("Em construção (etapa E5).")),
  nav_panel("6. Validação", caixa_ajuda("Em construção (etapa E6).")),
  nav_panel("Ajuda", card(includeMarkdown("docs/AJUDA.md")))
)

server <- function(input, output, session) {
  diag <- reactiveVal(NULL)
  observeEvent(input$especie, diag(NULL))

  observeEvent(input$rodar_diag, {
    withProgress(message = "Analisando os dados...", value = 0.3, {
      r <- tryCatch(diagnosticar_especie(carregar_dados_especie(input$especie)),
                    error = function(e) { showNotification(paste("Erro:", conditionMessage(e)), type = "error", duration = NULL); NULL })
      diag(r)
    })
    if (!is.null(diag())) showNotification("Diagnóstico concluído e salvo.", type = "message")
  })

  output$diag_pasta <- renderUI({ req(diag()); caixa_ajuda(strong("Arquivos salvos em: "), code(diag()$pasta)) })
  output$diag_texto <- renderText({ req(diag()); paste(diag()$texto, collapse = "\n") })
  for (g in c("01", "02", "03", "04", "05", "06")) local({
    gg <- g
    output[[paste0("g", gg)]] <- renderPlot({ req(diag()); diag()$graficos[[grep(paste0("^G", gg), names(diag()$graficos))]] })
  })
  for (t in c("01", "02", "03", "04", "05", "06", "07", "08")) local({
    tt <- t
    output[[paste0("t", tt)]] <- renderDT({ req(diag()); tabela(diag()$tabelas[[grep(paste0("^", tt), names(diag()$tabelas))]]) })
  })
}

shinyApp(ui, server)
