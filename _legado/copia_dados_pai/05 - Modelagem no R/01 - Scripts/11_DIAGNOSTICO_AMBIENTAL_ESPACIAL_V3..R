
# ============================================================
# TCC IPES - R11 V3
# DIAGNOSTICO AMBIENTAL, CLAMPING E VALIDACAO ESPACIAL
#
# Usa modelos e previsoes ja existentes do R08 e R10.
# NAO ajusta modelos. NAO modifica resultados anteriores.
# NAO utiliza as sete propriedades de teste externo.
# ============================================================

if (!requireNamespace("maxnet", quietly = TRUE)) {
  stop("Instale maxnet: install.packages('maxnet')")
}

cat("\nR11 - Selecione 10_METRICAS_36_AVALIACOES.csv\n")
arq <- normalizePath(file.choose(), winslash = "/",
                     mustWork = TRUE)

if (basename(arq) != "10_METRICAS_36_AVALIACOES.csv") {
  stop("Selecione o CSV de metricas do R10.")
}

pasta_m2 <- dirname(arq)
raiz <- dirname(dirname(pasta_m2))

if (basename(pasta_m2) !=
    "08 - MaxEnt M2 - Variaveis V3" ||
    basename(dirname(pasta_m2)) != "06 - Resultados" ||
    !dir.exists(file.path(raiz, "03 - Trabalho no QGIS"))) {
  stop("Estrutura oficial do projeto nao encontrada.")
}

pasta_r05 <- file.path(
  raiz, "04 - Dados para o MaxEnt",
  "04 - Presencas e folds V3"
)

pasta_m1 <- file.path(
  raiz, "06 - Resultados",
  "06 - MaxEnt M1 - Grade 72 V3"
)

saida <- file.path(
  raiz, "06 - Resultados",
  "09 - Diagnostico ambiental e espacial V3"
)

ler <- function(x) {
  read.csv(x, fileEncoding = "UTF-8-BOM",
           stringsAsFactors = FALSE, check.names = FALSE)
}

arq_pres <- file.path(
  pasta_r05, "05_PRESENCAS_UM_POR_PIXEL_30M.csv"
)
arq_bg <- file.path(
  pasta_r05, "05_BACKGROUND_COM_FOLDS.csv"
)
arq_m1 <- file.path(
  pasta_m1, "08_METRICAS_72_MODELOS.csv"
)
arq_manifesto <- file.path(
  pasta_m1, "08_MANIFESTO_ENTRADAS.csv"
)

arquivos <- c(arq_pres, arq_bg, arq_m1,
              arq_manifesto, arq)

if (!all(file.exists(arquivos))) {
  stop("Faltam arquivos do R05, R08 ou R10.")
}

pres <- ler(arq_pres)
bg <- ler(arq_bg)
m1 <- ler(arq_m1)
m2 <- ler(arq)
manifesto <- ler(arq_manifesto)

cont <- c(
  "altitude_m",
  "declividade_graus",
  "dist_rio_raster_m",
  "bio12_mm_ano",
  "bio17_mm_mes"
)

vars <- c(cont, "textura_subgrupo")

if (nrow(pres) != 8680L ||
    nrow(bg) != 5000L ||
    nrow(m1) != 72L ||
    nrow(m2) != 36L ||
    anyDuplicated(m2$id) ||
    !all(vars %in% names(pres)) ||
    !all(vars %in% names(bg))) {
  stop("Entradas diferentes das bases auditadas.")
}

# Confere os arquivos de origem contra o manifesto do R08.
for (f in c(arq_pres, arq_bg)) {
  z <- manifesto[
    manifesto$arquivo == basename(f), , drop = FALSE
  ]
  md5 <- unname(as.character(tools::md5sum(f)))
  if (nrow(z) != 1L ||
      tolower(as.character(z$md5)) != tolower(md5)) {
    stop("Arquivo alterado desde o R08: ", basename(f))
  }
}

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
)

if (any(c(pres$propriedade, bg$propriedade) %in%
        externas)) {
  stop("TESTE EXTERNO detectado. Execucao interrompida.")
}

