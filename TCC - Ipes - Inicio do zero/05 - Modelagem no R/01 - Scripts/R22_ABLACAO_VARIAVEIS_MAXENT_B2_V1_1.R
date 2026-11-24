# ============================================================================
# TCC IPES | R22 V1.1 - ABLACAO CONTROLADA DE VARIAVEIS | MAXENT / B2
# ============================================================================
# Objetivo: testar a sensibilidade dos modelos a retirada de preditores,
# SEM modificar os folds, as UPAs inventariadas, os backgrounds ou o teste externo.
# Plano: 2 especies x 3 folds x 6 conjuntos = 36 avaliacoes.
# C0: 6 modelos originais LQH/RM4 do R19, VALIDAR E REUTILIZAR (sem reajuste).
# C1 a C5: 30 ajustes NOVOS com maxnet usando exatamente os dados B2 do R19.
# AUC compara presencas e background, NAO ausencias confirmadas.
# Os 7 empreendimentos de teste externo jamais sao carregados.
#
# COMO EXECUTAR: source('.../R22_ABLACAO_VARIAVEIS_MAXENT_B2_V1_1.R')
# Ao solicitar, escolha 19_METRICAS_72_MODELOS_B2.csv NA PASTA ORIGINAL R19.
# Exige '19_MANIFESTO_ENTRADAS.csv' e '19_MODELOS_RDS/' no mesmo diretorio.
# Saida propria em 06 - Resultados/20 - Ablacao de variaveis R22 V1.
# Nao edita arquivos de R05, R08, R16, R18, R19, R20 ou R21.
# ============================================================================

# O identificador de protocolo do manifesto permanece V1 para permitir RETOMADA
# dos checkpoints ja gerados. V1.1 altera somente uma checagem que barrava
# categorias de SOLO raras presentes exclusivamente na validacao.
# Nao altera dados, formula, parametros, randomizacao ou metricas.
versao_r22 <- 'R22_ABLACAO_B2_V1_20261117'
versao_codigo <- 'R22_ABLACAO_B2_V1_1_20261117'
for (pacote in c('maxnet','ecospat')) {
  if (!requireNamespace(pacote,quietly=TRUE))
    stop('Falta o pacote ',pacote,'. Instale em R com install.packages("',pacote,'")')
}
cat('\nR22: selecione 19_METRICAS_72_MODELOS_B2.csv na pasta ORIGINAL do R19.\n')
metrica_19_arq <- normalizePath(file.choose(),winslash='/',mustWork=TRUE)
if (basename(metrica_19_arq)!='19_METRICAS_72_MODELOS_B2.csv')
  stop('Escolha exatamente 19_METRICAS_72_MODELOS_B2.csv (sem o sufixo (1)).')
pasta19 <- dirname(metrica_19_arq)
resultados_dir <- pasta19
while (basename(resultados_dir)!='06 - Resultados' &&
       dirname(resultados_dir)!=resultados_dir)
  resultados_dir <- dirname(resultados_dir)
if (basename(resultados_dir)!='06 - Resultados')
  stop('O R19 original precisa estar dentro da arvore 06 - Resultados.')
raiz <- dirname(resultados_dir)
saida <- file.path(resultados_dir,'20 - Ablacao de variaveis R22 V1')

ler <- function(f) utils::read.csv(f,stringsAsFactors=FALSE,
                                      fileEncoding='UTF-8-BOM',check.names=FALSE)
escrever_csv <- function(x,f) {
  temporario <- paste0(f,'.tmp')
  utils::write.csv(x,temporario,row.names=FALSE,fileEncoding='UTF-8')
  if (file.exists(f)) {
    if (!file.copy(temporario,f,overwrite=TRUE)) stop('Falha ao atualizar ',f)
    unlink(temporario)
  } else if (!file.rename(temporario,f)) stop('Falha ao gravar ',f)
}
exigir_colunas <- function(d,col,arquivo) {
  faltam <- setdiff(col,names(d))
  if(length(faltam)) stop(arquivo,': colunas ausentes: ',paste(faltam,collapse=', '))
}
md5 <- function(f) unname(tools::md5sum(f))
quantil <- function(x,prob) as.numeric(stats::quantile(x,prob,type=7))
auc <- function(p,b) {
  if (!length(p) || !length(b) || any(!is.finite(c(p,b))))
    return(NA_real_)
  n <- length(p)
  (sum(rank(c(p,b),ties.method='average')[seq_len(n)])-
    n*(n+1)/2)/(n*length(b))
}
calcular_boyce <- function(p,b) {
  avisos <- character()
  if (min(length(p),length(b))<2L || any(!is.finite(c(p,b))))
    return(list(valor=NA_real_,status='INDEFINIDO: valores invalidos'))
  obj <- tryCatch(withCallingHandlers(
    ecospat::ecospat.boyce(fit=as.numeric(b),obs=as.numeric(p),
      nclass=0,PEplot=FALSE,method='spearman',rm.duplicate=TRUE),
    warning=function(w){avisos <<- c(avisos,conditionMessage(w));
                         invokeRestart('muffleWarning')}
  ),error=function(e){avisos <<- c(avisos,conditionMessage(e)); NULL})
  v <- NA_real_
  if (is.list(obj) && !is.null(obj$cor)) v <- as.numeric(obj$cor)
  else if (is.list(obj) && !is.null(obj$Spearman.cor))
    v <- as.numeric(obj$Spearman.cor)
  if(length(v)!=1L || !is.finite(v) || abs(v)>1.0000001)
    return(list(valor=NA_real_,status=paste('INDEFINIDO:',
      if(length(avisos)) paste(unique(avisos),collapse=' | ')
      else 'coeficiente ausente')))
  list(valor=v,status=if(length(avisos)) paste('AVISO:',
       paste(unique(avisos),collapse=' | ')) else 'OK')
}

# ---------------------------------------------------------------------------
# A) Localizar as entradas exatamente conforme manifesto do R19 (sem adivinhar
# nomes ou buscar em todas as pastas, que pode confundir versoes diferentes).
# ---------------------------------------------------------------------------
arq_manifesto <- file.path(pasta19,'19_MANIFESTO_ENTRADAS.csv')
if (!file.exists(arq_manifesto))
  stop('Nao encontrei 19_MANIFESTO_ENTRADAS.csv junto das metricas do R19.')
manifesto19 <- ler(arq_manifesto)
exigir_colunas(manifesto19,c('arquivo','caminho','md5','maxnet','ecospat'),
               'Manifesto R19')
if (anyDuplicated(manifesto19$arquivo))
  stop('Manifesto R19 contem nomes de arquivo repetidos: revise manualmente.')
