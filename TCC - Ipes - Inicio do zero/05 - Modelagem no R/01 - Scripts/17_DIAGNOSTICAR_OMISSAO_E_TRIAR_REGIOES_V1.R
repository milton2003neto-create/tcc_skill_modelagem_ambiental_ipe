
# ============================================================
# TCC IPES - R17 V1
# DIAGNOSTICO DE OMISSAO E TRIAGEM REGIONAL
#
# Reutiliza os 72 modelos R16, sem novos ajustes.
# Analisa limiares 1%, 5% e 10%.
# Identifica novidade ambiental por especie e fold.
# Investiga grupos de propriedades proximas.
# Nao utiliza teste externo.
# ============================================================

if (!requireNamespace("maxnet", quietly = TRUE)) {
  stop("Instale o pacote maxnet.")
}

ler <- function(f) {
  read.csv(f, fileEncoding = "UTF-8-BOM",
           stringsAsFactors = FALSE,
           check.names = FALSE)
}

salvar <- function(x, f) {
  write.csv(x, f, row.names = FALSE,
            fileEncoding = "UTF-8")
}

raiz_do_tcc <- function(f) {
  p <- dirname(f)
  repeat {
    if (
      dir.exists(file.path(p, "04 - Dados para o MaxEnt")) &&
      dir.exists(file.path(p, "06 - Resultados"))
    ) return(p)
    
    acima <- dirname(p)
    if (acima == p) stop("Raiz do TCC nao localizada.")
    p <- acima
  }
}

cat("\nR17 - Selecione 16_METRICAS_72_MODELOS_B1.csv\n")

arq <- normalizePath(file.choose(),
                     winslash = "/", mustWork = TRUE)

if (basename(arq) != "16_METRICAS_72_MODELOS_B1.csv") {
  stop("Arquivo R16 incorreto.")
}

raiz <- raiz_do_tcc(arq)
pasta_r16 <- dirname(arq)

pasta_r05 <- file.path(
  raiz, "04 - Dados para o MaxEnt",
  "04 - Presencas e folds V3"
)

arq_pres <- file.path(
  pasta_r05, "05_PRESENCAS_UM_POR_PIXEL_30M.csv"
)
arq_bg0 <- file.path(
  pasta_r05, "05_BACKGROUND_COM_FOLDS.csv"
)

manifesto <- ler(file.path(
  pasta_r16, "16_MANIFESTO_ENTRADAS.csv"
))

candidatos <- list.files(
  file.path(raiz, "06 - Resultados"),
  pattern = "^15_BACKGROUND_B1_10000_COM_FOLDS\\.csv$",
  recursive = TRUE,
  full.names = TRUE
)

ref <- manifesto[
  manifesto$arquivo ==
    "15_BACKGROUND_B1_10000_COM_FOLDS.csv",
  , drop = FALSE
]

if (nrow(ref) != 1L || !length(candidatos)) {
  stop("Background B1 nao localizado no manifesto.")
}

hashes <- unname(as.character(
  tools::md5sum(candidatos)
))

validos <- candidatos[
  tolower(hashes) == tolower(ref$md5)
]

if (!length(validos)) {
  stop("B1 original do R16 nao encontrada por MD5.")
}

arq_bg1 <- validos[1]

for (f in c(arq_pres, arq_bg0, arq_bg1)) {
  z <- manifesto[
    manifesto$arquivo == basename(f),
    , drop = FALSE
  ]
  
  if (
    nrow(z) != 1L ||
    tolower(as.character(
      unname(tools::md5sum(f))
    )) != tolower(as.character(z$md5))
  ) stop("Fonte modificada: ", basename(f))
}

pres <- ler(arq_pres)
bg0 <- ler(arq_bg0)
bg1 <- ler(arq_bg1)
met <- ler(arq)

if (
  nrow(met) != 72L ||
  nrow(pres) != 8680L ||
  nrow(bg0) != 5000L ||
  nrow(bg1) != 10000L
) stop("Contagens das entradas incorretas.")

vars <- c(
  "altitude_m", "declividade_graus",
  "dist_rio_raster_m", "bio12_mm_ano",
  "bio17_mm_mes", "textura_subgrupo"
)

cont <- vars[1:5]

for (nm in c(vars, "fold_cv")) {
  pres[[nm]] <- as.numeric(pres[[nm]])
  bg0[[nm]] <- as.numeric(bg0[[nm]])
  bg1[[nm]] <- as.numeric(bg1[[nm]])
}

for (d in list(pres, bg0, bg1)) {
  if (anyNA(d[, vars, drop = FALSE]) ||
      any(!is.finite(as.matrix(
        d[, vars, drop = FALSE]
      )))) stop("Preditores invalidos.")
}

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
)

