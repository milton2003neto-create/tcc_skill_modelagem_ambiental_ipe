# Ferramenta de Modelagem Ambiental dos Ipês (TCC – UFRA)

Ferramenta em R/Shiny para modelar a ocorrência de *Handroanthus impetiginosus* (ipê-roxo) e
*H. serratifolius* (ipê-amarelo) com **MaxEnt (pacote `maxnet`)**, com fluxo separado por espécie.

## Como usar (do zero)

1. Abra `FerramentaIpes.Rproj` no RStudio.
2. Rode `R/00_SETUP_PACOTES_E_TESTES.R` (botão **Source**). Ele instala/testa os pacotes e confere os dados.
3. (Próximas etapas) Rode o app com `shiny::runApp()`.

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
