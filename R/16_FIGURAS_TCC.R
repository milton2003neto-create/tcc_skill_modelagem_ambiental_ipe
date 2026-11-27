# =============================================================================
# 16_FIGURAS_TCC.R
# -----------------------------------------------------------------------------
# Figuras e tabelas finais do TCC (padrao ABNT, estilo Ferreira, 2009):
#   F_DENS_<esp>   densidade media +- EP por classe: (a) altitude, (b) declividade,
#                  (c) distancia a hidrografia, com equacao e R2 da tendencia
#   F_JK_<esp>     Jackknife (ganho de treino): modelo escolhido e modelo com 6 variaveis
#   F_RESP_<esp>   curvas de resposta do modelo escolhido
#   F_ROC_<esp>    curvas ROC (treino, validacao cruzada, teste externo)
#   F_MAPA_<esp>   adequabilidade nas propriedades (grupos oeste, central e leste)
#   F_CORREL       correlacao de Pearson/Spearman entre as 6 variaveis + VIF
# Uso (na pasta do projeto): Rscript R/16_FIGURAS_TCC.R roxo
#                            Rscript R/16_FIGURAS_TCC.R correlacao
# =============================================================================
suppressPackageStartupMessages({
  source(file.path("R", "12_TESTE_EXTERNO.R"), encoding = "UTF-8")
  source(file.path("R", "11_BUSCA_METODOLOGICA.R"), encoding = "UTF-8")
  library(ggplot2); library(patchwork); library(sf); library(terra); library(ggspatial)
})
sf_use_s2(FALSE)
options(OutDec = ",")
SAIDA <- file.path(PASTA_RESULTADOS, "_geral", "11_figuras_tcc")
dir.create(SAIDA, recursive = TRUE, showWarnings = FALSE)

NOMES <- c(altitude_m = "Altitude (m)", declividade_graus = "Declividade (graus)",
           dist_rio_raster_m = "Distância à hidrografia (m)", bio12_mm_ano = "BIO12 (mm/ano)",
           bio17_mm_mes = "BIO17 (mm/mês)", textura_subgrupo = "Textura do solo")
NOME_SP <- c(roxo = "Handroanthus impetiginosus", amarelo = "Handroanthus serratifolius")

# tema ABNT/Ferreira: fundo branco, eixos pretos, sem grade
tema_abnt <- theme_classic(base_size = 9, base_family = "sans") +
  theme(axis.text = element_text(colour = "black", size = 7.5), axis.line = element_line(linewidth = 0.35),
        axis.ticks = element_line(linewidth = 0.35), plot.title = element_text(size = 9, face = "bold"),
        legend.text = element_text(size = 7.5), legend.title = element_text(size = 8, face = "bold"),
        strip.background = element_blank(), strip.text = element_text(face = "bold", size = 8.5))
salvar <- function(p, nome, w = 16, h = 7) {
  ggsave(file.path(SAIDA, paste0(nome, ".png")), p, width = w, height = h, units = "cm", dpi = 300, bg = "white")
  cat("  ", nome, "\n")
}
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, decimal.mark = ",")
fmt_sci <- function(x) {
  if (abs(x) >= 0.001) return(formatC(signif(x, 3), format = "fg", digits = 3, decimal.mark = ","))
  e <- floor(log10(abs(x))); m <- x / 10^e
  sup <- c("0" = "⁰", "1" = "¹", "2" = "²", "3" = "³", "4" = "⁴", "5" = "⁵",
           "6" = "⁶", "7" = "⁷", "8" = "⁸", "9" = "⁹", "-" = "⁻")
  paste0(formatC(m, format = "f", digits = 2, decimal.mark = ","), "×10", paste(sup[strsplit(as.character(e), "")[[1]]], collapse = ""))
}

