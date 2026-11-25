# ================================================================
# TCC - DISTRIBUICAO DOS IPES
# SCRIPT R 01 - ESTATISTICAS AMBIENTAIS DAS PRESENCAS DE DESENVOLVIMENTO (V3)
# ================================================================
#
# OBJETIVO
#   Descrever as arvores registradas nos inventarios e suas variaveis
#   ambientais, usando as camadas geradas pelo Script 10 do QGIS.
#
# ENTRADAS (somente leitura)
#   03 - Trabalho no QGIS/02 - Arquivos gerados/
#       Pontos com variaveis/*.gpkg
#   Camada interna de cada arquivo: arvores_com_variaveis
#
# SAIDAS
#   06 - Resultados/01 - Estatisticas dos inventarios/
#       7 tabelas CSV, graficos PNG, resumo TXT e versoes do R.
#       Se o pacote writexl estiver instalado, cria tambem um Excel.
#
# IMPORTANTE
#   - Este script NAO altera os GeoPackages nem os rasters do QGIS.
#   - Requer particao APROVADA do R02 V3. Somente desenvolvimento nas estatisticas.
#   - DAP estritamente >10 cm; os quatro menores permanecem nas fontes.
#   - A textura e uma CLASSE; nao calculamos media da textura.
#   - As duas distancias sao descritas, mas o MaxEnt usara apenas
#     dist_rio_raster_m, a distancia extraida do raster de 30 m.
#   - BIO12 e BIO17 sao descritas como variaveis distintas; para
#     MaxEnt, podemos comparar modelos alternativos com cada uma.
#   - Estas estatisticas descrevem as PRESENCAS, nao preferencias.
#
# COMO USAR
#   1. Abra este arquivo no RStudio e clique em Source.
#   2. Na janela, escolha UM arquivo .gpkg da pasta
#      "Pontos com variaveis" (qualquer uma das 34 propriedades).
#   3. O script localiza o TCC automaticamente, le os 34 arquivos
#      e salva os resultados na pasta 06 - Resultados.
# ================================================================

# 1 - CONFERIR BIBLIOTECA -----------------------------------------
for (pacote in c("terra", "ggplot2", "writexl")) {
  if (!requireNamespace(pacote, quietly = TRUE)) {
    stop("Falta o pacote '", pacote,
         "'. Execute install.packages(c('terra','ggplot2','writexl')) no RStudio.")
  }
}

# 2 - LOCALIZAR O PROJETO ------------------------------------------
cat("\nSCRIPT R 01 - ESTATISTICAS DOS IPES\n")
cat("Escolha UM arquivo .gpkg da pasta 'Pontos com variaveis'.\n")
arquivo_selecionado <- normalizePath(file.choose(), winslash = "/", mustWork = TRUE)

buscar_raiz <- function(caminho) {
  pasta <- dirname(caminho)
  repeat {
    tem_qgis <- dir.exists(file.path(pasta, "03 - Trabalho no QGIS"))
    tem_r <- dir.exists(file.path(pasta, "05 - Modelagem no R"))
    if (tem_qgis && tem_r) return(pasta)
    anterior <- dirname(pasta)
    if (identical(anterior, pasta)) {
      stop("Nao encontrei a pasta principal do TCC. Escolha um GeoPackage de dentro do projeto.")
    }
    pasta <- anterior
  }
}

raiz <- buscar_raiz(arquivo_selecionado)

# LEGENDA OFICIAL: MapBiomas Solo C3, subgrupo textural 0-30 cm.
# Nunca inferir as classes pelo valor numerico sozinho.
caminho_legenda <- file.path(raiz, "02 - Fontes ambientais", "MapBiomas Solo",
                              "LEGENDA_MapBiomas_Solo_C3_Subgrupo_0_30cm.csv")
if (!file.exists(caminho_legenda)) {
  stop("Falta a legenda oficial na pasta de fontes ambientais: ", caminho_legenda)
}
legenda_solo <- read.csv2(caminho_legenda, fileEncoding="UTF-8-BOM",
                          stringsAsFactors=FALSE, check.names=FALSE)
colunas_legenda <- c("codigo", "classe", "descricao", "cor_hex")
if (!all(colunas_legenda %in% names(legenda_solo))) {
  stop("Arquivo da legenda sem as colunas: ",
       paste(setdiff(colunas_legenda, names(legenda_solo)), collapse=", "))
}
legenda_solo$codigo <- as.integer(legenda_solo$codigo)
if (nrow(legenda_solo)!=9L ||
    anyNA(legenda_solo$codigo) ||
    !setequal(legenda_solo$codigo, 1:9) ||
    anyDuplicated(legenda_solo$codigo)) {
  stop("Legenda incorreta: devem existir os codigos de 1 a 9 sem repeticoes.")
}
legenda_solo <- legenda_solo[order(legenda_solo$codigo), , drop=FALSE]
entrada <- file.path(raiz, "03 - Trabalho no QGIS", "02 - Arquivos gerados",
                     "Pontos com variaveis")