normalizar <- function(x) {
  z <- iconv(as.character(x),
             to = "ASCII//TRANSLIT", sub = "")
  trimws(gsub("[^A-Z0-9]+", " ",
              toupper(z)))
}

if (any(
  normalizar(c(
    pres$propriedade,
    bg0$propriedade,
    bg1$propriedade
  )) %in% normalizar(externas)
)) stop("Teste externo encontrado.")

saida <- file.path(
  raiz, "06 - Resultados",
  "15 - Diagnostico da omissao R17 V1",
  paste0("Execucao_",
         format(Sys.time(), "%Y%m%d_%H%M%S"))
)

dir.create(saida, recursive = TRUE,
           showWarnings = FALSE)

dir.create(file.path(saida, "17_GRAFICOS"))

solo <- sort(unique(c(
  pres$textura_subgrupo,
  bg1$textura_subgrupo
)))

montar_x <- function(d) {
  x <- d[, vars, drop = FALSE]
  x$textura_subgrupo <- factor(
    as.character(x$textura_subgrupo),
    levels = as.character(solo)
  )
  x
}

# ============================================================
# ETAPA 1 - ANALISAR LIMIARES DOS 72 MODELOS
# ============================================================

cat("\nETAPA 1 - Diagnostico dos limiares...\n")

resultados <- list()
por_propriedade <- list()

for (i in seq_len(nrow(met))) {
  z <- met[i, ]
  
  arq_modelo <- file.path(
    pasta_r16, "16_MODELOS_RDS",
    paste0(z$id, ".rds")
  )
  
  arq_prev <- file.path(
    pasta_r16, "16_PREVISOES_VALIDACAO",
    paste0(z$id, ".csv")
  )
  
  if (!file.exists(arq_modelo) ||
      !file.exists(arq_prev)) {
    stop("Modelo ou previsoes ausentes: ", z$id)
  }
  
  mod <- readRDS(arq_modelo)
  pp <- ler(arq_prev)
  
  sp <- z$especie
  f <- as.integer(z$fold_cv)
  
  treino <- pres[
    pres$especie == sp &
      pres$fold_cv != f,
    , drop = FALSE
  ]
  
  validacao <- pres[
    pres$especie == sp &
      pres$fold_cv == f,
    , drop = FALSE
  ]
  
  score_treino <- as.numeric(stats::predict(
    mod,
    montar_x(treino),
    type = "cloglog",
    clamp = TRUE
  ))
  
  is_pres <- pp$tipo == "PRESENCA_VALIDACAO"
  is_bg <- pp$tipo == "BACKGROUND_VALIDACAO"
  
  score_valid <- as.numeric(
    pp$score_cloglog[is_pres]
  )
  
  score_bg <- as.numeric(
    pp$score_cloglog[is_bg]
  )
  
  if (
    length(score_treino) != nrow(treino) ||
    length(score_valid) != nrow(validacao) ||
    length(score_bg) != sum(bg1$fold_cv == f) ||
    any(!is.finite(c(
      score_treino, score_valid, score_bg
    )))
  ) stop("Previsoes invalidas: ", z$id)
  
  if (!identical(
    as.character(pp$propriedade[is_pres]),
    as.character(validacao$propriedade)
  )) stop("Ordem das presencas divergente.")
  
  for (pct in c(1, 5, 10)) {
    limiar <- as.numeric(stats::quantile(
      score_treino, probs = pct / 100,
      type = 7
    ))
    
    omissao <- mean(score_valid < limiar)
    
    if (
      pct == 10 &&
      (
        abs(limiar -
            z$limiar10_treino_cloglog) > 1e-7 ||
        abs(omissao -
            z$omissao10_validacao) > 1e-8
      )
    ) stop("Limiar 10% difere do R16: ", z$id)
    
    resultados[[length(resultados) + 1L]] <-
      data.frame(
        id = z$id,
        especie = sp,
        fold_cv = f,
        features = z$features,
        RM = z$RM,
        limiar_percentual = pct,
        limiar_cloglog = limiar,
        omissao_validacao = omissao,
        fracao_bg_classificado_adequado =
          mean(score_bg >= limiar),
        menor_score_treino = min(score_treino),
        maior_score_validacao = max(score_valid),
        mediana_score_validacao =
          median(score_valid),
        auc_r16_bg_fixo =
          z$auc_validacao_bg_b0_fixo,
        stringsAsFactors = FALSE
      )
    
    parcial <- data.frame(
      propriedade = validacao$propriedade,
      omitida = as.integer(score_valid < limiar)
    )
    
    tab <- aggregate(
      omitida ~ propriedade,
      parcial, mean
    )
    
    ns <- table(parcial$propriedade)
    
    por_propriedade[[
      length(por_propriedade) + 1L
    ]] <- data.frame(
      id = z$id,
      especie = sp,
      fold_cv = f,
      features = z$features,
      RM = z$RM,
      limiar_percentual = pct,
      propriedade = tab$propriedade,
      n_presencas = as.integer(
        ns[tab$propriedade]
      ),
      omissao = tab$omitida
    )
  }
  
  cat(sprintf(
    "[%02d/72] %s - OK\n", i, z$id
  ))
}

