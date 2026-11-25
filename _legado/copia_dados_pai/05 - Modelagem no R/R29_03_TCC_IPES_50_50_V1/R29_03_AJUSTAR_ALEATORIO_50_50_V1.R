# =============================================================================
# TCC IPES | R29 Parte 3 - REFERENCIA ALEATORIA 50/50 (2 MODELOS MAXENT)
# =============================================================================
# Comparacao EXPLORATORIA de sorteio dentro de especie x UPA elaborado em R27.
# NAO e validacao espacial independente, NAO substitui avaliacao por UPA,
# propriedade, regiao ou as SETE PROPRIEDADES EXTERNAS reservadas.
# Nao utiliza arquivos externos, nao sorteia novos pontos e nao seleciona modelo.
# Parametros iguais aos modelos de referencia R28: LQH / RM 4 / 6 variaveis,
# textura fator, cloglog, clamping e addsamplestobackground=TRUE.
# Execute usando Source no RStudio, mantendo a estrutura do ZIP.
# =============================================================================
versao <- 'R29_03_ALEATORIO_50_50_B2_V1_20261118'
for (pacote in c('maxnet','ecospat')) {
  if (!requireNamespace(pacote,quietly=TRUE)) {
    stop('Pacote ausente: ',pacote,'. Execute install.packages("',pacote,'")')
  }
}

localizar_pasta <- function() {
  fontes <- unlist(lapply(sys.frames(),function(f) {
    if (is.null(f$ofile)) character(0) else as.character(f$ofile)
  }),use.names=FALSE)
  if (length(fontes)) {
    p <- dirname(normalizePath(tail(fontes,1),winslash='/',mustWork=TRUE))
    if (file.exists(file.path(p,'29_03_MANIFESTO_ENTRADAS.csv'))) return(p)
  }
  if (file.exists('29_03_MANIFESTO_ENTRADAS.csv')) {
    return(normalizePath('.',winslash='/',mustWork=TRUE))
  }
  stop('Extraia o ZIP inteiro e execute o script na pasta principal.')
}
pasta <- localizar_pasta()
entrada <- file.path(pasta,'01_ENTRADAS_CONGELADAS')
saida <- file.path(pasta,'03_RESULTADOS_ALEATORIO_50_50_V1')
ler <- function(p) utils::read.csv(p,fileEncoding='UTF-8-BOM',
                                   check.names=FALSE,stringsAsFactors=FALSE)
exigir <- function(ok,msg) {
  if (!isTRUE(ok)) stop('R29-03: ',msg,call.=FALSE)
}
colunas <- function(d,nomes,nome) {
  faltam <- setdiff(nomes,names(d))
  exigir(length(faltam)==0L,paste(nome,'sem colunas:',paste(faltam,collapse=', ')))
}
md5 <- function(p) unname(tools::md5sum(p))
escrever_csv <- function(d,p) {
  tmp <- paste0(p,'.tmp')
  utils::write.csv(d,tmp,row.names=FALSE,fileEncoding='UTF-8')
  if (file.exists(p)) {
    exigir(file.copy(tmp,p,overwrite=TRUE),paste('Nao foi possivel salvar',p))
    unlink(tmp)
  } else {
    exigir(file.rename(tmp,p),paste('Nao foi possivel salvar',p))
  }
}
salvar_rds <- function(d,p) {
  tmp <- paste0(p,'.tmp')
  saveRDS(d,tmp,compress=TRUE)
  exigir(file.rename(tmp,p),paste('Falha ao salvar checkpoint:',p))
}
auc <- function(p,b) {
  p <- as.numeric(p);b <- as.numeric(b)
  if (!length(p) || !length(b) || any(!is.finite(c(p,b)))) return(NA_real_)
  n <- length(p)
  (sum(rank(c(p,b),ties.method='average')[seq_len(n)])-
     n*(n+1)/2)/(n*length(b))
}
boyce <- function(p,b,nclass=0) {
  avisos <- character(0)
  if (length(p)<2L || length(b)<2L || any(!is.finite(c(p,b)))) {
    return(list(valor=NA_real_,status='INDEFINIDO: dados insuficientes'))
  }
  z <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(p),
        nclass=nclass,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
    warning=function(w) {
      avisos <<- c(avisos,conditionMessage(w))
      invokeRestart('muffleWarning')
    }),error=function(e) {
      avisos <<- c(avisos,conditionMessage(e));NULL
    })
  valor <- NA_real_
  if (is.list(z) && !is.null(z$cor)) {
    valor <- as.numeric(z$cor)
  } else if (is.list(z) && !is.null(z$Spearman.cor)) {
    valor <- as.numeric(z$Spearman.cor)
  }
  if (length(valor)!=1L || !is.finite(valor) || abs(valor)>1.000001) {
    return(list(valor=NA_real_,status=paste('INDEFINIDO',paste(unique(avisos),collapse=' | '))))
  }
  list(valor=valor,status=if (length(avisos))
    paste('AVISO',paste(unique(avisos),collapse=' | ')) else 'OK')
}