# pastas do teste externo registrado
pastas_especie <- function(especie) {
  r <- read.csv2(list.files(file.path(PASTA_RESULTADOS, "_geral", "teste_externo"), "RESULTADO_TESTE_EXTERNO.csv",
                            recursive = TRUE, full.names = TRUE)[1])
  pv <- r$pasta_validacao[r$especie == ESPECIES[[especie]]]
  if (!length(pv)) stop("teste externo ainda nao realizado para ", especie)
  pv <- file.path(PASTA_RESULTADOS, especie, "06_validacao", basename(pv))
  tr <- sort(list.dirs(file.path(PASTA_RESULTADOS, especie, "05_treino"), recursive = FALSE))
  list(validacao = pv, treino = tail(tr[basename(tr) <= basename(pv)], 1))
}

# ---------------- 1) densidade por classe (Ferreira) ----------------
fig_densidade <- function(especie) {
  ajustes <- list()
  d <- read.csv2(file.path(PASTA_RESULTADOS, "_geral", "09_ecologia", "01_DENSIDADE_POR_CLASSE.csv"))
  d <- d[d$especie == c(roxo = "Ipê-roxo", amarelo = "Ipê-amarelo")[[especie]] & d$variavel %in% c("altitude_m", "declividade_graus", "dist_rio_raster_m"), ]
  paineis <- lapply(seq_along(c("altitude_m", "declividade_graus", "dist_rio_raster_m")), function(i) {
    v <- c("altitude_m", "declividade_graus", "dist_rio_raster_m")[i]; x <- d[d$variavel == v, ]
    m1 <- lm(dens_media ~ x, x); m2 <- lm(dens_media ~ x + I(x^2), x)
    r1 <- summary(m1)$r.squared; r2 <- summary(m2)$r.squared
    usar2 <- (r2 - r1) > 0.1                      # quadratico so se melhora bem o ajuste
    m <- if (usar2) m2 else m1; cf <- coef(m); fs <- summary(m)$fstatistic; p <- unname(pf(fs[1], fs[2], fs[3], lower.tail = FALSE))
    eq <- if (usar2) sprintf("y = %s %s %sx %s %sx²", fmt(cf[1]), ifelse(cf[2] < 0, "-", "+"), fmt_sci(abs(cf[2])),
                            ifelse(cf[3] < 0, "-", "+"), fmt_sci(abs(cf[3])))
          else sprintf("y = %s %s %sx", fmt(cf[1]), ifelse(cf[2] < 0, "-", "+"), fmt_sci(abs(cf[2])))
    eq <- paste0(eq, "\nR² = ", fmt(summary(m)$r.squared, 2), "; p ", ifelse(p < 0.001, "< 0,001", paste("=", fmt(p, 3))))
    ajustes[[v]] <<- data.frame(especie = especie, variavel = v, modelo = ifelse(usar2, "quadratico", "linear"),
                                r2_linear = round(r1, 3), r2_quadratico = round(r2, 3), r2_usado = round(summary(m)$r.squared, 3),
                                p = signif(p, 3), dens_min = round(min(x$dens_media), 3), dens_max = round(max(x$dens_media), 3),
                                classe_max = x$classe[which.max(x$dens_media)], classe_min = x$classe[which.min(x$dens_media)])
    xs <- seq(min(x$x), max(x$x), length.out = 100)
    ggplot(x, aes(x, dens_media)) +
      geom_line(data = data.frame(x = xs, dens_media = predict(m, data.frame(x = xs))), linewidth = 0.4, linetype = "dashed") +
      geom_errorbar(aes(ymin = pmax(dens_media - dens_ep, 0), ymax = dens_media + dens_ep), width = 0, linewidth = 0.35) +
      geom_point(shape = 21, fill = "black", size = 1.6) +
      annotate("text", x = -Inf, y = Inf, label = eq, hjust = -0.05, vjust = 1.1, size = 2.2, lineheight = 0.9) +
      scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.25))) +
      labs(x = NOMES[[v]], y = if (i == 1) expression("Densidade (árvores ha"^-1*")") else NULL,
           title = paste0("(", letters[i], ")")) + tema_abnt
  })
  salvar(wrap_plots(paineis, nrow = 1), paste0("F_DENS_", especie), h = 6.2)
  aj <- do.call(rbind, ajustes); print(aj); write.csv2(aj, file.path(SAIDA, paste0("AJUSTES_DENS_", especie, ".csv")), row.names = FALSE)
}

