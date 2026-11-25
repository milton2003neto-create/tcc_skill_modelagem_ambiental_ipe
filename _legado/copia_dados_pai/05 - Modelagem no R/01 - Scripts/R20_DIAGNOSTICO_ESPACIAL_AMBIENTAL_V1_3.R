# ============================================================================
# TCC IPES | R20 V1.3 - DIAGNOSTICO ESPACIAL E AMBIENTAL DO MAXENT M1 / B2
# ============================================================================
# OBJETIVO: investigar os folds criticos (ipe-roxo F3; ipe-amarelo F2)
# sem alterar os 72 modelos do R19, os backgrounds ou os folds.
#
# SAIDAS:
#  20_VERIFICACAO_72_PREVISOES.csv
#  20_AUC_POR_PROPRIEDADE.csv; 20_RESUMO_AUC_GLOBAL_LOCAL.csv
#  20_ESFORCO_POR_UPA.csv
#  20_NOVIDADE_UNIVARIADA.csv; 20_NOVIDADE_SOLO.csv
#  20_NOVIDADE_MULTIVARIADA_NN.csv; 20_NN_POR_PROPRIEDADE.csv
#  20_LIMIARES_CRITICOS.csv; 20_RELATORIO_DIAGNOSTICO.txt
#  20_GRAFICOS/*.png; 20_MANIFESTO_FONTES.csv
#
# NOTAS:
# - Nenhum ajuste maxnet novo e realizado. Modelos RDS sao LIDOS apenas para
#   reconstruir scores de treinamento nos seis ajustes criticos.
# - AUC = discriminacao de presencas contra background, nao ausencias reais.
# - A novidade multivariada usa distancia euclidiana padronizada ao vizinho
#   mais proximo em um SUBCONJUNTO de background de treino. NAO e MOP/MESS.
# - Nao acessar TESTE_CEGO nem as sete propriedades externas reservadas.
# - Apenas R base e pacote maxnet (ja utilizado no R19).
#
# INICIO: abra no RStudio e execute o script inteiro. Quando solicitado,
# selecione 19_METRICAS_72_MODELOS_B2.csv DENTRO da pasta original R19.
# ============================================================================

versao <- 'R20_V1_3_20261117'
if (!requireNamespace('maxnet', quietly=TRUE))
  stop('Pacote maxnet nao instalado. O R19 utiliza esse pacote.')

cat('\nR20: selecione 19_METRICAS_72_MODELOS_B2.csv na pasta R19.\n')
arq19 <- normalizePath(file.choose(), winslash='/', mustWork=TRUE)
if (basename(arq19) != '19_METRICAS_72_MODELOS_B2.csv')
  stop('Escolha o CSV de metricas finais do R19: 19_METRICAS_72_MODELOS_B2.csv.')
pasta19 <- dirname(arq19)
# Aceita tanto pasta R19 direta como subpasta 'Execucao_*', se houver.
pasta_resultados <- pasta19
while (basename(pasta_resultados) != '06 - Resultados' &&
       dirname(pasta_resultados) != pasta_resultados)
  pasta_resultados <- dirname(pasta_resultados)
if (basename(pasta_resultados) != '06 - Resultados')
  stop('O CSV do R19 precisa estar dentro da pasta 06 - Resultados.')
raiz <- dirname(pasta_resultados)

ler <- function(f) utils::read.csv(f, fileEncoding='UTF-8-BOM',
                                  stringsAsFactors=FALSE, check.names=FALSE)
colunas <- function(d, nomes, rotulo) {
  f <- setdiff(nomes, names(d))
  if (length(f)) stop(rotulo, ': faltam colunas: ', paste(f,collapse=', '))
}
media <- function(x) if (all(is.na(x))) NA_real_ else mean(x,na.rm=TRUE)
auc <- function(p,b) {
  if (!length(p) || !length(b) || any(!is.finite(c(p,b)))) return(NA_real_)
  n <- length(p)
  (sum(rank(c(p,b),ties.method='average')[seq_len(n)])-n*(n+1)/2)/
    (n*length(b))
}
q <- function(x, p) as.numeric(stats::quantile(x,p,na.rm=TRUE,type=7))
checar_valores <- function(x, nomes, rotulo) {
  if (anyNA(x[,nomes,drop=FALSE]) ||
      any(!is.finite(as.matrix(x[,nomes,drop=FALSE]))))
    stop('Variaveis ausentes ou invalidas em ',rotulo)
}
# Usa somente caminhos registrados no manifesto R19; permite mover a raiz do TCC.
manifesto19_arq <- file.path(pasta19,'19_MANIFESTO_ENTRADAS.csv')
locais19_arq <- file.path(pasta19,'19_AUC_OMISSAO_POR_PROPRIEDADE.csv')
comparacao19_arq <- file.path(pasta19,'19_COMPARACAO_72_B0_B1_B2.csv')
if (!all(file.exists(c(manifesto19_arq,locais19_arq,comparacao19_arq))))
  stop('Faltam 19_MANIFESTO_ENTRADAS.csv, 19_AUC_OMISSAO_POR_PROPRIEDADE.csv ou 19_COMPARACAO_72_B0_B1_B2.csv na pasta R19.')
manifesto <- ler(manifesto19_arq)
colunas(manifesto,c('arquivo','caminho','md5'),'manifesto R19')
localizar_manifestado <- function(nome) {
  r <- manifesto[manifesto$arquivo==nome,,drop=FALSE]
  if (nrow(r)!=1L) stop('Arquivo nao tem entrada unica no manifesto R19: ',nome)
  original <- gsub('\\\\','/',as.character(r$caminho[1]))
  possiveis <- original
  for (pasta in c('04 - Dados para o MaxEnt/','06 - Resultados/')) {
    i <- regexpr(pasta,original,fixed=TRUE)[1]
    if (i>0L) possiveis <- c(possiveis,file.path(raiz,substring(original,i)))
  }
  possiveis <- unique(possiveis)
  existentes <- possiveis[file.exists(possiveis)]
  if (!length(existentes)) stop('Arquivo de entrada nao localizado: ',nome,
    '\nRestaure-o na pasta relativa a raiz do TCC registrada no R19.')
  f <- existentes[1]
  atual <- unname(tools::md5sum(f))
  if (!identical(tolower(atual),tolower(as.character(r$md5[1]))))
    stop('MD5 DIFERENTE do R19. Entrada modificada: ',nome,'\n',f)
  f
}

