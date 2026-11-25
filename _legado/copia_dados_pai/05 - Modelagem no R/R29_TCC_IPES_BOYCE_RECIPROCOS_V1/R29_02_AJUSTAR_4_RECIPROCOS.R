# =============================================================================
# TCC IPES | R29 ETAPA 2/2 - QUATRO TESTES RECIPROCOS (2 UPAs POR AJUSTE)
# Inclui novel class de solo como ALERTA, SEM recodificacao, exclusao ou imputacao.
# Modelos exploratorios; NAO sao validacao regional nem modelos finais.
# Depende da execucao anterior de R29_01_AUDITAR_BOYCE_R28.R.
# =============================================================================
for(pacote in c('maxnet','ecospat')) if(!requireNamespace(pacote,quietly=TRUE))
  stop('Pacote ausente: ',pacote,'. Rode install.packages("',pacote,'")',call.=FALSE)
fonte_r29 <- unlist(lapply(sys.frames(),function(f) if(is.null(f$ofile)) character(0) else as.character(f$ofile)),use.names=FALSE)
if (length(fonte_r29)) {
  pasta <- dirname(normalizePath(
    tail(fonte_r29, 1),
    winslash = "/",
    mustWork = TRUE
  ))
} else {
  pasta <- getwd()
}
source(file.path(pasta,'R29_FUNCOES.R'),local=TRUE)
pasta <- locate_r29()
manifesto <- preflight_r29(pasta)
audit_path <- file.path(pasta,'03_RESULTADOS_R29_V1','01_AUDITORIA_BOYCE','29_CONFERENCIA_BOYCE_R28.csv')
assert_r29(file.exists(audit_path),paste('Execute PRIMEIRO R29_01_AUDITAR_BOYCE_R28.R. Falta:',audit_path))
audit <- read_r29(audit_path)
need_r29(audit,c('id','status','auc_validacao','limiar_p10'),'Auditoria R28')
assert_r29(nrow(audit)==6L && all(is.finite(audit$auc_validacao)) &&
            all(is.finite(audit$limiar_p10)),'Auditoria R28 incompleta.')
if(any(audit$status!='BOYCE_REPRODUZIDO'))
  warning('Ha divergencias Boyce no R28; confira 29_CONFERENCIA_BOYCE_R28.csv. ',
          'Reciprocos podem ser executados, mas NAO interprete Boyce sem revisar.',call.=FALSE)
orig <- file.path(pasta,'02_DADOS_RECIPROCOS')
pres <- read_r29(file.path(orig,'05_PRESENCAS_UM_POR_PIXEL_30M.csv'))
bg <- read_r29(file.path(orig,'18_BACKGROUND_B2_10000_COM_FOLDS.csv'))
rec <- read_r29(file.path(orig,'27_RECIPROCOS_DIAGNOSTICOS.csv'))
sp_lista <- c('Ipe-roxo','Ipe-amarelo')
seis <- c('altitude_m','declividade_graus','dist_rio_raster_m',
          'bio12_mm_ano','bio17_mm_mes','textura_subgrupo')
continuas <- seis[1:5]
need_r29(pres,c('propriedade','upa_id','especie','celula_raster','linha_csv',seis),'Presencas')
need_r29(bg,c('propriedade','upa_id','id_background',seis),'Background B2')
need_r29(rec,c('especie','cenario_id','propriedade','upa_treino','upa_validacao',
 'n_presencas_treino','n_presencas_validacao','n_background_treino',
 'n_background_validacao','distancia_limites_km'),'Reciprocos R27')
assert_r29(nrow(pres)==8680L && nrow(bg)==10000L && nrow(rec)==4L,
           'Tamanhos nao conferem com bases R27/R28.')
assert_r29(!anyDuplicated(rec$cenario_id) &&
           setequal(rec$cenario_id,c('RECIP_ROXO_1','RECIP_ROXO_2','RECIP_AMARELO_1','RECIP_AMARELO_2')),
           'Quatro testes reciprocos faltantes ou duplicados.')