# ---------------- 2) Jackknife ----------------
jk_seis <- function(especie, fc = "lq", rm = 2) {
  arq <- file.path(SAIDA, paste0("JK_SEIS_", especie, ".csv"))
  if (file.exists(arq)) return(read.csv2(arq))
  d <- dados_busca(especie); vs <- names(NOMES)
  conj <- c(list(todas = vs), setNames(lapply(vs, function(v) v), paste0("so|", vs)),
            setNames(lapply(vs, function(v) setdiff(vs, v)), paste0("sem|", vs)))
  out <- do.call(rbind, lapply(names(conj), function(nm) {
    cat("   JK 6 vars:", nm, "\n"); v <- conj[[nm]]
    dm <- dados_maxnet(d$pr, d$bg, v); a <- ajuste_seguro(dm$p, dm$x, fc, rm)
    data.frame(tipo = c(todas = "Com todas", so = "Somente a variavel", sem = "Sem a variavel")[[sub("\\|.*", "", nm)]],
               variavel = if (nm == "todas") "(todas)" else sub(".*\\|", "", nm),
               ganho_treino = ganho(a$modelo, d$pr[, v, drop = FALSE], d$bg[, v, drop = FALSE], TRUE))
  }))
  write.csv2(out, arq, row.names = FALSE); out
}
painel_jk <- function(jk, titulo) {
  tod <- jk$ganho_treino[jk$tipo == "Com todas"]
  d <- jk[jk$tipo != "Com todas", ]
  d$tipo <- factor(ifelse(d$tipo == "Somente a variavel", "Somente a variável", "Sem a variável"),
                   levels = c("Sem a variável", "Somente a variável"))
  d$nome <- factor(NOMES[d$variavel], levels = rev(NOMES[names(NOMES) %in% d$variavel]))
  ggplot(d, aes(ganho_treino, nome, fill = tipo)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.7, colour = "black", linewidth = 0.25) +
    geom_vline(xintercept = tod, linetype = "dashed", linewidth = 0.4) +
    scale_fill_manual(values = c("Somente a variável" = "grey20", "Sem a variável" = "grey80"), name = NULL,
                      breaks = c("Somente a variável", "Sem a variável")) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.08))) +
    labs(x = "Ganho de treino regularizado", y = NULL, title = titulo, subtitle = paste0("Com todas as variáveis = ", fmt(tod, 2), " (linha tracejada)")) + tema_abnt +
    theme(legend.position = "bottom", plot.subtitle = element_text(size = 7))
}
fig_jackknife <- function(especie, ps) {
  jk1 <- read.csv2(file.path(ps$treino, "05_JACKKNIFE.csv")); me <- readRDS(file.path(ps$treino, "MODELO_ESCOLHIDO.rds"))
  jk2 <- jk_seis(especie)
  p <- painel_jk(jk1, "(a) Modelo escolhido") +
       painel_jk(jk2, "(b) Modelo com as seis variáveis") +
       plot_layout(guides = "collect", widths = c(1, 1)) & theme(legend.position = "bottom")
  salvar(p, paste0("F_JK_", especie), h = 7)
  write.csv2(rbind(transform(jk1[, c("tipo", "variavel", "ganho_treino")], modelo = "escolhido"),
                   transform(jk2, modelo = "seis_variaveis")), file.path(SAIDA, paste0("JK_", especie, ".csv")), row.names = FALSE)
}