saida_final <- file.path(raiz, "06 - Resultados", "01 - Estatisticas dos inventarios - V3")
saida_temp <- file.path(raiz, "06 - Resultados", "_Estatisticas_em_andamento")

if (!dir.exists(entrada)) stop("Pasta de entrada nao encontrada: ", entrada)
if (normalizePath(dirname(arquivo_selecionado), winslash = "/") !=
    normalizePath(entrada, winslash = "/")) {
  stop("Escolha um .gpkg diretamente da pasta 'Pontos com variaveis'.")
}
if (dir.exists(saida_final)) {
  stop("Ja existe uma analise anterior em: ", saida_final,
       "\nPara preservar os resultados, renomeie essa pasta antes de executar novamente.")
}
if (dir.exists(saida_temp)) {
  stop("Existe uma pasta de execucao incompleta: ", saida_temp,
       "\nConfira seu conteudo antes de renomear/remover essa pasta.")
}

arquivos <- sort(list.files(entrada, pattern = "\\.gpkg$", full.names = TRUE,
                            ignore.case = TRUE))
if (length(arquivos) != 34L) {
  stop("Esperados 34 GeoPackages do Script 10. Encontrados: ", length(arquivos))
}

# 3 - LER AS ARVORES (SEM MODIFICAR AS FONTES) ---------------------
variaveis <- c("altitude_m", "declividade_graus", "dist_rio_raster_m",
               "dist_rio_vetorial_m", "bio12_mm_ano", "bio17_mm_mes")
obrigatorios <- c("linha_csv", "textura_subgrupo", "dap_cm_num", "elegivel_dap_gt10", variaveis)

numero <- function(x) {
  # Os valores nos GeoPackages costumam ser numericos, mas esta
  # conversao tambem aceita textos que usam virgula decimal.
  suppressWarnings(as.numeric(gsub(",", ".", as.character(x), fixed = TRUE)))
}

identificar_especie <- function(tabela) {
  n <- nrow(tabela)
  cientifico <- if ("nome_cientifico" %in% names(tabela)) {
    tolower(as.character(tabela$nome_cientifico))
  } else rep("", n)
  vulgar <- if ("nome_vulgar" %in% names(tabela)) {
    tolower(as.character(tabela$nome_vulgar))
  } else rep("", n)
  cientifico[is.na(cientifico)] <- ""
  vulgar[is.na(vulgar)] <- ""

  classe <- rep(NA_character_, n)
  classe[grepl("impetiginosus", cientifico) | grepl("roxo", vulgar)] <- "Ipe-roxo"
  classe[grepl("serratifolius", cientifico) | grepl("amarelo", vulgar)] <- "Ipe-amarelo"
  if (anyNA(classe)) {
    stop("Ha ", sum(is.na(classe)),
         " arvores sem especie reconhecida. Confira nome_cientifico e nome_vulgar.")
  }
  classe
}

ler_propriedade <- function(caminho) {
  nome_propriedade <- tools::file_path_sans_ext(basename(caminho))
  camada <- tryCatch(terra::vect(caminho, layer = "arvores_com_variaveis"),
                     error = function(e) stop("Nao abriu ", caminho, ": ", conditionMessage(e)))
  tabela <- as.data.frame(camada)  # Apenas a tabela de atributos (sem geometrias)
  faltam <- setdiff(obrigatorios, names(tabela))
  if (length(faltam) > 0) {
    stop("Faltam campos em ", nome_propriedade, ": ", paste(faltam, collapse = ", "))
  }
  if (!"upa" %in% names(tabela)) {
    stop("Falta o campo 'upa' em ", nome_propriedade)
  }
  if (!any(c("nome_cientifico", "nome_vulgar") %in% names(tabela))) {
    stop("Falta identificacao da especie em ", nome_propriedade)
  }
  tabela$propriedade <- nome_propriedade
  tabela$especie <- identificar_especie(tabela)
  tabela$upa <- as.character(tabela$upa)
  tabela$linha_csv <- as.character(tabela$linha_csv)
  tabela$dap_cm_num <- numero(tabela$dap_cm_num)
  tabela$elegivel_dap_gt10 <- numero(tabela$elegivel_dap_gt10)
  if(any(!is.finite(tabela$dap_cm_num)) ||
     any(tabela$elegivel_dap_gt10 != as.integer(tabela$dap_cm_num>10)))
    stop('Campo DAP ou indicador incoerente em ',nome_propriedade)
  # Confere o nome que veio do QGIS e usa a tabela OFICIAL como referencia.
  nomes_gpkg <- if ("textura_nome" %in% names(tabela)) as.character(tabela$textura_nome) else NULL
  for (col in c(variaveis, "textura_subgrupo")) tabela[[col]] <- numero(tabela[[col]])
  cod <- tabela$textura_subgrupo
  if (anyNA(cod) || any(!is.finite(cod)) || any(cod != floor(cod)) ||
      any(!cod %in% legenda_solo$codigo)) {
    stop("Codigo textural invalido em ", nome_propriedade)
  }
  ix <- match(as.integer(cod), legenda_solo$codigo)
  tabela$textura_nome <- legenda_solo$classe[ix]
  tabela$textura_descricao <- legenda_solo$descricao[ix]
  if (!is.null(nomes_gpkg) &&
      any(is.na(nomes_gpkg) | nomes_gpkg != tabela$textura_nome)) {
    stop("A legenda dos pontos nao corresponde a legenda oficial em ", nome_propriedade,
         ". Execute o Script 10 corrigido do QGIS primeiro.")
  }
  cat(sprintf("[LEITURA] %-24s %5d arvores\n", nome_propriedade, nrow(tabela)))
  tabela
}