externas <- c('BARRO BRANCO','CURUÇA','GUARIÚBA','JATOBÁ','LOTE 01','MARILIA','PALMEIRA')
assert_r29(!any(c(pres$propriedade,bg$propriedade) %in% externas),
           'Teste externo aparece nas entradas: ABORTADO.')
assert_r29(as.character(utils::packageVersion('maxnet'))=='0.1.4' &&
           as.character(utils::packageVersion('ecospat'))=='4.1.4',
           'Versoes diferentes do R28 (maxnet 0.1.4, ecospat 4.1.4). Revisar reprodutibilidade.')
for(v in continuas) assert_r29(is.numeric(pres[[v]]) && is.numeric(bg[[v]]) &&
  all(is.finite(pres[[v]])) && all(is.finite(bg[[v]])),paste('Preditor invalido:',v))
assert_r29(!anyNA(pres[,seis,drop=FALSE]) && !anyNA(bg[,seis,drop=FALSE]),
           'Valores ambientais ausentes.')
niveis <- as.character(sort(unique(as.integer(c(pres$textura_subgrupo,bg$textura_subgrupo)))))
assert_r29(identical(as.integer(niveis),c(2L,3L,4L,6L,7L)),
           'Niveis de textura nao correspondem ao R28.')
montar_x <- function(d) {
  x <- d[,seis,drop=FALSE]
  for(v in continuas) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),levels=niveis)
  assert_r29(!anyNA(x),'Categoria de solo invalida em montar_x().')
  x
}
prever <- function(m,d,id,rotulo) {
  z <- tryCatch(as.numeric(stats::predict(m,montar_x(d),type='cloglog',clamp=TRUE)),
                error=function(e) stop('Falha na previsao ',id,' ',rotulo,': ',conditionMessage(e),call.=FALSE))
  assert_r29(length(z)==nrow(d) && all(is.finite(z)) && all(z>=0 & z<=1),
             paste('Score invalido:',id,rotulo))
  z
}
# PRE-FLIGHT COMPLETO, ANTES de qualquer ajuste.
conferidos <- vector('list',nrow(rec))
for(i in seq_len(nrow(rec))) {
  z <- rec[i,,drop=FALSE]
  assert_r29(z$especie %in% sp_lista && z$upa_treino!=z$upa_validacao &&
             identical(as.character(z$propriedade),strsplit(as.character(z$upa_treino),'\\|')[[1]][1]) &&
             identical(as.character(z$propriedade),strsplit(as.character(z$upa_validacao),'\\|')[[1]][1]),
             paste('UPA ou propriedade inconsistente:',z$cenario_id))
  tp <- pres[pres$especie==z$especie & pres$upa_id==z$upa_treino,,drop=FALSE]
  tb <- bg[bg$upa_id==z$upa_treino,,drop=FALSE]
  vp <- pres[pres$especie==z$especie & pres$upa_id==z$upa_validacao,,drop=FALSE]
  vb <- bg[bg$upa_id==z$upa_validacao,,drop=FALSE]
  assert_r29(nrow(tp)==z$n_presencas_treino && nrow(tb)==z$n_background_treino &&
             nrow(vp)==z$n_presencas_validacao && nrow(vb)==z$n_background_validacao,
             paste('Contagens de UPAs divergem do R27:',z$cenario_id))
  assert_r29(nrow(tp)>=100L && nrow(tb)>=100L && nrow(vp)>=100L && nrow(vb)>=100L,
             paste('Amostras insuficientes:',z$cenario_id))
  assert_r29(all(tp$propriedade==z$propriedade) && all(tb$propriedade==z$propriedade) &&
             all(vp$propriedade==z$propriedade) && all(vb$propriedade==z$propriedade),
             paste('Outra propriedade misturada no reciprocal:',z$cenario_id))
  treino_cat <- unique(as.character(c(tp$textura_subgrupo,tb$textura_subgrupo)))
  novo_p <- !(as.character(vp$textura_subgrupo) %in% treino_cat)
  novo_b <- !(as.character(vb$textura_subgrupo) %in% treino_cat)
  cats_novas <- setdiff(unique(as.character(c(vp$textura_subgrupo,vb$textura_subgrupo))),treino_cat)
  conferidos[[i]] <- data.frame(cenario_id=z$cenario_id,especie=z$especie,
    propriedade=z$propriedade,upa_treino=z$upa_treino,upa_validacao=z$upa_validacao,
    n_treino=nrow(tp),n_bg_treino=nrow(tb),n_validacao=nrow(vp),n_bg_validacao=nrow(vb),
    solo_niveis_treino=paste(sort(treino_cat),collapse=';'),
    solo_niveis_novos=paste(sort(cats_novas),collapse=';'),
    n_presencas_solo_novo=sum(novo_p),n_bg_solo_novo=sum(novo_b),
    perc_presencas_solo_novo=100*mean(novo_p),
    status_solo=if(length(cats_novas)) 'ALERTA_EXTRAPOLACAO_CATEGORICA' else 'OK',
    distancia_limites_km=z$distancia_limites_km,stringsAsFactors=FALSE)
}
conferidos <- do.call(rbind,conferidos)
cat('R29 preflight: 4 reciprocos com contagens conferidas; alerta de solo em ',
    sum(conferidos$status_solo!='OK'),' direcao(oes).\n',sep='')