pres_arq <- localizar_manifestado('05_PRESENCAS_UM_POR_PIXEL_30M.csv')
b0_arq <- localizar_manifestado('05_BACKGROUND_COM_FOLDS.csv')
b2_arq <- localizar_manifestado('18_BACKGROUND_B2_10000_COM_FOLDS.csv')
pres <- ler(pres_arq)
b0 <- ler(b0_arq)
b2 <- ler(b2_arq)
m <- ler(arq19)
locais19 <- ler(locais19_arq)
comp <- ler(comparacao19_arq)
cont <- c('altitude_m','declividade_graus','dist_rio_raster_m',
          'bio12_mm_ano','bio17_mm_mes')
vars <- c(cont,'textura_subgrupo')
colunas(pres,c('especie','propriedade','upa_id','fold_cv',vars),'presencas R05')
colunas(b2,c('propriedade','upa_id','fold_cv',vars),'background B2')
colunas(b0,c('propriedade','upa_id','fold_cv',vars),'background B0')
colunas(m,c('id','especie','fold_cv','features','RM',
  'n_presenca_treino','n_background_treino','n_presenca_validacao',
  'n_background_validacao','auc_validacao','auc_validacao_bg_b0_fixo',
  'omissao10_validacao','limiar10_treino_cloglog','boyce_validacao'), 'metricas R19')
colunas(locais19,c('id','especie','fold_cv','features','RM','propriedade',
 'n_presencas','n_bg_b2','auc_bg_b2','auc_bg_b0_fixo','omissao10'),'AUC R19 local')
colunas(comp,c('id_b2','especie','fold_cv','features','RM','auc_b2_bg_b0_fixo'),
        'comparacao R19')

if (nrow(m)!=72L || nrow(comp)!=72L || nrow(pres)!=8680L ||
    nrow(b0)!=5000L || nrow(b2)!=10000L || nrow(locais19)<100L ||
    anyDuplicated(m$id) || anyDuplicated(comp$id_b2) ||
    !setequal(m$id,comp$id_b2) ||
    sum(pres$especie=='Ipe-roxo')!=3248L ||
    sum(pres$especie=='Ipe-amarelo')!=5432L ||
    !setequal(unique(m$especie),c('Ipe-roxo','Ipe-amarelo')) ||
    !setequal(unique(m$fold_cv),1:3) ||
    !setequal(unique(m$features),c('l','lq','lqh')) ||
    !setequal(unique(m$RM),1:4) ||
    !setequal(unique(b2$fold_cv),1:3) ||
    length(unique(b2$propriedade))!=27L ||
    nrow(unique(b2[,c('propriedade','upa_id')]))!=64L)
  stop('Contagens/grade do R19 e entradas B0/B2 nao conferem com protocolo auditado.')
if (anyNA(pres[,c('especie','propriedade','upa_id','fold_cv',vars),drop=FALSE]) ||
    anyNA(b2[,c('propriedade','upa_id','fold_cv',vars),drop=FALSE]))
  stop('Presencas ou background B2 apresentam campos obrigatorios vazios.')
checar_valores(pres,cont,'presencas R05')
checar_valores(b2,cont,'background B2')
if (!setequal(unique(pres$propriedade),unique(b2$propriedade)))
  stop('Conjunto de propriedades difere entre R05 e B2.')

# Protecao contra vazamento espacial: so os 27 empreendimentos de desenvolvimento.
sem_acentos <- function(x) toupper(iconv(as.character(x),from='',to='ASCII//TRANSLIT'))
externas <- c('BARRO BRANCO','CURUCA','GUARIUBA','JATOBA',
              'LOTE 01','MARILIA','PALMEIRA')
if (any(sem_acentos(c(pres$propriedade,b0$propriedade,b2$propriedade)) %in% externas))
  stop('VAZAMENTO DO TESTE EXTERNO: entradas incluem propriedade reservada.')
fo <- unique(rbind(pres[,c('propriedade','fold_cv')],
                   b2[,c('propriedade','fold_cv')],
                   b0[,c('propriedade','fold_cv')]))
if (any(vapply(split(fo$fold_cv,fo$propriedade),
               function(z) length(unique(z))!=1L,logical(1))))
  stop('Uma mesma propriedade foi atribuida a mais de um fold.')
if ('id_background' %in% names(b2) && anyDuplicated(b2$id_background))
  stop('IDs duplicados no background B2.')
if ('celula_raster' %in% names(b2) &&
    anyDuplicated(paste(b2$propriedade,b2$celula_raster,sep='|')))
  stop('Pontos B2 duplicados no mesmo pixel/propriedade.')

# Localiza os 72 CSVs e seis objetos RDS originais, sem escrever nessas pastas.
todos_csv19 <- list.files(pasta19,pattern='\\.csv$',recursive=TRUE,full.names=TRUE)
pred_necessarias <- paste0(m$id,'.csv')
previsoes <- todos_csv19[basename(todos_csv19) %in% pred_necessarias]
if (length(previsoes)!=72L || anyDuplicated(basename(previsoes)) ||
    !setequal(basename(previsoes),pred_necessarias))
  stop('Nao localizei exatamente os 72 arquivos de previsoes individuais no R19.\n',
       'Mantenha a pasta de previsoes original junto com as metricas R19.')
names(previsoes) <- sub('\\.csv$','',basename(previsoes))
todos_rds19 <- list.files(pasta19,pattern='\\.rds$',recursive=TRUE,full.names=TRUE)