loc_manifesto <- function(nome) {
  linha <- manifesto19[manifesto19$arquivo==nome,,drop=FALSE]
  if(nrow(linha)!=1L) stop('Fonte nao identificada no manifesto R19: ',nome)
  original <- gsub('\\\\','/',as.character(linha$caminho[1]))
  opcoes <- original
  for (ancora in c('04 - Dados para o MaxEnt/','06 - Resultados/')) {
    k <- regexpr(ancora,original,fixed=TRUE)[1]
    if(k>0L) opcoes <- c(opcoes,file.path(raiz,substring(original,k)))
  }
  opcoes <- unique(opcoes)
  existentes <- opcoes[file.exists(opcoes)]
  validos <- existentes[tolower(vapply(existentes,md5,character(1)))==
                         tolower(as.character(linha$md5[1]))]
  if(!length(validos)) stop('Nao encontrei fonte com MD5 correto: ',nome,
    '\nCaminho registrado: ',original,
    '\nReponha a fonte original; nao use outro CSV parecido.')
  normalizePath(validos[1],winslash='/',mustWork=TRUE)
}
arq_pres <- loc_manifesto('05_PRESENCAS_UM_POR_PIXEL_30M.csv')
arq_b2 <- loc_manifesto('18_BACKGROUND_B2_10000_COM_FOLDS.csv')
arq_b0 <- loc_manifesto('05_BACKGROUND_COM_FOLDS.csv')
pres <- ler(arq_pres)
b2 <- ler(arq_b2)
b0 <- ler(arq_b0)
m19 <- ler(metrica_19_arq)

continuas <- c('altitude_m','declividade_graus','dist_rio_raster_m',
               'bio12_mm_ano','bio17_mm_mes')
seis <- c(continuas,'textura_subgrupo')
especies <- c('Ipe-roxo','Ipe-amarelo')
exigir_colunas(pres,c('especie','propriedade','upa_id','fold_cv',
                      'celula_raster',seis),'Presencas R05')
exigir_colunas(b2,c('propriedade','upa_id','fold_cv',
                    'id_background','celula_raster',seis),'Background B2')
exigir_colunas(b0,c('propriedade','upa_id','fold_cv',seis),'Background B0')
exigir_colunas(m19,c('id','especie','fold_cv','features','RM',
    'n_presenca_treino','n_background_treino','n_presenca_validacao',
    'n_background_validacao','auc_treino','auc_validacao',
    'auc_validacao_bg_b0_fixo','omissao10_treino','omissao10_validacao',
    'limiar10_treino_cloglog','boyce_validacao','n_features_ativas'),
    'Metricas do R19')
if(nrow(pres)!=8680L || nrow(b2)!=10000L || nrow(b0)!=5000L ||
   nrow(m19)!=72L || anyDuplicated(m19$id) ||
   sum(pres$especie=='Ipe-roxo')!=3248L ||
   sum(pres$especie=='Ipe-amarelo')!=5432L ||
   !setequal(unique(pres$especie),especies) ||
   length(unique(b2$propriedade))!=27L ||
   nrow(unique(b2[,c('propriedade','upa_id')]))!=64L ||
   !setequal(unique(pres$propriedade),unique(b2$propriedade)) ||
   !setequal(unique(b2$fold_cv),1:3) ||
   !setequal(unique(pres$fold_cv),1:3) ||
   !setequal(unique(m19$features),c('l','lq','lqh')) ||
   !setequal(unique(m19$RM),1:4))
  stop('Entradas diferem do protocolo R05/R18/R19 auditado. Nenhum ajuste iniciado.')
if(anyNA(pres[,c('especie','propriedade','upa_id','fold_cv',seis),drop=FALSE]) ||
   anyNA(b2[,c('propriedade','upa_id','fold_cv',seis),drop=FALSE]) ||
   anyNA(b0[,c('propriedade','upa_id','fold_cv',seis),drop=FALSE]))
  stop('Variaveis ou identificadores com NA em R05/B0/B2.')
for(v in continuas) {
  if(!is.numeric(pres[[v]]) || !is.numeric(b2[[v]]) || !is.numeric(b0[[v]]) ||
     any(!is.finite(pres[[v]])) || any(!is.finite(b2[[v]])) ||
     any(!is.finite(b0[[v]]))) stop('Variavel numerica invalida: ',v)
}
normalizar_nome <- function(v) {
  w <- iconv(as.character(v),from='',to='ASCII//TRANSLIT')
  if(anyNA(w)) stop('Erro de codificacao no nome das propriedades.')
  toupper(trimws(gsub('_',' ',w,fixed=TRUE)))
}
reservadas <- c('BARRO BRANCO','CURUCA','GUARIUBA','JATOBA',
                'LOTE 01','MARILIA','PALMEIRA')
if(any(normalizar_nome(c(pres$propriedade,b2$propriedade,b0$propriedade)) %in%
       reservadas)) stop('TESTE EXTERNO DETECTADO: parada de seguranca.')
fo <- unique(rbind(pres[,c('propriedade','fold_cv')],
                   b2[,c('propriedade','fold_cv')],
                   b0[,c('propriedade','fold_cv')]))
if(any(vapply(split(fo$fold_cv,fo$propriedade),
          function(z) length(unique(z))!=1L,logical(1))))
  stop('Propriedade dividida entre folds em R05/B2/B0.')
chave_upa <- function(x) paste(x$propriedade,x$upa_id,sep='||')
if(!all(chave_upa(pres) %in% chave_upa(b2)))
  stop('Ha presencas fora das UPAs inventariadas usadas pelo background B2.')
if(anyDuplicated(paste(pres$propriedade,pres$especie,pres$celula_raster)) ||
   anyDuplicated(paste(b2$propriedade,b2$celula_raster)) ||
   anyDuplicated(b2$id_background))
  stop('Duplicidades encontradas nas entradas de presencas ou B2.')
if(any(vapply(split(b2$fold_cv,chave_upa(b2)),
              function(z) length(unique(z))>1L,logical(1))))
  stop('Uma UPA foi repartida entre folds.')
if(!identical(as.character(unique(manifesto19$maxnet)),
              as.character(utils::packageVersion('maxnet'))) ||
   !identical(as.character(unique(manifesto19$ecospat)),
              as.character(utils::packageVersion('ecospat'))))
  stop('Versao de maxnet/ecospat diferente do R19. Evite mesclar pacotes.')

# Os niveis do solo devem ser os mesmos do R19, inclusive nos folds nos quais
# uma classe e rara. Para C5 retiramos completamente o fator da formula.
niveis_solo <- as.character(sort(unique(as.integer(c(
                   pres$textura_subgrupo,b2$textura_subgrupo)))))
