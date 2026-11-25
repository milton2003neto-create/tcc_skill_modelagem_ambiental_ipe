# =============================================================================
# TCC IPES | R30 V1 - GRADE DE SENSIBILIDADE LOCAL MAXENT ENTRE UPAS
# =============================================================================
# SOMENTE EXPLORATORIO: 2 especies x 3 paineis R27 x 3 features x 4 RM = 72.
# Reaproveita 6 modelos R28 LQH/RM4, apos conferir entradas/checkpoints.
# Ajusta APENAS 66 modelos novos. NAO muda presencas, UPA, B2 ou solo.
# NAO usa as 7 propriedades externas; nao realiza selecao definitiva.
# Execute SOMENTE este script, com 'Source', na pasta extraida do ZIP.
# Saidas: 03_RESULTADOS_R30_GRADE_72 (retomada por checkpoint).
# =============================================================================

versao <- 'R30_GRADE_72_UPAS_V1_20261118'
versao_r28 <- 'R28_UPAS_B2_LQH_RM4_V1_1_20261118'
for (pacote in c('maxnet','ecospat')) {
  if (!requireNamespace(pacote,quietly=TRUE))
    stop('Instale ',pacote,' com install.packages("',pacote,'")',call.=FALSE)
}

parar <- function(ok,mensagem) {
  if (!isTRUE(ok)) stop('R30: ',mensagem,call.=FALSE)
}
ler <- function(p) utils::read.csv(p,fileEncoding='UTF-8-BOM',
                                  check.names=FALSE,stringsAsFactors=FALSE)
checar_colunas <- function(d,campos,nome) {
  faltam <- setdiff(campos,names(d))
  parar(length(faltam)==0L,paste(nome,'sem:',paste(faltam,collapse=', ')))
}
localizar_pasta <- function() {
  fontes <- unlist(lapply(sys.frames(),function(f) {
    if(is.null(f$ofile)) character() else as.character(f$ofile)
  }),use.names=FALSE)
  if(length(fontes)) {
    p <- dirname(normalizePath(tail(fontes,1),winslash='/',mustWork=TRUE))
    if(file.exists(file.path(p,'30_MANIFESTO_CONGELADO.csv'))) return(p)
  }
  if(file.exists('30_MANIFESTO_CONGELADO.csv'))
    return(normalizePath('.',winslash='/',mustWork=TRUE))
  stop('R30: extraia o pacote COMPLETO e abra o script nele.',call.=FALSE)
}
pasta <- localizar_pasta()
entrada <- file.path(pasta,'01_ENTRADAS_CONGELADAS')
r28 <- file.path(pasta,'02_R28_CHECKPOINTS')
saida <- file.path(pasta,'03_RESULTADOS_R30_GRADE_72')
md5 <- function(f) unname(tools::md5sum(f))

salvar_csv <- function(x,p) {
  tmp <- paste0(p,'.tmp')
  utils::write.csv(x,tmp,fileEncoding='UTF-8',row.names=FALSE,na='')
  if(file.exists(p)) {
    parar(file.copy(tmp,p,overwrite=TRUE),paste('Falha ao atualizar',p))
    unlink(tmp)
  } else parar(file.rename(tmp,p),paste('Falha ao gravar',p))
}
salvar_rds <- function(x,p) {
  tmp <- paste0(p,'.tmp')
  saveRDS(x,tmp,compress=TRUE)
  parar(file.rename(tmp,p),paste('Falha ao gravar',p))
}
auc <- function(p,b) {
  p <- as.numeric(p); b <- as.numeric(b)
  if(!length(p) || !length(b) || any(!is.finite(c(p,b)))) return(NA_real_)
  n <- length(p)
  (sum(rank(c(p,b),ties.method='average')[seq_len(n)]) - n*(n+1)/2) /
    (n*length(b))
}
calcular_boyce <- function(p,b,nclasses=0L) {
  avisos <- character()
  if(length(p)<2L || length(b)<2L || any(!is.finite(c(p,b))))
    return(list(valor=NA_real_,status='AMOSTRA_INVALIDA'))
  z <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(p),
       nclass=nclasses,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
    warning=function(w) {
      avisos <<- c(avisos,conditionMessage(w))
      invokeRestart('muffleWarning')
    }),error=function(e) {avisos <<- c(avisos,conditionMessage(e)); NULL})
  v <- NA_real_
  if(is.list(z) && !is.null(z$cor)) v <- as.numeric(z$cor)
  else if(is.list(z) && !is.null(z$Spearman.cor))
    v <- as.numeric(z$Spearman.cor)
  if(length(v)!=1L || !is.finite(v) || abs(v)>1.000001)
    return(list(valor=NA_real_,status=paste('INDEFINIDO',
      paste(unique(avisos),collapse=' | '))))
  list(valor=v,status=if(length(avisos)) paste('AVISO',
       paste(unique(avisos),collapse=' | ')) else 'OK')
}

