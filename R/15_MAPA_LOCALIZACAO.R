# 15_MAPA_LOCALIZACAO.R
# Mapa de localizacao das 34 propriedades (Figura 1 do TCC).
# Limites: IBGE (API de malhas v3). Fundo: Esri World Imagery (pacote maptiles).
# Uso (na pasta do projeto): Rscript R/15_MAPA_LOCALIZACAO.R
suppressPackageStartupMessages({
  library(sf); library(terra); library(maptiles); library(ggplot2)
  library(ggspatial); library(patchwork); library(ggrepel)
})
sf_use_s2(FALSE)

RAIZ  <- getwd()
GEOM  <- file.path(RAIZ, "..", "..", "TCC - Ipes - Inicio do zero", "01 - Dados originais",
                   "Dados separados", "Geometrias")
SAIDA <- file.path(RAIZ, "resultados", "_geral", "10_mapa")
IBGE  <- file.path(SAIDA, "ibge"); TILES <- file.path(SAIDA, "tiles")
dir.create(IBGE, recursive = TRUE, showWarnings = FALSE)
dir.create(TILES, recursive = TRUE, showWarnings = FALSE)

baixar <- function(url, arq) {
  f <- file.path(IBGE, arq)
  if (!file.exists(f)) download.file(url, f, mode = "wb", quiet = TRUE)
  f
}
api <- "https://servicodados.ibge.gov.br/api"
uf  <- st_read(baixar(paste0(api, "/v3/malhas/paises/BR?intrarregiao=UF&formato=application/vnd.geo%2Bjson&qualidade=minima"), "br_uf.json"), quiet = TRUE)
mun <- st_read(baixar(paste0(api, "/v3/malhas/estados/15?intrarregiao=municipio&formato=application/vnd.geo%2Bjson&qualidade=intermediaria"), "pa_mun.json"), quiet = TRUE)
st_crs(uf) <- 4674; st_crs(mun) <- 4674
nomes <- jsonlite::fromJSON(baixar(paste0(api, "/v1/localidades/estados/15/municipios"), "pa_mun_nomes.json"))
mun$nome <- nomes$nome[match(mun$codarea, as.character(nomes$id))]
pa <- uf[uf$codarea == "15", ]

# ---------------- propriedades ----------------
tab <- read.csv2(file.path(RAIZ, "resultados", "_geral", "TABELA1_PROPRIEDADES_COM_NOMES.csv"), encoding = "UTF-8")
pastas <- list.dirs(GEOM, recursive = FALSE)
props <- do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
  pasta <- pastas[toupper(basename(pastas)) == toupper(tab$propriedade[i])]
  g <- st_read(list.files(file.path(pasta, "PROPRIEDADE"), "\\.shp$", full.names = TRUE)[1], quiet = TRUE)
  st_sf(codigo = tab$codigo[i], conjunto = tab$conjunto[i], roxo = tab$roxo[i] > 0,
        amarelo = tab$amarelo[i] > 0, geometry = st_union(st_zm(st_transform(g, 4674))))
}))
props$ocorrencia <- factor(ifelse(props$roxo & props$amarelo, "Ambas as espécies",
                           ifelse(props$roxo, "Ipê-roxo", "Ipê-amarelo")),
                           levels = c("Ipê-roxo", "Ipê-amarelo", "Ambas as espécies"))
props$grupo <- factor(ifelse(props$conjunto == "Teste externo", "Teste externo", "Desenvolvimento"))
cent <- suppressWarnings(st_point_on_surface(props))
xy <- st_coordinates(cent); cent$x <- xy[, 1]; cent$y <- xy[, 2]
props$regiao <- cent$regiao <- cut(cent$x, c(-Inf, -55, -52, Inf), labels = c("oeste", "centro", "leste"))
mun_est <- mun[lengths(st_intersects(mun, props)) > 0, ]
write.csv2(data.frame(codigo = props$codigo,
                      municipio = sapply(st_intersects(cent, mun), \(k) paste(mun$nome[k], collapse = "/"))),
           file.path(SAIDA, "PROPRIEDADES_MUNICIPIOS.csv"), row.names = FALSE)

