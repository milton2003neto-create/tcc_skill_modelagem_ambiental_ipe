
# ============================================================
# TCC IPES - R18 V1
# BACKGROUND B2 - SORTEIO NOVO DE 10.000 PONTOS
#
# Usa as mesmas 64 UPAs e cotas da B1.
# NAO fixa os 5.000 pontos da B0.
# Coincidencias por acaso sao permitidas e contabilizadas.
#
# Usa o catalogo, o manifesto e o QA do R15 V3.5.
# Verifica geometrias, pixels e valores ambientais.
# Salva checkpoints para retomar por propriedade.
#
# NAO ajusta modelos MaxEnt.
# NAO modifica B0, B1 ou resultados anteriores.
# NAO utiliza as sete propriedades externas.
# ============================================================

R18_B2 <- function() {
  
  # ----------------------------------------------------------
  # 0 - PACOTES E CONFIGURACOES
  # ----------------------------------------------------------
  
  for (pacote in c("sf", "terra")) {
    if (!requireNamespace(pacote, quietly = TRUE)) {
      stop("Instale o pacote: ", pacote)
    }
  }
  
  sf::sf_use_s2(TRUE)
  
  VERSAO <- "R18_B2_V1_20261116"
  SEMENTE <- 20261117L
  
  N_B0 <- 5000L
  N_B1 <- 10000L
  N_B2 <- 10000L
  N_PIXELS <- 570227L
  
  variaveis <- c(
    "altitude_m",
    "declividade_graus",
    "dist_rio_raster_m",
    "bio12_mm_ano",
    "bio17_mm_mes",
    "textura_subgrupo"
  )
  
  campos <- c(
    "id_background",
    "propriedade",
    "upa_id",
    "fold_cv",
    "celula_raster",
    "longitude",
    "latitude",
    variaveis
  )
  
  tolerancias <- c(
    altitude_m = 0.01,
    declividade_graus = 0.01,
    dist_rio_raster_m = 0.05,
    bio12_mm_ano = 0.05,
    bio17_mm_mes = 0.02,
    textura_subgrupo = 0
  )
  
  ler <- function(f) {
    read.csv(
      f,
      fileEncoding = "UTF-8-BOM",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  
  salvar <- function(x, f) {
    write.csv(
      x, f,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
  }
  
  hash <- function(f) {
    unname(as.character(tools::md5sum(f)))
  }
  
  falhar <- function(...) {
    stop(paste0(...), call. = FALSE)
  }
  
  normalizar <- function(x) {
    x <- iconv(
      as.character(x),
      to = "ASCII//TRANSLIT",
      sub = ""
    )
    x <- toupper(x)
    trimws(gsub("[^A-Z0-9]+", " ", x))
  }
  
  # ----------------------------------------------------------
  # 1 - SELECIONAR A B1 DO R15
  # ----------------------------------------------------------
  
  cat("\n=======================================\n")
  cat("TCC IPES - R18 - BACKGROUND B2\n")
  cat("10.000 PONTOS - NOVO SORTEIO\n")
  cat("=======================================\n")
  
  cat(
    "\nSelecione 15_BACKGROUND_B1_10000_COM_FOLDS.csv\n"
  )
  
  arq_b1 <- normalizePath(
    file.choose(),
    winslash = "/",
    mustWork = TRUE
  )
  
  if (
    basename(arq_b1) !=
    "15_BACKGROUND_B1_10000_COM_FOLDS.csv"
  ) {
    falhar("Selecione a B1 final do R15 V3.5.")
  }
  
  pasta_r15 <- dirname(arq_b1)
  
  raiz <- pasta_r15
  
  repeat {
    if (
      dir.exists(file.path(
        raiz, "03 - Trabalho no QGIS"
      )) &&
      dir.exists(file.path(
        raiz, "04 - Dados para o MaxEnt"
      )) &&
      dir.exists(file.path(
        raiz, "06 - Resultados"
      ))
    ) break
    
    acima <- dirname(raiz)
    
    if (acima == raiz) {
      falhar("Raiz do TCC nao encontrada.")
    }
    
    raiz <- acima
  }
  
  arq_b0 <- file.path(
    raiz,
    "04 - Dados para o MaxEnt",
    "04 - Presencas e folds V3",
    "05_BACKGROUND_COM_FOLDS.csv"
  )
  
  arq_cat <- file.path(
    pasta_r15, "15_CATALOGO_FONTES.csv"
  )
  
  arq_cotas <- file.path(
    pasta_r15, "15_COTAS_B1_POR_UPA.csv"
  )
  
  arq_qa <- file.path(
    pasta_r15, "15_QA_FINAL_POR_PROPRIEDADE.csv"
  )
  
  arq_man <- file.path(
    pasta_r15, "15_MANIFESTO_FONTES.csv"
  )
  
  entradas <- c(
    arq_b0,
    arq_b1,
    arq_cat,
    arq_cotas,
    arq_qa,
    arq_man
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
  
  # ----------------------------------------------------------
  # 2 - AUDITAR B0, B1 E R15
  # ----------------------------------------------------------
  
  cat("\nETAPA 1 - Auditando dados originais...\n")
  
  b0 <- ler(arq_b0)
  b1 <- ler(arq_b1)
  catalogo <- ler(arq_cat)
  cotas <- ler(arq_cotas)
  qa15 <- ler(arq_qa)
  man15 <- ler(arq_man)
  
  if (
    nrow(b0) != N_B0 ||
    nrow(b1) != N_B1 ||
    nrow(cotas) != 64L ||
    nrow(catalogo) != 162L ||
    nrow(qa15) != 27L
  ) {
    falhar("Contagens diferentes das auditadas no R15.")
  }
  
  if (
    !all(campos %in% names(b0)) ||
    !all(c(
      campos, "origem_amostra"
    ) %in% names(b1))
  ) {
    falhar("Colunas do background incompletas.")
  }
  
  # A B1 deve preservar a B0 original.
  texto <- c(
    "id_background",
    "propriedade",
    "upa_id",
    "celula_raster"
  )
  
  numeros <- setdiff(campos, texto)
  
  for (v in texto) {
    if (!identical(
      as.character(b0[[v]]),
      as.character(b1[[v]][1:N_B0])
    )) {
      falhar("B0 alterada no campo: ", v)
    }
  }
  
  for (v in numeros) {
    x <- as.numeric(b0[[v]])
    y <- as.numeric(b1[[v]][1:N_B0])
    
    if (!isTRUE(all.equal(
      x, y,
      tolerance = 1e-9,
      check.attributes = FALSE
    ))) {
      falhar("B0 diferente da B1 no campo: ", v)
    }
  }
  
  if (
    sum(b1$origem_amostra == "B0_PRESERVADO") !=
    N_B0 ||
    sum(b1$origem_amostra == "B1_ADICIONAL") !=
    N_B0
  ) {
    falhar("Origem dos pontos da B1 inconsistente.")
  }
  
  # Conferir a B0 com o manifesto do R15.
  ref_b0 <- man15[
    man15$caminho == arq_b0,
    , drop = FALSE
  ]
  
  if (
    nrow(ref_b0) != 1L ||
    tolower(ref_b0$md5) != tolower(hash(arq_b0))
  ) {
    falhar("B0 nao confere com o manifesto R15.")
  }
  
  propriedades <- sort(unique(b0$propriedade))
  
  if (
    length(propriedades) != 27L ||
    length(unique(paste(
      b0$propriedade,
      b0$upa_id,
      sep = "||"
    ))) != 64L
  ) {
    falhar("Propriedades e UPAs inconsistentes.")
  }
  
  externas <- normalizar(c(
    "BARRO BRANCO",
    "CURUÇA",
    "GUARIÚBA",
    "JATOBÁ",
    "LOTE 01",
    "MARILIA",
    "PALMEIRA"
  ))
  
  if (any(
    normalizar(propriedades) %in% externas
  )) {
    falhar("Propriedade externa encontrada!")
  }
  
  if (
    !setequal(
      propriedades,
      unique(b1$propriedade)
    ) ||
    anyDuplicated(cotas$chave) ||
    sum(cotas$pixels_disponiveis) != N_PIXELS ||
    sum(cotas$n_b0) != N_B0 ||
    sum(cotas$n_b1) != N_B1 ||
    sum(qa15$pixels_elegiveis) != N_PIXELS ||
    sum(qa15$pontos_b0) != N_B0
  ) {
    falhar("Dominio ou cotas divergentes do R15.")
  }
  
  if (
    any(cotas$n_b1 < 1) ||
    any(cotas$n_b1 > cotas$pixels_disponiveis)
  ) {
    falhar("Cotas impossiveis por UPA.")
  }
  
  chaves_b1 <- paste(
    b1$propriedade,
    b1$upa_id,
    sep = "||"
  )
  
  distribuicao <- table(
    factor(chaves_b1, levels = cotas$chave)
  )
  
  if (!identical(
    as.integer(distribuicao),
    as.integer(cotas$n_b1)
  )) {
    falhar("A B1 nao corresponde as cotas do R15.")
  }
  
  for (v in variaveis) {
    b0[[v]] <- as.numeric(b0[[v]])
    b1[[v]] <- as.numeric(b1[[v]])
    
    if (
      any(!is.finite(b0[[v]])) ||
      any(!is.finite(b1[[v]]))
    ) {
      falhar("Preditor invalido: ", v)
    }
  }
  
  # Um unico fold por propriedade.
  fold_props <- split(
    b0$fold_cv,
    b0$propriedade
  )
  
  if (any(vapply(
    fold_props,
    function(x) length(unique(x)) != 1L,
    logical(1)
  ))) {
    falhar("Folds inconsistentes na B0.")
  }
  
  if (!setequal(unique(b0$fold_cv), 1:3)) {
    falhar("Folds originais nao reconhecidos.")
  }
  
  if (any(vapply(
    split(b1$fold_cv, b1$propriedade),
    function(x) length(unique(x)) != 1L,
    logical(1)
  ))) {
    falhar("Folds inconsistentes na B1.")
  }
  
  cat("AUDITORIA INICIAL: OK\n")
  cat("570227 pixels no dominio.\n")
  cat("64 UPAs e 27 propriedades.\n")
  cat("B0 e B1 preservadas.\n")
  
  # ----------------------------------------------------------
  # 3 - PASTA DE RESULTADOS E CHECKPOINTS
  # ----------------------------------------------------------
  
  saida <- file.path(
    raiz,
    "06 - Resultados",
    "16 - Background B2 10000 V1"
  )
  
  checkpoints <- file.path(
    saida, "18_CHECKPOINTS_PROPRIEDADES"
  )
  
  dir.create(
    saida,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  assinatura <- data.frame(
    caminho = normalizePath(
      entradas,
      winslash = "/",
      mustWork = TRUE
    ),
    md5 = hash(entradas),
    versao = VERSAO,
    semente = SEMENTE,
    stringsAsFactors = FALSE
  )
  
  arq_assinatura <- file.path(
    saida, "18_MANIFESTO_ENTRADAS.csv"
  )
  
  if (file.exists(arq_assinatura)) {
    anterior <- ler(arq_assinatura)
    
    if (!identical(anterior, assinatura)) {
      falhar(
        "A pasta R18 ja existe com outras entradas. ",
        "Nao vou misturar execucoes."
      )
    }
  } else {
    if (length(list.files(saida))) {
      falhar(
        "Pasta de resultados existente sem manifesto."
      )
    }
    
    salvar(assinatura, arq_assinatura)
  }
  
  dir.create(
    checkpoints,
    showWarnings = FALSE
  )
  
  assinatura_base <- paste(
    c(VERSAO, SEMENTE, assinatura$md5),
    collapse = "|"
  )
  
  # ----------------------------------------------------------
  # 4 - FUNCAO PARA LOCALIZAR FONTES POR PROPRIEDADE
  # ----------------------------------------------------------
  
  fontes_prop <- function(pr) {
    
    cat_pr <- catalogo[
      catalogo$propriedade == pr,
      , drop = FALSE
    ]
    
    pos <- match(variaveis, cat_pr$variavel)
    
    if (
      nrow(cat_pr) != 6L ||
      anyNA(pos) ||
      anyDuplicated(cat_pr$variavel)
    ) {
      falhar("Catalogo incompleto: ", pr)
    }
    
    fontes <- as.character(cat_pr$arquivo[pos])
    names(fontes) <- variaveis
    
    gpkg <- file.path(
      raiz,
      "03 - Trabalho no QGIS",
      "02 - Arquivos gerados",
      "GPKG por propriedade",
      paste0(pr, ".gpkg")
    )
    
    todos <- c(gpkg, unname(fontes))
    
    if (!all(file.exists(todos))) {
      falhar(
        "Fontes ausentes em ", pr, ":\n",
        paste(
          todos[!file.exists(todos)],
          collapse = "\n"
        )
      )
    }
    
    # Conferencia adicional dos hashes originais.
    pos_man <- match(
      todos,
      man15$caminho
    )
    
    if (anyNA(pos_man)) {
      falhar(
        "Fonte nao registrada no R15: ", pr
      )
    }
    
    hashes <- hash(todos)
    
    if (!identical(
      tolower(hashes),
      tolower(as.character(man15$md5[pos_man]))
    )) {
      falhar(
        "Alguma fonte foi modificada desde R15: ",
        pr
      )
    }
    
    list(
      gpkg = gpkg,
      rasters = fontes,
      hashes = hashes
    )
  }
  
  # ----------------------------------------------------------
  # 5 - PROCESSAR AS PROPRIEDADES
  # ----------------------------------------------------------
  
  cat("\nETAPA 2 - Sorteando 10000 pixels...\n")
  
  lista_amostras <- list()
  lista_qa <- list()
  lista_sobreposicoes <- list()
  
  for (ip in seq_along(propriedades)) {
    
    pr <- propriedades[ip]
    
    cat("\n----------------------------------------\n")
    cat(
      sprintf(
        "[%02d/%02d] %s\n",
        ip, length(propriedades), pr
      )
    )
    
    b0_pr <- b0[
      b0$propriedade == pr,
      , drop = FALSE
    ]
    
    b1_pr <- b1[
      b1$propriedade == pr,
      , drop = FALSE
    ]
    
    cotas_pr <- cotas[
      startsWith(
        cotas$chave,
        paste0(pr, "||")
      ),
      , drop = FALSE
    ]
    
    qa_pr <- qa15[
      qa15$propriedade == pr,
      , drop = FALSE
    ]
    
    if (
      !nrow(cotas_pr) ||
      nrow(qa_pr) != 1L
    ) {
      falhar("Cotas ou QA ausentes em: ", pr)
    }
    
    origem <- fontes_prop(pr)
    
    assinatura_pr <- paste(
      c(
        assinatura_base,
        origem$hashes
      ),
      collapse = "|"
    )
    
    nome_seguro <- gsub(
      " ", "_", normalizar(pr)
    )
    
    arq_cache <- file.path(
      checkpoints,
      sprintf(
        "%02d_%s.rds", ip, nome_seguro
      )
    )
    
    # --------------------------------------------------------
    # 5.1 - RECUPERAR PROPRIEDADE PROCESSADA
    # --------------------------------------------------------
    
    if (file.exists(arq_cache)) {
      
      cache <- readRDS(arq_cache)
      
      if (
        !is.list(cache) ||
        !identical(
          cache$assinatura,
          assinatura_pr
        ) ||
        !identical(
          cache$propriedade,
          pr
        ) ||
        !is.data.frame(cache$amostra) ||
        !is.data.frame(cache$qa) ||
        !is.data.frame(cache$sobreposicoes)
      ) {
        falhar("Checkpoint inconsistente: ", pr)
      }
      
      if (
        nrow(cache$amostra) !=
        sum(cotas_pr$n_b1) ||
        anyDuplicated(cache$amostra$celula_raster) ||
        !all(cache$amostra$propriedade == pr)
      ) {
        falhar(
          "Amostra do checkpoint invalida: ", pr
        )
      }
      
      ch <- paste(
        cache$amostra$propriedade,
        cache$amostra$upa_id,
        sep = "||"
      )
      
      if (!identical(
        as.integer(table(
          factor(ch, levels = cotas_pr$chave)
        )),
        as.integer(cotas_pr$n_b1)
      )) {
        falhar(
          "Cotas do checkpoint divergentes: ", pr
        )
      }
      
      lista_amostras[[ip]] <- cache$amostra
      lista_qa[[ip]] <- cache$qa
      lista_sobreposicoes[[ip]] <-
        cache$sobreposicoes
      
      cat("  Checkpoint validado e recuperado.\n")
      
      next
    }
    
    # --------------------------------------------------------
    # 5.2 - LER E IDENTIFICAR AS UPAs
    # --------------------------------------------------------
    
    geo <- suppressWarnings(
      sf::st_read(
        origem$gpkg,
        layer = "upas",
        quiet = TRUE
      )
    )
    
    if (is.na(sf::st_crs(geo))) {
      falhar("GPKG sem SRC: ", pr)
    }
    
    geo <- suppressWarnings(
      sf::st_make_valid(geo)
    )
    
    geo <- suppressWarnings(
      sf::st_collection_extract(
        geo, "POLYGON"
      )
    )
    
    geo <- geo[
      !sf::st_is_empty(geo),
      , drop = FALSE
    ]
    
    pontos_b0 <- sf::st_as_sf(
      b0_pr,
      coords = c("longitude", "latitude"),
      crs = 4674,
      remove = FALSE
    )
    
    pontos_g <- sf::st_transform(
      pontos_b0,
      sf::st_crs(geo)
    )
    
    rel <- sf::st_intersects(
      geo, pontos_g
    )
    
    codigo_upa <- rep(
      NA_character_,
      nrow(geo)
    )
    
    for (i in seq_len(nrow(geo))) {
      
      ids <- unique(
        b0_pr$upa_id[rel[[i]]]
      )
      
      if (length(ids) > 1L) {
        falhar(
          "Poligono com UPAs diferentes: ",
          pr, " / ", i
        )
      }
      
      if (length(ids) == 1L) {
        codigo_upa[i] <- ids
      }
    }
    
    geo$upa_r18 <- codigo_upa
    
    geo <- geo[
      !is.na(geo$upa_r18),
      , drop = FALSE
    ]
    
    if (!setequal(
      unique(geo$upa_r18),
      unique(b0_pr$upa_id)
    )) {
      falhar("UPAs nao identificadas: ", pr)
    }
    
    # --------------------------------------------------------
    # 5.3 - LER E CONFERIR OS RASTERS
    # --------------------------------------------------------
    
    rr <- lapply(
      unname(origem$rasters),
      terra::rast
    )
    
    uma_banda <- vapply(
      rr,
      function(r) {
        as.numeric(terra::nlyr(r)) == 1
      },
      logical(1)
    )
    
    if (!all(uma_banda)) {
      falhar("Raster com multiplas bandas: ", pr)
    }
    
    crs_base <- sf::st_crs(
      terra::crs(rr[[1]])
    )
    
    if (is.na(crs_base)) {
      falhar("SRC raster ausente: ", pr)
    }
    
    for (j in seq_along(rr)) {
      
      crsj <- sf::st_crs(
        terra::crs(rr[[j]])
      )
      
      if (
        is.na(crsj) ||
        !isTRUE(crsj == crs_base) ||
        terra::is.lonlat(rr[[j]]) ||
        any(abs(terra::res(rr[[j]]) - 30) > 0.05)
      ) {
        falhar(
          "SRC ou resolucao divergente: ",
          pr, " / ", variaveis[j]
        )
      }
    }
    
    # --------------------------------------------------------
    # 5.4 - RECONSTRUIR MASCARA E PIXELS
    # --------------------------------------------------------
    
    geo <- sf::st_transform(
      geo, crs_base
    )
    
    codigos <- sort(unique(
      geo$upa_r18
    ))
    
    geo$codigo_r18 <- match(
      geo$upa_r18,
      codigos
    )
    
    vetor <- terra::vect(geo)
    
    grade <- terra::crop(
      rr[[1]],
      terra::ext(vetor),
      snap = "out"
    )
    
    mascara <- terra::rasterize(
      vetor,
      grade,
      field = "codigo_r18",
      touches = FALSE
    )
    
    names(mascara) <- "codigo_r18"
    
    tab <- terra::as.data.frame(
      mascara,
      xy = TRUE,
      cells = TRUE,
      na.rm = TRUE
    )
    
    if (
      !all(c(
        "cell", "x", "y", "codigo_r18"
      ) %in% names(tab)) ||
      nrow(tab) == 0L
    ) {
      falhar("Mascara raster invalida: ", pr)
    }
    
    xy <- as.matrix(
      tab[, c("x", "y"), drop = FALSE]
    )
    
    # Extrair os seis valores nos mesmos centros
    # de pixel usados no R15.
    for (j in seq_along(variaveis)) {
      
      valores <- terra::extract(
        rr[[j]],
        xy,
        method = "simple"
      )
      
      if (
        nrow(valores) != nrow(tab) ||
        ncol(valores) != 1L
      ) {
        falhar(
          "Falha na extracao: ",
          pr, " / ", variaveis[j]
        )
      }
      
      tab[[variaveis[j]]] <-
        as.numeric(valores[[1]])
    }
    
    validos <- complete.cases(
      tab[, variaveis, drop = FALSE]
    )
    
    for (v in variaveis) {
      validos <- validos & is.finite(
        tab[[v]]
      )
    }
    
    tab <- tab[
      validos,
      , drop = FALSE
    ]
    
    tab$upa_id <- codigos[
      as.integer(tab$codigo_r18)
    ]
    
    tab$propriedade <- pr
    tab$fold_cv <- unique(b0_pr$fold_cv)
    
    tab$chave <- paste(
      tab$propriedade,
      tab$upa_id,
      sep = "||"
    )
    
    if (
      anyNA(tab$upa_id) ||
      anyDuplicated(tab$cell)
    ) {
      falhar("Pixels invalidos: ", pr)
    }
    
    # --------------------------------------------------------
    # 5.5 - CONFERIR DOMINIO CONTRA O R15
    # --------------------------------------------------------
    
    if (
      nrow(tab) !=
      qa_pr$pixels_elegiveis
    ) {
      falhar(
        "Total de pixels diferente do R15: ",
        pr
      )
    }
    
    disponibilidade <- table(
      factor(
        tab$chave,
        levels = cotas_pr$chave
      )
    )
    
    if (!identical(
      as.integer(disponibilidade),
      as.integer(cotas_pr$pixels_disponiveis)
    )) {
      falhar(
        "Pixels disponiveis por UPA divergentes: ",
        pr
      )
    }
    
    # --------------------------------------------------------
    # 5.6 - CONFERIR B0 E B1 CONTRA OS RASTERS
    # --------------------------------------------------------
    
    celulas_originais <- function(d) {
      
      pts <- sf::st_as_sf(
        d,
        coords = c("longitude", "latitude"),
        crs = 4674,
        remove = FALSE
      )
      
      pts <- sf::st_transform(
        pts, crs_base
      )
      
      terra::cellFromXY(
        grade,
        sf::st_coordinates(pts)
      )
    }
    
    cel_b0 <- celulas_originais(b0_pr)
    cel_b1 <- celulas_originais(b1_pr)
    
    pos_b0 <- match(
      cel_b0, tab$cell
    )
    
    pos_b1 <- match(
      cel_b1, tab$cell
    )
    
    if (
      anyNA(pos_b0) ||
      anyNA(pos_b1) ||
      anyDuplicated(cel_b0) ||
      anyDuplicated(cel_b1)
    ) {
      falhar(
        "Pontos B0 ou B1 fora da mascara: ",
        pr
      )
    }
    
    if (
      any(tab$upa_id[pos_b0] != b0_pr$upa_id) ||
      any(tab$upa_id[pos_b1] != b1_pr$upa_id)
    ) {
      falhar(
        "UPA dos pontos diferente da mascara: ",
        pr
      )
    }
    
    dif_b0 <- vapply(
      variaveis,
      function(v) {
        max(abs(
          tab[[v]][pos_b0] -
            b0_pr[[v]]
        ))
      },
      numeric(1)
    )
    
    dif_b1 <- vapply(
      variaveis,
      function(v) {
        max(abs(
          tab[[v]][pos_b1] -
            b1_pr[[v]]
        ))
      },
      numeric(1)
    )
    
    if (
      any(dif_b0 > tolerancias) ||
      any(dif_b1 > tolerancias)
    ) {
      falhar(
        "Preditores diferentes da B0/B1: ",
        pr
      )
    }
    
    # --------------------------------------------------------
    # 5.7 - SORTEAR TODA A B2
    # --------------------------------------------------------
    
    sorteios <- list()
    sobreposicoes <- list()
    
    for (iu in seq_len(nrow(cotas_pr))) {
      
      chave <- cotas_pr$chave[iu]
      
      candidatos <- tab[
        tab$chave == chave,
        , drop = FALSE
      ]
      
      # Ordenar antes de sortear para reprodutibilidade.
      candidatos <- candidatos[
        order(candidatos$cell),
        , drop = FALSE
      ]
      
      n <- as.integer(cotas_pr$n_b1[iu])
      
      # Semente unica para cada UPA.
      indice_global <- match(
        chave,
        cotas$chave
      )
      
      set.seed(
        SEMENTE + indice_global
      )
      
      pos <- sample.int(
        nrow(candidatos),
        size = n,
        replace = FALSE
      )
      
      selecionados <- candidatos[
        pos, , drop = FALSE
      ]
      
      # Coincidencias sao apenas contabilizadas.
      # Nao sao excluidas nem favorecidas no sorteio.
      sobreposicoes[[iu]] <- data.frame(
        chave = chave,
        n_b2 = n,
        coincidencias_b0 = sum(
          selecionados$cell %in% cel_b0
        ),
        coincidencias_b1 = sum(
          selecionados$cell %in% cel_b1
        )
      )
      
      sorteios[[iu]] <- selecionados
    }
    
    novos <- do.call(
      rbind, sorteios
    )
    
    rownames(novos) <- NULL
    
    if (
      nrow(novos) != sum(cotas_pr$n_b1) ||
      anyDuplicated(novos$cell)
    ) {
      falhar(
        "Sorteio duplicado ou incompleto: ",
        pr
      )
    }
    
    # --------------------------------------------------------
    # 5.8 - TRANSFORMAR COORDENADAS
    # --------------------------------------------------------
    
    pts_b2 <- sf::st_as_sf(
      novos,
      coords = c("x", "y"),
      crs = crs_base,
      remove = FALSE
    )
    
    pts_b2 <- sf::st_transform(
      pts_b2, 4674
    )
    
    coords <- sf::st_coordinates(
      pts_b2
    )
    
    novos$longitude <- coords[, 1]
    novos$latitude <- coords[, 2]
    
    novos$celula_raster <- paste0(
      "B2_",
      sprintf("%02d", ip),
      "_",
      novos$cell
    )
    
    if (
      any(!is.finite(novos$longitude)) ||
      any(!is.finite(novos$latitude))
    ) {
      falhar(
        "Coordenadas invalidas: ", pr
      )
    }
    
    amostra <- novos[
      , c(
        "propriedade",
        "upa_id",
        "fold_cv",
        "celula_raster",
        "longitude",
        "latitude",
        variaveis
      ),
      drop = FALSE
    ]
    
    qa_pr_final <- data.frame(
      propriedade = pr,
      pixels_elegiveis = nrow(tab),
      pontos_b0 = nrow(b0_pr),
      pontos_b1 = nrow(b1_pr),
      pontos_b2 = nrow(amostra),
      max_diferenca_b0 = max(dif_b0),
      max_diferenca_b1 = max(dif_b1)
    )
    
    sobreposicao_pr <- do.call(
      rbind, sobreposicoes
    )
    
    # --------------------------------------------------------
    # 5.9 - SALVAR CHECKPOINT
    # --------------------------------------------------------
    
    cache <- list(
      assinatura = assinatura_pr,
      propriedade = pr,
      amostra = amostra,
      qa = qa_pr_final,
      sobreposicoes = sobreposicao_pr
    )
    
    temporario <- paste0(
      arq_cache, ".tmp"
    )
    
    saveRDS(cache, temporario)
    
    if (!file.rename(
      temporario, arq_cache
    )) {
      falhar(
        "Falha ao salvar checkpoint: ", pr
      )
    }
    
    lista_amostras[[ip]] <- amostra
    lista_qa[[ip]] <- qa_pr_final
    lista_sobreposicoes[[ip]] <-
      sobreposicao_pr
    
    cat(
      "  Pixels: ", nrow(tab),
      " | B2: ", nrow(amostra),
      " | QA: OK\n",
      sep = ""
    )
    
    rm(
      geo, vetor, rr, grade,
      mascara, tab, xy,
      novos, pts_b2
    )
    
    invisible(gc(verbose = FALSE))
  }
  
  # ----------------------------------------------------------
  # 6 - CONSOLIDAR 10.000 PONTOS
  # ----------------------------------------------------------
  
  cat("\nETAPA 3 - Consolidando a B2...\n")
  
  b2 <- do.call(
    rbind, lista_amostras
  )
  
  rownames(b2) <- NULL
  
  b2$id_background <- sprintf(
    "B2_%05d",
    seq_len(nrow(b2))
  )
  
  b2$origem_amostra <- "B2_SORTEIO_NOVO"
  
  b2 <- b2[
    , c(
      campos,
      "origem_amostra"
    ),
    drop = FALSE
  ]
  
  qa_final <- do.call(
    rbind, lista_qa
  )
  
  sobreposicoes <- do.call(
    rbind, lista_sobreposicoes
  )
  
  rownames(qa_final) <- NULL
  rownames(sobreposicoes) <- NULL
  
  # ----------------------------------------------------------
  # 7 - AUDITORIA FINAL
  # ----------------------------------------------------------
  
  cat("\nETAPA 4 - Auditoria final...\n")
  
  if (
    nrow(b2) != N_B2 ||
    anyNA(b2) ||
    anyDuplicated(b2$id_background) ||
    anyDuplicated(paste(
      b2$propriedade,
      b2$celula_raster,
      sep = "||"
    ))
  ) {
    falhar("B2 final invalida.")
  }
  
  for (v in c(
    "longitude", "latitude", variaveis
  )) {
    if (any(!is.finite(
      as.numeric(b2[[v]])
    ))) {
      falhar("Valor invalido em: ", v)
    }
  }
  
  if (
    length(unique(b2$propriedade)) != 27L ||
    length(unique(paste(
      b2$propriedade, b2$upa_id,
      sep = "||"
    ))) != 64L ||
    sum(qa_final$pixels_elegiveis) != N_PIXELS ||
    sum(qa_final$pontos_b2) != N_B2
  ) {
    falhar("Dominio B2 diferente do previsto.")
  }
  
  chaves_b2 <- paste(
    b2$propriedade,
    b2$upa_id,
    sep = "||"
  )
  
  distribuicao_b2 <- table(
    factor(
      chaves_b2,
      levels = cotas$chave
    )
  )
  
  if (!identical(
    as.integer(distribuicao_b2),
    as.integer(cotas$n_b1)
  )) {
    falhar("Cotas B2 divergentes da B1.")
  }
  
  if (any(
    normalizar(b2$propriedade) %in% externas
  )) {
    falhar("Teste externo presente na B2!")
  }
  
  particao <- split(
    b2$fold_cv,
    b2$propriedade
  )
  
  if (any(vapply(
    particao,
    function(x) length(unique(x)) != 1L,
    logical(1)
  ))) {
    falhar("Folds alterados na B2.")
  }
  
  for (pr in propriedades) {
    if (
      unique(b2$fold_cv[
        b2$propriedade == pr
      ]) != unique(b0$fold_cv[
        b0$propriedade == pr
      ])
    ) {
      falhar("Fold diferente da B0: ", pr)
    }
  }
  
  if (
    anyDuplicated(paste(
      b2$propriedade,
      round(b2$longitude, 10),
      round(b2$latitude, 10),
      sep = "||"
    ))
  ) {
    falhar("Coordenadas duplicadas na B2.")
  }
  
  if (
    sum(sobreposicoes$n_b2) != N_B2 ||
    any(
      sobreposicoes$coincidencias_b0 >
      sobreposicoes$n_b2
    ) ||
    any(
      sobreposicoes$coincidencias_b1 >
      sobreposicoes$n_b2
    )
  ) {
    falhar("Sobreposicoes inconsistentes.")
  }
  
  # ----------------------------------------------------------
  # 8 - GERAR RELATORIOS
  # ----------------------------------------------------------
  
  resumo_upa <- data.frame(
    chave = cotas$chave,
    pixels_disponiveis =
      cotas$pixels_disponiveis,
    n_b0 = cotas$n_b0,
    n_b1 = cotas$n_b1,
    n_b2 = as.integer(distribuicao_b2)
  )
  
  pos_sob <- match(
    resumo_upa$chave,
    sobreposicoes$chave
  )
  
  if (anyNA(pos_sob)) {
    falhar("Relatorio de sobreposicao incompleto.")
  }
  
  resumo_upa$coincidencias_b0 <-
    sobreposicoes$coincidencias_b0[pos_sob]
  
  resumo_upa$coincidencias_b1 <-
    sobreposicoes$coincidencias_b1[pos_sob]
  
  resumo_fold <- aggregate(
    id_background ~ fold_cv,
    data = b2,
    FUN = length
  )
  
  names(resumo_fold)[2] <- "n_background_b2"
  
  resumo_propriedade <- aggregate(
    id_background ~ propriedade + fold_cv,
    data = b2,
    FUN = length
  )
  
  names(resumo_propriedade)[3] <-
    "n_background_b2"
  
  coincidencias_b0 <- sum(
    resumo_upa$coincidencias_b0
  )
  
  coincidencias_b1 <- sum(
    resumo_upa$coincidencias_b1
  )
  
  # ----------------------------------------------------------
  # 9 - SALVAR OS ARQUIVOS FINAIS
  # ----------------------------------------------------------
  
  cat("\nETAPA 5 - Salvando resultados...\n")
  
  salvar(
    b2,
    file.path(
      saida,
      "18_BACKGROUND_B2_10000_COM_FOLDS.csv"
    )
  )
  
  salvar(
    resumo_upa,
    file.path(
      saida,
      "18_COTAS_E_SOBREPOSICOES_POR_UPA.csv"
    )
  )
  
  salvar(
    qa_final,
    file.path(
      saida,
      "18_QA_POR_PROPRIEDADE.csv"
    )
  )
  
  salvar(
    resumo_fold,
    file.path(
      saida,
      "18_RESUMO_POR_FOLD.csv"
    )
  )
  
  salvar(
    resumo_propriedade,
    file.path(
      saida,
      "18_RESUMO_POR_PROPRIEDADE.csv"
    )
  )
  
  relatorio <- c(
    "TCC IPES - R18 V1",
    "BACKGROUND B2 - NOVO SORTEIO DE 10000 PONTOS",
    "",
    "DOMINIO",
    "27 propriedades de desenvolvimento.",
    "64 UPAs efetivamente inventariadas.",
    "570227 pixels ambientalmente elegiveis.",
    "",
    "AMOSTRAGEM",
    "10000 pixels sorteados novamente.",
    "Nenhum pixel da B0 foi fixado na amostra.",
    "Nenhum pixel da B0 foi excluido previamente.",
    "Cotas identicas as da B1 por UPA.",
    "Sorteio sem reposicao dentro de cada UPA.",
    paste("Semente principal:", SEMENTE),
    "",
    "COINCIDENCIAS CASUAIS",
    paste("Com B0:", coincidencias_b0),
    paste("Com B1:", coincidencias_b1),
    "",
    "AUDITORIA",
    "Fontes conferidas com o manifesto do R15.",
    "UPAs identificadas pelos pontos da B0.",
    "Dominios e cotas comparados com R15.",
    "Preditores comparados com B0 e B1.",
    "Folds mantidos.",
    "Teste externo nao utilizado.",
    "",
    "LIMITACOES",
    "B2 e um novo sorteio no mesmo dominio da B1.",
    "Nao e independente geograficamente da B1.",
    "Coincidencias por acaso sao esperadas.",
    "Nenhum novo modelo MaxEnt foi executado.",
    "Resultados anteriores nao foram alterados.",
    "",
    paste("Data:", as.character(Sys.time())),
    paste("R:", R.version.string),
    paste(
      "terra:",
      as.character(
        utils::packageVersion("terra")
      )
    ),
    paste(
      "sf:",
      as.character(
        utils::packageVersion("sf")
      )
    )
  )
  
  writeLines(
    relatorio,
    file.path(
      saida, "18_RELATORIO_BACKGROUND_B2.txt"
    )
  )
  
  writeLines(
    capture.output(sessionInfo()),
    file.path(
      saida, "18_SESSION_INFO.txt"
    )
  )
  
  cat("\n=======================================\n")
  cat("R18 CONCLUIDO\n")
  cat("=======================================\n")
  cat("Background B2: 10000 pontos\n")
  cat("UPAs: 64 | Propriedades: 27\n")
  cat("Pontos obrigatorios da B0: ZERO\n")
  cat(
    "Coincidencias casuais com B0: ",
    coincidencias_b0, "\n", sep = ""
  )
  cat(
    "Coincidencias com B1: ",
    coincidencias_b1, "\n", sep = ""
  )
  cat("Novos modelos MaxEnt: ZERO\n")
  cat("\nResultados em:\n", saida, "\n")
  cat("=======================================\n")
}

R18_B2()