# -------- PRE-FLIGHT: nenhuma modelagem antes de validar todos os arquivos -----
man <- ler(file.path(pasta,'30_MANIFESTO_CONGELADO.csv'))
checar_colunas(man,c('caminho_relativo','md5','bytes'),'Manifesto')
parar(nrow(man)==11L && !anyDuplicated(man$caminho_relativo),
      'Manifesto deveria conter cinco entradas e seis checkpoints R28.')
for(i in seq_len(nrow(man))) {
  f <- file.path(pasta,man$caminho_relativo[i])
  parar(file.exists(f),paste('Arquivo ausente:',f))
  parar(identical(tolower(as.character(md5(f))),
                  tolower(as.character(man$md5[i]))),
        paste('MD5 diferente:',basename(f)))
  parar(isTRUE(all.equal(as.numeric(file.info(f)$size),
                         as.numeric(man$bytes[i]))),
        paste('Tamanho diferente:',basename(f)))
}
parar(identical(as.character(utils::packageVersion('maxnet')),'0.1.4') &&
      identical(as.character(utils::packageVersion('ecospat')),'4.1.4'),
      'Versoes requeridas para comparacao: maxnet 0.1.4 e ecospat 4.1.4.')

pres <- ler(file.path(entrada,'05_PRESENCAS_UM_POR_PIXEL_30M.csv'))
bg <- ler(file.path(entrada,'18_BACKGROUND_B2_10000_COM_FOLDS.csv'))
papeis <- ler(file.path(entrada,'27_PAPEIS_64_UPAS_POR_CENARIO.csv'))
resumo <- ler(file.path(entrada,'27_RESUMO_6_PAINEIS.csv'))
reservas <- ler(file.path(entrada,'27_UPAS_RESERVADAS_PAINEIS.csv'))
cont <- c('altitude_m','declividade_graus','dist_rio_raster_m',
          'bio12_mm_ano','bio17_mm_mes')
seis <- c(cont,'textura_subgrupo')
especies <- c('Ipe-roxo','Ipe-amarelo')
cenarios <- sprintf('LOCAL_UPAS_%02d',1:3)
checar_colunas(pres,c('especie','propriedade','upa_id','fold_cv',
                     'linha_csv','celula_raster',seis),'Presencas')
checar_colunas(bg,c('propriedade','upa_id','fold_cv','id_background',
                   'celula_raster',seis),'B2')
checar_colunas(papeis,c('especie','cenario_id','upa_id','papel',
                       'n_presencas_especie','n_bg_b2'),'Papeis')
checar_colunas(resumo,c('especie','cenario_id','n_upas_validacao',
          'n_presencas_validacao','n_background_validacao',
          'n_presencas_treino','n_background_treino'),'Resumo')
checar_colunas(reservas,c('especie','cenario_id','upa_id'),'Reservas')
parar(nrow(pres)==8680L && nrow(bg)==10000L && nrow(papeis)==384L &&
      nrow(resumo)==6L && nrow(reservas)==19L,
      'Tamanho das entradas diferente do R27 congelado.')
parar(sum(pres$especie=='Ipe-roxo')==3248L &&
      sum(pres$especie=='Ipe-amarelo')==5432L,
      'Contagens das especies diferentes do R27.')
parar(length(unique(bg$upa_id))==64L &&
      length(unique(bg$propriedade))==27L,
      'Dominio B2/UPAs diferente do R27.')
parar(!anyDuplicated(bg$id_background) &&
      !anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster)),
      'Duplicacoes de registros no desenvolvimento.')
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ',
              'LOTE 01','MARILIA','PALMEIRA')
parar(!any(c(pres$propriedade,bg$propriedade) %in% externas),
      'Uma propriedade EXTERNA entrou no pacote. Processo bloqueado.')
