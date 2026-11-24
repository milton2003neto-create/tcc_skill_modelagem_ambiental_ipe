
# ============================================================
# TCC IPES - R12 V3.1
# AUDITORIA DA VALIDACAO ESPACIAL - BACKGROUND B0
#
# Corrige a identificacao das camadas "upas".
# Usa apenas as 27 propriedades de desenvolvimento.
# Nao ajusta MaxEnt nem modifica resultados anteriores.
# ============================================================

if (!requireNamespace("sf", quietly = TRUE)) {
  stop("Instale sf: install.packages('sf')")
}
sf::sf_use_s2(TRUE)

cat("\nR12 V3.1 - Selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv\n")
arq <- normalizePath(file.choose(), winslash = "/",
                     mustWork = TRUE)

if (basename(arq) != "05_PRESENCAS_UM_POR_PIXEL_30M.csv")
  stop("Selecione o arquivo correto do R05.")

entrada <- dirname(arq)
raiz <- dirname(dirname(entrada))

if (basename(entrada) != "04 - Presencas e folds V3" ||
    basename(dirname(entrada)) != "04 - Dados para o MaxEnt" ||
    !dir.exists(file.path(raiz, "03 - Trabalho no QGIS")))
  stop("Estrutura V3 nao encontrada.")

ler <- function(x) {
  read.csv(x, fileEncoding = "UTF-8-BOM",
           stringsAsFactors = FALSE, check.names = FALSE)
}

bg_arq <- file.path(entrada, "05_BACKGROUND_COM_FOLDS.csv")
total_arq <- file.path(
  entrada, "05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv")
manifesto_arq <- file.path(
  raiz, "06 - Resultados",
  "06 - MaxEnt M1 - Grade 72 V3",
  "08_MANIFESTO_ENTRADAS.csv")

if (!all(file.exists(c(bg_arq, total_arq, manifesto_arq))))
  stop("Faltam entradas R05/R08.")

pres <- ler(arq)
bg <- ler(bg_arq)
total <- ler(total_arq)
manifesto <- ler(manifesto_arq)

if (nrow(pres) != 8680L || nrow(bg) != 5000L ||
    nrow(total) != 9004L ||
    sum(pres$especie == "Ipe-roxo") != 3248L ||
    sum(pres$especie == "Ipe-amarelo") != 5432L)
  stop("Contagens diferentes do R05 auditado.")

for (f in c(arq, bg_arq, total_arq)) {
  z <- manifesto[manifesto$arquivo == basename(f), ]
  if (nrow(z) != 1L ||
      tolower(as.character(z$md5)) !=
      tolower(unname(as.character(tools::md5sum(f)))))
    stop("Arquivo modificado desde R08: ", basename(f))
}

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA")

if (any(c(pres$propriedade, bg$propriedade) %in% externas))
  stop("TESTE EXTERNO detectado.")

normalizar <- function(x) {
  y <- iconv(as.character(x), to = "ASCII//TRANSLIT")
  y <- toupper(y)
  y <- gsub("[^A-Z0-9]+", " ", y)
  trimws(gsub(" +", " ", y))
}

normalizar_upa <- function(x) {
  y <- normalizar(x)
  y[y %in% c("UNICA", "UPA UNICA")] <- "UPA UNICA"
  ok <- grepl("^(UPA )?0*[0-9]+$", y)
  if (any(ok)) {
    n <- as.integer(gsub("[^0-9]", "", y[ok]))
    y[ok] <- sprintf("UPA %02d", n)
  }
  y
}

obter_coluna <- function(d, nomes) {
  ix <- which(tolower(names(d)) %in% nomes)
  if (length(ix) != 1L)
    stop("Coluna geográfica ausente ou ambigua.")
  names(d)[ix]
}