# ---------------- 3) curvas de resposta ----------------
fig_resposta <- function(especie, ps) {
  me <- readRDS(file.path(ps$treino, "MODELO_ESCOLHIDO.rds")); d <- dados_busca(especie)
  ref <- lapply(d$bg[, me$variaveis, drop = FALSE], function(z) if (is.factor(z)) names(which.max(table(z))) else mean(z))
  ps_ <- lapply(seq_along(me$variaveis), function(i) {
    v <- me$variaveis[i]
    if (is.factor(d$bg[[v]])) {
      niv <- levels(d$bg[[v]]); nd <- as.data.frame(ref)[rep(1, length(niv)), , drop = FALSE]; nd[[v]] <- niv
      for (w in names(nd)) if (is.factor(d$bg[[w]])) nd[[w]] <- factor(nd[[w]], levels = levels(d$bg[[w]]))
      nd$s <- prever(me$maxnet, nd[, me$variaveis, drop = FALSE], me$clamp)
      return(ggplot(nd, aes(.data[[v]], s)) + geom_col(fill = "grey40", colour = "black", width = 0.6) +
               labs(x = NOMES[[v]], y = if (i == 1) "Adequabilidade (cloglog)" else NULL, title = paste0("(", letters[i], ")")) + tema_abnt)
    }
    r <- quantile(d$bg[[v]], c(0.005, 0.995)); xs <- seq(r[1], r[2], length.out = 200)
    nd <- as.data.frame(ref)[rep(1, 200), , drop = FALSE]; nd[[v]] <- xs
    for (w in names(nd)) if (is.factor(d$bg[[w]])) nd[[w]] <- factor(nd[[w]], levels = levels(d$bg[[w]]))
    nd$s <- prever(me$maxnet, nd[, me$variaveis, drop = FALSE], me$clamp)
    set.seed(1); rug_p <- data.frame(x = sample(d$pr[[v]], min(600, nrow(d$pr))))
    ggplot(nd, aes(.data[[v]], s)) + geom_line(linewidth = 0.6) +
      geom_rug(data = rug_p, aes(x = x), inherit.aes = FALSE, sides = "b", alpha = 0.25, linewidth = 0.2) +
      scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
      labs(x = NOMES[[v]], y = if (i == 1) "Adequabilidade (cloglog)" else NULL, title = paste0("(", letters[i], ")")) + tema_abnt
  })
  salvar(wrap_plots(ps_, nrow = 1), paste0("F_RESP_", especie), w = min(16, 5.6 * length(ps_) + 1), h = 6)
}

# ---------------- 4) ROC ----------------
fig_roc <- function(especie, ps) {
  r <- read.csv2(file.path(ps$validacao, "04_ROC.csv"))
  auc <- sub(".*AUC = ([0-9.]+).*", "\\1", r$curva)
  r$conj <- ifelse(grepl("^Treino", r$curva), "Treino", ifelse(grepl("cruzada", r$curva), "Validação cruzada", "Teste externo"))
  r$rot <- paste0(r$conj, " (AUC = ", gsub("\\.", ",", auc), ")")
  niv <- unique(r$rot[order(match(r$conj, c("Treino", "Validação cruzada", "Teste externo")))])
  r$rot <- factor(r$rot, levels = niv)
  p <- ggplot(r, aes(fpr, tpr, linetype = rot)) +
    geom_abline(intercept = 0, slope = 1, colour = "grey60", linewidth = 0.3) +
    geom_line(linewidth = 0.55) +
    scale_linetype_manual(values = c("solid", "dashed", "dotted"), name = NULL) +
    coord_equal(expand = FALSE) + scale_x_continuous(labels = function(x) gsub("\\.", ",", x)) +
    scale_y_continuous(labels = function(x) gsub("\\.", ",", x)) +
    labs(x = "1 - Especificidade (taxa de falsos positivos)", y = "Sensibilidade") + tema_abnt +
    theme(legend.position = c(0.62, 0.15), legend.key.width = unit(0.9, "cm"))
  salvar(p, paste0("F_ROC_", especie), w = 9, h = 8.5)
}

