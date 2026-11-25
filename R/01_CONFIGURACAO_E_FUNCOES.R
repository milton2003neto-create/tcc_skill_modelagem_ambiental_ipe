# =============================================================================
# 01_CONFIGURACAO_E_FUNCOES.R
# -----------------------------------------------------------------------------
# O QUE FAZ: define onde estao os dados do TCC, onde os resultados serao
#            salvos e funcoes auxiliares usadas por todos os outros scripts
#            (criar pastas organizadas, registrar log das escolhas, etc.).
# ENTRADAS : nenhuma (opcionalmente "config_local.R" para mudar caminhos).
# SAIDAS   : objetos CAMINHOS, ARQUIVOS e funcoes auxiliares na memoria do R.
# COMO USAR: e carregado automaticamente pelos demais scripts e pelo app.
# =============================================================================

# ---- 1. Pasta da ferramenta (onde este projeto esta) ------------------------
# Procura a pasta raiz do projeto (a que contem "FerramentaIpes.Rproj").
localizar_raiz_projeto <- function() {
  candidatos <- c(getwd(), dirname(getwd()))
  for (p in candidatos) {
    if (file.exists(file.path(p, "FerramentaIpes.Rproj"))) return(normalizePath(p, winslash = "/"))
  }
  stop("Nao encontrei a pasta da ferramenta. Abra o arquivo 'FerramentaIpes.Rproj' no RStudio ",
       "(ou use setwd() na pasta do projeto) e rode novamente.")
}
RAIZ_PROJETO <- localizar_raiz_projeto()

# ---- 2. Pasta dos dados do TCC -----------------------------------------------
# Padrao: a pasta "TCC - Ipes - Inicio do zero" fica dois niveis acima:
#   tcc milton/
#     |- TCC - Ipes - Inicio do zero/   <- dados (QGIS, CSVs, rasters)
#     |- github/tcc_skill_modelagem_ambiental_ipe/  <- esta ferramenta
# Em outro computador, crie "config_local.R" na raiz com:
#   PASTA_DADOS <- "C:/caminho/para/TCC - Ipes - Inicio do zero"
PASTA_DADOS <- file.path(dirname(dirname(RAIZ_PROJETO)), "TCC - Ipes - Inicio do zero")
if (file.exists(file.path(RAIZ_PROJETO, "config_local.R"))) {
  source(file.path(RAIZ_PROJETO, "config_local.R"), encoding = "UTF-8")
}
PASTA_DADOS <- normalizePath(PASTA_DADOS, winslash = "/", mustWork = FALSE)

# ---- 2b. Pandoc (usado para gerar .docx) --------------------------------------
# Dentro do RStudio ja funciona; fora dele (Rscript) procuramos o pandoc do RStudio.
if (Sys.getenv("RSTUDIO_PANDOC") == "") {
  for (p in c("C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools",
              "C:/Program Files/RStudio/bin/pandoc",
              "C:/Program Files/RStudio/resources/app/bin/pandoc")) {
    if (file.exists(file.path(p, "pandoc.exe"))) { Sys.setenv(RSTUDIO_PANDOC = p); break }
  }
}

# ---- 3. Arquivos de entrada usados pela ferramenta ---------------------------
# (todos ja produzidos pelas etapas QGIS 01-13 e R01-R19 do TCC)
ARQUIVOS <- list(
  # Presencas: DAP > 10 cm, 1 por especie por pixel de 30 m, 27 propriedades
  presencas      = file.path(PASTA_DADOS, "04 - Dados para o MaxEnt", "04 - Presencas e folds V3",
                             "05_PRESENCAS_UM_POR_PIXEL_30M.csv"),
  # Background B2 (10.000 pontos nas UPAs inventariadas, cotas por UPA - R18)
  background_b2  = file.path(PASTA_DADOS, "05 - Modelagem no R", "R26_TCC_IPES_ELEGIBILIDADE_V1",
                             "01_ENTRADAS_COPIAS", "18_BACKGROUND_B2_10000_COM_FOLDS.csv"),
  # Plano de folds por propriedade (inclui as 7 reservadas como TESTE)
  plano_folds    = file.path(PASTA_DADOS, "05 - Modelagem no R", "01 - Scripts", "05_PLANO_FOLDS_V3.csv"),
  # Distancias entre UPAs (R24) - usadas para avisar sobre UPAs vizinhas
  pares_upas     = file.path(PASTA_DADOS, "05 - Modelagem no R", "R26_TCC_IPES_ELEGIBILIDADE_V1",
                             "01_ENTRADAS_COPIAS", "24_PARES_UPAS_GEOMETRICOS.csv"),
  # Pastas do QGIS: arvores com variaveis (34 propriedades), rasters e mascaras de UPA
  pasta_pontos   = file.path(PASTA_DADOS, "03 - Trabalho no QGIS", "02 - Arquivos gerados", "Pontos com variaveis"),
  pasta_rasters  = file.path(PASTA_DADOS, "03 - Trabalho no QGIS", "02 - Arquivos gerados", "Clima e solo alinhados"),
  pasta_mascaras = file.path(PASTA_DADOS, "03 - Trabalho no QGIS", "02 - Arquivos gerados", "Mascaras UPAs inventariadas V3")
)