montar_pontos <- function(d) {
  lon <- obter_coluna(d, c("longitude", "lon", "long"))
  lat <- obter_coluna(d, c("latitude", "lat"))
  if (any(!is.finite(d[[lon]])) ||
      any(!is.finite(d[[lat]])) ||
      any(abs(d[[lon]]) > 180) ||
      any(abs(d[[lat]]) > 90))
    stop("Coordenadas invalidas.")
  
  sf::st_as_sf(d, coords = c(lon, lat),
               crs = 4674, remove = FALSE)
}

pres$prop_norm <- normalizar(pres$propriedade)
pres$upa_norm <- normalizar_upa(pres$upa_id)
bg$prop_norm <- normalizar(bg$propriedade)
bg$upa_norm <- normalizar_upa(bg$upa_id)

props <- unique(rbind(
  pres[, c("propriedade", "fold_cv")],
  bg[, c("propriedade", "fold_cv")]))

if (length(unique(props$propriedade)) != 27L ||
    any(vapply(split(props$fold_cv, props$propriedade),
               function(x) length(unique(x)) != 1L,
               logical(1))))
  stop("Propriedades distribuidas incorretamente.")

chaves <- unique(c(
  paste(pres$prop_norm, pres$upa_norm, sep = "|"),
  paste(bg$prop_norm, bg$upa_norm, sep = "|")
))

if (length(chaves) != 64L)
  stop("Quantidade de UPAs diferente de 64.")

cat("27 propriedades e 64 UPAs confirmadas.\n")

# ------------------------------------------------------------
# Saida em pasta nova, preservando tentativas anteriores
# ------------------------------------------------------------

base_saida <- file.path(
  raiz, "06 - Resultados",
  "10 - Auditoria da validacao espacial B0 V3_1")

dir.create(base_saida, recursive = TRUE,
           showWarnings = FALSE)

saida <- file.path(
  base_saida,
  paste0("Execucao_", format(Sys.time(), "%Y%m%d_%H%M%S"))
)

if (dir.exists(saida))
  stop("Pasta de execucao ja existente.")

dir.create(saida)

salvar <- function(d, nome) {
  write.csv(d, file.path(saida, nome),
            row.names = FALSE, fileEncoding = "UTF-8")
}

# ------------------------------------------------------------
# 1. Ler APENAS camadas de UPAs dos GPKGs oficiais
# ------------------------------------------------------------

pasta_gpkg <- file.path(
  raiz, "03 - Trabalho no QGIS",
  "02 - Arquivos gerados",
  "GPKG por propriedade")

if (!dir.exists(pasta_gpkg))
  stop("Pasta GPKG por propriedade nao encontrada.")

arquivos <- list.files(
  pasta_gpkg, pattern = "\\.gpkg$",
  full.names = TRUE, ignore.case = TRUE)

if (length(arquivos) != 34L)
  stop("Esperados 34 GPKGs por propriedade.")

geo_lista <- list()
log_lista <- list()
ng <- 0L
nl <- 0L
erros <- character()

