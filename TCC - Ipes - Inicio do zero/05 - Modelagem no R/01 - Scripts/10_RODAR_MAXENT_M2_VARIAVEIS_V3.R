# ============================================================================
# TCC IPES | R10 V3 - MaxEnt M2: comparacao controlada de conjuntos de variaveis
# 15/11/2026 | Handroanthus impetiginosus e H. serratifolius
# ============================================================================
# PROTOCOLO
# - 2 especies x 3 folds x 6 conjuntos = 36 avaliacoes.
# - Features LQH e multiplicador de regularizacao RM=4, fixos.
# - Mesmos 5.000 pontos de background e folds espaciais do R05/R08.
# - Reaproveita SEM REAJUSTAR as seis avaliacoes COMPLETO_6 de LQH/RM4 do R08,
#   depois de validar hashes, arquivos, contagens e metricas.
# - Ajusta somente os 30 modelos novos; salva RDS/previsoes/checkpoints.
# - Solo tratado como fator quando presente; previsao cloglog, clamp=TRUE.
# - Calcula AUC presenca-vs-background, omissao 10% pelo TREINO, Boyce e
#   complexidade, e discrimina por propriedade onde houver amostra suficiente.
# - Nenhuma das 7 propriedades externas de teste e consultada para selecao.
# - NAO modifica R01-R09 nem os resultados anteriores; nao escolhe vencedor.
# ============================================================================

if (!requireNamespace('maxnet',quietly=TRUE))
  stop("Instale maxnet: install.packages('maxnet')")
if (!requireNamespace('ecospat',quietly=TRUE))
  stop("Instale ecospat: install.packages('ecospat')")

versao <- 'R10_V3_M2_VARIAVEIS_20261115'
cat('\nR10 M2 | Selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv da pasta R05 V3.\n')
arq_pres <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(arq_pres) != '05_PRESENCAS_UM_POR_PIXEL_30M.csv')
  stop('Arquivo incorreto: escolha 05_PRESENCAS_UM_POR_PIXEL_30M.csv.')
entrada <- dirname(arq_pres)
raiz <- dirname(dirname(entrada))
if (basename(entrada) != '04 - Presencas e folds V3' ||
    basename(dirname(entrada)) != '04 - Dados para o MaxEnt' ||
    !dir.exists(file.path(raiz,'03 - Trabalho no QGIS')))
  stop('A estrutura de pastas nao corresponde ao projeto V3.')

arq_bg <- file.path(entrada,'05_BACKGROUND_COM_FOLDS.csv')
arq_total <- file.path(entrada,'05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv')
arq_folds <- file.path(entrada,'05_RESUMO_FOLDS.csv')
entradas <- c(arq_pres,arq_bg,arq_total,arq_folds)
if (!all(file.exists(entradas)))
  stop('Faltam arquivos R05 necessarios: ',paste(entradas[!file.exists(entradas)],collapse='; '))

ler <- function(f) read.csv(f,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE,
                            check.names=FALSE)
pres <- ler(arq_pres)
bg <- ler(arq_bg)
total <- ler(arq_total)
resumo05 <- ler(arq_folds)
continuas <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
todas_vars <- c(continuas,'textura_subgrupo')
campos_pres <- c('especie','propriedade','upa_id','fold_cv','celula_raster',todas_vars)
campos_bg <- c('propriedade','upa_id','fold_cv','celula_raster','id_background',todas_vars)
if (!all(campos_pres %in% names(pres)) || !all(campos_bg %in% names(bg)) ||
    !all(c('especie','fold_cv','n_presencas_pixel_30m','n_background') %in% names(resumo05)))
  stop('Campos obrigatorios do R05 V3 ausentes.')
if (nrow(pres)!=8680L || nrow(bg)!=5000L || nrow(total)!=9004L ||
    nrow(resumo05)!=6L || sum(pres$especie=='Ipe-roxo')!=3248L ||
    sum(pres$especie=='Ipe-amarelo')!=5432L ||
    !setequal(unique(pres$especie),c('Ipe-roxo','Ipe-amarelo')))
  stop('Contagens diferentes das entradas R05 V3 auditadas.')