# ---------------- 5) mapa de adequabilidade ----------------
fig_mapa <- function(especie, ps) {
  tab <- read.csv2(file.path(PASTA_RESULTADOS, "_geral", "TABELA1_PROPRIEDADES_COM_NOMES.csv"), encoding = "UTF-8")
  chave <- function(s) gsub("[^A-Z0-9]", "_", toupper(iconv(s, "UTF-8", "ASCII//TRANSLIT")))
  tifs <- list.files(file.path(ps$validacao, "mapas"), "_adequabilidade\\.tif$", full.names = TRUE)
  cod <- tab$codigo[match(sub("_adequabilidade\\.tif$", "", basename(tifs)), chave(tab$propriedade))]
  rs <- lapply(tifs, function(f) project(rast(f)[[1]], "EPSG:4674", method = "bilinear"))
  cx <- sapply(rs, function(r) mean(as.vector(ext(r))[1:2]))
  grupo <- cut(cx, c(-Inf, -55, -52, Inf), labels = c("oeste", "centro", "leste"))
  b <- carregar_base_completa(especie); pres <- b$presencas
  lim <- c(0, max(sapply(rs, function(r) global(r, "max", na.rm = TRUE)[[1]])))
  contornos <- do.call(rbind, lapply(seq_along(rs), function(i)
    st_as_sf(as.polygons(rs[[i]] > -1, dissolve = TRUE)) |> st_union() |> st_sf(codigo = cod[i], geometry = _)))
  painel <- function(g, titulo) {
    k <- which(grupo == g); e <- as.vector(Reduce(terra::union, lapply(rs[k], ext)))
    mx <- (e[2] - e[1]) * 0.06; my <- (e[4] - e[3]) * 0.06
    tmpl <- rast(ext(e[1] - mx, e[2] + mx, e[3] - my, e[4] + my), resolution = 0.0006, crs = "EPSG:4674")
    m <- do.call(mosaic, c(lapply(rs[k], function(r) resample(r, tmpl, method = "bilinear")), fun = "max"))
    df <- as.data.frame(m, xy = TRUE, na.rm = TRUE); names(df)[3] <- "s"
    pk <- pres[pres$longitude >= e[1] & pres$longitude <= e[2] & pres$latitude >= e[3] & pres$latitude <= e[4], ]
    cc <- st_coordinates(suppressWarnings(st_point_on_surface(contornos[k, ])))
    ggplot() + geom_raster(data = df, aes(x, y, fill = s)) +
      geom_sf(data = contornos[k, ], fill = NA, colour = "grey25", linewidth = 0.2) +
      ggrepel::geom_text_repel(data = data.frame(x = cc[, 1], y = cc[, 2], l = contornos$codigo[k]),
                               aes(x, y, label = l), size = 1.8, bg.color = "white", bg.r = 0.12,
                               segment.size = 0.2, min.segment.length = 0.3, seed = 2, max.overlaps = 50) +
      scale_fill_gradientn(colours = c("#2C7BB6", "#ABD9E9", "#FFFFBF", "#FDAE61", "#D7191C"), limits = lim,
                           name = "Adequabilidade\n(cloglog)", labels = function(x) gsub("\\.", ",", x)) +
      coord_sf(xlim = c(e[1] - mx, e[2] + mx), ylim = c(e[3] - my, e[4] + my), expand = FALSE) +
      scale_x_continuous(breaks = scales::breaks_pretty(2)) + scale_y_continuous(breaks = scales::breaks_pretty(2)) +
      annotation_scale(location = "bl", width_hint = 0.25, height = unit(0.08, "cm"), text_cex = 0.5) +
      labs(title = titulo, x = NULL, y = NULL) + theme_bw(base_size = 7) +
      theme(panel.grid = element_line(colour = "grey92", linewidth = 0.2), axis.text = element_text(size = 5.5, colour = "black"),
            axis.text.y = element_text(angle = 90, hjust = 0.5), plot.title = element_text(size = 8, face = "bold"))
  }
  p <- (painel("oeste", "(a) Grupo oeste") | (painel("centro", "(b) Grupo central") / painel("leste", "(c) Grupo leste"))) +
    plot_layout(guides = "collect", widths = c(1.25, 1)) &
    theme(legend.position = "bottom", legend.key.width = unit(1.2, "cm"), legend.key.height = unit(0.25, "cm"),
          legend.title = element_text(size = 7, face = "bold"), legend.text = element_text(size = 6))
  p[[1]] <- p[[1]] + annotation_north_arrow(location = "tr", height = unit(0.6, "cm"), width = unit(0.45, "cm"),
                                            style = north_arrow_fancy_orienteering(text_size = 5))
  salvar(p, paste0("F_MAPA_", especie), h = 11)
}