for (f in arquivos) {
  prop_norm <- normalizar(
    tools::file_path_sans_ext(basename(f)))
  
  if (!(prop_norm %in% pres$prop_norm)) next
  
  info <- sf::st_layers(f)
  camada <- info$name[
    tolower(info$name) == "upas"
  ]
  
  if (length(camada) != 1L) {
    erros <- c(erros, paste("Camada upas ausente:", f))
    next
  }
  
  d <- suppressWarnings(
    sf::st_read(f, layer = camada, quiet = TRUE))
  
  if (is.na(sf::st_crs(d))) {
    erros <- c(erros, paste("SRC ausente:", f))
    next
  }
  
  d <- suppressWarnings(sf::st_make_valid(d))
  d <- suppressWarnings(
    sf::st_collection_extract(d, "POLYGON"))
  
  d <- sf::st_transform(d, 4674)
  d <- d[!sf::st_is_empty(d), , drop = FALSE]
  
  if (!nrow(d)) {
    erros <- c(erros, paste("Sem poligonos:", f))
    next
  }
  
  pontos_prop <- rbind(
    pres[pres$prop_norm == prop_norm,
         c("propriedade", "upa_norm", "longitude",
           "latitude"), drop = FALSE],
    bg[bg$prop_norm == prop_norm,
       c("propriedade", "upa_norm", "longitude",
         "latitude"), drop = FALSE]
  )
  
  pontos_sf <- montar_pontos(pontos_prop)
  
  rel <- sf::st_intersects(d, pontos_sf)
  
  # Campos originais que podem identificar a UPA.
  campos <- grep(
    "upa|unidade|nome",
    names(sf::st_drop_geometry(d)),
    ignore.case = TRUE, value = TRUE)
  
  upas_esperadas <- unique(pontos_prop$upa_norm)
  
  for (i in seq_len(nrow(d))) {
    identificacao_espacial <- unique(
      pontos_prop$upa_norm[rel[[i]]])
    
    candidatos_attr <- character()
    
    for (campo in campos) {
      valor <- normalizar_upa(d[[campo]][i])
      if (!is.na(valor) &&
          valor %in% upas_esperadas) {
        candidatos_attr <- c(candidatos_attr, valor)
      }
    }
    
    candidatos_attr <- unique(candidatos_attr)
    
    resultado <- NA_character_
    metodo <- "NAO_IDENTIFICADO"
    
    if (length(identificacao_espacial) > 1L) {
      erros <- c(erros, paste(
        "Poligono contem pontos de UPAs diferentes:",
        basename(f), "feicao", i))
    } else if (length(candidatos_attr) > 1L) {
      erros <- c(erros, paste(
        "Atributos de UPA contraditorios:",
        basename(f), "feicao", i))
    } else if (length(identificacao_espacial) == 1L &&
               length(candidatos_attr) == 1L &&
               identificacao_espacial != candidatos_attr) {
      erros <- c(erros, paste(
        "Atributo e posicao discordam:",
        basename(f), "feicao", i))
    } else if (length(identificacao_espacial) == 1L) {
      resultado <- identificacao_espacial
      metodo <- "PONTOS_R05"
    } else if (length(candidatos_attr) == 1L) {
      resultado <- candidatos_attr
      metodo <- "ATRIBUTO_GPKG"
    } else {
      # A geometria pode pertencer a uma UPA nao inventariada.
      # Como nao e possivel confirmar, nao sera incluida.
      metodo <- "SEM_CORRESPONDENCIA_CONFIRMADA"
    }
    
    nl <- nl + 1L
    log_lista[[nl]] <- data.frame(
      arquivo = basename(f),
      feicao = i,
      propriedade = prop_norm,
      upa = ifelse(is.na(resultado), "", resultado),
      n_pontos = length(rel[[i]]),
      metodo = metodo,
      stringsAsFactors = FALSE
    )
    
    if (!is.na(resultado)) {
      ng <- ng + 1L
      geo_lista[[ng]] <- sf::st_sf(
        chave = paste(prop_norm, resultado, sep = "|"),
        geometria = sf::st_geometry(d)[i]
      )
    }
  }
}

log_df <- do.call(rbind, log_lista)
salvar(log_df, "12_IDENTIFICACAO_UPAS.csv")

if (length(erros)) {
  writeLines(erros, file.path(saida,
                              "12_ERROS_IDENTIFICACAO.txt"))
  stop("Problemas de identificacao. Consulte o TXT.")
}

if (!length(geo_lista))
  stop("Nenhuma UPA identificada.")

geo <- do.call(rbind, geo_lista)

faltantes <- setdiff(chaves, unique(geo$chave))

if (length(faltantes)) {
  salvar(data.frame(upa_faltante = faltantes),
         "12_UPAS_NAO_IDENTIFICADAS.csv")
  stop("Nem todas as 64 UPAs foram identificadas.")
}

# Se uma UPA tiver varias partes, unir suas geometrias.
ids <- sort(unique(geo$chave))