if (anyNA(pres[,campos_pres,drop=FALSE]) || anyNA(bg[,campos_bg,drop=FALSE]) ||
    any(!is.finite(as.matrix(pres[,todas_vars,drop=FALSE]))) ||
    any(!is.finite(as.matrix(bg[,todas_vars,drop=FALSE]))))
  stop('Entradas com NA, NaN ou Inf.')
if (anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster,sep='|')) ||
    anyDuplicated(paste(bg$propriedade,bg$celula_raster,sep='|')) ||
    anyDuplicated(bg$id_background))
  stop('Duplicatas inesperadas nas presencas ou no background.')
if (length(unique(bg$propriedade))!=27L || length(unique(bg$upa_id))!=64L ||
    !setequal(unique(bg$propriedade),unique(pres$propriedade)) ||
    !setequal(unique(pres$fold_cv),1:3) || !setequal(unique(bg$fold_cv),1:3))
  stop('Conjunto de propriedades, UPAs ou folds divergente do R05.')
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
if (any(pres$propriedade %in% externas) || any(bg$propriedade %in% externas))
  stop('TESTE EXTERNO detectado nos dados! R10 interrompido.')
propriedades_folds <- unique(rbind(pres[,c('propriedade','fold_cv')],
                                   bg[,c('propriedade','fold_cv')]))
if (any(vapply(split(propriedades_folds$fold_cv,propriedades_folds$propriedade),
               function(x) length(unique(x))!=1L,logical(1))))
  stop('Alguma propriedade aparece em folds diferentes.')
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (f in 1:3) {
  z <- resumo05[resumo05$especie==sp & resumo05$fold_cv==f,,drop=FALSE]
  if (nrow(z)!=1L ||
      z$n_presencas_pixel_30m!=sum(pres$especie==sp & pres$fold_cv==f) ||
      z$n_background!=sum(bg$fold_cv==f))
    stop('Contagens inconsistentes no resumo dos folds: ',sp,' F',f)
}
classes_solo <- sort(unique(c(pres$textura_subgrupo,bg$textura_subgrupo)))
if (!identical(as.integer(classes_solo),c(2L,3L,4L,6L,7L)))
  stop('As classes de textura do solo nao correspondem ao R05/R08.')

# Os seis conjuntos: altera-se SOMENTE a lista de preditores.
conjuntos <- list(
  COMPLETO_6 = todas_vars,
  SEM_BIO12 = setdiff(todas_vars,'bio12_mm_ano'),
  SEM_BIO17 = setdiff(todas_vars,'bio17_mm_mes'),
  SEM_BIO12_BIO17 = setdiff(todas_vars,c('bio12_mm_ano','bio17_mm_mes')),
  SEM_ALTITUDE = setdiff(todas_vars,'altitude_m'),
  SEM_SOLO = setdiff(todas_vars,'textura_subgrupo')
)
if (length(conjuntos)!=6L || any(lengths(conjuntos)<4L))
  stop('Definicao dos conjuntos de variaveis invalida.')

# ---------------------------------------------------------------------------
# Conferencia da referencia M1 (LQH/RM4, com seis preditores).
# NUNCA gravamos ou alteramos arquivos na pasta R08.
# ---------------------------------------------------------------------------
pasta_m1 <- file.path(raiz,'06 - Resultados','06 - MaxEnt M1 - Grade 72 V3')
arq_manifesto_m1 <- file.path(pasta_m1,'08_MANIFESTO_ENTRADAS.csv')
arq_metricas_m1 <- file.path(pasta_m1,'08_METRICAS_72_MODELOS.csv')
if (!file.exists(arq_manifesto_m1) || !file.exists(arq_metricas_m1))
  stop('R08 nao encontrado. Preserve 08_MANIFESTO_ENTRADAS.csv e 08_METRICAS_72_MODELOS.csv.')
manifesto_m1 <- ler(arq_manifesto_m1)
metricas_m1 <- ler(arq_metricas_m1)
if (!all(c('arquivo','md5','R','maxnet','ecospat') %in% names(manifesto_m1)) ||
    nrow(manifesto_m1)!=4L || nrow(metricas_m1)!=72L ||
    anyDuplicated(metricas_m1$id))
  stop('Manifesto ou metricas M1 inconsistentes.')
