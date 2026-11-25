
# ==============================================================
# TCC IPES | R16 V3
# MAXENT M1 / BACKGROUND B1 - 10000 PONTOS
#
# 2 especies x 3 folds x 3 features x 4 RM = 72 modelos
#
# Comparacao controlada com R08 / M1 / B0:
# - Mesmas 8680 presencas
# - Mesmos folds e propriedades
# - Mesmos seis preditores
# - Features L, LQ, LQH
# - RM 1, 2, 3, 4
# - Mesmo metodo maxnet, cloglog e clamping
# - Background B1 com 10000 pontos
#
# Avaliacoes:
# 1. AUC/Boyce contra background B1 do fold
# 2. AUC/Boyce contra background FIXO B0 do fold
# 3. Omissao10 com limiar definido no treino
# 4. Metricas por propriedade
# 5. Comparacoes pareadas com R08
#
# Seguranca:
# - Audita B0, B1 e fontes do R08
# - Verifica ausencia de teste externo
# - Salva checkpoints, permite retomar
# - Nao altera R01-R15
# - Nao seleciona automaticamente um modelo vencedor
# ==============================================================

# --------------------------------------------------------------
# 0 - PACOTES
# --------------------------------------------------------------

for (pacote in c("maxnet", "ecospat")) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    stop(
      "Pacote nao instalado: ", pacote,
      "\nExecute install.packages('", pacote, "')"
    )
  }
}

VERSAO <- "R16_V3_M1_B1_72_20261116"

especies <- c("Ipe-roxo", "Ipe-amarelo")

continuas <- c(
  "altitude_m",
  "declividade_graus",
  "dist_rio_raster_m",
  "bio12_mm_ano",
  "bio17_mm_mes"
)

vars <- c(continuas, "textura_subgrupo")