partes <- lapply(arquivos, ler_propriedade)
arvores <- do.call(rbind, partes)
row.names(arvores) <- NULL

if (nrow(arvores) != 11326L) {
  stop("A contagem nao corresponde ao inventario esperado: ", nrow(arvores),
       " (esperado: 11.326). Nao foram geradas estatisticas.")
}
if (length(unique(arvores$propriedade)) != 34L) stop("Numero incorreto de propriedades.")
# O inventario bruto serve exclusivamente para QA. NENHUMA estatistica
# ambiental que possa influenciar calibracao usa as propriedades de TESTE.
arvores_brutas <- arvores
arvores_elegiveis <- arvores_brutas[arvores_brutas$dap_cm_num>10,,drop=FALSE]
if (nrow(arvores_elegiveis)!=11322L ||
    sum(arvores_elegiveis$especie=='Ipe-roxo')!=5377L ||
    sum(arvores_elegiveis$especie=='Ipe-amarelo')!=5945L)
  stop('Conferencia DAP>10 falhou. Revisar dados e regra de inclusao.')
part_arquivo <- file.path(raiz, '04 - Dados para o MaxEnt',
  '03 - Background V3', '02_PARTICAO_APROVADA.csv')
if(!file.exists(part_arquivo))
  stop('R01 V3 exige particao aprovada do R02 V3 antes da analise ambiental.')
part <- read.csv2(part_arquivo,fileEncoding='UTF-8',stringsAsFactors=FALSE)
if(nrow(part)!=34 || anyDuplicated(part$propriedade) ||
   !all(part$conjunto %in% c('TESTE','DESENVOLVIMENTO')))
  stop('Particao V3 inconsistente.')
devel <- part$propriedade[part$conjunto=='DESENVOLVIMENTO']
arvores <- arvores_elegiveis[arvores_elegiveis$propriedade %in% devel,,drop=FALSE]
if(!nrow(arvores))stop('Sem arvores elegiveis de desenvolvimento.')
cat('[QA] ',nrow(arvores_brutas),' brutas; ',nrow(arvores_elegiveis),
    ' DAP>10; ',nrow(arvores),' para estatisticas ambientais de desenvolvimento.\n',sep='')

# 4 - DEFINIR FUNCOES DE ESTATISTICA -------------------------------
resumo <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(data.frame(n_validos=0L, minimo=NA_real_, q1=NA_real_,
                      mediana=NA_real_, media=NA_real_, q3=NA_real_,
                      maximo=NA_real_, desvio_padrao=NA_real_))
  }
  quartis <- as.numeric(quantile(x, probs = c(.25, .75), na.rm=TRUE, names=FALSE))
  data.frame(n_validos=length(x), minimo=min(x), q1=quartis[1],
             mediana=median(x), media=mean(x), q3=quartis[2],
             maximo=max(x), desvio_padrao=if (length(x)>1L) sd(x) else NA_real_)
}

tabela_estatisticas <- function(tabela, tipo, identificacao) {
  partes <- lapply(variaveis, function(nome) {
    cbind(data.frame(grupo=tipo, identificacao=identificacao, variavel=nome),
          resumo(tabela[[nome]]))
  })
  do.call(rbind, partes)
}

salvar <- function(df, arquivo) {
  # CSV com ponto e virgula e virgula decimal: abre bem no Excel em PT-BR.
  write.csv2(df, arquivo, row.names=FALSE, na="", fileEncoding="UTF-8")
}

# 5 - CONTAGEM DE ARVORES POR ESPECIE, PROPRIEDADE E UPA -----------
contagem <- as.data.frame(table(arvores$propriedade, arvores$especie),
                          stringsAsFactors=FALSE)