# ----------------------------------------------------------------------------
# PREFLIGHT: conferir cada arquivo ANTES de criar modelos ou arquivos de saida.
# ----------------------------------------------------------------------------
manifesto <- ler(file.path(pasta,'29_03_MANIFESTO_ENTRADAS.csv'))
colunas(manifesto,c('caminho_relativo','md5','bytes'),'Manifesto')
exigir(nrow(manifesto)==4L && !anyDuplicated(manifesto$caminho_relativo),
       'Manifesto diferente das quatro entradas congeladas.')
for (i in seq_len(nrow(manifesto))) {
  caminho <- file.path(pasta,manifesto$caminho_relativo[i])
  exigir(file.exists(caminho),paste('Arquivo nao encontrado:',caminho))
  exigir(identical(tolower(md5(caminho)),tolower(as.character(manifesto$md5[i]))),
         paste('MD5 diferente do original:',basename(caminho)))
  exigir(identical(as.numeric(file.info(caminho)$size),as.numeric(manifesto$bytes[i])),
         paste('Tamanho de arquivo diferente:',basename(caminho)))
}
pres <- ler(file.path(entrada,'05_PRESENCAS_UM_POR_PIXEL_30M.csv'))
bg <- ler(file.path(entrada,'18_BACKGROUND_B2_10000_COM_FOLDS.csv'))
pl_pres <- ler(file.path(entrada,'27_ALEATORIO_50_50_PRESENCAS.csv'))
pl_bg <- ler(file.path(entrada,'27_ALEATORIO_50_50_BACKGROUND.csv'))
continuas <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
seis <- c(continuas,'textura_subgrupo')
especies <- c('Ipe-roxo','Ipe-amarelo')
colunas(pres,c('especie','upa_id','propriedade','linha_csv','celula_raster',seis),'Presencas')
colunas(bg,c('id_background','upa_id','propriedade','celula_raster',seis),'Background')
colunas(pl_pres,c('indice_linha_fonte','papel','especie','upa_id'),'Plano presencas')
colunas(pl_bg,c('indice_linha_fonte','papel','id_background','upa_id'),'Plano background')
exigir(nrow(pres)==8680L && nrow(bg)==10000L &&
       nrow(pl_pres)==8680L && nrow(pl_bg)==10000L,
       'Dimensoes diferentes do R27 auditado.')
exigir(identical(as.integer(pl_pres$indice_linha_fonte),seq_len(nrow(pres))) &&
       identical(as.integer(pl_bg$indice_linha_fonte),seq_len(nrow(bg))),
       'Ordem da linha original mudou. NAO reordenar as tabelas.')
exigir(identical(as.character(pl_pres$especie),as.character(pres$especie)) &&
       identical(as.character(pl_pres$upa_id),as.character(pres$upa_id)) &&
       identical(as.character(pl_bg$id_background),as.character(bg$id_background)) &&
       identical(as.character(pl_bg$upa_id),as.character(bg$upa_id)),
       'IDs e UPAs do sorteio R27 nao correspondem as fontes.')
exigir(all(pl_pres$papel %in% c('TREINO','VALIDACAO')) &&
       all(pl_bg$papel %in% c('TREINO','VALIDACAO')) &&
       !anyNA(c(pl_pres$papel,pl_bg$papel)),
       'Papeis diferentes de TREINO/VALIDACAO.')