props <- unique(rbind(
  pres[, c("propriedade", "fold_cv")],
  bg[, c("propriedade", "fold_cv")]
))

if (length(unique(props$propriedade)) != 27L ||
    any(vapply(
      split(props$fold_cv, props$propriedade),
      function(z) length(unique(z)) != 1L,
      logical(1)
    ))) {
  stop("Particao das propriedades inconsistente.")
}

classes_solo <- sort(unique(c(
  as.character(pres$textura_subgrupo),
  as.character(bg$textura_subgrupo)
)))

montar_x <- function(d, variaveis) {
  x <- d[, variaveis, drop = FALSE]
  for (v in intersect(variaveis, cont)) {
    x[[v]] <- as.numeric(x[[v]])
  }
  if ("textura_subgrupo" %in% variaveis) {
    x$textura_subgrupo <- factor(
      as.character(x$textura_subgrupo),
      levels = classes_solo
    )
  }
  if (anyNA(x)) stop("Preditor com NA.")
  x
}

auc <- function(p, b) {
  n <- length(p)
  k <- length(b)
  if (!n || !k || any(!is.finite(c(p, b)))) {
    return(NA_real_)
  }
  r <- rank(c(p, b), ties.method = "average")
  (sum(r[seq_len(n)]) - n * (n + 1) / 2) / (n * k)
}

boyce <- function(p, b) {
  if (!requireNamespace("ecospat", quietly = TRUE)) {
    return(NA_real_)
  }
  z <- tryCatch(
    suppressWarnings(
      ecospat::ecospat.boyce(
        fit = as.numeric(b),
        obs = as.numeric(p),
        nclass = 0,
        PEplot = FALSE,
        method = "spearman",
        rm.duplicate = TRUE
      )
    ),
    error = function(e) NULL
  )
  if (is.null(z)) return(NA_real_)
  valor <- if (!is.null(z$cor)) z$cor else z$Spearman.cor
  if (length(valor) != 1L ||
      !is.finite(valor)) return(NA_real_)
  as.numeric(valor)
}

# ============================================================
# ETAPA 1 - CLAMPING NOS 36 MODELOS
# ============================================================

cat("\nETAPA 1 - Conferindo 36 modelos e clamping...\n")

impacto <- list()
propriedades <- list()
ni <- 0L
np <- 0L

