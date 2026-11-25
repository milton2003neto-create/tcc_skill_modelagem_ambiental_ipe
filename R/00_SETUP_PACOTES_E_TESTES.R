# =============================================================================
# 00_SETUP_PACOTES_E_TESTES.R
# -----------------------------------------------------------------------------
# O QUE FAZ: prepara o computador para usar a ferramenta. Rode UMA VEZ
#            (e sempre que trocar de computador ou atualizar o R).
#   1. Confere a versao do R.
#   2. Instala os pacotes que faltam (versoes binarias do CRAN, sem compilar).
#   3. Carrega cada pacote e faz um TESTE real (ajusta um MaxEnt pequeno,
#      cria um raster, calcula Boyce...).
#   4. Confere se os arquivos de dados do TCC estao no lugar.
#   5. Salva um relatorio em resultados/_geral/00_setup/<data_hora>/.
# COMPLEMENTOS: NAO precisa de Java (maxnet e R puro). Rtools so seria
#   necessario se algum pacote nao tivesse versao binaria (o script avisa).
#   Pandoc (para gerar .docx) ja vem junto com o RStudio.
# COMO RODAR: abra FerramentaIpes.Rproj no RStudio e clique em "Source".
# =============================================================================

cat("\n================ SETUP DA FERRAMENTA DE MODELAGEM DOS IPES ================\n")
source(file.path(if (file.exists("R")) "R" else ".", "01_CONFIGURACAO_E_FUNCOES.R"), encoding = "UTF-8")

resultado <- data.frame(item = character(), status = character(), detalhe = character())
anotar <- function(item, ok, detalhe = "") {
  resultado[nrow(resultado) + 1, ] <<- list(item, if (ok) "OK" else "FALHOU", detalhe)
  cat(sprintf("  [%s] %-38s %s\n", if (ok) "OK" else "XX", item, detalhe))
}

# ---- 1. Versao do R ---------------------------------------------------------
cat("\n1) Versao do R\n")
ok_r <- getRversion() >= "4.2.0"
anotar("Versao do R", ok_r, R.version.string)
if (!ok_r) stop("Instale o R 4.2 ou superior: https://cran.r-project.org/bin/windows/base/")

# ---- 2. Instalacao dos pacotes ----------------------------------------------
cat("\n2) Pacotes (instalando os que faltam - pode demorar alguns minutos na 1a vez)\n")
options(repos = c(CRAN = "https://cloud.r-project.org"))
faltando <- PACOTES_NECESSARIOS[!vapply(PACOTES_NECESSARIOS, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltando)) {
  cat("   Instalando:", paste(faltando, collapse = ", "), "\n")
  tipo <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  tryCatch(install.packages(faltando, type = tipo, dependencies = TRUE),
           error = function(e) cat("   ERRO na instalacao:", conditionMessage(e), "\n"))
}
for (p in PACOTES_NECESSARIOS) {
  ok <- suppressWarnings(suppressPackageStartupMessages(requireNamespace(p, quietly = TRUE)))
  anotar(paste("Pacote", p), ok,
         if (ok) as.character(utils::packageVersion(p)) else
           "nao instalou - veja mensagem acima; se pedir compilacao, instale o Rtools")
}

# ---- 3. Testes funcionais ----------------------------------------------------
cat("\n3) Testes funcionais\n")
testar <- function(nome, expr) {
  r <- tryCatch({ force(expr); list(TRUE, "funcionando") },
                error = function(e) list(FALSE, conditionMessage(e)))
  anotar(nome, r[[1]], r[[2]])
}
set.seed(1)
dados_teste <- data.frame(a = rnorm(300), b = runif(300), solo = factor(sample(1:3, 300, TRUE)))
pa_teste <- c(rep(1, 100), rep(0, 200))
testar("maxnet: ajustar MaxEnt (LQH)", {
  m <- maxnet::maxnet(pa_teste, dados_teste, maxnet::maxnet.formula(pa_teste, dados_teste, classes = "lqh"))
  p <- predict(m, dados_teste, type = "cloglog")
  stopifnot(all(is.finite(p)))
})
testar("ecospat: indice de Boyce", {
  b <- ecospat::ecospat.boyce(fit = runif(200), obs = runif(50, 0.3, 1), PEplot = FALSE)
  stopifnot(is.finite(b$cor))
})
testar("terra: criar e ler raster", {
  r <- terra::rast(nrows = 10, ncols = 10, vals = 1:100); stopifnot(terra::global(r, "sum")[1, 1] == 5050)
})
testar("sf: geometria de pontos", {
  s <- sf::st_as_sf(data.frame(x = -51, y = -2), coords = c("x", "y"), crs = 4674); stopifnot(nrow(s) == 1)
})
testar("usdm: VIF (multicolinearidade)", { v <- usdm::vif(dados_teste[, c("a", "b")]); stopifnot(nrow(v) == 2) })
testar("ggplot2: gerar grafico PNG", {
  f <- tempfile(fileext = ".png")
  ggplot2::ggsave(f, ggplot2::ggplot(dados_teste, ggplot2::aes(a, b)) + ggplot2::geom_point(), width = 3, height = 3)
  stopifnot(file.exists(f))
})
anotar("Pandoc (gerar .docx)", rmarkdown::pandoc_available(),
       if (rmarkdown::pandoc_available()) as.character(rmarkdown::pandoc_version())
       else "nao encontrado: rode este script dentro do RStudio (que ja traz o pandoc)")
anotar("Java", TRUE, "nao necessario (maxnet e MaxEnt em R puro)")

# ---- 4. Dados do TCC ---------------------------------------------------------
cat("\n4) Arquivos de dados do TCC em:", PASTA_DADOS, "\n")
for (n in names(ARQUIVOS)) {
  existe <- file.exists(ARQUIVOS[[n]])
  anotar(paste("Dados:", n), existe, if (existe) basename(ARQUIVOS[[n]]) else
         paste("NAO ENCONTRADO:", ARQUIVOS[[n]], "- ajuste PASTA_DADOS em config_local.R"))
}

# ---- 5. Relatorio ------------------------------------------------------------
pasta <- criar_pasta_saida("_geral", "00_setup")
salvar_csv(resultado, pasta, "00_RESULTADO_SETUP.csv")
falhas <- resultado$item[resultado$status != "OK"]
registrar_log(pasta, "00_setup", escolhas = list(pasta_dados = PASTA_DADOS),
              mensagens = if (length(falhas)) paste("FALHOU:", falhas) else "Tudo OK")
cat("\n==========================================================================\n")
if (length(falhas)) {
  cat("ATENCAO:", length(falhas), "item(ns) falharam:\n ", paste(falhas, collapse = "\n  "), "\n")
} else {
  cat("TUDO PRONTO! Todos os pacotes e testes funcionaram.\n")
}
cat("Relatorio salvo em:", pasta, "\n")
cat("==========================================================================\n")