# ---------------------------------------------------------------------------
# R19 registra escores adicionais contra B0/B1 para comparacao controlada.
# Os CSVs de predicao podem, portanto, conter MAIS de dois tipos de registro.
# Aqui identificamos a amostra B2 da validacao sem descartar informacao,
# exigindo concordancia com AUC GLOBAL, CONTAGENS e CONTAGENS POR PROPRIEDADE
# publicadas no R19. Nao assumimos que toda linha e valida para o B2.
# ---------------------------------------------------------------------------
identificar_previsoes_b2 <- function(tabela, metrica, locais) {
  id <- as.character(metrica$id[1])
  obrigatorias <- c('id','especie','fold_cv','features','RM',
                    'tipo','propriedade','score_cloglog')
  colunas(tabela,obrigatorias,paste('previsoes',id))
  # Ausencia de score em um conjunto comparativo extra nao invalida B2;
  # checamos score finito nas PRESENCAS e no B2 selecionado abaixo.
  if (anyNA(tabela[,setdiff(obrigatorias,'score_cloglog'),drop=FALSE]))
    stop('Identificadores ou tipos com NA nas previsoes de ',id,
         '. Examine o CSV individual do R19.')
  tipos <- unique(as.character(tabela$tipo))
  tipo_pres <- 'PRESENCA_VALIDACAO'
  if (!(tipo_pres %in% tipos))
    stop('Tipo de presenca nao encontrado em ',id,
         '. Tipos presentes: ',paste(tipos,collapse=' | '))
  pr <- tabela[tabela$tipo==tipo_pres,,drop=FALSE]
  if (nrow(pr)!=metrica$n_presenca_validacao)
    stop('Quantidade de presencas incorreta em ',id,': ',nrow(pr),
         '; esperado: ',metrica$n_presenca_validacao)
  if (any(!is.finite(pr$score_cloglog)))
    stop('Scores de presencas invalidos em ',id)
  # Uma tabela com B0, B1 e B2 nao deve ser rejeitada por ter linhas extras.
  tipos_bg <- setdiff(tipos,tipo_pres)
  candidatos <- list()
  for (tipo in tipos_bg) {
    bg <- tabela[tabela$tipo==tipo,,drop=FALSE]
    if (nrow(bg)!=metrica$n_background_validacao ||
        any(!is.finite(bg$score_cloglog))) next
    a <- auc(pr$score_cloglog,bg$score_cloglog)
    if (!is.finite(a) || abs(a-metrica$auc_validacao)>1e-8) next
    # Auditoria independente de distribuicao por propriedade: B1 pode
    # coincidir com B2 em tamanho, mas nao em cotas ou AUC local.
    l <- locais[locais$id==id,,drop=FALSE]
    if (!nrow(l)) stop('Sem AUC local R19 para ',id)
    nbg <- vapply(l$propriedade,function(x) sum(bg$propriedade==x),integer(1))
    if (any(nbg!=l$n_bg_b2)) next
    auc_locais <- vapply(seq_len(nrow(l)),function(j) {
      p <- pr$score_cloglog[pr$propriedade==l$propriedade[j]]
      b <- bg$score_cloglog[bg$propriedade==l$propriedade[j]]
      auc(p,b)
    },numeric(1))
    if (any(!is.finite(auc_locais)) ||
        any(abs(auc_locais-l$auc_bg_b2)>1e-8)) next
    candidatos[[tipo]] <- bg
  }
  if (length(candidatos)!=1L) {
    # Mostra os detalhes observados SEM forcar uma escolha por suposicao.
    resumo <- vapply(tipos,function(t) {
      g <- tabela[tabela$tipo==t,,drop=FALSE]
      paste0(t,'=',nrow(g),' linhas')
    },character(1))
    stop('Nao foi possivel identificar UNICAMENTE o background B2 de ',id,
         '\nTipos encontrados: ',paste(resumo,collapse=' | '),
         '\nCandidatos que reproduzem AUC e propriedades R19: ',
         paste(names(candidatos),collapse=', '),
         '\nConfira os tipos e as metricas do CSV individual; nao altere os dados.')
  }
  tipo_b2 <- names(candidatos)[1]
  bg <- candidatos[[1]]
  selecionado <- rbind(pr,bg)
  rownames(selecionado) <- NULL
  selecionado$tipo[selecionado$tipo==tipo_b2] <- 'BACKGROUND_VALIDACAO'
  list(dados=selecionado,tipo_b2_original=tipo_b2,
       total_linhas_originais=nrow(tabela),tipos_originais=tipos)
}

# ---------------------------------------------------------------------------
# 1. Auditoria independente das 72 previsoes de validacao.
# ---------------------------------------------------------------------------
verificacoes <- vector('list',nrow(m))
locais_calculados <- list()
nloc <- 0L
criticos <- data.frame(especie=c(rep('Ipe-roxo',3),rep('Ipe-amarelo',3)),
                       fold_cv=c(3,3,3,2,2,2),
                       features=c('lq','l','lqh','lq','lqh','lqh'),
                       RM=c(2,4,4,2,2,4),stringsAsFactors=FALSE)
