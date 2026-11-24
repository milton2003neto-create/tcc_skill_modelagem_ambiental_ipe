
# ============================================================
# TCC IPES - R15 V3.5 COMPLETO
# BACKGROUND B1 - 10.000 PONTOS
#
# CORRECOES:
# - Comparacao correta entre B0 e B1
# - Recuperacao segura da execucao V3.4, se disponivel
# - Reprocessamento completo quando necessario
# - Preservacao dos 5000 pontos originais
# - Auditoria das 64 UPAs, 27 propriedades e 3 folds
# - Verificacao dos 570227 pixels elegiveis
#
# NAO altera R01-R14 nem executa MaxEnt.
# ============================================================

R15_V35 <- function() {
  
  for (pacote in c("sf", "terra")) {
    if (!requireNamespace(pacote, quietly = TRUE)) {
      stop("Instale o pacote: ", pacote)
    }
  }
  
  sf::sf_use_s2(TRUE)
  
  N_B0 <- 5000L
  N_B1 <- 10000L
  N_PIXELS <- 570227L
  SEMENTE <- 20261116L
  
  vars <- c(
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
    vars
  )
  
  campos_texto <- c(
    "id_background",
    "propriedade",
    "upa_id",
    "celula_raster"
  )
  
  campos_num <- setdiff(campos, campos_texto)
  
  ler <- function(f) {
    read.csv(
      f,
      fileEncoding = "UTF-8-BOM",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  
  salvar <- function(d, f) {
    write.csv(
      d, f, row.names = FALSE,
      fileEncoding = "UTF-8"
    )
  }
  
  normalizar <- function(x) {
    z <- iconv(
      as.character(x),
      to = "ASCII//TRANSLIT",
      sub = ""
    )
    z <- toupper(z)
    z <- gsub("[^A-Z0-9]+", " ", z)
    trimws(gsub(" +", " ", z))
  }
  
  parar <- function(...) {
    stop(paste0(...), call. = FALSE)
  }
  
  # Comparar B0 e B1 sem confundir tipo de coluna
  # com alteracao do valor.
  conferir_b0 <- function(dados, original) {
    
    if (nrow(dados) < N_B0) return(FALSE)
    
    for (nm in campos_texto) {
      a <- as.character(dados[[nm]][seq_len(N_B0)])
      b <- as.character(original[[nm]])
      
      if (!identical(a, b)) {
        return(FALSE)
      }
    }
    
    for (nm in campos_num) {
      a <- as.numeric(dados[[nm]][seq_len(N_B0)])
      b <- as.numeric(original[[nm]])
      
      if (
        anyNA(a) ||
        anyNA(b) ||
        !identical(a, b)
      ) {
        return(FALSE)
      }
    }
    
    TRUE
  }
  
  cat("\n========================================\n")
  cat("R15 V3.5 - BACKGROUND B1\n")
  cat("========================================\n")
  
  cat("\nSelecione 05_BACKGROUND_COM_FOLDS.csv\n")
  
  arquivo_bg <- normalizePath(
    file.choose(),
    winslash = "/",
    mustWork = TRUE
  )
  
  if (basename(arquivo_bg) !=
      "05_BACKGROUND_COM_FOLDS.csv") {
    parar("Arquivo R05 incorreto.")
  }
  
  pasta_r05 <- dirname(arquivo_bg)
  pasta_dados <- dirname(pasta_r05)
  raiz <- dirname(pasta_dados)
  
  if (
    basename(pasta_r05) != "04 - Presencas e folds V3" ||
    basename(pasta_dados) != "04 - Dados para o MaxEnt" ||
    !dir.exists(file.path(raiz, "03 - Trabalho no QGIS"))
  ) {
    parar("Estrutura do projeto nao reconhecida.")
  }
  
  bg_original <- ler(arquivo_bg)
  
  if (
    !all(campos %in% names(bg_original)) ||
    nrow(bg_original) != N_B0 ||
    anyNA(bg_original[, campos, drop = FALSE]) ||
    anyDuplicated(bg_original$id_background)
  ) {
    parar("B0 original inconsistente.")
  }
  
  bg <- bg_original
  
  for (nm in c("longitude", "latitude", vars)) {
    bg[[nm]] <- as.numeric(bg[[nm]])
    
    if (any(!is.finite(bg[[nm]]))) {
      parar("Campo invalido: ", nm)
    }
  }
  
  bg$fold_cv <- as.integer(bg$fold_cv)
  bg$chave <- paste(
    bg$propriedade,
    bg$upa_id,
    sep = "||"
  )
  
  propriedades <- sort(unique(bg$propriedade))
  
  if (
    length(propriedades) != 27L ||
    length(unique(bg$chave)) != 64L ||
    !setequal(unique(bg$fold_cv), 1:3) ||
    any(abs(bg$longitude) > 180) ||
    any(abs(bg$latitude) > 90)
  ) {
    parar("Propriedades, UPAs ou folds incorretos.")
  }
  
  if (any(vapply(
    split(bg$fold_cv, bg$propriedade),
    function(x) length(unique(x)) != 1L,
    logical(1)
  ))) {
    parar("Propriedade presente em folds distintos.")
  }
  
  externas <- normalizar(c(
    "BARRO BRANCO", "CURUÇA",
    "GUARIÚBA", "JATOBÁ",
    "LOTE 01", "MARILIA", "PALMEIRA"
  ))
  
  if (any(normalizar(propriedades) %in% externas)) {
    parar("Teste externo encontrado.")
  }
  
  man_path <- file.path(
    raiz, "06 - Resultados",
    "06 - MaxEnt M1 - Grade 72 V3",
    "08_MANIFESTO_ENTRADAS.csv"
  )
  
  if (!file.exists(man_path)) {
    parar("Manifesto R08 nao encontrado.")
  }
  
  man <- ler(man_path)
  ref <- man[
    man$arquivo == basename(arquivo_bg),
    , drop = FALSE
  ]
  
  md5_atual <- unname(as.character(
    tools::md5sum(arquivo_bg)
  ))
  
  if (
    nrow(ref) != 1L ||
    tolower(as.character(ref$md5)) !=
    tolower(md5_atual)
  ) {
    parar("B0 nao corresponde ao R08.")
  }
  
  cat("\nB0 conferida pelo manifesto R08.\n")
  
  # ----------------------------------------------------------
  # RECUPERACAO DA EXECUCAO ANTERIOR
  # ----------------------------------------------------------
  
  cache_ok <- FALSE
  
  objetos <- c(
    "arquivo_bg", "md5", "saida",
    "pool", "cotas", "novos", "b1", "qa"
  )
  
  if (all(vapply(
    objetos,
    exists,
    logical(1),
    envir = .GlobalEnv,
    inherits = FALSE
  ))) {
    
    antigo_arquivo <- get(
      "arquivo_bg", envir = .GlobalEnv
    )
    
    antigo_md5 <- get(
      "md5", envir = .GlobalEnv
    )
    
    antiga_saida <- get(
      "saida", envir = .GlobalEnv
    )
    
    antigo_pool <- get(
      "pool", envir = .GlobalEnv
    )
    
    antigas_cotas <- get(
      "cotas", envir = .GlobalEnv
    )
    
    antigos_novos <- get(
      "novos", envir = .GlobalEnv
    )
    
    antiga_b1 <- get(
      "b1", envir = .GlobalEnv
    )
    
    antigo_qa <- get(
      "qa", envir = .GlobalEnv
    )
    
    caminho_igual <- identical(
      normalizePath(
        antigo_arquivo,
        winslash = "/",
        mustWork = TRUE
      ),
      arquivo_bg
    )
    
    cache_ok <- isTRUE(
      caminho_igual &&
        identical(as.character(antigo_md5), md5_atual) &&
        grepl("V3_4", antiga_saida, fixed = TRUE) &&
        nrow(antigo_pool) == N_PIXELS &&
        nrow(antigas_cotas) == 64L &&
        nrow(antigos_novos) == N_B0 &&
        nrow(antiga_b1) == N_B1 &&
        nrow(antigo_qa) == 27L &&
        sum(antigo_pool$e_b0) == N_B0 &&
        !any(antigos_novos$e_b0) &&
        sum(antigas_cotas$n_b1) == N_B1 &&
        sum(antigas_cotas$n_adicionais) == N_B0 &&
        length(unique(antigo_pool$chave)) == 64L &&
        conferir_b0(antiga_b1, bg_original)
    )
    
    if (cache_ok) {
      # Confirmar as cotas, os pixels sorteados
      # e a correspondencia com o dominio auditado.
      chaves_novas <- paste(
        antigos_novos$propriedade,
        antigos_novos$cell,
        sep = "||"
      )
      
      chaves_pool <- paste(
        antigo_pool$propriedade,
        antigo_pool$cell,
        sep = "||"
      )
      
      pos <- match(chaves_novas, chaves_pool)
      
      cache_ok <- (
        !anyNA(pos) &&
          !anyDuplicated(chaves_novas) &&
          !any(antigo_pool$e_b0[pos]) &&
          identical(
            as.character(antigo_pool$chave[pos]),
            as.character(antigos_novos$chave)
          ) &&
          !anyNA(antiga_b1[, campos, drop = FALSE])
      )
      
      if (cache_ok) {
        for (nm in vars) {
          if (!isTRUE(all.equal(
            as.numeric(antigo_pool[[nm]][pos]),
            as.numeric(antigos_novos[[nm]]),
            tolerance = 0,
            check.attributes = FALSE
          ))) {
            cache_ok <- FALSE
            break
          }
        }
      }
    }
    
    if (cache_ok) {
      pool <- antigo_pool
      cotas <- antigas_cotas
      novos <- antigos_novos
      b1 <- antiga_b1
      qa <- antigo_qa
      
      cat("\nRECUPERACAO SEGURA: OK\n")
      cat("Os 10000 pontos da V3.4 foram recuperados.\n")
      cat("Nao sera necessario reler os 162 rasters.\n")
    }
  }
  
  # ----------------------------------------------------------
  # CASO NAO HAJA CACHE, REFAZER O PROCESSAMENTO
  # ----------------------------------------------------------
  
  pasta_gerados <- file.path(
    raiz, "03 - Trabalho no QGIS",
    "02 - Arquivos gerados"
  )
  
  pasta_gpkg <- file.path(
    pasta_gerados, "GPKG por propriedade"
  )
  
  fontes_prop <- function(pr) {
    relevo <- file.path(
      pasta_gerados, "Altitude e declividade", pr
    )
    rios <- file.path(
      pasta_gerados, "Distancia aos rios", pr
    )
    clima <- file.path(
      pasta_gerados, "Clima e solo alinhados", pr
    )
    
    c(
      altitude_m = file.path(
        relevo, "altitude_utm30m.tif"
      ),
      declividade_graus = file.path(
        relevo, "declividade_graus_utm30m.tif"
      ),
      dist_rio_raster_m = file.path(
        rios, "distancia_rios_utm30m.tif"
      ),
      bio12_mm_ano = file.path(
        clima, "bio12_utm30m.tif"
      ),
      bio17_mm_mes = file.path(
        clima, "bio17_utm30m.tif"
      ),
      textura_subgrupo = file.path(
        clima, "textura_solo_utm30m.tif"
      )
    )
  }
  
  catalogo <- do.call(rbind, lapply(
    propriedades, function(pr) {
      f <- fontes_prop(pr)
      
      data.frame(
        propriedade = pr,
        variavel = names(f),
        arquivo = unname(f),
        existe = file.exists(f)
      )
    }
  ))
  
  if (
    nrow(catalogo) != 162L ||
    !all(catalogo$existe)
  ) {
    parar("Rasters finais ausentes.")
  }
  
  arquivos_gpkg <- list.files(
    pasta_gpkg,
    pattern = "\\.gpkg$",
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  nomes_gpkg <- normalizar(
    tools::file_path_sans_ext(
      basename(arquivos_gpkg)
    )
  )
  
  gpkg <- setNames(
    rep(NA_character_, length(propriedades)),
    propriedades
  )
  
  for (pr in propriedades) {
    ix <- which(nomes_gpkg == normalizar(pr))
    
    if (length(ix) != 1L) {
      parar("GeoPackage ausente: ", pr)
    }
    
    gpkg[[pr]] <- arquivos_gpkg[ix]
  }
  
  # Criar nova pasta de resultados antes do processamento.
  base_saida <- file.path(
    raiz, "06 - Resultados",
    "13 - Preparacao do background B1 10000 V3_5"
  )
  
  dir.create(
    base_saida, recursive = TRUE,
    showWarnings = FALSE
  )
  
  saida <- file.path(
    base_saida,
    paste0(
      "Execucao_",
      format(Sys.time(), "%Y%m%d_%H%M%S")
    )
  )
  
  if (dir.exists(saida)) {
    parar("Pasta de execucao ja existe.")
  }
  
  dir.create(saida)
  
  salvar(
    catalogo,
    file.path(saida, "15_CATALOGO_FONTES.csv")
  )
  
  if (!cache_ok) {
    
    cat("\nCache indisponivel.\n")
    cat("Executando a preparacao completa...\n")
    
    pool_lista <- list()
    qa_lista <- list()
    crs_lista <- list()
    
    tolerancias <- c(
      altitude_m = 0.01,
      declividade_graus = 0.01,
      dist_rio_raster_m = 0.05,
      bio12_mm_ano = 0.05,
      bio17_mm_mes = 0.02,
      textura_subgrupo = 0
    )
    
    for (pr in propriedades) {
      
      cat("\nPropriedade: ", pr, "\n", sep = "")
      
      antigo <- bg[
        bg$propriedade == pr,
        , drop = FALSE
      ]
      
      geo <- suppressWarnings(sf::st_read(
        gpkg[[pr]],
        layer = "upas",
        quiet = TRUE
      ))
      
      if (is.na(sf::st_crs(geo))) {
        parar("GPKG sem SRC: ", pr)
      }
      
      geo <- suppressWarnings(
        sf::st_make_valid(geo)
      )
      
      geo <- suppressWarnings(
        sf::st_collection_extract(geo, "POLYGON")
      )
      
      geo <- geo[
        !sf::st_is_empty(geo),
        , drop = FALSE
      ]
      
      pontos <- sf::st_as_sf(
        antigo,
        coords = c("longitude", "latitude"),
        crs = 4674,
        remove = FALSE
      )
      
      pontos_geo <- sf::st_transform(
        pontos,
        sf::st_crs(geo)
      )
      
      rel <- sf::st_intersects(
        geo, pontos_geo
      )
      
      codigo <- rep(
        NA_character_, nrow(geo)
      )
      
      for (i in seq_len(nrow(geo))) {
        upas <- unique(
          antigo$upa_id[rel[[i]]]
        )
        
        if (length(upas) > 1L) {
          parar(
            "Poligono com UPAs diferentes: ",
            pr, " feicao ", i
          )
        }
        
        if (length(upas) == 1L) {
          codigo[i] <- upas
        }
      }
      
      geo$upa_r15 <- codigo
      
      geo <- geo[
        !is.na(geo$upa_r15),
        , drop = FALSE
      ]
      
      if (!setequal(
        unique(geo$upa_r15),
        unique(antigo$upa_id)
      )) {
        parar("UPAs nao reproduzidas: ", pr)
      }
      
      relp <- sf::st_intersects(
        pontos_geo, geo
      )
      
      for (i in seq_len(nrow(antigo))) {
        ids <- unique(
          geo$upa_r15[relp[[i]]]
        )
        
        if (
          length(ids) != 1L ||
          ids != antigo$upa_id[i]
        ) {
          parar(
            "Ponto fora de sua UPA: ", pr
          )
        }
      }
      
      rr <- lapply(
        unname(fontes_prop(pr)),
        terra::rast
      )
      
      uma_banda <- vapply(
        rr,
        function(x) terra::nlyr(x) == 1,
        logical(1)
      )
      
      if (!all(uma_banda)) {
        parar("Raster multibanda: ", pr)
      }
      
      crs_base <- sf::st_crs(
        terra::crs(rr[[1]])
      )
      
      if (is.na(crs_base)) {
        parar("Raster sem SRC: ", pr)
      }
      
      for (j in seq_along(rr)) {
        crs_j <- sf::st_crs(
          terra::crs(rr[[j]])
        )
        
        if (
          is.na(crs_j) ||
          !isTRUE(crs_j == crs_base) ||
          terra::is.lonlat(rr[[j]]) ||
          any(abs(terra::res(rr[[j]]) - 30) > 0.05)
        ) {
          parar(
            "SRC ou resolucao diferente: ",
            pr, " / ", vars[j]
          )
        }
      }
      
      geo <- sf::st_transform(
        geo, crs_base
      )
      
      codigos <- sort(
        unique(geo$upa_r15)
      )
      
      geo$codigo_r15 <- match(
        geo$upa_r15, codigos
      )
      
      vetor <- terra::vect(geo)
      
      grade <- terra::crop(
        rr[[1]],
        terra::ext(vetor),
        snap = "out"
      )
      
      mascara <- terra::rasterize(
        vetor, grade,
        field = "codigo_r15",
        touches = FALSE
      )
      
      names(mascara) <- "codigo_r15"
      
      tab <- terra::as.data.frame(
        mascara,
        xy = TRUE,
        cells = TRUE,
        na.rm = TRUE
      )
      
      xy <- as.matrix(
        tab[, c("x", "y"), drop = FALSE]
      )
      
      for (j in seq_along(vars)) {
        extraido <- terra::extract(
          rr[[j]],
          xy,
          method = "simple"
        )
        
        if (
          nrow(extraido) != nrow(tab) ||
          ncol(extraido) != 1L
        ) {
          parar(
            "Extracao raster incorreta: ",
            pr, " / ", vars[j]
          )
        }
        
        tab[[vars[j]]] <- as.numeric(
          extraido[[1]]
        )
      }
      
      valido <- complete.cases(
        tab[, vars, drop = FALSE]
      )
      
      for (nm in vars) {
        valido <- valido &
          is.finite(tab[[nm]])
      }
      
      tab <- tab[
        valido, , drop = FALSE
      ]
      
      tab$upa_id <- codigos[
        as.integer(tab$codigo_r15)
      ]
      
      tab$propriedade <- pr
      tab$fold_cv <- unique(
        antigo$fold_cv
      )
      
      pontos_r <- sf::st_transform(
        pontos, crs_base
      )
      
      celulas_b0 <- terra::cellFromXY(
        grade,
        sf::st_coordinates(pontos_r)
      )
      
      ix <- match(
        celulas_b0, tab$cell
      )
      
      if (
        anyNA(ix) ||
        anyDuplicated(celulas_b0) ||
        any(tab$upa_id[ix] != antigo$upa_id)
      ) {
        parar(
          "Pixels B0 nao reproduzidos: ",
          pr
        )
      }
      
      dif <- vapply(
        vars,
        function(nm) {
          max(abs(
            tab[[nm]][ix] -
              antigo[[nm]]
          ))
        },
        numeric(1)
      )
      
      if (any(dif > tolerancias)) {
        salvar(
          data.frame(
            variavel = vars,
            diferenca = dif,
            tolerancia = tolerancias
          ),
          file.path(
            saida,
            paste0(
              "15_DIVERGENCIA_",
              normalizar(pr), ".csv"
            )
          )
        )
        
        parar(
          "Valores diferentes da B0: ",
          pr
        )
      }
      
      tab$e_b0 <- tab$cell %in% celulas_b0
      
      tab$chave <- paste(
        tab$propriedade,
        tab$upa_id,
        sep = "||"
      )
      
      tab$codigo_r15 <- NULL
      
      pool_lista[[length(pool_lista) + 1L]] <- tab
      crs_lista[[pr]] <- terra::crs(grade)
      
      qa_lista[[length(qa_lista) + 1L]] <-
        data.frame(
          propriedade = pr,
          pixels_elegiveis = nrow(tab),
          pontos_b0 = nrow(antigo),
          maior_diferenca = max(dif)
        )
      
      salvar(
        do.call(rbind, qa_lista),
        file.path(
          saida,
          "15_QA_PARCIAL_POR_PROPRIEDADE.csv"
        )
      )
      
      cat(
        "Pixels: ", nrow(tab),
        " | B0: ", nrow(antigo),
        " | OK\n",
        sep = ""
      )
      
      rm(
        geo, vetor, rr, grade, mascara,
        xy, extraido, tab
      )
      
      invisible(gc(verbose = FALSE))
    }
    
    pool <- do.call(rbind, pool_lista)
    rownames(pool) <- NULL
    
    qa <- do.call(rbind, qa_lista)
    
    if (
      nrow(pool) != N_PIXELS ||
      sum(pool$e_b0) != N_B0 ||
      length(unique(pool$chave)) != 64L
    ) {
      parar(
        "Dominio reconstruido difere do original."
      )
    }
    
    # --------------------------------------------------------
    # COTAS PROPORCIONAIS
    # --------------------------------------------------------
    
    chaves <- sort(unique(pool$chave))
    
    disp <- table(factor(
      pool$chave,
      levels = chaves
    ))
    
    b0_count <- table(factor(
      bg$chave,
      levels = chaves
    ))
    
    cotas <- data.frame(
      chave = chaves,
      pixels_disponiveis = as.integer(disp),
      n_b0 = as.integer(b0_count)
    )
    
    ideal <- N_B1 *
      cotas$pixels_disponiveis /
      sum(cotas$pixels_disponiveis)
    
    cotas$n_b1 <- pmax(
      cotas$n_b0,
      floor(ideal)
    )
    
    while (sum(cotas$n_b1) < N_B1) {
      ix <- which(
        cotas$n_b1 <
          cotas$pixels_disponiveis
      )
      
      if (!length(ix)) {
        parar("Cotas sem capacidade.")
      }
      
      i <- ix[which.max(
        ideal[ix] - cotas$n_b1[ix]
      )]
      
      cotas$n_b1[i] <- cotas$n_b1[i] + 1L
    }
    
    while (sum(cotas$n_b1) > N_B1) {
      ix <- which(
        cotas$n_b1 > cotas$n_b0
      )
      
      if (!length(ix)) {
        parar("Cotas nao ajustaveis.")
      }
      
      i <- ix[which.max(
        cotas$n_b1[ix] - ideal[ix]
      )]
      
      cotas$n_b1[i] <- cotas$n_b1[i] - 1L
    }
    
    cotas$n_adicionais <-
      cotas$n_b1 - cotas$n_b0
    
    if (
      sum(cotas$n_adicionais) != N_B0 ||
      any(cotas$n_adicionais < 0L)
    ) {
      parar("Cotas finais invalidas.")
    }
    
    # --------------------------------------------------------
    # SORTEIO DOS NOVOS PONTOS
    # --------------------------------------------------------
    
    set.seed(SEMENTE)
    
    lista_novos <- list()
    
    for (i in seq_len(nrow(cotas))) {
      n <- cotas$n_adicionais[i]
      
      if (n == 0L) next
      
      elegiveis <- pool[
        pool$chave == cotas$chave[i] &
          !pool$e_b0,
        , drop = FALSE
      ]
      
      if (n > nrow(elegiveis)) {
        parar("Pixels insuficientes.")
      }
      
      s <- sample.int(
        nrow(elegiveis),
        n, replace = FALSE
      )
      
      lista_novos[[length(lista_novos) + 1L]] <-
        elegiveis[s, , drop = FALSE]
    }
    
    novos <- do.call(rbind, lista_novos)
    rownames(novos) <- NULL
    
    novos$longitude <- NA_real_
    novos$latitude <- NA_real_
    
    for (pr in unique(novos$propriedade)) {
      ix <- which(
        novos$propriedade == pr
      )
      
      pts <- sf::st_as_sf(
        novos[ix, , drop = FALSE],
        coords = c("x", "y"),
        crs = sf::st_crs(crs_lista[[pr]]),
        remove = FALSE
      )
      
      pts <- sf::st_transform(
        pts, 4674
      )
      
      xy <- sf::st_coordinates(pts)
      
      novos$longitude[ix] <- xy[, 1]
      novos$latitude[ix] <- xy[, 2]
    }
    
    novos$id_background <- paste0(
      "B1_ADIC_",
      sprintf("%05d", seq_len(nrow(novos)))
    )
    
    novos$celula_raster <- paste0(
      "B1_",
      gsub(
        " ", "_",
        normalizar(novos$propriedade)
      ),
      "_",
      novos$cell
    )
    
    # --------------------------------------------------------
    # MONTAR A B1 CORRIGINDO OS TIPOS
    # --------------------------------------------------------
    
    b0_out <- bg_original[
      , campos, drop = FALSE
    ]
    
    novos_out <- novos[
      , campos, drop = FALSE
    ]
    
    for (nm in campos_texto) {
      b0_out[[nm]] <- as.character(b0_out[[nm]])
      novos_out[[nm]] <- as.character(novos_out[[nm]])
    }
    
    for (nm in campos_num) {
      b0_out[[nm]] <- as.numeric(b0_out[[nm]])
      novos_out[[nm]] <- as.numeric(novos_out[[nm]])
    }
    
    b0_out$origem_amostra <- "B0_PRESERVADO"
    novos_out$origem_amostra <- "B1_ADICIONAL"
    
    b1 <- rbind(b0_out, novos_out)
    rownames(b1) <- NULL
  }
  
  # ----------------------------------------------------------
  # VALIDACAO FINAL - COM OU SEM RECUPERACAO
  # ----------------------------------------------------------
  
  if (
    nrow(b1) != N_B1 ||
    anyNA(b1[, campos, drop = FALSE]) ||
    anyDuplicated(b1$id_background) ||
    sum(b1$origem_amostra == "B0_PRESERVADO") != N_B0 ||
    sum(b1$origem_amostra == "B1_ADICIONAL") != N_B0
  ) {
    parar("Background final inconsistente.")
  }
  
  if (!conferir_b0(b1, bg_original)) {
    parar(
      "Os VALORES da B0 sao diferentes. ",
      "A B1 nao sera salva."
    )
  }
  
  chaves_b1 <- paste(
    b1$propriedade,
    b1$upa_id,
    sep = "||"
  )
  
  if (
    length(unique(chaves_b1)) != 64L ||
    any(normalizar(b1$propriedade) %in% externas)
  ) {
    parar("UPAs ou teste externo inconsistentes.")
  }
  
  if (any(vapply(
    split(b1$fold_cv, b1$propriedade),
    function(x) length(unique(x)) != 1L,
    logical(1)
  ))) {
    parar("Folds foram alterados.")
  }
  
  contagem_final <- table(
    factor(
      chaves_b1,
      levels = cotas$chave
    )
  )
  
  if (!identical(
    as.integer(contagem_final),
    as.integer(cotas$n_b1)
  )) {
    parar("Cotas B1 nao conferem.")
  }
  
  # Conferir duplicidades e inclusao dos novos pixels.
  novos_chaves <- paste(
    novos$propriedade,
    novos$cell,
    sep = "||"
  )
  
  pool_chaves <- paste(
    pool$propriedade,
    pool$cell,
    sep = "||"
  )
  
  pos <- match(novos_chaves, pool_chaves)
  
  if (
    nrow(novos) != N_B0 ||
    anyDuplicated(novos_chaves) ||
    anyNA(pos) ||
    any(pool$e_b0[pos])
  ) {
    parar("Os novos pixels nao passaram na auditoria.")
  }
  
  # ----------------------------------------------------------
  # SALVAR RESULTADOS
  # ----------------------------------------------------------
  
  resumo_upa <- aggregate(
    id_background ~ propriedade + upa_id + fold_cv,
    data = b1,
    FUN = length
  )
  
  names(resumo_upa)[4] <- "n_background_b1"
  
  resumo_fold <- aggregate(
    id_background ~ fold_cv,
    data = b1,
    FUN = length
  )
  
  names(resumo_fold)[2] <- "n_background_b1"
  
  salvar(
    b1,
    file.path(
      saida,
      "15_BACKGROUND_B1_10000_COM_FOLDS.csv"
    )
  )
  
  salvar(
    b1[b1$origem_amostra == "B1_ADICIONAL", ],
    file.path(saida, "15_PONTOS_ADICIONAIS_B1.csv")
  )
  
  salvar(
    cotas,
    file.path(saida, "15_COTAS_B1_POR_UPA.csv")
  )
  
  salvar(
    resumo_upa,
    file.path(saida, "15_RESUMO_B1_POR_UPA.csv")
  )
  
  salvar(
    resumo_fold,
    file.path(saida, "15_RESUMO_B1_POR_FOLD.csv")
  )
  
  salvar(
    qa,
    file.path(saida, "15_QA_FINAL_POR_PROPRIEDADE.csv")
  )
  
  fontes_manifesto <- unique(c(
    arquivo_bg,
    man_path,
    unname(gpkg),
    catalogo$arquivo
  ))
  
  manifestof <- data.frame(
    caminho = normalizePath(
      fontes_manifesto,
      winslash = "/",
      mustWork = TRUE
    ),
    md5 = unname(as.character(
      tools::md5sum(fontes_manifesto)
    ))
  )
  
  salvar(
    manifestof,
    file.path(saida, "15_MANIFESTO_FONTES.csv")
  )
  
  writeLines(
    c(
      "TCC IPES - R15 V3.5",
      "BACKGROUND B1 - 10000 PONTOS",
      "",
      "B0: 5000 pontos preservados.",
      "B1: 5000 pontos adicionais.",
      "Total: 10000 pontos.",
      "",
      "27 propriedades de desenvolvimento.",
      "64 UPAs efetivamente inventariadas.",
      "570227 pixels elegiveis.",
      "Tres folds espaciais.",
      "",
      "Amostragem proporcional por UPA.",
      "Cotas respeitando B0.",
      "Sorteio sem reposicao.",
      paste("Semente:", SEMENTE),
      "",
      paste(
        "Recuperacao da V3.4:",
        ifelse(cache_ok, "SIM", "NAO")
      ),
      "",
      "B0 conferida com manifesto do R08.",
      "Identificadores conferidos como texto.",
      "Variaveis ambientais conferidas numericamente.",
      "UPAs e folds preservados.",
      "Teste externo excluido.",
      "Nenhum ajuste MaxEnt realizado.",
      "",
      paste("Data:", as.character(Sys.time())),
      paste("R:", R.version.string)
    ),
    file.path(saida, "15_RELATORIO_B1.txt")
  )
  
  writeLines(
    capture.output(sessionInfo()),
    file.path(saida, "15_SESSION_INFO.txt")
  )
  
  cat("\n========================================\n")
  cat("R15 V3.5 CONCLUIDO!\n")
  cat("========================================\n")
  cat("B0 preservada: 5000 pontos\n")
  cat("Novos pontos: 5000\n")
  cat("B1 total: 10000 pontos\n")
  cat("UPAs: 64 | Propriedades: 27\n")
  cat("Recuperacao: ",
      ifelse(cache_ok, "SIM", "NAO"), "\n", sep = "")
  cat("\nResultados:\n", saida, "\n")
  cat("========================================\n")
}

R15_V35()