if(!identical(as.integer(niveis_solo),c(2L,3L,4L,6L,7L)))
  stop('Codigos de textura diferentes dos utilizados no R19.')
montar_x <- function(d,vars) {
  x <- d[,vars,drop=FALSE]
  for (v in intersect(continuas,vars)) x[[v]] <- as.numeric(x[[v]])
  if ('textura_subgrupo' %in% vars)
    x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),
                                 levels=niveis_solo)
  if(anyNA(x)) stop('Alguma variavel ambiental virou NA no montar_x().')
  x
}

# ---------------------------------------------------------------------------
# B) Plano predefinido, fixo, sem escolha por desempenho.
# ---------------------------------------------------------------------------
conjuntos <- list(
  C0_COMPLETO=seis,
  C1_SEM_BIO12=setdiff(seis,'bio12_mm_ano'),
  C2_SEM_BIO17=setdiff(seis,'bio17_mm_mes'),
  C3_SEM_BIO12_E_BIO17=setdiff(seis,c('bio12_mm_ano','bio17_mm_mes')),
  C4_SEM_ALTITUDE=setdiff(seis,'altitude_m'),
  C5_SEM_TEXTURA=setdiff(seis,'textura_subgrupo')
)
plano <- expand.grid(especie=especies,fold_cv=1:3,
                     conjunto=names(conjuntos),KEEP.OUT.ATTRS=FALSE,
                     stringsAsFactors=FALSE)
plano$features <- 'lqh'; plano$RM <- 4L
plano$id <- vapply(seq_len(nrow(plano)),function(i) {
  z <- plano[i,]
  paste0('R22_',ifelse(z$especie=='Ipe-roxo','ROXO','AMARELO'),
         '_F',z$fold_cv,'_',sub('_.*$','',z$conjunto),'_LQH_RM4')
},character(1))
plano$preditores <- vapply(plano$conjunto,function(k)
                         paste(conjuntos[[k]],collapse='; '),character(1))
if(nrow(plano)!=36L || anyDuplicated(plano$id) ||
   sum(plano$conjunto=='C0_COMPLETO')!=6L) stop('Plano R22 invalido.')

# RDS oficiais: o R19 usa tambem 19_CHECKPOINTS, cujos arquivos .rds podem
# representar checkpoints nao-maxnet. NUNCA pesquisar de forma recursiva!
modelos19_dir <- file.path(pasta19,'19_MODELOS_RDS')
if(!dir.exists(modelos19_dir))
  stop('Pasta oficial de modelos R19 ausente: ',modelos19_dir,
       '\nNao use 19_CHECKPOINTS como substituta.')
referencias <- plano[plano$conjunto=='C0_COMPLETO',,drop=FALSE]
referencias$id_r19 <- vapply(seq_len(nrow(referencias)),function(i) {
  z <- referencias[i,]
  paste0('M1B2_',ifelse(z$especie=='Ipe-roxo','ROXO','AMARELO'),
         '_F',z$fold_cv,'_LQH_RM4')
},character(1))
if(!all(referencias$id_r19 %in% m19$id)) stop('Referencia C0 nao consta no R19.')
arqs_rds19 <- file.path(modelos19_dir,paste0(referencias$id_r19,'.rds'))
if(!all(file.exists(arqs_rds19)))
  stop('RDS C0 nao encontrados em 19_MODELOS_RDS: ',
       paste(basename(arqs_rds19[!file.exists(arqs_rds19)]),collapse=', '))

# Verificacoes de amostragem E identidade antes de criar arquivos de resultados.
for (f in 1:3) {
  tr <- b2[b2$fold_cv!=f,,drop=FALSE]
  va <- b2[b2$fold_cv==f,,drop=FALSE]
  if(min(nrow(tr),nrow(va))<500L) stop('Background B2 insuficiente no fold ',f)
  for (sp in especies) {
    x <- m19[m19$especie==sp & m19$fold_cv==f &
             m19$features=='lqh' & m19$RM==4,,drop=FALSE]
    if(nrow(x)!=1L ||
       x$n_background_treino!=nrow(tr) ||
       x$n_background_validacao!=nrow(va) ||
       x$n_presenca_treino!=sum(pres$especie==sp & pres$fold_cv!=f) ||
       x$n_presenca_validacao!=sum(pres$especie==sp & pres$fold_cv==f))
      stop('Fold B2 nao reproduz tamanhos R19 para ',sp,' F',f)
  }
}

cat('\nPreflight concluido: 8680 presencas; 10000 B2; 5000 B0; ',
    '27 propriedades; 64 UPAs; 36 avaliacoes.\n',sep='')