geometrias <- lapply(ids, function(k) {
  sf::st_union(
    sf::st_geometry(geo[geo$chave == k, ])
  )[[1]]
})

upas <- sf::st_sf(
  chave = ids,
  geometry = sf::st_sfc(geometrias, crs = 4674))

upas$prop_norm <- sub("\\|.*$", "", upas$chave)
upas$upa_norm <- sub("^.*\\|", "", upas$chave)

referencia <- unique(props)
referencia$prop_norm <- normalizar(referencia$propriedade)

upas$propriedade <- referencia$propriedade[
  match(upas$prop_norm, referencia$prop_norm)]

upas$fold_cv <- referencia$fold_cv[
  match(upas$prop_norm, referencia$prop_norm)]

if (nrow(upas) != 64L ||
    anyNA(upas$fold_cv) ||
    anyNA(upas$propriedade))
  stop("UPAs finais inconsistentes.")

# Conferir se cada ponto tem cobertura da UPA declarada.
pontos <- rbind(
  pres[, c("propriedade", "upa_norm",
           "longitude", "latitude")],
  bg[, c("propriedade", "upa_norm",
         "longitude", "latitude")]
)
pontos$chave <- paste(
  normalizar(pontos$propriedade),
  pontos$upa_norm, sep = "|")

pontos_sf <- montar_pontos(pontos)
fora <- integer()

for (i in seq_len(nrow(upas))) {
  ix <- which(pontos$chave == upas$chave[i])
  dentro <- lengths(sf::st_intersects(
    pontos_sf[ix, ], upas[i, ])) > 0
  if (any(!dentro))
    fora <- c(fora, ix[!dentro])
}

if (length(fora)) {
  salvar(pontos[fora, , drop = FALSE],
         "12_PONTOS_FORA_DA_UPA_DECLARADA.csv")
  stop("Pontos fora de suas UPAs. Conferir antes de continuar.")
}

salvar(sf::st_drop_geometry(upas)[
  , c("chave", "propriedade", "upa_norm", "fold_cv")],
  "12_UPAS_FOLDS_CONFERIDOS.csv")

cat("\n64 UPAs identificadas e conferidas espacialmente.\n")

# ------------------------------------------------------------
# 2. Distancias reais entre UPAs de folds distintos
# ------------------------------------------------------------

upas_wgs <- sf::st_transform(upas, 4326)
dist_m <- sf::st_distance(upas_wgs)

pares <- list()
k <- 0L

for (i in seq_len(nrow(upas) - 1L)) {
  for (j in seq.int(i + 1L, nrow(upas))) {
    if (upas$fold_cv[i] == upas$fold_cv[j]) next
    
    k <- k + 1L
    pares[[k]] <- data.frame(
      propriedade_a = upas$propriedade[i],
      upa_a = upas$upa_norm[i],
      fold_a = upas$fold_cv[i],
      propriedade_b = upas$propriedade[j],
      upa_b = upas$upa_norm[j],
      fold_b = upas$fold_cv[j],
      distancia_m = as.numeric(dist_m[i, j])
    )
  }
}

pares <- do.call(rbind, pares)
pares <- pares[order(pares$distancia_m), ]

salvar(pares, "12_DISTANCIAS_ENTRE_UPAS_FOLDS.csv")

dist_props <- aggregate(
  distancia_m ~ propriedade_a + propriedade_b +
    fold_a + fold_b,
  data = pares, FUN = min)

salvar(dist_props,
       "12_DISTANCIA_MINIMA_PROPRIEDADES.csv")

mais_proximas <- lapply(seq_len(nrow(upas)), function(i) {
  outros <- which(upas$fold_cv != upas$fold_cv[i])
  valores <- as.numeric(dist_m[i, outros])
  j <- outros[which.min(valores)]
  
  data.frame(
    propriedade = upas$propriedade[i],
    upa = upas$upa_norm[i],
    fold = upas$fold_cv[i],
    propriedade_vizinha = upas$propriedade[j],
    upa_vizinha = upas$upa_norm[j],
    fold_vizinho = upas$fold_cv[j],
    distancia_m = min(valores)
  )
})

