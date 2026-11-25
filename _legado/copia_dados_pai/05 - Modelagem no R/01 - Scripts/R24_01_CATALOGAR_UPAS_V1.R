# =============================================================================
# TCC IPES - R24 ETAPA 1 - INVENTARIO DOS POLIGONOS ORIGINAIS DAS UPAs
# Nao altera fontes, folds, modelos nem utiliza dados do teste externo.
# Executar somente se NAO houver um GPKG consolidado com propriedade e upa_id.
# =============================================================================
VERSAO <- 'R24_01_V1_20261117'
if (!requireNamespace('sf', quietly=TRUE)) stop('Instale sf: install.packages("sf")')
cat('\nR24 ETAPA 1: selecione 23_PARES_UPAS.csv da pasta R23 V1_1.\n')
f23 <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(f23)!='23_PARES_UPAS.csv') stop('Selecione 23_PARES_UPAS.csv do R23.')
ler <- function(p) utils::read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,fileEncoding='UTF-8-BOM')
orig <- ler(f23)
necessarias <- c('upa_a','upa_b','propriedade_a','propriedade_b','fold_a','fold_b')
if (!all(necessarias %in% names(orig))) stop('Colunas ausentes no R23.')
u <- unique(rbind(data.frame(upa_id=sub('^.*\\|\\|','',orig$upa_a),propriedade=orig$propriedade_a,fold_cv=orig$fold_a),
                  data.frame(upa_id=sub('^.*\\|\\|','',orig$upa_b),propriedade=orig$propriedade_b,fold_cv=orig$fold_b)))
if (nrow(u)!=64L || length(unique(u$propriedade))!=27L || nrow(orig)!=2016L ||
    anyDuplicated(paste(u$propriedade,u$upa_id,sep='||')))
  stop('As 64 UPAs ou 2016 pares do R23 nao conferem.')
raiz_saida <- dirname(f23)
while (basename(raiz_saida)!='06 - Resultados' && dirname(raiz_saida)!=raiz_saida)
  raiz_saida <- dirname(raiz_saida)
if (basename(raiz_saida)!='06 - Resultados') stop('R23 nao esta em 06 - Resultados.')
saida <- file.path(raiz_saida,'22 - Geometria das UPAs R24 V1')
if (!dir.exists(saida)) dir.create(saida,recursive=TRUE)
if (file.exists(file.path(saida,'24_MAPEAMENTO_UPAS_REVISAR.csv')))
  stop('Ja existe mapeamento R24. Preserve-o para nao perder sua revisao: ',saida)
cat('\nSelecione a PASTA que contem as subpastas com SHP/GPKG das UPAs.\n')
fonte <- if (.Platform$OS.type=='windows') utils::choose.dir(caption='Pasta com shapefiles/GPKG originais das UPAs') else NA_character_
if (is.na(fonte) || !nzchar(fonte)) stop('Pasta nao selecionada. Nenhuma fonte foi alterada.')
fonte <- normalizePath(fonte,winslash='/',mustWork=TRUE)
norm <- function(x) {
  y <- iconv(as.character(x),to='ASCII//TRANSLIT',sub='')
  toupper(gsub('[^A-Za-z0-9]','',y))
}
reservadas <- c('BARROBRANCO','CURUCA','GUARIUBA','JATOBA','LOTE01','MARILIA','PALMEIRA')
# SOMENTE descobrir metadata das camadas; nao ler geometrias ainda.
arquivos <- list.files(fonte,pattern='\\.(shp|gpkg)$',recursive=TRUE,
                       full.names=TRUE,ignore.case=TRUE)