for (i in seq_len(nrow(m2))) {
  z <- m2[i, , drop = FALSE]
  sp <- z$especie
  f <- as.integer(z$fold_cv)
  variaveis <- strsplit(
    z$preditores, ";", fixed = TRUE
  )[[1]]
  
  if (z$conjunto == "COMPLETO_6") {
    id_antigo <- paste0(
      "M1_",
      ifelse(sp == "Ipe-roxo", "ROXO", "AMARELO"),
      "_F", f, "_LQH_RM4"
    )
    arquivo_modelo <- file.path(
      pasta_m1, "08_MODELOS_RDS",
      paste0(id_antigo, ".rds")
    )
    arquivo_prev <- file.path(
      pasta_m1, "08_PREVISOES_VALIDACAO",
      paste0(id_antigo, ".csv")
    )
  } else {
    arquivo_modelo <- file.path(
      pasta_m2, "10_MODELOS_RDS",
      paste0(z$id, ".rds")
    )
    arquivo_prev <- file.path(
      pasta_m2, "10_PREVISOES_VALIDACAO",
      paste0(z$id, ".csv")
    )
  }
  
  if (!file.exists(arquivo_modelo) ||
      !file.exists(arquivo_prev)) {
    stop("Modelo ou previsoes ausentes: ", z$id)
  }
  
  modelo <- readRDS(arquivo_modelo)
  if (!inherits(modelo, "maxnet")) {
    stop("Arquivo RDS invalido: ", z$id)
  }
  
  pp <- ler(arquivo_prev)
  
  vp <- pres[
    pres$especie == sp & pres$fold_cv == f, ,
    drop = FALSE
  ]
  vb <- bg[bg$fold_cv == f, , drop = FALSE]
  
  if (nrow(pp) != nrow(vp) + nrow(vb)) {
    stop("Contagem de previsoes incorreta: ", z$id)
  }
  
  pos_p <- which(pp$tipo == "PRESENCA_VALIDACAO")
  pos_b <- which(pp$tipo == "BACKGROUND_VALIDACAO")
  
  if (length(pos_p) != nrow(vp) ||
      length(pos_b) != nrow(vb) ||
      !identical(
        as.character(pp$propriedade[pos_p]),
        as.character(vp$propriedade)
      ) ||
      !identical(
        as.character(pp$propriedade[pos_b]),
        as.character(vb$propriedade)
      )) {
    stop("Ordem das previsoes divergente: ", z$id)
  }
  
  dados <- rbind(
    vp[, vars, drop = FALSE],
    vb[, vars, drop = FALSE]
  )
  
  x <- montar_x(dados, variaveis)
  
  com <- as.numeric(predict(
    modelo, x, type = "cloglog", clamp = TRUE
  ))
  
  sem <- as.numeric(predict(
    modelo, x, type = "cloglog", clamp = FALSE
  ))
  
  if (any(!is.finite(c(com, sem))) ||
      any(c(com, sem) < 0 | c(com, sem) > 1)) {
    stop("Previsao invalida: ", z$id)
  }
  
  pcom <- com[seq_len(nrow(vp))]
  bcom <- com[nrow(vp) + seq_len(nrow(vb))]
  psem <- sem[seq_len(nrow(vp))]
  bsem <- sem[nrow(vp) + seq_len(nrow(vb))]
  
  if (max(abs(pcom - pp$score_cloglog[pos_p])) > 1e-8 ||
      max(abs(bcom - pp$score_cloglog[pos_b])) > 1e-8 ||
      abs(auc(pcom, bcom) - z$auc_validacao) > 1e-8) {
    stop("Previsoes originais nao reproduzidas: ", z$id)
  }
  
  limiar <- z$limiar10_treino_cloglog
  om_com <- mean(pcom < limiar)
  
  if (abs(om_com - z$omissao10_validacao) > 1e-8) {
    stop("Omissao original nao reproduzida: ", z$id)
  }
  
  ni <- ni + 1L
  impacto[[ni]] <- data.frame(
    id = z$id,
    especie = sp,
    fold_cv = f,
    conjunto = z$conjunto,
    auc_clamp = auc(pcom, bcom),
    auc_sem_clamp = auc(psem, bsem),
    delta_auc = auc(psem, bsem) - auc(pcom, bcom),
    omissao_clamp = om_com,
    omissao_sem_clamp = mean(psem < limiar),
    delta_omissao = mean(psem < limiar) - om_com,
    boyce_original = z$boyce_validacao,
    boyce_sem_clamp = boyce(psem, bsem),
    limiar_treino = limiar,
    fracao_presencas_alteradas = mean(
      abs(pcom - psem) > 1e-8
    ),
    fracao_background_alterado = mean(
      abs(bcom - bsem) > 1e-8
    ),
    mediana_presencas_com_clamp = median(pcom),
    mediana_presencas_sem_clamp = median(psem),
    mediana_background_com_clamp = median(bcom),
    mediana_background_sem_clamp = median(bsem)
  )
  
  for (pr in unique(c(vp$propriedade, vb$propriedade))) {
    a <- which(vp$propriedade == pr)
    b <- which(vb$propriedade == pr)
    if (length(a) < 10L || length(b) < 10L) next
    
    np <- np + 1L
    propriedades[[np]] <- data.frame(
      id = z$id,
      especie = sp,
      fold_cv = f,
      conjunto = z$conjunto,
      propriedade = pr,
      n_presencas = length(a),
      n_background = length(b),
      auc_clamp = auc(pcom[a], bcom[b]),
      auc_sem_clamp = auc(psem[a], bsem[b]),
      omissao_clamp = mean(pcom[a] < limiar),
      omissao_sem_clamp = mean(psem[a] < limiar)
    )
  }
  
  cat(sprintf(
    "[%02d/36] %s | AUC %.3f -> %.3f\n",
    i, z$id, auc(pcom, bcom), auc(psem, bsem)
  ))
}

impacto <- do.call(rbind, impacto)
propriedades <- do.call(rbind, propriedades)