names(contagem) <- c("propriedade", "especie", "n_arvores")
contagem <- contagem[contagem$n_arvores > 0, ]

por_upa <- as.data.frame(table(arvores$propriedade, arvores$upa, arvores$especie),
                         stringsAsFactors=FALSE)
names(por_upa) <- c("propriedade", "upa", "especie", "n_arvores")
por_upa <- por_upa[por_upa$n_arvores > 0, ]
# Obs.: UPAs sem arvores nao aparecem na contagem e devem ser consultadas
# nos poligonos censitados, caso seja necessario contar zeros.

# 6 - DESCRICAO DAS VARIAVEIS AMBIENTAIS --------------------------
resumos <- list(tabela_estatisticas(arvores, "Geral", "Todas as arvores"))
for (e in sort(unique(arvores$especie))) {
  resumos[[length(resumos)+1L]] <- tabela_estatisticas(
    arvores[arvores$especie == e, , drop=FALSE], "Especie", e)
}
for (p in sort(unique(arvores$propriedade))) {
  fatia <- arvores[arvores$propriedade == p, , drop=FALSE]
  resumos[[length(resumos)+1L]] <- tabela_estatisticas(fatia, "Propriedade", p)
  for (e in sort(unique(fatia$especie))) {
    resumos[[length(resumos)+1L]] <- tabela_estatisticas(
      fatia[fatia$especie == e, , drop=FALSE], "Propriedade e especie",
      paste(p, e, sep=" | "))
  }
}
estatisticas <- do.call(rbind, resumos)
row.names(estatisticas) <- NULL

# 7 - FREQUENCIA DAS CLASSES DE SOLO -------------------------------
solo <- arvores[is.finite(arvores$textura_subgrupo),
                c("propriedade", "especie", "textura_subgrupo"), drop=FALSE]
solo$classe <- as.integer(solo$textura_subgrupo)
frequencia_solo <- aggregate(rep(1L,nrow(solo)),
                            by=list(propriedade=solo$propriedade,
                                    especie=solo$especie, classe=solo$classe), FUN=sum)
names(frequencia_solo)[4] <- "n_arvores"
totais_pe <- aggregate(n_arvores~propriedade+especie, data=frequencia_solo, FUN=sum)
names(totais_pe)[3] <- "total_da_especie_na_propriedade"
frequencia_solo <- merge(frequencia_solo, totais_pe, by=c("propriedade","especie"))
frequencia_solo$percentual <- 100 * frequencia_solo$n_arvores /
                                     frequencia_solo$total_da_especie_na_propriedade
frequencia_solo <- frequencia_solo[order(frequencia_solo$propriedade,
                              frequencia_solo$especie,frequencia_solo$classe), ]
ix_solo <- match(frequencia_solo$classe, legenda_solo$codigo)
frequencia_solo$nome_classe <- legenda_solo$classe[ix_solo]
frequencia_solo$descricao <- legenda_solo$descricao[ix_solo]

# Frequencia GLOBAL dentro de cada especie (denominador: total de arvores
# de cada especie, NAO area de UPA e NAO disponibilidade ambiental).
solo_geral <- as.data.frame(table(especie=arvores$especie,
                                   codigo=arvores$textura_subgrupo),
                            stringsAsFactors=FALSE)
solo_geral <- solo_geral[solo_geral$Freq > 0, , drop=FALSE]
solo_geral$codigo <- as.integer(as.character(solo_geral$codigo))
names(solo_geral)[names(solo_geral)=="Freq"] <- "n_arvores"
solo_geral$nome_classe <- legenda_solo$classe[match(solo_geral$codigo, legenda_solo$codigo)]
solo_geral$cor_hex <- legenda_solo$cor_hex[match(solo_geral$codigo, legenda_solo$codigo)]
totais_especie <- table(arvores$especie)
solo_geral$percentual <- 100 * solo_geral$n_arvores / as.numeric(totais_especie[as.character(solo_geral$especie)])
solo_geral <- solo_geral[order(solo_geral$especie, solo_geral$codigo), , drop=FALSE]


# 8 - CONFERIR DISTANCIA VETORIAL X RASTER ------------------------
arvores$diferenca_absoluta_m <- abs(arvores$dist_rio_raster_m - arvores$dist_rio_vetorial_m)
resumos_diferenca <- list()
for (p in sort(unique(arvores$propriedade))) {
  for (e in sort(unique(arvores$especie))) {
    fatia <- arvores[arvores$propriedade==p & arvores$especie==e, , drop=FALSE]
    if (nrow(fatia) == 0L) next
    resumos_diferenca[[length(resumos_diferenca)+1L]] <- cbind(
      data.frame(propriedade=p, especie=e), resumo(fatia$diferenca_absoluta_m))
  }
}
comparacao_distancias <- do.call(rbind, resumos_diferenca)