previsoes_criticas <- list()
for (i in seq_len(nrow(m))) {
  z <- m[i,,drop=FALSE]
  origem <- identificar_previsoes_b2(ler(previsoes[[z$id]]),z,locais19)
  pp <- origem$dados
  if (i==1L) cat('R20 V1.3: tipos originais na primeira previsao: ',
                 paste(origem$tipos_originais,collapse=' | '),
                 '\nBackground B2 identificado como: ',origem$tipo_b2_original,'\n',sep='')
  # Erros individualizados: nao esconder qual condicao falhou.
  problemas <- character()
  verificar <- function(teste,rotulo) {
    if (!isTRUE(teste)) problemas <<- c(problemas,rotulo)
  }
  verificar(nrow(pp)==z$n_presenca_validacao+z$n_background_validacao,
            'numero de linhas diferente do esperado para presencas + B2')
  verificar(!anyNA(pp[,c('id','especie','fold_cv','features','RM',
                        'tipo','propriedade','score_cloglog'),drop=FALSE]),
            'campo obrigatorio vazio')
  verificar(all(pp$id==z$id),'ID de modelo nao coincide')
  verificar(all(pp$especie==z$especie),'especie nao coincide')
  verificar(all(pp$fold_cv==z$fold_cv),'fold nao coincide')
  verificar(all(pp$features==z$features),'features nao coincidem')
  verificar(all(pp$RM==z$RM),'RM nao coincide')
  verificar(setequal(unique(pp$tipo),c('PRESENCA_VALIDACAO',
                                      'BACKGROUND_VALIDACAO')),
            'tipos de linha diferentes dos esperados apos selecao')
  verificar(all(is.finite(pp$score_cloglog)),'score nao finito')
  verificar(all(pp$score_cloglog>=0 & pp$score_cloglog<=1),
            'score fora de [0,1]')
  verificar(all(pp$propriedade %in% fo$propriedade[fo$fold_cv==z$fold_cv]),
            'propriedade nao pertence ao fold de validacao')
  if (length(problemas))
    stop('Previsoes invalidas para: ',z$id,'\nCausas: ',
         paste(problemas,collapse='; '))
  p <- pp$score_cloglog[pp$tipo=='PRESENCA_VALIDACAO']
  b <- pp$score_cloglog[pp$tipo=='BACKGROUND_VALIDACAO']
  if (length(p)!=z$n_presenca_validacao || length(b)!=z$n_background_validacao ||
      length(p)!=sum(pres$especie==z$especie & pres$fold_cv==z$fold_cv) ||
      length(b)!=sum(b2$fold_cv==z$fold_cv))
    stop('Contagens de presencas/background divergem: ',z$id)
  lim <- as.numeric(z$limiar10_treino_cloglog)
  auc_calc <- auc(p,b)
  om_calc <- mean(p<lim)
  if (!is.finite(lim) || abs(auc_calc-z$auc_validacao)>1e-8 ||
      abs(om_calc-z$omissao10_validacao)>1e-8)
    stop('AUC ou omissao nao reproduzida: ',z$id)
  verificacoes[[i]] <- data.frame(id=z$id,especie=z$especie,fold_cv=z$fold_cv,
    features=z$features,RM=z$RM,
    tipo_background_b2_original=origem$tipo_b2_original,
    linhas_csv_original=origem$total_linhas_originais,
    n_presencas=length(p),n_background=length(b),
    auc_recalculada=auc_calc,boyce_importado=z$boyce_validacao,
    omissao_recalculada=om_calc,limiar10_treino=lim,
    score_min_presenca=min(p),score_max_presenca=max(p),
    score_mediana_presenca=median(p),score_mediana_bg=median(b),
    score_p10_presenca=q(p,.10),score_p90_presenca=q(p,.90),
    diferenca_max_presenca_menos_limiar=max(p)-lim,
    todas_presencas_abaixo_limiar=(max(p)<lim),stringsAsFactors=FALSE)
  for (pr in unique(pp$propriedade)) {
    pro <- pp[pp$propriedade==pr,,drop=FALSE]
    ap <- pro$score_cloglog[pro$tipo=='PRESENCA_VALIDACAO']
    ab <- pro$score_cloglog[pro$tipo=='BACKGROUND_VALIDACAO']
    # Igual ao criterio de QA local do protocolo: evitar AUC instavel
    # quando uma das amostras tem menos de 10 registros.
    if (min(length(ap),length(ab))<10L) next
    nloc <- nloc+1L
    locais_calculados[[nloc]] <- data.frame(id=z$id,especie=z$especie,
      fold_cv=z$fold_cv,features=z$features,RM=z$RM,
      propriedade=pr,n_presencas=length(ap),n_bg_b2=length(ab),
      auc_bg_b2=auc(ap,ab),omissao10=mean(ap<lim),
      score_mediano_presenca=median(ap),score_mediano_bg=median(ab),
      stringsAsFactors=FALSE)
  }
  ch <- criticos[criticos$especie==z$especie &
                 criticos$fold_cv==z$fold_cv &
                 criticos$features==z$features & criticos$RM==z$RM,,drop=FALSE]
  if (nrow(ch)) previsoes_criticas[[z$id]] <- list(p=p,b=b,limiar=lim,z=z)
  if (i%%12L==0L) cat('Conferidas previsoes:',i,'/72\n')
}
verific <- do.call(rbind,verificacoes)
local <- do.call(rbind,locais_calculados)
# Checa numeros locais da tabela original, em vez de assumir alinhamento por linha.
chave <- function(x) paste(x$id,x$propriedade,sep='||')
if (anyDuplicated(chave(local)) || anyDuplicated(chave(locais19)) ||
    !setequal(chave(local),chave(locais19)))
  stop('AUCs locais com >=10 presencas/background nao correspondem a tabela R19.')
idx <- match(chave(local),chave(locais19))
if (any(local$n_presencas!=locais19$n_presencas[idx]) ||
    any(local$n_bg_b2!=locais19$n_bg_b2[idx]) ||
    any(abs(local$auc_bg_b2-locais19$auc_bg_b2[idx])>1e-8) ||
    any(abs(local$omissao10-locais19$omissao10[idx])>1e-8))
  stop('AUC local, omissao ou contagem discordantes da tabela R19.')

# ---------------------------------------------------------------------------
# 2. AUC global versus AUC local: NAO sao medias diretamente equivalentes.
# ---------------------------------------------------------------------------
resumo_auc <- list()
for (sp in c('Ipe-roxo','Ipe-amarelo')) for (f in 1:3) {
  z <- m[m$especie==sp & m$fold_cv==f,,drop=FALSE]
  l <- local[local$especie==sp & local$fold_cv==f,,drop=FALSE]
  resumo_auc[[length(resumo_auc)+1L]] <- data.frame(
    especie=sp,fold_cv=f,n_modelos=nrow(z),
    auc_global_b2_media=mean(z$auc_validacao),
    auc_global_bg_b0_fixo_media=mean(z$auc_validacao_bg_b0_fixo),
    auc_local_b2_media_nao_ponderada=mean(l$auc_bg_b2),
    prop_aucs_locais_abaixo_05=mean(l$auc_bg_b2<.5),
    n_propriedades=length(unique(l$propriedade)),stringsAsFactors=FALSE)
}
resumo_auc <- do.call(rbind,resumo_auc)