if(any(conferidos$status_solo!='OK')) {
  print(conferidos[conferidos$status_solo!='OK',
         c('cenario_id','solo_niveis_novos','n_presencas_solo_novo','n_bg_solo_novo')])
  cat('ATENCAO: predicao em classe de solo ausente do treino eh extrapolatoria. ',
      'Nenhum registro sera removido ou recodificado.\n',sep='')
}
saida <- file.path(pasta,'03_RESULTADOS_R29_V1','02_TESTES_RECIPROCOS')
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
cp_dir <- file.path(saida,'29_CHECKPOINTS');md_dir <- file.path(saida,'29_MODELOS_RDS')
pr_dir <- file.path(saida,'29_PREVISOES');gr_dir <- file.path(saida,'29_GRAFICOS')
for(d in c(cp_dir,md_dir,pr_dir,gr_dir)) dir.create(d,recursive=TRUE,showWarnings=FALSE)
write_r29(conferidos,file.path(saida,'29_QA_RECIPROCOS_SOLO.csv'))
write_r29(manifesto,file.path(saida,'29_MANIFESTO_CONFERIDO.csv'))
versao <- 'R29_RECIPROCOS_V1_20261118'
previsoes_df <- function(d,id,papel,tipo,score) data.frame(
  id=id,especie=rep(papel,nrow(d)),tipo=tipo,
  propriedade=d$propriedade,upa_id=d$upa_id,
  id_presenca=if('linha_csv' %in% names(d)) as.character(d$linha_csv) else NA_character_,
  id_background=if('id_background' %in% names(d)) as.character(d$id_background) else NA_character_,
  score_cloglog=as.numeric(score),stringsAsFactors=FALSE)
