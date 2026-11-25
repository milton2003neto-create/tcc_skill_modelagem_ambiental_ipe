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
source("R/04_PREPARAR_PROPRIEDADES_RESERVADAS.R", encoding = "UTF-8")
source("R/05_SELECAO_TREINO_VALIDACAO.R", encoding = "UTF-8")
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
  nav_panel("2. Treino / Validação",
    caixa_ajuda(
      strong("O que esta etapa faz? "), "Separa quem o modelo vai ", strong("estudar"), " (treino) e quem vai servir de ",
      strong("prova"), " (validação). O treino ainda é dividido em ", strong("folds"),
      " (grupos que se revezam como mini-prova) para escolher a melhor configuração. ",
      "Uma unidade nunca fica em treino e validação ao mesmo tempo.", br(),
      strong("Propriedade × propriedade: "), "testa se o modelo funciona numa fazenda que ele nunca viu (mais rigoroso). ",
      strong("UPA × UPA: "), "testa transferência local, entre UPAs (uma fazenda pode ter UPAs nos dois lados), como Ferreira (2009)."),
    layout_columns(col_widths = c(4, 8),
      card(card_header("1) Recomendação"),
        radioButtons("sel_modo", "Desenho", c("Propriedade × propriedade" = "propriedade", "UPA × UPA" = "upa")),
        checkboxInput("sel_reserv", "Usar as 7 propriedades reservadas como validação", FALSE),
        numericInput("sel_pct", "% alvo das presenças na validação", 25, 5, 60, 5),
        numericInput("sel_min", "Mínimo de presenças por unidade de validação", 30, 5, 500, 5),
        numericInput("sel_k", "Nº de folds internos no treino", 3, 2, 10, 1),
        actionButton("sel_recomendar", "Gerar recomendação", class = "btn-primary")),
      card(card_header("Justificativa e avisos"), verbatimTextOutput("sel_just"), uiOutput("sel_avisos"))),
    card(card_header("2) Suas escolhas (opcional – mude o que quiser)"),
      layout_columns(
        selectizeInput("sel_val", "Unidades de VALIDAÇÃO", NULL, multiple = TRUE, width = "100%"),
        selectizeInput("sel_tr", "Unidades de TREINO", NULL, multiple = TRUE, width = "100%"),
        selectizeInput("sel_exc", "EXCLUIR (não usar)", NULL, multiple = TRUE, width = "100%")),
      helpText("O que não estiver em nenhuma lista fica 'reservado' (protegido). Para mudar o fold de uma unidade de treino, ",
               "dê dois cliques na coluna 'fold' da tabela abaixo."),
      actionButton("sel_aplicar", "Aplicar minhas escolhas", class = "btn-warning"),
      actionButton("sel_salvar", "Salvar plano (usar nas próximas etapas)", class = "btn-success")),
    uiOutput("sel_pasta"),
    navset_card_tab(
      nav_panel("Composição dos folds (para o TCC)", DTOutput("sel_comp")),
      nav_panel("Unidades", DTOutput("sel_unid")),
      nav_panel("Mapa", plotOutput("sel_mapa", height = 600)),
      nav_panel("Proximidade", DTOutput("sel_prox"),
                caixa_ajuda("Distância mínima entre pontos de cada unidade de validação e pontos de treino. ",
                            "Abaixo de ~1 km o ambiente é praticamente o mesmo: a validação mede transferência local, não independente.")))
  ),
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

  # ---- Etapa 2: selecao treino / validacao -----------------------------------
  # 'estado' guarda, por especie, a base completa e o plano (usado nas etapas seguintes)
  estado <- reactiveValues(base = list(), plano = list(), pasta_plano = list())
  base_atual <- reactive({
    e <- input$especie
    if (is.null(estado$base[[e]])) withProgress(message = "Carregando dados (inclui as 7 reservadas)...", value = 0.5,
                                                estado$base[[e]] <- carregar_base_completa(e))
    estado$base[[e]]
  })
  plano_atual <- reactive(estado$plano[[input$especie]])

  atualizar_listas <- function(p) {
    u <- p$unidades; ch <- u$unidade
    updateSelectizeInput(session, "sel_val", choices = ch, selected = ch[u$papel == "validacao"])
    updateSelectizeInput(session, "sel_tr", choices = ch, selected = ch[u$papel == "treino"])
    updateSelectizeInput(session, "sel_exc", choices = ch, selected = ch[u$papel == "excluida"])
  }
  executar <- function(expr) tryCatch(expr, error = function(e) {
    showNotification(paste("Erro:", conditionMessage(e)), type = "error", duration = NULL); NULL })

  observeEvent(input$sel_recomendar, {
    p <- executar(withProgress(message = "Calculando recomendação...", value = 0.5,
      recomendar_plano(base_atual(), input$sel_modo, input$sel_pct, input$sel_min, input$sel_reserv, input$sel_k)))
    if (!is.null(p)) { estado$plano[[input$especie]] <- p; atualizar_listas(p) }
  })
  # impede a mesma unidade em duas listas: a ultima escolha vence
  observeEvent(input$sel_val, {
    tr <- setdiff(input$sel_tr, input$sel_val); ex <- setdiff(input$sel_exc, input$sel_val)
    if (!identical(tr, input$sel_tr)) updateSelectizeInput(session, "sel_tr", selected = tr)
    if (!identical(ex, input$sel_exc)) updateSelectizeInput(session, "sel_exc", selected = ex)
  }, ignoreNULL = FALSE)
  observeEvent(input$sel_tr, {
    va <- setdiff(input$sel_val, input$sel_tr); ex <- setdiff(input$sel_exc, input$sel_tr)
    if (!identical(va, input$sel_val)) updateSelectizeInput(session, "sel_val", selected = va)
    if (!identical(ex, input$sel_exc)) updateSelectizeInput(session, "sel_exc", selected = ex)
  }, ignoreNULL = FALSE)
  observeEvent(input$sel_exc, {
    va <- setdiff(input$sel_val, input$sel_exc); tr <- setdiff(input$sel_tr, input$sel_exc)
    if (!identical(va, input$sel_val)) updateSelectizeInput(session, "sel_val", selected = va)
    if (!identical(tr, input$sel_tr)) updateSelectizeInput(session, "sel_tr", selected = tr)
  }, ignoreNULL = FALSE)

  folds_editados <- reactiveVal(integer())
  observeEvent(input$sel_unid_cell_edit, {
    ed <- input$sel_unid_cell_edit; u <- plano_atual()$unidades
    f <- folds_editados(); f[u$unidade[ed$row]] <- as.integer(ed$value); folds_editados(f)
  })
  observeEvent(input$sel_aplicar, {
    req(plano_atual())
    p <- executar(editar_plano(plano_atual(), base_atual(), validacao = input$sel_val %||% character(),
                               treino = input$sel_tr %||% character(), excluir = input$sel_exc %||% character(),
                               folds_manuais = folds_editados(), k_folds = input$sel_k))
    if (!is.null(p)) { estado$plano[[input$especie]] <- p; folds_editados(integer()); atualizar_listas(p)
      showNotification("Escolhas aplicadas. Confira os avisos.", type = "message") }
  })
  observeEvent(input$sel_salvar, {
    req(plano_atual())
    pasta <- executar(salvar_plano(plano_atual(), base_atual()))
    if (!is.null(pasta)) { estado$pasta_plano[[input$especie]] <- pasta; showNotification("Plano salvo.", type = "message") }
  })
  output$sel_pasta <- renderUI({ p <- estado$pasta_plano[[input$especie]]; req(p); caixa_ajuda(strong("Plano salvo em: "), code(p)) })
  output$sel_just <- renderText({ req(plano_atual()); paste(c(paste("Origem:", plano_atual()$origem), plano_atual()$justificativa), collapse = "\n\n") })
  output$sel_avisos <- renderUI({
    req(plano_atual()); av <- plano_atual()$avisos
    tagList(lapply(av, function(a) div(class = paste("alert", if (startsWith(a, "CRITICO")) "alert-danger"
                                                     else if (startsWith(a, "ATENCAO")) "alert-warning" else "alert-secondary"),
                                       style = "padding:6px;margin:4px 0;font-size:0.9em", a)))
  })
  output$sel_comp <- renderDT({ req(plano_atual()); tabela(plano_atual()$composicao) })
  output$sel_unid <- renderDT({
    req(plano_atual()); u <- plano_atual()$unidades
    datatable(u[, c("unidade", "propriedade", "papel", "fold", "n_presencas", "n_background", "reservada", "fold_original", "gradiente_pc1")],
              rownames = FALSE, editable = list(target = "cell", disable = list(columns = c(0:2, 4:8))),
              options = list(pageLength = 20, scrollX = TRUE))
  })
  output$sel_mapa <- renderPlot({ req(plano_atual()); grafico_mapa_plano(plano_atual(), base_atual()) })
  output$sel_prox <- renderDT({ req(plano_atual()$proximidade); tabela(plano_atual()$proximidade) })
}

shinyApp(ui, server)