# ---------------------------------------------------------------------------
# 3. Esforco por propriedade x UPA: a unidade e propriedade + upa_id.
# ---------------------------------------------------------------------------
upa_folds <- unique(b2[,c('propriedade','upa_id','fold_cv')])
upa_folds <- upa_folds[order(upa_folds$propriedade,upa_folds$upa_id),,drop=FALSE]
upa_res <- list()
for (i in seq_len(nrow(upa_folds))) {
  z <- upa_folds[i,,drop=FALSE]
  bg <- b2[b2$propriedade==z$propriedade & b2$upa_id==z$upa_id,,drop=FALSE]
  pr <- pres[pres$propriedade==z$propriedade & pres$upa_id==z$upa_id,,drop=FALSE]
  upa_res[[i]] <- data.frame(propriedade=z$propriedade,upa_id=z$upa_id,
    fold_cv=z$fold_cv,n_background_b2=nrow(bg),
    n_roxo=sum(pr$especie=='Ipe-roxo'),
    n_amarelo=sum(pr$especie=='Ipe-amarelo'),
    n_presencas_total=nrow(pr),stringsAsFactors=FALSE)
}
upa_res <- do.call(rbind,upa_res)

# ---------------------------------------------------------------------------
# 3b. Identificar os seis RDS da rodada B2 com verificacao de identidade.
# A busca recursiva pode encontrar copias do mesmo nome em subpastas R19.
# Copias identicas (MD5 igual) podem ser usadas sem ambiguidade.
# Se os MD5 diferirem, conferir a identidade contra a metrica do proprio R19
# (P10 das presencas de treino + numero de coeficientes ativos).
# Se varios candidatos diferentes passarem, comparar os scores de treino.
# O R20 NUNCA escolhe arbitrariamente um modelo divergente.
# ---------------------------------------------------------------------------
solo_niveis <- as.character(sort(unique(as.integer(c(pres$textura_subgrupo,
                                                    b2$textura_subgrupo)))))
montar_x <- function(d) {
  x <- d[,vars,drop=FALSE]
  for (v in cont) x[[v]] <- as.numeric(x[[v]])
  x$textura_subgrupo <- factor(as.character(x$textura_subgrupo),levels=solo_niveis)
  if (anyNA(x)) stop('Falha ao reconstruir o fator de solo.')
  x
}
ids_rds_criticos <- vapply(seq_len(nrow(criticos)), function(i) {
  z <- m[m$especie == criticos$especie[i] &
         m$fold_cv == criticos$fold_cv[i] &
         m$features == criticos$features[i] &
         m$RM == criticos$RM[i], , drop=FALSE]
  if (nrow(z)!=1L)
    stop('Modelo critico nao identificado de forma unica nas metricas: linha ',i)
  as.character(z$id)
}, character(1))
if (anyDuplicated(ids_rds_criticos))
  stop('Modelos criticos repetidos no plano de diagnostico R20.')

rds_registros <- list()
rds_registro_n <- 0L
selecionar_rds_verificado <- function(id) {
  candidatos <- sort(unique(todos_rds19[basename(todos_rds19)==paste0(id,'.rds')]))
  if (!length(candidatos))
    stop('Nenhum RDS encontrado para ',id,' na pasta do R19.')
  md5 <- unname(tools::md5sum(candidatos))
  z <- m[m$id==id,,drop=FALSE]
  if (nrow(z)!=1L) stop('Metrica R19 ambigua para ',id)
  cat('RDS ',id,': ',length(candidatos),' arquivo(s)',
      if(length(candidatos)>1L)' (copias detectadas)' else '', '\n',sep='')
  if (length(candidatos)>1L)
    for (k in seq_along(candidatos))
      cat('  [',k,'] ',candidatos[k],' | MD5=',md5[k],'\n',sep='')

  # Lista gerada para rastreabilidade mesmo se forem copias identicas.
  motivo <- rep('NAO_SELECIONADO',length(candidatos))
  p10 <- rep(NA_real_,length(candidatos))
  coef <- rep(NA_integer_,length(candidatos))
  escolhido <- NA_integer_
  decisao <- ''

  if (length(unique(md5))==1L) {
    # Identidade byte a byte: um so modelo, possivelmente copiado varias vezes.
    escolhido <- 1L
    decisao <- if (length(candidatos)>1L)'COPIAS_MD5_IDENTICAS' else 'UNICO_RDS'
  } else {
    # MD5 diferentes: checar qual candidato reproduz o modelo B2 registrado.
    tp <- pres[pres$especie==z$especie & pres$fold_cv!=z$fold_cv,,drop=FALSE]
    if(nrow(tp)!=z$n_presenca_treino)
      stop('Quantidade de treino incorreta antes de conferir RDS: ',id)
    x_tp <- montar_x(tp)
    scores_validos <- vector('list',length(candidatos))
    ok <- rep(FALSE,length(candidatos))
    for (k in seq_along(candidatos)) {
      mod <- tryCatch(readRDS(candidatos[k]),error=function(e)NULL)
      if (is.null(mod) || !inherits(mod,'maxnet')) {
        motivo[k] <- 'ARQUIVO_INVALIDO_OU_NAO_MAXNET'
        next
      }
      coef[k] <- length(mod$betas)
      if (coef[k]!=z$n_features_ativas) {
        motivo[k] <- 'NUMERO_COEFICIENTES_DIVERGENTE'
        next
      }
      score <- tryCatch(as.numeric(stats::predict(mod,x_tp,
                           type='cloglog',clamp=TRUE)),error=function(e)NULL)
      if (is.null(score) || length(score)!=nrow(tp) ||
          any(!is.finite(score))) {
        motivo[k] <- 'FALHA_PREDICAO_TREINO'
        next
      }
      p10[k] <- q(score,.10)
      if (!is.finite(p10[k]) ||
          abs(p10[k]-z$limiar10_treino_cloglog)>1e-6) {
        motivo[k] <- 'LIMIAR_TREINO_NAO_REPRODUZIDO'
        next
      }
      ok[k] <- TRUE
      scores_validos[[k]] <- score
      motivo[k] <- 'CONFERE_P10_COEFICIENTES'
    }
    if (sum(ok)==1L) {
      escolhido <- which(ok)
      decisao <- 'UNICO_RDS_VALIDADO_POR_P10_E_COEFICIENTES'
    } else if (sum(ok)>1L) {
      # Nao basta ambos terem o mesmo P10: comparar os scores completos.
      ks <- which(ok)
      referencia <- scores_validos[[ks[1]]]
      equiv <- vapply(ks, function(k)
        length(scores_validos[[k]])==length(referencia) &&
        max(abs(scores_validos[[k]]-referencia))<=1e-9,logical(1))
      if (all(equiv)) {
        escolhido <- ks[1]
        decisao <- 'RDS_DISTINTOS_MESMOS_SCORES_TREINO'
      }
    }
    if (is.na(escolhido)) {
      detalhes <- paste(sprintf('%s | md5=%s | p10=%s | coef=%s | %s',
        candidatos, md5,
        ifelse(is.finite(p10),format(p10,digits=12),'NA'),
        ifelse(is.na(coef),'NA',as.character(coef)),motivo),collapse='\n')
      stop('Modelos RDS nao desambiguados para ',id,
           '. Nao e seguro escolher um automaticamente.\n',detalhes,
           '\nEnvie estes caminhos e o script original do R19 para auditoria.')
    }
  }
  motivo[escolhido] <- paste0('ESCOLHIDO_',decisao)
  for (k in seq_along(candidatos)) {
    rds_registro_n <<- rds_registro_n + 1L
    rds_registros[[rds_registro_n]] <<- data.frame(
      id=id,caminho_rds=candidatos[k],md5=md5[k],
      p10_recalculado=p10[k],coeficientes_ativos=coef[k],
      status=motivo[k],selecionado=k==escolhido,
      stringsAsFactors=FALSE)
  }
  cat('  Escolhido: ',candidatos[escolhido],
      ' | motivo: ',decisao,'\n',sep='')
  candidatos[escolhido]
}
modelos_rds_criticos <- setNames(vapply(ids_rds_criticos,
                selecionar_rds_verificado,character(1)), ids_rds_criticos)