# ============================================================
# ETAPA 2 - NOVIDADE AMBIENTAL MULTIVARIADA
# ============================================================

cat("\nETAPA 2 - Diagnostico ambiental...\n")

novidade <- list()
por_variavel <- list()
nov_prop <- list()

nn <- 0L
nv <- 0L
npr <- 0L

for (f in 1:3) {
  treino <- bg[bg$fold_cv != f, , drop = FALSE]
  valid_bg <- bg[bg$fold_cv == f, , drop = FALSE]
  
  X <- as.matrix(treino[, cont])
  centro <- colMeans(X)
  escala <- apply(X, 2, sd)
  escala[!is.finite(escala) | escala < 1e-12] <- 1
  
  Z <- sweep(sweep(X, 2, centro, "-"),
             2, escala, "/")
  
  # Covariancia com regularizacao para reduzir instabilidade.
  S <- 0.95 * stats::cov(Z) +
    0.05 * diag(length(cont))
  
  distancia <- function(d) {
    xx <- as.matrix(d[, cont, drop = FALSE])
    zz <- sweep(sweep(xx, 2, centro, "-"),
                2, escala, "/")
    sqrt(pmax(0, stats::mahalanobis(
      zz, center = rep(0, length(cont)), cov = S
    )))
  }
  
  limite95 <- as.numeric(
    quantile(distancia(treino), 0.95)
  )
  
  minimos <- apply(X, 2, min)
  maximos <- apply(X, 2, max)
  
  for (sp in c("Ipe-roxo", "Ipe-amarelo")) {
    vp <- pres[
      pres$especie == sp & pres$fold_cv == f, ,
      drop = FALSE
    ]
    
    dp <- distancia(vp)
    db <- distancia(valid_bg)
    
    fora <- vapply(
      cont,
      function(v) {
        vp[[v]] < minimos[v] |
          vp[[v]] > maximos[v]
      },
      logical(nrow(vp))
    )
    
    fora_bg <- vapply(
      cont,
      function(v) {
        valid_bg[[v]] < minimos[v] |
          valid_bg[[v]] > maximos[v]
      },
      logical(nrow(valid_bg))
    )
    
    nn <- nn + 1L
    novidade[[nn]] <- data.frame(
      especie = sp,
      fold_cv = f,
      n_presencas = nrow(vp),
      n_background = nrow(valid_bg),
      fracao_presencas_fora_algum_intervalo =
        mean(rowSums(fora) > 0),
      fracao_bg_fora_algum_intervalo =
        mean(rowSums(fora_bg) > 0),
      distancia95_background_treino = limite95,
      distancia_mediana_presencas = median(dp),
      distancia_mediana_background = median(db),
      fracao_presencas_acima_p95 =
        mean(dp > limite95),
      fracao_bg_acima_p95 =
        mean(db > limite95)
    )
    
    for (v in cont) {
      nv <- nv + 1L
      por_variavel[[nv]] <- data.frame(
        especie = sp,
        fold_cv = f,
        variavel = v,
        min_bg_treino = minimos[v],
        max_bg_treino = maximos[v],
        n_presencas_fora = sum(fora[, v]),
        percentual_presencas_fora =
          100 * mean(fora[, v]),
        n_background_fora = sum(fora_bg[, v]),
        percentual_background_fora =
          100 * mean(fora_bg[, v])
      )
    }
    
    for (pr in unique(vp$propriedade)) {
      ip <- which(vp$propriedade == pr)
      
      npr <- npr + 1L
      nov_prop[[npr]] <- data.frame(
        especie = sp,
        fold_cv = f,
        propriedade = pr,
        n_presencas = length(ip),
        fracao_fora_intervalos =
          mean(rowSums(fora[ip, , drop = FALSE]) > 0),
        distancia_mediana = median(dp[ip]),
        fracao_acima_p95 = mean(dp[ip] > limite95)
      )
    }
  }
}

novidade <- do.call(rbind, novidade)
por_variavel <- do.call(rbind, por_variavel)
nov_prop <- do.call(rbind, nov_prop)

# ============================================================
# ETAPA 3 - CONFERENCIA ESPACIAL DAS PROPRIEDADES
# ============================================================