# ---------------- 6) correlação e VIF ----------------
fig_correlacao <- function() {
  d <- dados_busca("roxo")$bg                        # background comum as duas especies (desenvolvimento)
  x <- data.frame(lapply(d[, names(NOMES)], function(z) if (is.factor(z)) as.numeric(as.character(z)) else z))
  pe <- cor(x, method = "pearson"); sp <- cor(x, method = "spearman")
  vif <- usdm::vif(x)
  n <- names(NOMES); g <- expand.grid(a = n, b = n, stringsAsFactors = FALSE)
  g$i <- match(g$a, n); g$j <- match(g$b, n)
  g$r <- ifelse(g$i > g$j, pe[cbind(g$i, g$j)], ifelse(g$i < g$j, sp[cbind(g$i, g$j)], NA))
  g$a <- factor(NOMES[g$a], levels = NOMES); g$b <- factor(NOMES[g$b], levels = rev(NOMES))
  p <- ggplot(g, aes(a, b, fill = r)) + geom_tile(colour = "white") +
    geom_text(aes(label = ifelse(is.na(r), "", fmt(r, 2))), size = 2.4) +
    scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", limits = c(-1, 1), na.value = "grey85",
                         name = "r", labels = function(x) gsub("\\.", ",", x)) +
    labs(x = NULL, y = NULL) + coord_equal() + tema_abnt +
    theme(axis.text.x = element_text(angle = 35, hjust = 1), axis.line = element_blank(), axis.ticks = element_blank())
  salvar(p, "F_CORREL", w = 12, h = 10)
  vt <- data.frame(variavel = NOMES[vif$Variables], VIF = round(vif$VIF, 2),
                   max_abs_r = sapply(vif$Variables, function(v) round(max(abs(c(pe[v, setdiff(n, v)], sp[v, setdiff(n, v)]))), 2)))
  write.csv2(vt, file.path(SAIDA, "TAB_VIF.csv"), row.names = FALSE); print(vt)
}

# ---------------- 7) tabela do teste externo ----------------
tab_externo <- function(especie, ps) {
  c <- read.csv2(file.path(ps$validacao, "01_COMPARACAO_TREINO_VALIDACAO.csv"))
  u <- read.csv2(file.path(ps$validacao, "02_METRICAS_POR_UNIDADE.csv"))
  write.csv2(c, file.path(SAIDA, paste0("TAB_EXTERNO_", especie, ".csv")), row.names = FALSE)
  write.csv2(u, file.path(SAIDA, paste0("TAB_EXTERNO_UNIDADES_", especie, ".csv")), row.names = FALSE)
  print(c); print(u)
}