registro_rds <- do.call(rbind,rds_registros)
if (length(modelos_rds_criticos)!=6L ||
    length(unique(modelos_rds_criticos))!=6L ||
    sum(registro_rds$selecionado)!=6L)
  stop('Auditoria dos seis RDS nao foi concluida de forma unica.')
cat('Modelos RDS criticos identificados: ',length(modelos_rds_criticos),
    '/',length(ids_rds_criticos),'\n',sep='')

# ---------------------------------------------------------------------------
# 4. Novidade univariada e classes novas de solo (fundo = B2 de treino).
# ---------------------------------------------------------------------------
nov_uni <- list(); nov_solo <- list(); nn_res <- list(); nn_prop <- list()
nov_unis <- 0L; ns <- 0L; nm <- 0L; np <- 0L
# Distancia padronizada ao vizinho mais proximo, calculada em blocos.
# O conjunto referencia vem EXCLUSIVAMENTE do background dos folds de treino.
nearest <- function(alvo,referencia,bloco=200L) {
  if (!nrow(alvo)) return(numeric())
  if (!nrow(referencia)) stop('Referencia ambiental vazia.')
  ref_norm <- rowSums(referencia^2)
  saida <- numeric(nrow(alvo))
  for (ini in seq.int(1L,nrow(alvo),by=bloco)) {
    ii <- ini:min(ini+bloco-1L,nrow(alvo))
    a <- alvo[ii,,drop=FALSE]
    dist2 <- outer(rowSums(a^2),ref_norm,'+') - 2*tcrossprod(a,referencia)
    saida[ii] <- sqrt(pmax(0,apply(dist2,1L,min)))
  }
  saida
}
for (f in 1:3) {
  bg_treino <- b2[b2$fold_cv!=f,,drop=FALSE]
  bg_valid <- b2[b2$fold_cv==f,,drop=FALSE]
  if (nrow(bg_treino)<3000L || nrow(bg_valid)<500L)
    stop('Background do fold nao corresponde a distribuicao B2 esperada.')
  cat('Diagnostico ambiental do Fold',f,'\n')
  # Fracionamento interno do background de treino: nao utiliza o fold retido.
  set.seed(20261120L + f)
  ids_ref <- sample.int(nrow(bg_treino),size=min(2000L,nrow(bg_treino)-700L))
  restantes <- setdiff(seq_len(nrow(bg_treino)),ids_ref)
  ids_cal <- sample(restantes,size=min(700L,length(restantes)))
  mu <- vapply(bg_treino[,cont,drop=FALSE],mean,numeric(1))
  desvio <- vapply(bg_treino[,cont,drop=FALSE],stats::sd,numeric(1))
  validas <- names(desvio)[is.finite(desvio) & desvio>0]
  if (length(validas)<2L) stop('Menos de 2 variaveis continuas variam no treino.')
  padrao <- function(d) {
    z <- as.matrix(d[,validas,drop=FALSE])
    sweep(sweep(z,2L,mu[validas],'-'),2L,desvio[validas],'/')
  }
  referencia <- padrao(bg_treino[ids_ref,,drop=FALSE])
  nn_cal <- nearest(padrao(bg_treino[ids_cal,,drop=FALSE]),referencia)
  limite_nn <- q(nn_cal,.95)
  nn_bg <- nearest(padrao(bg_valid),referencia)
  cats_treino <- sort(unique(as.character(bg_treino$textura_subgrupo)))
  for (sp in c('Ipe-roxo','Ipe-amarelo')) {
    vp <- pres[pres$especie==sp & pres$fold_cv==f,,drop=FALSE]
    nn_pres <- nearest(padrao(vp),referencia)
    for (v in cont) {
      mi <- min(bg_treino[[v]]); ma <- max(bg_treino[[v]])
      fp <- vp[[v]]<mi | vp[[v]]>ma
      fb <- bg_valid[[v]]<mi | bg_valid[[v]]>ma
      nov_unis <- nov_unis+1L
      nov_uni[[nov_unis]] <- data.frame(especie=sp,fold_cv=f,variavel=v,
        minimo_bg_treino=mi,maximo_bg_treino=ma,
        n_presencas=length(fp),n_presencas_fora=sum(fp),prop_presencas_fora=mean(fp),
        n_background=length(fb),n_background_fora=sum(fb),
        prop_background_fora=mean(fb),stringsAsFactors=FALSE)
    }
    ns <- ns+1L
    nov_solo[[ns]] <- data.frame(especie=sp,fold_cv=f,
      categorias_bg_treino=paste(cats_treino,collapse=';'),
      categorias_presenca=paste(sort(unique(vp$textura_subgrupo)),collapse=';'),
      prop_presencas_solo_ausente_bg_treino=mean(!as.character(vp$textura_subgrupo) %in% cats_treino),
      prop_bg_solo_ausente_bg_treino=mean(!as.character(bg_valid$textura_subgrupo) %in% cats_treino),
      stringsAsFactors=FALSE)
    nm <- nm+1L
    nn_res[[nm]] <- data.frame(especie=sp,fold_cv=f,
      n_referencia=nrow(referencia),n_calibracao=nrow(bg_treino[ids_cal,,drop=FALSE]),
      variaveis_continuas=paste(validas,collapse=';'),
      limiar_p95_interno_treino=limite_nn,
      mediana_nn_calibracao=median(nn_cal),
      mediana_nn_presencas=median(nn_pres),
      mediana_nn_background=median(nn_bg),
      prop_presencas_acima_p95_treino=mean(nn_pres>limite_nn),
      prop_background_acima_p95_treino=mean(nn_bg>limite_nn),
      stringsAsFactors=FALSE)
    for (pr in unique(c(vp$propriedade,bg_valid$propriedade))) {
      ap <- nn_pres[vp$propriedade==pr]
      ab <- nn_bg[bg_valid$propriedade==pr]
      np <- np+1L
      nn_prop[[np]] <- data.frame(especie=sp,fold_cv=f,propriedade=pr,
        n_presencas=length(ap),n_background=length(ab),
        mediana_nn_presenca=if(length(ap)) median(ap) else NA_real_,
        mediana_nn_background=if(length(ab)) median(ab) else NA_real_,
        prop_presencas_acima_p95=if(length(ap)) mean(ap>limite_nn) else NA_real_,
        prop_background_acima_p95=if(length(ab)) mean(ab>limite_nn) else NA_real_,
        stringsAsFactors=FALSE)
    }
  }
}
nov_uni <- do.call(rbind,nov_uni)
nov_solo <- do.call(rbind,nov_solo)
nov_nn <- do.call(rbind,nn_res)
nov_nn_prop <- do.call(rbind,nn_prop)

