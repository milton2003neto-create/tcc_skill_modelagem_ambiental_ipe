# TCC IPES | R08 - Grade de 72 ajustes MaxEnt/maxnet | V3 M1
# Criado em 11/11/2026. Requer entradas oficiais do R05 V3.1.
# Exploratorio: 2 especies x 3 folds x 3 classes (L, LQ, LQH) x 4 RM (1-4).
# SEIS preditores fixos, mesmo background e folds do M0. Sem teste externo.
# AUC presencia-background do fold; omissao10 do treino; Boyce ecospat integrado.
# Checkpoints por modelo e retomada segura com hash dos arquivos de entrada.
# Nao seleciona automaticamente modelo vencedor e nao altera M0.

if (!requireNamespace('maxnet',quietly=TRUE))
  stop("Instale maxnet: install.packages('maxnet')")
if (!requireNamespace('ecospat',quietly=TRUE))
  stop("Instale ecospat: install.packages('ecospat')")
versao <- 'R08_V3_M1_72_20261111'
cat('\nR08 | Selecione 05_PRESENCAS_UM_POR_PIXEL_30M.csv, gerado pelo R05.\n')
arq_pres <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(arq_pres) != '05_PRESENCAS_UM_POR_PIXEL_30M.csv')
  stop('Arquivo incorreto: selecione o CSV de presencas por pixel 30 m do R05.')
entrada <- dirname(arq_pres)
raiz <- dirname(dirname(entrada))
if (basename(entrada) != '04 - Presencas e folds V3' ||
    basename(dirname(entrada)) != '04 - Dados para o MaxEnt' ||
    !dir.exists(file.path(raiz,'03 - Trabalho no QGIS')))
  stop('A estrutura da raiz do TCC nao corresponde ao projeto V3 oficial.')
arq_bg <- file.path(entrada,'05_BACKGROUND_COM_FOLDS.csv')
arq_total <- file.path(entrada,'05_PRESENCAS_TODAS_DESENVOLVIMENTO.csv')
arq_folds <- file.path(entrada,'05_RESUMO_FOLDS.csv')
entradas <- c(arq_pres,arq_bg,arq_total,arq_folds)
if (!all(file.exists(entradas))) stop('Arquivos necessarios do R05 estao ausentes.')
ler <- function(f) read.csv(f,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE,
                            check.names=FALSE)
pres <- ler(arq_pres); bg <- ler(arq_bg); total <- ler(arq_total)
resumo05 <- ler(arq_folds)
cont <- c('altitude_m','declividade_graus','dist_rio_raster_m',
          'bio12_mm_ano','bio17_mm_mes')
vars <- c(cont,'textura_subgrupo')
cp <- c('especie','propriedade','upa_id','fold_cv','celula_raster',vars)
cb <- c('propriedade','upa_id','fold_cv','celula_raster','id_background',vars)
if (!all(cp %in% names(pres)) || !all(cb %in% names(bg)) ||
    !all(c('especie','fold_cv','n_presencas_pixel_30m','n_background') %in% names(resumo05)))
  stop('Campos obrigatorios nao existem. Verifique a saida do R05.')
if (nrow(pres)!=8680L || nrow(bg)!=5000L || nrow(total)!=9004L ||
    sum(pres$especie=='Ipe-roxo')!=3248L ||
    sum(pres$especie=='Ipe-amarelo')!=5432L ||
    nrow(resumo05)!=6L ||
    !setequal(unique(pres$especie),c('Ipe-roxo','Ipe-amarelo')))
  stop('Contagens de entrada diferem do R05 auditado; interrompido.')
if (anyNA(pres[,cp,drop=FALSE]) || anyNA(bg[,cb,drop=FALSE]) ||
    any(!is.finite(as.matrix(pres[,vars,drop=FALSE]))) ||
    any(!is.finite(as.matrix(bg[,vars,drop=FALSE]))))
  stop('Dados ausentes ou nao finitos nas entradas do R05.')