# ---------------- utilidades ----------------
cores <- c("Ipê-roxo" = "#C77DFF", "Ipê-amarelo" = "#FFD60A", "Ambas as espécies" = "#2EF2A0")

caixa <- function(x, m = 0.06, asp = 1) {          # caixa com proporcao fixa (asp = largura/altura)
  b <- st_bbox(x); cx <- mean(b[c(1, 3)]); cy <- mean(b[c(2, 4)])
  w <- (b[[3]] - b[[1]]) / 2 + m; h <- (b[[4]] - b[[2]]) / 2 + m
  if (w / h < asp) w <- h * asp else h <- w / asp
  st_bbox(c(xmin = cx - w, ymin = cy - h, xmax = cx + w, ymax = cy + h), crs = st_crs(4674))
}
fundo <- function(bb, zoom, nome) {                 # imagem de satelite como data.frame RGB
  arq <- file.path(TILES, paste0(nome, ".tif"))
  if (!file.exists(arq)) {
    r <- get_tiles(st_as_sfc(bb), provider = "Esri.WorldImagery", zoom = zoom, crop = TRUE,
                   cachedir = TILES)
    r <- project(r, "EPSG:4674", method = "bilinear")
    if (ncol(r) > 900) r <- aggregate(r, fact = ceiling(ncol(r) / 900))
    writeRaster(r, arq, overwrite = TRUE)
  }
  r <- rast(arq)
  d <- as.data.frame(r, xy = TRUE, na.rm = TRUE)
  d$hex <- rgb(pmin(d[[3]], 255), pmin(d[[4]], 255), pmin(d[[5]], 255), maxColorValue = 255)
  d[, c("x", "y", "hex")]
}
graus <- function(eixo) function(v) {               # 56°20'O / 3°10'S
  h <- if (eixo == "x") ifelse(v < 0, "O", "L") else ifelse(v < 0, "S", "N")
  a <- abs(v); g <- floor(a + 1e-9); m <- round((a - g) * 60)
  ifelse(is.na(v), NA, ifelse(m == 0, sprintf("%d°%s", g, h), sprintf("%d°%02d'%s", g, m, h)))
}
tema <- theme_void(base_size = 8, base_family = "sans") +
  theme(panel.border = element_rect(fill = NA, colour = "grey15", linewidth = 0.5),
        panel.grid.major = element_line(colour = alpha("white", 0.35), linewidth = 0.2, linetype = "dotted"),
        axis.text = element_text(size = 5.5, colour = "grey25"),
        axis.text.y = element_text(angle = 90, hjust = 0.5),
        axis.ticks = element_line(colour = "grey25", linewidth = 0.25),
        axis.ticks.length = unit(0.08, "cm"),
        plot.title = element_text(size = 8, face = "bold", margin = margin(b = 2)),
        plot.margin = margin(3, 4, 3, 4))
escala <- function(loc = "bl") annotation_scale(location = loc, width_hint = 0.2, height = unit(0.09, "cm"),
  text_cex = 0.5, text_col = "white", bar_cols = c("white", "grey20"), line_col = "white",
  pad_x = unit(0.15, "cm"), pad_y = unit(0.15, "cm"))
norte <- function(cor = "white") annotation_north_arrow(location = "tr", height = unit(0.6, "cm"),
  width = unit(0.45, "cm"), pad_x = unit(0.12, "cm"), pad_y = unit(0.12, "cm"),
  style = north_arrow_orienteering(fill = c(cor, "grey20"), line_col = "grey20", text_col = cor, text_size = 5))


# ---------------- estilo "carta" (caixas laterais com faixa de titulo) ----------------
VERDE <- "#DCE8DA"; BORDA <- "grey55"
caixa_tema <- theme(strip.background = element_rect(fill = VERDE, colour = BORDA, linewidth = 0.3),
                    strip.text = element_text(size = 6.5, face = "bold", margin = margin(2, 0, 2, 0)),
                    plot.background = element_rect(fill = "grey98", colour = BORDA, linewidth = 0.3),
                    plot.margin = margin(2, 2, 2, 2))