for (f in entradas) {
  z <- manifesto_m1[manifesto_m1$arquivo==basename(f),,drop=FALSE]
  if (nrow(z)!=1L ||
      !identical(tolower(as.character(z$md5)),
                 tolower(unname(as.character(tools::md5sum(f))))))
    stop('Entrada mudou desde R08: ',basename(f),
         '. Nao comparar modelos com bancos diferentes.')
}
if (length(unique(manifesto_m1$R))!=1L ||
    length(unique(manifesto_m1$maxnet))!=1L ||
    length(unique(manifesto_m1$ecospat))!=1L ||
    !identical(as.character(manifesto_m1$R[1]),R.version.string) ||
    !identical(as.character(manifesto_m1$maxnet[1]),
               as.character(utils::packageVersion('maxnet'))) ||
    !identical(as.character(manifesto_m1$ecospat[1]),
               as.character(utils::packageVersion('ecospat'))))
  stop('Versao do R/maxnet/ecospat diferente do R08. ',
       'Mantenha o mesmo ambiente para a comparacao controlada.')

especies <- c('Ipe-roxo','Ipe-amarelo')
grade <- expand.grid(especie=especies,fold_cv=1:3,
                     conjunto=names(conjuntos),
                     KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
grade$id <- vapply(seq_len(nrow(grade)),function(i) {
  z <- grade[i,]
  paste0('M2_',ifelse(z$especie=='Ipe-roxo','ROXO','AMARELO'),
         '_F',z$fold_cv,'_',z$conjunto,'_LQH_RM4')
},character(1))
if (nrow(grade)!=36L || anyDuplicated(grade$id))
  stop('A grade M2 deveria ter exatamente 36 avaliacoes.')

# Inspeciona os seis modelos de referencia e inclui seus caminhos no manifesto.
ids_m1 <- character()
arqs_m1_modelos <- character()
arqs_m1_prev <- character()
for (sp in especies) for (f in 1:3) {
  sid <- paste0('M1_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
                '_F',f,'_LQH_RM4')
  ids_m1 <- c(ids_m1,sid)
  arqs_m1_modelos <- c(arqs_m1_modelos,
                       file.path(pasta_m1,'08_MODELOS_RDS',paste0(sid,'.rds')))
  arqs_m1_prev <- c(arqs_m1_prev,
                    file.path(pasta_m1,'08_PREVISOES_VALIDACAO',paste0(sid,'.csv')))
  z <- metricas_m1[metricas_m1$id==sid,,drop=FALSE]
  if (nrow(z)!=1L || z$especie!=sp || z$fold_cv!=f ||
      z$features!='lqh' || z$RM!=4 ||
      !is.finite(z$auc_validacao) || !is.finite(z$omissao10_validacao) ||
      !is.finite(z$boyce_validacao))
    stop('Configuracao M1 LQH/RM4 incompleta: ',sid)
}
if (!all(file.exists(c(arqs_m1_modelos,arqs_m1_prev))))
  stop('Os seis modelos/previsoes LQH/RM4 do R08 devem estar extraidos nas subpastas originais.')

# O manifesto amarra os dados, as metricas e as seis referencias M1.
fontes_hash <- c(entradas,arq_manifesto_m1,arq_metricas_m1,
                 arqs_m1_modelos,arqs_m1_prev)
manifesto <- data.frame(
  arquivo=basename(fontes_hash),
  md5=unname(as.character(tools::md5sum(fontes_hash))),
  versao_script=versao,
  R=R.version.string,
  maxnet=as.character(utils::packageVersion('maxnet')),
  ecospat=as.character(utils::packageVersion('ecospat')),
  stringsAsFactors=FALSE)

saida <- file.path(raiz,'06 - Resultados','08 - MaxEnt M2 - Variaveis V3')
modelos_dir <- file.path(saida,'10_MODELOS_RDS')
pred_dir <- file.path(saida,'10_PREVISOES_VALIDACAO')
checkpoint_dir <- file.path(saida,'10_CHECKPOINT_METRICAS')
graf_dir <- file.path(saida,'10_GRAFICOS')
manifesto_path <- file.path(saida,'10_MANIFESTO_ENTRADAS.csv')
if (!dir.exists(saida)) {
  dir.create(saida,recursive=TRUE,showWarnings=FALSE)
  for (d in c(modelos_dir,pred_dir,checkpoint_dir,graf_dir))
    dir.create(d,recursive=TRUE,showWarnings=FALSE)
  write.csv(manifesto,manifesto_path,row.names=FALSE,fileEncoding='UTF-8')
} else {
  if (!file.exists(manifesto_path))
    stop('Pasta M2 ja existe sem manifesto. Nao sobrescrever seus resultados.')
  manifesto_antigo <- ler(manifesto_path)
  if (!identical(manifesto_antigo,manifesto))
    stop('Arquivos, hashes ou versoes mudaram desde a execucao M2. ',
         'Nao mesclar rodadas diferentes.')
  for (d in c(modelos_dir,pred_dir,checkpoint_dir,graf_dir))
    if (!dir.exists(d)) stop('Subpasta de M2 ausente: ',d)
  cat('\nRetomando M2 com o mesmo manifesto e validando checkpoints...\n')
}

# ---------------------------------------------------------------------------
# Metricas e utilitarios: mesma definicao de R08.
# ---------------------------------------------------------------------------
montar_x <- function(d,variaveis) {
  x <- d[,variaveis,drop=FALSE]
  for (v in intersect(continuas,variaveis))
    x[[v]] <- as.numeric(x[[v]])
  if ('textura_subgrupo' %in% variaveis)
    x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),
                                  levels=as.character(classes_solo))
  if (anyNA(x)) stop('Preditores invalidos ao montar matriz de modelagem.')
  x
}
auc <- function(a,b) {
  a <- as.numeric(a); b <- as.numeric(b)
  if (!length(a) || !length(b) || any(!is.finite(c(a,b))))
    return(NA_real_)
  s <- sum(rank(c(a,b),ties.method='average')[seq_along(a)])
  (s-length(a)*(length(a)+1)/2)/(length(a)*length(b))
}
boyce <- function(a,b) {
  avisos <- character()
  if (min(length(a),length(b))<2L || any(!is.finite(c(a,b))))
    return(list(valor=NA_real_,status='INDEFINIDO: dados insuficientes'))
  z <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(a),
      nclass=0,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
    warning=function(w) {
      avisos <<- c(avisos,conditionMessage(w))
      invokeRestart('muffleWarning')
    }),error=function(e) {avisos <<- c(avisos,conditionMessage(e));NULL})
  valor <- NA_real_
  if (is.list(z) && !is.null(z$cor)) valor <- as.numeric(z$cor)
  else if (is.list(z) && !is.null(z$Spearman.cor))
    valor <- as.numeric(z$Spearman.cor)
  if (length(valor)!=1L || !is.finite(valor) || abs(valor)>1.000001)
    return(list(valor=NA_real_,status=paste0('INDEFINIDO: ',
      if (length(avisos)) paste(unique(avisos),collapse=' | ')
      else 'coeficiente nao disponivel')))
  list(valor=valor,status=if (length(avisos))
    paste('CALCULADO COM AVISO:',paste(unique(avisos),collapse=' | ')) else 'OK')
}
escrever_csv <- function(x,path) {
  tmp <- paste0(path,'.tmp')
  write.csv(x,tmp,row.names=FALSE,fileEncoding='UTF-8')
  if (file.exists(path)) {
    if (!file.copy(tmp,path,overwrite=TRUE))
      stop('Falha ao atualizar: ',path)
    unlink(tmp)
  } else if (!file.rename(tmp,path)) stop('Falha ao salvar: ',path)
}
escrever_rds <- function(x,path) {
  tmp <- paste0(path,'.tmp')
  saveRDS(x,tmp)
  if (!file.rename(tmp,path)) stop('Falha ao salvar modelo: ',path)
}
verificar_prev <- function(pp,vp,vb,referencia,id) {
  req <- c('tipo','propriedade','score_cloglog')
  if (!all(req %in% names(pp))) stop('Previsoes sem campos obrigatorios: ',id)
  a <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
  b <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
  if (nrow(pp)!=(nrow(vp)+nrow(vb)) || length(a)!=nrow(vp) ||
      length(b)!=nrow(vb) || any(!is.finite(c(a,b))) ||
      any(c(a,b)<0 | c(a,b)>1) ||
      !identical(as.character(pp$propriedade[pp$tipo=='PRESENCA_VALIDACAO']),
                 as.character(vp$propriedade)) ||
      !identical(as.character(pp$propriedade[pp$tipo=='BACKGROUND_VALIDACAO']),
                 as.character(vb$propriedade)))
    stop('Previsoes/ordem de propriedades divergentes para ',id)
  if (abs(auc(a,b)-referencia$auc_validacao)>1e-8 ||
      abs(mean(a<referencia$limiar10_treino_cloglog)-
          referencia$omissao10_validacao)>1e-8)
    stop('AUC/omissao recalculadas diferem das metricas: ',id)
  list(a=a,b=b)
}

