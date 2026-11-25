
# ============================================================
# TCC IPES - R19 V1
# MAXENT M1 - BACKGROUND B2 - 10.000 PONTOS
#
# 2 especies x 3 folds x 3 features x 4 RM = 72 modelos
#
# Comparacao controlada:
# B0 - 5.000 pontos (R08)
# B1 - 10.000 pontos com B0 fixa (R16)
# B2 - 10.000 pontos sorteados novamente (R18)
#
# Mesmas presencas, folds, variaveis e parametros.
# AUC e Boyce comparativos com background B0 fixo.
# Omissao10 calculada com limiar do treinamento.
#
# Salva modelos, previsoes, metricas e checkpoints.
# Nao utiliza as sete propriedades de teste externo.
# Nao altera arquivos e resultados anteriores.
# ============================================================

R19 <- function() {
  
  # ----------------------------------------------------------
  # 0 - PACOTES E CONFIGURACOES
  # ----------------------------------------------------------
  
  for (pacote in c("maxnet", "ecospat")) {
    if (!requireNamespace(pacote, quietly = TRUE)) {
      stop("Instale o pacote: ", pacote)
    }
  }
  
  VERSAO <- "R19_M1_B2_V1_20261116"
  
  variaveis <- c(
    "altitude_m",
    "declividade_graus",
    "dist_rio_raster_m",
    "bio12_mm_ano",
    "bio17_mm_mes",
    "textura_subgrupo"
  )
  
  continuas <- variaveis[1:5]
  especies <- c("Ipe-roxo", "Ipe-amarelo")
  
  ler <- function(f) {
    read.csv(
      f,
      fileEncoding = "UTF-8-BOM",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  
  salvar <- function(x, f) {
    temporario <- tempfile(
      pattern = "R19_",
      tmpdir = dirname(f),
      fileext = ".tmp"
    )
    
    write.csv(
      x, temporario,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
    
    if (!file.copy(
      temporario, f,
      overwrite = TRUE
    )) {
      stop("Falha ao salvar: ", f)
    }
    
    unlink(temporario)
  }
  
  md5 <- function(f) {
    unname(as.character(tools::md5sum(f)))
  }
  
  exigir <- function(condicao, mensagem) {
    if (!isTRUE(condicao)) {
      stop(mensagem, call. = FALSE)
    }
  }
  
  normalizar <- function(x) {
    z <- iconv(
      as.character(x),
      to = "ASCII//TRANSLIT",
      sub = ""
    )
    
    trimws(gsub(
      "[^A-Z0-9]+", " ",
      toupper(z)
    ))
  }
  
  media <- function(x) {
    x <- as.numeric(x)
    x <- x[is.finite(x)]
    if (!length(x)) return(NA_real_)
    mean(x)
  }
  
  auc <- function(presencas, background) {
    a <- as.numeric(presencas)
    b <- as.numeric(background)
    
    if (
      !length(a) || !length(b) ||
      any(!is.finite(c(a, b)))
    ) return(NA_real_)
    
    r <- rank(
      c(a, b),
      ties.method = "average"
    )
    
    (
      sum(r[seq_along(a)]) -
        length(a) * (length(a) + 1) / 2
    ) / (length(a) * length(b))
  }
  
  boyce <- function(presencas, background) {
    avisos <- character()
    
    z <- tryCatch(
      withCallingHandlers(
        ecospat::ecospat.boyce(
          fit = as.numeric(background),
          obs = as.numeric(presencas),
          nclass = 0,
          PEplot = FALSE,
          method = "spearman",
          rm.duplicate = TRUE
        ),
        warning = function(w) {
          avisos <<- c(
            avisos,
            conditionMessage(w)
          )
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) {
        avisos <<- c(
          avisos,
          conditionMessage(e)
        )
        NULL
      }
    )
    
    valor <- NA_real_
    
    if (!is.null(z$cor)) {
      valor <- as.numeric(z$cor)
    } else if (!is.null(z$Spearman.cor)) {
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
  
  cat("\n========================================\n")
  cat("TCC IPES - R19\n")
  cat("MAXENT M1 / BACKGROUND B2\n")
  cat("72 MODELOS - 10.000 PONTOS NOVOS\n")
  cat("========================================\n")
  
  # ----------------------------------------------------------
  # 1 - LOCALIZAR OS ARQUIVOS
  # ----------------------------------------------------------
  
  cat("\nSelecione 18_BACKGROUND_B2_10000_COM_FOLDS.csv\n")
  
  arq_b2 <- normalizePath(
    file.choose(),
    winslash = "/",
    mustWork = TRUE
  )
  
  exigir(
    basename(arq_b2) ==
      "18_BACKGROUND_B2_10000_COM_FOLDS.csv",
    "Selecione o background B2 final do R18."
  )
  
  raiz <- dirname(arq_b2)
  
  repeat {
    if (
      dir.exists(file.path(
        raiz, "04 - Dados para o MaxEnt"
      )) &&
      dir.exists(file.path(
        raiz, "06 - Resultados"
      ))
    ) break
    
    acima <- dirname(raiz)
    
    exigir(
      acima != raiz,
      "Raiz do TCC nao localizada."
    )
    
    raiz <- acima
  }
  
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
  
  pasta_r16 <- file.path(
    raiz,
    "06 - Resultados",
    "14 - MaxEnt M1 - B1 10000 V3"
  )
  
  pasta_r18 <- dirname(arq_b2)
  
  arq_pres <- file.path(
    pasta_r05, "05_PRESENCAS_UM_POR_PIXEL_30M.csv"
  )
  
  arq_b0 <- file.path(
    pasta_r05, "05_BACKGROUND_COM_FOLDS.csv"
  )
  
  arq_m08 <- file.path(
    pasta_r08, "08_METRICAS_72_MODELOS.csv"
  )
  
  arq_man08 <- file.path(
    pasta_r08, "08_MANIFESTO_ENTRADAS.csv"
  )
  
  arq_m16 <- file.path(
    pasta_r16, "16_METRICAS_72_MODELOS_B1.csv"
  )
  
  arq_man16 <- file.path(
    pasta_r16, "16_MANIFESTO_ENTRADAS.csv"
  )
  
  arq_man18 <- file.path(
    pasta_r18, "18_MANIFESTO_ENTRADAS.csv"
  )
  
  arq_cotas18 <- file.path(
    pasta_r18,
    "18_COTAS_E_SOBREPOSICOES_POR_UPA.csv"
  )
  
  arq_qa18 <- file.path(
    pasta_r18, "18_QA_POR_PROPRIEDADE.csv"
  )
  
  entradas_iniciais <- c(
    arq_pres, arq_b0,
    arq_m08, arq_man08,
    arq_m16, arq_man16,
    arq_b2, arq_man18,
    arq_cotas18, arq_qa18
  )
  
  exigir(
    all(file.exists(entradas_iniciais)),
    paste(
      "Arquivos ausentes:\n",
      paste(
        entradas_iniciais[
          !file.exists(entradas_iniciais)
        ],
        collapse = "\n"
      )
    )
  )
  
  # Localizar automaticamente a B1 do R15,
  # usando o MD5 registrado no R16.
  man16 <- ler(arq_man16)
  
  ref_b1 <- man16[
    man16$arquivo ==
      "15_BACKGROUND_B1_10000_COM_FOLDS.csv",
    , drop = FALSE
  ]
  
  exigir(
    nrow(ref_b1) == 1L,
    "B1 nao identificada no manifesto R16."
  )
  
  pasta_b1 <- file.path(
    raiz,
    "06 - Resultados",
    "13 - Preparacao do background B1 10000 V3_5"
  )
  
  candidatos <- list.files(
    pasta_b1,
    pattern = "^15_BACKGROUND_B1_10000_COM_FOLDS[.]csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  exigir(
    length(candidatos) > 0,
    "B1 original do R15 nao encontrada."
  )
  
  candidatos <- candidatos[
    tolower(md5(candidatos)) ==
      tolower(ref_b1$md5)
  ]
  
  exigir(
    length(candidatos) >= 1L,
    "Nenhum arquivo B1 corresponde ao MD5 do R16."
  )
  
  arq_b1 <- candidatos[1]
  
  # ----------------------------------------------------------
  # 2 - AUDITORIA DAS ENTRADAS
  # ----------------------------------------------------------
  
  cat("\nETAPA 1 - Auditando B0, B1 e B2...\n")
  
  pres <- ler(arq_pres)
  b0 <- ler(arq_b0)
  b1 <- ler(arq_b1)
  b2 <- ler(arq_b2)
  
  m08 <- ler(arq_m08)
  m16 <- ler(arq_m16)
  man08 <- ler(arq_man08)
  man18 <- ler(arq_man18)
  
  cotas18 <- ler(arq_cotas18)
  qa18 <- ler(arq_qa18)
  
  exigir(
    nrow(pres) == 8680L &&
      nrow(b0) == 5000L &&
      nrow(b1) == 10000L &&
      nrow(b2) == 10000L &&
      nrow(m08) == 72L &&
      nrow(m16) == 72L &&
      nrow(cotas18) == 64L &&
      nrow(qa18) == 27L,
    "Contagens diferentes do protocolo original."
  )
  
  campos_bg <- c(
    "id_background", "propriedade",
    "upa_id", "fold_cv", "celula_raster",
    "longitude", "latitude", variaveis
  )
  
  campos_pres <- c(
    "especie", "propriedade", "upa_id",
    "fold_cv", variaveis
  )
  
  for (d in list(b0, b1, b2)) {
    exigir(
      all(campos_bg %in% names(d)),
      "Background com colunas ausentes."
    )
  }
  
  exigir(
    all(campos_pres %in% names(pres)),
    "Presencas com colunas ausentes."
  )
  
  exigir(
    all(c(
      "id", "especie", "fold_cv",
      "features", "RM",
      "auc_validacao",
      "boyce_validacao",
      "omissao10_validacao",
      "n_presenca_validacao",
      "n_background_validacao"
    ) %in% names(m08)),
    "Metricas R08 incompletas."
  )
  
  exigir(
    all(c(
      "id", "id_m1_b0",
      "auc_validacao_bg_b0_fixo",
      "boyce_validacao_bg_b0_fixo",
      "omissao10_validacao"
    ) %in% names(m16)),
    "Metricas R16 incompletas."
  )
  
  # Conferir MD5 das fontes originais usadas no R16.
  for (f in c(arq_pres, arq_b0, arq_m08, arq_man08)) {
    z <- man16[
      man16$arquivo == basename(f),
      , drop = FALSE
    ]
    
    exigir(
      nrow(z) == 1L &&
        tolower(md5(f)) == tolower(z$md5),
      paste(
        "Fonte alterada desde o R16:",
        basename(f)
      )
    )
  }
  
  # Conferencia complementar com o R08.
  for (f in c(arq_pres, arq_b0)) {
    z <- man08[
      man08$arquivo == basename(f),
      , drop = FALSE
    ]
    
    exigir(
      nrow(z) == 1L &&
        tolower(md5(f)) == tolower(z$md5),
      paste("Arquivo diferente do R08:", basename(f))
    )
  }
  
  # Conferir a B1 registrada no R18.
  for (f in c(arq_b0, arq_b1)) {
    z <- man18[
      basename(man18$caminho) == basename(f),
      , drop = FALSE
    ]
    
    exigir(
      nrow(z) == 1L &&
        tolower(md5(f)) == tolower(z$md5),
      paste("Fonte diferente do R18:", basename(f))
    )
  }
  
  for (d in list(pres, b0, b1, b2)) {
    exigir(
      all(c(variaveis, "fold_cv") %in% names(d)),
      "Colunas ambientais incompletas."
    )
  }
  
  # Preservar o mesmo tratamento numerico e
  # as mesmas classes de solo utilizadas no R16.
  for (nome in c("pres", "b0", "b1", "b2")) {
    d <- get(nome)
    
    for (v in c(variaveis, "fold_cv")) {
      d[[v]] <- as.numeric(d[[v]])
    }
    
    exigir(
      !anyNA(d[, c(variaveis, "fold_cv"),
               drop = FALSE]) &&
        all(is.finite(as.matrix(
          d[, variaveis, drop = FALSE
          ]))),
      paste("Preditores invalidos em", nome)
    )
    
    assign(nome, d)
  }
  
  exigir(
    sum(pres$especie == "Ipe-roxo") == 3248L &&
      sum(pres$especie == "Ipe-amarelo") == 5432L,
    "Quantidade de presencas alterada."
  )
  
  solo <- sort(unique(c(
    pres$textura_subgrupo,
    b0$textura_subgrupo,
    b1$textura_subgrupo,
    b2$textura_subgrupo
  )))
  
  exigir(
    identical(
      as.integer(solo),
      c(2L, 3L, 4L, 6L, 7L)
    ),
    "Classes de solo diferentes do R08/R16."
  )
  
  for (d in list(b0, b1, b2)) {
    exigir(
      !anyDuplicated(d$id_background) &&
        !anyDuplicated(paste(
          d$propriedade,
          d$longitude,
          d$latitude,
          sep = "|"
        )),
      "IDs ou coordenadas duplicadas no background."
    )
    
    exigir(
      length(unique(d$propriedade)) == 27L &&
        length(unique(paste(
          d$propriedade, d$upa_id,
          sep = "||"
        ))) == 64L,
      "Dominio de propriedades ou UPAs diferente."
    )
  }
  
  # As cotas da B2 devem ser identicas as da B1.
  chaves_b2 <- paste(
    b2$propriedade,
    b2$upa_id,
    sep = "||"
  )
  
  contagens <- table(
    factor(
      chaves_b2,
      levels = cotas18$chave
    )
  )
  
  exigir(
    identical(
      as.integer(contagens),
      as.integer(cotas18$n_b2)
    ) &&
      sum(cotas18$n_b2) == 10000L &&
      sum(cotas18$n_b1) == 10000L &&
      all(cotas18$n_b2 == cotas18$n_b1) &&
      sum(cotas18$pixels_disponiveis) == 570227L,
    "Cotas da B2 diferentes das auditadas."
  )
  
  exigir(
    sum(qa18$pixels_elegiveis) == 570227L &&
      sum(qa18$pontos_b2) == 10000L &&
      all(qa18$max_diferenca_b0 < 1e-7) &&
      all(qa18$max_diferenca_b1 < 1e-7),
    "QA ambiental do R18 divergente."
  )
  
  exigir(
    all(b2$origem_amostra == "B2_SORTEIO_NOVO"),
    "Origem dos pontos B2 inesperada."
  )
  
  # Conferir que uma propriedade permanece no
  # mesmo fold em todas as bases.
  particao <- unique(rbind(
    pres[, c("propriedade", "fold_cv")],
    b0[, c("propriedade", "fold_cv")],
    b1[, c("propriedade", "fold_cv")],
    b2[, c("propriedade", "fold_cv")]
  ))
  
  exigir(
    nrow(particao) == 27L &&
      !anyDuplicated(particao$propriedade) &&
      setequal(particao$fold_cv, 1:3),
    "Folds espaciais foram alterados."
  )
  
  externas <- normalizar(c(
    "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
    "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
  ))
  
  exigir(
    !any(normalizar(particao$propriedade) %in% externas),
    "Teste externo encontrado nas entradas."
  )
  
  # Conferir os totais por fold.
  for (f in 1:3) {
    exigir(
      sum(b0$fold_cv == f) ==
        c(1851, 1750, 1399)[f] &&
        sum(b1$fold_cv == f) ==
        c(3671, 3516, 2813)[f] &&
        sum(b2$fold_cv == f) ==
        c(3671, 3516, 2813)[f],
      paste("Contagem de background errada no fold", f)
    )
  }
  
  cat("AUDITORIA INICIAL: OK\n")
  cat("Presencas: 8680\n")
  cat("B0: 5000 pontos\n")
  cat("B1: 10000 pontos\n")
  cat("B2: 10000 pontos\n")
  cat("27 propriedades, 64 UPAs e 3 folds.\n")
  
  # ----------------------------------------------------------
  # 3 - MATRIZ AMBIENTAL E GRADE DE MODELOS
  # ----------------------------------------------------------
  
  montar_x <- function(d) {
    x <- d[, variaveis, drop = FALSE]
    
    for (v in continuas) {
      x[[v]] <- as.numeric(x[[v]])
    }
    
    x$textura_subgrupo <- factor(
      as.character(x$textura_subgrupo),
      levels = as.character(solo)
    )
    
    exigir(
      !anyNA(x),
      "Matriz ambiental com valores ausentes."
    )
    
    x
  }
  
  grade <- expand.grid(
    especie = especies,
    fold_cv = 1:3,
    features = c("l", "lq", "lqh"),
    RM = 1:4,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  
  sufixo <- function(z) {
    paste0(
      ifelse(
        z$especie == "Ipe-roxo",
        "ROXO", "AMARELO"
      ),
      "_F", z$fold_cv,
      "_", toupper(z$features),
      "_RM", z$RM
    )
  }
  
  grade$id_b0 <- paste0(
    "M1_", vapply(
      seq_len(nrow(grade)),
      function(i) sufixo(grade[i, ]),
      character(1)
    )
  )
  
  grade$id_b1 <- sub(
    "^M1_", "M1B1_", grade$id_b0
  )
  
  grade$id_b2 <- sub(
    "^M1_", "M1B2_", grade$id_b0
  )
  
  exigir(
    nrow(grade) == 72L &&
      !anyDuplicated(grade$id_b2) &&
      setequal(grade$id_b0, m08$id) &&
      setequal(grade$id_b1, m16$id),
    "Grade de modelos diferente do R08/R16."
  )
  
  # ----------------------------------------------------------
  # 4 - RESULTADOS E CHECKPOINTS
  # ----------------------------------------------------------
  
  saida <- file.path(
    raiz,
    "06 - Resultados",
    "17 - MaxEnt M1 - B2 10000 V1"
  )
  
  pasta_ck <- file.path(
    saida, "19_CHECKPOINTS"
  )
  
  pasta_mod <- file.path(
    saida, "19_MODELOS_RDS"
  )
  
  pasta_prev <- file.path(
    saida, "19_PREVISOES_VALIDACAO"
  )
  
  pasta_graf <- file.path(
    saida, "19_GRAFICOS"
  )
  
  dir.create(
    saida,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  manifest_path <- file.path(
    saida, "19_MANIFESTO_ENTRADAS.csv"
  )
  
  entradas <- c(
    arq_pres, arq_b0, arq_b1, arq_b2,
    arq_m08, arq_m16,
    arq_man08, arq_man16, arq_man18,
    arq_cotas18, arq_qa18
  )
  
  manifest <- data.frame(
    arquivo = basename(entradas),
    caminho = normalizePath(
      entradas, winslash = "/",
      mustWork = TRUE
    ),
    md5 = md5(entradas),
    script = VERSAO,
    R = R.version.string,
    maxnet = as.character(
      utils::packageVersion("maxnet")
    ),
    ecospat = as.character(
      utils::packageVersion("ecospat")
    ),
    stringsAsFactors = FALSE
  )
  
  if (file.exists(manifest_path)) {
    exigir(
      identical(ler(manifest_path), manifest),
      paste(
        "A pasta R19 ja existe com entradas",
        "ou versoes diferentes. Nao sobrescrever."
      )
    )
  } else {
    exigir(
      !length(list.files(saida)),
      "Pasta R19 existente sem manifesto."
    )
    
    salvar(manifest, manifest_path)
  }
  
  for (d in c(
    pasta_ck, pasta_mod,
    pasta_prev, pasta_graf
  )) {
    dir.create(
      d,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }
  
  assinatura <- paste(
    c(
      VERSAO,
      manifest$md5,
      manifest$R,
      manifest$maxnet,
      manifest$ecospat
    ),
    collapse = "|"
  )
  
  # ----------------------------------------------------------
  # 5 - AJUSTAR OS 72 MODELOS COM B2
  # ----------------------------------------------------------
  
  cat("\nETAPA 2 - Executando 72 ajustes M1/B2...\n")
  
  metricas_lista <- vector(
    "list", nrow(grade)
  )
  
  props_lista <- vector(
    "list", nrow(grade)
  )
  
  for (i in seq_len(nrow(grade))) {
    
    cfg <- grade[i, ]
    
    sp <- cfg$especie
    f <- as.integer(cfg$fold_cv)
    feat <- cfg$features
    rm <- as.integer(cfg$RM)
    id <- cfg$id_b2
    
    treino_p <- pres[
      pres$especie == sp &
        pres$fold_cv != f,
      , drop = FALSE
    ]
    
    valid_p <- pres[
      pres$especie == sp &
        pres$fold_cv == f,
      , drop = FALSE
    ]
    
    treino_b2 <- b2[
      b2$fold_cv != f,
      , drop = FALSE
    ]
    
    valid_b2 <- b2[
      b2$fold_cv == f,
      , drop = FALSE
    ]
    
    valid_b1 <- b1[
      b1$fold_cv == f,
      , drop = FALSE
    ]
    
    valid_b0 <- b0[
      b0$fold_cv == f,
      , drop = FALSE
    ]
    
    exigir(
      min(
        nrow(treino_p),
        nrow(valid_p),
        nrow(treino_b2),
        nrow(valid_b2),
        nrow(valid_b1),
        nrow(valid_b0)
      ) > 0,
      paste("Particao vazia:", id)
    )
    
    arq_ck <- file.path(
      pasta_ck, paste0(id, ".rds")
    )
    
    arq_mod <- file.path(
      pasta_mod, paste0(id, ".rds")
    )
    
    arq_prev <- file.path(
      pasta_prev, paste0(id, ".csv")
    )
    
    # --------------------------------------------------------
    # 5.1 - RECUPERAR CHECKPOINT OU AJUSTAR
    # --------------------------------------------------------
    
    if (file.exists(arq_ck)) {
      
      ck <- readRDS(arq_ck)
      
      exigir(
        identical(ck$assinatura, assinatura) &&
          identical(ck$id, id) &&
          inherits(ck$modelo, "maxnet") &&
          nrow(ck$metrica) == 1L &&
          ck$metrica$id == id,
        paste("Checkpoint inconsistente:", id)
      )
      
      modelo <- ck$modelo
      met <- ck$metrica
      prev <- ck$previsoes
      prop_tab <- ck$propriedades
      
      cat(sprintf(
        "[%02d/72] %s | recuperado\n",
        i, id
      ))
      
    } else {
      
      inicio <- Sys.time()
      set.seed(20261119L + i)
      
      x_treino <- montar_x(rbind(
        treino_p[, variaveis, drop = FALSE],
        treino_b2[, variaveis, drop = FALSE]
      ))
      
      y <- c(
        rep(1L, nrow(treino_p)),
        rep(0L, nrow(treino_b2))
      )
      
      formula <- maxnet::maxnet.formula(
        y,
        x_treino,
        classes = feat
      )
      
      modelo <- maxnet::maxnet(
        y,
        x_treino,
        f = formula,
        regmult = rm,
        addsamplestobackground = TRUE
      )
      
      predizer <- function(d) {
        as.numeric(stats::predict(
          modelo,
          montar_x(d),
          type = "cloglog",
          clamp = TRUE
        ))
      }
      
      # Treinamento.
      pt <- predizer(treino_p)
      bt <- predizer(treino_b2)
      
      # Validacao, preservando o mesmo fold.
      pv <- predizer(valid_p)
      
      bv2 <- predizer(valid_b2)
      bv1 <- predizer(valid_b1)
      bv0 <- predizer(valid_b0)
      
      exigir(
        all(is.finite(c(
          pt, bt, pv, bv2, bv1, bv0
        ))) &&
          all(c(
            pt, bt, pv, bv2, bv1, bv0
          ) >= 0) &&
          all(c(
            pt, bt, pv, bv2, bv1, bv0
          ) <= 1),
        paste("Previsoes invalidas:", id)
      )
      
      # Limiar 10% determinado nas
      # presencas de TREINAMENTO.
      limiar10 <- as.numeric(
        stats::quantile(
          pt,
          probs = 0.10,
          type = 7
        )
      )
      
      boyce2 <- boyce(pv, bv2)
      boyce1 <- boyce(pv, bv1)
      boyce0 <- boyce(pv, bv0)
      
      met <- data.frame(
        id = id,
        id_m1_b0 = cfg$id_b0,
        id_m1_b1 = cfg$id_b1,
        
        especie = sp,
        fold_cv = f,
        features = feat,
        RM = rm,
        
        n_presenca_treino = nrow(treino_p),
        n_background_treino = nrow(treino_b2),
        
        n_presenca_validacao = nrow(valid_p),
        n_background_validacao = nrow(valid_b2),
        n_background_b1_fixo = nrow(valid_b1),
        n_background_b0_fixo = nrow(valid_b0),
        
        auc_treino = auc(pt, bt),
        auc_validacao = auc(pv, bv2),
        auc_validacao_bg_b1_fixo = auc(pv, bv1),
        auc_validacao_bg_b0_fixo = auc(pv, bv0),
        
        boyce_validacao = boyce2$valor,
        status_boyce_validacao = boyce2$status,
        
        boyce_validacao_bg_b1_fixo = boyce1$valor,
        status_boyce_bg_b1_fixo = boyce1$status,
        
        boyce_validacao_bg_b0_fixo = boyce0$valor,
        status_boyce_bg_b0_fixo = boyce0$status,
        
        limiar10_treino_cloglog = limiar10,
        
        omissao10_treino = mean(pt < limiar10),
        omissao10_validacao = mean(pv < limiar10),
        
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
        background = "B2_10000",
        stringsAsFactors = FALSE
      )
      
      # Previsoes individuais de validacao.
      partes <- list(
        list(
          tipo = "PRESENCA_VALIDACAO",
          dados = valid_p,
          score = pv
        ),
        list(
          tipo = "BACKGROUND_B2_VALIDACAO",
          dados = valid_b2,
          score = bv2
        ),
        list(
          tipo = "BACKGROUND_B1_FIXO",
          dados = valid_b1,
          score = bv1
        ),
        list(
          tipo = "BACKGROUND_B0_FIXO",
          dados = valid_b0,
          score = bv0
        )
      )
      
      prev <- do.call(
        rbind,
        lapply(partes, function(z) {
          data.frame(
            id = id,
            especie = sp,
            fold_cv = f,
            features = feat,
            RM = rm,
            tipo = z$tipo,
            propriedade = z$dados$propriedade,
            score_cloglog = z$score,
            stringsAsFactors = FALSE
          )
        })
      )
      
      rownames(prev) <- NULL
      
      # ------------------------------------------------------
      # 5.2 - AVALIACAO POR PROPRIEDADE
      # ------------------------------------------------------
      
      prop_lista <- list()
      
      for (pr in unique(valid_p$propriedade)) {
        
        a <- pv[
          valid_p$propriedade == pr
        ]
        
        z0 <- bv0[
          valid_b0$propriedade == pr
        ]
        
        z1 <- bv1[
          valid_b1$propriedade == pr
        ]
        
        z2 <- bv2[
          valid_b2$propriedade == pr
        ]
        
        prop_lista[[
          length(prop_lista) + 1L
        ]] <- data.frame(
          id = id,
          especie = sp,
          fold_cv = f,
          features = feat,
          RM = rm,
          propriedade = pr,
          
          n_presencas = length(a),
          n_bg_b0 = length(z0),
          n_bg_b1 = length(z1),
          n_bg_b2 = length(z2),
          
          auc_bg_b0_fixo =
            if (min(length(a), length(z0)) >= 10) {
              auc(a, z0)
            } else NA_real_,
          
          auc_bg_b1_fixo =
            if (min(length(a), length(z1)) >= 10) {
              auc(a, z1)
            } else NA_real_,
          
          auc_bg_b2 =
            if (min(length(a), length(z2)) >= 10) {
              auc(a, z2)
            } else NA_real_,
          
          omissao10 = mean(a < limiar10),
          
          stringsAsFactors = FALSE
        )
      }
      
      prop_tab <- do.call(
        rbind, prop_lista
      )
      
      # Um checkpoint guarda o conjunto completo
      # de resultados desse modelo.
      ck <- list(
        assinatura = assinatura,
        id = id,
        modelo = modelo,
        metrica = met,
        previsoes = prev,
        propriedades = prop_tab
      )
      
      temporario <- paste0(
        arq_ck, ".tmp"
      )
      
      saveRDS(ck, temporario)
      
      exigir(
        file.rename(temporario, arq_ck),
        paste("Nao foi possivel salvar:", id)
      )
    }
    
    # --------------------------------------------------------
    # 5.3 - AUDITAR O MODELO
    # --------------------------------------------------------
    
    exigir(
      nrow(prev) ==
        nrow(valid_p) +
        nrow(valid_b0) +
        nrow(valid_b1) +
        nrow(valid_b2),
      paste("Previsoes incompletas:", id)
    )
    
    ap <- prev$score_cloglog[
      prev$tipo == "PRESENCA_VALIDACAO"
    ]
    
    ab2 <- prev$score_cloglog[
      prev$tipo == "BACKGROUND_B2_VALIDACAO"
    ]
    
    ab1 <- prev$score_cloglog[
      prev$tipo == "BACKGROUND_B1_FIXO"
    ]
    
    ab0 <- prev$score_cloglog[
      prev$tipo == "BACKGROUND_B0_FIXO"
    ]
    
    exigir(
      length(ap) == nrow(valid_p) &&
        length(ab2) == nrow(valid_b2) &&
        length(ab1) == nrow(valid_b1) &&
        length(ab0) == nrow(valid_b0) &&
        all(is.finite(c(ap, ab2, ab1, ab0))),
      paste("Tamanhos da validacao incorretos:", id)
    )
    
    exigir(
      abs(auc(ap, ab2) -
            met$auc_validacao) < 1e-9 &&
        abs(auc(ap, ab1) -
              met$auc_validacao_bg_b1_fixo) < 1e-9 &&
        abs(auc(ap, ab0) -
              met$auc_validacao_bg_b0_fixo) < 1e-9 &&
        abs(
          mean(ap < met$limiar10_treino_cloglog) -
            met$omissao10_validacao
        ) < 1e-9,
      paste("Metricas divergentes:", id)
    )
    
    exigir(
      sum(prop_tab$n_presencas) ==
        nrow(valid_p) &&
        abs(
          sum(
            prop_tab$n_presencas *
              prop_tab$omissao10
          ) / nrow(valid_p) -
            met$omissao10_validacao
        ) < 1e-9,
      paste("Metricas por propriedade divergentes:", id)
    )
    
    # Salvar tambem objetos individuais
    # para os diagnosticos posteriores.
    if (!file.exists(arq_mod)) {
      saveRDS(modelo, arq_mod)
    }
    
    salvar(prev, arq_prev)
    
    metricas_lista[[i]] <- met
    props_lista[[i]] <- prop_tab
    
    parcial <- do.call(
      rbind,
      metricas_lista[
        !vapply(
          metricas_lista,
          is.null,
          logical(1)
        )
      ]
    )
    
    salvar(
      parcial,
      file.path(
        saida, "19_METRICAS_PARCIAIS.csv"
      )
    )
    
    cat(sprintf(
      "[%02d/72] %s | AUC B2=%.3f | AUC fixa=%.3f | Omissao=%.3f\n",
      i, id,
      met$auc_validacao,
      met$auc_validacao_bg_b0_fixo,
      met$omissao10_validacao
    ))
  }
  
  # ----------------------------------------------------------
  # 6 - CONSOLIDAR OS 72 RESULTADOS
  # ----------------------------------------------------------
  
  cat("\nETAPA 3 - Consolidando 72 modelos...\n")
  
  metricas <- do.call(
    rbind, metricas_lista
  )
  
  propriedades <- do.call(
    rbind, props_lista
  )
  
  rownames(metricas) <- NULL
  rownames(propriedades) <- NULL
  
  exigir(
    nrow(metricas) == 72L &&
      !anyDuplicated(metricas$id),
    "Resultados M1/B2 incompletos."
  )
  
  salvar(
    metricas,
    file.path(
      saida, "19_METRICAS_72_MODELOS_B2.csv"
    )
  )
  
  salvar(
    propriedades,
    file.path(
      saida, "19_AUC_OMISSAO_POR_PROPRIEDADE.csv"
    )
  )
  
  # ----------------------------------------------------------
  # 7 - COMPARACAO PAREADA B0 / B1 / B2
  # ----------------------------------------------------------
  
  cat("\nETAPA 4 - Comparando B0, B1 e B2...\n")
  
  comparacoes <- list()
  
  for (i in seq_len(nrow(metricas))) {
    
    z <- metricas[i, ]
    
    ref0 <- m08[
      m08$id == z$id_m1_b0,
      , drop = FALSE
    ]
    
    ref1 <- m16[
      m16$id == z$id_m1_b1,
      , drop = FALSE
    ]
    
    exigir(
      nrow(ref0) == 1L &&
        nrow(ref1) == 1L,
      paste("Referencia ausente:", z$id)
    )
    
    exigir(
      ref0$especie == z$especie &&
        ref1$especie == z$especie &&
        ref0$fold_cv == z$fold_cv &&
        ref1$fold_cv == z$fold_cv &&
        ref0$features == z$features &&
        ref1$features == z$features &&
        ref0$RM == z$RM &&
        ref1$RM == z$RM &&
        ref0$n_presenca_validacao ==
        z$n_presenca_validacao &&
        ref1$n_presenca_validacao ==
        z$n_presenca_validacao &&
        ref0$n_background_validacao ==
        z$n_background_b0_fixo &&
        ref1$n_background_b0_fixo ==
        z$n_background_b0_fixo &&
        ref1$n_background_validacao ==
        z$n_background_b1_fixo,
      paste("Configuracoes nao comparaveis:", z$id)
    )
    
    comparacoes[[i]] <- data.frame(
      id_b0 = ref0$id,
      id_b1 = ref1$id,
      id_b2 = z$id,
      
      especie = z$especie,
      fold_cv = z$fold_cv,
      features = z$features,
      RM = z$RM,
      
      auc_b0 = ref0$auc_validacao,
      auc_b1_bg_b0_fixo =
        ref1$auc_validacao_bg_b0_fixo,
      auc_b2_bg_b0_fixo =
        z$auc_validacao_bg_b0_fixo,
      
      auc_b1_bg_b1 = ref1$auc_validacao,
      auc_b2_bg_b2 = z$auc_validacao,
      
      delta_auc_b2_b1 =
        z$auc_validacao_bg_b0_fixo -
        ref1$auc_validacao_bg_b0_fixo,
      
      delta_auc_b2_b0 =
        z$auc_validacao_bg_b0_fixo -
        ref0$auc_validacao,
      
      boyce_b0 = ref0$boyce_validacao,
      boyce_b1_bg_b0_fixo =
        ref1$boyce_validacao_bg_b0_fixo,
      boyce_b2_bg_b0_fixo =
        z$boyce_validacao_bg_b0_fixo,
      
      delta_boyce_b2_b1 =
        z$boyce_validacao_bg_b0_fixo -
        ref1$boyce_validacao_bg_b0_fixo,
      
      omissao_b0 =
        ref0$omissao10_validacao,
      omissao_b1 =
        ref1$omissao10_validacao,
      omissao_b2 =
        z$omissao10_validacao,
      
      delta_omissao_b2_b1 =
        z$omissao10_validacao -
        ref1$omissao10_validacao,
      
      delta_omissao_b2_b0 =
        z$omissao10_validacao -
        ref0$omissao10_validacao,
      
      complexidade_b0 =
        ref0$n_features_ativas,
      complexidade_b1 =
        ref1$n_features_ativas,
      complexidade_b2 =
        z$n_features_ativas,
      
      stringsAsFactors = FALSE
    )
  }
  
  comparacoes <- do.call(
    rbind, comparacoes
  )
  
  rownames(comparacoes) <- NULL
  
  salvar(
    comparacoes,
    file.path(
      saida, "19_COMPARACAO_72_B0_B1_B2.csv"
    )
  )
  
  # ----------------------------------------------------------
  # 8 - RESUMOS DE CONFIGURACAO E FOLD
  # ----------------------------------------------------------
  
  resumos <- list()
  
  for (sp in especies) {
    for (feat in c("l", "lq", "lqh")) {
      for (rm in 1:4) {
        
        z <- comparacoes[
          comparacoes$especie == sp &
            comparacoes$features == feat &
            comparacoes$RM == rm,
          , drop = FALSE
        ]
        
        exigir(
          nrow(z) == 3L &&
            setequal(z$fold_cv, 1:3),
          "Configuracao sem tres folds."
        )
        
        resumos[[
          length(resumos) + 1L
        ]] <- data.frame(
          especie = sp,
          features = feat,
          RM = rm,
          folds = 3L,
          
          auc_b0 = media(z$auc_b0),
          auc_b1 = media(z$auc_b1_bg_b0_fixo),
          auc_b2 = media(z$auc_b2_bg_b0_fixo),
          
          boyce_b0 = media(z$boyce_b0),
          boyce_b1 = media(z$boyce_b1_bg_b0_fixo),
          boyce_b2 = media(z$boyce_b2_bg_b0_fixo),
          
          omissao_b0 = media(z$omissao_b0),
          omissao_b1 = media(z$omissao_b1),
          omissao_b2 = media(z$omissao_b2),
          
          maior_omissao_b2 = max(z$omissao_b2),
          
          delta_auc_b2_b1 =
            media(z$delta_auc_b2_b1),
          
          delta_boyce_b2_b1 =
            media(z$delta_boyce_b2_b1),
          
          delta_omissao_b2_b1 =
            media(z$delta_omissao_b2_b1),
          
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  resumo <- do.call(rbind, resumos)
  
  exigir(
    nrow(resumo) == 24L,
    "Resumo das 24 configuracoes incompleto."
  )
  
  salvar(
    resumo,
    file.path(
      saida, "19_RESUMO_24_CONFIGURACOES.csv"
    )
  )
  
  fold_lista <- list()
  
  for (sp in especies) {
    for (f in 1:3) {
      
      z <- comparacoes[
        comparacoes$especie == sp &
          comparacoes$fold_cv == f,
        , drop = FALSE
      ]
      
      exigir(
        nrow(z) == 12L,
        "Fold sem 12 configuracoes."
      )
      
      fold_lista[[
        length(fold_lista) + 1L
      ]] <- data.frame(
        especie = sp,
        fold_cv = f,
        
        auc_b0 = media(z$auc_b0),
        auc_b1 = media(z$auc_b1_bg_b0_fixo),
        auc_b2 = media(z$auc_b2_bg_b0_fixo),
        
        boyce_b0 = media(z$boyce_b0),
        boyce_b1 = media(z$boyce_b1_bg_b0_fixo),
        boyce_b2 = media(z$boyce_b2_bg_b0_fixo),
        
        omissao_b0 = media(z$omissao_b0),
        omissao_b1 = media(z$omissao_b1),
        omissao_b2 = media(z$omissao_b2),
        
        modelos_omissao_100_b2 =
          sum(z$omissao_b2 == 1),
        
        stringsAsFactors = FALSE
      )
    }
  }
  
  resumo_fold <- do.call(
    rbind, fold_lista
  )
  
  salvar(
    resumo_fold,
    file.path(
      saida, "19_RESUMO_POR_FOLD.csv"
    )
  )
  
  # ----------------------------------------------------------
  # 9 - GRAFICOS B0 X B1 X B2
  # ----------------------------------------------------------
  
  cat("\nETAPA 5 - Gerando graficos...\n")
  
  indicadores <- list(
    AUC = c(
      "auc_b0",
      "auc_b1",
      "auc_b2"
    ),
    BOYCE = c(
      "boyce_b0",
      "boyce_b1",
      "boyce_b2"
    ),
    OMISSAO = c(
      "omissao_b0",
      "omissao_b1",
      "omissao_b2"
    )
  )
  
  for (sp in especies) {
    
    nome <- ifelse(
      sp == "Ipe-roxo",
      "ROXO", "AMARELO"
    )
    
    for (indicador in names(indicadores)) {
      
      cols <- indicadores[[indicador]]
      
      arquivo_png <- file.path(
        pasta_graf,
        paste0(
          "19_", nome, "_",
          indicador, "_B0_B1_B2.png"
        )
      )
      
      png(
        arquivo_png,
        width = 1500,
        height = 550,
        res = 140
      )
      
      par(
        mfrow = c(1, 3),
        mar = c(4.5, 4.5, 3, 1)
      )
      
      for (feat in c("l", "lq", "lqh")) {
        
        z <- resumo[
          resumo$especie == sp &
            resumo$features == feat,
          , drop = FALSE
        ]
        
        z <- z[order(z$RM), ]
        
        intervalo <- if (indicador == "BOYCE") {
          c(-1, 1)
        } else {
          c(0, 1)
        }
        
        plot(
          1:4,
          rep(NA_real_, 4),
          xlim = c(1, 4),
          ylim = intervalo,
          xaxt = "n",
          xlab = "Regularizacao (RM)",
          ylab = indicador,
          main = toupper(feat),
          type = "n"
        )
        
        axis(1, at = 1:4)
        
        for (j in 1:3) {
          lines(
            z$RM,
            z[[cols[j]]],
            type = "b",
            lty = c(2, 3, 1)[j],
            pch = c(15, 16, 17)[j],
            lwd = 1.5,
            col = c(
              "gray60",
              "gray35",
              "black"
            )[j]
          )
        }
        
        legend(
          "bottomright",
          legend = c("B0", "B1", "B2"),
          lty = c(2, 3, 1),
          pch = c(15, 16, 17),
          col = c("gray60", "gray35", "black"),
          bty = "n"
        )
      }
      
      dev.off()
    }
  }
  
  # ----------------------------------------------------------
  # 10 - RELATORIO E REPRODUTIBILIDADE
  # ----------------------------------------------------------
  
  relatorio <- c(
    "TCC IPES - R19",
    "MAXENT M1 / BACKGROUND B2",
    "",
    "EXPERIMENTOS COMPARADOS",
    "B0: 5000 pontos, R08.",
    "B1: 10000 pontos com B0 preservada, R16.",
    "B2: 10000 pontos sorteados novamente, R18.",
    "",
    "MODELOS",
    "72 ajustes novos com B2.",
    "2 especies.",
    "3 folds espaciais.",
    "Features L, LQ e LQH.",
    "RM 1, 2, 3 e 4.",
    "6 variaveis ambientais.",
    "",
    "METODO",
    "MaxEnt via maxnet.",
    "Solo como fator.",
    "Previsao cloglog.",
    "Clamping TRUE.",
    "Omissao com limiar do treinamento.",
    "",
    "COMPARABILIDADE",
    "Mesmas presencas e folds nas tres rodadas.",
    "Mesmo background B0 na avaliacao comparativa.",
    "AUC/Boyce com B2 sao metricas adicionais.",
    "Metricas por propriedade registradas.",
    "",
    "LIMITACOES",
    "B1 e B2 pertencem ao mesmo dominio ambiental.",
    "B2 nao e uma regiao independente de B1.",
    "A B2 permite avaliar sensibilidade ao sorteio.",
    "Uma unica semente nao mede toda a variabilidade.",
    "AUC media nao e criterio unico de selecao.",
    "Novidade ambiental entre folds permanece relevante.",
    "",
    "TESTE EXTERNO",
    "As sete propriedades externas nao foram usadas.",
    "",
    "REPRODUTIBILIDADE",
    "Entradas registradas por MD5.",
    "Modelos salvos em RDS.",
    "Checkpoints individuais para retomada.",
    "R08, R16 e R18 preservados.",
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
      saida, "19_RELATORIO_COMPARATIVO.txt"
    )
  )
  
  writeLines(
    capture.output(sessionInfo()),
    file.path(
      saida, "19_SESSION_INFO.txt"
    )
  )
  
  cat("\n========================================\n")
  cat("R19 CONCLUIDO!\n")
  cat("========================================\n")
  cat("72 modelos novos com B2.\n")
  cat("24 configuracoes comparadas.\n")
  cat("216 avaliacoes B0 / B1 / B2.\n")
  cat("Background de validacao B0 fixo.\n")
  cat("Teste externo nao utilizado.\n")
  cat("\nResultados em:\n", saida, "\n")
  cat("========================================\n")
}

R19()
