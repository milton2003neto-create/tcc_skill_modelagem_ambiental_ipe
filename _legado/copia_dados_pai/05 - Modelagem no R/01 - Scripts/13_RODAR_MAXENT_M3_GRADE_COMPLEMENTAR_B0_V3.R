
# ==============================================================
# TCC IPES - R13 V3 | M3 - GRADE COMPLEMENTAR B0
#
# 72 avaliacoes:
#   Ipe-roxo:    SEM_BIO12_BIO17
#   Ipe-amarelo: SEM_BIO12
#   3 folds x 3 features (L/LQ/LQH) x 4 RM (1 a 4)
#
# 70 ajustes novos e 2 modelos R10 reutilizados.
# Compara cada avaliacao com M1/R08 de 6 variaveis.
#
# Dados, background e folds identicos ao R08 e R10.
# Sem teste externo. Sem modificar resultados anteriores.
# Rodada exploratoria, sem selecao automatica de vencedor.
# ==============================================================

for (pacote in c("maxnet", "ecospat")) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    stop("Instale o pacote: install.packages('",
         pacote, "')")
  }
}

versao <- "R13_V3_M3_B0_20261115"

cat("\nR13 | Selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv\n")
arq_pres <- normalizePath(
  file.choose(), winslash = "/", mustWork = TRUE
)

if (basename(arq_pres) !=
    "05_PRESENCAS_UM_POR_PIXEL_30M.csv") {
  stop("Arquivo incorreto. Selecione o CSV do R05.")
}

entrada <- dirname(arq_pres)
raiz <- dirname(dirname(entrada))

if (basename(entrada) != "04 - Presencas e folds V3" ||
    basename(dirname(entrada)) != "04 - Dados para o MaxEnt" ||
    !dir.exists(file.path(raiz, "03 - Trabalho no QGIS"))) {
  stop("Estrutura oficial V3 nao encontrada.")
}

ler <- function(f) {
  read.csv(f, fileEncoding = "UTF-8-BOM",
           stringsAsFactors = FALSE, check.names = FALSE)
}

arq_bg <- file.path(
  entrada, "05_BACKGROUND_COM_FOLDS.csv"
)
arq_total <- file.path(
  entrada, "05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv"
)
arq_folds <- file.path(
  entrada, "05_RESUMO_FOLDS.csv"
)

entradas <- c(
  arq_pres, arq_bg, arq_total, arq_folds
)

pasta_m1 <- file.path(
  raiz, "06 - Resultados",
  "06 - MaxEnt M1 - Grade 72 V3"
)

pasta_m2 <- file.path(
  raiz, "06 - Resultados",
  "08 - MaxEnt M2 - Variaveis V3"
)

arq_m1 <- file.path(
  pasta_m1, "08_METRICAS_72_MODELOS.csv"
)
arq_m2 <- file.path(
  pasta_m2, "10_METRICAS_36_AVALIACOES.csv"
)
man_m1 <- file.path(
  pasta_m1, "08_MANIFESTO_ENTRADAS.csv"
)
man_m2 <- file.path(
  pasta_m2, "10_MANIFESTO_ENTRADAS.csv"
)

necessarios <- c(
  entradas, arq_m1, arq_m2, man_m1, man_m2
)

if (!all(file.exists(necessarios))) {
  stop("Faltam arquivos do R05, R08 ou R10.")
}

pres <- ler(arq_pres)
bg <- ler(arq_bg)
total <- ler(arq_total)
folds <- ler(arq_folds)
m1 <- ler(arq_m1)
m2 <- ler(arq_m2)
manifesto_m1 <- ler(man_m1)
manifesto_m2 <- ler(man_m2)

continuas <- c(
  "altitude_m",
  "declividade_graus",
  "dist_rio_raster_m",
  "bio12_mm_ano",
  "bio17_mm_mes"
)

vars <- c(continuas, "textura_subgrupo")

cp <- c(
  "especie", "propriedade", "upa_id",
  "fold_cv", "celula_raster", vars
)

cb <- c(
  "propriedade", "upa_id", "fold_cv",
  "celula_raster", "id_background", vars
)

if (!all(cp %in% names(pres)) ||
    !all(cb %in% names(bg)) ||
    !all(c(
      "especie", "fold_cv",
      "n_presencas_pixel_30m", "n_background"
    ) %in% names(folds))) {
  stop("Colunas obrigatorias ausentes no R05.")
}