# 9 - CORRELACOES EXPLORATORIAS ------------------------------------
# A textura nao entra aqui, porque e categórica.
# BIO12 e BIO17 sao incluidos para investigar a relacao entre ambas;
# isso NAO significa que serao usadas juntas no MaxEnt.
preditores_numericos <- c("altitude_m", "declividade_graus", "dist_rio_raster_m",
                          "bio12_mm_ano", "bio17_mm_mes")
combinacoes <- combn(preditores_numericos, 2, simplify=FALSE)
linhas_corr <- list()
for (especie in sort(unique(arvores$especie))) {
  fatia <- arvores[arvores$especie == especie, , drop=FALSE]
  for (par in combinacoes) {
    x <- fatia[[par[1]]]
    y <- fatia[[par[2]]]
    validos <- is.finite(x) & is.finite(y)
    n <- sum(validos)
    r <- if (n >= 3L && sd(x[validos]) > 0 && sd(y[validos]) > 0) {
      cor(x[validos],y[validos], method="pearson")
    } else NA_real_
    linhas_corr[[length(linhas_corr)+1L]] <- data.frame(
      especie=especie, variavel_1=par[1], variavel_2=par[2],
      n_pares=n, correlacao_pearson=r,
      observacao=if (!is.na(r) && abs(r) >= .7) "Investigar correlacao" else "")
  }
}
correlacoes <- do.call(rbind,linhas_corr)

# 10 - CONFERENCIA DOS DADOS ---------------------------------------
conferencias <- list()
for (p in sort(unique(arvores$propriedade))) {
  fatia <- arvores[arvores$propriedade==p, , drop=FALSE]
  qtd_duplicados <- sum(duplicated(fatia$linha_csv) | is.na(fatia$linha_csv))
  valores_ausentes <- sum(!is.finite(as.matrix(fatia[,variaveis,drop=FALSE])))
  classe_invalida <- sum(!is.finite(fatia$textura_subgrupo) |
                          fatia$textura_subgrupo != floor(fatia$textura_subgrupo) |
                          !(fatia$textura_subgrupo %in% 1:9))
  negativos <- sum((is.finite(fatia$dist_rio_raster_m) & fatia$dist_rio_raster_m < 0) |
                   (is.finite(fatia$dist_rio_vetorial_m) & fatia$dist_rio_vetorial_m < 0) |
                   (is.finite(fatia$declividade_graus) & fatia$declividade_graus < 0), na.rm=TRUE)
  declividade_extrema <- sum(is.finite(fatia$declividade_graus) &
                               fatia$declividade_graus > 90, na.rm=TRUE)
  conferencias[[length(conferencias)+1L]] <- data.frame(
    propriedade=p, n_arvores=nrow(fatia), duplicados_linha_csv=qtd_duplicados,
    valores_numericos_ausentes=valores_ausentes,
    classes_solo_invalidas=classe_invalida, distancias_ou_declividade_negativas=negativos,
    declividade_maior_que_90_graus=declividade_extrema)
}
qualidade <- do.call(rbind,conferencias)

# 11 - ESCREVER RESULTADOS (SEM SOBRESCREVER ANALISE ANTERIOR) -----
dir.create(saida_temp, recursive=TRUE, showWarnings=FALSE)
dir.create(file.path(saida_temp,"Graficos"), showWarnings=FALSE)

salvar(contagem, file.path(saida_temp,"01_Arvores_por_propriedade.csv"))
salvar(por_upa, file.path(saida_temp,"02_Arvores_por_UPA.csv"))
salvar(data.frame(estado=c('bruto','DAP_maior_10','desenvolvimento_DAP_maior_10'),
 n=c(nrow(arvores_brutas),nrow(arvores_elegiveis),nrow(arvores))),
 file.path(saida_temp,'00_CONFERENCIA_FILTRO_E_PARTICAO.csv'))
salvar(estatisticas, file.path(saida_temp,"03_Estatisticas_ambientais.csv"))
salvar(frequencia_solo, file.path(saida_temp,"04_Classes_de_solo.csv"))
salvar(comparacao_distancias, file.path(saida_temp,"05_Comparacao_distancias.csv"))
salvar(correlacoes, file.path(saida_temp,"06_Correlacoes.csv"))
salvar(qualidade, file.path(saida_temp,"07_Conferencia_dos_dados.csv"))
salvar(legenda_solo, file.path(saida_temp, "Solo_Legenda_Oficial.csv"))
salvar(solo_geral, file.path(saida_temp, "Solo_Resumo_Por_Especie.csv"))