limiares <- do.call(rbind, resultados)

salvar(
  limiares,
  file.path(saida, "17_TESTE_LIMIARES_72_MODELOS.csv")
)

salvar(
  do.call(rbind, por_propriedade),
  file.path(saida, "17_OMISSAO_POR_PROPRIEDADE.csv")
)

resumo_limiares <- aggregate(
  cbind(
    omissao_validacao,
    fracao_bg_classificado_adequado
  ) ~ especie + fold_cv + limiar_percentual,
  limiares,
  FUN = mean
)

salvar(
  resumo_limiares,
  file.path(saida, "17_RESUMO_LIMIARES_POR_FOLD.csv")
)

# ============================================================
# ETAPA 2 - NOVIDADE AMBIENTAL
# ============================================================

cat("\nETAPA 2 - Novidade ambiental...\n")

ambiente <- list()
ambiente_prop <- list()

for (sp in unique(pres$especie)) {
  for (f in 1:3) {
    
    treino_bg <- bg1[
      bg1$fold_cv != f,
      , drop = FALSE
    ]
    
    val <- pres[
      pres$especie == sp &
        pres$fold_cv == f,
      , drop = FALSE
    ]
    
    if (!nrow(val) || !nrow(treino_bg)) {
      stop("Fold ambiental vazio.")
    }
    
    for (v in cont) {
      
      a <- treino_bg[[v]]
      b <- val[[v]]
      
      q <- as.numeric(stats::quantile(
        a, c(0.01, 0.99)
      ))
      
      ambiente[[length(ambiente) + 1L]] <-
        data.frame(
          especie = sp,
          fold_cv = f,
          variavel = v,
          n_validacao = length(b),
          minimo_treino_bg = min(a),
          maximo_treino_bg = max(a),
          mediana_treino_bg = median(a),
          mediana_validacao = median(b),
          fracao_fora_amplitude =
            mean(b < min(a) | b > max(a)),
          fracao_fora_p01_p99 =
            mean(b < q[1] | b > q[2]),
          stringsAsFactors = FALSE
        )
    }
    
    bio12 <- range(treino_bg$bio12_mm_ano)
    bio17 <- range(treino_bg$bio17_mm_mes)
    
    for (pr in unique(val$propriedade)) {
      x <- val[
        val$propriedade == pr,
        , drop = FALSE
      ]
      
      fora12 <- (
        x$bio12_mm_ano < bio12[1] |
          x$bio12_mm_ano > bio12[2]
      )
      
      fora17 <- (
        x$bio17_mm_mes < bio17[1] |
          x$bio17_mm_mes > bio17[2]
      )
      
      ambiente_prop[[
        length(ambiente_prop) + 1L
      ]] <- data.frame(
        especie = sp,
        fold_cv = f,
        propriedade = pr,
        n_presencas = nrow(x),
        fracao_fora_bio12 = mean(fora12),
        fracao_fora_bio17 = mean(fora17),
        fracao_fora_algum_bio =
          mean(fora12 | fora17)
      )
    }
  }
}

salvar(
  do.call(rbind, ambiente),
  file.path(saida, "17_NOVIDADE_AMBIENTAL_VARIAVEIS.csv")
)

salvar(
  do.call(rbind, ambiente_prop),
  file.path(saida, "17_NOVIDADE_CLIMATICA_PROPRIEDADES.csv")
)

# ============================================================
# ETAPA 3 - TRIAGEM GEOGRAFICA DE PROPRIEDADES
# ============================================================

cat("\nETAPA 3 - Triagem de grupos regionais...\n")

# Coordenadas medias do background B0 por propriedade.
# Aproximam a posicao das UPAs inventariadas,
# NAO o centroide dos limites inteiros das fazendas.

centros <- aggregate(
  cbind(longitude, latitude) ~ propriedade,
  bg0,
  FUN = mean
)

props <- centros$propriedade
n <- nrow(centros)

haversine <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  
  dlat <- (lat2 - lat1) * rad
  dlon <- (lon2 - lon1) * rad
  
  a <- sin(dlat / 2)^2 +
    cos(lat1 * rad) *
    cos(lat2 * rad) *
    sin(dlon / 2)^2
  
  6371 * 2 * atan2(
    sqrt(a), sqrt(pmax(0, 1 - a))
  )
}

distancias <- matrix(
  0, nrow = n, ncol = n,
  dimnames = list(props, props)
)