if (nrow(pres) != 8680L ||
    nrow(bg) != 5000L ||
    nrow(total) != 9004L ||
    nrow(folds) != 6L ||
    nrow(m1) != 72L ||
    nrow(m2) != 36L ||
    sum(pres$especie == "Ipe-roxo") != 3248L ||
    sum(pres$especie == "Ipe-amarelo") != 5432L) {
  stop("Contagens divergentes das rodadas auditadas.")
}

if (anyDuplicated(m1$id) ||
    anyDuplicated(m2$id) ||
    anyNA(pres[, cp, drop = FALSE]) ||
    anyNA(bg[, cb, drop = FALSE]) ||
    any(!is.finite(as.matrix(
      pres[, vars, drop = FALSE]
    ))) ||
    any(!is.finite(as.matrix(
      bg[, vars, drop = FALSE]
    )))) {
  stop("Duplicidade ou valor ambiental invalido.")
}

if (anyDuplicated(paste(
  pres$propriedade, pres$especie,
  pres$celula_raster
)) ||
anyDuplicated(paste(
  bg$propriedade, bg$celula_raster
)) ||
anyDuplicated(bg$id_background)) {
  stop("Duplicidades inesperadas nas entradas.")
}

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
)

if (any(c(pres$propriedade, bg$propriedade) %in%
        externas)) {
  stop("TESTE EXTERNO presente. R13 interrompido.")
}

prop_folds <- unique(rbind(
  pres[, c("propriedade", "fold_cv")],
  bg[, c("propriedade", "fold_cv")]
))

if (length(unique(bg$propriedade)) != 27L ||
    length(unique(bg$upa_id)) != 64L ||
    !setequal(unique(pres$propriedade),
              unique(bg$propriedade)) ||
    !setequal(unique(pres$fold_cv), 1:3) ||
    !setequal(unique(bg$fold_cv), 1:3) ||
    any(vapply(
      split(prop_folds$fold_cv, prop_folds$propriedade),
      function(x) length(unique(x)) != 1L,
      logical(1)
    ))) {
  stop("Background, UPAs ou folds inconsistentes.")
}

for (sp in c("Ipe-roxo", "Ipe-amarelo")) {
  for (f in 1:3) {
    z <- folds[
      folds$especie == sp & folds$fold_cv == f,
      , drop = FALSE
    ]
    
    if (nrow(z) != 1L ||
        z$n_presencas_pixel_30m !=
        sum(pres$especie == sp & pres$fold_cv == f) ||
        z$n_background != sum(bg$fold_cv == f)) {
      stop("Contagens divergentes no fold ", f, " ", sp)
    }
  }
}

# Integridade dos arquivos originais do R08.
for (f in entradas) {
  z <- manifesto_m1[
    manifesto_m1$arquivo == basename(f),
    , drop = FALSE
  ]
  
  if (nrow(z) != 1L ||
      tolower(as.character(z$md5)) !=
      tolower(unname(as.character(tools::md5sum(f))))) {
    stop("Arquivo alterado desde o R08: ", basename(f))
  }
}

# Conferir o ambiente de R usado anteriormente.
if (!all(c("R", "maxnet", "ecospat") %in%
         names(manifesto_m1))) {
  stop("Manifesto R08 incompleto.")
}

if (as.character(manifesto_m1$R[1]) != R.version.string ||
    as.character(manifesto_m1$maxnet[1]) !=
    as.character(utils::packageVersion("maxnet")) ||
    as.character(manifesto_m1$ecospat[1]) !=
    as.character(utils::packageVersion("ecospat"))) {
  stop("Versao do R ou pacotes mudou desde o R08.")
}

classes_solo <- sort(unique(c(
  pres$textura_subgrupo,
  bg$textura_subgrupo
)))

if (!identical(
  as.integer(classes_solo),
  c(2L, 3L, 4L, 6L, 7L))) {
  stop("Classes do solo diferentes da base auditada.")
}

# --------------------------------------------------------------
# CONJUNTOS ALTERNATIVOS PREDEFINIDOS
# --------------------------------------------------------------

conjuntos <- list(
  "Ipe-roxo" = setdiff(
    vars, c("bio12_mm_ano", "bio17_mm_mes")
  ),
  "Ipe-amarelo" = setdiff(
    vars, "bio12_mm_ano"
  )
)

nomes_conjuntos <- c(
  "Ipe-roxo" = "SEM_BIO12_BIO17",
  "Ipe-amarelo" = "SEM_BIO12"
)

especies <- c("Ipe-roxo", "Ipe-amarelo")