faixa <- function(txt) facet_wrap(~ rotulo, labeller = as_labeller(function(x) rep(txt, length(x))))
com_rotulo <- function(d) { d$rotulo <- "x"; d }

# ---------------- (b) região de estudo (mapa principal) ----------------
area <- caixa(props, m = 0.2, asp = 2.4)
grp <- do.call(rbind, lapply(levels(props$regiao), function(r)
  st_sf(regiao = r, geometry = st_as_sfc(caixa(props[props$regiao == r, ], m = 0.05, asp = 1.15)))))
grp$rot <- c("c", "d", "e")
grp$xmin <- sapply(st_geometry(grp), function(g) st_bbox(g)[[1]])
grp$ytop <- sapply(st_geometry(grp), function(g) st_bbox(g)[[4]])
f_b <- fundo(area, 8, "regiao_v2")
mun_r <- suppressWarnings(st_crop(mun, area))
rot_mun <- suppressWarnings(st_point_on_surface(st_crop(mun_est, area)))
xy <- st_coordinates(rot_mun); rot_mun$x <- xy[, 1]; rot_mun$y <- xy[, 2]
b <- ggplot() +
  geom_raster(data = f_b, aes(x, y, fill = hex)) + scale_fill_identity() +
  geom_sf(data = mun_r, fill = NA, colour = alpha("white", 0.5), linewidth = 0.2, linetype = "dashed") +
  geom_sf(data = grp, fill = NA, colour = "red", linewidth = 0.5) +
  geom_label(data = grp, aes(xmin, ytop, label = rot), colour = "white", fill = "red", size = 2.4,
             fontface = "bold", label.size = 0, label.padding = unit(0.06, "cm"), hjust = 0, vjust = 1,
             label.r = unit(0, "cm")) +
  geom_point(data = cent, aes(x, y, colour = ocorrencia), size = 0.7, show.legend = FALSE) +
  geom_text_repel(data = rot_mun, aes(x, y, label = toupper(nome)), size = 1.9, colour = "white",
                  fontface = "bold", bg.color = "grey15", bg.r = 0.12, seed = 3, segment.color = NA, force = 0.5) +
  annotate("text", x = -54.75, y = -2.1, label = "Rio Amazonas", colour = "#BFE3FF", size = 1.9, fontface = "italic", angle = 8) +
  annotate("text", x = -55.2, y = -3.25, label = "Rio Tapajós", colour = "#BFE3FF", size = 1.9, fontface = "italic", angle = 72) +
  annotate("text", x = area[[1]] + 0.06, y = area[[2]] + 0.07, label = "IMAGEM: ESRI WORLD IMAGERY",
           hjust = 0, vjust = 0, size = 1.8, colour = "white", fontface = "bold") +
  scale_colour_manual(values = cores) +
  coord_sf(xlim = area[c(1, 3)], ylim = area[c(2, 4)], expand = FALSE, label_axes = "ENEN") +
  scale_x_continuous(breaks = seq(-56, -51, 1), labels = graus("x")) +
  scale_y_continuous(breaks = seq(-5, 0, 1), labels = graus("y")) +
  annotation_scale(location = "br", width_hint = 0.2, height = unit(0.09, "cm"), text_cex = 0.5,
                   text_col = "white", bar_cols = c("white", "grey20"), line_col = "white") +
  labs(title = "(b) Região de estudo") + tema