# ---------------------------------------------------------------------------
# C) Funcoes para calcular previsoes e verificacoes dos modelos C0.
# ---------------------------------------------------------------------------
prever <- function(modelo,x,rotulo) {
  z <- tryCatch(as.numeric(stats::predict(modelo,x,type='cloglog',clamp=TRUE)),
    error=function(e) stop('Falha na previsao [',rotulo,']: ',
                            conditionMessage(e),call.=FALSE))
  if(length(z)!=nrow(x) || any(!is.finite(z)) || any(z<0 | z>1))
    stop('Scores invalidos: ',rotulo)
  z
}
obter_dados_fold <- function(sp,f) {
  list(tp=pres[pres$especie==sp & pres$fold_cv!=f,,drop=FALSE],
       vp=pres[pres$especie==sp & pres$fold_cv==f,,drop=FALSE],
       tb=b2[b2$fold_cv!=f,,drop=FALSE],
       vb=b2[b2$fold_cv==f,,drop=FALSE],
       v0=b0[b0$fold_cv==f,,drop=FALSE])
}
calcular_scores <- function(mod,ds,vars,rotulo) {
  list(stp=prever(mod,montar_x(ds$tp,vars),paste(rotulo,'treino pres')),
       stb=prever(mod,montar_x(ds$tb,vars),paste(rotulo,'treino bg')),
       svp=prever(mod,montar_x(ds$vp,vars),paste(rotulo,'val pres')),
       svb=prever(mod,montar_x(ds$vb,vars),paste(rotulo,'val bg B2')),
       sv0=prever(mod,montar_x(ds$v0,vars),paste(rotulo,'val bg B0')))
}
calcular_metricas <- function(z,ds,sc,modelo,origem,segundos) {
  lim <- quantil(sc$stp,.10)
  b2boyce <- calcular_boyce(sc$svp,sc$svb)
  b0boyce <- calcular_boyce(sc$svp,sc$sv0)
  data.frame(id=z$id,especie=z$especie,fold_cv=z$fold_cv,
    conjunto=z$conjunto,features='lqh',RM=4L,
    preditores=z$preditores,
    n_presenca_treino=nrow(ds$tp),n_background_treino=nrow(ds$tb),
    n_presenca_validacao=nrow(ds$vp),n_background_b2_validacao=nrow(ds$vb),
    n_background_b0_fixo=nrow(ds$v0),
    auc_treino=auc(sc$stp,sc$stb),
    auc_validacao_b2=auc(sc$svp,sc$svb),
    auc_validacao_b0_fixo=auc(sc$svp,sc$sv0),
    boyce_b2=b2boyce$valor,status_boyce_b2=b2boyce$status,
    boyce_b0_fixo=b0boyce$valor,status_boyce_b0_fixo=b0boyce$status,
    limiar_p10_treino=lim,
    omissao_p10_treino=mean(sc$stp<lim),
    omissao_p10_validacao=mean(sc$svp<lim),
    p50_score_presencas_validacao=stats::median(sc$svp),
    p50_score_bg_b2_validacao=stats::median(sc$svb),
    max_score_presencas_validacao=max(sc$svp),
    numero_coeficientes=length(modelo$betas),
    origem_modelo=origem,tempo_ajuste_segundos=segundos,
    stringsAsFactors=FALSE)
}
criar_previsoes <- function(z,ds,sc) {
  def <- function(d,tipo,score) data.frame(
    id=z$id,especie=z$especie,fold_cv=z$fold_cv,conjunto=z$conjunto,
    tipo=tipo,propriedade=d$propriedade,upa_id=d$upa_id,
    celula_raster=if('celula_raster' %in% names(d))
       as.character(d$celula_raster) else NA_character_,
    id_background=if('id_background' %in% names(d))
       as.character(d$id_background) else NA_character_,
    score_cloglog=score,stringsAsFactors=FALSE)
  rbind(def(ds$vp,'PRESENCA_VALIDACAO',sc$svp),
        def(ds$vb,'BACKGROUND_B2_VALIDACAO',sc$svb),
        def(ds$v0,'BACKGROUND_B0_FIXO',sc$sv0))
}

# Primeiro reproduz rigorosamente os seis C0 do R19, inclusive sobre B0 fixo.
# O teste usa scores do RDS, nao apenas igualdade das metricas entre CSVs.
verificacao_c0 <- vector('list',6L)
for(i in seq_len(nrow(referencias))) {
  z <- referencias[i,,drop=FALSE]
  ds <- obter_dados_fold(z$especie,z$fold_cv)
  ref <- m19[m19$id==z$id_r19,,drop=FALSE]
  caminho <- arqs_rds19[i]
  modelo <- tryCatch(readRDS(caminho),error=function(e)NULL)
  if(is.null(modelo) || !inherits(modelo,'maxnet'))
    stop('Modelo R19 C0 nao e objeto maxnet valido: ',caminho)
  sc <- calcular_scores(modelo,ds,seis,z$id_r19)
  lim <- quantil(sc$stp,.10)
  verificacoes <- c(
    p10=abs(lim-ref$limiar10_treino_cloglog),
    auc_b2=abs(auc(sc$svp,sc$svb)-ref$auc_validacao),
    auc_b0=abs(auc(sc$svp,sc$sv0)-ref$auc_validacao_bg_b0_fixo),
    auc_treino=abs(auc(sc$stp,sc$stb)-ref$auc_treino),
    omissao=abs(mean(sc$svp<lim)-ref$omissao10_validacao),
    omissao_treino=abs(mean(sc$stp<lim)-ref$omissao10_treino))
  if(any(!is.finite(verificacoes)) || max(verificacoes)>1e-6 ||
     length(modelo$betas)!=ref$n_features_ativas)
    stop('C0 nao reproduziu R19: ',z$id_r19,
         '\nDiferencas: ',paste(names(verificacoes),
         signif(verificacoes,5),sep='=',collapse=' | '),
         '\nNumero de coeficientes: ',length(modelo$betas),
         ' (R19: ',ref$n_features_ativas,'). NENHUM ajuste iniciado.')
  verificacao_c0[[i]] <- data.frame(id_r22=z$id,id_r19=z$id_r19,
      caminho_rds=caminho,md5_rds=md5(caminho),
      maior_diferenca_numerica=max(verificacoes),
      coeficientes=length(modelo$betas),status='REPRODUZIDO',
      stringsAsFactors=FALSE)
  cat(sprintf('Referencia R19 validada [%d/6]: %s | maior diferenca %.3g\n',
              i,z$id_r19,max(verificacoes)))
}
verificacao_c0 <- do.call(rbind,verificacao_c0)

# Auditoria de niveis de solo por especie/fold. O nivel 7 ocorre em apenas
# 2 backgrounds B2 de validacao no Fold 1, sem presencas amarelas nessa classe.
# A contagem vem das ENTRADAS R05/R18, nao de valores inferidos.
auditoria_solo <- list(); ns <- 0L
for (sp in especies) for (f in 1:3) {
  ds <- obter_dados_fold(sp,f)
  treino_niveis <- unique(as.character(c(ds$tp$textura_subgrupo,
                                          ds$tb$textura_subgrupo)))
  for(grupo in c('presencas_validacao','background_b2_validacao',
                 'background_b0_fixo')) {
    d <- switch(grupo,presencas_validacao=ds$vp,
                background_b2_validacao=ds$vb,
                background_b0_fixo=ds$v0)
    for(k in niveis_solo) {
      ns <- ns+1L
      auditoria_solo[[ns]] <- data.frame(
        especie=sp,fold_cv=f,grupo=grupo,classe_textura=k,
        presente_no_treino=k %in% treino_niveis,
        n_grupo=nrow(d),n_classe=sum(as.character(d$textura_subgrupo)==k),
        n_nivel_novo=if(k %in% treino_niveis) 0L
          else sum(as.character(d$textura_subgrupo)==k),
        stringsAsFactors=FALSE)
    }
  }
}
auditoria_solo <- do.call(rbind,auditoria_solo)
# Nao tratar como extrapolacao negligenciavel se houver PRESENCAS de
# validacao com classe nova ou numero relevante de BG novos. Para os dados
# R19, ha somente 2 BG B2 na classe 7 (Fold 1), sem presencas novas.
aus_pres <- auditoria_solo[auditoria_solo$grupo=='presencas_validacao',]
aus_b2 <- auditoria_solo[auditoria_solo$grupo=='background_b2_validacao',]
if(sum(aus_pres$n_nivel_novo)>0L)
  stop('Solo: ha PRESENCAS de validacao com classe ausente no treino; ',
       'analise necessita decisao metodologica, nao extrapolacao automatica.')