exigir(sum(pl_pres$papel=='TREINO')==4326L &&
       sum(pl_pres$papel=='VALIDACAO')==4354L &&
       sum(pl_bg$papel=='TREINO')==4986L &&
       sum(pl_bg$papel=='VALIDACAO')==5014L,
       'Quantidades de 50/50 divergentes do R27.')
exigir(sum(pres$especie=='Ipe-roxo')==3248L &&
       sum(pres$especie=='Ipe-amarelo')==5432L,
       'Quantidades por especie divergentes.')
exigir(length(unique(bg$upa_id))==64L && length(unique(bg$propriedade))==27L &&
       all(unique(pres$upa_id) %in% unique(bg$upa_id)),
       'UPAs/propriedades divergentes do R27.')
exigir(!anyDuplicated(bg$id_background) &&
       !anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster)),
       'IDs B2 ou celulas de presenca duplicadas.')
exigir(!anyNA(pres[,seis,drop=FALSE]) && !anyNA(bg[,seis,drop=FALSE]),
       'Preditores com NA.')
for (v in continuas) {
  exigir(is.numeric(pres[[v]]) && is.numeric(bg[[v]]) &&
         all(is.finite(pres[[v]])) && all(is.finite(bg[[v]])),
         paste('Preditor invalido:',v))
}
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
exigir(!any(c(pres$propriedade,bg$propriedade) %in% externas),
       'Propriedade do teste externo presente; interrompido.')
exigir(identical(as.character(utils::packageVersion('maxnet')),'0.1.4') &&
       identical(as.character(utils::packageVersion('ecospat')),'4.1.4'),
       'Versoes esperadas do protocolo: maxnet 0.1.4 / ecospat 4.1.4.')
niveis <- as.character(sort(unique(as.integer(c(pres$textura_subgrupo,
                                              bg$textura_subgrupo)))))
exigir(identical(as.integer(niveis),c(2L,3L,4L,6L,7L)),
       'Categorias de solo diferentes do protocolo.')
pres$indice_linha_fonte <- seq_len(nrow(pres))
bg$indice_linha_fonte <- seq_len(nrow(bg))

montar_x <- function(d) {
  x <- d[,seis,drop=FALSE]
  for (v in continuas) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),levels=niveis)
  exigir(!anyNA(x),'Falha ao montar matriz ambiental (NA).')
  x
}
prever <- function(mod,d,rotulo) {
  s <- tryCatch(as.numeric(stats::predict(mod,montar_x(d),
         type='cloglog',clamp=TRUE)),
         error=function(e) stop('Falha ao prever ',rotulo,': ',
                                conditionMessage(e),call.=FALSE))
  exigir(length(s)==nrow(d) && all(is.finite(s)) && all(s>=0 & s<=1),
         paste('Score de previsao invalido em',rotulo))
  s
}
criar_prev <- function(d,sp,id,tipo,s) {
  data.frame(id=id,especie=sp,cenario_id='ALEATORIO_50_50_R27',
             tipo=tipo,propriedade=as.character(d$propriedade),
             upa_id=as.character(d$upa_id),
             indice_linha_fonte=as.integer(d$indice_linha_fonte),
             celula_raster=as.character(d$celula_raster),
             linha_csv=if ('linha_csv' %in% names(d)) as.character(d$linha_csv)
                       else NA_character_,
             id_background=if ('id_background' %in% names(d))
               as.character(d$id_background) else NA_character_,
             score_cloglog=as.numeric(s),stringsAsFactors=FALSE)
}
metrica_local <- function(p,b,lim,esp,escala,id) {
  unids <- sort(unique(if (escala=='UPA') p$upa_id else p$propriedade))
  if (!length(unids)) return(data.frame())
  saidas <- vector('list',length(unids))
  for (j in seq_along(unids)) {
    u <- unids[j]
    a <- if (escala=='UPA') p[p$upa_id==u,,drop=FALSE]
         else p[p$propriedade==u,,drop=FALSE]
    bb <- if (escala=='UPA') b[b$upa_id==u,,drop=FALSE]
          else b[b$propriedade==u,,drop=FALSE]
    ok <- nrow(a)>=10L && nrow(bb)>=10L
    saidas[[j]] <- data.frame(id=id,especie=esp,escala=escala,unidade=u,
      propriedade=as.character(a$propriedade[1]),
      n_presencas=nrow(a),n_background=nrow(bb),n_pares=nrow(a)*nrow(bb),
      auc_local=if (ok) auc(a$score_cloglog,bb$score_cloglog) else NA_real_,
      omissao_p10=mean(a$score_cloglog<lim),
      status_auc=if (ok) 'OK' else 'AMOSTRA_LOCAL_PEQUENA')
  }
  do.call(rbind,saidas)
}