if (!length(arquivos)) stop('Nao foram encontrados SHP/GPKG extraidos da pasta selecionada.')
cat('Camadas candidatas a catalogar: ',length(arquivos),' arquivos.\n',sep='')
catalogo <- list(); k <- 0L
for (f in arquivos) {
  rel <- substring(gsub('\\\\','/',f),nchar(fonte)+2L)
  componentes <- strsplit(rel,'/',fixed=TRUE)[[1]]
  # Ignorar diretorios explicitamente identificados como teste externo.
  if (any(norm(tools::file_path_sans_ext(componentes)) %in% reservadas)) next
  info <- tryCatch(sf::st_layers(f), error=function(e) NULL)
  if (is.null(info)) next
  for (i in seq_along(info$name)) {
    gt <- as.character(info$geomtype[i])
    if (!grepl('POLYGON',toupper(gt))) next
    k <- k+1L
    catalogo[[k]] <- data.frame(arquivo=normalizePath(f,winslash='/',mustWork=TRUE),
       camada=as.character(info$name[i]),n_geometrias=as.integer(info$features[i]),
       tipo_geometria=gt,caminho_relativo=rel,stringsAsFactors=FALSE)
  }
}
if (!length(catalogo)) stop('Nenhuma camada poligonal encontrada. Confira a pasta e os dados.')
catg <- do.call(rbind,catalogo)
# A correspondencia serve apenas como SUGESTAO; nunca aprovada automaticamente.
resultado <- u[order(u$propriedade,u$upa_id),,drop=FALSE]
resultado$arquivo <- ''
resultado$camada <- ''
resultado$filtro_campo <- ''
resultado$filtro_valor <- ''
resultado$APROVADO <- 'NAO'
resultado$diagnostico_sugestao <- ''
for (i in seq_len(nrow(resultado))) {
  p <- norm(resultado$propriedade[i]); up <- norm(sub('^.*\\|','',resultado$upa_id[i]))
  if (!nzchar(p) || !nzchar(up)) stop('Identificador vazio na referencia R23.')
  escores <- vapply(seq_len(nrow(catg)),function(j) {
    componentes <- strsplit(catg$caminho_relativo[j],'/',fixed=TRUE)[[1]]
    bits <- norm(tools::file_path_sans_ext(componentes))
    camada_norm <- norm(catg$camada[j])
    # Exigir que alguma pasta ou arquivo coincida exatamente com a propriedade.
    tem_prop <- p %in% bits || p==camada_norm
    if (!tem_prop) return(-999L)
    esta_upa <- up %in% bits || up==camada_norm
    # Pasta "UPA 01" e arquivo "UPA01.shp" contam como correspondencia.
    # 'UPA UNICA' necessita identificacao exata; nao presumir que imovel=UPA.
    score <- 4L + if (esta_upa) 5L else 0L
    if (grepl('APP|RIO|HIDRO|IMOVEL|PROPRIEDADE|DRENAGEM',paste(bits,collapse=' '))) score <- score-20L
    score
  },integer(1))
  melhor <- max(escores)
  ii <- which(escores==melhor)
  if (melhor>=9L && length(ii)==1L) {
    resultado$arquivo[i] <- catg$arquivo[ii]
    resultado$camada[i] <- catg$camada[ii]
    resultado$diagnostico_sugestao[i] <- 'SUGESTAO_UNICA_REVISAR'
  } else if (melhor>=9L) {
    resultado$diagnostico_sugestao[i] <- paste0('AMBIGUO_',length(ii),'_CANDIDATOS')
  } else {
    resultado$diagnostico_sugestao[i] <- 'SEM_SUGESTAO_SEGURA'
  }
}
grava <- function(d,n) utils::write.csv(d,file.path(saida,n),row.names=FALSE,fileEncoding='UTF-8')
grava(catg,'24_CATALOGO_CAMADAS_POLIGONAIS.csv')
grava(resultado,'24_MAPEAMENTO_UPAS_REVISAR.csv')
writeLines(c(
 'R24 - ETAPA 1 CONCLUIDA: CATALOGO DE FONTES (NAO SAO DISTANCIAS).',
 paste('Fontes examinadas:',length(arquivos)),
 paste('Camadas poligonais candidatas:',nrow(catg)),
 paste('UPAs do desenvolvimento:',nrow(resultado)),
 paste('Sugestoes unicas:',sum(resultado$diagnostico_sugestao=='SUGESTAO_UNICA_REVISAR')),
 'Abra 24_MAPEAMENTO_UPAS_REVISAR.csv, confirme caminho/camada para as 64 UPAs.',
 'Se cada arquivo contem exclusivamente a UPA, deixe filtro_campo/valor vazios.',
 'Se o arquivo agrupa varias UPAs, preencha campo e valor para selecionar a UPA.',
 'Somente apos revisar altere APROVADO de NAO para SIM nas 64 linhas.',
 'Execute R24_02_MEDIR_DISTANCIAS_UPAS_V1.R e escolha modo MAPEAMENTO.',
 'Nao use poligonos de IMOVEL quando existem limites de UPA.',
 'Nao foram carregados modelos MaxEnt, nem alterados os folds.'
 ),file.path(saida,'24_LEIA_ME_MAPEAMENTO.txt'),useBytes=TRUE)
cat('\nR24 etapa 1 concluida. Pasta: ',saida,'\n',sep='')
cat('Revise o CSV de mapeamento, marque APROVADO=SIM e execute a etapa 2.\n')