# Excel com as tabelas anteriores + legenda oficial + resumo por especie.
writexl::write_xlsx(list(
  "Arvores por propriedade"=contagem,
  "Arvores por UPA"=por_upa,
  "Estatisticas ambientais"=estatisticas,
  "Classes de solo"=frequencia_solo,
  "Solo por especie"=solo_geral,
  "Legenda oficial solo"=legenda_solo,
  "Distancias aos rios"=comparacao_distancias,
  "Correlacoes"=correlacoes,
  "Conferencia"=qualidade),
  path=file.path(saida_temp,"Resumo_estatistico_dos_ipes.xlsx"))

# 12 - GRAFICOS CIENTIFICOS (PNG 300 DPI + PDF) --------------------
# Graficos descritivos sem testes de significancia: os registros sao
# espacialmente agrupados e nao devem ser tratados como replicacoes
# independentes na comparacao entre especies.

cores_especies <- c("Ipe-roxo"="#0072B2", "Ipe-amarelo"="#D55E00")
nomes_especies <- c("Ipe-roxo"="Ipê-roxo", "Ipe-amarelo"="Ipê-amarelo")

# Fonte legivel, unidades em portugues, grade horizontal discreta.
tema_tcc <- function() {
  ggplot2::theme_minimal(base_size=13, base_family="sans") +
    ggplot2::theme(
      plot.title=ggplot2::element_text(face="bold", size=16, margin=ggplot2::margin(b=7)),
      plot.subtitle=ggplot2::element_text(size=11, color="#3C4850", margin=ggplot2::margin(b=10)),
      plot.caption=ggplot2::element_text(size=9, color="#626D75", hjust=0),
      panel.grid.major.x=ggplot2::element_blank(),
      panel.grid.minor=ggplot2::element_blank(),
      axis.title=ggplot2::element_text(size=12),
      axis.text=ggplot2::element_text(size=11),
      strip.text=ggplot2::element_text(face="bold", size=12),
      legend.position="bottom",
      legend.title=ggplot2::element_blank(),
      plot.margin=ggplot2::margin(12,16,12,12)
    )
}

salvar_figura <- function(grafico, nome, largura=10, altura=6.6) {
  destino <- file.path(saida_temp, "Graficos", nome)
  ggplot2::ggsave(paste0(destino,".png"), plot=grafico, width=largura,
                  height=altura, units="in", dpi=300, bg="white", limitsize=FALSE)
  dispositivo_pdf <- if (capabilities("cairo")) grDevices::cairo_pdf else "pdf"
  ggplot2::ggsave(paste0(destino,".pdf"), plot=grafico, width=largura,
                  height=altura, units="in", device=dispositivo_pdf,
                  bg="white", limitsize=FALSE)
}

arvores$especie <- factor(arvores$especie,
                          levels=c("Ipe-roxo","Ipe-amarelo"))
# Nomes populares para os eixos; nomes cientificos no guia de interpretacao.
rotulos_variaveis <- c(
  altitude_m="Altitude (m)",
  declividade_graus="Declividade (graus)",
  dist_rio_raster_m="Distância aos rios — raster (m)",
  bio12_mm_ano="Precipitação anual — BIO12 (mm/ano)",
  bio17_mm_mes="Precipitação média mensal do trimestre mais seco — BIO17 (mm/mês)"
)
for (i in seq_along(rotulos_variaveis)) {
  variavel <- names(rotulos_variaveis)[i]
  fatia <- data.frame(especie=arvores$especie, valor=arvores[[variavel]])
  n_p_especie <- table(fatia$especie)
  graf <- ggplot2::ggplot(fatia,
          ggplot2::aes(x=especie, y=valor, fill=especie)) +
    ggplot2::geom_boxplot(width=0.55, alpha=0.80, linewidth=0.5,
                          outlier.shape=16, outlier.size=0.6,
                          outlier.alpha=0.22, na.rm=TRUE) +
    ggplot2::scale_fill_manual(values=cores_especies, guide="none") +
    ggplot2::scale_x_discrete(labels=nomes_especies) +
    ggplot2::labs(
      title=paste("Condições ambientais nas árvores —", unname(rotulos_variaveis[i])),
      subtitle=sprintf("Registros inventariados: ipê-roxo (n=%s); ipê-amarelo (n=%s)",
                       n_p_especie["Ipe-roxo"], n_p_especie["Ipe-amarelo"]),
      x=NULL, y=unname(rotulos_variaveis[i]),
      caption="Caixa: Q1–Q3; linha: mediana; hastes: 1,5 × AIQ. Dados das presenças; não indica preferência ambiental."
    ) + tema_tcc()
  salvar_figura(graf, sprintf("%02d_%s",i,variavel))
}