metricas <- vector('list',nrow(grade))
set.seed(20261111)
for (i in seq_len(nrow(grade))) {
  cfg <- grade[i,]; sp <- cfg$especie; f <- cfg$fold_cv
  conjunto <- cfg$conjunto; variaveis <- conjuntos[[conjunto]]
  id <- cfg$id
  tp <- pres[pres$especie==sp & pres$fold_cv!=f,,drop=FALSE]
  vp <- pres[pres$especie==sp & pres$fold_cv==f,,drop=FALSE]
  tb <- bg[bg$fold_cv!=f,,drop=FALSE]
  vb <- bg[bg$fold_cv==f,,drop=FALSE]
  if (min(nrow(tp),nrow(vp),nrow(tb),nrow(vb))<100L)
    stop('Amostra inesperada no fold: ',id)

  # Referencia: nao refaz o M1 completo, reutiliza modelo e previsoes R08.
  if (conjunto=='COMPLETO_6') {
    nome_m1 <- paste0('M1_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
                      '_F',f,'_LQH_RM4')
    ref <- metricas_m1[metricas_m1$id==nome_m1,,drop=FALSE]
    caminho_modelo <- file.path(pasta_m1,'08_MODELOS_RDS',paste0(nome_m1,'.rds'))
    caminho_pred <- file.path(pasta_m1,'08_PREVISOES_VALIDACAO',paste0(nome_m1,'.csv'))
    mod <- tryCatch(readRDS(caminho_modelo),error=function(e) NULL)
    if (!inherits(mod,'maxnet') || length(mod$betas)!=ref$n_features_ativas)
      stop('Modelo de referencia M1 RDS invalido: ',nome_m1)
    pp <- ler(caminho_pred)
    verificar_prev(pp,vp,vb,ref,nome_m1)
    if (ref$n_presenca_treino!=nrow(tp) ||
        ref$n_background_treino!=nrow(tb) ||
        ref$n_presenca_validacao!=nrow(vp) ||
        ref$n_background_validacao!=nrow(vb))
      stop('Contagens M1 e R05 divergentes: ',nome_m1)
    met <- data.frame(id=id,especie=sp,fold_cv=f,
      conjunto=conjunto,preditores=paste(variaveis,collapse=';'),
      n_preditores=length(variaveis),features='lqh',RM=4,
      n_presenca_treino=nrow(tp),n_background_treino=nrow(tb),
      n_presenca_validacao=nrow(vp),n_background_validacao=nrow(vb),
      auc_treino=ref$auc_treino,auc_validacao=ref$auc_validacao,
      omissao10_treino=ref$omissao10_treino,
      omissao10_validacao=ref$omissao10_validacao,
      limiar10_treino_cloglog=ref$limiar10_treino_cloglog,
      boyce_validacao=ref$boyce_validacao,
      status_boyce_validacao=ref$status_boyce_validacao,
      n_features_ativas=ref$n_features_ativas,
      segundos_ajuste_nesta_rodada=0,
      origem='R08_REUTILIZADO',
      modelo_rds=caminho_modelo,previsoes_csv=caminho_pred,
      previsao='cloglog',clamping=TRUE,
      solo=if ('textura_subgrupo' %in% variaveis) 'fator' else 'ausente',
      stringsAsFactors=FALSE)
    metricas[[i]] <- met
    cat(sprintf('[%02d/36] %s | M1 verificado e reutilizado\n',i,id))
    next
  }

  caminho_rds <- file.path(modelos_dir,paste0(id,'.rds'))
  caminho_pred <- file.path(pred_dir,paste0(id,'.csv'))
  caminho_met <- file.path(checkpoint_dir,paste0(id,'.csv'))
  existente <- file.exists(c(caminho_rds,caminho_pred,caminho_met))
  if (any(existente) && !all(existente))
    stop('Checkpoint M2 incompleto para ',id,
         '. Preserve os arquivos para auditoria; nao sobrescrever.')
  if (all(existente)) {
    mod <- tryCatch(readRDS(caminho_rds),error=function(e) NULL)
    met <- ler(caminho_met)
    pp <- ler(caminho_pred)
    if (!inherits(mod,'maxnet') || nrow(met)!=1L ||
        met$id!=id || met$conjunto!=conjunto ||
        met$preditores!=paste(variaveis,collapse=';') ||
        met$features!='lqh' || met$RM!=4 ||
        length(mod$betas)!=met$n_features_ativas)
      stop('Checkpoint de modelo/metricas inconsistente: ',id)
    verificar_prev(pp,vp,vb,met,id)
    metricas[[i]] <- met
    cat(sprintf('[%02d/36] %s | checkpoint conferido\n',i,id))
    next
  }

  if ('textura_subgrupo' %in% variaveis) {
    cats_treino <- unique(c(as.character(tp$textura_subgrupo),
                            as.character(tb$textura_subgrupo)))
    cats_valid <- unique(c(as.character(vp$textura_subgrupo),
                           as.character(vb$textura_subgrupo)))
    if (!all(cats_valid %in% cats_treino))
      stop('Classe de solo apenas na validacao: ',id)
  }
  xt <- montar_x(rbind(tp[,variaveis,drop=FALSE],
                       tb[,variaveis,drop=FALSE]),variaveis)
  y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
  inicio <- Sys.time()
  fml <- maxnet::maxnet.formula(y,xt,classes='lqh')
  modelo <- maxnet::maxnet(y,xt,f=fml,regmult=4,
                           addsamplestobackground=TRUE)
  predizer <- function(d) as.numeric(stats::predict(
    modelo,montar_x(d,variaveis),type='cloglog',clamp=TRUE))
  stp <- predizer(tp)
  stb <- predizer(tb)
  svp <- predizer(vp)
  svb <- predizer(vb)
  if (any(!is.finite(c(stp,stb,svp,svb))) ||
      any(c(stp,stb,svp,svb)<0 | c(stp,stb,svp,svb)>1))
    stop('Previsoes nao finitas ou fora de [0,1]: ',id)
  limiar <- unname(as.numeric(stats::quantile(stp,probs=0.10,type=7)))
  ib <- boyce(svp,svb)
  met <- data.frame(id=id,especie=sp,fold_cv=f,
    conjunto=conjunto,preditores=paste(variaveis,collapse=';'),
    n_preditores=length(variaveis),features='lqh',RM=4,
    n_presenca_treino=nrow(tp),n_background_treino=nrow(tb),
    n_presenca_validacao=nrow(vp),n_background_validacao=nrow(vb),
    auc_treino=auc(stp,stb),auc_validacao=auc(svp,svb),
    omissao10_treino=mean(stp<limiar),
    omissao10_validacao=mean(svp<limiar),
    limiar10_treino_cloglog=limiar,
    boyce_validacao=ib$valor,status_boyce_validacao=ib$status,
    n_features_ativas=length(modelo$betas),
    segundos_ajuste_nesta_rodada=as.numeric(difftime(Sys.time(),inicio,units='secs')),
    origem='R10_NOVO',modelo_rds=caminho_rds,previsoes_csv=caminho_pred,
    previsao='cloglog',clamping=TRUE,
    solo=if ('textura_subgrupo' %in% variaveis) 'fator' else 'ausente',
    stringsAsFactors=FALSE)
  pp <- rbind(
    data.frame(id=id,especie=sp,fold_cv=f,conjunto=conjunto,
               features='lqh',RM=4,tipo='PRESENCA_VALIDACAO',
               propriedade=vp$propriedade,score_cloglog=svp),
    data.frame(id=id,especie=sp,fold_cv=f,conjunto=conjunto,
               features='lqh',RM=4,tipo='BACKGROUND_VALIDACAO',
               propriedade=vb$propriedade,score_cloglog=svb))
  verificar_prev(pp,vp,vb,met,id)
  escrever_rds(modelo,caminho_rds)
  escrever_csv(pp,caminho_pred)
  escrever_csv(met,caminho_met)
  metricas[[i]] <- met
  cat(sprintf('[%02d/36] %s | AUC=%.3f | omissao=%.3f | Boyce=%s\n',
    i,id,met$auc_validacao,met$omissao10_validacao,
    if (is.finite(met$boyce_validacao)) sprintf('%.3f',met$boyce_validacao)
    else met$status_boyce_validacao))
  parcial <- do.call(rbind,metricas[!vapply(metricas,is.null,logical(1))])
  escrever_csv(parcial,file.path(saida,'10_METRICAS_PARCIAIS.csv'))
}

