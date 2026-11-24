# TCC IPES - R05 V3.1 | Preparacao auditavel para o primeiro MaxEnt (M0)
# NAO AJUSTA MODELOS. NAO LE DADOS DAS PROPRIEDADES EXTERNAS DE TESTE.
# Requer: pacote terra (ja utilizado no projeto).
# Colocar este script e 05_PLANO_FOLDS_V3.csv em 05 - Modelagem no R/01 - Scripts/
# No RStudio, clicar Source e escolher BACKGROUND_COMUM_DESENVOLVIMENTO.csv do R02.

if (!requireNamespace('terra', quietly=TRUE))
  stop("Pacote R 'terra' ausente. Instale com install.packages('terra').")

cat('\nR05 V3 - Selecione BACKGROUND_COMUM_DESENVOLVIMENTO.csv do R02.\n')
arq <- normalizePath(file.choose(), winslash='/', mustWork=TRUE)
if (basename(arq) != 'BACKGROUND_COMUM_DESENVOLVIMENTO.csv')
  stop('Arquivo errado. Selecione BACKGROUND_COMUM_DESENVOLVIMENTO.csv.')

achar_raiz <- function(p) {
  d <- dirname(p)
  repeat {
    if (dir.exists(file.path(d, '03 - Trabalho no QGIS')) &&
        dir.exists(file.path(d, '04 - Dados para o MaxEnt')))
      return(d)
    pai <- dirname(d)
    if (identical(pai, d)) stop('Raiz TCC nao localizada a partir do background.')
    d <- pai
  }
}
raiz <- achar_raiz(arq)
bgdir <- file.path(raiz, '04 - Dados para o MaxEnt', '03 - Background V3')
if (normalizePath(dirname(arq), winslash='/', mustWork=TRUE) !=
    normalizePath(bgdir, winslash='/', mustWork=TRUE))
  stop('O background deve estar na pasta 03 - Background V3 da raiz do projeto.')

scripts <- file.path(raiz, '05 - Modelagem no R', '01 - Scripts')
plano_path <- file.path(scripts, '05_PLANO_FOLDS_V3.csv')
if (!file.exists(plano_path))
  stop('Falta 05_PLANO_FOLDS_V3.csv em ', scripts)
part_path <- file.path(bgdir, '02_PARTICAO_APROVADA.csv')
if (!file.exists(part_path)) stop('Falta a particao aprovada gerada pelo R02.')
conf <- file.path(raiz, '03 - Trabalho no QGIS', '03 - Conferencias',
                  '12C - Dominio inventariado V3')
prox_path <- file.path(conf, '12_PROXIMIDADE_ENTRE_PROPRIEDADES.csv')
upas_path <- file.path(conf, '12_UPAS_UNICAS.csv')
if (!file.exists(prox_path) || !file.exists(upas_path))
  stop('Faltam os CSVs de proximidade ou de UPAs do QGIS12.')
saida <- file.path(raiz, '04 - Dados para o MaxEnt',
                   '04 - Presencas e folds V3')
if (dir.exists(saida)) stop('Saida ja existe. Preserve a anterior antes de rodar: ', saida)

ler2 <- function(p) read.csv2(p, fileEncoding='UTF-8-BOM',
                              stringsAsFactors=FALSE, check.names=FALSE)
lerq <- function(p) read.table(p, header=TRUE, sep=';', dec='.',
                                fileEncoding='UTF-8-BOM', quote='"',
                                stringsAsFactors=FALSE, check.names=FALSE)
numero <- function(x) suppressWarnings(as.numeric(gsub(',', '.', as.character(x), fixed=TRUE)))
vars_cont <- c('altitude_m', 'declividade_graus', 'dist_rio_raster_m',
               'bio12_mm_ano', 'bio17_mm_mes')
vars <- c(vars_cont, 'textura_subgrupo')