# A linha do sorteio R27 e a UNIDADE de identidade, nao refazer o sorteio.
plano <- list()
for (i in seq_along(especies)) {
  sp <- especies[i]
  id <- paste0('R29_03_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
               '_ALEATORIO_50_50_LQH_RM4')
  tp <- pres[pres$especie==sp & pl_pres$papel=='TREINO',,drop=FALSE]
  vp <- pres[pres$especie==sp & pl_pres$papel=='VALIDACAO',,drop=FALSE]
  tb <- bg[pl_bg$papel=='TREINO',,drop=FALSE]
  vb <- bg[pl_bg$papel=='VALIDACAO',,drop=FALSE]
  esperado <- if (sp=='Ipe-roxo') c(1620L,1628L) else c(2706L,2726L)
  exigir(identical(c(nrow(tp),nrow(vp)),esperado) &&
         nrow(tb)==4986L && nrow(vb)==5014L,
         paste('Contagens inesperadas:',id))
  exigir(!any(tp$indice_linha_fonte %in% vp$indice_linha_fonte) &&
         !any(tb$id_background %in% vb$id_background),
         paste('Vazamento de IDs entre treino e validacao:',id))
  exigir(setequal(c(tp$indice_linha_fonte,vp$indice_linha_fonte),
                  pres$indice_linha_fonte[pres$especie==sp]) &&
         setequal(c(tb$id_background,vb$id_background),bg$id_background),
         paste('Sorteio nao preserva todos os indices:',id))
  lev_treino <- unique(c(as.character(tp$textura_subgrupo),
                         as.character(tb$textura_subgrupo)))
  lev_val <- unique(c(as.character(vp$textura_subgrupo),
                      as.character(vb$textura_subgrupo)))
  exigir(length(setdiff(lev_val,lev_treino))==0L,
         paste('Categoria de solo na validacao ausente no treino:',id))
  exigir(length(unique(tp$upa_id))==length(unique(vp$upa_id)) &&
         setequal(unique(tp$upa_id),unique(vp$upa_id)) &&
         setequal(unique(tb$upa_id),unique(vb$upa_id)),
         paste('Sorteio nao cobre as UPAs em ambos os papeis:',id))
  plano[[i]] <- data.frame(id=id,especie=sp,
    n_presencas_treino=nrow(tp),n_presencas_validacao=nrow(vp),
    n_bg_treino=nrow(tb),n_bg_validacao=nrow(vb),
    n_upas_com_presenca_treino=length(unique(tp$upa_id)),
    n_upas_com_presenca_validacao=length(unique(vp$upa_id)),
    n_upas_bg_treino=length(unique(tb$upa_id)),
    n_upas_bg_validacao=length(unique(vb$upa_id)),
    niveis_solo_treino=paste(sort(lev_treino),collapse=';'),
    niveis_solo_validacao=paste(sort(lev_val),collapse=';'))
}
plano <- do.call(rbind,plano)
cat('R29-03 PREFLIGHT OK: 2 modelos, sorteio R27 congelado,',
    ' 8680 presencas, 10000 pontos B2; teste externo preservado.\n')
print(plano[,c('especie','n_presencas_treino','n_presencas_validacao',
               'n_bg_treino','n_bg_validacao')],row.names=FALSE)

