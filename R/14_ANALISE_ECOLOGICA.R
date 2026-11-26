# =============================================================================
# 14_ANALISE_ECOLOGICA.R
# -----------------------------------------------------------------------------
# O QUE FAZ: analise descritiva "estilo Ferreira (2009)" - onde, no ambiente,
#            estao os ipes? Independe do MaxEnt e serve de base ecologica
#            para a discussao. So propriedades de DESENVOLVIMENTO (as 7
#            reservadas ficam fora, para nao contaminar o teste externo).
#   1) Densidade (pixels com ipe por ha) por classe de cada variavel continua:
#      media e erro padrao entre propriedades + ajuste linear e quadratico
#      (como as Figs. 61/65 de Ferreira, 2009).
#   2) Densidade por classe combinada altitude x declividade e altitude x
#      distancia ao rio (como as Figs. 62/66).
#   3) Densidade por textura do solo.
#   4) Presenca x disponivel (background) por variavel: medianas e teste de
#      Mann-Whitney; indice de selecao (proporcao das arvores / proporcao da area).
#   5) Quanto de cada variavel varia DENTRO x ENTRE propriedades (explica por
#      que o clima - 1 km - separa propriedades, mas nao lugares dentro delas).
#   6) Roxo x amarelo nas 4 propriedades onde ocorrem juntos (mesmo lugar,
#      ambiente diferente?).
# AREA: cada ponto de background representa (pixels da UPA / pontos na UPA)
#       pixels de 30 m (0,09 ha) - assim a area de cada classe e estimada.
# SAIDAS : resultados/_geral/09_ecologia/
# USO    : Rscript R/14_ANALISE_ECOLOGICA.R
# =============================================================================

if (!exists("carregar_dados_especie")) source(file.path("R", "02_CARREGAR_DADOS.R"), encoding = "UTF-8")
suppressMessages({ library(ggplot2) })

HA_PIXEL <- 0.09
CONTINUAS <- setdiff(names(VARIAVEIS), VARIAVEIS_CATEGORICAS)
ROT <- c(altitude_m = "Altitude (m)", declividade_graus = "Declividade (graus)", dist_rio_raster_m = "Distância à hidrografia (m)",
         bio12_mm_ano = "BIO12 - precipitação anual (mm)", bio17_mm_mes = "BIO17 - precip. trimestre mais seco (mm/mês)",
         textura_subgrupo = "Textura do solo (código)")

base_ecologia <- function() {
  up <- utils::read.csv2(file.path(RAIZ_PROJETO, "resultados", "_geral", "00_pixels_por_upa.csv"), encoding = "UTF-8")
  r <- carregar_dados_especie("roxo"); a <- carregar_dados_especie("amarelo")
  bg <- r$background[!r$background$propriedade %in% PROPRIEDADES_RESERVADAS, ]
  n_upa <- table(bg$upa_id); bg$peso_ha <- up$pixels[match(bg$upa_id, up$upa_id)] / as.numeric(n_upa[bg$upa_id]) * HA_PIXEL
  pr <- rbind(transform(r$presencas, especie = "Ipê-roxo"), transform(a$presencas, especie = "Ipê-amarelo"))
  pr <- pr[!pr$propriedade %in% PROPRIEDADES_RESERVADAS, ]
  bg$textura_subgrupo <- as.character(bg$textura_subgrupo); pr$textura_subgrupo <- as.character(pr$textura_subgrupo)
  list(bg = bg, pr = pr)
}

classes <- function(x, ref, n = 8) {
  q <- unique(stats::quantile(ref, seq(0, 1, length.out = n + 1), na.rm = TRUE))
  q <- unique(signif(q, 3)); q[1] <- min(q[1], min(x, na.rm = TRUE)); q[length(q)] <- max(q[length(q)], max(x, na.rm = TRUE))
  cut(x, q, include.lowest = TRUE, dig.lab = 5)
}

#' Densidade por classe: total e media +- EP entre propriedades onde a especie ocorre.
densidade_classes <- function(B, especie, var, cls_bg, cls_pr) {
  pr <- B$pr[B$pr$especie == especie, ]; props <- unique(pr$propriedade)
  ok <- B$bg$propriedade %in% props
  area <- tapply(B$bg$peso_ha[ok], list(cls_bg[ok], B$bg$propriedade[ok]), sum); area[is.na(area)] <- 0
  n <- table(factor(cls_pr[B$pr$especie == especie], levels = rownames(area)), factor(pr$propriedade, levels = colnames(area)))
  dens <- n / area; dens[area < 5] <- NA                   # classe com < 5 ha na propriedade: nao estima
  data.frame(especie = especie, variavel = var, classe = rownames(area),
             area_ha = rowSums(area), arvores = rowSums(n), dens_total = rowSums(n) / rowSums(area),
             dens_media = apply(dens, 1, mean, na.rm = TRUE),
             dens_ep = apply(dens, 1, function(z) stats::sd(z, na.rm = TRUE) / sqrt(sum(!is.na(z)))),
             n_props = apply(dens, 1, function(z) sum(!is.na(z))), row.names = NULL)
}