# ---- 4. Constantes do estudo -------------------------------------------------
ESPECIES <- c(roxo = "Ipe-roxo", amarelo = "Ipe-amarelo")
VARIAVEIS <- c(
  altitude_m        = "Altitude (m) - ANADEM",
  declividade_graus = "Declividade (graus) - ANADEM",
  dist_rio_raster_m = "Distancia a hidrografia (m)",
  bio12_mm_ano      = "BIO12 Precipitacao anual (mm/ano) - CHELSA 1980-2021",
  bio17_mm_mes      = "BIO17 Precip. trimestre mais seco (mm/mes) - CHELSA",
  textura_subgrupo  = "Textura do solo (categorica) - MapBiomas Solo C3"
)
VARIAVEIS_CATEGORICAS <- "textura_subgrupo"
PROPRIEDADES_RESERVADAS <- c("BARRO BRANCO", "CURUÇA", "GUARIÚBA", "JATOBÁ",
                             "LOTE 01", "MARILIA", "PALMEIRA")
SEMENTE_PADRAO <- 20261125

# ---- 5. Pasta de resultados --------------------------------------------------
# Estrutura: resultados/<especie>/<etapa>/<AAAA-MM-DD_HHMMSS>/
PASTA_RESULTADOS <- file.path(RAIZ_PROJETO, "resultados")

#' Cria (e retorna) a pasta de saida de uma execucao.
#' @param especie "roxo", "amarelo" ou "_geral"
#' @param etapa   ex.: "01_diagnostico", "04_treinamento"
criar_pasta_saida <- function(especie, etapa, carimbo = format(Sys.time(), "%Y-%m-%d_%H%M%S")) {
  p <- file.path(PASTA_RESULTADOS, especie, etapa, carimbo)
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
  normalizePath(p, winslash = "/")
}

#' Registra um log legivel (.txt) e estruturado (.json) com as escolhas feitas.
#' @param pasta   pasta da execucao
#' @param etapa   nome da etapa
#' @param escolhas lista nomeada com tudo que o usuario escolheu
#' @param mensagens vetor de textos (avisos, erros, observacoes)
registrar_log <- function(pasta, etapa, escolhas = list(), mensagens = character()) {
  info <- list(
    etapa       = etapa,
    data_hora   = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    usuario_pc  = Sys.info()[["nodename"]],
    versao_R    = R.version.string,
    pacotes     = versoes_pacotes(),
    pasta_dados = PASTA_DADOS,
    escolhas    = escolhas,
    mensagens   = as.list(mensagens)
  )
  jsonlite::write_json(info, file.path(pasta, "LOG_EXECUCAO.json"), auto_unbox = TRUE, pretty = TRUE)
  linhas <- c(
    paste0("ETAPA: ", etapa), paste0("DATA/HORA: ", info$data_hora),
    paste0("R: ", info$versao_R), paste0("DADOS: ", PASTA_DADOS), "",
    "ESCOLHAS:",
    vapply(names(escolhas), function(n) paste0("  - ", n, ": ",
           paste(format(escolhas[[n]]), collapse = ", ")), ""),
    "", "MENSAGENS:", if (length(mensagens)) paste0("  * ", mensagens) else "  (nenhuma)",
    "", "PACOTES:", paste0("  ", names(info$pacotes), " ", unlist(info$pacotes))
  )
  writeLines(linhas, file.path(pasta, "LOG_EXECUCAO.txt"), useBytes = TRUE)
  invisible(info)
}

PACOTES_NECESSARIOS <- c("shiny", "bslib", "DT", "maxnet", "glmnet", "ecospat", "terra", "sf",
                         "ggplot2", "dplyr", "tidyr", "readr", "jsonlite", "corrplot", "usdm",
                         "rmarkdown")

versoes_pacotes <- function(pk = PACOTES_NECESSARIOS) {
  v <- vapply(pk, function(p) tryCatch(as.character(utils::packageVersion(p)),
                                       error = function(e) "NAO INSTALADO"), "")
  as.list(v)
}

#' Salva um data.frame em CSV (separador ";" e virgula decimal, abre certo no Excel BR)
salvar_csv <- function(df, pasta, nome) {
  arq <- file.path(pasta, nome)
  utils::write.csv2(df, arq, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(arq)
}