# ----------------------------------------------------------------------------
# SO DEPOIS DO PREFLIGHT: criar saidas e executar os DOIS modelos.
# ----------------------------------------------------------------------------
dir.create(saida,showWarnings=FALSE,recursive=TRUE)
cpdir <- file.path(saida,'29_03_CHECKPOINTS')
modeldir <- file.path(saida,'29_03_MODELOS_RDS')
prevdir <- file.path(saida,'29_03_PREVISOES')
grafdir <- file.path(saida,'29_03_GRAFICOS')
for (d in c(cpdir,modeldir,prevdir,grafdir)) {
  dir.create(d,showWarnings=FALSE,recursive=TRUE)
}
escrever_csv(manifesto,file.path(saida,'29_03_MANIFESTO_ENTRADAS.csv'))
escrever_csv(plano,file.path(saida,'29_03_PLANO_CONFERIDO.csv'))
metricas <- vector('list',2L)
locprop <- vector('list',2L)
locupa <- vector('list',2L)
for (i in seq_along(especies)) {
  sp <- especies[i]
  id <- plano$id[i]
  tp <- pres[pres$especie==sp & pl_pres$papel=='TREINO',,drop=FALSE]
  vp <- pres[pres$especie==sp & pl_pres$papel=='VALIDACAO',,drop=FALSE]
  tb <- bg[pl_bg$papel=='TREINO',,drop=FALSE]
  vb <- bg[pl_bg$papel=='VALIDACAO',,drop=FALSE]
  checkpoint <- file.path(cpdir,paste0(id,'.rds'))
  if (file.exists(checkpoint)) {
    ck <- tryCatch(readRDS(checkpoint),error=function(e)NULL)
    exigir(is.list(ck) && identical(ck$id,id) &&
           identical(ck$versao,versao) &&
           identical(as.character(ck$md5_entradas),as.character(manifesto$md5)) &&
           inherits(ck$modelo,'maxnet') &&
           nrow(ck$previsoes)==nrow(tp)+nrow(vp)+nrow(tb)+nrow(vb),
           paste('Checkpoint corrompido/diferente:',id))
    pval <- ck$previsoes$score_cloglog[
      ck$previsoes$tipo=='PRESENCA_VALIDACAO']
    bval <- ck$previsoes$score_cloglog[
      ck$previsoes$tipo=='BACKGROUND_VALIDACAO']
    exigir(length(pval)==nrow(vp) && length(bval)==nrow(vb) &&
           abs(auc(pval,bval)-ck$metricas$auc_validacao_b2)<1e-8 &&
           abs(mean(pval<ck$metricas$limiar_p10_treino)-
               ck$metricas$omissao_p10_validacao)<1e-8,
           paste('Checkpoint nao reproduz metricas:',id))
    cat(sprintf('[%d/2] %s: checkpoint conferido, sem reajuste.\n',i,id))
  } else {
    y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
    x <- rbind(montar_x(tp),montar_x(tb))
    exigir(nrow(x)==length(y) && identical(names(x),seis),
           paste('Matriz de treino invalida:',id))
    cat(sprintf('[%d/2] Ajustando %s: %d presencas + %d BG ...\n',
                i,id,nrow(tp),nrow(tb)))
    tempo <- Sys.time()
    mod <- tryCatch({
      fm <- maxnet::maxnet.formula(y,x,classes='lqh')
      maxnet::maxnet(y,x,f=fm,regmult=4,addsamplestobackground=TRUE)
    },error=function(e) stop('Falha maxnet: ',conditionMessage(e),call.=FALSE))
    segundos <- as.numeric(difftime(Sys.time(),tempo,units='secs'))
    exigir(inherits(mod,'maxnet'),'O ajuste nao produziu objeto maxnet.')
    stp <- prever(mod,tp,'presencas treino')
    stb <- prever(mod,tb,'background treino')
    svp <- prever(mod,vp,'presencas validacao')
    svb <- prever(mod,vb,'background validacao')
    lim <- as.numeric(stats::quantile(stp,probs=0.1,type=7,names=FALSE))
    bo0 <- boyce(svp,svb,nclass=0)
    bo10 <- boyce(svp,svb,nclass=10)
    pp <- rbind(
      criar_prev(tp,sp,id,'PRESENCA_TREINO',stp),
      criar_prev(tb,sp,id,'BACKGROUND_TREINO',stb),
      criar_prev(vp,sp,id,'PRESENCA_VALIDACAO',svp),
      criar_prev(vb,sp,id,'BACKGROUND_VALIDACAO',svb))
    p_val <- pp[pp$tipo=='PRESENCA_VALIDACAO',,drop=FALSE]
    b_val <- pp[pp$tipo=='BACKGROUND_VALIDACAO',,drop=FALSE]
    lp <- metrica_local(p_val,b_val,lim,sp,'PROPRIEDADE',id)
    lu <- metrica_local(p_val,b_val,lim,sp,'UPA',id)
    pares <- lp[is.finite(lp$auc_local),,drop=FALSE]
    a_intra <- if (nrow(pares)) sum(pares$auc_local*pares$n_pares)/sum(pares$n_pares)
               else NA_real_
    met <- data.frame(id=id,especie=sp,
      tipo_validacao='ALEATORIO_50_50_EXPLORATORIO_NAO_ESPACIAL',
      features='lqh',RM=4L,n_preditores=6L,
      n_presencas_treino=nrow(tp),n_background_treino=nrow(tb),
      n_presencas_validacao=nrow(vp),n_background_validacao=nrow(vb),
      auc_treino=auc(stp,stb),auc_validacao_b2=auc(svp,svb),
      auc_intra_propriedade_ponderada=a_intra,
      boyce_validacao=bo0$valor,status_boyce=bo0$status,
      boyce_nclass10=bo10$valor,status_boyce_nclass10=bo10$status,
      limiar_p10_treino=lim,omissao_p10_treino=mean(stp<lim),
      omissao_p10_validacao=mean(svp<lim),
      fracao_bg_acima_p10=mean(svb>=lim),
      mediana_score_presencas_validacao=stats::median(svp),
      mediana_score_bg_validacao=stats::median(svb),
      numero_coeficientes=length(mod$betas),
      tempo_ajuste_segundos=segundos,
      status='EXPLORATORIO_50_50',stringsAsFactors=FALSE)
    ck <- list(versao=versao,id=id,md5_entradas=manifesto$md5,
               modelo=mod,metricas=met,previsoes=pp,
               por_propriedade=lp,por_upa=lu)
    salvar_rds(ck,checkpoint)
    cat(sprintf('  AUC = %.3f | omissao P10 = %.2f%% | Boyce = %s\n',
      met$auc_validacao_b2,100*met$omissao_p10_validacao,
      if (is.finite(met$boyce_validacao)) sprintf('%.3f',met$boyce_validacao)
      else 'NA'))
  }
  metricas[[i]] <- ck$metricas
  locprop[[i]] <- ck$por_propriedade
  locupa[[i]] <- ck$por_upa
  rds_file <- file.path(modeldir,paste0(id,'.rds'))
  if (file.exists(rds_file)) {
    antigo <- tryCatch(readRDS(rds_file),error=function(e)NULL)
    exigir(inherits(antigo,'maxnet') &&
           isTRUE(all.equal(antigo$betas,ck$modelo$betas)),
           paste('RDS oficial difere do checkpoint:',id))
  } else {
    salvar_rds(ck$modelo,rds_file)
  }
  escrever_csv(ck$previsoes,file.path(prevdir,paste0(id,'.csv')))
  parcial <- do.call(rbind,metricas[!vapply(metricas,is.null,logical(1))])
  escrever_csv(parcial,file.path(saida,'29_03_METRICAS_PARCIAIS.csv'))
}

