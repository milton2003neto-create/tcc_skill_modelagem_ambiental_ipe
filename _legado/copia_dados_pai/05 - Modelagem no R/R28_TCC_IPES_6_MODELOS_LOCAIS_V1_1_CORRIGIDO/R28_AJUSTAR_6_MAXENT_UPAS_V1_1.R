# =============================================================================
# TCC IPES | R28 V1.1 - SEIS MODELOS MAXENT (VALIDACAO LOCAL ENTRE UPAS)
# =============================================================================
# PLANO CONGELADO: R27 V1, 3 paineis por especie, UPAs INTEIRAS reservadas.
# Parametros: 6 preditores, textura fator, features LQH, RM=4, B2 original.
# ESTRITAMENTE EXPLORATORIO: UPAs de treino e validacao podem ser contiguas.
# NAO representa transferencia regional independente e NAO escolhe modelo final.
# NAO mexe em R01-R27, folds originais, RDS anteriores ou teste externo.
# Execute na pasta extraida: source('R28_AJUSTAR_6_MAXENT_UPAS_V1_1.R')
# Saidas: 03_RESULTADOS_R28_V1_1/ (permite retomar checkpoints).
# =============================================================================

versao <- 'R28_UPAS_B2_LQH_RM4_V1_1_20261118'
for (pacote in c('maxnet', 'ecospat')) {
  if (!requireNamespace(pacote, quietly=TRUE))
    stop('Instale o pacote ', pacote, ': install.packages("', pacote, '")')
}

localizar_pasta <- function() {
  of <- unlist(lapply(sys.frames(), function(f) {
    if (is.null(f$ofile)) character(0) else as.character(f$ofile)
  }), use.names=FALSE)
  if (length(of)) {
    p <- dirname(normalizePath(tail(of,1), winslash='/', mustWork=TRUE))
    if (file.exists(file.path(p,'28_MANIFESTO_CONGELADO.csv'))) return(p)
  }
  if (file.exists('28_MANIFESTO_CONGELADO.csv'))
    return(normalizePath('.',winslash='/',mustWork=TRUE))
  stop('R28: extraia o pacote inteiro e rode o R28 na pasta principal do ZIP; ',
       'nao mova o script isoladamente.')
}
pasta <- localizar_pasta()
entrada <- file.path(pasta,'01_ENTRADAS_CONGELADAS')
planos <- file.path(pasta,'02_PLANO_CONGELADO')
saida <- file.path(pasta,'03_RESULTADOS_R28_V1_1')
ler <- function(p) utils::read.csv(p,fileEncoding='UTF-8-BOM',check.names=FALSE,
                                   stringsAsFactors=FALSE)
exigir <- function(ok,msg) {
  if(!isTRUE(ok)) stop('R28: ',msg,call.=FALSE)
}
colunas <- function(d,cols,rotulo) {
  f <- setdiff(cols,names(d))
  exigir(length(f)==0L,paste(rotulo,'sem colunas:',paste(f,collapse=', ')))
}
md5 <- function(p) unname(tools::md5sum(p))
escrever_csv <- function(d,p) {
  tmp <- paste0(p,'.tmp')
  utils::write.csv(d,tmp,row.names=FALSE,fileEncoding='UTF-8')
  if(file.exists(p)) {
    exigir(file.copy(tmp,p,overwrite=TRUE),paste('Falha ao atualizar:',p))
    unlink(tmp)
  } else exigir(file.rename(tmp,p),paste('Falha ao gravar:',p))
}
salvar_rds <- function(d,p) {
  tmp <- paste0(p,'.tmp')
  saveRDS(d,tmp,compress=TRUE)
  exigir(file.rename(tmp,p),paste('Falha ao salvar:',p))
}
auc <- function(p,b) {
  p <- as.numeric(p); b <- as.numeric(b)
  if(!length(p) || !length(b) || any(!is.finite(c(p,b)))) return(NA_real_)
  n <- length(p)
  (sum(rank(c(p,b),ties.method='average')[seq_len(n)])-
     n*(n+1)/2)/(n*length(b))
}
boyce <- function(p,b) {
  avisos <- character()
  if(length(p)<2L || length(b)<2L || any(!is.finite(c(p,b))))
    return(list(valor=NA_real_,status='INDEFINIDO: amostra invalida'))
  z <- tryCatch(withCallingHandlers(
      ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(p),
       nclass=0,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
      warning=function(w){ avisos <<- c(avisos,conditionMessage(w));
                           invokeRestart('muffleWarning') }),
      error=function(e){avisos <<- c(avisos,conditionMessage(e));NULL})
  valor <- NA_real_
  if(is.list(z) && !is.null(z$cor)) valor <- as.numeric(z$cor)
  else if(is.list(z) && !is.null(z$Spearman.cor))
    valor <- as.numeric(z$Spearman.cor)
  if(length(valor)!=1L || !is.finite(valor) || abs(valor)>1.000001)
    return(list(valor=NA_real_,status=paste('INDEFINIDO:',
       if(length(avisos)) paste(unique(avisos),collapse=' | ') else 'sem coeficiente')))
  list(valor=valor,status=if(length(avisos)) paste('AVISO:',
     paste(unique(avisos),collapse=' | ')) else 'OK')
}