cat("\nETAPA 3 - Conferindo os folds espaciais...\n")

props <- props[order(props$fold_cv, props$propriedade), ]

# Distancia entre centroides somente se o background
# possuir longitude/latitude em graus.
nomes <- tolower(names(bg))
ix_lon <- which(nomes %in% c("longitude", "lon", "long"))
ix_lat <- which(nomes %in% c("latitude", "lat"))

distancias <- NULL
status_espacial <- paste(
  "Distancias entre limites de UPAs NAO avaliadas.",
  "Essa avaliacao requer as geometrias dos poligonos.",
  "A particao por propriedade foi conferida."
)

if (length(ix_lon) == 1L && length(ix_lat) == 1L) {
  lon <- as.numeric(bg[[ix_lon]])
  lat <- as.numeric(bg[[ix_lat]])
  
  if (all(is.finite(c(lon, lat))) &&
      all(abs(lon) <= 180) &&
      all(abs(lat) <= 90)) {
    
    centros <- aggregate(
      data.frame(lon = lon, lat = lat),
      by = list(
        propriedade = bg$propriedade,
        fold_cv = bg$fold_cv
      ),
      FUN = mean
    )
    
    haversine <- function(lo1, la1, lo2, la2) {
      r <- pi / 180
      a <- sin((la2 - la1) * r / 2)^2 +
        cos(la1 * r) * cos(la2 * r) *
        sin((lo2 - lo1) * r / 2)^2
      2 * 6371.0088 * asin(pmin(1, sqrt(a)))
    }
    
    pares <- list()
    k <- 0L
    
    for (i in seq_len(nrow(centros) - 1L)) {
      for (j in seq.int(i + 1L, nrow(centros))) {
        if (centros$fold_cv[i] == centros$fold_cv[j]) {
          next
        }
        
        k <- k + 1L
        pares[[k]] <- data.frame(
          propriedade_1 = centros$propriedade[i],
          propriedade_2 = centros$propriedade[j],
          fold_1 = centros$fold_cv[i],
          fold_2 = centros$fold_cv[j],
          distancia_centroides_km = haversine(
            centros$lon[i], centros$lat[i],
            centros$lon[j], centros$lat[j]
          )
        )
      }
    }
    
    distancias <- do.call(rbind, pares)
    status_espacial <- paste(
      "Distancias calculadas ENTRE CENTROIDES aproximados",
      "das propriedades, usando pontos de background.",
      "NAO representam distancias minimas entre UPAs.",
      "NAO comprovam independencia espacial."
    )
  }
}

# ============================================================
# ETAPA 4 - SALVAR TABELAS E GRAFICOS
# ============================================================

if (dir.exists(saida)) {
  stop(paste(
    "A pasta de resultados R11 ja existe.",
    "Preserve essa pasta antes de repetir a execucao."
  ))
}

dir.create(saida, recursive = TRUE)
graficos <- file.path(saida, "11_GRAFICOS")
dir.create(graficos)

salvar <- function(x, nome) {
  write.csv(
    x, file.path(saida, nome),
    row.names = FALSE, fileEncoding = "UTF-8"
  )
}

salvar(impacto, "11_IMPACTO_CLAMPING_36_MODELOS.csv")
salvar(propriedades,
       "11_CLAMPING_POR_PROPRIEDADE.csv")
salvar(novidade,
       "11_NOVIDADE_AMBIENTAL_MULTIVARIADA.csv")
salvar(por_variavel,
       "11_NOVIDADE_POR_VARIAVEL.csv")
salvar(nov_prop,
       "11_NOVIDADE_POR_PROPRIEDADE.csv")
salvar(props,
       "11_PARTICAO_PROPRIEDADES_FOLDS.csv")

if (!is.null(distancias)) {
  salvar(distancias,
         "11_DISTANCIA_ENTRE_CENTROIDES.csv")
}

# Comparacao dos modelos nos folds problematicos.
rotulos <- c(
  "Completo", "-BIO12", "-BIO17",
  "-BIO12/17", "-Altitude", "-Solo"
)
ordem <- c(
  "COMPLETO_6", "SEM_BIO12", "SEM_BIO17",
  "SEM_BIO12_BIO17", "SEM_ALTITUDE", "SEM_SOLO"
)

