# ==============================================================
# TCC IPES | R27 V1 - AUDITAR PLANEJAMENTO DE VALIDACAO POR UPA
# Executa SOMENTE verificacoes. NAO ajusta MaxEnt nem muda folds.
# Entradas e propostas devem permanecer nas subpastas do pacote.
# ==============================================================

options(stringsAsFactors = FALSE)

localizar_pasta <- function() {
  of <- unlist(lapply(sys.frames(), function(f) {
    if (is.null(f$ofile)) character(0) else as.character(f$ofile)
  }), use.names = FALSE)
  if (length(of)) {
    pasta <- dirname(normalizePath(tail(of, 1), winslash = '/', mustWork = TRUE))
    if (file.exists(file.path(pasta, '01_ENTRADAS_COPIAS', '26_MATRIZ_64_UPAS.csv'))) return(pasta)
  }
  if (file.exists('01_ENTRADAS_COPIAS/26_MATRIZ_64_UPAS.csv')) {
    return(normalizePath('.', winslash = '/', mustWork = TRUE))
  }
  stop('R27: Mantenha o script na pasta principal do pacote, junto das subpastas 01_ENTRADAS_COPIAS e 02_PLANO_PRECALCULADO.')
}

pasta <- localizar_pasta()
entrada <- file.path(pasta, '01_ENTRADAS_COPIAS')
propostas <- file.path(pasta, '02_PLANO_PRECALCULADO')
ler <- function(p) {
  if (!file.exists(p)) stop('Arquivo ausente: ', p)
  utils::read.csv(p, fileEncoding = 'UTF-8-BOM', check.names = FALSE,
                  stringsAsFactors = FALSE)
}
exigir <- function(cond, msg) {
  if (!isTRUE(cond)) stop('R27 - ', msg, call. = FALSE)
}

# 1. Integridade dos CSVs congelados dentro do pacote.
manifesto <- ler(file.path(propostas, '27_MANIFESTO_ENTRADAS.csv'))
exigir(nrow(manifesto) == 6, 'O manifesto deveria conter seis entradas.')
for (i in seq_len(nrow(manifesto))) {
  p <- file.path(entrada, manifesto$arquivo[i])
  exigir(file.exists(p), paste('Entrada nao localizada:', manifesto$arquivo[i]))
  md5 <- unname(tools::md5sum(p))
  exigir(identical(tolower(md5), tolower(manifesto$md5[i])),
         paste('MD5 diferente para', manifesto$arquivo[i], '- nao misture bases.'))
}
cat('R27: seis entradas conferidas por MD5.\n')

m <- ler(file.path(entrada, '26_MATRIZ_64_UPAS.csv'))
candidatas <- ler(file.path(entrada, '26_CANDIDATAS_RESERVA_UPA.csv'))
pares_rec <- ler(file.path(entrada, '26_PARES_RECIPROCOS_CANDIDATOS.csv'))
pares <- ler(file.path(entrada, '24_PARES_UPAS_GEOMETRICOS.csv'))
pres <- ler(file.path(entrada, '05_PRESENCAS_UM_POR_PIXEL_30M.csv'))
bg <- ler(file.path(entrada, '18_BACKGROUND_B2_10000_COM_FOLDS.csv'))
plano <- ler(file.path(propostas, '27_UPAS_RESERVADAS_PAINEIS.csv'))
mapa <- ler(file.path(propostas, '27_PAPEIS_64_UPAS_POR_CENARIO.csv'))
resumo <- ler(file.path(propostas, '27_RESUMO_6_PAINEIS.csv'))
dist <- ler(file.path(propostas, '27_DISTANCIAS_RESERVAS_TREINO.csv'))
reciprocos <- ler(file.path(propostas, '27_RECIPROCOS_DIAGNOSTICOS.csv'))
rp <- ler(file.path(propostas, '27_ALEATORIO_50_50_PRESENCAS.csv'))
rb <- ler(file.path(propostas, '27_ALEATORIO_50_50_BACKGROUND.csv'))

# 2. Controles globais.
exigir(nrow(m) == 64 && length(unique(m$upa_id)) == 64, 'Matriz de UPAs inesperada.')
exigir(nrow(pres) == 8680 && nrow(bg) == 10000, 'Quantidade de linhas inesperada.')
exigir(sum(m$n_roxo) == 3248 && sum(m$n_amarelo) == 5432,
       'Totais por especie diferentes dos dados consolidados.')