part <- ler2(part_path)
plano <- ler2(plano_path)
upas <- lerq(upas_path)
prox <- lerq(prox_path)
if (nrow(part)!=34L || nrow(plano)!=34L || nrow(upas)!=84L || nrow(prox)!=561L ||
    anyDuplicated(part$propriedade) || anyDuplicated(plano$propriedade) ||
    !setequal(part$propriedade, plano$propriedade) ||
    !all(c('propriedade','conjunto') %in% names(part)))
  stop('Incoerencia em numero/nome de propriedades, UPAs ou distancias.')
if (!all(part$conjunto %in% c('TESTE','DESENVOLVIMENTO'))) stop('Conjunto invalido.')
plano <- plano[match(part$propriedade,plano$propriedade),,drop=FALSE]
if (!identical(as.character(plano$conjunto), as.character(part$conjunto)))
  stop('O plano de folds nao corresponde a particao aprovada pelo R02.')
teste <- part$propriedade[part$conjunto=='TESTE']
dev <- part$propriedade[part$conjunto=='DESENVOLVIMENTO']
teste_fixo <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
                'LOTE 01','MARILIA','PALMEIRA')
if (length(dev)!=27L || length(teste)!=7L || !setequal(teste,teste_fixo))
  stop('Particao externa mudou. Interrompendo para nao misturar teste com treinamento.')
if (any(!is.na(plano$fold_cv[plano$conjunto=='TESTE'])))
  stop('Uma propriedade externa de TESTE recebeu fold: proibido.')
pl_dev <- plano[plano$conjunto=='DESENVOLVIMENTO',,drop=FALSE]
pl_dev$fold_cv <- as.integer(pl_dev$fold_cv)
if (anyNA(pl_dev$fold_cv) || !setequal(unique(pl_dev$fold_cv),1:3))
  stop('Folds das propriedades de desenvolvimento incompletos.')
map_fold <- setNames(pl_dev$fold_cv, pl_dev$propriedade)

pares <- prox[(prox$propriedade_a %in% dev) & (prox$propriedade_b %in% dev),,drop=FALSE]
if (nrow(pares)!=choose(27,2)) stop('Tabela de pares das propriedades de desenvolvimento incompleta.')
a <- unname(map_fold[pares$propriedade_a]); b <- unname(map_fold[pares$propriedade_b])
if (anyNA(a) || anyNA(b)) stop('Propriedade sem atribuicao de fold.')
if (any(pares$distancia_minima_m<=1000 & a!=b))
  stop('Violacao dos agrupamentos: propriedades a <= 1 km em folds diferentes.')
menor_cross <- min(pares$distancia_minima_m[a!=b])/1000

# Background fisico: identico para ambas as especies. Apenas desenvolvimento.
bg <- read.csv(arq, fileEncoding='UTF-8', stringsAsFactors=FALSE, check.names=FALSE)
campos_bg <- c('propriedade','upa_id','celula_raster','id_background',vars)
if (!all(campos_bg %in% names(bg))) stop('Faltam campos no background: ', paste(setdiff(campos_bg,names(bg)),collapse=', '))
if (nrow(bg)!=5000L || anyDuplicated(bg$id_background) ||
    anyDuplicated(paste(bg$propriedade,bg$celula_raster,sep='|')) ||
    !all(bg$propriedade %in% dev) || !setequal(unique(bg$propriedade),dev))
  stop('Background nao corresponde ao R02 V3 aprovado (5000 pontos / 27 propriedades).')
upas_dev <- upas[upas$inventariada=='SIM' & upas$propriedade %in% dev,,drop=FALSE]
if (nrow(upas_dev)!=64L || !setequal(unique(bg$upa_id),upas_dev$upa_id))
  stop('UPAs do background nao correspondem as 64 elegiveis de desenvolvimento.')

