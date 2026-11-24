
# ============================================================
# TCC IPES - R14 V3.1
# CONSOLIDACAO DO BACKGROUND B0 - 5.000 PONTOS
#
# R08 / M1: 72 modelos completos
# R10 / M2: 36 avaliacoes (30 ajustes novos)
# R13 / M3: 72 avaliacoes (66 ajustes novos)
#
# TOTAL: 180 avaliacoes / 168 ajustes distintos
#        56 configuracoes avaliadas em 3 folds
#
# CORRECOES V3.1:
# - Padronizacao das tabelas por propriedade
# - Controle de modelos reutilizados
# - Comparacoes pareadas sem duplicacoes
# - Auditoria de metricas e resumos
# - Saida em pasta nova
#
# NAO executa MaxEnt.
# NAO altera os dados ou modelos anteriores.
# NAO utiliza as 7 propriedades de teste externo.
# ============================================================

versao <- "R14_V3_1_CONSOLIDACAO_B0"

cat("\n============================================\n")
cat("TCC IPES - R14 V3.1\n")
cat("CONSOLIDACAO DO BACKGROUND B0\n")
cat("============================================\n")

cat("\nSelecione 13_METRICAS_72_AVALIACOES.csv\n")

arquivo <- normalizePath(
  file.choose(),
  winslash = "/",
  mustWork = TRUE
)

if (basename(arquivo) !=
    "13_METRICAS_72_AVALIACOES.csv") {
  stop("Selecione o CSV final de metricas do R13.")
}

pasta_m3 <- dirname(arquivo)
raiz <- dirname(dirname(dirname(arquivo)))

if (basename(pasta_m3) !=
    "11 - MaxEnt M3 - Grade complementar B0 V3" ||
    !dir.exists(file.path(raiz, "03 - Trabalho no QGIS"))) {
  stop("Estrutura de pastas do TCC nao encontrada.")
}