ler <- function(f) {
  read.csv(
    f,
    fileEncoding = "UTF-8-BOM",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

falhar <- function(...) {
  stop(paste0(...), call. = FALSE)
}

localizar_raiz <- function(arquivo) {
  pasta <- dirname(arquivo)
  
  repeat {
    if (
      dir.exists(file.path(
        pasta, "03 - Trabalho no QGIS"
      )) &&
      dir.exists(file.path(
        pasta, "04 - Dados para o MaxEnt"
      )) &&
      dir.exists(file.path(
        pasta, "06 - Resultados"
      ))
    ) {
      return(pasta)
    }
    
    acima <- dirname(pasta)
    
    if (identical(acima, pasta)) {
      falhar("Pasta principal do TCC nao localizada.")
    }
    
    pasta <- acima
  }
}

conferir_colunas <- function(d, campos, nome) {
  faltam <- setdiff(campos, names(d))
  
  if (length(faltam)) {
    falhar(
      nome, ": campos ausentes: ",
      paste(faltam, collapse = ", ")
    )
  }
}

comparar_b0 <- function(a, b) {
  if (nrow(a) != nrow(b)) return(FALSE)
  
  texto <- c(
    "id_background", "propriedade",
    "upa_id", "celula_raster"
  )
  
  numeros <- c(
    "fold_cv", "longitude", "latitude", vars
  )
  
  for (nm in texto) {
    if (!identical(
      as.character(a[[nm]]),
      as.character(b[[nm]])
    )) {
      return(FALSE)
    }
  }
  
  for (nm in numeros) {
    x <- suppressWarnings(as.numeric(a[[nm]]))
    y <- suppressWarnings(as.numeric(b[[nm]]))
    
    if (
      any(!is.finite(c(x, y))) ||
      !isTRUE(all.equal(
        x, y,
        tolerance = 1e-10,
        check.attributes = FALSE
      ))
    ) {
      return(FALSE)
    }
  }
  
  TRUE
}

cat("\n==============================================\n")
cat("R16 - MAXENT M1 / BACKGROUND B1\n")
cat("72 MODELOS - 10000 PONTOS\n")
cat("==============================================\n")

# --------------------------------------------------------------
# 1 - SELECIONAR B1 E LOCALIZAR O TCC
# --------------------------------------------------------------

cat("\nSelecione 15_BACKGROUND_B1_10000_COM_FOLDS.csv\n")

arq_b1 <- normalizePath(
  file.choose(),
  winslash = "/",
  mustWork = TRUE
)

if (
  basename(arq_b1) !=
  "15_BACKGROUND_B1_10000_COM_FOLDS.csv"
) {
  falhar("Selecione o CSV final do R15 V3.5.")
}

raiz <- localizar_raiz(arq_b1)
pasta_b1 <- dirname(arq_b1)

pasta_r05 <- file.path(
  raiz,
  "04 - Dados para o MaxEnt",
  "04 - Presencas e folds V3"
)

pasta_r08 <- file.path(
  raiz,
  "06 - Resultados",
  "06 - MaxEnt M1 - Grade 72 V3"
)

arq_pres <- file.path(
  pasta_r05, "05_PRESENCAS_UM_POR_PIXEL_30M.csv"
)

arq_bg0 <- file.path(
  pasta_r05, "05_BACKGROUND_COM_FOLDS.csv"
)

arq_total <- file.path(
  pasta_r05,
  "05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv"
)

arq_folds <- file.path(
  pasta_r05, "05_RESUMO_FOLDS.csv"
)

arq_m1 <- file.path(
  pasta_r08, "08_METRICAS_72_MODELOS.csv"
)

arq_man_m1 <- file.path(
  pasta_r08, "08_MANIFESTO_ENTRADAS.csv"
)

arq_qa <- file.path(
  pasta_b1, "15_QA_FINAL_POR_PROPRIEDADE.csv"
)

arq_cotas <- file.path(
  pasta_b1, "15_COTAS_B1_POR_UPA.csv"
)

arq_extra <- file.path(
  pasta_b1, "15_PONTOS_ADICIONAIS_B1.csv"
)

arq_res_fold <- file.path(
  pasta_b1, "15_RESUMO_B1_POR_FOLD.csv"
)

entradas_r05 <- c(
  arq_pres, arq_bg0, arq_total, arq_folds
)

entradas <- c(
  entradas_r05,
  arq_b1, arq_m1, arq_man_m1,
  arq_qa, arq_cotas, arq_extra, arq_res_fold
)

if (!all(file.exists(entradas))) {
  falhar(
    "Arquivos obrigatorios ausentes:\n",
    paste(
      entradas[!file.exists(entradas)],
      collapse = "\n"
    )
  )
}

cat("\nProjeto identificado:\n", raiz, "\n")

# --------------------------------------------------------------
# 2 - CONFERIR DADOS ORIGINAIS E BACKGROUND B1
# --------------------------------------------------------------

cat("\nETAPA 1 - Auditando entradas...\n")

pres <- ler(arq_pres)
bg0 <- ler(arq_bg0)
bg1 <- ler(arq_b1)
total <- ler(arq_total)
resumo05 <- ler(arq_folds)

m1 <- ler(arq_m1)
man08 <- ler(arq_man_m1)

qa <- ler(arq_qa)
cotas <- ler(arq_cotas)
extra <- ler(arq_extra)
resumo_fold_b1 <- ler(arq_res_fold)

campos_pres <- c(
  "especie", "propriedade", "upa_id",
  "fold_cv", "celula_raster", vars
)

campos_bg <- c(
  "id_background", "propriedade", "upa_id",
  "fold_cv", "celula_raster",
  "longitude", "latitude", vars
)

conferir_colunas(pres, campos_pres, "Presencas")
conferir_colunas(bg0, campos_bg, "B0")
conferir_colunas(bg1, c(
  campos_bg, "origem_amostra"
), "B1")

conferir_colunas(m1, c(
  "id", "especie", "fold_cv",
  "features", "RM",
  "auc_validacao", "boyce_validacao",
  "omissao10_validacao",
  "n_presenca_validacao",
  "n_background_validacao"
), "R08")

conferir_colunas(
  man08, c("arquivo", "md5"), "Manifesto R08"
)

conferir_colunas(
  cotas,
  c("chave", "pixels_disponiveis",
    "n_b0", "n_b1", "n_adicionais"),
  "Cotas B1"
)

conferir_colunas(
  resumo_fold_b1,
  c("fold_cv", "n_background_b1"),
  "Resumo folds B1"
)

if (
  nrow(pres) != 8680L ||
  nrow(bg0) != 5000L ||
  nrow(bg1) != 10000L ||
  nrow(extra) != 5000L ||
  nrow(total) != 9004L ||
  nrow(resumo05) != 6L ||
  nrow(m1) != 72L ||
  nrow(qa) != 27L ||
  nrow(cotas) != 64L ||
  nrow(resumo_fold_b1) != 3L
) {
  falhar("Contagens divergentes das bases auditadas.")
}

if (
  sum(pres$especie == "Ipe-roxo") != 3248L ||
  sum(pres$especie == "Ipe-amarelo") != 5432L ||
  !setequal(unique(pres$especie), especies)
) {
  falhar("Presencas diferentes do R05.")
}

# Conferir hashes dos quatro arquivos usados pelo R08.
for (f in entradas_r05) {
  z <- man08[
    man08$arquivo == basename(f),
    , drop = FALSE
  ]
  
  hash <- unname(
    as.character(tools::md5sum(f))
  )
  
  if (
    nrow(z) != 1L ||
    tolower(as.character(z$md5)) != tolower(hash)
  ) {
    falhar(
      "Arquivo original alterado desde R08: ",
      basename(f)
    )
  }
}

# Conferir B0 dentro da B1.
origens <- as.character(bg1$origem_amostra)

if (
  sum(origens == "B0_PRESERVADO") != 5000L ||
  sum(origens == "B1_ADICIONAL") != 5000L ||
  !identical(
    origens[1:5000],
    rep("B0_PRESERVADO", 5000)
  ) ||
  !identical(
    origens[5001:10000],
    rep("B1_ADICIONAL", 5000)
  )
) {
  falhar("Composicao B0/B1 diferente do R15.")
}

if (!comparar_b0(
  bg1[1:5000, , drop = FALSE],
  bg0
)) {
  falhar("Os 5000 registros originais nao conferem.")
}

campos_extra <- intersect(
  campos_bg, names(extra)
)

if (
  !all(campos_bg %in% names(extra)) ||
  !comparar_b0(
    bg1[5001:10000, , drop = FALSE],
    extra
  )
) {
  falhar("Pontos adicionais nao conferem com R15.")
}

# --------------------------------------------------------------
# 3 - VERIFICACOES DE FOLDS, UPAS E PREDITORES
# --------------------------------------------------------------

cat("\nETAPA 2 - Auditando folds e predictores...\n")

for (v in c(vars, "fold_cv")) {
  pres[[v]] <- as.numeric(pres[[v]])
  bg0[[v]] <- as.numeric(bg0[[v]])
  bg1[[v]] <- as.numeric(bg1[[v]])
}

for (d in list(pres, bg0, bg1)) {
  if (
    anyNA(d) ||
    any(!is.finite(
      as.matrix(d[, vars, drop = FALSE])
    ))
  ) {
    falhar("Valores ambientais ausentes ou invalidos.")
  }
}

if (
  anyDuplicated(bg1$id_background) ||
  anyDuplicated(paste(
    bg1$propriedade,
    bg1$longitude,
    bg1$latitude,
    sep = "|"
  )) ||
  anyDuplicated(paste(
    pres$especie,
    pres$propriedade,
    pres$celula_raster,
    sep = "|"
  ))
) {
  falhar("Duplicidades identificadas nas entradas.")
}

if (
  length(unique(bg1$propriedade)) != 27L ||
  length(unique(paste(
    bg1$propriedade, bg1$upa_id,
    sep = "||"
  ))) != 64L ||
  !setequal(
    unique(bg1$propriedade),
    unique(bg0$propriedade)
  ) ||
  !setequal(
    unique(bg1$propriedade),
    unique(pres$propriedade)
  ) ||
  !setequal(unique(bg1$fold_cv), 1:3)
) {
  falhar("UPAs, propriedades ou folds diferentes.")
}

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
)

normalizar <- function(x) {
  x <- iconv(
    as.character(x),
    to = "ASCII//TRANSLIT",
    sub = ""
  )
  x <- toupper(x)
  trimws(gsub("[^A-Z0-9]+", " ", x))
}

if (any(
  normalizar(c(
    pres$propriedade,
    bg0$propriedade,
    bg1$propriedade
  )) %in% normalizar(externas)
)) {
  falhar("Teste externo presente nas entradas!")
}

particao <- unique(rbind(
  pres[, c("propriedade", "fold_cv")],
  bg0[, c("propriedade", "fold_cv")],
  bg1[, c("propriedade", "fold_cv")]
))

if (
  any(vapply(
    split(particao$fold_cv, particao$propriedade),
    function(z) length(unique(z)) != 1L,
    logical(1)
  ))
) {
  falhar("A particao espacial foi alterada.")
}

chaves_bg1 <- paste(
  bg1$propriedade, bg1$upa_id,
  sep = "||"
)

for (i in seq_len(nrow(cotas))) {
  z <- cotas[i, ]
  
  atual <- sum(chaves_bg1 == z$chave)
  
  if (
    atual != z$n_b1 ||
    z$n_b0 + z$n_adicionais != z$n_b1 ||
    z$n_b1 > z$pixels_disponiveis
  ) {
    falhar("Cota divergente: ", z$chave)
  }
}

if (
  sum(cotas$pixels_disponiveis) != 570227L ||
  sum(cotas$n_b0) != 5000L ||
  sum(cotas$n_adicionais) != 5000L ||
  sum(cotas$n_b1) != 10000L
) {
  falhar("Totais das cotas B1 incorretos.")
}

for (f in 1:3) {
  z <- resumo_fold_b1[
    resumo_fold_b1$fold_cv == f,
    , drop = FALSE
  ]
  
  if (
    nrow(z) != 1L ||
    z$n_background_b1 !=
    sum(bg1$fold_cv == f)
  ) {
    falhar("Resumo B1 divergente no fold ", f)
  }
}

if (
  !all(c(
    "pixels_elegiveis",
    "pontos_b0",
    "maior_diferenca"
  ) %in% names(qa)) ||
  sum(qa$pixels_elegiveis) != 570227L ||
  sum(qa$pontos_b0) != 5000L ||
  any(qa$maior_diferenca > 1e-8)
) {
  falhar("Auditoria ambiental R15 divergente.")
}

solo <- sort(unique(c(
  pres$textura_subgrupo,
  bg1$textura_subgrupo
)))

if (!identical(
  as.integer(solo),
  c(2L, 3L, 4L, 6L, 7L)
)) {
  falhar("Classes texturais diferentes do protocolo.")
}

# Conferir presencas e background de cada fold.
for (sp in especies) {
  for (f in 1:3) {
    z <- resumo05[
      resumo05$especie == sp &
        resumo05$fold_cv == f,
      , drop = FALSE
    ]
    
    if (
      nrow(z) != 1L ||
      z$n_presencas_pixel_30m !=
      sum(pres$especie == sp & pres$fold_cv == f) ||
      z$n_background != sum(bg0$fold_cv == f)
    ) {
      falhar("Particao R05 divergente: ", sp, " F", f)
    }
    
    # Solo da validacao deve ter suporte no treinamento.
    treino <- unique(c(
      pres$textura_subgrupo[
        pres$especie == sp & pres$fold_cv != f
      ],
      bg1$textura_subgrupo[bg1$fold_cv != f]
    ))
    
    validacao <- unique(c(
      pres$textura_subgrupo[
        pres$especie == sp & pres$fold_cv == f
      ],
      bg1$textura_subgrupo[bg1$fold_cv == f]
    ))
    
    if (!all(validacao %in% treino)) {
      falhar(
        "Classe de solo exclusiva da validacao: ",
        sp, " Fold ", f
      )
    }
  }
}

cat("\nAUDITORIA DAS ENTRADAS: OK\n")
cat("B0 original: 5000 pontos\n")
cat("B1: 10000 pontos\n")
cat("Presencas: 8680\n")
cat("27 propriedades | 64 UPAs | 3 folds\n")

# --------------------------------------------------------------
# 4 - FUNCOES IDENTICAS AO PROTOCOLO R08
# --------------------------------------------------------------

montar_x <- function(d) {
  x <- d[, vars, drop = FALSE]
  
  for (v in continuas) {
    x[[v]] <- as.numeric(x[[v]])
  }
  
  x$textura_subgrupo <- factor(
    as.character(x$textura_subgrupo),
    levels = as.character(solo)
  )
  
  if (anyNA(x)) {
    falhar("Preditores invalidos na matriz MaxEnt.")
  }
  
  x
}

auc <- function(a, b) {
  a <- as.numeric(a)
  b <- as.numeric(b)
  
  if (
    !length(a) || !length(b) ||
    any(!is.finite(c(a, b)))
  ) {
    return(NA_real_)
  }
  
  r <- rank(
    c(a, b),
    ties.method = "average"
  )
  
  (
    sum(r[seq_along(a)]) -
      length(a) * (length(a) + 1) / 2
  ) / (length(a) * length(b))
}

boyce <- function(a, b) {
  avisos <- character()
  
  if (
    min(length(a), length(b)) < 2L ||
    any(!is.finite(c(a, b)))
  ) {
    return(list(
      valor = NA_real_,
      status = "INDEFINIDO"
    ))
  }
  
  z <- tryCatch(
    withCallingHandlers(
      ecospat::ecospat.boyce(
        fit = as.numeric(b),
        obs = as.numeric(a),
        nclass = 0,
        PEplot = FALSE,
        method = "spearman",
        rm.duplicate = TRUE
      ),
      warning = function(w) {
        avisos <<- c(
          avisos, conditionMessage(w)
        )
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      avisos <<- c(
        avisos, conditionMessage(e)
      )
      NULL
    }
  )
  
  valor <- NA_real_
  
  if (is.list(z) && !is.null(z$cor)) {
    valor <- as.numeric(z$cor)
  } else if (
    is.list(z) &&
    !is.null(z$Spearman.cor)
  ) {
    valor <- as.numeric(z$Spearman.cor)
  }
  
  if (
    length(valor) != 1L ||
    !is.finite(valor) ||
    abs(valor) > 1.000001
  ) {
    return(list(
      valor = NA_real_,
      status = "INDEFINIDO"
    ))
  }
  
  list(
    valor = valor,
    status = if (length(avisos)) {
      paste(
        "CALCULADO COM AVISO:",
        paste(unique(avisos), collapse = " | ")
      )
    } else {
      "OK"
    }
  )
}

# --------------------------------------------------------------
# 5 - DEFINIR OS 72 AJUSTES
# --------------------------------------------------------------

grade <- expand.grid(
  especie = especies,
  fold_cv = 1:3,
  features = c("l", "lq", "lqh"),
  RM = 1:4,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

grade$id <- vapply(
  seq_len(nrow(grade)),
  function(i) {
    z <- grade[i, ]
    
    paste0(
      "M1B1_",
      ifelse(
        z$especie == "Ipe-roxo",
        "ROXO", "AMARELO"
      ),
      "_F", z$fold_cv,
      "_", toupper(z$features),
      "_RM", z$RM
    )
  },
  character(1)
)

grade$id_m1_b0 <- sub(
  "^M1B1_", "M1_", grade$id
)

if (
  nrow(grade) != 72L ||
  anyDuplicated(grade$id) ||
  !setequal(grade$id_m1_b0, m1$id)
) {
  falhar("Grade B1 diferente da grade R08.")
}

# --------------------------------------------------------------
# 6 - PASTAS, MANIFESTO E CHECKPOINTS
# --------------------------------------------------------------

saida <- file.path(
  raiz,
  "06 - Resultados",
  "14 - MaxEnt M1 - B1 10000 V3"
)

modelos_dir <- file.path(
  saida, "16_MODELOS_RDS"
)

prev_dir <- file.path(
  saida, "16_PREVISOES_VALIDACAO"
)

met_dir <- file.path(
  saida, "16_CHECKPOINT_METRICAS"
)

graf_dir <- file.path(
  saida, "16_GRAFICOS"
)

manifesto_path <- file.path(
  saida, "16_MANIFESTO_ENTRADAS.csv"
)

manifesto <- data.frame(
  arquivo = basename(entradas),
  md5 = unname(as.character(
    tools::md5sum(entradas)
  )),
  versao_script = VERSAO,
  R = R.version.string,
  maxnet = as.character(
    utils::packageVersion("maxnet")
  ),
  ecospat = as.character(
    utils::packageVersion("ecospat")
  ),
  stringsAsFactors = FALSE
)

if (!dir.exists(saida)) {
  dir.create(saida, recursive = TRUE)
  
  for (d in c(
    modelos_dir, prev_dir, met_dir, graf_dir
  )) {
    dir.create(d)
  }
  
  write.csv(
    manifesto,
    manifesto_path,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
} else {
  if (!file.exists(manifesto_path)) {
    falhar(
      "Pasta R16 existente sem manifesto. ",
      "Nao sobrescrever."
    )
  }
  
  anterior <- ler(manifesto_path)
  
  if (!identical(anterior, manifesto)) {
    falhar(
      "Arquivos, hashes ou versoes mudaram ",
      "desde a execucao anterior."
    )
  }
  
  if (!all(dir.exists(c(
    modelos_dir, prev_dir, met_dir, graf_dir
  )))) {
    falhar("Subpastas R16 ausentes.")
  }
  
  cat("\nRetomando rodada R16 existente.\n")
}

escrever_csv <- function(x, caminho) {
  temporario <- paste0(caminho, ".tmp")
  
  write.csv(
    x, temporario,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  
  if (file.exists(caminho)) {
    ok <- file.copy(
      temporario, caminho,
      overwrite = TRUE
    )
    unlink(temporario)
  } else {
    ok <- file.rename(temporario, caminho)
  }
  
  if (!ok) {
    falhar("Falha ao gravar: ", caminho)
  }
}

escrever_rds <- function(x, caminho) {
  temporario <- paste0(caminho, ".tmp")
  saveRDS(x, temporario)
  
  if (!file.rename(temporario, caminho)) {
    falhar("Falha ao salvar modelo: ", caminho)
  }
}

# --------------------------------------------------------------
# 7 - CONFERIR PREVISOES DE UM MODELO
# --------------------------------------------------------------

verificar_prev <- function(pp, vp, vb1, vb0, met, id) {
  obrig <- c(
    "tipo", "propriedade", "score_cloglog"
  )
  
  conferir_colunas(pp, obrig, id)
  
  ap <- pp$score_cloglog[
    pp$tipo == "PRESENCA_VALIDACAO"
  ]
  
  ab1 <- pp$score_cloglog[
    pp$tipo == "BACKGROUND_VALIDACAO"
  ]
  
  ab0 <- pp$score_cloglog[
    pp$tipo == "BACKGROUND_B0_FIXO"
  ]
  
  if (
    nrow(pp) != nrow(vp) + nrow(vb1) + nrow(vb0) ||
    length(ap) != nrow(vp) ||
    length(ab1) != nrow(vb1) ||
    length(ab0) != nrow(vb0) ||
    any(!is.finite(c(ap, ab1, ab0))) ||
    any(c(ap, ab1, ab0) < 0) ||
    any(c(ap, ab1, ab0) > 1)
  ) {
    falhar("Previsoes incompletas: ", id)
  }
  
  tipos <- c(
    "PRESENCA_VALIDACAO",
    "BACKGROUND_VALIDACAO",
    "BACKGROUND_B0_FIXO"
  )
  
  dados <- list(vp, vb1, vb0)
  
  for (j in seq_along(tipos)) {
    prop_prev <- as.character(
      pp$propriedade[pp$tipo == tipos[j]]
    )
    
    prop_dados <- as.character(
      dados[[j]]$propriedade
    )
    
    if (!identical(prop_prev, prop_dados)) {
      falhar(
        "Ordem das propriedades divergente: ",
        id
      )
    }
  }
  
  if (
    abs(auc(ap, ab1) - met$auc_validacao) > 1e-8 ||
    abs(auc(ap, ab0) -
        met$auc_validacao_bg_b0_fixo) > 1e-8 ||
    abs(
      mean(ap < met$limiar10_treino_cloglog) -
      met$omissao10_validacao
    ) > 1e-8
  ) {
    falhar(
      "AUC ou omissao nao confere: ", id
    )
  }
  
  invisible(TRUE)
}

# --------------------------------------------------------------
# 8 - EXECUTAR OS 72 MODELOS
# --------------------------------------------------------------

cat("\nETAPA 3 - Iniciando 72 ajustes MaxEnt...\n")

set.seed(20261111)

metricas <- vector(
  "list", nrow(grade)
)

for (i in seq_len(nrow(grade))) {
  cfg <- grade[i, ]
  
  sp <- cfg$especie
  f <- as.integer(cfg$fold_cv)
  feat <- cfg$features
  rm <- as.integer(cfg$RM)
  id <- cfg$id
  
  tp <- pres[
    pres$especie == sp &
      pres$fold_cv != f,
    , drop = FALSE
  ]
  
  vp <- pres[
    pres$especie == sp &
      pres$fold_cv == f,
    , drop = FALSE
  ]
  
  tb1 <- bg1[
    bg1$fold_cv != f,
    , drop = FALSE
  ]
  
  vb1 <- bg1[
    bg1$fold_cv == f,
    , drop = FALSE
  ]
  
  vb0 <- bg0[
    bg0$fold_cv == f,
    , drop = FALSE
  ]
  
  if (
    min(
      nrow(tp), nrow(vp),
      nrow(tb1), nrow(vb1), nrow(vb0)
    ) < 100L
  ) {
    falhar("Amostras insuficientes: ", id)
  }
  
  modelo_path <- file.path(
    modelos_dir, paste0(id, ".rds")
  )
  
  prev_path <- file.path(
    prev_dir, paste0(id, ".csv")
  )
  
  met_path <- file.path(
    met_dir, paste0(id, ".csv")
  )
  
  existentes <- file.exists(c(
    modelo_path, prev_path, met_path
  ))
  
  if (any(existentes) && !all(existentes)) {
    falhar(
      "Checkpoint incompleto: ", id,
      ". Preserve os arquivos para auditoria."
    )
  }
  
  # ----------------------------------------------------------
  # 8.1 - RETOMAR CHECKPOINT EXISTENTE
  # ----------------------------------------------------------
  
  if (all(existentes)) {
    modelo <- tryCatch(
      readRDS(modelo_path),
      error = function(e) NULL
    )
    
    met <- ler(met_path)
    pp <- ler(prev_path)
    
    if (
      !inherits(modelo, "maxnet") ||
      nrow(met) != 1L ||
      met$id != id ||
      met$especie != sp ||
      met$fold_cv != f ||
      met$features != feat ||
      met$RM != rm ||
      length(modelo$betas) !=
      met$n_features_ativas
    ) {
      falhar("Checkpoint inconsistente: ", id)
    }
    
    verificar_prev(
      pp, vp, vb1, vb0, met, id
    )
    
    metricas[[i]] <- met
    
    cat(sprintf(
      "[%02d/72] %s | checkpoint conferido\n",
      i, id
    ))
    
    next
  }
  
  # ----------------------------------------------------------
  # 8.2 - TREINAMENTO
  # ----------------------------------------------------------
  
  xt <- montar_x(rbind(
    tp[, vars, drop = FALSE],
    tb1[, vars, drop = FALSE]
  ))
  
  y <- c(
    rep(1L, nrow(tp)),
    rep(0L, nrow(tb1))
  )
  
  inicio <- Sys.time()
  
  formula <- maxnet::maxnet.formula(
    y, xt,
    classes = feat
  )
  
  modelo <- maxnet::maxnet(
    y,
    xt,
    f = formula,
    regmult = rm,
    addsamplestobackground = TRUE
  )
  
  predizer <- function(d) {
    as.numeric(
      stats::predict(
        modelo,
        montar_x(d),
        type = "cloglog",
        clamp = TRUE
      )
    )
  }
  
  # Treino
  stp <- predizer(tp)
  stb1 <- predizer(tb1)
  
  # Validacao principal da B1
  svp <- predizer(vp)
  svb1 <- predizer(vb1)
  
  # Avaliacao de referencia com o mesmo BG da B0
  svb0 <- predizer(vb0)
  
  scores <- c(
    stp, stb1, svp, svb1, svb0
  )
  
  if (
    any(!is.finite(scores)) ||
    any(scores < 0 | scores > 1)
  ) {
    falhar("Previsoes invalidas: ", id)
  }
  
  # Mesmo limiar de treinamento do R08.
  limiar <- unname(as.numeric(
    stats::quantile(
      stp,
      probs = 0.10,
      type = 7
    )
  ))
  
  ib1 <- boyce(svp, svb1)
  ib0 <- boyce(svp, svb0)
  
  met <- data.frame(
    id = id,
    id_m1_b0 = cfg$id_m1_b0,
    especie = sp,
    fold_cv = f,
    features = feat,
    RM = rm,
    
    n_presenca_treino = nrow(tp),
    n_background_treino = nrow(tb1),
    
    n_presenca_validacao = nrow(vp),
    n_background_validacao = nrow(vb1),
    n_background_b0_fixo = nrow(vb0),
    
    auc_treino = auc(stp, stb1),
    auc_validacao = auc(svp, svb1),
    auc_validacao_bg_b0_fixo = auc(svp, svb0),
    
    omissao10_treino = mean(stp < limiar),
    omissao10_validacao = mean(svp < limiar),
    
    limiar10_treino_cloglog = limiar,
    
    boyce_validacao = ib1$valor,
    status_boyce_validacao = ib1$status,
    
    boyce_validacao_bg_b0_fixo = ib0$valor,
    status_boyce_bg_b0_fixo = ib0$status,
    
    n_features_ativas = length(modelo$betas),
    
    segundos_ajuste = as.numeric(
      difftime(
        Sys.time(), inicio,
        units = "secs"
      )
    ),
    
    previsao = "cloglog",
    clamping = TRUE,
    solo = "fator",
    background = "B1_10000",
    stringsAsFactors = FALSE
  )
  
  # ----------------------------------------------------------
  # 8.3 - SALVAR PREVISOES
  # ----------------------------------------------------------
  
  pp <- rbind(
    data.frame(
      id = id,
      especie = sp,
      fold_cv = f,
      features = feat,
      RM = rm,
      tipo = "PRESENCA_VALIDACAO",
      propriedade = vp$propriedade,
      score_cloglog = svp
    ),
    
    data.frame(
      id = id,
      especie = sp,
      fold_cv = f,
      features = feat,
      RM = rm,
      tipo = "BACKGROUND_VALIDACAO",
      propriedade = vb1$propriedade,
      score_cloglog = svb1
    ),
    
    data.frame(
      id = id,
      especie = sp,
      fold_cv = f,
      features = feat,
      RM = rm,
      tipo = "BACKGROUND_B0_FIXO",
      propriedade = vb0$propriedade,
      score_cloglog = svb0
    )
  )
  
  verificar_prev(
    pp, vp, vb1, vb0, met, id
  )
  
  escrever_rds(modelo, modelo_path)
  escrever_csv(pp, prev_path)
  escrever_csv(met, met_path)
  
  metricas[[i]] <- met
  
  cat(sprintf(
    "[%02d/72] %s | AUC B1=%.3f | AUC BG fixo=%.3f | Omissao=%.3f\n",
    i, id,
    met$auc_validacao,
    met$auc_validacao_bg_b0_fixo,
    met$omissao10_validacao
  ))
  
  parcial <- do.call(
    rbind,
    metricas[!vapply(
      metricas, is.null, logical(1)
    )]
  )
  
  escrever_csv(
    parcial,
    file.path(
      saida, "16_METRICAS_PARCIAIS.csv"
    )
  )
}

# --------------------------------------------------------------
# 9 - CONSOLIDAR 72 AVALIACOES
# --------------------------------------------------------------

metricas <- do.call(rbind, metricas)

if (
  nrow(metricas) != 72L ||
  anyDuplicated(metricas$id)
) {
  falhar("Grade R16 incompleta.")
}

escrever_csv(
  metricas,
  file.path(
    saida, "16_METRICAS_72_MODELOS_B1.csv"
  )
)

# --------------------------------------------------------------
# 10 - COMPARACAO PAREADA COM R08
# --------------------------------------------------------------

cat("\nETAPA 4 - Comparando B0 e B1...\n")

comparacoes <- vector(
  "list", nrow(metricas)
)

for (i in seq_len(nrow(metricas))) {
  z <- metricas[i, ]
  
  ref <- m1[
    m1$id == z$id_m1_b0,
    , drop = FALSE
  ]
  
  if (
    nrow(ref) != 1L ||
    ref$especie != z$especie ||
    ref$fold_cv != z$fold_cv ||
    ref$features != z$features ||
    ref$RM != z$RM ||
    ref$n_presenca_validacao !=
    z$n_presenca_validacao ||
    ref$n_background_validacao !=
    z$n_background_b0_fixo
  ) {
    falhar(
      "Referencia R08 divergente: ", z$id
    )
  }
  
  comparacoes[[i]] <- data.frame(
    id_b1 = z$id,
    id_b0 = ref$id,
    especie = z$especie,
    fold_cv = z$fold_cv,
    features = z$features,
    RM = z$RM,
    
    auc_b0 = ref$auc_validacao,
    auc_b1_bg_b1 = z$auc_validacao,
    auc_b1_bg_b0_fixo =
      z$auc_validacao_bg_b0_fixo,
    
    delta_auc_mesmo_bg =
      z$auc_validacao_bg_b0_fixo -
      ref$auc_validacao,
    
    boyce_b0 = ref$boyce_validacao,
    boyce_b1_bg_b1 = z$boyce_validacao,
    boyce_b1_bg_b0_fixo =
      z$boyce_validacao_bg_b0_fixo,
    
    delta_boyce_mesmo_bg =
      z$boyce_validacao_bg_b0_fixo -
      ref$boyce_validacao,
    
    omissao_b0 =
      ref$omissao10_validacao,
    
    omissao_b1 =
      z$omissao10_validacao,
    
    delta_omissao =
      z$omissao10_validacao -
      ref$omissao10_validacao,
    
    complexidade_b0 =
      ref$n_features_ativas,
    
    complexidade_b1 =
      z$n_features_ativas,
    
    stringsAsFactors = FALSE
  )
}

comparacoes <- do.call(
  rbind, comparacoes
)

escrever_csv(
  comparacoes,
  file.path(
    saida,
    "16_COMPARACAO_72_B0_VS_B1.csv"
  )
)

# --------------------------------------------------------------
# 11 - RESUMO DAS 24 CONFIGURACOES
# --------------------------------------------------------------

resumos <- list()
j <- 0L

for (sp in especies) {
  for (feat in c("l", "lq", "lqh")) {
    for (rm in 1:4) {
      z <- metricas[
        metricas$especie == sp &
          metricas$features == feat &
          metricas$RM == rm,
        , drop = FALSE
      ]
      
      c0 <- comparacoes[
        comparacoes$especie == sp &
          comparacoes$features == feat &
          comparacoes$RM == rm,
        , drop = FALSE
      ]
      
      if (
        nrow(z) != 3L ||
        nrow(c0) != 3L ||
        !setequal(z$fold_cv, 1:3)
      ) {
        falhar("Configuracao sem tres folds.")
      }
      
      b <- z$boyce_validacao[
        is.finite(z$boyce_validacao)
      ]
      
      bfixo <- z$boyce_validacao_bg_b0_fixo[
        is.finite(z$boyce_validacao_bg_b0_fixo)
      ]
      
      j <- j + 1L
      
      resumos[[j]] <- data.frame(
        especie = sp,
        features = feat,
        RM = rm,
        folds = 3L,
        
        auc_b0_media =
          mean(c0$auc_b0),
        
        auc_b1_media =
          mean(z$auc_validacao),
        
        auc_b1_bg_fixo_media =
          mean(z$auc_validacao_bg_b0_fixo),
        
        delta_auc_bg_fixo_media =
          mean(c0$delta_auc_mesmo_bg),
        
        auc_b1_dp =
          sd(z$auc_validacao_bg_b0_fixo),
        
        auc_b1_min =
          min(z$auc_validacao_bg_b0_fixo),
        
        boyce_b0_media =
          mean(c0$boyce_b0),
        
        boyce_b1_media =
          if (length(b)) mean(b) else NA_real_,
        
        boyce_b1_bg_fixo_media =
          if (length(bfixo)) mean(bfixo) else NA_real_,
        
        delta_boyce_bg_fixo_media =
          mean(c0$delta_boyce_mesmo_bg,
               na.rm = TRUE),
        
        omissao_b0_media =
          mean(c0$omissao_b0),
        
        omissao_b1_media =
          mean(z$omissao10_validacao),
        
        delta_omissao_media =
          mean(c0$delta_omissao),
        
        omissao_b1_max =
          max(z$omissao10_validacao),
        
        complexidade_b1_media =
          mean(z$n_features_ativas),
        
        stringsAsFactors = FALSE
      )
    }
  }
}

resumo <- do.call(rbind, resumos)

if (nrow(resumo) != 24L) {
  falhar("Resumo deveria ter 24 configuracoes.")
}

escrever_csv(
  resumo,
  file.path(
    saida,
    "16_RESUMO_24_CONFIGURACOES_B0_B1.csv"
  )
)

# --------------------------------------------------------------
# 12 - METRICAS POR PROPRIEDADE
# --------------------------------------------------------------

cat("\nETAPA 5 - Auditando propriedades...\n")

props_out <- list()
k <- 0L

for (i in seq_len(nrow(metricas))) {
  z <- metricas[i, ]
  
  pp <- ler(file.path(
    prev_dir,
    paste0(z$id, ".csv")
  ))
  
  for (pr in unique(pp$propriedade)) {
    a <- pp$score_cloglog[
      pp$propriedade == pr &
        pp$tipo == "PRESENCA_VALIDACAO"
    ]
    
    b1p <- pp$score_cloglog[
      pp$propriedade == pr &
        pp$tipo == "BACKGROUND_VALIDACAO"
    ]
    
    b0p <- pp$score_cloglog[
      pp$propriedade == pr &
        pp$tipo == "BACKGROUND_B0_FIXO"
    ]
    
    if (!length(a)) next
    
    k <- k + 1L
    
    props_out[[k]] <- data.frame(
      id = z$id,
      especie = z$especie,
      fold_cv = z$fold_cv,
      features = z$features,
      RM = z$RM,
      propriedade = pr,
      
      n_presencas = length(a),
      n_background_b1 = length(b1p),
      n_background_b0 = length(b0p),
      
      auc_propriedade_b1 =
        if (min(length(a), length(b1p)) >= 10) {
          auc(a, b1p)
        } else {
          NA_real_
        },
      
      auc_propriedade_bg_b0_fixo =
        if (min(length(a), length(b0p)) >= 10) {
          auc(a, b0p)
        } else {
          NA_real_
        },
      
      omissao10_propriedade = mean(
        a < z$limiar10_treino_cloglog
      ),
      
      stringsAsFactors = FALSE
    )
  }
}

if (length(props_out)) {
  dados_prop <- do.call(rbind, props_out)
  
  escrever_csv(
    dados_prop,
    file.path(
      saida,
      "16_AUC_OMISSAO_POR_PROPRIEDADE.csv"
    )
  )
}

# --------------------------------------------------------------
# 13 - GRAFICOS DE SENSIBILIDADE
# --------------------------------------------------------------

cat("\nETAPA 6 - Gerando graficos...\n")

for (sp in especies) {
  apelido <- ifelse(
    sp == "Ipe-roxo",
    "ROXO", "AMARELO"
  )
  
  z <- resumo[
    resumo$especie == sp,
    , drop = FALSE
  ]
  
  graficos_metricas <- list(
    AUC = c(
      "auc_b0_media",
      "auc_b1_bg_fixo_media"
    ),
    OMISSAO = c(
      "omissao_b0_media",
      "omissao_b1_media"
    )
  )
  
  for (nome in names(graficos_metricas)) {
    campos <- graficos_metricas[[nome]]
    
    png(
      file.path(
        graf_dir,
        paste0(
          "16_", apelido, "_",
          nome, "_B0_VS_B1.png"
        )
      ),
      width = 1100,
      height = 750,
      res = 140
    )
    
    plot(
      1:4, rep(NA_real_, 4),
      xlim = c(1, 4),
      ylim = c(0, 1),
      type = "n",
      xaxt = "n",
      xlab = "Multiplicador de regularizacao (RM)",
      ylab = nome,
      main = paste(
        sp, "- B0 vs B1 -", nome
      )
    )
    
    axis(1, at = 1:4)
    
    classes <- c("l", "lq", "lqh")
    tons <- c(
      "gray20", "gray45", "gray70"
    )
    
    for (j in seq_along(classes)) {
      zz <- z[
        z$features == classes[j],
        , drop = FALSE
      ]
      
      zz <- zz[order(zz$RM), ]
      
      lines(
        zz$RM, zz[[campos[1]]],
        type = "b", lty = 2,
        pch = 14 + j,
        col = tons[j]
      )
      
      lines(
        zz$RM, zz[[campos[2]]],
        type = "b", lty = 1,
        pch = 14 + j,
        col = tons[j]
      )
    }
    
    legend(
      "topright",
      legend = c(
        "B0 - tracejado",
        "B1 - continuo",
        "L", "LQ", "LQH"
      ),
      lty = c(2, 1, 1, 1, 1),
      pch = c(NA, NA, 15, 16, 17),
      col = c(
        "gray40", "gray40", tons
      ),
      bty = "n"
    )
    
    dev.off()
  }
}

# --------------------------------------------------------------
# 14 - RELATORIO E DOCUMENTACAO
# --------------------------------------------------------------

relatorio <- c(
  "# TCC IPES - R16",
  "",
  "## Experimento M1/B1",
  "",
  "- Background B1: 10000 pontos.",
  "- Background B0: 5000 pontos originais.",
  "- B1 inclui integralmente a B0.",
  "- 64 UPAs inventariadas.",
  "- 27 propriedades de desenvolvimento.",
  "- Tres folds espaciais.",
  "",
  "## Modelagem",
  "",
  "- 72 novos ajustes MaxEnt/maxnet.",
  "- Seis preditores ambientais.",
  "- Features: L, LQ e LQH.",
  "- RM: 1, 2, 3 e 4.",
  "- Solo tratado como fator.",
  "- Previsoes cloglog com clamping TRUE.",
  "",
  "## Comparacao B0/B1",
  "",
  "As mesmas presencas foram utilizadas.",
  "Os folds foram mantidos.",
  "O limiar de omissao foi definido no treinamento.",
  "",
  "AUC e Boyce com background B1 sao descritivos.",
  "A comparacao principal usa o background B0",
  "FIXO na validacao dos modelos B0 e B1.",
  "Isso evita confundir alteracao da amostra de",
  "validacao com alteracao do treinamento.",
  "",
  "## Limitacoes",
  "",
  "B1 e uma ampliacao aninhada da B0.",
  "As amostras nao sao independentes.",
  "Os folds apresentam heterogeneidade ambiental.",
  "A validacao espacial nao garante independencia",
  "ecologica absoluta entre todas as areas.",
  "",
  "Nao selecionar o vencedor somente pela AUC media.",
  "Examinar Boyce, omissao, folds e propriedades.",
  "Nao utilizar o teste externo na selecao.",
  "",
  "## Teste externo",
  "",
  "Sete propriedades continuam reservadas.",
  "Nenhum dado do teste externo foi utilizado.",
  "",
  "## Reprodutibilidade",
  "",
  "Entradas originais R05 conferidas por MD5.",
  "B0 preservada nos primeiros 5000 registros de B1.",
  "Cotas e QA R15 conferidos.",
  "Checkpoints de modelos R16 gravados.",
  "Resultados R01-R15 preservados.",
  "",
  paste("Data:", as.character(Sys.time())),
  paste("R:", R.version.string),
  paste(
    "maxnet:",
    as.character(
      utils::packageVersion("maxnet")
    )
  ),
  paste(
    "ecospat:",
    as.character(
      utils::packageVersion("ecospat")
    )
  )
)

writeLines(
  relatorio,
  file.path(
    saida, "16_RELATORIO_COMPARATIVO_B0_B1.md"
  )
)

writeLines(
  capture.output(sessionInfo()),
  file.path(
    saida, "16_SESSION_INFO.txt"
  )
)

cat("\n============================================\n")
cat("R16 CONCLUIDO!\n")
cat("============================================\n")
cat("72 modelos MaxEnt ajustados para B1.\n")
cat("24 configuracoes comparadas com B0.\n")
cat("Background B1: 10000 pontos.\n")
cat("Background de referencia: B0 fixo.\n")
cat("Teste externo: nao utilizado.\n")
cat("\nResultados:\n", saida, "\n")
cat("============================================\n")