metricas <- do.call(rbind,metricas)
if (nrow(metricas)!=36L || anyDuplicated(metricas$id) ||
    sum(metricas$origem=='R08_REUTILIZADO')!=6L ||
    sum(metricas$origem=='R10_NOVO')!=30L)
  stop('M2 nao terminou com 36 avaliacoes (6 reutilizadas e 30 novas).')
escrever_csv(metricas,file.path(saida,'10_METRICAS_36_AVALIACOES.csv'))

# Resumo por especie x conjunto, sempre com os 3 folds NAO ponderados.
resumos <- list(); j <- 0L
for (sp in especies) for (co in names(conjuntos)) {
  z <- metricas[metricas$especie==sp & metricas$conjunto==co,,drop=FALSE]
  if (nrow(z)!=3L || !setequal(z$fold_cv,1:3))
    stop('Resumo sem os tres folds: ',sp,' ',co)
  b <- z$boyce_validacao[is.finite(z$boyce_validacao)]
  j <- j+1L
  resumos[[j]] <- data.frame(especie=sp,conjunto=co,
    n_preditores=z$n_preditores[1],folds=3L,
    auc_media=mean(z$auc_validacao),auc_dp=sd(z$auc_validacao),
    auc_min=min(z$auc_validacao),
    omissao10_media=mean(z$omissao10_validacao),
    omissao10_max=max(z$omissao10_validacao),
    boyce_media=if (length(b)) mean(b) else NA_real_,
    boyce_min=if (length(b)) min(b) else NA_real_,
    boyce_dp=if (length(b)>1L) sd(b) else NA_real_,
    n_boyce_validos=length(b),
    n_features_ativas_media=mean(z$n_features_ativas),
    stringsAsFactors=FALSE)
}
resumo <- do.call(rbind,resumos)
escrever_csv(resumo,file.path(saida,'10_RESUMO_12_CONJUNTOS.csv'))

