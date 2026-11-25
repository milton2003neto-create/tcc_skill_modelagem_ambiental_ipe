# =============================================================================
# TCC IPES | R29 ETAPA 1/2 - AUDITORIA BOYCE E LIMIAR P10 DOS 6 MODELOS R28
# Nao treina modelos. Nao modifica R28. Reproduz o metodo ecospat do R28.
# O diagnostico de sensibilidade nclass=10 NAO substitui Boyce original.
# =============================================================================
if(!requireNamespace('ecospat',quietly=TRUE))
  stop('Instale ecospat: install.packages("ecospat")',call.=FALSE)
fonte_r29 <- unlist(lapply(sys.frames(),function(f) if(is.null(f$ofile)) character(0) else as.character(f$ofile)),use.names=FALSE)
if(length(fonte_r29)) {
  pasta <- dirname(normalizePath(tail(fonte_r29,1),winslash='/',mustWork=TRUE))
} else pasta <- getwd()
source(file.path(pasta,'R29_FUNCOES.R'),local=TRUE)
pasta <- locate_r29()
manifesto <- preflight_r29(pasta)
met <- read_r29(file.path(pasta,'01_R28_PREVISOES','28_METRICAS_6_MODELOS.csv'))
need_r29(met,c('id','especie','cenario_id','n_presencas_validacao',
 'n_background_validacao','auc_validacao_b2','boyce_validacao',
 'limiar_p10_treino','omissao_p10_validacao'),'Metricas R28')