# -----------------------------------------------------------------------------
# 1 - Verificacao previa (NENHUM modelo ajustado antes desta secao terminar)
# -----------------------------------------------------------------------------
manifesto <- ler(file.path(pasta,'28_MANIFESTO_CONGELADO.csv'))
colunas(manifesto,c('caminho_relativo','md5','bytes'),'Manifesto')
exigir(nrow(manifesto)==5L && !anyDuplicated(manifesto$caminho_relativo),
       'O manifesto deve conter exatamente cinco fontes distintas.')
for(i in seq_len(nrow(manifesto))) {
  f <- file.path(pasta,manifesto$caminho_relativo[i])
  exigir(file.exists(f),paste('Arquivo ausente:',f))
  exigir(identical(tolower(md5(f)),tolower(manifesto$md5[i])),
         paste('MD5 alterado:',basename(f),'. Reextraia o ZIP original.'))
  exigir(identical(as.numeric(file.info(f)$size),as.numeric(manifesto$bytes[i])),
         paste('Tamanho alterado:',basename(f)))
}
pres <- ler(file.path(entrada,'05_PRESENCAS_UM_POR_PIXEL_30M.csv'))
bg <- ler(file.path(entrada,'18_BACKGROUND_B2_10000_COM_FOLDS.csv'))
papeis <- ler(file.path(planos,'27_PAPEIS_64_UPAS_POR_CENARIO.csv'))
resumo <- ler(file.path(planos,'27_RESUMO_6_PAINEIS.csv'))
reservas <- ler(file.path(planos,'27_UPAS_RESERVADAS_PAINEIS.csv'))
continuas <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
seis <- c(continuas,'textura_subgrupo')
especies <- c('Ipe-roxo','Ipe-amarelo')
cenarios <- sprintf('LOCAL_UPAS_%02d',1:3)
colunas(pres,c('propriedade','upa_id','especie','fold_cv','celula_raster',
              'linha_csv',seis),'Presencas R05')
colunas(bg,c('propriedade','upa_id','fold_cv','id_background','celula_raster',seis),
        'Background B2 R18')
colunas(papeis,c('cenario_id','especie','propriedade','upa_id','papel',
                 'n_presencas_especie','n_bg_b2'),'Papeis R27')
colunas(resumo,c('cenario_id','especie','n_upas_validacao',
  'n_presencas_validacao','n_background_validacao','n_presencas_treino',
  'n_background_treino','status'),'Resumo R27')
colunas(reservas,c('especie','cenario_id','upa_id','propriedade'),
        'Reservas R27')
exigir(nrow(pres)==8680L && nrow(bg)==10000L && nrow(papeis)==384L &&
       nrow(resumo)==6L && nrow(reservas)==19L,
       'Tamanhos das tabelas nao reproduzem o R27 auditado.')