grade <- expand.grid(
  especie = especies,
  fold_cv = 1:3,
  features = c("l", "lq", "lqh"),
  RM = 1:4,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

grade$conjunto <- unname(
  nomes_conjuntos[grade$especie]
)

grade$id <- vapply(
  seq_len(nrow(grade)),
  function(i) {
    z <- grade[i, ]
    paste0(
      "M3_",
      ifelse(z$especie == "Ipe-roxo",
             "ROXO", "AMARELO"),
      "_F", z$fold_cv,
      "_", z$conjunto,
      "_", toupper(z$features),
      "_RM", z$RM
    )
  },
  character(1)
)

if (nrow(grade) != 72L ||
    anyDuplicated(grade$id)) {
  stop("A grade M3 deveria ter 72 avaliacoes.")
}

# --------------------------------------------------------------
# CONFERENCIA DOS 2 MODELOS A REUTILIZAR DO R10
# --------------------------------------------------------------

referencias_m2 <- list()

for (sp in especies) {
  apelido <- ifelse(
    sp == "Ipe-roxo", "ROXO", "AMARELO"
  )
  
  id_m2 <- paste0(
    "M2_", apelido, "_F",
    1:3, "_", nomes_conjuntos[[sp]],
    "_LQH_RM4"
  )
  
  for (f in 1:3) {
    z <- m2[m2$id == id_m2[f], , drop = FALSE]
    
    if (nrow(z) != 1L ||
        z$especie != sp ||
        z$fold_cv != f ||
        z$conjunto != nomes_conjuntos[[sp]] ||
        z$features != "lqh" || z$RM != 4 ||
        z$preditores != paste(
          conjuntos[[sp]], collapse = ";"
        )) {
      stop("Referencia R10 incorreta: ", id_m2[f])
    }
    
    if (f == 1L) next
  }
  
  # Apenas o RM4/LQH do R10 sera reaproveitado
  # para cada especie e seu respectivo fold.
  for (f in 1:3) {
    id <- id_m2[f]
    referencias_m2[[id]] <- list(
      modelo = file.path(
        pasta_m2, "10_MODELOS_RDS",
        paste0(id, ".rds")
      ),
      previsoes = file.path(
        pasta_m2, "10_PREVISOES_VALIDACAO",
        paste0(id, ".csv")
      )
    )
  }
}

# A grade inclui seis combinacoes LQH/RM4 (tres folds
# por especie). Vamos reutilizar as seis correspondentes
# do R10, evitando reajustes redundantes.
ids_ref <- names(referencias_m2)

arquivos_ref <- unlist(
  lapply(referencias_m2, unlist),
  use.names = FALSE
)

if (!all(file.exists(arquivos_ref))) {
  stop("Modelos ou previsoes de referencia R10 ausentes.")
}

# --------------------------------------------------------------
# SAIDA E MANIFESTO
# --------------------------------------------------------------

saida <- file.path(
  raiz, "06 - Resultados",
  "11 - MaxEnt M3 - Grade complementar B0 V3"
)

modelos_dir <- file.path(saida, "13_MODELOS_RDS")
pred_dir <- file.path(saida, "13_PREVISOES_VALIDACAO")
checkpoint_dir <- file.path(
  saida, "13_CHECKPOINT_METRICAS"
)
graf_dir <- file.path(saida, "13_GRAFICOS")

manifesto_path <- file.path(
  saida, "13_MANIFESTO_ENTRADAS.csv"
)

fontes_hash <- c(
  entradas,
  arq_m1, arq_m2,
  man_m1, man_m2,
  arquivos_ref
)

manifesto <- data.frame(
  arquivo = basename(fontes_hash),
  md5 = unname(as.character(
    tools::md5sum(fontes_hash)
  )),
  versao_script = versao,
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
  
  for (p in c(
    modelos_dir, pred_dir, checkpoint_dir, graf_dir
  )) {
    dir.create(p, recursive = TRUE)
  }
  
  write.csv(
    manifesto, manifesto_path,
    row.names = FALSE, fileEncoding = "UTF-8"
  )
} else {
  if (!file.exists(manifesto_path))
    stop("Pasta R13 existente sem manifesto.")
  
  antigo <- ler(manifesto_path)
  
  if (!identical(antigo, manifesto))
    stop("Entradas ou versoes mudaram. Nao mesclar rodadas.")
  
  for (p in c(
    modelos_dir, pred_dir, checkpoint_dir, graf_dir
  )) {
    if (!dir.exists(p))
      stop("Subpasta de checkpoints ausente: ", p)
  }
  
  cat("\nRetomando R13 com manifesto conferido.\n")
}

escrever_csv <- function(d, caminho) {
  tmp <- paste0(caminho, ".tmp")
  write.csv(
    d, tmp, row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  
  if (file.exists(caminho)) {
    if (!file.copy(tmp, caminho, overwrite = TRUE))
      stop("Falha ao atualizar: ", caminho)
    unlink(tmp)
  } else if (!file.rename(tmp, caminho)) {
    stop("Falha ao salvar: ", caminho)
  }
}

escrever_rds <- function(obj, caminho) {
  tmp <- paste0(caminho, ".tmp")
  saveRDS(obj, tmp)
  if (!file.rename(tmp, caminho))
    stop("Falha ao salvar modelo: ", caminho)
}

# --------------------------------------------------------------
# FUNCOES IDENTICAS AO PROTOCOLO R08/R10
# --------------------------------------------------------------

montar_x <- function(d, variaveis) {
  x <- d[, variaveis, drop = FALSE]
  
  for (v in intersect(continuas, variaveis)) {
    x[[v]] <- as.numeric(x[[v]])
  }
  
  if ("textura_subgrupo" %in% variaveis) {
    x$textura_subgrupo <- factor(
      as.character(x$textura_subgrupo),
      levels = as.character(classes_solo)
    )
  }
  
  if (anyNA(x))
    stop("Preditores invalidos na modelagem.")
  
  x
}

auc <- function(a, b) {
  a <- as.numeric(a)
  b <- as.numeric(b)
  
  if (!length(a) || !length(b) ||
      any(!is.finite(c(a, b)))) {
    return(NA_real_)
  }
  
  r <- rank(c(a, b), ties.method = "average")
  (sum(r[seq_along(a)]) -
      length(a) * (length(a) + 1) / 2) /
    (length(a) * length(b))
}

boyce <- function(a, b) {
  avisos <- character()
  
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
        avisos <<- c(avisos, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      avisos <<- c(avisos, conditionMessage(e))
      NULL
    }
  )
  
  valor <- NA_real_
  
  if (is.list(z) && !is.null(z$cor)) {
    valor <- as.numeric(z$cor)
  } else if (is.list(z) &&
             !is.null(z$Spearman.cor)) {
    valor <- as.numeric(z$Spearman.cor)
  }
  
  if (length(valor) != 1L ||
      !is.finite(valor) || abs(valor) > 1.000001) {
    return(list(
      valor = NA_real_,
      status = "INDEFINIDO"
    ))
  }
  
  list(
    valor = valor,
    status = if (length(avisos)) {
      paste("CALCULADO COM AVISO:",
            paste(unique(avisos), collapse = " | "))
    } else {
      "OK"
    }
  )
}

verificar_prev <- function(pp, vp, vb, met, id) {
  necessario <- c(
    "tipo", "propriedade", "score_cloglog"
  )
  
  if (!all(necessario %in% names(pp)))
    stop("Previsoes incompletas: ", id)
  
  a <- pp$score_cloglog[
    pp$tipo == "PRESENCA_VALIDACAO"
  ]
  
  b <- pp$score_cloglog[
    pp$tipo == "BACKGROUND_VALIDACAO"
  ]
  
  if (nrow(pp) != nrow(vp) + nrow(vb) ||
      length(a) != nrow(vp) ||
      length(b) != nrow(vb) ||
      any(!is.finite(c(a, b))) ||
      any(c(a, b) < 0 | c(a, b) > 1) ||
      !identical(
        as.character(pp$propriedade[
          pp$tipo == "PRESENCA_VALIDACAO"
        ]),
        as.character(vp$propriedade)
      ) ||
      !identical(
        as.character(pp$propriedade[
          pp$tipo == "BACKGROUND_VALIDACAO"
        ]),
        as.character(vb$propriedade)
      )) {
    stop("Previsoes divergentes: ", id)
  }
  
  if (abs(auc(a, b) - met$auc_validacao) > 1e-8 ||
      abs(mean(a < met$limiar10_treino_cloglog) -
          met$omissao10_validacao) > 1e-8) {
    stop("AUC ou omissao nao confere: ", id)
  }
  
  invisible(TRUE)
}

# --------------------------------------------------------------
# EXECUCAO DA GRADE
# --------------------------------------------------------------

metricas <- vector("list", nrow(grade))
set.seed(20261115)

for (i in seq_len(nrow(grade))) {
  cfg <- grade[i, ]
  
  sp <- cfg$especie
  f <- as.integer(cfg$fold_cv)
  feat <- cfg$features
  rm <- as.integer(cfg$RM)
  conjunto <- cfg$conjunto
  variaveis <- conjuntos[[sp]]
  id <- cfg$id
  
  tp <- pres[
    pres$especie == sp & pres$fold_cv != f,
    , drop = FALSE
  ]
  vp <- pres[
    pres$especie == sp & pres$fold_cv == f,
    , drop = FALSE
  ]
  tb <- bg[bg$fold_cv != f, , drop = FALSE]
  vb <- bg[bg$fold_cv == f, , drop = FALSE]
  
  if (min(nrow(tp), nrow(vp),
          nrow(tb), nrow(vb)) < 100L) {
    stop("Amostra inesperada no fold: ", id)
  }
  
  apelido <- ifelse(
    sp == "Ipe-roxo", "ROXO", "AMARELO"
  )
  
  # Identificador do modelo completo correspondente do R08.
  id_m1 <- paste0(
    "M1_", apelido, "_F", f,
    "_", toupper(feat), "_RM", rm
  )
  
  ref_m1 <- m1[m1$id == id_m1, , drop = FALSE]
  
  if (nrow(ref_m1) != 1L)
    stop("Referencia R08 ausente: ", id_m1)
  
  # Cada fold, feature e RM devem ser identicos ao M1.
  if (ref_m1$especie != sp ||
      ref_m1$fold_cv != f ||
      ref_m1$features != feat ||
      ref_m1$RM != rm) {
    stop("Configuracao M1 divergente: ", id_m1)
  }
  
  # Verificar a disponibilidade das classes de solo.
  cats_treino <- unique(c(
    as.character(tp$textura_subgrupo),
    as.character(tb$textura_subgrupo)
  ))
  
  cats_valid <- unique(c(
    as.character(vp$textura_subgrupo),
    as.character(vb$textura_subgrupo)
  ))
  
  if (!all(cats_valid %in% cats_treino))
    stop("Classe textural exclusiva da validacao: ", id)
  
  # ----------------------------------------------------------
  # REUTILIZACAO DO R10 - LQH / RM4
  # ----------------------------------------------------------
  
  reutilizar <- feat == "lqh" && rm == 4L
  
  if (reutilizar) {
    id_m2 <- paste0(
      "M2_", apelido, "_F", f,
      "_", conjunto, "_LQH_RM4"
    )
    
    ref <- m2[m2$id == id_m2, , drop = FALSE]
    
    modelo_path <- file.path(
      pasta_m2, "10_MODELOS_RDS",
      paste0(id_m2, ".rds")
    )
    
    prev_path <- file.path(
      pasta_m2, "10_PREVISOES_VALIDACAO",
      paste0(id_m2, ".csv")
    )
    
    modelo <- readRDS(modelo_path)
    pp <- ler(prev_path)
    
    if (nrow(ref) != 1L ||
        !inherits(modelo, "maxnet") ||
        length(modelo$betas) !=
        ref$n_features_ativas) {
      stop("Modelo reutilizado inconsistente: ", id_m2)
    }
    
    verificar_prev(pp, vp, vb, ref, id_m2)
    
    met <- ref[, c(
      "especie", "fold_cv", "conjunto",
      "preditores", "n_preditores",
      "features", "RM",
      "n_presenca_treino", "n_background_treino",
      "n_presenca_validacao",
      "n_background_validacao",
      "auc_treino", "auc_validacao",
      "omissao10_treino", "omissao10_validacao",
      "limiar10_treino_cloglog",
      "boyce_validacao", "status_boyce_validacao",
      "n_features_ativas"
    ), drop = FALSE]
    
    met$id <- id
    met$origem <- "R10_REUTILIZADO"
    met$segundos_ajuste <- 0
    met$modelo_rds <- modelo_path
    met$previsoes_csv <- prev_path
    
    metricas[[i]] <- met
    
    cat(sprintf(
      "[%02d/72] %s | R10 reutilizado\n", i, id
    ))
    
    next
  }
  
  # ----------------------------------------------------------
  # NOVOS AJUSTES - FEATURES / RM
  # ----------------------------------------------------------
  
  modelo_path <- file.path(
    modelos_dir, paste0(id, ".rds")
  )
  
  prev_path <- file.path(
    pred_dir, paste0(id, ".csv")
  )
  
  met_path <- file.path(
    checkpoint_dir, paste0(id, ".csv")
  )
  
  existentes <- file.exists(c(
    modelo_path, prev_path, met_path
  ))
  
  if (any(existentes) && !all(existentes)) {
    stop(
      "Checkpoint incompleto. Preserve e audite: ",
      id
    )
  }
  
  if (all(existentes)) {
    modelo <- readRDS(modelo_path)
    pp <- ler(prev_path)
    met <- ler(met_path)
    
    if (!inherits(modelo, "maxnet") ||
        nrow(met) != 1L ||
        met$id != id ||
        met$especie != sp ||
        met$fold_cv != f ||
        met$conjunto != conjunto ||
        met$features != feat ||
        met$RM != rm ||
        met$preditores !=
        paste(variaveis, collapse = ";") ||
        length(modelo$betas) !=
        met$n_features_ativas) {
      stop("Checkpoint inconsistente: ", id)
    }
    
    verificar_prev(pp, vp, vb, met, id)
    
    metricas[[i]] <- met
    
    cat(sprintf(
      "[%02d/72] %s | checkpoint OK\n", i, id
    ))
    
    next
  }
  
  xt <- montar_x(
    rbind(
      tp[, variaveis, drop = FALSE],
      tb[, variaveis, drop = FALSE]
    ),
    variaveis
  )
  
  y <- c(
    rep(1L, nrow(tp)),
    rep(0L, nrow(tb))
  )
  
  inicio <- Sys.time()
  
  fml <- maxnet::maxnet.formula(
    y, xt, classes = feat
  )
  
  modelo <- maxnet::maxnet(
    y, xt, f = fml,
    regmult = rm,
    addsamplestobackground = TRUE
  )
  
  predizer <- function(d) {
    as.numeric(stats::predict(
      modelo,
      montar_x(d, variaveis),
      type = "cloglog",
      clamp = TRUE
    ))
  }
  
  stp <- predizer(tp)
  stb <- predizer(tb)
  svp <- predizer(vp)
  svb <- predizer(vb)
  
  todos_scores <- c(stp, stb, svp, svb)
  
  if (any(!is.finite(todos_scores)) ||
      any(todos_scores < 0 |
          todos_scores > 1)) {
    stop("Previsoes invalidas: ", id)
  }
  
  limiar <- unname(as.numeric(
    stats::quantile(stp, 0.10, type = 7)
  ))
  
  ib <- boyce(svp, svb)
  
  met <- data.frame(
    especie = sp,
    fold_cv = f,
    conjunto = conjunto,
    preditores = paste(variaveis, collapse = ";"),
    n_preditores = length(variaveis),
    features = feat,
    RM = rm,
    n_presenca_treino = nrow(tp),
    n_background_treino = nrow(tb),
    n_presenca_validacao = nrow(vp),
    n_background_validacao = nrow(vb),
    auc_treino = auc(stp, stb),
    auc_validacao = auc(svp, svb),
    omissao10_treino = mean(stp < limiar),
    omissao10_validacao = mean(svp < limiar),
    limiar10_treino_cloglog = limiar,
    boyce_validacao = ib$valor,
    status_boyce_validacao = ib$status,
    n_features_ativas = length(modelo$betas),
    id = id,
    origem = "R13_NOVO",
    segundos_ajuste = as.numeric(difftime(
      Sys.time(), inicio, units = "secs"
    )),
    modelo_rds = modelo_path,
    previsoes_csv = prev_path,
    stringsAsFactors = FALSE
  )
  
  pp <- rbind(
    data.frame(
      id = id, especie = sp,
      fold_cv = f, conjunto = conjunto,
      features = feat, RM = rm,
      tipo = "PRESENCA_VALIDACAO",
      propriedade = vp$propriedade,
      score_cloglog = svp
    ),
    data.frame(
      id = id, especie = sp,
      fold_cv = f, conjunto = conjunto,
      features = feat, RM = rm,
      tipo = "BACKGROUND_VALIDACAO",
      propriedade = vb$propriedade,
      score_cloglog = svb
    )
  )
  
  verificar_prev(pp, vp, vb, met, id)
  
  escrever_rds(modelo, modelo_path)
  escrever_csv(pp, prev_path)
  escrever_csv(met, met_path)
  
  metricas[[i]] <- met
  
  cat(sprintf(
    "[%02d/72] %s | AUC=%.3f | Omissao=%.3f | Boyce=%s\n",
    i, id, met$auc_validacao,
    met$omissao10_validacao,
    if (is.finite(ib$valor))
      sprintf("%.3f", ib$valor)
    else ib$status
  ))
  
  parcial <- do.call(
    rbind,
    metricas[!vapply(
      metricas, is.null, logical(1)
    )]
  )
  
  escrever_csv(
    parcial,
    file.path(saida, "13_METRICAS_PARCIAIS.csv")
  )
}

# --------------------------------------------------------------
# CONSOLIDACAO DAS 72 AVALIACOES
# --------------------------------------------------------------

metricas <- do.call(rbind, metricas)

if (nrow(metricas) != 72L ||
    anyDuplicated(metricas$id) ||
    sum(metricas$origem == "R10_REUTILIZADO") != 6L ||
    sum(metricas$origem == "R13_NOVO") != 66L) {
  stop("Grade M3 incompleta ou inconsistente.")
}

escrever_csv(
  metricas,
  file.path(saida, "13_METRICAS_72_AVALIACOES.csv")
)

# --------------------------------------------------------------
# COMPARACAO PAREADA COM O R08
# --------------------------------------------------------------

comparacoes <- list()

for (i in seq_len(nrow(metricas))) {
  z <- metricas[i, ]
  
  id_m1 <- paste0(
    "M1_",
    ifelse(z$especie == "Ipe-roxo",
           "ROXO", "AMARELO"),
    "_F", z$fold_cv,
    "_", toupper(z$features),
    "_RM", z$RM
  )
  
  ref <- m1[m1$id == id_m1, , drop = FALSE]
  
  if (nrow(ref) != 1L)
    stop("Referencia M1 ausente: ", id_m1)
  
  comparacoes[[i]] <- data.frame(
    id_m3 = z$id,
    id_m1 = id_m1,
    especie = z$especie,
    conjunto = z$conjunto,
    fold_cv = z$fold_cv,
    features = z$features,
    RM = z$RM,
    auc_m3 = z$auc_validacao,
    auc_m1_completo = ref$auc_validacao,
    delta_auc = z$auc_validacao -
      ref$auc_validacao,
    omissao_m3 = z$omissao10_validacao,
    omissao_m1_completo =
      ref$omissao10_validacao,
    delta_omissao = z$omissao10_validacao -
      ref$omissao10_validacao,
    boyce_m3 = z$boyce_validacao,
    boyce_m1_completo = ref$boyce_validacao,
    delta_boyce = z$boyce_validacao -
      ref$boyce_validacao,
    complexidade_m3 = z$n_features_ativas,
    complexidade_m1 = ref$n_features_ativas,
    stringsAsFactors = FALSE
  )
}

comparacoes <- do.call(rbind, comparacoes)

escrever_csv(
  comparacoes,
  file.path(saida, "13_COMPARACAO_PAREADA_VS_R08.csv")
)

# --------------------------------------------------------------
# RESUMO DE CONFIGURACOES
# --------------------------------------------------------------

resumos <- list()
nr <- 0L

for (sp in especies) {
  for (feat in c("l", "lq", "lqh")) {
    for (rm in 1:4) {
      z <- metricas[
        metricas$especie == sp &
          metricas$features == feat &
          metricas$RM == rm,
        , drop = FALSE
      ]
      
      if (nrow(z) != 3L ||
          !setequal(z$fold_cv, 1:3)) {
        stop("Configuracao sem os tres folds.")
      }
      
      b <- z$boyce_validacao[
        is.finite(z$boyce_validacao)
      ]
      
      nr <- nr + 1L
      
      resumos[[nr]] <- data.frame(
        especie = sp,
        conjunto = unique(z$conjunto),
        features = feat,
        RM = rm,
        folds = 3L,
        auc_media = mean(z$auc_validacao),
        auc_dp = sd(z$auc_validacao),
        auc_min = min(z$auc_validacao),
        omissao10_media =
          mean(z$omissao10_validacao),
        omissao10_max =
          max(z$omissao10_validacao),
        boyce_media = if (length(b))
          mean(b) else NA_real_,
        boyce_min = if (length(b))
          min(b) else NA_real_,
        n_boyce_validos = length(b),
        complexidade_media =
          mean(z$n_features_ativas)
      )
    }
  }
}

resumo <- do.call(rbind, resumos)

escrever_csv(
  resumo,
  file.path(saida, "13_RESUMO_24_CONFIGURACOES.csv")
)

# --------------------------------------------------------------
# AVALIACAO POR PROPRIEDADE
# --------------------------------------------------------------

propriedades_out <- list()
np <- 0L

for (i in seq_len(nrow(metricas))) {
  z <- metricas[i, ]
  pp <- ler(z$previsoes_csv)
  
  for (pr in unique(pp$propriedade)) {
    a <- pp$score_cloglog[
      pp$propriedade == pr &
        pp$tipo == "PRESENCA_VALIDACAO"
    ]
    
    b <- pp$score_cloglog[
      pp$propriedade == pr &
        pp$tipo == "BACKGROUND_VALIDACAO"
    ]
    
    if (!length(a) || !length(b)) next
    
    suficiente <- min(length(a), length(b)) >= 10L
    
    np <- np + 1L
    
    propriedades_out[[np]] <- data.frame(
      id = z$id,
      especie = z$especie,
      conjunto = z$conjunto,
      fold_cv = z$fold_cv,
      features = z$features,
      RM = z$RM,
      propriedade = pr,
      n_presencas = length(a),
      n_background = length(b),
      auc_propriedade = if (suficiente)
        auc(a, b) else NA_real_,
      omissao10_propriedade =
        mean(a < z$limiar10_treino_cloglog),
      status_auc = if (suficiente)
        "OK" else "AMOSTRA_PEQUENA"
    )
  }
}

if (length(propriedades_out)) {
  escrever_csv(
    do.call(rbind, propriedades_out),
    file.path(
      saida, "13_AUC_OMISSAO_POR_PROPRIEDADE.csv"
    )
  )
}

# --------------------------------------------------------------
# GRAFICOS EXPLORATORIOS
# --------------------------------------------------------------

for (sp in especies) {
  z <- resumo[resumo$especie == sp, ]
  
  for (indicador in c(
    "auc_media", "omissao10_media", "boyce_media"
  )) {
    nome <- paste0(
      "13_",
      ifelse(sp == "Ipe-roxo", "ROXO", "AMARELO"),
      "_", toupper(indicador), ".png"
    )
    
    png(
      file.path(graf_dir, nome),
      width = 1100, height = 730, res = 135
    )
    
    ylim <- if (indicador == "boyce_media")
      c(-1, 1) else c(0, 1)
    
    plot(
      1:4, rep(NA_real_, 4),
      type = "n",
      xlim = c(1, 4),
      ylim = ylim,
      xaxt = "n",
      xlab = "Multiplicador de regularizacao (RM)",
      ylab = indicador,
      main = paste("MaxEnt M3 -", sp, "-", indicador)
    )
    
    axis(1, at = 1:4)
    
    cores <- c("gray20", "gray50", "gray75")
    grupos <- c("l", "lq", "lqh")
    
    for (j in seq_along(grupos)) {
      zz <- z[z$features == grupos[j], ]
      zz <- zz[order(zz$RM), ]
      
      lines(
        zz$RM, zz[[indicador]],
        type = "b", lwd = 2,
        pch = 14 + j,
        col = cores[j]
      )
    }
    
    legend(
      "topright",
      legend = toupper(grupos),
      lty = 1, pch = 15:17,
      col = cores,
      bty = "n"
    )
    
    dev.off()
  }
}

# --------------------------------------------------------------
# DOCUMENTACAO
# --------------------------------------------------------------

writeLines(
  c(
    "TCC IPES - R13 V3 - M3 - Background B0",
    "",
    "Grade de 72 avaliacoes:",
    "2 especies x 3 folds x 3 features x 4 RM.",
    "",
    "Ipe-roxo: sem BIO12 e BIO17.",
    "Ipe-amarelo: sem BIO12.",
    "",
    "Referencia: 72 modelos completos do R08.",
    "Seis modelos LQH/RM4 reutilizados do R10.",
    "66 ajustes novos nesta rodada.",
    "",
    "Background B0: 5000 pontos.",
    "Mesmas UPAs, propriedades e folds do R05.",
    "Solo categorico. Previsao cloglog.",
    "Clamping TRUE.",
    "Omissao10: limiar definido no treino.",
    "AUC: presencas versus background.",
    "Boyce: ecospat.",
    "",
    "Resultados de R01-R12 preservados.",
    "Teste externo: NAO utilizado.",
    "A rodada NAO seleciona automaticamente vencedor.",
    "O desenho espacial permanece exploratorio.",
    "A escolha dos conjuntos foi informada pelo R10:",
    "interpretar resultados como sensibilidade exploratoria.",
    "",
    paste("Data:", as.character(Sys.time())),
    paste("R:", R.version.string),
    paste(
      "maxnet:",
      as.character(utils::packageVersion("maxnet"))
    ),
    paste(
      "ecospat:",
      as.character(utils::packageVersion("ecospat"))
    )
  ),
  file.path(saida, "13_LEIA_RESULTADOS.txt")
)

writeLines(
  capture.output(sessionInfo()),
  file.path(saida, "13_SESSION_INFO.txt")
)

cat("\n========================================\n")
cat("R13 CONCLUIDO!\n")
cat("72 avaliacoes: 66 novas e 6 reutilizadas.\n")
cat("Resultados:\n", saida, "\n")
cat("========================================\n")