parar(!anyNA(pres[,c('especie','propriedade','upa_id',seis)]) &&
      !anyNA(bg[,c('propriedade','upa_id',seis)]),
      'Entradas possuem valores ausentes.')
for(v in cont) parar(is.numeric(pres[[v]]) && is.numeric(bg[[v]]) &&
                    all(is.finite(pres[[v]])) && all(is.finite(bg[[v]])),
                    paste('Preditor continuo invalido:',v))
niveis <- as.character(sort(unique(as.integer(c(pres$textura_subgrupo,
                                               bg$textura_subgrupo)))))
parar(identical(as.integer(niveis),c(2L,3L,4L,6L,7L)),
      'Classes texturais diferentes de 2,3,4,6,7.')

x_pred <- function(d) {
  x <- d[,seis,drop=FALSE]
  for(v in cont) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),levels=niveis)
  parar(!anyNA(x),'Valores NA apos fatorizar textura.')
  x
}
prever <- function(mod,d,titulo) {
  sc <- tryCatch(as.numeric(stats::predict(mod,x_pred(d),
                           type='cloglog',clamp=TRUE)),
                 error=function(e) stop('R30 ',titulo,': ',
                    conditionMessage(e),call.=FALSE))
  parar(length(sc)==nrow(d) && all(is.finite(sc)) &&
        all(sc>=0 & sc<=1),paste('Scores invalidos:',titulo))
  sc
}

# Contratos R27: 6 paineis independentes entre si, nao 6 folds regionais.
parar(!anyDuplicated(paste(papeis$especie,papeis$cenario_id,papeis$upa_id)) &&
      !anyDuplicated(paste(resumo$especie,resumo$cenario_id)),
      'IDs repetidos no plano R27.')
parar(setequal(unique(pres$especie),especies) &&
      setequal(unique(resumo$cenario_id),cenarios),
      'Especies ou paineis inesperados.')