# Diferencas pareadas por fold versus o modelo completo (mesma reg. e validacao).
comparacoes <- list()
for (i in seq_len(nrow(metricas))) {
  z <- metricas[i,,drop=FALSE]
  ref <- metricas[metricas$especie==z$especie &
                 metricas$fold_cv==z$fold_cv &
                 metricas$conjunto=='COMPLETO_6',,drop=FALSE]
  if (nrow(ref)!=1L) stop('Referencia completa ausente para ',z$id)
  comparacoes[[i]] <- data.frame(
    id=z$id,especie=z$especie,fold_cv=z$fold_cv,conjunto=z$conjunto,
    auc=z$auc_validacao,auc_completo=ref$auc_validacao,
    delta_auc=z$auc_validacao-ref$auc_validacao,
    omissao10=z$omissao10_validacao,
    omissao10_completo=ref$omissao10_validacao,
    delta_omissao10=z$omissao10_validacao-ref$omissao10_validacao,
    boyce=z$boyce_validacao,boyce_completo=ref$boyce_validacao,
    delta_boyce=z$boyce_validacao-ref$boyce_validacao,
    n_features_ativas=z$n_features_ativas,
    stringsAsFactors=FALSE)
}
escrever_csv(do.call(rbind,comparacoes),
             file.path(saida,'10_COMPARACAO_VS_COMPLETO_POR_FOLD.csv'))