metricas <- vector('list',nrow(rec))
for(i in seq_len(nrow(rec))) {
  z <- rec[i,,drop=FALSE]; id <- paste0('R29_',z$cenario_id,'_LQH_RM4')
  tp <- pres[pres$especie==z$especie & pres$upa_id==z$upa_treino,,drop=FALSE]
  tb <- bg[bg$upa_id==z$upa_treino,,drop=FALSE]
  vp <- pres[pres$especie==z$especie & pres$upa_id==z$upa_validacao,,drop=FALSE]
  vb <- bg[bg$upa_id==z$upa_validacao,,drop=FALSE]
  cp <- file.path(cp_dir,paste0(id,'.rds'))
  if(file.exists(cp)) {
    ck <- tryCatch(readRDS(cp),error=function(e)NULL)
    assert_r29(is.list(ck) && identical(ck$versao,versao) &&
      identical(ck$id,as.character(id)) && identical(ck$md5,manifesto$md5) &&
      inherits(ck$modelo,'maxnet') && is.data.frame(ck$previsoes) &&
      nrow(ck$previsoes)==sum(nrow(tp),nrow(tb),nrow(vp),nrow(vb)),
      paste('Checkpoint divergente/corrompido. Nao sobrescreva:',cp))
    cat(sprintf('[%d/4] Checkpoint confirmado: %s\n',i,id))
  } else {
    y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
    x <- rbind(montar_x(tp),montar_x(tb))
    assert_r29(nrow(x)==length(y) && identical(names(x),seis),paste('Matriz invalida:',id))
    cat(sprintf('[%d/4] Ajustando %s: %d presencas + %d BG de treino...\n',i,id,nrow(tp),nrow(tb)))
    ini <- Sys.time()
    modelo <- tryCatch({
      formula_m <- maxnet::maxnet.formula(y,x,classes='lqh')
      maxnet::maxnet(y,x,f=formula_m,regmult=4,addsamplestobackground=TRUE)
    },error=function(e) stop('maxnet nao ajustou ',id,': ',conditionMessage(e),call.=FALSE))
    assert_r29(inherits(modelo,'maxnet'),paste('Objeto maxnet nao reconhecido:',id))
    dur <- as.numeric(difftime(Sys.time(),ini,units='secs'))
    stp <- prever(modelo,tp,id,'presenca treino');stb <- prever(modelo,tb,id,'BG treino')
    svp <- prever(modelo,vp,id,'presenca validacao');svb <- prever(modelo,vb,id,'BG validacao')
    lim <- as.numeric(stats::quantile(stp,probs=.10,type=7,names=FALSE))
    bo <- boyce_r29(svp,svb,nclass=0,rm_dup=TRUE)
    qua <- conferidos[conferidos$cenario_id==z$cenario_id,,drop=FALSE]
    prev <- rbind(previsoes_df(tp,id,z$especie,'PRESENCA_TREINO',stp),
                  previsoes_df(tb,id,z$especie,'BACKGROUND_TREINO',stb),
                  previsoes_df(vp,id,z$especie,'PRESENCA_VALIDACAO',svp),
                  previsoes_df(vb,id,z$especie,'BACKGROUND_VALIDACAO',svb))
    met <- data.frame(id=id,especie=z$especie,cenario_id=z$cenario_id,
      propriedade=z$propriedade,upa_treino=z$upa_treino,upa_validacao=z$upa_validacao,
      n_presencas_treino=nrow(tp),n_background_treino=nrow(tb),
      n_presencas_validacao=nrow(vp),n_background_validacao=nrow(vb),
      distancia_limites_km=z$distancia_limites_km,
      auc_treino=auc_r29(stp,stb),auc_validacao=auc_r29(svp,svb),
      boyce_validacao=bo$valor,status_boyce=bo$status,
      limiar_p10_treino=lim,omissao_p10_treino=mean(stp<lim),
      omissao_p10_validacao=mean(svp<lim),
      frac_bg_acima_limiar=mean(svb>=lim),
      mediana_presencas_validacao=stats::median(svp),
      mediana_background_validacao=stats::median(svb),
      n_presencas_classe_nova=qua$n_presencas_solo_novo,
      n_bg_classe_nova=qua$n_bg_solo_novo,
      status_solo=qua$status_solo,
      n_coeficientes_ativos=length(modelo$betas),
      tempo_ajuste_segundos=dur,
      tipo_validacao='RECIPROCO_LOCAL_DUAS_UPAS_NAO_INDEPENDENTE_REGIONAL',
      stringsAsFactors=FALSE)
    ck <- list(versao=versao,id=as.character(id),md5=manifesto$md5,
               modelo=modelo,metricas=met,previsoes=prev)
    save_r29(ck,cp)
  }
  # Recalcular metricas do checkpoint antes de publicar.
  prev <- ck$previsoes;met <- ck$metricas
  pv <- prev$score_cloglog[prev$tipo=='PRESENCA_VALIDACAO']
  bv <- prev$score_cloglog[prev$tipo=='BACKGROUND_VALIDACAO']
  pt <- prev$score_cloglog[prev$tipo=='PRESENCA_TREINO']
  assert_r29(length(pv)==nrow(vp) && length(bv)==nrow(vb) &&
             abs(auc_r29(pv,bv)-met$auc_validacao)<1e-9 &&
             abs(mean(pv<met$limiar_p10_treino)-met$omissao_p10_validacao)<1e-9 &&
             abs(as.numeric(stats::quantile(pt,.10,type=7,names=FALSE))-met$limiar_p10_treino)<1e-9,
             paste('Metricas nao conferem com checkpoint:',id))
  metricas[[i]] <- met
  mod_file <- file.path(md_dir,paste0(id,'.rds'))
  if(file.exists(mod_file)) {
    md <- tryCatch(readRDS(mod_file),error=function(e)NULL)
    assert_r29(inherits(md,'maxnet') && isTRUE(all.equal(md$betas,ck$modelo$betas)),
               paste('Modelo oficial nao confere com checkpoint:',id))
  } else save_r29(ck$modelo,mod_file)
  write_r29(prev,file.path(pr_dir,paste0(id,'.csv')))
  plot_scores_r29(pv,bv,met$limiar_p10_treino,
    file.path(gr_dir,paste0('29_SCORES_',id,'.png')),paste('Reciproco: ',id))
  plot_pe_r29(pv,bv,boyce_r29(pv,bv),
    file.path(gr_dir,paste0('29_PE_',id,'.png')),paste('P/E: ',id))
  write_r29(do.call(rbind,metricas[!vapply(metricas,is.null,logical(1))]),
            file.path(saida,'29_METRICAS_PARCIAIS.csv'))
  cat(sprintf('  AUC %.3f | Boyce %s | Omissao %.1f%% | BG acima P10 %.1f%%\n',
      met$auc_validacao,if(is.finite(met$boyce_validacao))
      sprintf('%.3f',met$boyce_validacao) else 'NA',
      100*met$omissao_p10_validacao,100*met$frac_bg_acima_limiar))
}
met <- do.call(rbind,metricas)
assert_r29(nrow(met)==4L && !anyDuplicated(met$id),'Esperadas quatro avaliacoes reciprocas.')
write_r29(met,file.path(saida,'29_METRICAS_4_RECIPROCOS.csv'))
writeLines(c('R29 - 4 TESTES RECIPROCOS LOCAL ENTRE UPAS',
  paste('Versao:',versao),paste('Executado:',Sys.time()),
  'Roxo: Hermes UPA 01 ↔ UPA 03; Amarelo: Limao UPA 02 ↔ UPA 03.',
  'Treino e validacao usam APENAS AS DUAS UPAS da propriedade indicada.',
  'Seis preditores; textura em fator; features LQH, RM 4; maxnet 0.1.4.',
  'As sete propriedades externas nao foram consultadas.',
  'AUC e Boyce usam BG B2 de VALIDACAO; P10 definido no TREINO.',
  'Os BG de treinamento tem apenas 131 a 273 pontos: limitacao de estabilidade.',
  'ALERTA: uma direcao do amarelo tem presencas com classe de textura ausente do treino.',
  'Esses scores sao extrapolatorios para essa classe, nao estimativa de preferencia.',
  'Nenhum registro foi excluido, imputado ou recodificado.',
  'Avaliacao por duas UPAs NAO equivale a transferencia entre regioes independentes.',
  'AUC e Boyce podem divergir; interpretar scores, omissao e curvas P/E conjuntamente.',
  'Nao escolher modelo definitivo com esses reciprocos; nao alterar folds originais.',
  'A comparacao de duas UPAs nao e diretamente equivalente aos paineis R28.'),
  file.path(saida,'29_RELATORIO_RECIPROCOS.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'29_SESSION_INFO.txt'))
cat('\nR29 ETAPA 2 CONCLUIDA. Quatro testes reciprocos.\nResultados:',saida,'\n')