assert_r29(nrow(met)==6L && !anyDuplicated(met$id),'Esperados seis modelos unicos do R28.')
saida <- file.path(pasta,'03_RESULTADOS_R29_V1','01_AUDITORIA_BOYCE')
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
graf <- file.path(saida,'29_GRAFICOS_BOYCE')
dir.create(graf,recursive=TRUE,showWarnings=FALSE)
res <- vector('list',nrow(met)); curvas <- vector('list',nrow(met))
for(i in seq_len(nrow(met))) {
  z <- met[i,,drop=FALSE]; id <- as.character(z$id)
  prev <- read_r29(file.path(pasta,'01_R28_PREVISOES',paste0(id,'.csv')))
  need_r29(prev,c('id','tipo','especie','cenario_id','propriedade','upa_id','score_cloglog'),paste('Previsoes',id))
  assert_r29(all(prev$id==id),paste('ID divergente:',id))
  assert_r29(all(is.finite(prev$score_cloglog)) && all(prev$score_cloglog>=0 & prev$score_cloglog<=1),
    paste('Scores nao-finitos/fora dos limites:',id))
  pv <- prev[prev$tipo=='PRESENCA_VALIDACAO',,drop=FALSE]
  bv <- prev[prev$tipo=='BACKGROUND_VALIDACAO',,drop=FALSE]
  pt <- prev[prev$tipo=='PRESENCA_TREINO',,drop=FALSE]
  assert_r29(nrow(pv)==z$n_presencas_validacao && nrow(bv)==z$n_background_validacao && nrow(pt)>100L,
             paste('Contagem divergente:',id))
  score_p <- pv$score_cloglog;score_b <- bv$score_cloglog
  auc <- auc_r29(score_p,score_b)
  p10 <- as.numeric(stats::quantile(pt$score_cloglog,probs=.10,type=7,names=FALSE))
  om <- mean(score_p < z$limiar_p10_treino)
  assert_r29(abs(auc-z$auc_validacao_b2)<1e-8 && abs(p10-z$limiar_p10_treino)<1e-8 &&
             abs(om-z$omissao_p10_validacao)<1e-8,
             paste('AUC/P10/omissao do R28 nao foram reproduzidos:',id))
  bo <- boyce_r29(score_p,score_b,nclass=0,rm_dup=TRUE)
  bo10 <- boyce_r29(score_p,score_b,nclass=10,rm_dup=TRUE)
  bo_full <- boyce_r29(score_p,score_b,nclass=0,rm_dup=FALSE)
  dif <- if(is.finite(bo$valor) && is.finite(z$boyce_validacao))
    bo$valor-z$boyce_validacao else NA_real_
  status <- if(is.finite(dif) && abs(dif)<=.002) 'BOYCE_REPRODUZIDO' else
    if(is.finite(dif)) 'REVER_BOYCE_DIVERGENTE' else 'REVER_BOYCE_INDEFINIDO'
  res[[i]] <- data.frame(id=id,especie=z$especie,cenario_id=z$cenario_id,
    n_presencas=nrow(pv),n_background=nrow(bv),auc_validacao=auc,
    boyce_r28=z$boyce_validacao,boyce_recalculado=bo$valor,
    delta_boyce=dif,boyce_10_classes=bo10$valor,
    boyce_sem_remover_duplicatas=bo_full$valor,
    n_intervalos_PE=length(bo$PE),n_intervalos_PE_finitos=sum(is.finite(bo$PE)),
    limiar_p10=p10,omissao_p10=om,fracao_BG_acima_p10=mean(score_b>=p10),
    mediana_presencas=stats::median(score_p),mediana_BG=stats::median(score_b),
    status=status,status_ecospat=bo$status,stringsAsFactors=FALSE)
  if(length(bo$HS)==length(bo$PE) && length(bo$HS))
    curvas[[i]] <- data.frame(id=id,intervalo=seq_along(bo$PE),
       adequabilidade=bo$HS,PE=bo$PE,stringsAsFactors=FALSE)
  plot_pe_r29(score_p,score_b,bo,file.path(graf,paste0('29_PE_',id,'.png')),
              paste('P/E e Boyce |',id))
  plot_scores_r29(score_p,score_b,p10,file.path(graf,paste0('29_SCORES_',id,'.png')),
                  paste('Presencas vs BG |',id))
  cat(sprintf('[%d/6] %s | AUC %.3f | Boyce R28 %.3f vs recalculado %s | %s\n',
       i,id,auc,z$boyce_validacao,if(is.finite(bo$valor)) sprintf('%.3f',bo$valor) else 'NA',status))
}
res <- do.call(rbind,res)
write_r29(res,file.path(saida,'29_CONFERENCIA_BOYCE_R28.csv'))
if(length(Filter(Negate(is.null),curvas)))
  write_r29(do.call(rbind,Filter(Negate(is.null),curvas)),
            file.path(saida,'29_CURVAS_PE_R28.csv'))
write_r29(manifesto,file.path(saida,'29_MANIFESTO_VERIFICADO.csv'))
writeLines(c(
  'R29 ETAPA 1 - BOYCE E P10 DOS 6 MODELOS R28',
  paste('Executado:',Sys.time()),
  'AUC, P10 e omissao recalculados dos scores: conferidos com R28.',
  'Boyce original: ecospat nclass=0, rm.duplicate=TRUE, Spearman, fit=BG de validacao, obs=presencas de validacao.',
  'nclass=10 e rm.duplicate=FALSE: apenas sensibilidade, NAO outra selecao de modelo.',
  paste('Boyce reproduzidos:',sum(res$status=='BOYCE_REPRODUZIDO'),'de 6.'),
  paste('Pendentes:',paste(res$id[res$status!='BOYCE_REPRODUZIDO'],collapse='; ')),
  'Boyce elevado com AUC baixa pode ocorrer; verificar curvas P/E e proporcao de BG acima P10.',
  'UPAs reservadas contiguas a areas de treino: diagnostico LOCAL, nao independencia regional.'
),file.path(saida,'29_RELATORIO_AUDITORIA_BOYCE.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),file.path(saida,'29_SESSION_INFO.txt'))
cat('\nR29 ETAPA 1 CONCLUIDA. Pasta:',saida,'\n')