# AUC e omissao em cada propriedade, usando apenas BG da MESMA propriedade.
props_out <- list(); j <- 0L
for (i in seq_len(nrow(metricas))) {
  z <- metricas[i,]
  p <- ler(z$previsoes_csv)
  for (pr in unique(p$propriedade)) {
    a <- p$score_cloglog[p$propriedade==pr &
                          p$tipo=='PRESENCA_VALIDACAO']
    b <- p$score_cloglog[p$propriedade==pr &
                          p$tipo=='BACKGROUND_VALIDACAO']
    if (!length(a) || !length(b)) next
    j <- j+1L
    suficiente <- min(length(a),length(b))>=10L
    props_out[[j]] <- data.frame(
      id=z$id,especie=z$especie,fold_cv=z$fold_cv,
      conjunto=z$conjunto,propriedade=pr,
      n_presencas=length(a),n_background=length(b),
      auc_propriedade=if (suficiente) auc(a,b) else NA_real_,
      omissao10_propriedade=mean(a<z$limiar10_treino_cloglog),
      status_auc=if (suficiente) 'OK' else 'AMOSTRA_PEQUENA',
      stringsAsFactors=FALSE)
  }
}
if (length(props_out))
  escrever_csv(do.call(rbind,props_out),
               file.path(saida,'10_AUC_E_OMISSAO_POR_PROPRIEDADE.csv'))