if(any(aus_b2$n_nivel_novo/pmax(1L,aus_b2$n_grupo)>.01))
  stop('Solo: >1% do BG B2 em classe sem treino; auditar antes de ajustar.')
if(sum(auditoria_solo$n_nivel_novo)>0L)
  cat('AVISO R22 V1.1: niveis de solo ausentes no treino detectados; ',
      'serao registrados sem reclassificacao.\n',sep='')

# ---------------------------------------------------------------------------
# D) Nova pasta R22. Retomada segura com checkpoint por avaliacao.
# ---------------------------------------------------------------------------
manifesto22 <- data.frame(
  arquivo=c('05_PRESENCAS_UM_POR_PIXEL_30M.csv',
            '18_BACKGROUND_B2_10000_COM_FOLDS.csv',
            '05_BACKGROUND_COM_FOLDS.csv',
            '19_METRICAS_72_MODELOS_B2.csv',
            '19_MANIFESTO_ENTRADAS.csv'),
  md5=vapply(c(arq_pres,arq_b2,arq_b0,metrica_19_arq,arq_manifesto),
              md5,character(1)),
  versao=versao_r22,
  R=R.version.string,
  maxnet=as.character(utils::packageVersion('maxnet')),
  ecospat=as.character(utils::packageVersion('ecospat')),
  stringsAsFactors=FALSE)
manifesto_saida <- file.path(saida,'22_MANIFESTO_ENTRADAS.csv')
if(dir.exists(saida)) {
  if(!file.exists(manifesto_saida))
    stop('A pasta R22 existe sem manifesto. Nao sobrescrever: ',saida)
  antigo <- ler(manifesto_saida)
  if(!identical(antigo,manifesto22))
    stop('Dados, ambiente ou versao do R22 mudaram. Nao misturar execucoes.')
  cat('R22: retomada de execucao anterior (manifesto identico).\n')
} else dir.create(saida,recursive=TRUE,showWarnings=FALSE)
mod_dir <- file.path(saida,'22_MODELOS_RDS')
met_dir <- file.path(saida,'22_CHECKPOINT_METRICAS')
pred_dir <- file.path(saida,'22_PREVISOES_VALIDACAO')
graf_dir <- file.path(saida,'22_GRAFICOS')
for(d in c(mod_dir,met_dir,pred_dir,graf_dir))
  if(!dir.exists(d)) dir.create(d,recursive=TRUE,showWarnings=FALSE)
if(!file.exists(manifesto_saida)) escrever_csv(manifesto22,manifesto_saida)
escrever_csv(plano,file.path(saida,'22_PLANO_36_AVALIACOES.csv'))
escrever_csv(verificacao_c0,file.path(saida,'22_VERIFICACAO_RDS_R19_C0.csv'))
escrever_csv(auditoria_solo,file.path(saida,'22_AUDITORIA_SOLO_NIVEIS_V1_1.csv'))
nota_v11 <- c(
  'R22 V1.1 - correcao de verificacao de categorias de solo',
  paste('Codigo:',versao_codigo),
  paste('Executado em:',as.character(Sys.time())),
  'O R22 V1 interrompia se qualquer categoria do solo na validacao',
  'nao estivesse no treino. No Fold 1 amarelo, classe 7 ocorre em',
  'apenas 2 pontos de BG B2 e nao ocorre no treino nem nas presencas',
  'de validacao. Niveis de fator globais: 2, 3, 4, 6, 7.',
  'V1.1 mantem a classe original, preve com os mesmos niveis globais',
  'e registra contagens e a sensibilidade da AUC sem esses pontos.',
  'SEM alteracoes de dados, modelos C0, LQH, RM4 ou formula maxnet.',
  'A pasta R22 V1 e os checkpoints originais sao preservados.',
  'Os novos checkpoints apos a retomada usam V1.1.',
  'O manifesto original V1 fica preservado para compatibilidade;',
  'este arquivo e a auditoria de solo documentam a correcao.',
  'Nenhuma recodificacao, exclusao ou imputacao de classes foi aplicada.',
  'Uma classe inedita nao tem efeito categorial estimado do treino:',
  'a predicao e extrapolatoria e requer interpretacao cuidadosa.'
)
writeLines(nota_v11,file.path(saida,'22_NOTA_CORRECAO_V1_1.txt'),useBytes=TRUE)