exigir(sum(pres$especie=='Ipe-roxo')==3248L &&
       sum(pres$especie=='Ipe-amarelo')==5432L,
       'Totais de especies diferentes do R27.')
exigir(length(unique(bg$upa_id))==64L &&
       length(unique(bg$propriedade))==27L &&
       all(unique(pres$upa_id) %in% unique(bg$upa_id)),
       'UPAs de presencas e de BG nao correspondem.')
exigir(setequal(unique(resumo$especie),especies) &&
       setequal(unique(resumo$cenario_id),cenarios) &&
       !anyDuplicated(paste(resumo$especie,resumo$cenario_id)),
       'Seis paineis R27 faltantes ou duplicados.')
exigir(!anyDuplicated(paste(papeis$especie,papeis$cenario_id,papeis$upa_id)),
       'Duplicidade de especie/cenario/UPA no plano R27.')
exigir(!anyNA(pres[,c('propriedade','upa_id','especie','fold_cv',seis)]) &&
       !anyNA(bg[,c('propriedade','upa_id','fold_cv',seis)]),
       'Valores ou identificadores ausentes nos preditores.')
for(v in continuas) {
  exigir(is.numeric(pres[[v]]) && is.numeric(bg[[v]]) &&
         all(is.finite(pres[[v]])) && all(is.finite(bg[[v]])),
         paste('Preditor numerico invalido:',v))
}
exigir(!anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster)) &&
       !anyDuplicated(bg$id_background),
       'Duplicidade de presenca/pixel ou ID de background B2.')
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
exigir(!any(c(pres$propriedade,bg$propriedade) %in% externas),
       'Propriedade EXTERNA detectada. Nenhum ajuste permitido.')
exigir(identical(as.character(utils::packageVersion('maxnet')),'0.1.4') &&
       identical(as.character(utils::packageVersion('ecospat')),'4.1.4'),
       'Versoes diferentes do R19/R22: requer maxnet 0.1.4 e ecospat 4.1.4.')

niveis <- as.character(sort(unique(as.integer(c(pres$textura_subgrupo,
                                              bg$textura_subgrupo)))))
exigir(identical(as.integer(niveis),c(2L,3L,4L,6L,7L)),
       'Categorias de textura fora do protocolo R19/R22.')
montar_x <- function(d) {
  x <- d[,seis,drop=FALSE]
  for(v in continuas) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),levels=niveis)
  exigir(!anyNA(x),'Preditor convertido em NA em montar_x().')
  x
}
prever <- function(mod,x,rotulo) {
  s <- tryCatch(as.numeric(stats::predict(mod,montar_x(x),
                            type='cloglog',clamp=TRUE)),
      error=function(e) stop('Falha na previsao de ',rotulo,': ',
                             conditionMessage(e),call.=FALSE))
  exigir(length(s)==nrow(x) && all(is.finite(s)) &&
         all(s>=0 & s<=1),paste('Score invalido:',rotulo))
  s
}