# Graficos: tres indicadores por especie, com os seis conjuntos identificados.
rotulos <- c('6 vars','- BIO12','- BIO17','- BIO12/17',
             '- Altitude','- Solo')
for (sp in especies) {
  z <- resumo[resumo$especie==sp,,drop=FALSE]
  z <- z[match(names(conjuntos),z$conjunto),,drop=FALSE]
  if (anyNA(z$conjunto)) stop('Conjunto faltando no resumo de ',sp)
  for (met in c('auc_media','omissao10_media','boyce_media')) {
    arquivo_g <- paste0('10_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
                        '_',toupper(met),'.png')
    png(file.path(graf_dir,arquivo_g),width=1150,height=720,res=135)
    op <- par(mar=c(8,5,4,2))
    valores <- z[[met]]
    ylim <- if (met=='boyce_media') c(-1,1) else c(0,1)
    plot(seq_along(valores),valores,type='b',pch=19,lwd=2,
         xaxt='n',xlab='',ylab=met,ylim=ylim,
         main=paste('MaxEnt M2 -',sp,'-',met))
    axis(1,at=1:6,labels=rotulos,las=2,cex.axis=.82)
    abline(h=if (met=='auc_media') 0.5 else 0,lty=3,col='gray55')
    par(op)
    dev.off()
  }
}

writeLines(c(
  'TCC IPES - R10 V3 - M2: comparacao de conjuntos de variaveis',
  '36 avaliacoes: 6 M1 LQH/RM4 reutilizadas e verificadas; 30 novos ajustes.',
  'Mesmos 5000 pontos de background e particao espacial do R05/R08.',
  'Features LQH e regularizacao RM=4 fixas nos seis conjuntos.',
  'Preditores: 6; sem BIO12; sem BIO17; sem ambos; sem altitude; sem solo.',
  'Solo e fator quando presente. Previsao cloglog com clamping TRUE.',
  'AUC avalia presencas versus background, nao ausencia verdadeira.',
  'Omissao10 usa limiar definido nas presencas de treino.',
  'Boyce por ecospat; observar o status individual por fold.',
  'AUC por propriedade usa presencas e background da propria propriedade.',
  'Medias de tres folds nao ponderadas; olhar principalmente as falhas espaciais.',
  'Modelos M1/R08 NAO foram alterados e permanecem na pasta R08.',
  'Nenhuma propriedade de teste externo usada para selecao.',
  'Esta rodada NAO prova causalidade nem seleciona modelo final.',
  'Correlacao, autocorrelacao, clamping e novidade multivariada nao sao ',
  'corrigidos automaticamente por este script.',
  paste('Data:',as.character(Sys.time())),
  paste('R:',R.version.string),
  paste('maxnet:',as.character(utils::packageVersion('maxnet'))),
  paste('ecospat:',as.character(utils::packageVersion('ecospat'))),
  'Manifesto MD5 em 10_MANIFESTO_ENTRADAS.csv.'
),file.path(saida,'10_LEIA_RESULTADOS.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),
           file.path(saida,'10_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR10 CONCLUIDO!\n')
cat('Ajustes: 30 novos, 6 referencias reaproveitadas = 36 avaliacoes.\n')
cat('Resultados em: ',saida,'\n',sep='')
cat('Envie a pasta de resultados compactada (ZIP) para auditoria.\n')