metricas_list <- vector('list',nrow(plano))
for(i in seq_len(nrow(plano))) {
  z <- plano[i,,drop=FALSE]; id <- z$id
  cp <- file.path(pred_dir,paste0(id,'.csv'))
  cm <- file.path(met_dir,paste0(id,'.csv'))
  cr <- file.path(mod_dir,paste0(id,'.rds'))
  existentes <- file.exists(c(cp,cm,cr))
  if(any(existentes) && !all(existentes))
    stop('Checkpoint incompleto para ',id,
         '. Preserve os arquivos; envie os caminhos para auditoria.')
  ds <- obter_dados_fold(z$especie,z$fold_cv)
  var <- conjuntos[[z$conjunto]]
  if(all(existentes)) {
    met <- ler(cm); pr <- ler(cp)
    modelo <- tryCatch(readRDS(cr),error=function(e)NULL)
    if(nrow(met)!=1L || !inherits(modelo,'maxnet') ||
       !identical(as.character(met$id),id) ||
       !identical(as.character(met$conjunto),z$conjunto) ||
       length(modelo$betas)!=met$numero_coeficientes ||
       nrow(pr)!=(nrow(ds$vp)+nrow(ds$vb)+nrow(ds$v0)) ||
       any(!is.finite(pr$score_cloglog)))
      stop('Checkpoint invalido: ',id)
    p <- pr$score_cloglog[pr$tipo=='PRESENCA_VALIDACAO']
    b <- pr$score_cloglog[pr$tipo=='BACKGROUND_B2_VALIDACAO']
    b0fixo <- pr$score_cloglog[pr$tipo=='BACKGROUND_B0_FIXO']
    if(length(p)!=nrow(ds$vp) || length(b)!=nrow(ds$vb) ||
       length(b0fixo)!=nrow(ds$v0) ||
       abs(auc(p,b)-met$auc_validacao_b2)>1e-8 ||
       abs(auc(p,b0fixo)-met$auc_validacao_b0_fixo)>1e-8 ||
       abs(mean(p<met$limiar_p10_treino)-met$omissao_p10_validacao)>1e-8)
      stop('Metricas do checkpoint nao reproduzidas: ',id)
    metricas_list[[i]] <- met
    cat(sprintf('[%02d/36] %s: checkpoint validado\n',i,id))
    next
  }
  if(z$conjunto=='C0_COMPLETO') {
    idx <- match(id,verificacao_c0$id_r22)
    modelo <- readRDS(verificacao_c0$caminho_rds[idx])
    origem <- 'REUTILIZADO_R19_C0'; segundos <- 0
  } else {
    # Como a ablação e um experimento controlado, NAO ajustar novos folds,
    # NAO refazer dados de background e NAO selecionar features por metricas.
    tp <- ds$tp; tb <- ds$tb
    if(min(nrow(tp),nrow(tb),nrow(ds$vp),nrow(ds$vb))<100L)
      stop('Amostras insuficientes no fold ',id)
    if('textura_subgrupo' %in% var) {
      cat_train <- unique(c(as.character(tp$textura_subgrupo),
                            as.character(tb$textura_subgrupo)))
      cat_val <- unique(c(as.character(ds$vp$textura_subgrupo),
                          as.character(ds$vb$textura_subgrupo),
                          as.character(ds$v0$textura_subgrupo)))
      if(!all(cat_val %in% niveis_solo))
        stop('Solo: categoria de validacao NAO prevista nos niveis globais: ',id)
      # Classe sem observacoes no treino nao recebe efeito aprendido proprio.
      # NAO recodificar, excluir ou reclassificar esses pontos. Como no R19,
      # os fatores mantem os niveis globais e a previsao fica auditavel.
      faltam <- setdiff(cat_val,cat_train)
      if(length(faltam))
        cat('AVISO SOLO [',id,']: nivel(is) somente na validacao: ',
            paste(faltam,collapse=','),
            ' (detalhes em 22_AUDITORIA_SOLO_NIVEIS_V1_1.csv).\n',sep='')
    }
    xt <- montar_x(rbind(tp[,var,drop=FALSE],tb[,var,drop=FALSE]),var)
    y <- c(rep(1L,nrow(tp)),rep(0L,nrow(tb)))
    t0 <- Sys.time()
    formula_maxnet <- maxnet::maxnet.formula(y,xt,classes='lqh')
    modelo <- maxnet::maxnet(y,xt,f=formula_maxnet,regmult=4,
                            addsamplestobackground=TRUE)
    segundos <- as.numeric(difftime(Sys.time(),t0,units='secs'))
    origem <- 'NOVO_AJUSTE_R22'
  }
  sc <- calcular_scores(modelo,ds,var,id)
  met <- calcular_metricas(z,ds,sc,modelo,origem,segundos)
  pp <- criar_previsoes(z,ds,sc)
  if(z$conjunto=='C0_COMPLETO') {
    ref <- m19[m19$id==referencias$id_r19[match(id,referencias$id)],,
               drop=FALSE]
    if(abs(met$limiar_p10_treino-ref$limiar10_treino_cloglog)>1e-6 ||
       abs(met$auc_validacao_b2-ref$auc_validacao)>1e-6 ||
       abs(met$auc_validacao_b0_fixo-ref$auc_validacao_bg_b0_fixo)>1e-6 ||
       abs(met$omissao_p10_validacao-ref$omissao10_validacao)>1e-8)
      stop('C0 de R19 perdeu identidade durante execucao: ',id)
  }
  # Checkpoints sao gravados apenas na pasta nova R22. Nao existe escrita no R19.
  caminho_tmp <- paste0(cr,'.tmp')
  saveRDS(modelo,caminho_tmp)
  if(!file.rename(caminho_tmp,cr))
    stop('Falha ao salvar modelo R22: ',id)
  escrever_csv(pp,cp)
  escrever_csv(met,cm)
  metricas_list[[i]] <- met
  cat(sprintf('[%02d/36] %s | AUC B2=%.3f | omissao=%.1f%% | Boyce=%s | %s\n',
        i,id,met$auc_validacao_b2,100*met$omissao_p10_validacao,
        if(is.finite(met$boyce_b2)) sprintf('%.3f',met$boyce_b2)
        else 'indefinido',origem))
  parcial <- do.call(rbind,metricas_list[!vapply(metricas_list,is.null,logical(1))])
  escrever_csv(parcial,file.path(saida,'22_METRICAS_PARCIAIS.csv'))
}
metricas <- do.call(rbind,metricas_list)
if(nrow(metricas)!=36L || anyDuplicated(metricas$id))
  stop('R22 nao terminou com 36 avaliacoes unicas.')
escrever_csv(metricas,file.path(saida,'22_METRICAS_36_AVALIACOES.csv'))

# Sensibilidade do calculo de AUC caso se excluissem SOMENTE DA METRICA
# os BG com solo ausente no treino (nenhuma exclusao no modelo principal).
# Caso raro: 2 BG B2 da classe 7 no Fold 1 amarelo. AUC principal inalterada.
sensibilidade_solo <- list()
for(i in seq_len(nrow(metricas))) {
  z <- metricas[i,,drop=FALSE]
  if(z$conjunto=='C5_SEM_TEXTURA') next
  ds <- obter_dados_fold(z$especie,z$fold_cv)
  treino_solo <- unique(as.character(c(ds$tp$textura_subgrupo,
                                           ds$tb$textura_subgrupo)))
  p_aceito <- as.character(ds$vp$textura_subgrupo) %in% treino_solo
  b_aceito <- as.character(ds$vb$textura_subgrupo) %in% treino_solo
  pr <- ler(file.path(pred_dir,paste0(z$id,'.csv')))
  p <- pr$score_cloglog[pr$tipo=='PRESENCA_VALIDACAO']
  b <- pr$score_cloglog[pr$tipo=='BACKGROUND_B2_VALIDACAO']
  if(length(p)!=nrow(ds$vp) || length(b)!=nrow(ds$vb))
    stop('Sensibilidade de solo com ordem/contagem diferente: ',z$id)
  # A ordem de linhas nas previsoes e preservada por criar_previsoes().
  auc_filtrada <- auc(p[p_aceito],b[b_aceito])
  if(!is.finite(auc_filtrada)) stop('AUC filtrada indefinida: ',z$id)
  sensibilidade_solo[[length(sensibilidade_solo)+1L]] <- data.frame(
    id=z$id,especie=z$especie,fold_cv=z$fold_cv,conjunto=z$conjunto,
    n_presencas_solo_novo=sum(!p_aceito),
    n_background_b2_solo_novo=sum(!b_aceito),
    auc_b2_original=z$auc_validacao_b2,
    auc_b2_analise_sensibilidade=auc_filtrada,
    diferenca_sensibilidade_menos_original=auc_filtrada-z$auc_validacao_b2,
    observacao='Analise secundaria; modelo/metricas principais INALTERADOS',
    stringsAsFactors=FALSE)
}
sensibilidade_solo <- do.call(rbind,sensibilidade_solo)
escrever_csv(sensibilidade_solo,
             file.path(saida,'22_SENSIBILIDADE_SOLO_NOVO_V1_1.csv'))