# CORRECAO R05 V3.1: GeoPackage guarda UPA como '1', '2', '3' ou 'ÚNICA';
# QGIS12 usa 'UPA 01', 'UPA 02', 'UPA UNICA'. Comparar identificadores
# normalizados SEM alterar campos originais ou dispensar validacao das UPAs.
normalizar_upa <- function(x) {
  y <- iconv(as.character(x), from='', to='ASCII//TRANSLIT', sub='')
  if (anyNA(y)) stop('Nao foi possivel normalizar o identificador de alguma UPA.')
  y <- toupper(trimws(y))
  y <- gsub('[^A-Z0-9]', '', y)
  y <- sub('^UPA', '', y)
  numerico <- grepl('^[0-9]+$', y)
  if (any(numerico)) y[numerico] <- paste0('N', as.integer(y[numerico]))
  y[y %in% c('UNICO','UNICA')] <- 'UNICA'
  if (any(!grepl('^N[0-9]+$', y) & y!='UNICA'))
    stop('Codigo de UPA nao reconhecido: ', paste(unique(y[!grepl('^N[0-9]+$', y) & y!='UNICA']),collapse=', '))
  y
}
chaves_upas_dev <- paste(upas_dev$propriedade, normalizar_upa(upas_dev$upa_nome),sep='|')
if (anyDuplicated(chaves_upas_dev))
  stop('Identificadores de UPA ambiguos apos normalizacao no CSV do QGIS12.')
for (v in vars) bg[[v]] <- numero(bg[[v]])
if (any(!is.finite(as.matrix(bg[,vars,drop=FALSE]))) ||
    any(bg$textura_subgrupo!=round(bg$textura_subgrupo)))
  stop('Valores ambientais nao validos no background.')
bg$fold_cv <- as.integer(map_fold[bg$propriedade])
if (anyNA(bg$fold_cv)) stop('Background sem fold.')

identificar <- function(x, propriedade) {
  ci <- if ('nome_cientifico' %in% names(x)) tolower(as.character(x$nome_cientifico)) else rep('',nrow(x))
  vu <- if ('nome_vulgar' %in% names(x)) tolower(as.character(x$nome_vulgar)) else rep('',nrow(x))
  ci[is.na(ci)]<-'';vu[is.na(vu)]<-''
  ro <- grepl('impetiginosus',ci) | grepl('roxo',vu)
  am <- grepl('serratifolius',ci) | grepl('amarelo',vu)
  if (any(ro==am)) stop('Identificacao de especie ambigua em ', propriedade)
  ifelse(ro,'Ipe-roxo','Ipe-amarelo')
}