if (anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster)) ||
    anyDuplicated(paste(bg$propriedade,bg$celula_raster)) ||
    anyDuplicated(bg$id_background))
  stop('Duplicidade de presenca por especie/pixel ou de background.')
if (length(unique(bg$propriedade))!=27L ||
    length(unique(bg$upa_id))!=64L ||
    !setequal(unique(pres$propriedade),unique(bg$propriedade)) ||
    !setequal(unique(pres$fold_cv),1:3) ||
    !setequal(unique(bg$fold_cv),1:3))
  stop('Propriedades, UPAs ou folds diferem da particao auditada.')
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ','LOTE 01',
              'MARILIA','PALMEIRA')
if (any(pres$propriedade %in% externas) || any(bg$propriedade %in% externas))
  stop('VAZAMENTO DO TESTE EXTERNO: nenhum modelo sera ajustado.')
fo <- unique(rbind(pres[,c('propriedade','fold_cv')],
                   bg[,c('propriedade','fold_cv')]))
if (any(vapply(split(fo$fold_cv,fo$propriedade),function(z)
               length(unique(z))!=1L,logical(1))))
  stop('Uma propriedade foi dividida entre folds!')
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (k in 1:3) {
  x <- resumo05[resumo05$especie==sp & resumo05$fold_cv==k,,drop=FALSE]
  if (nrow(x)!=1L ||
      x$n_presencas_pixel_30m != sum(pres$especie==sp & pres$fold_cv==k) ||
      x$n_background != sum(bg$fold_cv==k))
    stop('Contagens de fold divergem do R05: ',sp,' F',k)
}
solo <- sort(unique(c(pres$textura_subgrupo,bg$textura_subgrupo)))
if (!identical(as.integer(solo),c(2L,3L,4L,6L,7L)))
  stop('Classes de solo diferentes das registradas no protocolo V3.')
montar_x <- function(d) {
  x <- d[,vars,drop=FALSE]
  for (v in cont) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),
                               levels=as.character(solo))
  if (anyNA(x)) stop('Solo nao pode ser fator com NA.')
  x
}
auc <- function(a,b) {
  a <- as.numeric(a); b <- as.numeric(b)
  if (!length(a) || !length(b) || any(!is.finite(c(a,b)))) return(NA_real_)
  sum_r <- sum(rank(c(a,b),ties.method='average')[seq_along(a)])
  (sum_r-length(a)*(length(a)+1)/2)/(length(a)*length(b))
}
boyce <- function(a,b) {
  avisos <- character()
  if (length(a)<2L || length(b)<2L || any(!is.finite(c(a,b))))
    return(list(valor=NA_real_,status='INDEFINIDO: amostras ou scores invalidos'))
  z <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(a),
      nclass=0,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
    warning=function(w) {
      avisos <<- c(avisos,conditionMessage(w))
      invokeRestart('muffleWarning')
    }),error=function(e) {avisos <<- c(avisos,conditionMessage(e)); NULL})
  v <- NA_real_
  if (is.list(z) && !is.null(z$cor)) v <- as.numeric(z$cor)
  else if (is.list(z) && !is.null(z$Spearman.cor)) v <- as.numeric(z$Spearman.cor)
  if (length(v)!=1L || !is.finite(v) || abs(v)>1.000001)
    return(list(valor=NA_real_,
      status=paste('INDEFINIDO:',if(length(avisos)) paste(unique(avisos),collapse=' | ')
                   else 'coeficiente nao disponivel')))
  list(valor=v,status=if(length(avisos))
    paste('CALCULADO COM AVISO:',paste(unique(avisos),collapse=' | ')) else 'OK')
}

