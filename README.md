# Ferramenta de Modelagem Ambiental dos Ipês (TCC – UFRA)

Ferramenta em R/Shiny para modelar a ocorrência de *Handroanthus impetiginosus* (ipê-roxo) e
*H. serratifolius* (ipê-amarelo) com **MaxEnt (pacote `maxnet`)**, com fluxo separado por espécie.

## Como usar (do zero)

1. Abra `FerramentaIpes.Rproj` no RStudio.
2. Rode `R/00_SETUP_PACOTES_E_TESTES.R` (botão **Source**). Ele instala/testa os pacotes e confere os dados.
3. Abra `app.R` e clique em **Run App** (ou `shiny::runApp()`). Siga as abas 1 → 6; a aba **Ajuda** explica cada termo.

| Aba | Script | O que faz |
|---|---|---|
| 1. Diagnóstico | `R/03` | Concentração, folds, novidade ambiental, agrupamento |
| 2. Treino / Validação | `R/04`, `R/05` | Propriedade×propriedade ou UPA×UPA; recomenda e você ajusta; protege as reservadas |
| 3. Variáveis | `R/06` | Correlação (Pearson/Spearman), VIF, solo; escolha manual |
| 4. Background e parâmetros | `R/07` | B2 ou novo sorteio; grade features × RM; estimativa de tempo/memória |
| 5. Treinamento | `R/08` | Todos os modelos nos folds, recomendação, Jackknife, ROC |
| 6. Validação | `R/09` | Treino × validação, AUC por propriedade, mapas `.tif`/`.gpkg` para o QGIS, teste externo protegido |

Metodologia detalhada (para o TCC): `docs/METODOLOGIA_SCRIPTS.md` e `.docx`.

## Organização

| Pasta / arquivo | Conteúdo |
|---|---|
| `R/00_...`, `R/01_...`, ... | Scripts numerados, na ordem de execução, todos comentados |
| `resultados/<especie>/<etapa>/<data_hora>/` | Saídas: `.csv`, `.png`, `.rds` e `LOG_EXECUCAO.txt/.json` (fora do Git) |
| `docs/` | Documentação para a metodologia do TCC |
| `_legado/` | Material anterior (skill Python simulada, consolidação R28–R30, cópia de dados) — preservado, não usado |

## Dados

Lidos (sem cópia) de `../../TCC - Ipes - Inicio do zero`. Para outro computador, crie `config_local.R`
com `PASTA_DADOS <- "C:/.../TCC - Ipes - Inicio do zero"`.

## Requisitos

R ≥ 4.2 e RStudio. **Não precisa de Java.** Rtools não é necessário (pacotes binários do CRAN).