base <- file.path(raiz,'03 - Trabalho no QGIS','02 - Arquivos gerados')
entrada <- file.path(base,'Pontos com variaveis')
partes <- vector('list', length(dev))
for (k in seq_along(dev)) {
  prop <- dev[k]
  gpkg <- file.path(entrada,paste0(prop,'.gpkg'))
  alt <- file.path(base,'Altitude e declividade',prop,'altitude_utm30m.tif')
  if (!file.exists(gpkg) || !file.exists(alt)) stop('Falta GPKG ou altitude de ',prop)
  v <- terra::vect(gpkg, layer='arvores_com_variaveis')
  r <- terra::rast(alt)
  if (!isTRUE(terra::same.crs(v,r))) stop('CRS divergente em ',prop)
  tab <- as.data.frame(v)
  obrig <- c('linha_csv','dap_cm_num','elegivel_dap_gt10','upa','latitude','longitude',vars)
  if (!all(obrig %in% names(tab))) stop('Campos ausentes em ', prop, ': ',paste(setdiff(obrig,names(tab)),collapse=', '))
  if (nrow(tab)!=nrow(terra::crds(v))) stop('Geometrias e atributos desalinhados em ',prop)
  tab$dap_cm_num <- numero(tab$dap_cm_num)
  tab$elegivel_dap_gt10 <- numero(tab$elegivel_dap_gt10)
  if (any(!is.finite(tab$dap_cm_num)) ||
      any(tab$elegivel_dap_gt10 != as.integer(tab$dap_cm_num > 10)))
    stop('Regra DAP inconsistente em ',prop)
  cel <- terra::cellFromXY(r,terra::crds(v))
  if (anyNA(cel)) stop('Ocorrencias fora da grade de 30m de ',prop)
  for (nm in vars) tab[[nm]] <- numero(tab[[nm]])
  if (any(!is.finite(as.matrix(tab[,vars,drop=FALSE])))) stop('Preditor ausente em ',prop)
  if (any(tab$textura_subgrupo != round(tab$textura_subgrupo))) stop('Solo nao categorizado em ',prop)
  especie <- identificar(tab,prop)
  ix <- which(tab$dap_cm_num > 10)
  s <- data.frame(propriedade=prop,upa=as.character(tab$upa[ix]),
     linha_csv=as.character(tab$linha_csv[ix]),
     especie=especie[ix], fold_cv=as.integer(map_fold[prop]),
     celula_raster=as.integer(cel[ix]),
     longitude=numero(tab$longitude[ix]), latitude=numero(tab$latitude[ix]),
     tab[ix,vars,drop=FALSE],check.names=FALSE,stringsAsFactors=FALSE)
  if (any(!is.finite(s$longitude)) || any(!is.finite(s$latitude)) ||
      any(s$longitude < -180 | s$longitude > 180) ||
      any(s$latitude < -90 | s$latitude > 90)) stop('Coordenadas geograficas invalidas em ',prop)
  # Relacionar cada arvore ao identificador CANONICO da tabela QGIS12.
  # Nao autorizar UPAs ausentes, nao inventariadas nem chaves ambiguas.
  chaves_arvores <- paste(prop, normalizar_upa(s$upa),sep='|')
  pos_upa <- match(chaves_arvores, chaves_upas_dev)
  if (anyNA(pos_upa))
    stop('Ocorrencia analitica em UPA ausente/nao inventariada: ',prop,
         ' [codigos: ',paste(unique(s$upa[is.na(pos_upa)]),collapse=', '),']')
  s$upa_id <- upas_dev$upa_id[pos_upa]
  partes[[k]]<-s
  cat(sprintf('[R05] %02d/%02d %-24s %5d arvores elegiveis\n', k,length(dev),prop,nrow(s)))
}
todas <- do.call(rbind,partes)
rownames(todas)<-NULL
if (nrow(todas)!=9004L || sum(todas$especie=='Ipe-roxo')!=3395L ||
    sum(todas$especie=='Ipe-amarelo')!=5609L ||
    any(todas$propriedade %in% teste) ||
    anyDuplicated(paste(todas$propriedade,todas$linha_csv,sep='|')))
  stop('Presencas nao fecham com auditoria R01 ou ocorreu vazamento TESTE.')

# Conferencia adicional: contagem exata de individuos elegiveis POR UPA,
# confrontando a tabela QGIS12; impede associacoes equivocadas silenciosas.
esperado_upa <- numero(upas_dev$n_roxo_dap_gt10) + numero(upas_dev$n_amarelo_dap_gt10)
observado_upa <- as.integer(table(factor(todas$upa_id, levels=upas_dev$upa_id)))
if (anyNA(esperado_upa) || length(observado_upa)!=length(esperado_upa) ||
    any(observado_upa != esperado_upa)) {
  divergentes <- upas_dev$upa_id[is.na(esperado_upa) | observado_upa != esperado_upa]
  stop('Contagem por UPA difere do QGIS12: ',paste(divergentes,collapse=', '))
}

# Reducao por especie e centro de pixel AMBIENTAL de 30m.
# Preserva TODAS em arquivo separado para auditoria e sensibilidade futura.
todas <- todas[order(todas$propriedade,todas$especie,
                     todas$celula_raster,todas$linha_csv),,drop=FALSE]
rownames(todas)<-NULL
chave <- paste(todas$propriedade,todas$especie,todas$celula_raster,sep='|')
todas$primeiro_no_pixel <- !duplicated(chave)
dedup <- todas[todas$primeiro_no_pixel,,drop=FALSE]
if (anyDuplicated(paste(dedup$propriedade,dedup$especie,dedup$celula_raster,sep='|')))
  stop('Falha na deduplicacao espacial.')