# ---------------------------------------------------------------------------
# E) AUC e omissao locais - presencas x BG da MESMA propriedade. Sem interpretar
# BG como ausencia real. NA quando menos de 10 em qualquer um dos dois grupos.
# ---------------------------------------------------------------------------
locais <- list(); nloc <- 0L
for(i in seq_len(nrow(metricas))) {
  z <- metricas[i,,drop=FALSE]
  pp <- ler(file.path(pred_dir,paste0(z$id,'.csv')))
  for(propr in unique(pp$propriedade)) {
    pr <- pp[pp$propriedade==propr,,drop=FALSE]
    ap <- pr$score_cloglog[pr$tipo=='PRESENCA_VALIDACAO']
    ab <- pr$score_cloglog[pr$tipo=='BACKGROUND_B2_VALIDACAO']
    if(!length(ap) || !length(ab)) next
    nloc <- nloc+1L
    locais[[nloc]] <- data.frame(id=z$id,especie=z$especie,
      fold_cv=z$fold_cv,conjunto=z$conjunto,propriedade=propr,
      n_presencas=length(ap),n_background_b2=length(ab),
      n_pares_comparaveis=length(ap)*length(ab),
      auc_local_b2=if(min(length(ap),length(ab))>=10L) auc(ap,ab) else NA_real_,
      omissao_local=mean(ap<z$limiar_p10_treino),
      status_auc=if(min(length(ap),length(ab))>=10L) 'OK' else 'AMOSTRA_PEQUENA',
      stringsAsFactors=FALSE)
  }
}
locais <- do.call(rbind,locais)
escrever_csv(locais,file.path(saida,'22_AUC_OMISSAO_POR_PROPRIEDADE.csv'))

# Conferencia adicional: as AUCs locais dos seis modelos completos devem ser
# exatamente as mesmas da tabela R19, calculadas na mesma propriedade e B2.
arq_locais19 <- file.path(pasta19,'19_AUC_OMISSAO_POR_PROPRIEDADE.csv')
if(!file.exists(arq_locais19))
  stop('Tabela local original R19 nao encontrada: ',arq_locais19)
locais19 <- ler(arq_locais19)
exigir_colunas(locais19,c('id','propriedade','n_presencas','n_bg_b2',
                          'auc_bg_b2','omissao10'),'AUC por propriedade R19')
r22_c0 <- locais[locais$conjunto=='C0_COMPLETO' &
                   locais$status_auc=='OK',,drop=FALSE]
r22_c0$id_r19 <- referencias$id_r19[match(r22_c0$id,referencias$id)]
r19_c0 <- locais19[locais19$id %in% referencias$id_r19,,drop=FALSE]
chave_c0_22 <- paste(r22_c0$id_r19,r22_c0$propriedade,sep='||')
chave_c0_19 <- paste(r19_c0$id,r19_c0$propriedade,sep='||')
if(anyDuplicated(chave_c0_22) || anyDuplicated(chave_c0_19) ||
   !setequal(chave_c0_22,chave_c0_19))
  stop('Propriedades locais de C0 nao correspondem ao R19.')
pos_c0 <- match(chave_c0_22,chave_c0_19)
if(any(r22_c0$n_presencas!=r19_c0$n_presencas[pos_c0]) ||
   any(r22_c0$n_background_b2!=r19_c0$n_bg_b2[pos_c0]) ||
   any(abs(r22_c0$auc_local_b2-r19_c0$auc_bg_b2[pos_c0])>1e-8) ||
   any(abs(r22_c0$omissao_local-r19_c0$omissao10[pos_c0])>1e-8))
  stop('AUC local ou omissao C0 nao reproduzidas em relacao ao R19.')
cat('AUC local dos 6 modelos C0 reproduzida contra R19:',
    nrow(r22_c0),'linhas.\n')

for(i in seq_len(nrow(metricas))) {
  z <- metricas[i,,drop=FALSE]
  ll <- locais[locais$id==z$id & is.finite(locais$auc_local_b2),,drop=FALSE]
  metricas$auc_intra_prop_ponderada[i] <-
    if(nrow(ll)) weighted.mean(ll$auc_local_b2,w=ll$n_pares_comparaveis)
    else NA_real_
  metricas$n_propriedades_auc_local[i] <- nrow(ll)
}
escrever_csv(metricas,file.path(saida,'22_METRICAS_36_AVALIACOES.csv'))

# ---------------------------------------------------------------------------
# F) Pares por mesmo fold (C1-C5 menos C0); avaliacoes equilibradas.
# ---------------------------------------------------------------------------
comparacoes <- list(); nc <- 0L
for(sp in especies) for(f in 1:3) {
  ref <- metricas[metricas$especie==sp & metricas$fold_cv==f &
                  metricas$conjunto=='C0_COMPLETO',,drop=FALSE]
  if(nrow(ref)!=1L) stop('Referencia C0 ambigua: ',sp,' Fold ',f)
  for(k in setdiff(names(conjuntos),'C0_COMPLETO')) {
    z <- metricas[metricas$especie==sp & metricas$fold_cv==f &
                  metricas$conjunto==k,,drop=FALSE]
    if(nrow(z)!=1L) stop('Comparacao R22 faltante: ',sp,' Fold ',f,' ',k)
    nc <- nc+1L
    comparacoes[[nc]] <- data.frame(especie=sp,fold_cv=f,conjunto=k,
      auc_b2_dif=z$auc_validacao_b2-ref$auc_validacao_b2,
      auc_b0_fixo_dif=z$auc_validacao_b0_fixo-ref$auc_validacao_b0_fixo,
      auc_intra_prop_dif=z$auc_intra_prop_ponderada-ref$auc_intra_prop_ponderada,
      boyce_b2_dif=z$boyce_b2-ref$boyce_b2,
      omissao_p10_dif=z$omissao_p10_validacao-ref$omissao_p10_validacao,
      numero_coeficientes_dif=z$numero_coeficientes-ref$numero_coeficientes)
  }
}
comparacoes <- do.call(rbind,comparacoes)
escrever_csv(comparacoes,file.path(saida,'22_COMPARACOES_PAREADAS_VS_C0.csv'))