# ---------------- 8) fluxograma da metodologia ----------------
fig_fluxograma <- function() {
  cx <- 3.4; w <- 3.2                                     # coluna principal (centro, meia largura)
  cx2 <- 9.3; w2 <- 1.9                                   # coluna das reservadas
  passos <- data.frame(
    y = c(10, 8.75, 7.5, 6.25, 5, 3.75, 2.5, 1.25),
    tit = c("Dados brutos", "Preparação", "Divisão das propriedades", "Ambiente disponível e análise descritiva",
            "Seleção do modelo (validação LOPO)", "Grade completa (confirmação)", "Modelo final",
            "Teste externo e produtos"),
    txt = c("Inventários a 100% de 34 propriedades (11.326 indivíduos) | ANADEM, hidrografia, CHELSA e MapBiomas Solo",
            "DAP > 10 cm; uma presença por pixel de 30 m | extração das seis variáveis no QGIS/GDAL",
            "27 propriedades de desenvolvimento (8.680 presenças) | 7 reservadas para o teste externo",
            "Background de 10.000 pontos proporcional à área das UPAs | correlação, VIF e densidade por classe",
            "MaxEnt (maxnet) | 57 combinações → 3 melhores × 15 configurações de features e RM",
            "Todas as 63 combinações das seis variáveis | 63 × 3 features × 5 RM = 945 modelos por espécie",
            "Ajuste com as 27 propriedades de desenvolvimento | Jackknife, curvas de resposta e curva ROC",
            "Avaliação única nas 7 propriedades reservadas | mapas de adequabilidade"))
  caixas <- rbind(transform(passos, x0 = cx - w, x1 = cx + w, h = 0.47, fill = "grey97"),
                  data.frame(y = 7.5, tit = "Propriedades reservadas", txt = "Não utilizadas no ajuste | nem na seleção dos modelos",
                             x0 = cx2 - w2, x1 = cx2 + w2, h = 0.47, fill = "grey88"))
  setas <- data.frame(x = cx, xend = cx, y = passos$y[-8] - 0.47, yend = passos$y[-1] + 0.47)
  p <- ggplot() +
    geom_rect(data = caixas, aes(xmin = x0, xmax = x1, ymin = y - h, ymax = y + h, fill = fill),
              colour = "grey20", linewidth = 0.35) + scale_fill_identity() +
    geom_text(data = caixas, aes(x = (x0 + x1) / 2, y = y + 0.2, label = tit), fontface = "bold", size = 2.55) +
    geom_text(data = caixas, aes(x = (x0 + x1) / 2, y = y - 0.15, label = gsub(" \\| ", "\n", txt)),
              size = 2.05, lineheight = 0.9) +
    geom_segment(data = setas, aes(x, y, xend = xend, yend = yend), linewidth = 0.4,
                 arrow = arrow(length = unit(0.12, "cm"), type = "closed")) +
    # ramo das reservadas: sai da divisao e so volta no teste externo
    annotate("segment", x = cx + w, xend = cx2 - w2, y = 7.5, yend = 7.5, linewidth = 0.4,
             arrow = arrow(length = unit(0.12, "cm"), type = "closed")) +
    annotate("path", x = c(cx2, cx2, cx + w), y = c(7.5 - 0.47, 1.25, 1.25), linewidth = 0.4, linetype = "dashed") +
    annotate("segment", x = cx + w + 0.6, xend = cx + w, y = 1.25, yend = 1.25, linewidth = 0.4,
             arrow = arrow(length = unit(0.12, "cm"), type = "closed")) +
    annotate("text", x = cx2 + 0.15, y = 4.4, label = "usadas uma única vez", angle = 90, size = 2.1, fontface = "italic") +
    coord_cartesian(xlim = c(0, 11.3), ylim = c(0.7, 10.55), expand = FALSE) + theme_void()
  salvar(p, "F_FLUXOGRAMA", w = 16, h = 13)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  if (args[1] == "correlacao") fig_correlacao() else if (args[1] == "fluxo") fig_fluxograma() else {
    e <- args[1]; ps <- tryCatch(pastas_especie(e), error = function(z) NULL)
    so <- if (length(args) > 1) args[-1] else c("dens", "resp", "roc", "tab", "jk", "mapa")
    if ("dens" %in% so) fig_densidade(e); if ("resp" %in% so) fig_resposta(e, ps); if ("roc" %in% so) fig_roc(e, ps)
    if ("tab" %in% so) tab_externo(e, ps); if ("jk" %in% so) fig_jackknife(e, ps); if ("mapa" %in% so) fig_mapa(e, ps)
  }
}