# Auditoria da cobertura da textura: o modelo categorico pode ter classes raras.
solo_rows <- list(); j<-0L
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (f in 1:3) for (orig in c('PRESENCA','BACKGROUND')) {
  x <- if (orig=='PRESENCA') dedup[dedup$especie==sp & dedup$fold_cv==f,,drop=FALSE] else bg[bg$fold_cv==f,,drop=FALSE]
  for (catg in sort(unique(c(bg$textura_subgrupo,dedup$textura_subgrupo)))) {
    j<-j+1L
    solo_rows[[j]] <- data.frame(especie=sp,fold_cv=f,origem=orig,
      textura_subgrupo=catg,n=sum(x$textura_subgrupo==catg))
  }
}
solo <- do.call(rbind,solo_rows)
resumo <- list();j<-0L
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (f in 1:3) {
  j<-j+1L
  resumo[[j]] <- data.frame(especie=sp,fold_cv=f,
    n_arvores_todas=sum(todas$especie==sp & todas$fold_cv==f),
    n_presencas_pixel_30m=sum(dedup$especie==sp & dedup$fold_cv==f),
    n_background=sum(bg$fold_cv==f),
    n_propriedades=length(unique(bg$propriedade[bg$fold_cv==f])),
    n_upas=length(unique(bg$upa_id[bg$fold_cv==f])))
}
resumo <- do.call(rbind,resumo)
if (any(resumo$n_presencas_pixel_30m < 100) || any(resumo$n_background < 250))
  stop('Fold pequeno demais. Rever proposta antes de calibrar modelos.')

# Nao cria pasta nem altera fonte antes de todas as verificacoes acima.
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
salvar <- function(x,n) write.csv(x,file.path(saida,n),row.names=FALSE,fileEncoding='UTF-8')
salvar(todas,'05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv')
salvar(dedup,'05_PRESENCAS_UM_POR_PIXEL_30M.csv')
salvar(bg,'05_BACKGROUND_COM_FOLDS.csv')
salvar(resumo,'05_RESUMO_FOLDS.csv')
salvar(solo,'05_CLASSES_SOLO_POR_FOLD.csv')
writeLines(c('R05 V3.1 - PREPARACAO DOS DADOS PARA O MAXENT M0',
  'NAO FOI AJUSTADO QUALQUER MAXENT. Nenhuma propriedade reservada foi lida.',
  'Verificacao adicional: nomes de UPA normalizados e contagens exatas por UPA confrontadas com QGIS12.',
  sprintf('Particao: %d desenvolvimento e %d externas de teste.',length(dev),length(teste)),
  sprintf('Total de arvores analiticas = %d (roxo=3395; amarelo=5609).',nrow(todas)),
  sprintf('Presencas unicas por especie/pixel de 30m = %d.',nrow(dedup)),
  sprintf('Registros adicionais no mesmo pixel = %d. Originais preservados.',nrow(todas)-nrow(dedup)),
  sprintf('Background = %d; propriedades=%d; UPAs=%d.',nrow(bg),length(dev),nrow(upas_dev)),
  sprintf('Distancia minima entre folds de desenvolvimento: %.3f km.',menor_cross),
  'Agrupamento por componentes de propriedades <= 1 km: exploratorio, NAO escala empirica de autocorrelacao.',
  'Roxo concentra-se em dois grupos regionais; fold com menor roxo apresenta menos ocorrencias.',
  'Solo e categorico; inspecione classes raras/faltantes por fold ANTES de ajustar modelos.',
  'Background != ausencia. Pixels CHELSA nativos ~1km, nao replicacoes climaticas de 30m.',
  'NAO utilizar TESTE EXTERNO para escolher predictores, complexidade, background ou folds.',
  paste('Versao R:',R.version.string),
  paste('Versao terra:',as.character(utils::packageVersion('terra')))),
  con=file.path(saida,'05_LEIA_RESULTADOS_E_CUIDADOS.txt'),useBytes=TRUE)
cat('\nR05 CONCLUIDO, sem ajustes de MaxEnt. Resultados em:\n',saida,'\n')
cat('Envie a pasta de resultados compactada para a proxima conferencia.\n')