# ---------------------------------------------------------------------------
# 5. Recupera escores de TREINO nos 6 modelos criticos (sem novo ajuste).
# ---------------------------------------------------------------------------
limiares <- list()
for (id in names(previsoes_criticas)) {
  z <- previsoes_criticas[[id]]$z
  rds <- modelos_rds_criticos[[id]]
  modelo <- readRDS(rds)
  if (!inherits(modelo,'maxnet')) stop('RDS nao contem objeto maxnet: ',id)
  tp <- pres[pres$especie==z$especie & pres$fold_cv!=z$fold_cv,,drop=FALSE]
  if (nrow(tp)!=z$n_presenca_treino)
    stop('Contagem de presencas treino diferente do R19: ',id)
  stp <- tryCatch(as.numeric(stats::predict(modelo,montar_x(tp),
                            type='cloglog',clamp=TRUE)),error=function(e)
                            stop('Falha ao prever treino ',id,': ',conditionMessage(e)))
  limiar_recriado <- q(stp,.10)
  if (length(stp)!=nrow(tp) || any(!is.finite(stp)) ||
      abs(limiar_recriado-z$limiar10_treino_cloglog)>1e-6)
    stop('Limiar de treino nao reproduzido para ',id,
         '. Confira versao do maxnet e niveis de solo antes de interpretar.')
  pp <- previsoes_criticas[[id]]
  limiares[[length(limiares)+1L]] <- data.frame(id=id,
    especie=z$especie,fold_cv=z$fold_cv,features=z$features,RM=z$RM,
    n_presencas_treino=length(stp),n_presencas_validacao=length(pp$p),
    limiar_p10_recriado=limiar_recriado,
    mediana_treino=median(stp),mediana_validacao=median(pp$p),
    max_validacao=max(pp$p),
    distancia_max_validacao_ao_limiar=max(pp$p)-limiar_recriado,
    omissao_validacao=mean(pp$p<limiar_recriado),stringsAsFactors=FALSE)
}
limiares <- do.call(rbind,limiares)

# ---------------------------------------------------------------------------
# 6. Criar UMA NOVA pasta de resultados. Nenhum arquivo anterior sobrescrito.
# ---------------------------------------------------------------------------
saida <- file.path(pasta_resultados,'18 - Diagnostico espacial ambiental R20 V1_3')
if (dir.exists(saida))
  stop('A pasta R20 ja existe, e o script nao a sobrescreve: ',saida,
       '\nPreserve-a e renomeie-a manualmente apenas se desejar nova rodada.')
dir.create(saida,recursive=TRUE,showWarnings=FALSE)
graficos <- file.path(saida,'20_GRAFICOS')
dir.create(graficos,showWarnings=FALSE)
escrever <- function(x,nome) utils::write.csv(x,file.path(saida,nome),
                                              row.names=FALSE,fileEncoding='UTF-8')
escrever(verific,'20_VERIFICACAO_72_PREVISOES.csv')
escrever(local,'20_AUC_POR_PROPRIEDADE.csv')
escrever(resumo_auc,'20_RESUMO_AUC_GLOBAL_LOCAL.csv')
escrever(upa_res,'20_ESFORCO_POR_UPA.csv')
escrever(nov_uni,'20_NOVIDADE_UNIVARIADA.csv')
escrever(nov_solo,'20_NOVIDADE_SOLO.csv')
escrever(nov_nn,'20_NOVIDADE_MULTIVARIADA_NN.csv')
escrever(nov_nn_prop,'20_NN_POR_PROPRIEDADE.csv')
escrever(limiares,'20_LIMIARES_CRITICOS.csv')
escrever(registro_rds,'20_AUDITORIA_RDS_CRITICOS.csv')
fontes <- data.frame(arquivo=c(basename(arq19),basename(locais19_arq),
  basename(comparacao19_arq),basename(manifesto19_arq),
  basename(pres_arq),basename(b0_arq),basename(b2_arq)),
  md5=unname(tools::md5sum(c(arq19,locais19_arq,comparacao19_arq,
                              manifesto19_arq,pres_arq,b0_arq,b2_arq))),
  stringsAsFactors=FALSE)