ler <- function(f) {
  read.csv(
    f,
    fileEncoding = "UTF-8-BOM",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

salvar <- function(d, nome, pasta) {
  write.csv(
    d,
    file.path(pasta, nome),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
}

# ============================================================
# ETAPA 1 - LOCALIZAR E AUDITAR AS ENTRADAS
# ============================================================

cat("\nETAPA 1 - Auditando arquivos...\n")

pasta_resultados <- file.path(raiz, "06 - Resultados")

pasta_m1 <- file.path(
  pasta_resultados,
  "06 - MaxEnt M1 - Grade 72 V3"
)

pasta_m2 <- file.path(
  pasta_resultados,
  "08 - MaxEnt M2 - Variaveis V3"
)

pasta_r05 <- file.path(
  raiz,
  "04 - Dados para o MaxEnt",
  "04 - Presencas e folds V3"
)

arq_m1 <- file.path(
  pasta_m1, "08_METRICAS_72_MODELOS.csv"
)
arq_m2 <- file.path(
  pasta_m2, "10_METRICAS_36_AVALIACOES.csv"
)
arq_m3 <- arquivo

arq_p1 <- file.path(
  pasta_m1, "08_AUC_E_OMISSAO_POR_PROPRIEDADE.csv"
)
arq_p2 <- file.path(
  pasta_m2, "10_AUC_E_OMISSAO_POR_PROPRIEDADE.csv"
)
arq_p3 <- file.path(
  pasta_m3, "13_AUC_OMISSAO_POR_PROPRIEDADE.csv"
)

man1 <- file.path(
  pasta_m1, "08_MANIFESTO_ENTRADAS.csv"
)
man2 <- file.path(
  pasta_m2, "10_MANIFESTO_ENTRADAS.csv"
)
man3 <- file.path(
  pasta_m3, "13_MANIFESTO_ENTRADAS.csv"
)

entradas_r05 <- file.path(
  pasta_r05,
  c(
    "05_PRESENCAS_UM_POR_PIXEL_30M.csv",
    "05_BACKGROUND_COM_FOLDS.csv",
    "05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv",
    "05_RESUMO_FOLDS.csv"
  )
)

obrigatorios <- c(
  entradas_r05,
  arq_m1, arq_m2, arq_m3,
  arq_p1, arq_p2, arq_p3,
  man1, man2, man3
)

if (!all(file.exists(obrigatorios))) {
  faltantes <- obrigatorios[!file.exists(obrigatorios)]
  
  stop(
    "Arquivos obrigatorios ausentes:\n",
    paste(faltantes, collapse = "\n")
  )
}

m1 <- ler(arq_m1)
m2 <- ler(arq_m2)
m3 <- ler(arq_m3)

p1 <- ler(arq_p1)
p2 <- ler(arq_p2)
p3 <- ler(arq_p3)

manifesto1 <- ler(man1)
manifesto3 <- ler(man3)

if (nrow(m1) != 72L ||
    nrow(m2) != 36L ||
    nrow(m3) != 72L) {
  stop("As contagens M1/M2/M3 estao incorretas.")
}

# Verificacao de integridade das fontes do R13.
fontes_conferir <- c(
  entradas_r05, arq_m1, arq_m2, man1, man2
)

for (f in fontes_conferir) {
  z <- manifesto3[
    manifesto3$arquivo == basename(f),
    , drop = FALSE
  ]
  
  hash_atual <- unname(
    as.character(tools::md5sum(f))
  )
  
  if (nrow(z) != 1L ||
      tolower(as.character(z$md5)) !=
      tolower(hash_atual)) {
    stop(
      "Hash diferente do manifesto R13: ",
      basename(f)
    )
  }
}

for (f in entradas_r05) {
  z <- manifesto1[
    manifesto1$arquivo == basename(f),
    , drop = FALSE
  ]
  
  if (nrow(z) != 1L ||
      tolower(as.character(z$md5)) !=
      tolower(unname(
        as.character(tools::md5sum(f))
      ))) {
    stop("Entrada R05 alterada: ", basename(f))
  }
}

cat("Arquivos de origem conferidos.\n")

# ============================================================
# ETAPA 2 - PADRONIZAR M1, M2 E M3
# ============================================================

cat("\nETAPA 2 - Padronizando M1, M2 e M3...\n")

vars <- c(
  "altitude_m",
  "declividade_graus",
  "dist_rio_raster_m",
  "bio12_mm_ano",
  "bio17_mm_mes",
  "textura_subgrupo"
)

# O M1 usou sempre as seis variaveis.
m1$conjunto <- "COMPLETO_6"
m1$preditores <- paste(vars, collapse = ";")
m1$n_preditores <- 6L
m1$origem <- "R08_NOVO"

campos_metricas <- c(
  "id",
  "especie",
  "fold_cv",
  "conjunto",
  "preditores",
  "n_preditores",
  "features",
  "RM",
  "origem",
  "n_presenca_validacao",
  "n_background_validacao",
  "auc_treino",
  "auc_validacao",
  "omissao10_treino",
  "omissao10_validacao",
  "limiar10_treino_cloglog",
  "boyce_validacao",
  "status_boyce_validacao",
  "n_features_ativas"
)

padronizar <- function(d, rodada) {
  faltantes <- setdiff(campos_metricas, names(d))
  
  if (length(faltantes)) {
    stop(
      "Campos ausentes em ", rodada, ": ",
      paste(faltantes, collapse = ", ")
    )
  }
  
  x <- d[, campos_metricas, drop = FALSE]
  x$rodada <- rodada
  
  x
}

a1 <- padronizar(m1, "M1")
a2 <- padronizar(m2, "M2")
a3 <- padronizar(m3, "M3")

# Identificador canonico de cada ajuste.
a1$ajuste_unico <- a1$id
a2$ajuste_unico <- a2$id
a3$ajuste_unico <- a3$id

reuso2 <- a2$origem == "R08_REUTILIZADO"
reuso3 <- a3$origem == "R10_REUTILIZADO"

if (sum(reuso2) != 6L ||
    sum(reuso3) != 6L ||
    sum(a2$origem == "R10_NOVO") != 30L ||
    sum(a3$origem == "R13_NOVO") != 66L) {
  stop("Quantidade de modelos novos/reutilizados incorreta.")
}

if (any(a2$conjunto[reuso2] != "COMPLETO_6") ||
    any(a2$features[reuso2] != "lqh") ||
    any(a2$RM[reuso2] != 4) ||
    any(a3$features[reuso3] != "lqh") ||
    any(a3$RM[reuso3] != 4)) {
  stop("Configuracao dos modelos reutilizados incorreta.")
}

# Referencias M2 aos modelos originais do M1.
a2$ajuste_unico[reuso2] <- paste0(
  "M1_",
  ifelse(
    a2$especie[reuso2] == "Ipe-roxo",
    "ROXO", "AMARELO"
  ),
  "_F", a2$fold_cv[reuso2],
  "_LQH_RM4"
)

# Referencias M3 aos modelos originais do M2.
a3$ajuste_unico[reuso3] <- paste0(
  "M2_",
  ifelse(
    a3$especie[reuso3] == "Ipe-roxo",
    "ROXO", "AMARELO"
  ),
  "_F", a3$fold_cv[reuso3],
  "_", a3$conjunto[reuso3],
  "_LQH_RM4"
)

comparar_reutilizacao <- function(x, y, id) {
  if (nrow(x) != 1L ||
      nrow(y) != 1L ||
      x$especie != y$especie ||
      x$fold_cv != y$fold_cv ||
      x$conjunto != y$conjunto ||
      x$features != y$features ||
      x$RM != y$RM) {
    stop("Referencia incorreta: ", id)
  }
  
  campos <- c(
    "auc_treino",
    "auc_validacao",
    "omissao10_treino",
    "omissao10_validacao",
    "limiar10_treino_cloglog",
    "boyce_validacao",
    "n_features_ativas",
    "n_presenca_validacao",
    "n_background_validacao"
  )
  
  for (campo in campos) {
    iguais <- isTRUE(all.equal(
      as.numeric(x[[campo]]),
      as.numeric(y[[campo]]),
      tolerance = 1e-8
    ))
    
    if (!iguais) {
      stop(
        "Divergencia no modelo ", id,
        ": ", campo
      )
    }
  }
}

for (i in which(reuso2)) {
  y <- a1[
    a1$id == a2$ajuste_unico[i],
    , drop = FALSE
  ]
  
  comparar_reutilizacao(
    a2[i, , drop = FALSE],
    y,
    a2$id[i]
  )
}

for (i in which(reuso3)) {
  y <- a2[
    a2$id == a3$ajuste_unico[i],
    , drop = FALSE
  ]
  
  comparar_reutilizacao(
    a3[i, , drop = FALSE],
    y,
    a3$id[i]
  )
}

avaliacoes <- rbind(a1, a2, a3)
rownames(avaliacoes) <- NULL

if (nrow(avaliacoes) != 180L ||
    anyDuplicated(avaliacoes$id)) {
  stop("As 180 avaliacoes nao estao consistentes.")
}

# Retirar os registros referentes a ajustes ja existentes.
modelos <- avaliacoes[
  !duplicated(avaliacoes$ajuste_unico),
  , drop = FALSE
]

if (nrow(modelos) != 168L ||
    anyDuplicated(modelos$ajuste_unico)) {
  stop("Esperados 168 ajustes distintos.")
}

numericos <- c(
  "auc_treino",
  "auc_validacao",
  "omissao10_treino",
  "omissao10_validacao",
  "boyce_validacao",
  "n_features_ativas"
)

if (any(!is.finite(
  as.matrix(modelos[, numericos, drop = FALSE])
))) {
  stop("Metricas ausentes ou nao finitas.")
}

cat("180 avaliacoes consolidadas.\n")
cat("168 ajustes distintos confirmados.\n")

# ============================================================
# ETAPA 3 - CORRECAO DAS TABELAS POR PROPRIEDADE
# ============================================================

cat("\nETAPA 3 - Auditando resultados por propriedade...\n")

# CORRECAO V3.1:
# R08, R10 e R13 possuem colunas adicionais diferentes.
# Selecionar apenas as colunas comuns antes de usar rbind.

campos_prop <- c(
  "id",
  "especie",
  "fold_cv",
  "propriedade",
  "n_presencas",
  "n_background",
  "auc_propriedade",
  "omissao10_propriedade",
  "status_auc"
)

tabelas_prop <- list(
  R08 = p1,
  R10 = p2,
  R13 = p3
)

for (nome in names(tabelas_prop)) {
  faltantes <- setdiff(
    campos_prop,
    names(tabelas_prop[[nome]])
  )
  
  if (length(faltantes)) {
    stop(
      "Campos ausentes em ", nome, ": ",
      paste(faltantes, collapse = ", ")
    )
  }
}

propriedades <- do.call(
  rbind,
  lapply(
    tabelas_prop,
    function(d) {
      d[, campos_prop, drop = FALSE]
    }
  )
)

rownames(propriedades) <- NULL

externas <- c(
  "BARRO BRANCO", "CURUÇA", "GUARIÚBA",
  "JATOBÁ", "LOTE 01", "MARILIA", "PALMEIRA"
)

if (any(propriedades$propriedade %in% externas)) {
  stop("Propriedade de teste externo encontrada.")
}

if (anyDuplicated(paste(
  propriedades$id,
  propriedades$propriedade,
  sep = "|"
))) {
  stop("Registros repetidos na tabela por propriedade.")
}

# Conferir presencas e omissao de cada avaliacao.
for (i in seq_len(nrow(avaliacoes))) {
  z <- avaliacoes[i, , drop = FALSE]
  
  p <- propriedades[
    propriedades$id == z$id,
    , drop = FALSE
  ]
  
  if (!nrow(p)) {
    stop(
      "Modelo sem dados por propriedade: ",
      z$id
    )
  }
  
  if (sum(p$n_presencas) !=
      z$n_presenca_validacao) {
    stop(
      "Presencas divergentes: ",
      z$id
    )
  }
  
  omissao_ponderada <- sum(
    p$n_presencas * p$omissao10_propriedade
  ) / sum(p$n_presencas)
  
  if (!is.finite(omissao_ponderada) ||
      abs(
        omissao_ponderada -
        z$omissao10_validacao
      ) > 1e-8) {
    stop(
      "Omissao divergente: ",
      z$id
    )
  }
}

propriedades$ajuste_unico <-
  avaliacoes$ajuste_unico[
    match(propriedades$id, avaliacoes$id)
  ]

if (anyNA(propriedades$ajuste_unico)) {
  stop("ID nao reconhecido nas propriedades.")
}

# Eliminar copias da mesma avaliacao por propriedade.
chave_prop <- paste(
  propriedades$ajuste_unico,
  propriedades$propriedade,
  sep = "|"
)

propriedades_unicas <- propriedades[
  !duplicated(chave_prop),
  , drop = FALSE
]

cat(
  "Registros por propriedade padronizados: ",
  nrow(propriedades), "\n",
  sep = ""
)

cat(
  "Registros sem reutilizacoes: ",
  nrow(propriedades_unicas), "\n",
  sep = ""
)

# ============================================================
# ETAPA 4 - COMPARACAO PAREADA COM O R08
# ============================================================

cat("\nETAPA 4 - Comparando com o modelo completo...\n")

# Comparar somente os ajustes alternativos DISTINTOS.
alternativos <- modelos[
  modelos$conjunto != "COMPLETO_6",
  , drop = FALSE
]

if (nrow(alternativos) != 96L) {
  stop("Esperados 96 ajustes alternativos distintos.")
}

comparacoes <- vector(
  "list", nrow(alternativos)
)

for (i in seq_len(nrow(alternativos))) {
  z <- alternativos[i, , drop = FALSE]
  
  ref <- a1[
    a1$especie == z$especie &
      a1$fold_cv == z$fold_cv &
      a1$features == z$features &
      a1$RM == z$RM,
    , drop = FALSE
  ]
  
  if (nrow(ref) != 1L) {
    stop(
      "Modelo completo de referencia ausente: ",
      z$id
    )
  }
  
  comparacoes[[i]] <- data.frame(
    id_alternativo = z$id,
    id_completo = ref$id,
    especie = z$especie,
    conjunto = z$conjunto,
    rodada = z$rodada,
    fold_cv = z$fold_cv,
    features = z$features,
    RM = z$RM,
    auc_alternativo = z$auc_validacao,
    auc_completo = ref$auc_validacao,
    delta_auc =
      z$auc_validacao - ref$auc_validacao,
    boyce_alternativo = z$boyce_validacao,
    boyce_completo = ref$boyce_validacao,
    delta_boyce =
      z$boyce_validacao - ref$boyce_validacao,
    omissao_alternativo =
      z$omissao10_validacao,
    omissao_completo =
      ref$omissao10_validacao,
    delta_omissao =
      z$omissao10_validacao -
      ref$omissao10_validacao,
    complexidade_alternativa =
      z$n_features_ativas,
    complexidade_completa =
      ref$n_features_ativas,
    stringsAsFactors = FALSE
  )
}

comparacoes <- do.call(rbind, comparacoes)

cat("96 comparacoes pareadas distintas conferidas.\n")

# ============================================================
# ETAPA 5 - RESUMO DAS 56 CONFIGURACOES
# ============================================================

cat("\nETAPA 5 - Gerando resumos...\n")

modelos$chave_config <- paste(
  modelos$especie,
  modelos$conjunto,
  modelos$features,
  modelos$RM,
  sep = "|"
)

grupos <- split(
  seq_len(nrow(modelos)),
  modelos$chave_config
)

resumos <- vector("list", length(grupos))
k <- 0L

for (indices in grupos) {
  z <- modelos[indices, , drop = FALSE]
  
  if (nrow(z) != 3L ||
      !setequal(z$fold_cv, 1:3)) {
    stop(
      "Configuracao sem tres folds: ",
      z$chave_config[1]
    )
  }
  
  p <- propriedades_unicas[
    propriedades_unicas$ajuste_unico %in%
      z$ajuste_unico,
    , drop = FALSE
  ]
  
  ap <- p$auc_propriedade[
    is.finite(p$auc_propriedade)
  ]
  
  if (!length(ap)) {
    stop(
      "Nenhuma AUC por propriedade: ",
      z$chave_config[1]
    )
  }
  
  k <- k + 1L
  
  resumos[[k]] <- data.frame(
    especie = z$especie[1],
    conjunto = z$conjunto[1],
    n_preditores = z$n_preditores[1],
    features = z$features[1],
    RM = z$RM[1],
    rodada_origem = z$rodada[1],
    folds = 3L,
    auc_media = mean(z$auc_validacao),
    auc_dp = sd(z$auc_validacao),
    auc_min = min(z$auc_validacao),
    boyce_media = mean(z$boyce_validacao),
    boyce_min = min(z$boyce_validacao),
    boyce_dp = sd(z$boyce_validacao),
    omissao_media = mean(z$omissao10_validacao),
    omissao_max = max(z$omissao10_validacao),
    omissao_dp = sd(z$omissao10_validacao),
    auc_mediana_propriedades = median(ap),
    auc_media_propriedades = mean(ap),
    propriedades_auc_abaixo_05 =
      sum(ap < 0.5),
    n_propriedades_avaliadas =
      length(ap),
    complexidade_media =
      mean(z$n_features_ativas),
    folds_omissao_acima_80 =
      sum(z$omissao10_validacao >= 0.80),
    stringsAsFactors = FALSE
  )
}

resumo <- do.call(rbind, resumos)
rownames(resumo) <- NULL

if (nrow(resumo) != 56L) {
  stop("Esperadas 56 configuracoes distintas.")
}

# Alertas descritivos, nao criterios automaticos
# para selecionar um modelo final.
resumo$alerta_auc <- resumo$auc_min < 0.5
resumo$alerta_boyce <- resumo$boyce_min < 0
resumo$alerta_omissao <-
  resumo$omissao_max >= 0.8

resumo$n_alertas <-
  as.integer(resumo$alerta_auc) +
  as.integer(resumo$alerta_boyce) +
  as.integer(resumo$alerta_omissao)

# ============================================================
# ETAPA 6 - FRONTEIRA DE PARETO EXPLORATORIA
# ============================================================

cat("\nETAPA 6 - Comparacao multicriterio...\n")

# Nao estabelece um modelo vencedor.
# Identifica configuracoes nao dominadas considerando:
# AUC media, Boyce medio, omissao media e maxima,
# AUC mediana dentro das propriedades.

resumo$pareto_exploratorio <- FALSE

for (sp in unique(resumo$especie)) {
  ix <- which(resumo$especie == sp)
  
  X <- as.matrix(resumo[ix, c(
    "auc_media",
    "boyce_media",
    "omissao_media",
    "omissao_max",
    "auc_mediana_propriedades"
  )])
  
  # Quanto maior, melhor, apos inverter as omissoes.
  X[, 3:4] <- -X[, 3:4]
  
  for (i in seq_len(nrow(X))) {
    dominado <- FALSE
    
    for (j in seq_len(nrow(X))) {
      if (i == j) next
      
      nao_pior <- all(
        X[j, ] >= X[i, ] - 1e-10
      )
      
      estritamente_melhor <- any(
        X[j, ] > X[i, ] + 1e-10
      )
      
      if (nao_pior && estritamente_melhor) {
        dominado <- TRUE
        break
      }
    }
    
    resumo$pareto_exploratorio[ix[i]] <-
      !dominado
  }
}

resumo <- resumo[order(
  resumo$especie,
  resumo$n_alertas,
  -resumo$auc_media
), , drop = FALSE]

# ============================================================
# ETAPA 7 - DIAGNOSTICOS AMBIENTAIS E ESPACIAIS
# ============================================================

cat("\nETAPA 7 - Incorporando diagnosticos R11/R12...\n")

diagnosticos <- data.frame(
  origem = character(),
  indicador = character(),
  valor = character(),
  stringsAsFactors = FALSE
)

registrar <- function(origem, indicador, valor) {
  diagnosticos <<- rbind(
    diagnosticos,
    data.frame(
      origem = origem,
      indicador = indicador,
      valor = as.character(valor),
      stringsAsFactors = FALSE
    )
  )
}

pasta_r11 <- file.path(
  pasta_resultados,
  "09 - Diagnostico ambiental e espacial V3"
)

arq_nov <- file.path(
  pasta_r11,
  "11_NOVIDADE_AMBIENTAL_MULTIVARIADA.csv"
)

arq_clamp <- file.path(
  pasta_r11,
  "11_IMPACTO_CLAMPING_36_MODELOS.csv"
)

if (file.exists(arq_nov)) {
  novidade <- ler(arq_nov)
  
  if (nrow(novidade) == 6L) {
    for (i in seq_len(nrow(novidade))) {
      registrar(
        "R11",
        paste(
          novidade$especie[i],
          "Fold", novidade$fold_cv[i],
          "- % presencas atipicas"
        ),
        round(
          100 *
            novidade$fracao_presencas_acima_p95[i],
          2
        )
      )
    }
  }
} else {
  registrar("R11", "Novidade ambiental",
            "Arquivo nao localizado")
}

if (file.exists(arq_clamp)) {
  clamping <- ler(arq_clamp)
  
  if (nrow(clamping) == 36L) {
    registrar(
      "R11",
      "Avaliacoes com alteracao na omissao por clamping",
      sum(abs(clamping$delta_omissao) > 1e-8)
    )
  }
} else {
  registrar("R11", "Clamping",
            "Arquivo nao localizado")
}

pasta_r12_base <- file.path(
  pasta_resultados,
  "10 - Auditoria da validacao espacial B0 V3_1"
)

pasta_r12 <- NA_character_

if (dir.exists(pasta_r12_base)) {
  candidatas <- unique(c(
    pasta_r12_base,
    list.dirs(
      pasta_r12_base,
      recursive = FALSE,
      full.names = TRUE
    )
  ))
  
  candidatas <- candidatas[
    file.exists(file.path(
      candidatas,
      "12_DISTANCIAS_ENTRE_UPAS_FOLDS.csv"
    ))
  ]
  
  if (length(candidatas)) {
    pasta_r12 <- tail(sort(candidatas), 1L)
  }
}

if (!is.na(pasta_r12)) {
  distancias <- ler(file.path(
    pasta_r12,
    "12_DISTANCIAS_ENTRE_UPAS_FOLDS.csv"
  ))
  
  registrar(
    "R12",
    "Menor distancia entre UPAs de folds diferentes (m)",
    round(min(distancias$distancia_m), 2)
  )
  
  registrar(
    "R12",
    "Pares de UPAs com distancia inferior a 5 km",
    sum(distancias$distancia_m < 5000)
  )
  
  arq_moran <- file.path(
    pasta_r12,
    "12_MORAN_POR_PROPRIEDADE.csv"
  )
  
  if (file.exists(arq_moran)) {
    moran <- ler(arq_moran)
    
    for (v in unique(moran$variavel)) {
      z <- moran[moran$variavel == v, ]
      
      registrar(
        "R12",
        paste("Moran I medio:", v),
        round(mean(z$moran_i), 4)
      )
    }
  }
} else {
  registrar(
    "R12",
    "Distancias espaciais",
    "Resultados nao localizados"
  )
}

# ============================================================
# ETAPA 8 - SALVAR RESULTADOS EM PASTA NOVA
# ============================================================

cat("\nETAPA 8 - Salvando os resultados...\n")

base_saida <- file.path(
  pasta_resultados,
  "12 - Consolidacao do background B0 V3_1"
)

dir.create(
  base_saida,
  recursive = TRUE,
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
  stop("Pasta de execucao ja existente.")
}

dir.create(saida)

graficos <- file.path(saida, "14_GRAFICOS")
dir.create(graficos)

salvar(
  avaliacoes,
  "14_TODAS_180_AVALIACOES.csv",
  saida
)

salvar(
  modelos,
  "14_MODELOS_168_AJUSTES_DISTINTOS.csv",
  saida
)

salvar(
  propriedades_unicas,
  "14_AVALIACOES_POR_PROPRIEDADE.csv",
  saida
)

salvar(
  comparacoes,
  "14_COMPARACAO_96_ALTERNATIVOS_VS_M1.csv",
  saida
)

salvar(
  resumo,
  "14_RESUMO_56_CONFIGURACOES.csv",
  saida
)

salvar(
  resumo[resumo$pareto_exploratorio, ],
  "14_PARETO_EXPLORATORIO.csv",
  saida
)

salvar(
  diagnosticos,
  "14_DIAGNOSTICOS_R11_R12.csv",
  saida
)

# Arquivos originais e respectivos hashes.
manifesto_final <- data.frame(
  arquivo = basename(obrigatorios),
  caminho = normalizePath(
    obrigatorios,
    winslash = "/",
    mustWork = TRUE
  ),
  md5 = unname(
    as.character(tools::md5sum(obrigatorios))
  )
)

salvar(
  manifesto_final,
  "14_MANIFESTO_FONTES.csv",
  saida
)

# ============================================================
# ETAPA 9 - GRAFICOS COMPARATIVOS
# ============================================================

cat("\nETAPA 9 - Gerando graficos...\n")

cores <- c(
  "M1" = "gray20",
  "M2" = "gray50",
  "M3" = "gray75"
)

for (sp in c("Ipe-roxo", "Ipe-amarelo")) {
  apelido <- ifelse(
    sp == "Ipe-roxo",
    "ROXO", "AMARELO"
  )
  
  z <- resumo[
    resumo$especie == sp,
    , drop = FALSE
  ]
  
  # AUC media versus maior omissao entre folds.
  png(
    file.path(
      graficos,
      paste0(
        "14_", apelido,
        "_AUC_VS_OMISSAO.png"
      )
    ),
    width = 1250,
    height = 850,
    res = 140
  )
  
  plot(
    z$omissao_max,
    z$auc_media,
    pch = 21,
    bg = cores[z$rodada_origem],
    col = "black",
    cex = 1.4,
    xlim = c(0, 1),
    ylim = c(0, 1),
    xlab = "Maior omissao entre os folds",
    ylab = "AUC media",
    main = paste(
      "MaxEnt B0 -", sp,
      "- AUC e omissao"
    )
  )
  
  abline(h = 0.5, lty = 3, col = "gray55")
  abline(v = 0.8, lty = 2, col = "gray55")
  
  legend(
    "topright",
    legend = c("M1", "M2", "M3"),
    pch = 21,
    pt.bg = cores[c("M1", "M2", "M3")],
    bty = "n"
  )
  
  dev.off()
  
  # Comparacao do modelo completo com o conjunto
  # alternativo testado no M3, sempre LQH/RM4.
  conjunto_alt <- if (sp == "Ipe-roxo") {
    "SEM_BIO12_BIO17"
  } else {
    "SEM_BIO12"
  }
  
  completo <- modelos[
    modelos$especie == sp &
      modelos$conjunto == "COMPLETO_6" &
      modelos$features == "lqh" &
      modelos$RM == 4,
    , drop = FALSE
  ]
  
  alternativo <- modelos[
    modelos$especie == sp &
      modelos$conjunto == conjunto_alt &
      modelos$features == "lqh" &
      modelos$RM == 4,
    , drop = FALSE
  ]
  
  completo <- completo[
    order(completo$fold_cv),
    , drop = FALSE
  ]
  
  alternativo <- alternativo[
    order(alternativo$fold_cv),
    , drop = FALSE
  ]
  
  if (nrow(completo) != 3L ||
      nrow(alternativo) != 3L) {
    stop("Comparacao LQH/RM4 incompleta.")
  }
  
  for (indicador in c(
    "auc_validacao",
    "omissao10_validacao",
    "boyce_validacao"
  )) {
    png(
      file.path(
        graficos,
        paste0(
          "14_", apelido,
          "_LQH_RM4_",
          toupper(indicador),
          ".png"
        )
      ),
      width = 1150,
      height = 760,
      res = 140
    )
    
    limite <- if (
      indicador == "boyce_validacao"
    ) c(-1, 1) else c(0, 1)
    
    plot(
      1:3,
      completo[[indicador]],
      type = "b",
      pch = 16,
      lwd = 2,
      col = "gray20",
      ylim = limite,
      xaxt = "n",
      xlab = "Fold espacial",
      ylab = indicador,
      main = paste(
        sp, "- Completo vs alternativo"
      )
    )
    
    axis(1, at = 1:3)
    
    lines(
      1:3,
      alternativo[[indicador]],
      type = "b",
      pch = 17,
      lwd = 2,
      col = "gray60"
    )
    
    if (indicador == "auc_validacao") {
      abline(h = 0.5, lty = 3)
    }
    
    legend(
      "topright",
      legend = c(
        "Completo - 6 variaveis",
        conjunto_alt
      ),
      lty = 1,
      pch = c(16, 17),
      col = c("gray20", "gray60"),
      bty = "n"
    )
    
    dev.off()
  }
}

# ============================================================
# ETAPA 10 - RELATORIO CONSOLIDADO
# ============================================================

cat("\nETAPA 10 - Finalizando relatorio...\n")

relatorio <- c(
  "# TCC IPES - Consolidacao B0",
  "",
  "## Configuracao",
  "",
  "- Background B0: 5.000 pontos.",
  "- 27 propriedades de desenvolvimento.",
  "- 64 UPAs inventariadas de desenvolvimento.",
  "- Tres folds espaciais.",
  "- Teste externo nao utilizado.",
  "",
  "## Experimentos",
  "",
  paste(
    "- Avaliacoes registradas:",
    nrow(avaliacoes)
  ),
  paste(
    "- Ajustes distintos:",
    nrow(modelos)
  ),
  paste(
    "- Configuracoes:",
    nrow(resumo)
  ),
  "- M1: 72 ajustes com seis variaveis.",
  "- M2: 30 ajustes novos e seis reutilizados.",
  "- M3: 66 ajustes novos e seis reutilizados.",
  "",
  "## Metricas",
  "",
  "- AUC: discriminacao presenca-background.",
  "- Boyce: indicador de concordancia com as presencas.",
  "- Omissao: presencas abaixo do limiar do treinamento.",
  "- Complexidade: numero de coeficientes ativos.",
  "- Avaliacao intra-propriedade tambem considerada.",
  "",
  "## Limitacoes",
  "",
  "Nao foi comprovada independencia espacial absoluta.",
  "Algumas UPAs de folds diferentes estao proximas.",
  "Ha autocorrelacao ambiental nas propriedades.",
  "M2 e M3 investigaram conjuntos escolhidos",
  "a partir dos resultados exploratorios anteriores.",
  "Nao interpretar ganhos como evidencia confirmatoria.",
  "",
  "A fronteira de Pareto nao seleciona vencedor.",
  "Os alertas sao descritores exploratorios.",
  "Os resultados devem ser examinados por fold.",
  "",
  "## Pendencias",
  "",
  "- Analise Jackknife por especie.",
  "- Avaliacao de backgrounds alternativos.",
  "- Selecao de configuracoes usando desenvolvimento.",
  "- Validacao nas propriedades externas reservadas.",
  "- Interpretacao ecologica e mapas finais.",
  "",
  "## Reprodutibilidade",
  "",
  "- Dados R05 conferidos por MD5.",
  "- Reutilizacoes entre M1, M2 e M3 conferidas.",
  "- Omissao validada por propriedade.",
  "- Nenhum modelo MaxEnt ajustado no R14.",
  "- Scripts e resultados anteriores preservados.",
  "",
  paste("Data:", as.character(Sys.time())),
  paste("R:", R.version.string),
  paste("Script:", versao)
)

writeLines(
  relatorio,
  file.path(
    saida,
    "14_RELATORIO_CONSOLIDADO_B0.md"
  )
)

writeLines(
  capture.output(sessionInfo()),
  file.path(
    saida,
    "14_SESSION_INFO.txt"
  )
)

cat("\n============================================\n")
cat("R14 V3.1 FINALIZADO!\n")
cat("============================================\n")
cat("Avaliacoes:", nrow(avaliacoes), "\n")
cat("Ajustes distintos:", nrow(modelos), "\n")
cat("Configuracoes:", nrow(resumo), "\n")
cat("Novos modelos MaxEnt: ZERO\n")
cat("\nResultados em:\n")
cat(saida, "\n")
cat("============================================\n")