exigir(sum(m$n_bg_b2) == 10000, 'Total de background incorreto.')
exigir(length(unique(m$propriedade)) == 27, 'Esperadas 27 propriedades.')
externas <- c('BARRO BRANCO', 'CURUÇA', 'GUARIÚBA', 'JATOBÁ',
              'LOTE 01', 'MARILIA', 'PALMEIRA')
exigir(!any(m$propriedade %in% externas) &&
       !any(pres$propriedade %in% externas) &&
       !any(bg$propriedade %in% externas), 'Uma propriedade externa entrou no planejamento!')
exigir(!anyNA(c(m$upa_id, pres$upa_id, bg$upa_id)), 'UPA sem identificador.')
exigir(all(pres$upa_id %in% m$upa_id) && all(bg$upa_id %in% m$upa_id),
       'Presenca/background com UPA desconhecida.')

# Conferir contagens linha a linha contra dados completos, nao so contra resumos.
contar <- function(v, upas) {
  vv <- table(factor(v, levels = upas))
  as.integer(vv)
}
exigir(all(contar(pres$upa_id[pres$especie == 'Ipe-roxo'], m$upa_id) == m$n_roxo),
       'Contagens de presenca roxo diferentes da matriz R26.')
exigir(all(contar(pres$upa_id[pres$especie == 'Ipe-amarelo'], m$upa_id) == m$n_amarelo),
       'Contagens de presenca amarelo diferentes da matriz R26.')
exigir(all(contar(bg$upa_id, m$upa_id) == m$n_bg_b2),
       'Contagens do background diferentes da matriz R26.')
cat('R27: 64 UPAs, 8680 presencas e 10000 backgrounds confirmados.\n')

# 3. Paineis locais (tres por especie, sem sobreposicao de UPAs de validacao).
exigir(nrow(resumo) == 6 && nrow(mapa) == 384,
       'Esperados 6 paineis e 384 linhas da matriz de papeis.')
exigir(nrow(plano) >= 12, 'Plano de reservas incompleto.')
exigir(nrow(dist) == nrow(plano), 'Distancias devem ter uma linha por UPA reservada.')
q <- list(); nq <- 0L
for (sp in c('Ipe-roxo', 'Ipe-amarelo')) {
  plsp <- plano[plano$especie == sp, , drop = FALSE]
  exigir(length(unique(plsp$cenario_id)) == 3, paste('Faltam paineis:', sp))
  exigir(!anyDuplicated(plsp$upa_id), paste('UPA reservada em mais de um painel:', sp))
  exigir(!anyDuplicated(plsp$propriedade),
         paste('Propriedade repetida entre reservas da especie:', sp))
  col <- if (sp == 'Ipe-roxo') 'n_roxo' else 'n_amarelo'
  for (id in sort(unique(plsp$cenario_id))) {
    s <- plsp[plsp$cenario_id == id, , drop = FALSE]
    exigir(nrow(s) >= 2 && nrow(s) <= 4, paste('Numero UPAs inadequado:', sp, id))
    exigir(nrow(s) == length(unique(s$propriedade)),
           paste('Propriedade duplicada no painel:', sp, id))
    exigir(all(s$upa_id %in% m$upa_id), paste('UPA desconhecida:', sp, id))
    exigir(all(s$n_presencas_upa >= 50) && all(s$n_bg_upa >= 30),
           paste('UPA pequena para o painel:', sp, id))
    exigir(all(paste(s$especie, s$upa_id) %in%
                paste(candidatas$especie, candidatas$upa_id)),
           paste('Reserva nao elegivel pelo R26:', sp, id))
    val <- m[m$upa_id %in% s$upa_id, , drop = FALSE]
    tr <- m[!m$upa_id %in% s$upa_id, , drop = FALSE]
    nval <- sum(val[[col]]); ntr <- sum(tr[[col]])
    bgval <- sum(val$n_bg_b2); bgtr <- sum(tr$n_bg_b2)
    exigir(nval >= 250 && nval <= 500 && bgval >= 180 && ntr >= 1000,
           paste('Total treino/validacao inadequado:', sp, id))
    for (j in seq_len(nrow(s))) {
      pr <- s$propriedade[j]; upa <- s$upa_id[j]
      outros <- m[m$propriedade == pr & m$upa_id != upa, , drop = FALSE]
      exigir(sum(outros[[col]]) >= 30 && sum(outros$n_bg_b2) >= 30,
             paste('Sem suporte de treino na mesma propriedade:', sp, upa))
    }
    z <- mapa[mapa$cenario_id == id & mapa$especie == sp, , drop = FALSE]
    exigir(nrow(z) == 64 && !anyDuplicated(z$upa_id) &&
           setequal(z$upa_id, m$upa_id), paste('Mapa incompleto:', sp, id))
    exigir(setequal(z$upa_id[z$papel == 'VALIDACAO'], s$upa_id),
           paste('Mapa com reservas diferentes:', sp, id))
    zval <- z[z$papel == 'VALIDACAO', , drop = FALSE]
    exigir(sum(zval$n_presencas_especie) == nval && sum(zval$n_bg_b2) == bgval,
           paste('Mapa com contagens diferentes:', sp, id))
    esperado <- resumo[resumo$especie == sp & resumo$cenario_id == id, , drop = FALSE]
    exigir(nrow(esperado) == 1 &&
           esperado$n_presencas_validacao == nval &&
           esperado$n_background_validacao == bgval &&
           esperado$n_presencas_treino == ntr &&
           esperado$n_background_treino == bgtr,
           paste('Resumo inconsistente:', sp, id))
    nq <- nq + 1L
    q[[nq]] <- data.frame(especie = sp, cenario_id = id,
       n_upas_validacao = nrow(s), n_presencas_validacao = nval,
       n_background_validacao = bgval, n_presencas_treino = ntr,
       n_background_treino = bgtr, status = 'PASSOU_NA_AUDITORIA_NAO_APLICADO')
    cat(sprintf('R27 OK: %s %s, val %d presencas / %d BG; treino %d presencas.\n',
                sp, id, nval, bgval, ntr))
  }
}