escrever(fontes,'20_MANIFESTO_FONTES.csv')

# AUC local e global, nos dois folds criticos; linha pontilhada = 0.5.
for (sp in c('Ipe-roxo','Ipe-amarelo')) {
  f <- if (sp=='Ipe-roxo') 3L else 2L
  l <- local[local$especie==sp & local$fold_cv==f,,drop=FALSE]
  ps <- split(l$auc_bg_b2,l$propriedade)
  med <- sort(vapply(ps,mean,numeric(1)))
  glo <- mean(m$auc_validacao[m$especie==sp & m$fold_cv==f])
  png(file.path(graficos,paste0('20_AUC_LOCAL_',if(sp=='Ipe-roxo')'ROXO_F3' else 'AMARELO_F2','.png')),
      width=1300,height=790,res=130)
  par(mar=c(12,5,4,2))
  plot(seq_along(med),med,pch=19,ylim=c(0,1),xaxt='n',
       xlab='',ylab='AUC local media (12 modelos)',
       main=paste('B2 -',sp,'Fold',f,'| propriedades'))
  axis(1,at=seq_along(med),labels=names(med),las=2,cex.axis=.8)
  abline(h=.5,lty=2,col='gray55')
  abline(h=glo,lty=3,col='gray25',lwd=2)
  legend('topleft',legend=c(paste('AUC global media =',round(glo,3)),
                             'AUC 0,5'),lty=c(3,2),col=c('gray25','gray55'),bty='n')
  dev.off()
}
# Seis distribuicoes de validacao com o limiar do treino.
for (id in names(previsoes_criticas)) {
  a <- previsoes_criticas[[id]]
  png(file.path(graficos,paste0('20_SCORES_',id,'.png')),
      width=1200,height=770,res=125)
  breaks <- seq(0,1,by=.02)
  hp <- hist(a$p,breaks=breaks,plot=FALSE)
  hb <- hist(a$b,breaks=breaks,plot=FALSE)
  ymax <- max(c(hp$density,hb$density),na.rm=TRUE)*1.14
  plot(hb,frequency=FALSE,col=adjustcolor('gray65',alpha.f=.65),
       border=NA,xlim=c(0,1),ylim=c(0,ymax),main=paste('R20 -',id),
       xlab='Score cloglog de validacao',ylab='Densidade')
  plot(hp,frequency=FALSE,add=TRUE,
       col=adjustcolor('steelblue3',alpha.f=.48),border=NA)
  abline(v=a$limiar,lty=2,lwd=2,col='firebrick3')
  legend('topright',legend=c('Background B2','Presencas','Limiar P10 do treino'),
    fill=c('gray65','steelblue3',NA),border=NA,lty=c(NA,NA,2),
    col=c(NA,NA,'firebrick3'),bty='n',cex=.85)
  dev.off()
}

crit_roxo <- verific[verific$especie=='Ipe-roxo' & verific$fold_cv==3,,drop=FALSE]
crit_amarelo <- verific[verific$especie=='Ipe-amarelo' & verific$fold_cv==2,,drop=FALSE]
texto <- c(
  paste('TCC IPES -',versao),
  paste('Executado:',format(Sys.time(),'%Y-%m-%d %H:%M:%S')),
  'Analise exploratoria: somente 27 propriedades de desenvolvimento.',
  'Nao houve ajuste novo e nao foi usado o teste externo de 7 propriedades.',
  paste('Previsoes R19 conferidas:',nrow(verific),'modelos.'),
  paste('RDS candidatos revisados:',nrow(registro_rds),'para 6 modelos criticos.'),
  paste('Copias RDS: identificadas por MD5, P10 e numero de coeficientes.'),
  paste('AUC por propriedade conferida:',nrow(local),'linhas.'),
  paste('UPAs inventariadas:',nrow(upa_res)),
  paste('Roxo F3 - modelos com omissao 100%:',
        sum(crit_roxo$omissao_recalculada==1),'de',nrow(crit_roxo)),
  paste('Amarelo F2 - modelos com omissao 100%:',
        sum(crit_amarelo$omissao_recalculada==1),'de',nrow(crit_amarelo)),
  '',
  'Interpretacao:',
  '1) AUC global mistura propriedades; AUC local e comparacao interna.',
  '2) AUC nao representa acuracia contra ausencias confirmadas.',
  '3) Omissao mede proporcao de presencas abaixo do limiar P10 de treino.',
  '4) As medidas ambientais foram calculadas com B2 de treino de cada fold.',
  '5) NN multivariada usa somente 5 preditores continuos padronizados:',
  '   distancia ao vizinho mais proximo de 2000 amostras aleatorias de BG treino.',
  '   O percentil 95 vem de 700 amostras disjuntas tambem do BG treino.',
  '   Esse procedimento NAO e MOP/MESS formal; amostragem e exploratoria.',
  '   A categoria solo e examinada a parte; ha limites pela composicao BG.',
  '6) Novidade ambiental e associacao, nao demonstracao causal.',
  '7) CSVs R19 podem conter B0/B1 extras: filtrados com verificacao',
  '   de AUC, contagens e AUC local antes de analisar B2.',
  '8) Nao unir presencas a previsoes pelo numero da linha: os CSVs de',
  '   previsao nao trazem necessariamente um identificador individual.',
  '9) Boyce foi apenas importado do R19, nao recalculado.',
  '10) 20_AUDITORIA_RDS_CRITICOS.csv documenta copias dos modelos.',
  '11) Nenhuma configuracao foi selecionada como modelo final.',
  '12) A razao de AUC global discordante das locais requer interpretacao',
  '    espacial e ambiental; esta analise nao estabelece causa definitiva.',
  '',
  'Fontes: confira 20_MANIFESTO_FONTES.csv.',
  paste('Pasta de saida:',saida))
writeLines(texto,file.path(saida,'20_RELATORIO_DIAGNOSTICO.txt'),useBytes=TRUE)
cat('\nR20 TERMINOU. Resultados em:\n',saida,'\n',sep='')