met <- do.call(rbind,metricas)
prop <- do.call(rbind,locprop)
upa <- do.call(rbind,locupa)
exigir(nrow(met)==2L && !anyDuplicated(met$id) &&
       all(is.finite(met$auc_validacao_b2)) &&
       all(is.finite(met$omissao_p10_validacao)),
       'Resultado final incompleto ou invalido.')
escrever_csv(met,file.path(saida,'29_03_METRICAS_2_MODELOS.csv'))
escrever_csv(prop,file.path(saida,'29_03_RESULTADO_POR_PROPRIEDADE.csv'))
escrever_csv(upa,file.path(saida,'29_03_RESULTADO_POR_UPA.csv'))

# Dois graficos automaticos para o TCC.
png(file.path(grafdir,'29_03_COMPARACAO_AUC_P10.png'),width=1250,height=700,res=145)
op <- par(mfrow=c(1,2),mar=c(5,5,3,1)+0.1)
nomes <- ifelse(met$especie=='Ipe-roxo','Ipe-roxo','Ipe-amarelo')
barplot(met$auc_validacao_b2,names.arg=nomes,col=c('#426C81','#BC874E'),
        ylim=c(0,1),ylab='AUC (presencas x background)',
        main='AUC de validacao 50/50')
abline(h=0.5,lty=2,col='gray55')
barplot(100*met$omissao_p10_validacao,names.arg=nomes,
        col=c('#426C81','#BC874E'),ylim=c(0,100),
        ylab='Omissao P10 (%)',main='Omissao P10 50/50')