# 4. Auditoria das distancias geometricas, inclusive as UPAs contiguas.
chaves <- function(a, b) paste(pmin(a,b), pmax(a,b), sep = ';;')
par_chave <- chaves(sub('^.*\\|\\|', '', pares$upa_a),
                   sub('^.*\\|\\|', '', pares$upa_b))
exigir(!anyDuplicated(par_chave), 'Duplicacao dos pares geometricos R24.')
for (i in seq_len(nrow(dist))) {
  rr <- dist[i, , drop = FALSE]
  pl <- plano[plano$cenario_id == rr$cenario_id & plano$especie == rr$especie,
              , drop = FALSE]
  outras <- setdiff(m$upa_id, pl$upa_id)
  idx <- match(chaves(rep(rr$upa_id, length(outras)), outras), par_chave)
  exigir(all(!is.na(idx)), paste('Par geometrico ausente:', rr$upa_id))
  dmin <- min(pares$distancia_limites_km[idx])
  exigir(is.finite(dmin) &&
           abs(dmin - rr$distancia_min_limites_outra_upa_treino_km) < 1e-6,
         paste('Distancia minima divergente:', rr$upa_id))
}
cat('R27: distancias de todas as UPAs reservadas conferidas.\n')

# 5. Reciprocos: duas UPAs apenas, nunca misturar com o painel principal.
exigir(nrow(reciprocos) == 4 && length(unique(reciprocos$cenario_id)) == 4,
       'Esperados quatro testes reciprocos ilustrativos.')
for (i in seq_len(nrow(reciprocos))) {
  r <- reciprocos[i, , drop = FALSE]
  col <- if (r$especie == 'Ipe-roxo') 'n_roxo' else 'n_amarelo'
  a <- m[m$upa_id == r$upa_treino, , drop = FALSE]
  b <- m[m$upa_id == r$upa_validacao, , drop = FALSE]
  exigir(nrow(a) == 1 && nrow(b) == 1 &&
         a$propriedade == b$propriedade &&
         a[[col]] == r$n_presencas_treino &&
         b[[col]] == r$n_presencas_validacao &&
         a$n_bg_b2 == r$n_background_treino &&
         b$n_bg_b2 == r$n_background_validacao,
         paste('Teste reciproco inconsistente:', r$cenario_id))
  dois <- pares_rec[pares_rec$especie == r$especie &
                    pares_rec$propriedade == r$propriedade &
                    ((pares_rec$upa_a == r$upa_treino &
                      pares_rec$upa_b == r$upa_validacao) |
                     (pares_rec$upa_b == r$upa_treino &
                      pares_rec$upa_a == r$upa_validacao)), , drop = FALSE]
  exigir(nrow(dois) == 1 &&
         abs(dois$distancia_limites_km-r$distancia_limites_km)<1e-6,
         paste('Reciproco nao existe no R26:', r$cenario_id))
}