ponto_medio <- function(cl) sapply(strsplit(gsub("[][()]", "", cl), ","), function(z) mean(as.numeric(z)))

analisar_ecologia <- function() {
  pasta <- file.path(RAIZ_PROJETO, "resultados", "_geral", "09_ecologia"); dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  B <- base_ecologia(); esp <- c("Ipê-roxo", "Ipê-amarelo")
  sv <- function(d, f) utils::write.csv2(d, file.path(pasta, f), row.names = FALSE, fileEncoding = "UTF-8")

  # ---- 1) densidade por classe -------------------------------------------------------
  D <- do.call(rbind, lapply(CONTINUAS, function(v) {
    cb <- classes(B$bg[[v]], B$bg[[v]])
    br <- unique(c(sapply(strsplit(gsub("[][()]", "", levels(cb)), ","), function(z) as.numeric(z))))
    cp <- cut(B$pr[[v]], br, include.lowest = TRUE, dig.lab = 5)
    do.call(rbind, lapply(esp, function(e) densidade_classes(B, e, v, cb, cp)))
  }))
  D$x <- ponto_medio(D$classe)
  aj <- do.call(rbind, lapply(split(D, list(D$especie, D$variavel), drop = TRUE), function(d) {
    l <- stats::lm(dens_total ~ x, d, weights = area_ha); q <- stats::lm(dens_total ~ x + I(x^2), d, weights = area_ha)
    data.frame(especie = d$especie[1], variavel = d$variavel[1], r2_linear = summary(l)$r.squared, r2_quadratico = summary(q)$r.squared,
               p_linear = summary(l)$coefficients[2, 4], tendencia = ifelse(stats::coef(l)[2] > 0, "aumenta", "diminui"),
               classe_maior_densidade = d$classe[which.max(d$dens_total)], razao_max_min = max(d$dens_total) / max(min(d$dens_total), 1e-6))
  }))
  sv(D, "01_DENSIDADE_POR_CLASSE.csv"); sv(aj, "02_AJUSTE_LINEAR_QUADRATICO.csv")
  g1 <- ggplot(D, aes(x, dens_media, colour = especie)) +
    geom_errorbar(aes(ymin = dens_media - dens_ep, ymax = dens_media + dens_ep), width = 0, alpha = .6, position = position_dodge(width = 0)) +
    geom_point(size = 2) + geom_smooth(aes(weight = area_ha), method = "lm", formula = y ~ x + I(x^2), se = FALSE, linewidth = .7) +
    facet_wrap(~ variavel, scales = "free", labeller = as_labeller(ROT)) +
    scale_colour_manual(values = c("Ipê-amarelo" = "#D4A017", "Ipê-roxo" = "#7B3F9E")) +
    labs(x = "Ponto médio da classe", y = "Densidade (árvores/ha) - média ± EP entre propriedades", colour = NULL) +
    theme_bw(11) + theme(legend.position = "top")
  ggsave(file.path(pasta, "G1_DENSIDADE_POR_CLASSE.png"), g1, width = 10, height = 7, dpi = 200, bg = "white")

  # ---- 2) classes combinadas ---------------------------------------------------------
  comb <- function(v1, v2) do.call(rbind, lapply(esp, function(e) {
    b1 <- classes(B$bg[[v1]], B$bg[[v1]], 5); b2 <- classes(B$bg[[v2]], B$bg[[v2]], 5)
    br <- function(cb) unique(c(sapply(strsplit(gsub("[][()]", "", levels(cb)), ","), as.numeric)))
    p <- B$pr[B$pr$especie == e, ]; ok <- B$bg$propriedade %in% unique(p$propriedade)
    area <- tapply(B$bg$peso_ha[ok], list(b1[ok], b2[ok]), sum)
    n <- table(cut(p[[v1]], br(b1), include.lowest = TRUE, dig.lab = 5), cut(p[[v2]], br(b2), include.lowest = TRUE, dig.lab = 5))
    dd <- as.data.frame(as.table(n / area)); names(dd) <- c("c1", "c2", "dens"); dd$especie <- e; dd$par <- paste(ROT[v1], "x", ROT[v2])
    dd$area_ha <- as.vector(area); dd
  }))
  C2 <- rbind(comb("altitude_m", "declividade_graus"), comb("altitude_m", "dist_rio_raster_m"))
  sv(C2, "03_DENSIDADE_CLASSES_COMBINADAS.csv")
  for (pp in unique(C2$par)) {
    g <- ggplot(C2[C2$par == pp, ], aes(c1, c2, fill = dens)) + geom_tile(colour = "white") +
      geom_text(aes(label = ifelse(is.na(dens), "", formatC(dens, format = "f", digits = 2))), size = 3) +
      facet_wrap(~ especie) + scale_fill_viridis_c(na.value = "grey90", option = "magma", direction = -1) +
      labs(x = strsplit(pp, " x ")[[1]][1], y = strsplit(pp, " x ")[[1]][2], fill = "árv./ha") +
      theme_bw(10) + theme(axis.text.x = element_text(angle = 30, hjust = 1))
    ggsave(file.path(pasta, paste0("G2_", if (grepl("Decl", pp)) "ALT_DECL" else "ALT_RIO", ".png")), g, width = 10, height = 4.8, dpi = 200, bg = "white")
  }

  # ---- 3) solo --------------------------------------------------------------------------
  S <- do.call(rbind, lapply(esp, function(e) densidade_classes(B, e, "textura_subgrupo", factor(B$bg$textura_subgrupo),
                                                              factor(B$pr$textura_subgrupo, levels = sort(unique(B$bg$textura_subgrupo))))))
  sv(S, "04_DENSIDADE_SOLO.csv")
  ggsave(file.path(pasta, "G3_SOLO.png"), ggplot(S[S$area_ha > 50, ], aes(classe, dens_total, fill = especie)) + geom_col(position = "dodge") +
    scale_fill_manual(values = c("Ipê-amarelo" = "#D4A017", "Ipê-roxo" = "#7B3F9E")) +
    labs(x = "Textura do solo (código MapBiomas)", y = "Densidade (árvores/ha)", fill = NULL) + theme_bw(11), width = 8, height = 4.5, dpi = 200, bg = "white")

  # ---- 4) presenca x disponivel ---------------------------------------------------------
  P <- do.call(rbind, lapply(esp, function(e) do.call(rbind, lapply(CONTINUAS, function(v) {
    p <- B$pr[B$pr$especie == e, ]; ok <- B$bg$propriedade %in% unique(p$propriedade)
    w <- stats::wilcox.test(p[[v]], B$bg[[v]][ok])
    data.frame(especie = e, variavel = v, mediana_ipe = stats::median(p[[v]]), mediana_disponivel = stats::median(B$bg[[v]][ok]),
               p_valor = w$p.value, efeito_r = auc_simples(p[[v]], B$bg[[v]][ok]) * 2 - 1)
  }))))
  sv(P, "05_PRESENCA_X_DISPONIVEL.csv")

  # ---- 5) variacao dentro x entre propriedades -----------------------------------------
  V <- do.call(rbind, lapply(CONTINUAS, function(v) {
    m <- stats::aov(B$bg[[v]] ~ B$bg$propriedade); ss <- summary(m)[[1]][["Sum Sq"]]
    data.frame(variavel = v, pct_variacao_entre_propriedades = round(100 * ss[1] / sum(ss), 1))
  }))
  sv(V, "06_VARIACAO_ENTRE_PROPRIEDADES.csv")

  # ---- 6) roxo x amarelo onde ocorrem juntos --------------------------------------------
  juntas <- intersect(B$pr$propriedade[B$pr$especie == esp[1]], B$pr$propriedade[B$pr$especie == esp[2]])
  J <- do.call(rbind, lapply(CONTINUAS, function(v) {
    x <- B$pr[B$pr$propriedade %in% juntas, ]
    # teste estratificado por propriedade: media das diferencas de mediana dentro de cada propriedade
    dif <- sapply(juntas, function(pp) stats::median(x[[v]][x$especie == esp[1] & x$propriedade == pp]) - stats::median(x[[v]][x$especie == esp[2] & x$propriedade == pp]))
    data.frame(variavel = v, propriedades = paste(juntas, collapse = "; "), mediana_roxo = stats::median(x[[v]][x$especie == esp[1]]),
               mediana_amarelo = stats::median(x[[v]][x$especie == esp[2]]), dif_mediana_por_propriedade = paste(round(dif, 1), collapse = "; "),
               p_wilcoxon = stats::wilcox.test(x[[v]] ~ x$especie)$p.value)
  }))
  sv(J, "07_ROXO_X_AMARELO_MESMAS_PROPRIEDADES.csv")
  writeLines(c("Propriedades de desenvolvimento usadas (reservadas fora).",
               sprintf("Roxo: %d arvores em %d propriedades; Amarelo: %d em %d.", sum(B$pr$especie == esp[1]), length(unique(B$pr$propriedade[B$pr$especie == esp[1]])),
                       sum(B$pr$especie == esp[2]), length(unique(B$pr$propriedade[B$pr$especie == esp[2]])))), file.path(pasta, "LEIA.txt"))
  message("Ecologia salva em ", pasta)
  invisible(list(D = D, aj = aj, C2 = C2, S = S, P = P, V = V, J = J))
}

auc_simples <- function(p, b) { r <- rank(c(p, b)); (sum(r[seq_along(p)]) - length(p) * (length(p) + 1) / 2) / (length(p) * length(b)) }

if (sys.nframe() == 0) analisar_ecologia()
