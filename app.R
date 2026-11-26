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
source("R/06_SELECAO_VARIAVEIS.R", encoding = "UTF-8")
source("R/07_BACKGROUND_E_PARAMETROS.R", encoding = "UTF-8")
source("R/08_TREINAMENTO.R", encoding = "UTF-8")
source("R/09_VALIDACAO.R", encoding = "UTF-8")
suppressPackageStartupMessages({ library(shiny); library(bslib); library(DT) })

caixa_ajuda <- function(...) div(class = "alert alert-info", style = "font-size:0.92em", ...)
tabela <- function(df) datatable(df, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE))

# CSS: textos maiores e legiveis; pagina ROLA normalmente (nada fica cortado)
estilo <- tags$style(HTML("
  body { font-size: 15px; }
  .navbar .nav-link { font-size: 15px; padding-left: .55rem !important; padding-right: .55rem !important; }
  .seletor-especie { display: flex; align-items: center; gap: .6rem; color: #fff; margin: 0 .5rem; }
  .seletor-especie .form-group { margin: 0; }
  .seletor-especie label, .seletor-especie .radio-inline { color: #fff !important; font-weight: 600; }
  .bslib-sidebar-layout > .sidebar { font-size: 14px; }
  .card { margin-bottom: 1rem; }
  .card-body { overflow: visible; }
  pre.shiny-text-output { white-space: pre-wrap; word-break: break-word; font-size: 13.5px; max-height: none; }
  .alert { margin-bottom: .5rem; }
  .btn { margin: .2rem 0; width: 100%; }
  .card .btn { width: auto; margin-right: .4rem; }
"))

ui <- page_navbar(
  title = "Ipês – TCC UFRA",
  theme = bs_theme(bootswatch = "flatly"),
  fillable = FALSE,                       # nao espreme o conteudo na altura da janela
  header = estilo,
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
  nav_panel("3. Variáveis",
    layout_sidebar(fillable = FALSE,
      sidebar = sidebar(width = 300,
        caixa_ajuda("Usa o plano da aba 2 (só o TREINO). Mostra variáveis redundantes e recomenda quais manter. Você decide marcando as caixas."),
        radioButtons("var_metodo", "Correlação usada na regra", c("Maior |r| das duas (rigoroso)" = "maior", "Spearman (robusta)" = "spearman", "Pearson (linear)" = "pearson")),
        sliderInput("var_r", "Limiar |r|", 0.5, 0.9, 0.7, 0.05),
        selectInput("var_vif", "Limiar VIF", c("5 (conservador)" = 5, "10 (tolerante)" = 10)),
        actionButton("var_analisar", "Analisar variáveis", class = "btn-primary"), hr(),
        checkboxGroupInput("var_escolha", "Variáveis que entram no modelo", choices = setNames(names(VARIAVEIS), VARIAVEIS)),
        actionButton("var_salvar", "Salvar escolha", class = "btn-success"),
        uiOutput("var_pasta")),
      uiOutput("var_avisos"),
      navset_card_tab(
        nav_panel("Recomendação", verbatimTextOutput("var_just"), DTOutput("var_rec")),
        nav_panel("Correlação", plotOutput("var_g1", height = 450)),
        nav_panel("VIF e solo", layout_columns(plotOutput("var_g2"), DTOutput("var_eta"))),
        nav_panel("Presença × background", plotOutput("var_g3", height = 500)),
        nav_panel("AUC univariada", plotOutput("var_g4"))
      ))),
  nav_panel("4. Background e parâmetros",
    layout_sidebar(fillable = FALSE,
      sidebar = sidebar(width = 320,
        caixa_ajuda("Usa o plano (aba 2) e as variáveis salvas (aba 3)."),
        h6("Background"),
        radioButtons("bg_origem", NULL, c("Reaproveitar B2 (recomendado)" = "b2", "Novo sorteio" = "novo")),
        numericInput("bg_n", "Nº de pontos no treino (vazio = todo o B2)", NA, min = 500, step = 500),
        numericInput("bg_semente", "Semente (reprodutível)", SEMENTE_PADRAO),
        conditionalPanel("input.bg_origem == 'novo'", checkboxInput("bg_val", "Novo sorteio também na validação (mesma densidade)", FALSE)),
        actionButton("bg_preparar", "Preparar background", class = "btn-primary"), hr(),
        h6("Parâmetros do maxnet"),
        checkboxGroupInput("par_fc", "Features", FEATURES_DISPONIVEIS, selected = recomendar_grade()$features),
        textInput("par_rm", "RM (separe por vírgula)", "0.5, 1, 2, 3, 4"),
        checkboxInput("par_clamp", "Clamping (recomendado)", TRUE),
        checkboxInput("par_jk", "Incluir Jackknife na estimativa", TRUE),
        actionButton("par_estimar", "Estimar tempo e memória", class = "btn-warning"),
        actionButton("par_salvar", "Salvar configuração", class = "btn-success"),
        uiOutput("par_pasta")),
      uiOutput("par_avisos"),
      navset_card_tab(
        nav_panel("Recomendação", verbatimTextOutput("bg_rec")),
        nav_panel("Background", DTOutput("bg_resumo"), plotOutput("bg_mapa", height = 550)),
        nav_panel("Grade e custo", DTOutput("par_grade"), DTOutput("par_custo"))
      ))),
  nav_panel("5. Treinamento",
    layout_sidebar(fillable = FALSE,
      sidebar = sidebar(width = 320,
        caixa_ajuda("Roda todos os modelos da grade na validação cruzada por folds. Feche outros programas antes (pouca RAM)."),
        selectInput("tr_cfg", "Configuração salva (aba 4)", choices = NULL),
        actionButton("tr_rodar", "Rodar todos os modelos", class = "btn-primary"), hr(),
        uiOutput("tr_escolhido"),
        helpText("Para escolher outro modelo, clique numa linha da tabela 'Modelos'."),
        actionButton("tr_jk", "Rodar Jackknife + curva ROC", class = "btn-warning"),
        actionButton("tr_salvar", "Salvar treinamento", class = "btn-success"),
        uiOutput("tr_pasta")),
      uiOutput("tr_avisos"),
      navset_card_tab(
        nav_panel("Composição dos folds (TCC)", DTOutput("tr_comp")),
        nav_panel("Modelos", plotOutput("tr_g1", height = 420), DTOutput("tr_resumo")),
        nav_panel("Métricas por fold", DTOutput("tr_fold")),
        nav_panel("Erros e avisos", DTOutput("tr_erros")),
        nav_panel("Jackknife", plotOutput("tr_g2", height = 450), DTOutput("tr_jk_tab")),
        nav_panel("Curva ROC", plotOutput("tr_g3", height = 600))
      ))),
  nav_panel("6. Validação",
    layout_sidebar(fillable = FALSE,
      sidebar = sidebar(width = 320,
        caixa_ajuda("Avalia o modelo escolhido (aba 5) nas unidades de VALIDAÇÃO do plano, que o modelo nunca viu."),
        selectInput("va_modelo", "Treinamento salvo (aba 5)", choices = NULL),
        uiOutput("va_situacao"),
        radioButtons("va_mapas", "Mapas .tif para o QGIS", c("Só propriedades de validação" = "validacao",
                     "Todas as propriedades" = "todas", "Nenhum" = "nenhum")),
        actionButton("va_rodar", "Validar", class = "btn-primary"),
        actionButton("va_salvar", "Salvar + exportar", class = "btn-success"),
        uiOutput("va_pasta")),
      uiOutput("va_avisos"),
      navset_card_tab(
        nav_panel("Treino × validação", DTOutput("va_comp"), plotOutput("va_g1", height = 600)),
        nav_panel("Por unidade", plotOutput("va_g2", height = 400), DTOutput("va_unid")),
        nav_panel("Novidade ambiental", DTOutput("va_nov")),
        nav_panel("Notas", plotOutput("va_g3", height = 500)),
        nav_panel("Mapa de acertos", plotOutput("va_g4", height = 600))
      ))),
  nav_panel("Ajuda", card(caixa_ajuda("Dados lidos de: ", code(PASTA_DADOS)), includeMarkdown("docs/AJUDA.md"))),
  nav_spacer(),
  nav_item(div(class = "seletor-especie",
    radioButtons("especie", "Espécie:", inline = TRUE, choices = c("Ipê-roxo" = "roxo", "Ipê-amarelo" = "amarelo"))))
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
    output[[paste0("g", gg)]] <- renderPlot({ req(diag()); diag()$graficos[[grep(paste0("^G", gg), names(diag()$graficos))]] }, res = 110)
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
  output$sel_mapa <- renderPlot({ req(plano_atual()); grafico_mapa_plano(plano_atual(), base_atual()) }, res = 110)
  output$sel_prox <- renderDT({ req(plano_atual()$proximidade); tabela(plano_atual()$proximidade) })
  # ---- Etapa 3: variaveis ------------------------------------------------------
  estado$var <- list(); estado$escolha_var <- list(); estado$pasta_var <- list()
  var_atual <- reactive(estado$var[[input$especie]])
  observeEvent(input$var_analisar, {
    if (is.null(plano_atual())) return(showNotification("Primeiro gere (ou aplique) um plano na aba 2.", type = "warning"))
    r <- executar(withProgress(message = "Calculando correlação, VIF e AUC univariada...", value = 0.5,
      analisar_variaveis(plano_atual(), base_atual(), input$var_r, as.numeric(input$var_vif), input$var_metodo)))
    if (!is.null(r)) { estado$var[[input$especie]] <- r; updateCheckboxGroupInput(session, "var_escolha", selected = r$recomendadas) }
  })
  output$var_avisos <- renderUI({
    req(var_atual()); av <- checar_escolha(var_atual(), input$var_escolha %||% character())
    tagList(lapply(av, function(a) div(class = paste("alert", if (startsWith(a, "CRITICO")) "alert-danger"
      else if (startsWith(a, "ATENCAO")) "alert-warning" else if (startsWith(a, "OK")) "alert-success" else "alert-secondary"),
      style = "padding:6px;margin:4px 0;font-size:0.9em", a)))
  })
  observeEvent(input$var_salvar, {
    req(var_atual()); esc <- input$var_escolha %||% character()
    if (length(esc) < 2) return(showNotification("Escolha pelo menos 2 variáveis.", type = "error"))
    pasta <- executar(salvar_variaveis(var_atual(), esc, estado$pasta_plano[[input$especie]] %||% NA))
    if (!is.null(pasta)) { estado$escolha_var[[input$especie]] <- esc; estado$pasta_var[[input$especie]] <- pasta
      showNotification("Escolha de variáveis salva.", type = "message") }
  })
  output$var_pasta <- renderUI({ p <- estado$pasta_var[[input$especie]]; req(p); caixa_ajuda(strong("Salvo em: "), code(p)) })
  output$var_just <- renderText({ req(var_atual()); paste(var_atual()$justificativa, collapse = "
") })
  output$var_rec <- renderDT({ req(var_atual()); tabela(var_atual()$recomendacao[, -1]) })
  output$var_eta <- renderDT({ req(var_atual()); tabela(transform(var_atual()$eta, eta_com_solo = round(eta_com_solo, 3))) })
  output$var_g1 <- renderPlot({ req(var_atual()); grafico_correlacao(var_atual()) }, res = 110)
  output$var_g2 <- renderPlot({ req(var_atual()); grafico_vif(var_atual()) }, res = 110)
  output$var_g3 <- renderPlot({ req(var_atual()); grafico_densidades(var_atual()) }, res = 110)
  output$var_g4 <- renderPlot({ req(var_atual()); grafico_auc_univ(var_atual()) }, res = 110)
  # ---- Etapa 4: background e parametros ----------------------------------------
  estado$bg <- list(); estado$custo <- list(); estado$pasta_cfg <- list()
  observeEvent(list(input$especie, plano_atual()), {
    if (is.null(plano_atual())) return()
    rb <- executar(recomendar_background(plano_atual(), base_atual()))
    if (!is.null(rb)) updateNumericInput(session, "bg_n", value = rb$n)
  })
  output$bg_rec <- renderText({
    req(plano_atual()); rb <- recomendar_background(plano_atual(), base_atual())
    paste(c("BACKGROUND", rb$texto, "", "PARAMETROS", recomendar_grade()$texto), collapse = "
")
  })
  rm_vetor <- reactive(suppressWarnings(as.numeric(trimws(strsplit(input$par_rm, "[,;]")[[1]]))))
  grade_atual <- reactive({ r <- rm_vetor(); req(length(input$par_fc), length(r), !anyNA(r)); grade_parametros(input$par_fc, r) })
  observeEvent(input$bg_preparar, {
    if (is.null(plano_atual())) return(showNotification("Gere um plano na aba 2 primeiro.", type = "warning"))
    n <- if (is.na(input$bg_n)) NULL else input$bg_n
    if (input$bg_origem == "novo" && is.null(n)) return(showNotification("Informe o nº de pontos do novo sorteio.", type = "error"))
    b <- executar(withProgress(message = "Preparando background...", value = 0.5,
      preparar_background(plano_atual(), base_atual(), input$bg_origem, n, input$bg_semente, isTRUE(input$bg_val))))
    if (!is.null(b)) { estado$bg[[input$especie]] <- b; showNotification("Background pronto.", type = "message") }
  })
  variaveis_escolhidas <- reactive(estado$escolha_var[[input$especie]] %||% var_atual()$recomendadas)
  observeEvent(input$par_estimar, {
    b <- estado$bg[[input$especie]]; if (is.null(b)) return(showNotification("Prepare o background primeiro.", type = "warning"))
    if (is.null(variaveis_escolhidas())) return(showNotification("Analise/salve as variáveis na aba 3.", type = "warning"))
    pr <- marcar_papel(base_atual()$presencas, plano_atual()); pr <- pr[pr$papel %in% "treino", ]
    k <- length(unique(stats::na.omit(plano_atual()$unidades$fold[plano_atual()$unidades$papel == "treino"])))
    c1 <- executar(withProgress(message = "Cronometrando 1 ajuste de cada feature...", value = 0.5,
      estimar_custo(pr, b$treino, variaveis_escolhidas(), grade_atual(), k, input$par_jk)))
    if (!is.null(c1)) estado$custo[[input$especie]] <- c1
  })
  observeEvent(input$par_salvar, {
    b <- estado$bg[[input$especie]]; req(b, variaveis_escolhidas())
    pasta <- executar(salvar_config(input$especie, plano_atual(), base_atual(), b, variaveis_escolhidas(), grade_atual(),
                                    input$par_clamp, estado$custo[[input$especie]], estado$pasta_plano[[input$especie]] %||% NA,
                                    estado$pasta_var[[input$especie]] %||% NA))
    if (!is.null(pasta)) { estado$pasta_cfg[[input$especie]] <- pasta; showNotification("Configuração salva.", type = "message") }
  })
  output$par_pasta <- renderUI({ p <- estado$pasta_cfg[[input$especie]]; req(p); caixa_ajuda(strong("Salvo em: "), code(p)) })
  output$par_avisos <- renderUI({
    av <- c(if (is.null(estado$escolha_var[[input$especie]])) "ATENCAO: variáveis ainda não salvas na aba 3 (usando a recomendação).",
            estado$custo[[input$especie]]$avisos)
    req(length(av))
    tagList(lapply(av, function(a) div(class = paste("alert", if (startsWith(a, "CRITICO")) "alert-danger"
      else if (startsWith(a, "ATENCAO")) "alert-warning" else "alert-secondary"), style = "padding:6px;margin:4px 0;font-size:0.9em", a)))
  })
  output$bg_resumo <- renderDT({ b <- estado$bg[[input$especie]]; req(b); tabela(b$resumo) })
  output$bg_mapa <- renderPlot({ b <- estado$bg[[input$especie]]; req(b); grafico_background(b, base_atual(), plano_atual()) }, res = 110)
  output$par_grade <- renderDT(tabela(grade_atual()))
  output$par_custo <- renderDT({ c1 <- estado$custo[[input$especie]]; req(c1); tabela(c1$tabela) })
  # ---- Etapa 5: treinamento ------------------------------------------------------
  estado$tr <- list(); estado$escolhido <- list(); estado$jk <- list(); estado$roc <- list(); estado$pasta_tr <- list()
  observe({
    estado$pasta_cfg[[input$especie]]
    pastas <- rev(list.dirs(file.path(PASTA_RESULTADOS, input$especie, "04_parametros"), recursive = FALSE))
    pastas <- pastas[file.exists(file.path(pastas, "CONFIG_MODELAGEM.rds"))]
    updateSelectInput(session, "tr_cfg", choices = setNames(pastas, basename(pastas)))
  })
  tr_atual <- reactive(estado$tr[[input$especie]])
  escolhido <- reactive(estado$escolhido[[input$especie]] %||% tr_atual()$recomendado)
  observeEvent(input$tr_rodar, {
    req(input$tr_cfg); cfg <- readRDS(file.path(input$tr_cfg, "CONFIG_MODELAGEM.rds"))
    if (cfg$especie != input$especie) return(showNotification("Essa configuração é de outra espécie.", type = "error"))
    tr <- executar(withProgress(message = "Treinando modelos...", value = 0, {
      rodar_grade(cfg, base_atual(), function(i, n, m) setProgress(i / n, detail = sprintf("%d/%d %s", i, n, m)))
    }))
    if (!is.null(tr)) { tr$pasta_cfg <- input$tr_cfg; estado$tr[[input$especie]] <- tr; estado$escolhido[[input$especie]] <- NULL
      estado$jk[[input$especie]] <- NULL; estado$roc[[input$especie]] <- NULL
      showNotification(sprintf("Grade concluída em %.1f min.", tr$minutos), type = "message") }
  })
  observeEvent(input$tr_resumo_rows_selected, {
    req(tr_atual()); estado$escolhido[[input$especie]] <- tr_atual()$resumo$modelo[input$tr_resumo_rows_selected]
    estado$jk[[input$especie]] <- NULL; estado$roc[[input$especie]] <- NULL
  })
  observeEvent(input$tr_jk, {
    req(tr_atual())
    withProgress(message = "Jackknife...", value = 0, {
      jk <- executar(rodar_jackknife(tr_atual(), escolhido(), base_atual(), function(i, n, m) setProgress(i / n, detail = m)))
      setProgress(1, detail = "Curva ROC"); roc <- executar(roc_modelo(tr_atual(), escolhido(), base_atual()))
    })
    estado$jk[[input$especie]] <- jk; estado$roc[[input$especie]] <- roc
  })
  observeEvent(input$tr_salvar, {
    req(tr_atual())
    pasta <- executar(salvar_treino(tr_atual(), escolhido(), estado$jk[[input$especie]], estado$roc[[input$especie]], tr_atual()$pasta_cfg))
    if (!is.null(pasta)) { estado$pasta_tr[[input$especie]] <- pasta; showNotification("Treinamento salvo.", type = "message") }
  })
  output$tr_escolhido <- renderUI({ req(tr_atual())
    caixa_ajuda(strong("Modelo escolhido: "), escolhido(), if (escolhido() == tr_atual()$recomendado) " (recomendado)" else " (diferente do recomendado)") })
  output$tr_pasta <- renderUI({ p <- estado$pasta_tr[[input$especie]]; req(p); caixa_ajuda(strong("Salvo em: "), code(p)) })
  output$tr_avisos <- renderUI({ req(tr_atual())
    tagList(lapply(tr_atual()$justificativa, function(a) div(class = paste("alert", if (startsWith(a, "ATENCAO")) "alert-warning"
      else if (startsWith(a, "RECOMENDADO")) "alert-success" else "alert-secondary"), style = "padding:6px;margin:4px 0;font-size:0.9em", a))) })
  output$tr_comp <- renderDT({ req(tr_atual()); tabela(tr_atual()$composicao) })
  output$tr_resumo <- renderDT({ req(tr_atual())
    datatable(tr_atual()$resumo, rownames = FALSE, selection = "single", options = list(pageLength = 20, scrollX = TRUE)) })
  output$tr_fold <- renderDT({ req(tr_atual()); tabela(tr_atual()$metricas_fold) })
  output$tr_erros <- renderDT({ req(tr_atual()); tabela(tr_atual()$erros_avisos) })
  output$tr_g1 <- renderPlot({ req(tr_atual()); grafico_modelos(tr_atual(), escolhido()) }, res = 110)
  output$tr_g2 <- renderPlot({ jk <- estado$jk[[input$especie]]; req(jk); grafico_jackknife(jk, escolhido()) }, res = 110)
  output$tr_jk_tab <- renderDT({ jk <- estado$jk[[input$especie]]; req(jk); tabela(jk) })
  output$tr_g3 <- renderPlot({ r <- estado$roc[[input$especie]]; req(r); grafico_roc(r, paste("Curva ROC -", escolhido())) }, res = 110)
  # ---- Etapa 6: validacao ----------------------------------------------------------
  estado$va <- list(); estado$pasta_va <- list()
  observe({
    estado$pasta_tr[[input$especie]]
    pastas <- rev(list.dirs(file.path(PASTA_RESULTADOS, input$especie, "05_treino"), recursive = FALSE))
    pastas <- pastas[file.exists(file.path(pastas, "MODELO_ESCOLHIDO.rds"))]
    rot <- sapply(pastas, function(p) paste(basename(p), "-", readRDS(file.path(p, "MODELO_ESCOLHIDO.rds"))$modelo))
    updateSelectInput(session, "va_modelo", choices = setNames(pastas, rot))
  })
  me_atual <- reactive({ req(input$va_modelo); readRDS(file.path(input$va_modelo, "MODELO_ESCOLHIDO.rds")) })
  sit_atual <- reactive({ input$va_rodar; situacao_teste_externo(me_atual(), base_atual()) })
  output$va_situacao <- renderUI({
    s <- sit_atual()
    tagList(div(class = paste("alert", if (s$confirmatorio) "alert-danger" else "alert-info"), style = "font-size:0.88em", s$texto),
            if (s$confirmatorio) checkboxInput("va_confirmo", "Confirmo: todas as escolhas estão finais e quero abrir o TESTE EXTERNO.", FALSE))
  })
  va_atual <- reactive(estado$va[[input$especie]])
  observeEvent(input$va_rodar, {
    va <- executar(withProgress(message = "Validando...", value = 0.5,
      validar_modelo(me_atual(), base_atual(), input$va_modelo, isTRUE(input$va_confirmo))))
    if (!is.null(va)) estado$va[[input$especie]] <- va
  })
  observeEvent(input$va_salvar, {
    req(va_atual())
    pasta <- executar(withProgress(message = "Salvando e gerando mapas...", value = 0.5, salvar_validacao(va_atual(), base_atual(), input$va_mapas)))
    if (!is.null(pasta)) { estado$pasta_va[[input$especie]] <- pasta; showNotification("Validação salva.", type = "message") }
  })
  output$va_pasta <- renderUI({ p <- estado$pasta_va[[input$especie]]; req(p); caixa_ajuda(strong("Salvo em: "), code(p)) })
  output$va_avisos <- renderUI({ req(va_atual())
    tagList(lapply(va_atual()$avisos, function(a) div(class = paste("alert", if (startsWith(a, "ATENCAO")) "alert-warning" else "alert-secondary"),
                                                      style = "padding:6px;margin:4px 0;font-size:0.9em", a))) })
  output$va_comp <- renderDT({ req(va_atual()); d <- va_atual()$comparacao; d[-1] <- lapply(d[-1], round, 3); tabela(d) })
  output$va_unid <- renderDT({ req(va_atual()); d <- va_atual()$por_unidade; n <- sapply(d, is.numeric); d[n] <- lapply(d[n], round, 3); tabela(d) })
  output$va_nov <- renderDT({ req(va_atual()); tabela(va_atual()$novidade) })
  output$va_g1 <- renderPlot({ req(va_atual()); grafico_roc(va_atual()$roc, paste("Curva ROC -", va_atual()$modelo)) }, res = 110)
  output$va_g2 <- renderPlot({ req(va_atual()); grafico_auc_unidade(va_atual()) }, res = 110)
  output$va_g3 <- renderPlot({ req(va_atual()); grafico_notas(va_atual()) }, res = 110)
  output$va_g4 <- renderPlot({ req(va_atual()); grafico_acertos(va_atual()) }, res = 110)
}

shinyApp(ui, server)