# 6. Sorteio 50/50: apenas controle exploratorio, NAO CV independente.
exigir(nrow(rp)==nrow(pres) &&
       identical(as.integer(rp$indice_linha_fonte), seq_len(nrow(pres))),
       'Referencia aleatoria de presencas nao corresponde ao arquivo R05.')
exigir(nrow(rb)==nrow(bg) &&
       identical(as.integer(rb$indice_linha_fonte), seq_len(nrow(bg))),
       'Referencia aleatoria de background nao corresponde ao arquivo R18.')
exigir(identical(as.character(rp$especie), as.character(pres$especie)) &&
       identical(as.character(rp$upa_id), as.character(pres$upa_id)) &&
       identical(as.character(rb$upa_id), as.character(bg$upa_id)) &&
       identical(as.character(rb$id_background), as.character(bg$id_background)),
       'IDs ou ordem dos dados foram modificados!')
exigir(all(rp$papel %in% c('TREINO','VALIDACAO')) &&
       all(rb$papel %in% c('TREINO','VALIDACAO')),
       'Papeis invalidos na referencia aleatoria.')
equilibrio <- function(papeis) abs(sum(papeis=='TREINO')-sum(papeis=='VALIDACAO')) <= 1
exigir(all(vapply(split(rp$papel, paste(rp$especie,rp$upa_id)), equilibrio,
                   logical(1))), 'Amostra aleatoria de presencas sem equilibrio intra-UPA.')
exigir(all(vapply(split(rb$papel, rb$upa_id), equilibrio, logical(1))),
       'Amostra aleatoria B2 sem equilibrio intra-UPA.')
cat('R27: dois sorteios de referencia 50/50 auditados.\n')

# 7. Entregar SOMENTE novas copias auditadas, sem sobrescrever produtos antigos.
saida <- file.path(pasta, paste0('03_RESULTADOS_R_',format(Sys.time(),'%Y%m%d_%H%M%S')))
exigir(!dir.exists(saida), 'Ja existe pasta de saida com este timestamp.')
dir.create(saida, recursive = TRUE, showWarnings = FALSE)
qfinal <- do.call(rbind, q)
utils::write.csv(qfinal, file.path(saida, '27_QA_6_PAINEIS_CONFERIDOS.csv'),
                 row.names = FALSE, fileEncoding = 'UTF-8')
nomes <- c('27_UPAS_RESERVADAS_PAINEIS.csv',
           '27_PAPEIS_64_UPAS_POR_CENARIO.csv',
           '27_RESUMO_6_PAINEIS.csv',
           '27_DISTANCIAS_RESERVAS_TREINO.csv',
           '27_RECIPROCOS_DIAGNOSTICOS.csv',
           '27_ALEATORIO_50_50_PRESENCAS.csv',
           '27_ALEATORIO_50_50_BACKGROUND.csv',
           '27_MANIFESTO_ENTRADAS.csv',
           '27_RELATORIO_PLANEJAMENTO.md',
           '27_GRAFICO_PAINEIS.png',
           '27_GRAFICO_BACKGROUND.png')
for (nm in nomes) {
  exigir(file.copy(file.path(propostas,nm), file.path(saida,nm), overwrite=FALSE),
         paste('Falha ao copiar:', nm))
}
nota <- c('R27 - AUDITORIA CONCLUIDA',
          paste('Data:', Sys.time()),
          'Seis paineis locais conferidos; quatro direcoes reciprocas conferidas.',
          'Random 50/50 conferido; esta referencia NAO e independente espacialmente.',
          'Nenhum modelo MaxEnt ajustado; nenhum fold antigo alterado.',
          'Nao usar os 6 paineis como validacao regional independente.',
          'Modelos R19 NAO reutilizaveis nas novas particoes.',
          'Sete propriedades de teste externo permanecem excluidas.',
          paste('Saida:',saida))
writeLines(nota, file.path(saida, '27_RELATORIO_EXECUCAO_R.txt'),useBytes=TRUE)
cat('\nR27 CONCLUIDO.\nResultados: ', saida,
    '\nEnvie a pasta compactada para conferirmos o planejamento antes do R28.\n',sep='')