# Histograma da diferenca entre a distancia exata e a medida raster.
dif_valores <- arvores$diferenca_absoluta_m
sdiff <- data.frame(diferenca=dif_valores[is.finite(dif_valores)])
graf_dist <- ggplot2::ggplot(sdiff,ggplot2::aes(x=diferenca)) +
  ggplot2::geom_histogram(bins=45,fill="#567D90",color="white",linewidth=0.2) +
  ggplot2::geom_vline(xintercept=median(sdiff$diferenca),color="#C23B32",
                      linewidth=0.8,linetype="dashed") +
  ggplot2::labs(
    title="Diferença entre distância vetorial e distância raster",
    subtitle=paste("Diferença absoluta em",nrow(sdiff),"árvores; linha tracejada = mediana"),
    x="Diferença absoluta (m)",y="Número de árvores",
    caption="A diferença decorre da representação raster de 30 m; o MaxEnt utiliza a distância raster."
  ) + tema_tcc()
salvar_figura(graf_dist,"06_Diferenca_das_distancias")

# Grafico principal de SOLO: nomes da legenda oficial, percentuais
# dentro de cada especie e numero de individuos, com as cores oficiais.
solo_fig <- solo_geral
solo_fig$especie <- factor(solo_fig$especie,
                levels=c("Ipe-roxo","Ipe-amarelo"),labels=c("Ipê-roxo","Ipê-amarelo"))
solo_fig$classe_rotulo <- factor(
  paste0(solo_fig$codigo," — ",solo_fig$nome_classe),
  levels=rev(paste0(legenda_solo$codigo," — ",legenda_solo$classe)))
solo_fig$codigo_cor <- factor(solo_fig$codigo,levels=legenda_solo$codigo)
cores_solo <- stats::setNames(legenda_solo$cor_hex,as.character(legenda_solo$codigo))
solo_fig$etiqueta <- sprintf("%.1f%%  (n=%d)",solo_fig$percentual,solo_fig$n_arvores)
graf_solo <- ggplot2::ggplot(solo_fig,
          ggplot2::aes(x=classe_rotulo,y=percentual,fill=codigo_cor)) +
  ggplot2::geom_col(width=.72,color="#404040",linewidth=.25) +
  ggplot2::geom_text(ggplot2::aes(label=etiqueta),hjust=-.10,size=3.5) +
  ggplot2::coord_flip(clip="off") +
  ggplot2::facet_wrap(~especie,ncol=2,scales="fixed") +
  ggplot2::scale_fill_manual(values=cores_solo,guide="none") +
  ggplot2::scale_y_continuous(labels=function(x)paste0(x,"%"),
                              expand=ggplot2::expansion(mult=c(0,.29))) +
  ggplot2::labs(
    title="Distribuição das árvores por subgrupo textural do solo",
    subtitle="MapBiomas Solo, Coleção 3, 0–30 cm | Percentual calculado dentro de cada espécie",
    x=NULL,y="Percentual de indivíduos (%)",
    caption="Cores e nomenclatura: legenda oficial do MapBiomas Solo C3. Frequências nas presenças, não disponibilidade ambiental."
  ) + tema_tcc() + ggplot2::theme(axis.text.y=ggplot2::element_text(size=10))
salvar_figura(graf_solo,"07_Textura_solo_Classes_Oficiais",largura=15,altura=8)

# Correlacoes de Pearson: painel exploratorio (sem interpretacao causal).
nomes_curtos <- c(altitude_m="Altitude",declividade_graus="Declividade",
                  dist_rio_raster_m="Dist. rios",bio12_mm_ano="BIO12",bio17_mm_mes="BIO17")
corr_fig <- correlacoes
corr_fig$variavel_1 <- factor(corr_fig$variavel_1,
                              levels=names(nomes_curtos),labels=unname(nomes_curtos))
corr_fig$variavel_2 <- factor(corr_fig$variavel_2,
                              levels=rev(names(nomes_curtos)),labels=rev(unname(nomes_curtos)))
corr_fig$especie <- factor(corr_fig$especie,
                           levels=c("Ipe-roxo","Ipe-amarelo"),labels=c("Ipê-roxo","Ipê-amarelo"))
graf_corr <- ggplot2::ggplot(corr_fig,
      ggplot2::aes(x=variavel_1,y=variavel_2,fill=correlacao_pearson)) +
  ggplot2::geom_tile(color="white",linewidth=.7) +
  ggplot2::geom_text(ggplot2::aes(label=sprintf("%.2f",correlacao_pearson)),
                     size=3.8,color="#20252A") +
  ggplot2::facet_wrap(~especie,ncol=2) +
  ggplot2::scale_fill_gradient2(low="#6C8DB3",mid="#FFFFFF",high="#C67B55",
                                 midpoint=0,limits=c(-1,1),name="r de Pearson") +
  ggplot2::labs(title="Correlações ambientais nos registros de presença",
      subtitle="Associação linear exploratória entre preditores numéricos, por espécie",
      x=NULL,y=NULL,
      caption="Não testa independência espacial, causalidade ou colinearidade do background.") +
  tema_tcc() + ggplot2::theme(axis.text.x=ggplot2::element_text(angle=35,hjust=1))