for (sp in c("Ipe-roxo", "Ipe-amarelo")) {
  f <- if (sp == "Ipe-roxo") 3L else 2L
  apelido <- if (sp == "Ipe-roxo") "ROXO" else "AMARELO"
  
  d <- impacto[
    impacto$especie == sp & impacto$fold_cv == f, ,
    drop = FALSE
  ]
  d <- d[match(ordem, d$conjunto), ]
  
  for (indicador in c("auc", "omissao")) {
    a <- d[[paste0(indicador, "_clamp")]]
    b <- d[[paste0(indicador, "_sem_clamp")]]
    
    png(file.path(
      graficos,
      paste0("11_", apelido, "_F", f,
             "_", toupper(indicador), "_CLAMPING.png")
    ), width = 1200, height = 760, res = 135)
    
    op <- par(mar = c(9, 5, 4, 2))
    
    barplot(
      rbind(a, b), beside = TRUE,
      col = c("gray30", "gray75"),
      names.arg = rotulos,
      las = 2, ylim = c(0, 1),
      ylab = indicador,
      main = paste(
        "MaxEnt -", sp, "- Fold", f,
        "-", indicador
      )
    )
    
    legend(
      "topright",
      legend = c("Com clamping", "Sem clamping"),
      fill = c("gray30", "gray75"),
      bty = "n"
    )
    par(op)
    dev.off()
  }
  
  z <- novidade[novidade$especie == sp, ]
  z <- z[order(z$fold_cv), ]
  
  png(file.path(
    graficos,
    paste0("11_", apelido,
           "_NOVIDADE_MULTIVARIADA.png")
  ), width = 1150, height = 700, res = 135)
  
  barplot(
    rbind(
      z$fracao_presencas_acima_p95,
      z$fracao_bg_acima_p95
    ),
    beside = TRUE,
    names.arg = paste("Fold", z$fold_cv),
    col = c("gray30", "gray75"),
    ylim = c(0, 1),
    ylab = "Fracao acima do percentil 95",
    main = paste(
      sp, "- Distancia ambiental atipica"
    )
  )
  
  legend(
    "topright",
    legend = c("Presencas", "Background"),
    fill = c("gray30", "gray75"),
    bty = "n"
  )
  dev.off()
}

writeLines(
  c(
    "TCC IPES - R11 V3",
    "Diagnostico ambiental e espacial exploratorio.",
    "",
    "Modelos reajustados: ZERO.",
    "Modelos examinados: 36.",
    "Referencia: R08 e R10.",
    "Teste externo: NAO utilizado.",
    "",
    "Clamping: previsoes com TRUE e FALSE no mesmo modelo.",
    "Omissao sem clamping usa o mesmo limiar de treino.",
    "Boyce sem clamping e diagnostico complementar.",
    "",
    "Novidade univariada: valores fora do minimo/maximo",
    "do background de treinamento.",
    "",
    "Distancia multivariada: Mahalanobis regularizada",
    "com base no background de treinamento.",
    "Percentil 95 e um limiar exploratorio de atipicidade.",
    "NAO equivale a MOP ou ExDet.",
    "Nao identifica causalidade nem define modelo final.",
    "",
    status_espacial,
    "",
    "A independencia espacial nao foi demonstrada.",
    "Necessario avaliar geometrias, autocorrelacao",
    "e variogramas em etapa especifica.",
    "",
    "Nao apagar os resultados anteriores.",
    paste("Data:", as.character(Sys.time())),
    paste("R:", R.version.string),
    paste(
      "maxnet:",
      as.character(packageVersion("maxnet"))
    )
  ),
  file.path(saida, "11_LEIA_RESULTADOS.txt")
)

writeLines(
  capture.output(sessionInfo()),
  file.path(saida, "11_SESSION_INFO.txt")
)

cat("\n=======================================\n")
cat("R11 FINALIZADO!\n")
cat("36 modelos diagnosticados, zero reajustes.\n")
cat("Resultados salvos em:\n")
cat(saida, "\n")
cat("=======================================\n")