resumos <- list(); nr <- 0L
for(sp in especies) for(k in names(conjuntos)) {
  z <- metricas[metricas$especie==sp & metricas$conjunto==k,,drop=FALSE]
  if(nrow(z)!=3L || !setequal(z$fold_cv,1:3))
    stop('Conjunto sem 3 folds: ',sp,' / ',k)
  bo <- z$boyce_b2[is.finite(z$boyce_b2)]
  nr <- nr+1L
  resumos[[nr]] <- data.frame(especie=sp,conjunto=k,
    n_folds=3L,auc_b2_media=mean(z$auc_validacao_b2),
    auc_b2_min=min(z$auc_validacao_b2),auc_b2_dp=sd(z$auc_validacao_b2),
    auc_b0_fixo_media=mean(z$auc_validacao_b0_fixo),
    auc_intra_prop_media=mean(z$auc_intra_prop_ponderada,na.rm=TRUE),
    omissao_p10_media=mean(z$omissao_p10_validacao),
    omissao_p10_max=max(z$omissao_p10_validacao),
    n_folds_omissao_100=sum(z$omissao_p10_validacao>=1-1e-12),
    boyce_b2_media=if(length(bo))mean(bo)else NA_real_,
    boyce_b2_min=if(length(bo))min(bo)else NA_real_,
    n_boyce_validos=length(bo),
    coeficientes_media=mean(z$numero_coeficientes),
    stringsAsFactors=FALSE)
}
resumo <- do.call(rbind,resumos)
escrever_csv(resumo,file.path(saida,'22_RESUMO_12_CONJUNTOS.csv'))

# ---------------------------------------------------------------------------
# G) Graficos por especie: cada linha e um conjunto, cada ponto um fold.
# ---------------------------------------------------------------------------
cores <- c('black','#377eb8','#4daf4a','#984ea3','#ff7f00','#a65628')
nomes_curto <- c('C0 Completo','C1 Sem BIO12','C2 Sem BIO17',
                 'C3 Sem BIO12+BIO17','C4 Sem altitude','C5 Sem textura')
for(sp in especies) for(metric in c('auc_validacao_b2',
           'auc_intra_prop_ponderada','omissao_p10_validacao','boyce_b2')) {
  code <- if(sp=='Ipe-roxo') 'ROXO' else 'AMARELO'
  graf <- file.path(graf_dir,paste0('22_',code,'_',toupper(metric),'_FOLDS.png'))
  png(graf,width=1350,height=800,res=140)
  op <- par(mar=c(5,6,5,2),oma=c(0,0,0,2))
  ylim <- if(metric=='boyce_b2')c(-1,1) else c(0,1)
  plot(1:3,rep(NA_real_,3),xlim=c(.9,3.1),ylim=ylim,xaxt='n',
    xlab='Fold espacial retido',
    ylab=metric,
    main=paste('R22 -',sp,'|',metric))
  axis(1,at=1:3,labels=paste('Fold',1:3))
  if(grepl('auc',metric))abline(h=.5,col='gray65',lty=3)
  if(metric=='boyce_b2') abline(h=0,col='gray65',lty=3)
  for(j in seq_along(conjuntos)) {
    z <- metricas[metricas$especie==sp &
                 metricas$conjunto==names(conjuntos)[j],,drop=FALSE]
    z <- z[order(z$fold_cv),,drop=FALSE]
    lines(z$fold_cv,z[[metric]],type='b',lwd=if(j==1)3 else 1.8,
          pch=14+j,col=cores[j])
  }
  legend('topright',legend=nomes_curto,col=cores,lty=1,
         lwd=c(3,rep(1.8,5)),pch=15:20,cex=.83,bty='n',
         bg='white')
  par(op); dev.off()
}

texto <- c(
 paste('TCC IPES -',versao_r22),
 paste('Codigo:',versao_codigo),
 'V1.1: aviso/auditoria para classes de solo apenas na validacao;',
 'niveis globais preservados, sem recodificacao e sem excluir registros.',
 paste('Data:',as.character(Sys.time())),
 'Experimento: 6 conjuntos x 2 especies x 3 folds = 36 avaliacoes.',
 '6 modelos completos C0 REUTILIZADOS do R19, com preflight de RDS/P10/AUC.',
 '30 ajustes novos C1-C5 executados para ablação controlada.',
 'Features LQH; RM=4; maxnet; addsamplestobackground=TRUE.',
 'Solo: fator global com categorias 2, 3, 4, 6, 7 (exceto C5).',
 'Previsao cloglog com clamp=TRUE; P10 do TREINO aplicado na validacao.',
 'Mesmo B2 10000, mesmas presencas e mesmos folds de R19.',
 'AUC/ Boyce contra BG B2; tambem AUC/Boyce com BG B0 FIXO.',
 'AUC local so quando >=10 presencas e >=10 BG na propriedade.',
 'AUC intra-propriedade ponderada por numero de pares presentes-background.',
 'AUC e Boyce NAO sao validacao contra ausencias verdadeiras.',
 'Interpretar efeito geográfico entre propriedades e novidade ambiental.',
 'Omissao de 100% nao deve ser escondida por medias.',
 'Nenhum conjunto escolhido automaticamente como modelo final.',
 'Sete propriedades externas permanecem intocadas; apenas desenvolvimento.',
 'Entradas e referencias R19 rastreadas por MD5.',
 'Checkpoints preservam progresso em caso de reinicio.',
 'AUC de sensibilidade (excluindo apenas da metrica BG com solo inedito)',
 'registrada em 22_SENSIBILIDADE_SOLO_NOVO_V1_1.csv.',
 'Comparacoes C1-C5 versus C0 sao do MESMO fold, com B2/B0 identicos.',
 'Resultados sao de sensibilidade a preditores, nao prova de causalidade.',
 paste('Saida:',saida),
 paste('R:',R.version.string),
 paste('maxnet:',as.character(utils::packageVersion('maxnet'))),
 paste('ecospat:',as.character(utils::packageVersion('ecospat')))
)
writeLines(texto,file.path(saida,'22_RELATORIO_EXPERIMENTO.txt'),useBytes=TRUE)
writeLines(capture.output(sessionInfo()),
           file.path(saida,'22_SESSION_INFO.txt'),useBytes=TRUE)
cat('\nR22 CONCLUIDO: 36 avaliacoes (6 modelos reutilizados + 30 ajustes novos).\n')
cat('Resultados:',saida,'\n')
cat('Auditoria de solo V1.1 e analise de sensibilidade gravadas.\n')
cat('Envie 22_METRICAS_36_AVALIACOES.csv, 22_RESUMO_12_CONJUNTOS.csv,\n',
    '22_COMPARACOES_PAREADAS_VS_C0.csv e os graficos para auditoria.\n')