salvar_figura(graf_corr,"08_Correlacoes_Exploratorias",largura=14,altura=7)

# Amostras por propriedade (comparacoes de contagem apenas, sem densidade/ha).
cont_fig <- contagem
cont_fig$especie <- factor(cont_fig$especie,levels=c("Ipe-roxo","Ipe-amarelo"),
                           labels=c("Ipê-roxo","Ipê-amarelo"))
cont_fig$propriedade <- factor(cont_fig$propriedade,
                               levels=rev(sort(unique(cont_fig$propriedade))))
graf_cont <- ggplot2::ggplot(cont_fig,
       ggplot2::aes(x=propriedade,y=n_arvores,fill=especie)) +
  ggplot2::geom_col(position="stack",width=.8) +
  ggplot2::coord_flip() +
  ggplot2::scale_fill_manual(values=c("Ipê-roxo"="#0072B2","Ipê-amarelo"="#D55E00")) +
  ggplot2::labs(title="Número de árvores inventariadas por propriedade",
    subtitle="Contagens absolutas, sem padronização pela área inventariada",
    x=NULL,y="Indivíduos registrados (n)",
    caption="Comparações de densidade exigem área censitada (ha) de cada UPA.") +
  tema_tcc()
salvar_figura(graf_cont,"09_Arvores_por_propriedade",largura=11,altura=12)

# 13 - RESUMO DE INTERPRETACAO E VERSOES ---------------------------
quantidades_especies <- table(arvores$especie)
texto <- c(
  "TCC - ESTATISTICAS DESCRITIVAS DOS IPES",
  "=====================================",
  paste("Data:", format(Sys.time(), "%d/%m/%Y %H:%M:%S")),
  paste("Propriedades:", length(unique(arvores$propriedade))),
  paste("Arvores:", nrow(arvores)),
  paste(names(quantidades_especies), as.integer(quantidades_especies), collapse=" | "),
  "",
  "ENTRADA: 34 GeoPackages da camada arvores_com_variaveis (Script 10 do QGIS).",
  "",
  "O QUE OS RESULTADOS SIGNIFICAM:",
  "- Contagem: numero de individuos registrados, nao densidade por hectare.",
  "- Estatisticas: resumo das condicoes ambientais NAS PRESENCAS.",
  "- Textura: códigos 1 a 9 e nomes da legenda OFICIAL do MapBiomas Solo C3.",
  "- A classe 1 representa rocha / nao solo; classes 2 a 9 sao texturas.",
  "- Frequencias de solo: denominador = individuos da especie, nao area da UPA.",
  "- Distancias: a vetorial e de auditoria; a raster entra no MaxEnt.",
  "- Correlacoes: exploratorias; arvores vizinhas nao sao independentes.",
  "- BIO12 e BIO17 (1980-2021): climatologia CHELSA; informacao nativa ~1 km.",
  "- O alinhamento a 30 m nao adiciona detalhe climatico real.",
  "- Estas estatisticas nao comprovam preferencias ambientais das especies.",
  "- Figuras em PNG 300 dpi e PDF, sem testes estatisticos entre especies.",
  "- Nomes cientificos: Ipe-roxo = Handroanthus impetiginosus;",
  "  Ipe-amarelo = Handroanthus serratifolius.",
  "- Fonte da legenda: https://brasil.mapbiomas.org/iniciativas-e-produtos/solo/textura/",
  "- A disponibilidade ambiental das UPAs sera analisada com o background.",
  "- UPAs sem registro bruto NAO foram inventariadas e foram excluidas do background.",
  "- Apenas DAP > 10 cm, e somente DESENVOLVIMENTO em analises ambientais V3.",
  "- O conjunto TESTE tem somente suas contagens globais de QA, nao preditores usados para escolha.",
  "",
  "O SCRIPT NAO MODIFICA AS CAMADAS DE ENTRADA."
)
writeLines(texto, file.path(saida_temp,"08_LEIA_OS_RESULTADOS.txt"), useBytes=TRUE)
capture.output(sessionInfo(), file=file.path(saida_temp,"09_Versoes_do_R.txt"))

if (!file.rename(saida_temp,saida_final)) {
  stop("As tabelas foram geradas, mas nao consegui finalizar a pasta: ", saida_temp)
}

cat("\n=========================================\n")
cat("SCRIPT R 01 CONCLUIDO!\n")
cat("Arvores analisadas: ", nrow(arvores), "\n", sep="")
cat("Propriedades: ", length(unique(arvores$propriedade)), "\n", sep="")
cat("RESULTADOS EM:\n",saida_final,"\n",sep="")
cat("=========================================\n")