# ---------------- (c–e) grupos ----------------
painel <- function(r, titulo, zoom, m = 0.05, loc = "bl") {
  bb <- caixa(props[props$regiao == r, ], m = m, asp = 1.15)
  f <- fundo(bb, zoom, paste0("grupo_", r, "_", m))
  mr <- suppressWarnings(st_crop(mun, bb))
  ggplot() +
    geom_raster(data = f, aes(x, y, fill = hex)) + scale_fill_identity() +
    geom_sf(data = mr, fill = NA, colour = alpha("white", 0.6), linewidth = 0.25, linetype = "dashed") +
    geom_sf(data = props, aes(colour = ocorrencia, linetype = grupo), fill = NA, linewidth = 0.5,
            key_glyph = "path") +
    geom_text_repel(data = cent[cent$regiao == r, ], aes(x, y, label = codigo), size = 1.8,
                    colour = "white", fontface = "bold", bg.color = "grey10", bg.r = 0.15,
                    min.segment.length = 0.3, segment.colour = "white", segment.size = 0.25,
                    box.padding = 0.2, max.overlaps = 50, seed = 4) +
    scale_colour_manual(values = cores, name = "Ocorrência", drop = FALSE) +
    scale_linetype_manual(values = c("Desenvolvimento" = "solid", "Teste externo" = "22"),
                          name = "Conjunto de dados", drop = FALSE) +
    coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], expand = FALSE) +
    scale_x_continuous(breaks = scales::breaks_pretty(2), labels = graus("x")) +
    scale_y_continuous(breaks = scales::breaks_pretty(2), labels = graus("y")) +
    escala(loc) + labs(title = titulo) + tema + theme(plot.title = element_text(size = 7, face = "bold"))
}
c_ <- painel("oeste",  "(c) Grupo oeste",   10, m = 0.09, loc = "bl")
d  <- painel("centro", "(d) Grupo central", 11)
e  <- painel("leste",  "(e) Grupo leste",   10)

# ---------------- coluna lateral ----------------
a <- ggplot() +
  geom_sf(data = com_rotulo(uf), fill = "white", colour = "grey55", linewidth = 0.15) +
  geom_sf(data = com_rotulo(pa), fill = "#A9C8A4", colour = "grey25", linewidth = 0.3) +
  geom_sf(data = com_rotulo(st_sf(geometry = st_as_sfc(area))), fill = NA, colour = "red", linewidth = 0.4) +
  annotate("text", x = -52.5, y = -6.6, label = "PARÁ", size = 1.9, fontface = "bold", colour = "grey20") +
  annotate("text", x = -47, y = -19, label = "BRASIL", size = 1.9, colour = "grey40") +
  annotate("text", x = -40.5, y = -29, label = "Oceano\nAtlântico", size = 1.6, colour = "#5A8BB0", fontface = "italic") +
  coord_sf(xlim = c(-74.5, -34), ylim = c(-34, 5.5), expand = FALSE) +
  theme_void(base_size = 7) +
  theme(panel.background = element_rect(fill = "#E6F0F7", colour = BORDA, linewidth = 0.3))

res <- do.call(rbind, lapply(levels(props$regiao), function(r) {
  k <- props$regiao == r
  mm <- sort(unique(sapply(st_intersects(cent[k, ], mun), function(i) mun$nome[i[1]])))
  data.frame(Grupo = c(oeste = "Oeste", centro = "Central", leste = "Leste")[[r]],
             Municipios = paste(mm, collapse = "\n"), Prop = sum(k),
             Roxo = sum(props$roxo[k]), Amarelo = sum(props$amarelo[k]))
}))
res <- rbind(res, data.frame(Grupo = "Total", Municipios = "", Prop = sum(res$Prop),
                             Roxo = sum(res$Roxo), Amarelo = sum(res$Amarelo)))
alt <- c(3, 1, 1, 1)                                   # linhas de texto por grupo
yy <- -cumsum(alt) + alt / 2
cab <- c("Grupo", "Municípios", "Prop.", "Roxo", "Amar.")
xs <- c(0.03, 0.25, 0.64, 0.78, 0.92); hj <- c(0, 0, 0.5, 0.5, 0.5)
lin <- do.call(rbind, lapply(seq_len(nrow(res)), function(i)
  data.frame(x = xs, y = yy[i], hj = hj, txt = c(res$Grupo[i], res$Municipios[i], res$Prop[i],
                                                 res$Roxo[i], res$Amarelo[i]),
             ff = ifelse(res$Grupo[i] == "Total", "bold", "plain"))))