salvar(do.call(rbind, mais_proximas),
       "12_VIZINHO_MAIS_PROXIMO_POR_UPA.csv")

# ------------------------------------------------------------
# 3. Autocorrelacao ambiental exploratoria no background
# ------------------------------------------------------------

cat("\nCalculando autocorrelacao...\n")

continuas <- c(
  "altitude_m", "declividade_graus",
  "dist_rio_raster_m", "bio12_mm_ano",
  "bio17_mm_mes")

set.seed(20261115)

moran_lista <- list()
semi_lista <- list()
nm <- 0L
ns <- 0L

faixas <- c(
  0, 250, 500, 1000, 2000, 4000,
  8000, 16000, Inf)

rotulos <- c(
  "0-250", "250-500", "500-1000",
  "1000-2000", "2000-4000",
  "4000-8000", "8000-16000", ">16000")

for (pr in unique(bg$propriedade)) {
  d <- bg[bg$propriedade == pr, ]
  
  if (nrow(d) < 12L) next
  
  sfp <- sf::st_transform(montar_pontos(d), 4326)
  
  D <- sf::st_distance(sfp)
  D <- matrix(as.numeric(D),
              nrow = nrow(d), ncol = nrow(d))
  diag(D) <- Inf
  
  viz <- t(vapply(seq_len(nrow(d)), function(i) {
    order(D[i, ])[seq_len(min(8L, nrow(d) - 1L))]
  }, integer(min(8L, nrow(d) - 1L))))
  
  n_viz <- ncol(viz)
  
  calc_moran <- function(x) {
    z <- x - mean(x)
    if (sum(z^2) < 1e-12) return(NA_real_)
    mz <- rowMeans(matrix(
      z[viz], nrow = length(z), ncol = n_viz))
    sum(z * mz) / sum(z^2)
  }
  
  for (v in continuas) {
    x <- as.numeric(d[[v]])
    if (any(!is.finite(x)) || sd(x) < 1e-12) next
    
    observado <- calc_moran(x)
    simulados <- replicate(199, calc_moran(sample(x)))
    
    nm <- nm + 1L
    moran_lista[[nm]] <- data.frame(
      propriedade = pr,
      fold = unique(d$fold_cv)[1],
      variavel = v,
      n_background = nrow(d),
      vizinhos = n_viz,
      moran_i = observado,
      p_permutacao_unilateral =
        (1 + sum(simulados >= observado)) / 200
    )
  }
  
  # Semivariograma: amostra limitada a 150 pontos
  # por propriedade para reduzir custo de processamento.
  ii <- sample(seq_len(nrow(d)), min(150L, nrow(d)))
  sub <- d[ii, ]
  sfsub <- sf::st_transform(montar_pontos(sub), 4326)
  
  ds <- sf::st_distance(sfsub)
  ds <- matrix(as.numeric(ds),
               nrow = nrow(sub), ncol = nrow(sub))
  
  tri <- upper.tri(ds)
  grupos <- cut(
    ds[tri], breaks = faixas,
    labels = rotulos, include.lowest = TRUE)
  
  for (v in continuas) {
    x <- as.numeric(sub[[v]])
    if (any(!is.finite(x)) || sd(x) < 1e-12) next
    
    z <- as.numeric(scale(x))
    gamma <- 0.5 * outer(z, z, "-")[tri]^2
    
    for (fx in rotulos) {
      sel <- which(as.character(grupos) == fx)
      if (length(sel) < 10L) next
      
      ns <- ns + 1L
      semi_lista[[ns]] <- data.frame(
        propriedade = pr,
        variavel = v,
        faixa_m = fx,
        n_pares = length(sel),
        soma_semivariancia = sum(gamma[sel])
      )
    }
  }
}