for (i in seq_len(n)) {
  for (j in seq_len(n)) {
    distancias[i, j] <- haversine(
      centros$longitude[i],
      centros$latitude[i],
      centros$longitude[j],
      centros$latitude[j]
    )
  }
}

arvore <- hclust(
  as.dist(distancias),
  method = "complete"
)

grupos_saida <- list()

for (raio in c(25, 50, 100, 150, 250)) {
  cls <- cutree(arvore, h = raio)
  
  for (grupo in sort(unique(cls))) {
    membros <- props[cls == grupo]
    
    p <- pres[
      pres$propriedade %in% membros,
      , drop = FALSE
    ]
    
    nroxo <- sum(p$especie == "Ipe-roxo")
    namarelo <- sum(p$especie == "Ipe-amarelo")
    
    nupas <- length(unique(paste(
      p$propriedade, p$upa_id, sep = "||"
    )))
    
    d <- distancias[membros, membros,
                    drop = FALSE]
    
    grupos_saida[[
      length(grupos_saida) + 1L
    ]] <- data.frame(
      distancia_limite_km = raio,
      grupo = grupo,
      n_propriedades = length(membros),
      n_upas = nupas,
      n_ipe_roxo = nroxo,
      n_ipe_amarelo = namarelo,
      menor_n_especie = min(nroxo, namarelo),
      maior_distancia_centros_km = max(d),
      triagem_inicial = (
        length(membros) >= 3 &&
          nupas >= 4 &&
          nroxo >= 200 &&
          namarelo >= 200
      ),
      propriedades = paste(
        membros, collapse = " | "
      ),
      stringsAsFactors = FALSE
    )
  }
}

grupos <- do.call(rbind, grupos_saida)

grupos <- grupos[order(
  !grupos$triagem_inicial,
  -grupos$menor_n_especie,
  grupos$maior_distancia_centros_km
), ]

salvar(
  centros,
  file.path(saida, "17_CENTROS_APROXIMADOS_UPAS.csv")
)

salvar(
  grupos,
  file.path(saida, "17_GRUPOS_REGIONAIS_CANDIDATOS.csv")
)

# ============================================================
# ETAPA 4 - GRAFICOS E RELATORIO
# ============================================================

for (sp in unique(resumo_limiares$especie)) {
  z <- resumo_limiares[
    resumo_limiares$especie == sp,
    , drop = FALSE
  ]
  
  nome <- ifelse(
    sp == "Ipe-roxo",
    "ROXO", "AMARELO"
  )
  
  png(
    file.path(
      saida, "17_GRAFICOS",
      paste0("17_", nome, "_LIMIARES.png")
    ),
    width = 1150,
    height = 760,
    res = 140
  )
  
  plot(
    NA, NA,
    xlim = c(1, 10),
    ylim = c(0, 1),
    xlab = "Limiar percentual das presencas de treino",
    ylab = "Omissao media na validacao",
    main = paste(sp, "- Sensibilidade ao limiar")
  )
  
  for (f in 1:3) {
    x <- z[z$fold_cv == f, ]
    x <- x[order(x$limiar_percentual), ]
    
    lines(
      x$limiar_percentual,
      x$omissao_validacao,
      type = "b", lwd = 2,
      pch = 14 + f,
      lty = f
    )
  }
  
  legend(
    "bottomright",
    legend = paste("Fold", 1:3),
    lty = 1:3,
    pch = 15:17,
    bty = "n"
  )
  
  dev.off()
}

writeLines(
  c(
    "R17 - DIAGNOSTICO EXPLORATORIO",
    "",
    "Nenhum novo MaxEnt foi ajustado.",
    "Os limiares foram definidos nas presencas de treino.",
    "Reducao de omissao nao equivale a melhor AUC.",
    "O custo e a fracao de background adequado.",
    "",
    "A novidade ambiental compara validacao com",
    "o background de treinamento em cada fold.",
    "A analise usa amplitudes univariadas;",
    "nao substitui MESS ou ExDet multivariado.",
    "",
    "Os agrupamentos regionais usam distancias",
    "aproximadas entre centros das areas inventariadas.",
    "Nao equivalem a distancias entre os poligonos.",
    "Nenhuma regiao foi escolhida automaticamente.",
    "",
    "As sete propriedades externas nao foram utilizadas.",
    "Resultados anteriores preservados."
  ),
  file.path(saida, "17_RELATORIO.txt")
)

cat("\n====================================\n")
cat("R17 CONCLUIDO\n")
cat("====================================\n")
cat("72 modelos existentes diagnosticados.\n")
cat("Limiares: 1%, 5% e 10%.\n")
cat("Novidade ambiental por fold e propriedade.\n")
cat("Grupos regionais para triagem.\n")
cat("\nResultados:\n", saida, "\n")