lin$rotulo <- "x"
tabela <- ggplot(lin) +
  annotate("text", x = xs, y = 0.7, label = cab, hjust = hj, size = 1.6, fontface = "bold") +
  geom_text(aes(x, y, label = txt, hjust = hj, fontface = ff), size = 1.65, lineheight = 0.85) +
  geom_hline(yintercept = c(1.3, 0.1, -sum(alt[1:3])), linewidth = 0.25, colour = "grey30") +
  geom_hline(yintercept = -sum(alt), linewidth = 0.25, colour = "grey30") +
  scale_x_continuous(limits = c(0, 1)) + scale_y_continuous(limits = c(-sum(alt) - 0.2, 1.5)) +
  theme_void(base_size = 7)

rodape <- ggplot(data.frame(rotulo = "x", x = 0.5, y = 0.3)) + xlim(0, 1) + ylim(0, 1) +
  geom_text(aes(x = 0.6, y = 0.5), size = 1.6, lineheight = 0.95, colour = "grey15",
            label = "Sistema de coordenadas geográficas\nDatum: SIRGAS 2000 (EPSG:4674)\nUnidade: graus\nLimites: IBGE (2024)") +
  annotation_north_arrow(location = "bl", height = unit(0.75, "cm"), width = unit(0.5, "cm"),
                         pad_x = unit(0.2, "cm"), pad_y = unit(0.15, "cm"), style = north_arrow_fancy_orienteering(text_size = 4.5)) +
  theme_void(base_size = 7)

# ---------------- montagem tipo compositor de impressao (posicoes absolutas) ----------------
library(cowplot)
leg_plot <- c_ + guides(colour = guide_legend(order = 1, ncol = 1, override.aes = list(linewidth = 0.9)),
                        linetype = guide_legend(order = 2, ncol = 1, override.aes = list(colour = "grey15", linewidth = 0.6))) +
  theme(legend.position = "right", legend.box.just = "left", legend.title = element_text(size = 5.8, face = "bold"),
        legend.text = element_text(size = 5.6), legend.key = element_rect(fill = "grey98", colour = NA),
        legend.background = element_rect(fill = "grey98", colour = NA),
        legend.key.width = unit(0.5, "cm"), legend.key.height = unit(0.24, "cm"), legend.spacing.y = unit(0.05, "cm"))
legenda <- get_plot_component(leg_plot, "guide-box-right", return_all = TRUE)
sem_leg <- theme(legend.position = "none")

caixa_lateral <- function(y0, y1, titulo, x0 = 0.748, x1 = 0.995, hcab = 0.042) list(
  draw_grob(grid::rectGrob(gp = grid::gpar(fill = "grey98", col = BORDA, lwd = 0.7)), x0, y0, x1 - x0, y1 - y0),
  draw_grob(grid::rectGrob(gp = grid::gpar(fill = VERDE, col = BORDA, lwd = 0.7)), x0, y1 - hcab, x1 - x0, hcab),
  draw_label(titulo, x = (x0 + x1) / 2, y = y1 - hcab / 2, size = 6.3, fontface = "bold"))
dentro <- function(p, y0, y1, x0 = 0.752, x1 = 0.991, hcab = 0.042) draw_plot(p, x0, y0 + 0.004, x1 - x0, y1 - y0 - hcab - 0.008)

fig <- ggdraw() +
  draw_plot(b + sem_leg, 0, 0.40, 0.735, 0.60) +
  draw_plot(c_ + sem_leg, 0.000, 0, 0.245, 0.40) +
  draw_plot(d  + sem_leg, 0.245, 0, 0.245, 0.40) +
  draw_plot(e  + sem_leg, 0.490, 0, 0.245, 0.40) +
  caixa_lateral(0.655, 0.99, "(a) LOCALIZAÇÃO NO BRASIL") + dentro(a, 0.655, 0.99) +
  caixa_lateral(0.425, 0.645, "PROPRIEDADES POR GRUPO") + dentro(tabela, 0.425, 0.645) +
  caixa_lateral(0.175, 0.415, "LEGENDA") + draw_grob(legenda, 0.752, 0.18, 0.239, 0.19) +
  caixa_lateral(0.01, 0.165, "REFERÊNCIA ESPACIAL") + dentro(rodape, 0.01, 0.165)
ggsave(file.path(SAIDA, "FIGURA1_LOCALIZACAO.png"), fig, width = 16, height = 9.9, units = "cm",
       dpi = 300, bg = "white")
cat("ok
")