if (length(moran_lista))
  salvar(do.call(rbind, moran_lista),
         "12_MORAN_POR_PROPRIEDADE.csv")

if (length(semi_lista)) {
  semi <- do.call(rbind, semi_lista)
  salvar(semi, "12_SEMIVARIOGRAMA_POR_PROPRIEDADE.csv")
  
  resumo_semi <- aggregate(
    cbind(n_pares, soma_semivariancia) ~
      variavel + faixa_m,
    data = semi, FUN = sum)
  
  resumo_semi$semivariancia_media <-
    resumo_semi$soma_semivariancia / resumo_semi$n_pares
  
  salvar(resumo_semi, "12_SEMIVARIOGRAMA_RESUMO.csv")
}

# ------------------------------------------------------------
# 4. Mapas, graficos e relatorio
# ------------------------------------------------------------

graficos <- file.path(saida, "12_GRAFICOS")
dir.create(graficos)

png(file.path(graficos, "12_MAPA_UPAS_FOLDS.png"),
    width = 1400, height = 1000, res = 140)

cores <- c("gray85", "gray55", "gray20")

plot(sf::st_geometry(upas_wgs),
     col = cores[upas$fold_cv],
     border = "gray35",
     main = "UPAs inventariadas de desenvolvimento")

legend("bottomleft",
       legend = paste("Fold", 1:3),
       fill = cores, bty = "n")
dev.off()

png(file.path(graficos, "12_DISTANCIAS_FOLDS.png"),
    width = 1200, height = 750, res = 140)

hist(pares$distancia_m / 1000,
     breaks = 35,
     col = "gray70",
     main = "Distancias entre UPAs de folds diferentes",
     xlab = "Distancia entre poligonos (km)",
     ylab = "Pares de UPAs")
dev.off()

relatorio <- c(
  "TCC IPES - R12 V3.1",
  "AUDITORIA DA VALIDACAO ESPACIAL - BACKGROUND B0",
  "",
  paste("UPAs inventariadas:", nrow(upas)),
  paste("Propriedades:", length(unique(upas$propriedade))),
  paste("Background:", nrow(bg)),
  paste("Pares entre folds:", nrow(pares)),
  paste("Menor distancia (m):",
        round(min(pares$distancia_m), 2)),
  paste("Pares abaixo de 1 km:",
        sum(pares$distancia_m < 1000)),
  paste("Pares abaixo de 5 km:",
        sum(pares$distancia_m < 5000)),
  "",
  "As distancias usam os poligonos das UPAs.",
  "Calculo geodesico via sf/s2 em metros.",
  "Nao representam distancias entre centroides.",
  "",
  "Moran e semivariogramas sao exploratorios,",
  "baseados nos pontos de background.",
  "Nao substituem autocorrelacao nos rasters originais.",
  "BIO12 e BIO17 possuem resolucao nativa mais grosseira.",
  "O solo categorico nao foi incluido nesses calculos.",
  "",
  "A independencia espacial nao esta automaticamente",
  "comprovada pela distancia entre poligonos.",
  "Os folds NAO foram alterados.",
  "Teste externo NAO utilizado.",
  "Modelos MaxEnt reajustados: ZERO.",
  "Resultados R01-R11 preservados.",
  "",
  paste("Data:", as.character(Sys.time())),
  paste("R:", R.version.string),
  paste("sf:", as.character(packageVersion("sf")))
)

writeLines(relatorio,
           file.path(saida, "12_LEIA_RESULTADOS.txt"))

writeLines(capture.output(sessionInfo()),
           file.path(saida, "12_SESSION_INFO.txt"))

cat("\n========================================\n")
cat("R12 V3.1 FINALIZADO!\n")
cat("UPAs:", nrow(upas), "\n")
cat("Menor distancia entre folds:",
    round(min(pares$distancia_m), 2), "metros\n")
cat("Resultados:", saida, "\n")
cat("========================================\n")