# Grade fixa, para comparacao justa: somente features e RM mudam.
grade <- expand.grid(especie=c('Ipe-roxo','Ipe-amarelo'),fold_cv=1:3,
                     features=c('l','lq','lqh'),RM=c(1,2,3,4),
                     KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
if (nrow(grade)!=72L) stop('Grade deveria conter 72 ajustes.')
grade$id <- vapply(seq_len(nrow(grade)),function(i) {
  x <- grade[i,]
  paste0('M1_',ifelse(x$especie=='Ipe-roxo','ROXO','AMARELO'),
         '_F',x$fold_cv,'_',toupper(x$features),'_RM',x$RM)
},character(1))
saida <- file.path(raiz,'06 - Resultados','06 - MaxEnt M1 - Grade 72 V3')
modelos_dir <- file.path(saida,'08_MODELOS_RDS')
pred_dir <- file.path(saida,'08_PREVISOES_VALIDACAO')
met_dir <- file.path(saida,'08_CHECKPOINT_METRICAS')
graf_dir <- file.path(saida,'08_GRAFICOS')
manifesto_path <- file.path(saida,'08_MANIFESTO_ENTRADAS.csv')
manifesto <- data.frame(arquivo=basename(entradas),md5=unname(tools::md5sum(entradas)),
  versao_script=versao,R=R.version.string,
  maxnet=as.character(utils::packageVersion('maxnet')),
  ecospat=as.character(utils::packageVersion('ecospat')),
  stringsAsFactors=FALSE)
if (!dir.exists(saida)) {
  dir.create(saida,recursive=TRUE,showWarnings=FALSE)
  for (d in c(modelos_dir,pred_dir,met_dir,graf_dir))
    dir.create(d,recursive=TRUE,showWarnings=FALSE)
  write.csv(manifesto,manifesto_path,row.names=FALSE,fileEncoding='UTF-8')
} else {
  if (!file.exists(manifesto_path))
    stop('Pasta de resultados existente sem manifesto: nao sobrescrever.')
  anterior <- ler(manifesto_path)
  if (!identical(anterior,manifesto))
    stop('Entradas, hashes, versao do R/pacotes ou script mudaram: nao mesclar execucoes.')
  for (d in c(modelos_dir,pred_dir,met_dir,graf_dir))
    if (!dir.exists(d)) stop('Subpasta de checkpoints ausente: ',d)
  cat('\nRetomada de execucao anterior com manifesto identico.\n')
}
# Escrita atomica para evitar checkpoints CSV/RDS parcialmente gravados.
escrever_csv <- function(x,path) {
  tmp <- paste0(path,'.tmp')
  write.csv(x,tmp,row.names=FALSE,fileEncoding='UTF-8')
  if (file.exists(path)) {
    # Windows nao substitui sempre o destino de file.rename.
    if (!file.copy(tmp,path,overwrite=TRUE))
      stop('Falha ao atualizar arquivo consolidado: ',path)
    unlink(tmp)
  } else if (!file.rename(tmp,path)) {
    stop('Falha ao salvar arquivo: ',path)
  }
}
escrever_rds <- function(x,path) {
  tmp <- paste0(path,'.tmp')
  saveRDS(x,tmp)
  if (!file.rename(tmp,path)) stop('Falha ao salvar modelo: ',path)
}
# M0 original: apenas verificador de reprodutibilidade (nunca altera seus resultados).
caminho_m0 <- file.path(raiz,'06 - Resultados',
   '04 - MaxEnt M0 - Validacao espacial V3','06_METRICAS_FOLDS_M0.csv')
m0 <- if(file.exists(caminho_m0)) ler(caminho_m0) else NULL
metricas <- vector('list',nrow(grade))
set.seed(20261111)
for (i in seq_len(nrow(grade))) {
  cfg <- grade[i,]; sp <- cfg$especie; f <- cfg$fold_cv
  id <- cfg$id; feat <- cfg$features; rm <- cfg$RM
  caminho_rds <- file.path(modelos_dir,paste0(id,'.rds'))
  caminho_pred <- file.path(pred_dir,paste0(id,'.csv'))
  caminho_met <- file.path(met_dir,paste0(id,'.csv'))
  existentes <- file.exists(c(caminho_rds,caminho_pred,caminho_met))
  if (any(existentes) && !all(existentes))
    stop('Checkpoint incompleto para ',id,'. Preserve a pasta e audite os arquivos.')
  if (all(existentes)) {
    met <- ler(caminho_met); pp <- ler(caminho_pred)
    mod <- tryCatch(readRDS(caminho_rds),error=function(e) NULL)
    if (nrow(met)!=1L || !inherits(mod,'maxnet') ||
        !identical(as.character(met$id),id) ||
        !all(c('tipo','score_cloglog','propriedade') %in% names(pp)) ||
        nrow(pp)!=met$n_presenca_validacao+met$n_background_validacao ||
        any(!is.finite(pp$score_cloglog)))
      stop('Checkpoint inconsistente: ',id)
    p <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
    b <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
    if(length(p)!=met$n_presenca_validacao || length(b)!=met$n_background_validacao ||
       abs(auc(p,b)-met$auc_validacao)>1e-8 ||
       abs(mean(p<met$limiar10_treino_cloglog)-met$omissao10_validacao)>1e-8)
      stop('AUC/omissao de checkpoint nao confere: ',id)
    metricas[[i]] <- met
    cat(sprintf('[%02d/72] %s | checkpoint validado\n',i,id))
    next
  }
  tp <- pres[pres$especie==sp & pres$fold_cv!=f,,drop=FALSE]
  vp <- pres[pres$especie==sp & pres$fold_cv==f,,drop=FALSE]
  tb <- bg[bg$fold_cv!=f,,drop=FALSE]
  vb <- bg[bg$fold_cv==f,,drop=FALSE]
  if (min(nrow(tp),nrow(vp),nrow(tb),nrow(vb))<100L)
    stop('Fold com amostras insuficientes: ',id)
  categorias_treino <- unique(c(as.character(tp$textura_subgrupo),
                                 as.character(tb$textura_subgrupo)))
  categorias_valid <- unique(c(as.character(vp$textura_subgrupo),
                                as.character(vb$textura_subgrupo)))
  if (!all(categorias_valid %in% categorias_treino))
    stop('Classe de solo nao presente no treino: ',id)
  xt <- montar_x(rbind(tp[,vars,drop=FALSE],tb[,vars,drop=FALSE]))
  y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
  inicio <- Sys.time()
  formula <- maxnet::maxnet.formula(y,xt,classes=feat)
  modelo <- maxnet::maxnet(y,xt,f=formula,regmult=rm,
                           addsamplestobackground=TRUE)
  stp <- as.numeric(stats::predict(modelo,montar_x(tp),type='cloglog',clamp=TRUE))
  stb <- as.numeric(stats::predict(modelo,montar_x(tb),type='cloglog',clamp=TRUE))
  svp <- as.numeric(stats::predict(modelo,montar_x(vp),type='cloglog',clamp=TRUE))
  svb <- as.numeric(stats::predict(modelo,montar_x(vb),type='cloglog',clamp=TRUE))
  if (any(!is.finite(c(stp,stb,svp,svb))) ||
      any(c(stp,stb,svp,svb)<0 | c(stp,stb,svp,svb)>1))
    stop('Previsao nao finita ou fora de [0,1]: ',id)
  limiar <- as.numeric(stats::quantile(stp,probs=.10,type=7))
  ib <- boyce(svp,svb)
  met <- data.frame(id=id,especie=sp,fold_cv=f,features=feat,RM=rm,
    n_presenca_treino=nrow(tp),n_background_treino=nrow(tb),
    n_presenca_validacao=nrow(vp),n_background_validacao=nrow(vb),
    auc_treino=auc(stp,stb),auc_validacao=auc(svp,svb),
    omissao10_treino=mean(stp<limiar),omissao10_validacao=mean(svp<limiar),
    limiar10_treino_cloglog=limiar,boyce_validacao=ib$valor,
    status_boyce_validacao=ib$status,
    n_features_ativas=length(modelo$betas),
    segundos_ajuste=as.numeric(difftime(Sys.time(),inicio,units='secs')),
    previsao='cloglog',clamping=TRUE,solo='fator',
    stringsAsFactors=FALSE)
  pp <- rbind(
    data.frame(id=id,especie=sp,fold_cv=f,features=feat,RM=rm,
      tipo='PRESENCA_VALIDACAO',propriedade=vp$propriedade,score_cloglog=svp),
    data.frame(id=id,especie=sp,fold_cv=f,features=feat,RM=rm,
      tipo='BACKGROUND_VALIDACAO',propriedade=vb$propriedade,score_cloglog=svb))
  if (!is.null(m0) && feat=='lq' && rm==2) {
    ref <- m0[m0$especie==sp & m0$fold_cv==f,,drop=FALSE]
    if (nrow(ref)!=1L ||
        abs(met$auc_validacao-ref$auc_validacao_vs_bg_validacao)>1e-8 ||
        abs(met$omissao10_validacao-ref$omissao10_validacao)>1e-8)
      stop('M1 LQ RM2 nao reproduziu o M0: ',id,
           '. Nenhum modelo deste ajuste foi gravado.')
  }
  escrever_rds(modelo,caminho_rds)
  escrever_csv(pp,caminho_pred)
  escrever_csv(met,caminho_met)
  metricas[[i]] <- met
  cat(sprintf('[%02d/72] %s | AUC=%.3f | Omissao=%.3f | Boyce=%s | %d coeficientes\n',
    i,id,met$auc_validacao,met$omissao10_validacao,
    if(is.finite(ib$valor)) sprintf('%.3f',ib$valor) else ib$status,
    met$n_features_ativas))
  # O consolidado parcial permite conferir progresso sem alterar checkpoints.
  parcial <- do.call(rbind,metricas[!vapply(metricas,is.null,logical(1))])
  escrever_csv(parcial,file.path(saida,'08_METRICAS_PARCIAIS.csv'))
}
metricas <- do.call(rbind,metricas)
if (nrow(metricas)!=72L || anyDuplicated(metricas$id))
  stop('A grade nao terminou com 72 linhas unicas.')
escrever_csv(metricas,file.path(saida,'08_METRICAS_72_MODELOS.csv'))
# As medias sao por fold (nao ponderadas por quantidade de presencas).
resumos <- list(); j <- 0L
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (fc in c('l','lq','lqh')) for (rm in 1:4) {
  z <- metricas[metricas$especie==sp & metricas$features==fc & metricas$RM==rm,,drop=FALSE]
  if (nrow(z)!=3L || !setequal(z$fold_cv,1:3)) stop('Resumo sem tres folds.')
  v <- z$boyce_validacao[is.finite(z$boyce_validacao)]
  j <- j+1L
  resumos[[j]] <- data.frame(especie=sp,features=fc,RM=rm,
    folds=3L,auc_media=mean(z$auc_validacao),
    auc_dp=sd(z$auc_validacao),auc_min=min(z$auc_validacao),
    omissao10_media=mean(z$omissao10_validacao),
    omissao10_max=max(z$omissao10_validacao),
    boyce_media=if(length(v)) mean(v) else NA_real_,
    boyce_min=if(length(v)) min(v) else NA_real_,
    boyce_dp=if(length(v)>1L) sd(v) else NA_real_,
    n_boyce_validos=length(v),
    n_features_ativas_media=mean(z$n_features_ativas))
}
resumo <- do.call(rbind,resumos)
resumo <- resumo[order(resumo$especie,-resumo$auc_media),,drop=FALSE]
escrever_csv(resumo,file.path(saida,'08_RESUMO_24_CONFIGURACOES.csv'))
# Diagnostico por propriedade, calculado contra background da propria propriedade.
prop_tabelas <- list(); k <- 0L
for (ii in seq_len(nrow(metricas))) {
  z <- metricas[ii,]
  p <- ler(file.path(pred_dir,paste0(z$id,'.csv')))
  props <- unique(p$propriedade)
  for (pr in props) {
    a <- p$score_cloglog[p$propriedade==pr & p$tipo=='PRESENCA_VALIDACAO']
    b <- p$score_cloglog[p$propriedade==pr & p$tipo=='BACKGROUND_VALIDACAO']
    if (!length(a) || !length(b)) next
    k <- k+1L
    prop_tabelas[[k]] <- data.frame(id=z$id,especie=z$especie,
      fold_cv=z$fold_cv,features=z$features,RM=z$RM,propriedade=pr,
      n_presencas=length(a),n_background=length(b),
      auc_propriedade=if(min(length(a),length(b))>=10) auc(a,b) else NA_real_,
      omissao10_propriedade=mean(a<z$limiar10_treino_cloglog),
      status_auc=if(min(length(a),length(b))>=10) 'OK' else 'AMOSTRA_PEQUENA')
  }
}
if (length(prop_tabelas))
  escrever_csv(do.call(rbind,prop_tabelas),
              file.path(saida,'08_AUC_E_OMISSAO_POR_PROPRIEDADE.csv'))
# Tres indicadores por especie; graficos exploratorios, nao ranking final.
for (sp in c('Ipe-roxo','Ipe-amarelo')) {
  z <- resumo[resumo$especie==sp,,drop=FALSE]
  for (metrica in c('auc_media','omissao10_media','boyce_media')) {
    nome <- paste0('08_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),'_',
                   toupper(metrica),'.png')
    png(file.path(graf_dir,nome),width=1050,height=680,res=130)
    op <- par(mar=c(5,5,4,2))
    ylim <- if (metrica=='boyce_media') c(-1,1) else c(0,1)
    plot(1:4,rep(NA_real_,4),type='n',ylim=ylim,xlim=c(1,4),xaxt='n',
         xlab='Multiplicador de regularizacao (RM)',
         ylab=metrica,main=paste('MaxEnt M1:',sp,metrica))
    axis(1,at=1:4)
    abline(h=if(metrica=='auc_media') .5 else 0,lty=3,col='gray65')
    cores <- c('gray25','gray50','gray75'); nomes <- c('L','LQ','LQH')
    for (jj in 1:3) {
      zz <- z[z$features==tolower(nomes[jj]),,drop=FALSE]
      zz <- zz[order(zz$RM),]
      lines(zz$RM,zz[[metrica]],type='b',pch=14+jj,lwd=2,col=cores[jj])
    }
    legend('topright',legend=nomes,lty=1,pch=15:17,col=cores,bty='n')
    par(op); dev.off()
  }
}
writeLines(c('R08 V3 - M1: 72 modelos exploratorios, 24 configuracoes por especie/3 folds',
  'Os seis preditores, os 5.000 backgrounds e os folds do M0 foram mantidos.',
  'Nao acessar as 7 propriedades externas de teste para selecionar modelos.',
  'Solo e fator; previsao cloglog com clamping; AUC contra BG do proprio fold.',
  'Boyce calculado durante cada ajuste com ecospat e BG do fold de validacao.',
  'Omissao 10% aplica limiar definido apenas no treino.',
  'M0 LQ RM2, quando presente, e conferencia de reproducao: AUC/omissao.',
  'Medias de 3 folds sao nao ponderadas; interpretar os folds individualmente.',
  'O desempenho intra-propriedade pode diferir muito do global.',
  'Nao selecionar vencedor apenas pela media de AUC; examinar Boyce, omissao,',
  'heterogeneidade, extrapolacao ambiental e curvas de resposta.',
  'Particao espacial por proximidade de 1 km NAO garante independencia ecologica.',
  'A analise de variaveis e do numero de pontos de background sera posterior,',
  'mantendo esta rodada de seis variaveis como referencia de controle.',
  paste('Data:',as.character(Sys.time())),
  paste('R:',R.version.string),
  paste('maxnet:',as.character(utils::packageVersion('maxnet'))),
  paste('ecospat:',as.character(utils::packageVersion('ecospat'))),
  'Hashes SHA/MD5 das entradas no 08_MANIFESTO_ENTRADAS.csv.'),
  file.path(saida,'08_LEIA_RESULTADOS.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),
  file.path(saida,'08_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR08 FINALIZADO: 72 ajustes, 24 configuracoes (12 por especie).\n')
cat('Resultados: ',saida,'\n',sep='')
cat('Envie a pasta de resultados inteira em ZIP para auditoria antes de escolher modelos.\n')