base <- expand.grid(especie=especies,cenario_id=cenarios,
                    KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
comb <- expand.grid(features=c('l','lq','lqh'),RM=1:4,
                    KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
plano <- merge(base,comb,by=NULL,sort=FALSE)
plano <- plano[order(match(plano$especie,especies),plano$cenario_id,
                     match(plano$features,c('l','lq','lqh')),plano$RM),,
               drop=FALSE]
rownames(plano) <- NULL
plano$id <- paste0('R30_',ifelse(plano$especie=='Ipe-roxo','ROXO','AMARELO'),
                   '_',plano$cenario_id,'_',toupper(plano$features),
                   '_RM',plano$RM)
plano$origem <- ifelse(plano$features=='lqh' & plano$RM==4L,
                       'REAPROVEITAR_R28','AJUSTAR_R30')
parar(nrow(plano)==72L && sum(plano$origem=='REAPROVEITAR_R28')==6L &&
      !anyDuplicated(plano$id),'Grade de 72 configuracoes invalida.')

# Verificar AS SEIS combinacoes de dados antes de qualquer ajuste.
contagens <- list()
r28_cache <- list()
for(i in seq_len(nrow(base))) {
  sp <- base$especie[i]; cen <- base$cenario_id[i]
  chave <- paste(sp,cen,sep='|')
  rr <- papeis[papeis$especie==sp & papeis$cenario_id==cen,,drop=FALSE]
  rv <- rr$upa_id[rr$papel=='VALIDACAO']
  esperado <- resumo[resumo$especie==sp & resumo$cenario_id==cen,,drop=FALSE]
  parar(nrow(rr)==64L && nrow(esperado)==1L && length(rv)>=2L &&
        setequal(rr$upa_id,unique(bg$upa_id)) &&
        all(rr$papel %in% c('TREINO','VALIDACAO')),
        paste('Papeis de UPA inconsistentes:',chave))
  ps <- pres[pres$especie==sp,,drop=FALSE]
  tp <- ps[!ps$upa_id %in% rv,,drop=FALSE]
  vp <- ps[ps$upa_id %in% rv,,drop=FALSE]
  tb <- bg[!bg$upa_id %in% rv,,drop=FALSE]
  vb <- bg[bg$upa_id %in% rv,,drop=FALSE]
  parar(nrow(vp)==esperado$n_presencas_validacao &&
        nrow(tp)==esperado$n_presencas_treino &&
        nrow(vb)==esperado$n_background_validacao &&
        nrow(tb)==esperado$n_background_treino &&
        length(rv)==esperado$n_upas_validacao &&
        setequal(rv,reservas$upa_id[reservas$especie==sp &
                                  reservas$cenario_id==cen]),
        paste('Contagens/UPAs diferentes do R27:',chave))
  cats_train <- unique(c(as.character(tp$textura_subgrupo),
                         as.character(tb$textura_subgrupo)))
  cats_val <- unique(c(as.character(vp$textura_subgrupo),
                       as.character(vb$textura_subgrupo)))
  parar(length(setdiff(cats_val,cats_train))==0L,
        paste('Classe de solo desconhecida na validacao:',chave))
  contagens[[chave]] <- data.frame(especie=sp,cenario_id=cen,
    n_UPAs_val=length(rv),pres_treino=nrow(tp),bg_treino=nrow(tb),
    pres_val=nrow(vp),bg_val=nrow(vb),stringsAsFactors=FALSE)
  id28 <- paste0('R28_',ifelse(sp=='Ipe-roxo','ROXO','AMARELO'),
                  '_',cen,'_LQH_RM4')
  f28 <- file.path(r28,paste0(id28,'.rds'))
  ck28 <- tryCatch(readRDS(f28),error=function(e) NULL)
  parar(is.list(ck28) && identical(ck28$versao,versao_r28) &&
        identical(as.character(ck28$id),id28) &&
        inherits(ck28$modelo,'maxnet') &&
        is.data.frame(ck28$metricas) && nrow(ck28$metricas)==1L &&
        is.data.frame(ck28$previsoes) &&
        nrow(ck28$previsoes)==(nrow(tp)+nrow(tb)+nrow(vp)+nrow(vb)) &&
        identical(as.character(ck28$md5_entradas),as.character(man$md5[1:5])) &&
        identical(as.character(ck28$metricas$features),'lqh') &&
        identical(as.numeric(ck28$metricas$RM),4),
        paste('Checkpoint R28 incompativel:',id28))
  pp <- ck28$previsoes
  checar_colunas(pp,c('tipo','score_cloglog','upa_id','especie',
                     'id','cenario_id'),'Previsoes R28')
  parar(all(pp$especie==sp) && all(pp$cenario_id==cen) &&
        all(pp$id==id28),paste('Checkpoint R28 com IDs inconsistentes:',id28))
  contagens_tipos <- c(PRESENCA_TREINO=nrow(tp),BACKGROUND_TREINO=nrow(tb),
                      PRESENCA_VALIDACAO=nrow(vp),BACKGROUND_VALIDACAO=nrow(vb))
  parar(identical(as.integer(table(factor(pp$tipo,
                    levels=names(contagens_tipos)))),
                  as.integer(contagens_tipos)),
        paste('Checkpoint R28 com particoes divergentes:',id28))
  parar(setequal(unique(pp$upa_id[pp$tipo=='PRESENCA_VALIDACAO']),
                unique(vp$upa_id)) &&
        setequal(unique(pp$upa_id[pp$tipo=='BACKGROUND_VALIDACAO']),
                unique(vb$upa_id)) &&
        !any(pp$upa_id[pp$tipo %in% c('PRESENCA_TREINO',
                                      'BACKGROUND_TREINO')] %in% rv),
        paste('Checkpoint R28 vazou UPA ou divergiu do plano:',id28))
  p <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
  b <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
  parar(all(is.finite(pp$score_cloglog)) &&
        abs(auc(p,b)-ck28$metricas$auc_validacao_b2)<1e-8 &&
        abs(mean(p<ck28$metricas$limiar_p10_treino)-
            ck28$metricas$omissao_p10_validacao)<1e-8,
        paste('Metrias de R28 nao reproduzidas:',id28))
  r28_cache[[chave]] <- ck28
}
cat('R30 PREFLIGHT OK: 72 avaliacoes; 6 checkpoints R28 compativeis;',
    ' 66 novos ajustes. Nenhuma propriedade externa.\n')

# ----------------------- SAIDA E ANALISE DOS 72 ------------------------------
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
cpdir <- file.path(saida,'30_CHECKPOINTS_NOVOS')
prevdir <- file.path(saida,'30_PREVISOES_NOVAS')
for(d in c(cpdir,prevdir)) dir.create(d,recursive=TRUE,showWarnings=FALSE)
salvar_csv(plano,file.path(saida,'30_PLANO_72_MODELOS.csv'))
salvar_csv(man,file.path(saida,'30_MANIFESTO_CONGELADO.csv'))
salvar_csv(do.call(rbind,contagens),file.path(saida,'30_CONTAGENS_PAINEIS.csv'))

fazer_prev <- function(d,sp,cen,id,tipo,score) {
  data.frame(id=id,especie=sp,cenario_id=cen,tipo=tipo,
    propriedade=as.character(d$propriedade),upa_id=as.character(d$upa_id),
    celula_raster=as.character(d$celula_raster),
    linha_csv=if('linha_csv' %in% names(d)) as.character(d$linha_csv)
              else NA_character_,
    id_background=if('id_background' %in% names(d))
      as.character(d$id_background) else NA_character_,
    score_cloglog=score,stringsAsFactors=FALSE)
}
local <- function(pr,bg,lim,escala,id,sp,cen) {
  unidades <- unique(pr[[if(escala=='propriedade') 'propriedade' else 'upa_id']])
  out <- lapply(unidades,function(k) {
    p <- if(escala=='propriedade') pr[pr$propriedade==k,,drop=FALSE]
         else pr[pr$upa_id==k,,drop=FALSE]
    b <- if(escala=='propriedade') bg[bg$propriedade==k,,drop=FALSE]
         else bg[bg$upa_id==k,,drop=FALSE]
    ok <- nrow(p)>=10L && nrow(b)>=10L
    data.frame(id=id,especie=sp,cenario_id=cen,escala=escala,
      unidade=k,propriedade=as.character(p$propriedade[1]),
      n_presencas=nrow(p),n_background=nrow(b),n_pares=nrow(p)*nrow(b),
      auc_local=if(ok) auc(p$score_cloglog,b$score_cloglog) else NA_real_,
      omissao_p10=mean(p$score_cloglog<lim),
      status=if(ok) 'OK' else 'AMOSTRA_PEQUENA',stringsAsFactors=FALSE)
  })
  do.call(rbind,out)
}
pond <- function(d) {
  ok <- is.finite(d$auc_local) & d$n_pares>0L
  if(!any(ok)) NA_real_
  else stats::weighted.mean(d$auc_local[ok],w=d$n_pares[ok])
}

metricas <- vector('list',nrow(plano))
por_prop <- vector('list',nrow(plano))
por_upa <- vector('list',nrow(plano))
for(i in seq_len(nrow(plano))) {
  z <- plano[i,,drop=FALSE]
  sp <- z$especie; cen <- z$cenario_id; id <- z$id
  chave <- paste(sp,cen,sep='|')
  rr <- papeis[papeis$especie==sp & papeis$cenario_id==cen,,drop=FALSE]
  rv <- rr$upa_id[rr$papel=='VALIDACAO']
  ps <- pres[pres$especie==sp,,drop=FALSE]
  tp <- ps[!ps$upa_id %in% rv,,drop=FALSE]
  vp <- ps[ps$upa_id %in% rv,,drop=FALSE]
  tb <- bg[!bg$upa_id %in% rv,,drop=FALSE]
  vb <- bg[bg$upa_id %in% rv,,drop=FALSE]
  origem <- z$origem
  cp <- file.path(cpdir,paste0(id,'.rds'))

  if(origem=='REAPROVEITAR_R28') {
    ck28 <- r28_cache[[chave]]
    modelo <- ck28$modelo
    pp <- ck28$previsoes
    # Preservamos os scores e o ajuste R28; apenas harmonizamos IDs de saida.
    pp$id <- id
    t_ajuste <- ck28$metricas$tempo_ajuste_segundos
    boy0 <- list(valor=ck28$metricas$boyce_validacao,
                 status=as.character(ck28$metricas$status_boyce))
    cat(sprintf('[%d/72] %s: reutilizando modelo R28 verificado.\n',i,id))
  } else if(file.exists(cp)) {
    ck <- tryCatch(readRDS(cp),error=function(e) NULL)
    parar(is.list(ck) && identical(ck$versao,versao) &&
          identical(ck$id,id) && identical(ck$md5_entradas,man$md5) &&
          inherits(ck$modelo,'maxnet') &&
          is.data.frame(ck$previsoes) &&
          nrow(ck$previsoes)==nrow(tp)+nrow(vp)+nrow(tb)+nrow(vb) &&
          all(ck$previsoes$id==id) &&
          is.data.frame(ck$metricas) &&
          identical(as.character(ck$metricas$features),as.character(z$features)) &&
          isTRUE(all.equal(as.numeric(ck$metricas$RM),as.numeric(z$RM))),
          paste('Checkpoint R30 corrompido ou incompativel:',id))
    modelo <- ck$modelo; pp <- ck$previsoes
    t_ajuste <- ck$metricas$tempo_ajuste_segundos
    boy0 <- list(valor=ck$metricas$boyce_validacao,
                 status=as.character(ck$metricas$status_boyce))
    cat(sprintf('[%d/72] %s: checkpoint R30 reutilizado.\n',i,id))
  } else {
    y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
    x <- rbind(x_pred(tp),x_pred(tb))
    parar(nrow(x)==length(y) && identical(names(x),seis),
          paste('Matriz com seis preditores invalida:',id))
    cat(sprintf('[%d/72] AJUSTANDO %s (%d pres, %d BG treino).\n',
                i,id,nrow(tp),nrow(tb)))
    tempo0 <- Sys.time()
    modelo <- tryCatch({
      fm <- maxnet::maxnet.formula(y,x,classes=as.character(z$features))
      maxnet::maxnet(y,x,f=fm,regmult=as.numeric(z$RM),
                     addsamplestobackground=TRUE)
    },error=function(e) stop('R30 falhou no ajuste ',id,': ',
                             conditionMessage(e),call.=FALSE))
    t_ajuste <- as.numeric(difftime(Sys.time(),tempo0,units='secs'))
    parar(inherits(modelo,'maxnet'),paste('Modelo invalido:',id))
    stp <- prever(modelo,tp,paste(id,'presencas treino'))
    stb <- prever(modelo,tb,paste(id,'background treino'))
    svp <- prever(modelo,vp,paste(id,'presencas validacao'))
    svb <- prever(modelo,vb,paste(id,'background validacao'))
    pp <- rbind(
      fazer_prev(tp,sp,cen,id,'PRESENCA_TREINO',stp),
      fazer_prev(tb,sp,cen,id,'BACKGROUND_TREINO',stb),
      fazer_prev(vp,sp,cen,id,'PRESENCA_VALIDACAO',svp),
      fazer_prev(vb,sp,cen,id,'BACKGROUND_VALIDACAO',svb))
    boy0 <- calcular_boyce(svp,svb,0L)
  }

  parar(nrow(pp)==(nrow(tp)+nrow(tb)+nrow(vp)+nrow(vb)) &&
        all(is.finite(pp$score_cloglog)) &&
        all(pp$score_cloglog>=0 & pp$score_cloglog<=1),
        paste('Previsoes incompletas:',id))
  stp <- pp$score_cloglog[pp$tipo=='PRESENCA_TREINO']
  stb <- pp$score_cloglog[pp$tipo=='BACKGROUND_TREINO']
  svp <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
  svb <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
  parar(length(stp)==nrow(tp) && length(stb)==nrow(tb) &&
        length(svp)==nrow(vp) && length(svb)==nrow(vb),
        paste('Previsoes trocadas de treino/validacao:',id))
  lim <- as.numeric(stats::quantile(stp,probs=0.1,type=7,names=FALSE))
  if(origem=='REAPROVEITAR_R28')
    parar(abs(lim-ck28$metricas$limiar_p10_treino)<1e-8,
          paste('Limiar R28 alterado:',id))
  if(origem=='AJUSTAR_R30' && file.exists(cp)) {
    parar(abs(auc(svp,svb)-ck$metricas$auc_validacao_b2)<1e-8 &&
          abs(mean(svp<lim)-ck$metricas$omissao_p10_validacao)<1e-8,
          paste('Metrica de checkpoint divergente:',id))
  }
  valp <- pp[pp$tipo=='PRESENCA_VALIDACAO',,drop=FALSE]
  valb <- pp[pp$tipo=='BACKGROUND_VALIDACAO',,drop=FALSE]
  proptab <- local(valp,valb,lim,'propriedade',id,sp,cen)
  upatab <- local(valp,valb,lim,'upa',id,sp,cen)
  boy10 <- calcular_boyce(svp,svb,10L)
  met <- data.frame(id=id,especie=sp,cenario_id=cen,
    features=as.character(z$features),RM=as.integer(z$RM),origem=origem,
    validacao='UPAS_LOCAIS_CONTIGUAS_NAO_INDEPENDENTE_REGIONAL',
    presencas_treino=nrow(tp),background_treino=nrow(tb),
    presencas_validacao=nrow(vp),background_validacao=nrow(vb),
    n_upas_validacao=length(rv),
    auc_treino=auc(stp,stb),auc_validacao_b2=auc(svp,svb),
    auc_intra_propriedade=pond(proptab),auc_intra_upa=pond(upatab),
    n_propriedades_auc=sum(is.finite(proptab$auc_local)),
    n_upas_auc=sum(is.finite(upatab$auc_local)),
    boyce_validacao=boy0$valor,status_boyce=boy0$status,
    boyce_10classes=boy10$valor,status_boyce_10=boy10$status,
    limiar_p10_treino=lim,
    omissao_p10_treino=mean(stp<lim),
    omissao_p10_validacao=mean(svp<lim),
    proporcao_bg_acima_p10=mean(svb>=lim),
    n_coeficientes=length(modelo$betas),
    n_coeficientes_nao_zero=sum(abs(modelo$betas)>0),
    tempo_ajuste_segundos=t_ajuste,
    stringsAsFactors=FALSE)
  if(origem=='AJUSTAR_R30' && !file.exists(cp)) {
    # CHECKPOINT ATOMICO primeiro; se a sessao fechar, proximo Source retoma.
    novo <- list(versao=versao,id=id,md5_entradas=man$md5,
                 modelo=modelo,metricas=met,previsoes=pp,
                 por_propriedade=proptab,por_upa=upatab)
    salvar_rds(novo,cp)
  }
  metricas[[i]] <- met
  por_prop[[i]] <- proptab
  por_upa[[i]] <- upatab
  if(origem=='AJUSTAR_R30')
    salvar_csv(pp,file.path(prevdir,paste0(id,'.csv')))
  parcial <- do.call(rbind,metricas[!vapply(metricas,is.null,logical(1))])
  salvar_csv(parcial,file.path(saida,'30_METRICAS_PARCIAIS.csv'))
  cat(sprintf('  AUC=%.3f | intra-prop=%s | intra-UPA=%s | omissao=%.1f%% | Boyce=%.3f\n',
              met$auc_validacao_b2,
              if(is.finite(met$auc_intra_propriedade))
                sprintf('%.3f',met$auc_intra_propriedade) else 'NA',
              if(is.finite(met$auc_intra_upa))
                sprintf('%.3f',met$auc_intra_upa) else 'NA',
              100*met$omissao_p10_validacao,
              met$boyce_validacao))
}

# ----------------------- RESUMOS FINAIS -------------------------------------
met <- do.call(rbind,metricas)
parar(nrow(met)==72L && !anyDuplicated(met$id) &&
      sum(met$origem=='REAPROVEITAR_R28')==6L &&
      all(is.finite(met$auc_validacao_b2)) &&
      all(met$auc_validacao_b2>=0 & met$auc_validacao_b2<=1) &&
      all(met$omissao_p10_validacao>=0 & met$omissao_p10_validacao<=1),
      'Grade incompleta ou metricas fora dos limites.')
salvar_csv(met,file.path(saida,'30_METRICAS_72_AVALIACOES.csv'))
salvar_csv(do.call(rbind,por_prop),
           file.path(saida,'30_RESULTADOS_POR_PROPRIEDADE.csv'))
salvar_csv(do.call(rbind,por_upa),
           file.path(saida,'30_RESULTADOS_POR_UPA.csv'))

resumo24 <- list()
k <- 0L
for(sp in especies) for(fe in c('l','lq','lqh')) for(rm in 1:4) {
  k <- k+1L
  z <- met[met$especie==sp & met$features==fe & met$RM==rm,,drop=FALSE]
  parar(nrow(z)==3L,paste('Faltam paineis de',sp,fe,rm))
  media_segura <- function(x) if(all(!is.finite(x))) NA_real_
    else mean(x[is.finite(x)])
  resumo24[[k]] <- data.frame(especie=sp,features=fe,RM=rm,n_paineis=3L,
    auc_global_media=mean(z$auc_validacao_b2),
    auc_global_min=min(z$auc_validacao_b2),
    auc_intra_propriedade_media=media_segura(z$auc_intra_propriedade),
    auc_intra_upa_media=media_segura(z$auc_intra_upa),
    omissao_media=mean(z$omissao_p10_validacao),
    pior_omissao=max(z$omissao_p10_validacao),
    bg_acima_p10_medio=mean(z$proporcao_bg_acima_p10),
    boyce_medio=media_segura(z$boyce_validacao),
    boyce_10classes_medio=media_segura(z$boyce_10classes),
    coeficientes_ativos_medio=mean(z$n_coeficientes_nao_zero),
    stringsAsFactors=FALSE)
}
salvar_csv(do.call(rbind,resumo24),
           file.path(saida,'30_RESUMO_24_CONFIGURACOES.csv'))

# Imagens simples de conferencia. Nao escolher melhor modelo automaticamente.
grafico <- function(col,nome,titulo,ylab) {
  png(file.path(saida,nome),width=1500,height=850,res=135)
  op <- par(mar=c(7,5,4,2))
  sub <- do.call(rbind,resumo24)
  grupos <- c('Ipe-roxo','Ipe-amarelo')
  for(sp in grupos) {
    d <- sub[sub$especie==sp,,drop=FALSE]
    lab <- paste(toupper(d$features),paste0('RM',d$RM))
    # 12 configuracoes por especie; separacao por especies em um unico grafico.
    valores <- d[[col]]
    if(sp==grupos[1]) {
      par(mfrow=c(2,1),mar=c(5,5,3,1))
    }
    barplot(ifelse(is.finite(valores),valores,0),names.arg=lab,
            col=if(sp==grupos[1]) '#426C81' else '#BC874E',
            ylim=c(0,1.05),las=2,cex.names=0.8,
            main=paste(titulo,'-',sp),ylab=ylab)
    abline(h=0.5,col='gray60',lty=2)
  }
  par(op);dev.off()
}
grafico('auc_global_media','30_AUC_GLOBAL_MEDIA.png',
        'AUC de validacao global - media dos 3 paineis','AUC')
grafico('auc_intra_upa_media','30_AUC_INTRA_UPA_MEDIA.png',
        'AUC dentro das UPAs - media dos 3 paineis','AUC')
grafico('omissao_media','30_OMISSAO_P10_MEDIA.png',
        'Omissao P10 - media dos 3 paineis','Proporcao')

rel <- c('TCC IPES | R30 GRADE LOCAL - 72 AVALIACOES',
  paste('Versao:',versao),paste('Data:',as.character(Sys.time())),
  '2 especies x 3 paineis R27 x 3 features (L,LQ,LQH) x 4 RM (1,2,3,4).',
  '6 checkpoints LQH/RM4 do R28 conferidos e reaproveitados.',
  '66 ajustes R30 novos; NAO foram reamostrados registros.',
  'AUC/Boyce de validacao: presenca versus background B2 da validacao.',
  'Boyce principal: ecospat nclass=0; sensibilidade: nclass=10.',
  'P10 calculado SOMENTE nas presencas de treinamento.',
  'AUC intra-UPA e intra-propriedade ponderada por pares presenca-background.',
  'UPAs de validacao podem tocar outras UPAs de treino:',
  'VALIDACAO LOCAL; NAO prova transferencia regional independente.',
  'Comparacoes entre configuracoes sao EXPLORATORIAS.',
  'Nao selecionar automaticamente melhor ajuste por maior AUC.',
  'Sete propriedades externas nao foram acessadas, e devem permanecer intactas.',
  'R01-R29 permanecem inalterados.',
  '', 'PROXIMO: auditar 72 metricas, pior UPA/painel, Boyce e complexidade;',
  'definir estrategia de selecao sem usar teste externo.',
  '', 'RESUMO:',
  paste('Total:',nrow(met)),
  paste('Reaproveitados R28:',sum(met$origem=='REAPROVEITAR_R28')),
  paste('Novos R30:',sum(met$origem=='AJUSTAR_R30')))
writeLines(rel,file.path(saida,'30_RELATORIO_EXECUCAO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'30_SESSION_INFO.txt'))
cat('\nR30 CONCLUIDO: 72 avaliacoes, 6 R28 reaproveitadas, 66 novos ajustes.\n',
    'Envie compactada a pasta:',saida,'\n')