par(op);dev.off()

for (i in seq_along(especies)) {
  sp <- especies[i]
  id <- met$id[i]
  q <- ler(file.path(prevdir,paste0(id,'.csv')))
  p <- q$score_cloglog[q$tipo=='PRESENCA_VALIDACAO']
  b <- q$score_cloglog[q$tipo=='BACKGROUND_VALIDACAO']
  png(file.path(grafdir,paste0('29_03_DISTRIBUICAO_',
      if (sp=='Ipe-roxo') 'ROXO' else 'AMARELO','.png')),
      width=1250,height=760,res=145)
  op <- par(mar=c(5,5,4,2))
  hist(b,breaks=35,freq=FALSE,col=grDevices::adjustcolor('#777777',alpha.f=0.45),
       border=NA,xlim=c(0,1),main=paste('50/50 -',sp),
       xlab='Score cloglog de validacao',ylab='Densidade')
  hist(p,breaks=35,freq=FALSE,col=grDevices::adjustcolor('#3779AD',alpha.f=0.38),
       border=NA,add=TRUE)
  abline(v=met$limiar_p10_treino[i],col='#BD3D3D',lty=2,lwd=2)
  legend('topright',legend=c('Background B2','Presencas','Limiar P10 do treino'),
         fill=c('#999999','#3779AD',NA),border=NA,bty='n')
  par(op);dev.off()
}
rel <- c('TCC IPES | R29 PARTE 3 - REFERENCIA ALEATORIA 50/50',
         paste('Protocolo:',versao),
         paste('Executado:',as.character(Sys.time())),
         'Duas especies; 2 modelos novos. Particao R27 50/50 congelada.',
         'Treino e validacao podem compartilhar as MESMAS UPAs.',
         'ISSO NAO E VALIDACAO ESPACIAL INDEPENDENTE.',
         'MaxEnt maxnet / LQH / RM4 / 6 preditores; textura fator.',
         'Background B2 da area inventariada de desenvolvimento, sorteio R27.',
         'AUC e Boyce: presencas versus background (NAO ausencia confirmada).',
         'Boyce com nclass 0 (protocolo R28) e 10 (sensibilidade).',
         'P10 derivado SOMENTE dos scores de presencas no treinamento.',
         'NENHUMA propriedade do teste externo e usada.',
         'Nao comparar metricas com paineis R28 como validacao da mesma escala.',
         'Amostragem aleatoria espacialmente dependente pode ser otimista.',
         'Nao selecionar modelo final pelo 50/50.',
         '', 'METRICAS:')
for (i in seq_len(nrow(met))) {
  r <- met[i,,drop=FALSE]
  rel <- c(rel,sprintf('%s | AUC %.3f | AUC intra-prop %.3f | omissao %.2f%% | Boyce %s | Boyce10 %s',
    r$especie,r$auc_validacao_b2,r$auc_intra_propriedade_ponderada,
    100*r$omissao_p10_validacao,
    if (is.finite(r$boyce_validacao)) sprintf('%.3f',r$boyce_validacao) else 'NA',
    if (is.finite(r$boyce_nclass10)) sprintf('%.3f',r$boyce_nclass10) else 'NA'))
}
writeLines(rel,file.path(saida,'29_03_RELATORIO_EXECUCAO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'29_03_SESSION_INFO.txt'))
cat('\nR29 PARTE 3 CONCLUIDO: dois modelos 50/50 gerados e conferidos.\n',
    'Resultados:',saida,'\n',
    'Envie a pasta 03_RESULTADOS_ALEATORIO_50_50_V1 compactada.\n',sep='')