plano <- expand.grid(especie=especies,cenario_id=cenarios,
                     KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
plano$id <- paste0('R28_',ifelse(plano$especie=='Ipe-roxo','ROXO','AMARELO'),
                   '_',plano$cenario_id,'_LQH_RM4')
plano$n_val <- NA_integer_; plano$n_bg_val <- NA_integer_
plano$n_train <- NA_integer_; plano$n_bg_train <- NA_integer_
audit_solo <- list()
for(i in seq_len(nrow(plano))) {
  z <- plano[i,,drop=FALSE]
  rr <- papeis[papeis$especie==z$especie &
               papeis$cenario_id==z$cenario_id,,drop=FALSE]
  rv <- rr$upa_id[rr$papel=='VALIDACAO']
  exigir(nrow(rr)==64L && length(rv)>=2L &&
         !anyDuplicated(rr$upa_id) &&
         setequal(rr$upa_id,unique(bg$upa_id)) &&
         all(rr$papel %in% c('TREINO','VALIDACAO')),
         paste('Plano de UPA invalido:',z$id))
  ps <- pres[pres$especie==z$especie,,drop=FALSE]
  tp <- ps[!(ps$upa_id %in% rv),,drop=FALSE]
  vp <- ps[ps$upa_id %in% rv,,drop=FALSE]
  tb <- bg[!(bg$upa_id %in% rv),,drop=FALSE]
  vb <- bg[bg$upa_id %in% rv,,drop=FALSE]
  esperado <- resumo[resumo$especie==z$especie &
     resumo$cenario_id==z$cenario_id,,drop=FALSE]
  exigir(nrow(esperado)==1L &&
         nrow(tp)==esperado$n_presencas_treino &&
         nrow(vp)==esperado$n_presencas_validacao &&
         nrow(tb)==esperado$n_background_treino &&
         nrow(vb)==esperado$n_background_validacao &&
         length(rv)==esperado$n_upas_validacao &&
         setequal(rv,reservas$upa_id[reservas$especie==z$especie &
            reservas$cenario_id==z$cenario_id]),
         paste('Contagens/UPAs diferentes do planejamento R27:',z$id))
  exigir(nrow(tp)>=1000L && nrow(vp)>=250L &&
         nrow(tb)>=5000L && nrow(vb)>=180L,
         paste('Amostra de treino ou validacao insuficiente:',z$id))
  exigir(!any(tp$upa_id %in% rv) && !any(tb$upa_id %in% rv) &&
         all(vp$upa_id %in% rv) && all(vb$upa_id %in% rv),
         paste('Possivel vazamento de UPA:',z$id))
  exigir(sum(rr$n_presencas_especie[rr$papel=='VALIDACAO'])==nrow(vp) &&
         sum(rr$n_bg_b2[rr$papel=='VALIDACAO'])==nrow(vb),
         paste('Contagens do mapa R27 divergentes:',z$id))
  cat_treino <- sort(unique(c(as.character(tp$textura_subgrupo),
                              as.character(tb$textura_subgrupo))))
  cat_val <- sort(unique(c(as.character(vp$textura_subgrupo),
                           as.character(vb$textura_subgrupo))))
  desconhecidos <- setdiff(cat_val,cat_treino)
  exigir(length(desconhecidos)==0L,
         paste('Solo: classes sem representacao no treino:',z$id,
               paste(desconhecidos,collapse=',')))
  audit_solo[[i]] <- data.frame(id=z$id,especie=z$especie,
    cenario_id=z$cenario_id,niveis_treino=paste(cat_treino,collapse=';'),
    niveis_validacao=paste(cat_val,collapse=';'),
    niveis_sem_treino=paste(desconhecidos,collapse=';'),
    status='OK',stringsAsFactors=FALSE)
  plano$n_val[i] <- nrow(vp); plano$n_bg_val[i] <- nrow(vb)
  plano$n_train[i] <- nrow(tp); plano$n_bg_train[i] <- nrow(tb)
}
cat('R28 PREFLIGHT OK: 6 paineis, 8680 presencas, 10000 BG B2,',
    ' 64 UPAs; sem classes de solo novas na validacao.\n')

# -----------------------------------------------------------------------------
# 2 - Somente agora criar saidas. Nenhuma entrada ou resultado anterior e alterado.
# -----------------------------------------------------------------------------
dir.create(saida,showWarnings=FALSE,recursive=TRUE)
cpdir <- file.path(saida,'28_CHECKPOINTS')
moddir <- file.path(saida,'28_MODELOS_RDS')
prevdir <- file.path(saida,'28_PREVISOES')
grafdir <- file.path(saida,'28_GRAFICOS')
for(d in c(cpdir,moddir,prevdir,grafdir))
  dir.create(d,showWarnings=FALSE,recursive=TRUE)
escrever_csv(manifesto,file.path(saida,'28_MANIFESTO_CONGELADO.csv'))
escrever_csv(plano,file.path(saida,'28_PLANO_CONFERIDO.csv'))
escrever_csv(do.call(rbind,audit_solo),file.path(saida,'28_AUDITORIA_SOLO.csv'))

fazer_previsoes <- function(d,sp,id,papel,tipo,score) {
  data.frame(id=id,especie=sp,cenario_id=papel,tipo=tipo,
    propriedade=as.character(d$propriedade),upa_id=as.character(d$upa_id),
    celula_raster=as.character(d$celula_raster),
    linha_csv=if('linha_csv' %in% names(d)) as.character(d$linha_csv)
                else NA_character_,
    id_background=if('id_background' %in% names(d))
      as.character(d$id_background) else NA_character_,
    score_cloglog=score,stringsAsFactors=FALSE)
}
resultado_local <- function(pr,bg,lim,met_tipo,z) {
  props <- if(met_tipo=='propriedade') unique(pr$propriedade)
           else unique(pr$upa_id)
  out <- vector('list',length(props))
  for(j in seq_along(props)) {
    k <- props[j]
    p <- if(met_tipo=='propriedade') pr[pr$propriedade==k,,drop=FALSE]
         else pr[pr$upa_id==k,,drop=FALSE]
    b <- if(met_tipo=='propriedade') bg[bg$propriedade==k,,drop=FALSE]
         else bg[bg$upa_id==k,,drop=FALSE]
    n1 <- nrow(p); n0 <- nrow(b)
    ok <- n1>=10L && n0>=10L
    out[[j]] <- data.frame(id=z$id,especie=z$especie,
      cenario_id=z$cenario_id,escala=met_tipo,unidade=k,
      propriedade=as.character(p$propriedade[1]),
      n_presencas=n1,n_bg=n0,n_pares=n1*n0,
      auc_local=if(ok) auc(p$score_cloglog,b$score_cloglog) else NA_real_,
      omissao_p10=mean(p$score_cloglog<lim),
      status_auc=if(ok) 'OK' else 'AMOSTRA_LOCAL_PEQUENA',
      stringsAsFactors=FALSE)
  }
  if(length(out)) do.call(rbind,out) else data.frame()
}

metricas_todas <- vector('list',6L)
por_prop <- vector('list',6L)
por_upa <- vector('list',6L)
for(i in seq_len(nrow(plano))) {
  z <- plano[i,,drop=FALSE]
  id <- z$id
  cp <- file.path(cpdir,paste0(id,'.rds'))
  rv <- papeis$upa_id[papeis$especie==z$especie &
       papeis$cenario_id==z$cenario_id & papeis$papel=='VALIDACAO']
  ps <- pres[pres$especie==z$especie,,drop=FALSE]
  tp <- ps[!ps$upa_id %in% rv,,drop=FALSE]
  vp <- ps[ps$upa_id %in% rv,,drop=FALSE]
  tb <- bg[!bg$upa_id %in% rv,,drop=FALSE]
  vb <- bg[bg$upa_id %in% rv,,drop=FALSE]
  if(file.exists(cp)) {
    ck <- tryCatch(readRDS(cp),error=function(e)NULL)
    exigir(is.list(ck) && identical(ck$versao,versao) &&
           identical(as.character(ck$id),as.character(id)) &&
           identical(ck$md5_entradas,manifesto$md5) &&
           inherits(ck$modelo,'maxnet') &&
           is.data.frame(ck$previsoes) &&
           nrow(ck$previsoes)==(nrow(tp)+nrow(tb)+nrow(vp)+nrow(vb)),
           paste('Checkpoint desatualizado/corrompido:',id))
    pp <- ck$previsoes
    p <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
    b <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
    exigir(length(p)==nrow(vp) && length(b)==nrow(vb) &&
           all(is.finite(c(p,b))) &&
           abs(auc(p,b)-ck$metricas$auc_validacao_b2)<1e-8 &&
           abs(mean(p<ck$metricas$limiar_p10_treino)-
               ck$metricas$omissao_p10_validacao)<1e-8,
           paste('Checkpoint nao reproduz metricas:',id))
    cat(sprintf('[%d/6] %s: checkpoint confirmado, sem reajuste.\n',i,id))
  } else {
    y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
    # Presencas e background tem colunas de identificacao DIFERENTES.
    # Empilhar somente os seis preditores padronizados, mantendo os fatores.
    x <- rbind(montar_x(tp),montar_x(tb))
    exigir(nrow(x)==length(y) && identical(names(x),seis),
           paste('Matriz de treino invalida:',id))
    cat(sprintf('[%d/6] Ajustando %s: %d presencas + %d BG treino...\n',
                i,id,nrow(tp),nrow(tb)))
    tempo <- Sys.time()
    modelo <- tryCatch({
      formula_m <- maxnet::maxnet.formula(y,x,classes='lqh')
      maxnet::maxnet(y,x,f=formula_m,regmult=4,
                     addsamplestobackground=TRUE)
    },error=function(e) stop('Erro de maxnet para ',id,': ',
                              conditionMessage(e),call.=FALSE))
    segundos <- as.numeric(difftime(Sys.time(),tempo,units='secs'))
    exigir(inherits(modelo,'maxnet'),paste('Objeto maxnet invalido:',id))
    stp <- prever(modelo,tp,paste(id,'presencas treino'))
    stb <- prever(modelo,tb,paste(id,'BG treino'))
    svp <- prever(modelo,vp,paste(id,'presencas validacao'))
    svb <- prever(modelo,vb,paste(id,'BG validacao'))
    lim <- as.numeric(stats::quantile(stp,probs=0.10,type=7,names=FALSE))
    bo <- boyce(svp,svb)
    pp <- rbind(
      fazer_previsoes(tp,z$especie,id,z$cenario_id,'PRESENCA_TREINO',stp),
      fazer_previsoes(tb,z$especie,id,z$cenario_id,'BACKGROUND_TREINO',stb),
      fazer_previsoes(vp,z$especie,id,z$cenario_id,'PRESENCA_VALIDACAO',svp),
      fazer_previsoes(vb,z$especie,id,z$cenario_id,'BACKGROUND_VALIDACAO',svb))
    valp <- pp[pp$tipo=='PRESENCA_VALIDACAO',,drop=FALSE]
    valb <- pp[pp$tipo=='BACKGROUND_VALIDACAO',,drop=FALSE]
    tabprop <- resultado_local(valp,valb,lim,'propriedade',z)
    tabupa <- resultado_local(valp,valb,lim,'upa',z)
    aval <- tabprop[is.finite(tabprop$auc_local),,drop=FALSE]
    intra <- if(nrow(aval)) sum(aval$auc_local*aval$n_pares)/sum(aval$n_pares)
             else NA_real_
    met <- data.frame(id=id,especie=z$especie,cenario_id=z$cenario_id,
      tipo_validacao='LOCAL_UPA_NAO_INDEPENDENTE_REGIONAL',
      features='lqh',RM=4L,n_preditores=6L,n_UPAs_validacao=length(rv),
      n_presencas_treino=nrow(tp),n_background_treino=nrow(tb),
      n_presencas_validacao=nrow(vp),n_background_validacao=nrow(vb),
      auc_treino=auc(stp,stb),auc_validacao_b2=auc(svp,svb),
      auc_intra_propriedade_ponderada=intra,
      n_propriedades_auc_local=nrow(aval),
      boyce_validacao=bo$valor,status_boyce=bo$status,
      limiar_p10_treino=lim,
      omissao_p10_treino=mean(stp<lim),
      omissao_p10_validacao=mean(svp<lim),
      mediana_score_presencas_validacao=stats::median(svp),
      mediana_score_background_validacao=stats::median(svb),
      max_score_presencas_validacao=max(svp),
      numero_coeficientes=length(modelo$betas),
      tempo_ajuste_segundos=segundos,
      status='EXPLORATORIO_LOCAL',stringsAsFactors=FALSE)
    ck <- list(versao=versao,id=id,md5_entradas=manifesto$md5,
               modelo=modelo,metricas=met,previsoes=pp,
               por_propriedade=tabprop,por_upa=tabupa)
    salvar_rds(ck,cp)
    cat(sprintf('  AUC=%.3f; Boyce=%s; omissao P10=%.1f%%; AUC intra-prop=%s\n',
      met$auc_validacao_b2,
      if(is.finite(met$boyce_validacao)) sprintf('%.3f',met$boyce_validacao)
        else 'indefinido',100*met$omissao_p10_validacao,
      if(is.finite(met$auc_intra_propriedade_ponderada))
        sprintf('%.3f',met$auc_intra_propriedade_ponderada) else 'NA'))
  }
  metricas_todas[[i]] <- ck$metricas
  por_prop[[i]] <- ck$por_propriedade
  por_upa[[i]] <- ck$por_upa
  # RDS oficial salvo em pasta propria (diferente de checkpoints).
  caminho_modelo <- file.path(moddir,paste0(id,'.rds'))
  if(file.exists(caminho_modelo)) {
    mod_ant <- tryCatch(readRDS(caminho_modelo),error=function(e)NULL)
    exigir(inherits(mod_ant,'maxnet') &&
           isTRUE(all.equal(mod_ant$betas,ck$modelo$betas)),
           paste('Modelo salvo diverge do checkpoint:',id))
  } else salvar_rds(ck$modelo,caminho_modelo)
  caminho_prev <- file.path(prevdir,paste0(id,'.csv'))
  escrever_csv(ck$previsoes,caminho_prev)
  parcial <- do.call(rbind,metricas_todas[!vapply(metricas_todas,is.null,logical(1))])
  escrever_csv(parcial,file.path(saida,'28_METRICAS_PARCIAIS.csv'))
}

# -----------------------------------------------------------------------------
# 3 - Produtos finais, interpretacao local e auditoria
# -----------------------------------------------------------------------------
met <- do.call(rbind,metricas_todas)
locprop <- do.call(rbind,por_prop)
locupa <- do.call(rbind,por_upa)
exigir(nrow(met)==6L && !anyDuplicated(met$id),
       'A grade final nao possui seis avaliacoes unicas.')
exigir(all(is.finite(met$auc_validacao_b2)) &&
       all(is.finite(met$omissao_p10_validacao)) &&
       all(met$auc_validacao_b2>=0 & met$auc_validacao_b2<=1) &&
       all(met$omissao_p10_validacao>=0 & met$omissao_p10_validacao<=1),
       'Metricas finais fora dos limites esperados.')
escrever_csv(met,file.path(saida,'28_METRICAS_6_MODELOS.csv'))
escrever_csv(locprop,file.path(saida,'28_AUC_OMISSAO_POR_PROPRIEDADE.csv'))
escrever_csv(locupa,file.path(saida,'28_AUC_OMISSAO_POR_UPA.csv'))
res <- data.frame(especie=especies,
  n_modelos=rep(3L,2),auc_media=NA_real_,
  auc_minima=NA_real_,auc_maxima=NA_real_,
  auc_intra_prop_media=NA_real_,omissao_p10_media=NA_real_,
  pior_omissao_p10=NA_real_,boyce_medio=NA_real_)
for(j in seq_along(especies)) {
  s <- met[met$especie==especies[j],,drop=FALSE]
  res$auc_media[j] <- mean(s$auc_validacao_b2)
  res$auc_minima[j] <- min(s$auc_validacao_b2)
  res$auc_maxima[j] <- max(s$auc_validacao_b2)
  res$auc_intra_prop_media[j] <- if(all(is.na(s$auc_intra_propriedade_ponderada)))
    NA_real_ else mean(s$auc_intra_propriedade_ponderada,na.rm=TRUE)
  res$omissao_p10_media[j] <- mean(s$omissao_p10_validacao)
  res$pior_omissao_p10[j] <- max(s$omissao_p10_validacao)
  res$boyce_medio[j] <- if(all(is.na(s$boyce_validacao))) NA_real_
                        else mean(s$boyce_validacao,na.rm=TRUE)
}
escrever_csv(res,file.path(saida,'28_RESUMO_POR_ESPECIE.csv'))

graficar <- function(col,nome,titulo,ylab,ylim) {
  ord <- order(match(met$especie,especies),met$cenario_id)
  z <- met[ord,,drop=FALSE]
  v <- z[[col]]
  nom <- paste(ifelse(z$especie=='Ipe-roxo','Roxo','Amarelo'),
               sub('LOCAL_UPAS_0','',z$cenario_id))
  png(file.path(grafdir,nome),width=1250,height=790,res=145)
  op <- par(mar=c(6.5,5,4,2)+0.1)
  barras <- barplot(replace(v,is.na(v),0),names.arg=nom,ylim=ylim,
     col=c(rep('#426C81',3),rep('#BC874E',3)),border=NA,
     main=titulo,ylab=ylab,las=2,cex.names=.95)
  if(col!='omissao_p10_validacao') abline(h=0.5,lty=2,col='gray65')
  labels <- ifelse(is.na(v),'NA',sprintf('%.3f',v))
  text(barras,replace(v,is.na(v),0),labels,pos=3,cex=.8,xpd=NA)
  par(op);dev.off()
}
graficar('auc_validacao_b2','28_AUC_GLOBAL.png',
         'R28: AUC de validacao (presenca versus background)',
         'AUC',c(0,1.06))
graficar('auc_intra_propriedade_ponderada','28_AUC_LOCAL.png',
         'R28: AUC dentro das propriedades (ponderada)',
         'AUC',c(0,1.06))
graficar('omissao_p10_validacao','28_OMISSAO_P10.png',
         'R28: omissao do limiar P10 do treinamento',
         'Proporcao de omissao',c(0,1.06))

rel <- c('TCC IPES | R28 - SEIS MODELOS LOCAIS POR UPA',
  paste('Protocolo:',versao),paste('Executado:',as.character(Sys.time())),
  '6 ajustes NOVOS: 2 especies x 3 paineis locais do R27.',
  'LQH, RM4, maxnet addsamplestobackground=TRUE, seis preditores.',
  'Textura subgrupo: fator 2,3,4,6,7. Previsao cloglog/clamping TRUE.',
  'Limiar P10: percentil 10 dos scores de presencas de TREINO.',
  'AUC e Boyce: presencas versus background B2 de VALIDACAO.',
  'AUC intra-propriedade ponderada por pares presenca-background.',
  'UPAs reservadas integralmente; UPAs contiguas -> validacao LOCAL,',
  'NAO validacao regional independente. Nenhum modelo final escolhido.',
  'Os seis modelos antigos R19 NAO foram reutilizados nesta particao.',
  'Os folds antigos, as 7 propriedades de teste e os dados originais',
  'continuam INALTERADOS e FORA deste protocolo.',
  'Nao comparar AUC dos novos paineis e antigos folds como se testassem',
  'a mesma populacao ambiental/amostragem.',
  'Resultados exploratorios: analisar cada UPA/propriedade e pior painel.',
  '', 'RESUMO POR MODELO:')
for(i in seq_len(nrow(met))) {
  r <- met[i,,drop=FALSE]
  rel <- c(rel,sprintf('%s | AUC %.3f | intra-prop %s | omissao %.1f%% | Boyce %s',
    r$id,r$auc_validacao_b2,
    if(is.finite(r$auc_intra_propriedade_ponderada))
      sprintf('%.3f',r$auc_intra_propriedade_ponderada) else 'NA',
    100*r$omissao_p10_validacao,
    if(is.finite(r$boyce_validacao)) sprintf('%.3f',r$boyce_validacao)
    else 'NA'))
}
writeLines(rel,file.path(saida,'28_RELATORIO_EXECUCAO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'28_SESSION_INFO.txt'))
cat('\nR28 CONCLUIDO. 6 de 6 modelos locais conferidos.\n',
    'Resultados:',saida,'\n',
    'Envie a pasta 03_RESULTADOS_R28_V1_1 compactada para auditoria.\n',sep='')
