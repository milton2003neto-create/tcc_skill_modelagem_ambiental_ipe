# R27 — Planejamento da validação por UPAs

**Status: PROPOSTA DIAGNÓSTICA. Nenhum fold novo aplicado; nenhum MaxEnt ajustado.**

## 1. Objetivo
Produzir conjuntos de validação locais com cerca de 200–500 presenças, distribuídos entre múltiplas UPAs e com outras UPAs da mesma propriedade permanecendo no treinamento.

## 2. Regras usadas ANTES de calcular qualquer desempenho
- Dados: R26 V1.1; 64 UPAs inventariadas, 27 propriedades de desenvolvimento, 8.680 presenças, B2 com 10.000 pontos.
- Cada espécie tem 3 painéis locais; cada painel reserva UPAs INTEIRAS, não árvores aleatórias.
- Cada painel contém 250–500 presenças e >=180 pontos B2 na validação; 2 a 4 propriedades.
- Cada UPA reservada tem >=50 presenças e uma outra UPA da mesma propriedade com >=30 presenças e >=30 B2.
- Uma propriedade contribui com no máximo UMA UPA reservada ao conjunto dos três painéis da mesma espécie.
- Os três painéis do roxo incluem áreas dos folds originais 1 e 2; os do amarelo incluem áreas dos folds 1, 2 e 3.
- Seleção por contagens e distribuição, SEM usar AUC/Boyce/omissão dos modelos.

## 3. Seis painéis primários
| Espécie | Painel | UPAs | Presenças de validação | Background B2 de validação | Presenças de treino |
|---|---|---:|---:|---:|---:|
| Ipe-roxo | LOCAL_UPAS_01 | 3 | 394 | 469 | 2854 |
| Ipe-roxo | LOCAL_UPAS_02 | 3 | 399 | 484 | 2849 |
| Ipe-roxo | LOCAL_UPAS_03 | 2 | 388 | 424 | 2860 |
| Ipe-amarelo | LOCAL_UPAS_01 | 4 | 385 | 681 | 5047 |
| Ipe-amarelo | LOCAL_UPAS_02 | 3 | 383 | 417 | 5049 |
| Ipe-amarelo | LOCAL_UPAS_03 | 4 | 385 | 613 | 5047 |

### UPAs reservadas
| Espécie | Painel | Propriedade | UPA | Presenças |
|---|---|---|---|---:|
| Ipe-amarelo | LOCAL_UPAS_01 | CEDRO | CEDRO|UPA 03 | 53 |
| Ipe-amarelo | LOCAL_UPAS_01 | PEDACINHO DE TERRA | PEDACINHO DE TERRA|UPA 01 | 51 |
| Ipe-amarelo | LOCAL_UPAS_01 | PINHO | PINHO|UPA 03 | 79 |
| Ipe-amarelo | LOCAL_UPAS_01 | SANTA LÚCIA | SANTA LÚCIA|UPA 01 | 202 |
| Ipe-amarelo | LOCAL_UPAS_02 | IMBAÚBA II | IMBAÚBA II|UPA 03 | 92 |
| Ipe-amarelo | LOCAL_UPAS_02 | LIMÃO | LIMÃO|UPA 02 | 187 |
| Ipe-amarelo | LOCAL_UPAS_02 | SAFIRA | SAFIRA|UPA 01 | 104 |
| Ipe-amarelo | LOCAL_UPAS_03 | AVEIRO | AVEIRO|UPA 02 | 101 |
| Ipe-amarelo | LOCAL_UPAS_03 | ESPERANÇA - PRAINHA | ESPERANÇA - PRAINHA|UPA 03 | 83 |
| Ipe-amarelo | LOCAL_UPAS_03 | IMBAÚBA I | IMBAÚBA I|UPA 03 | 140 |
| Ipe-amarelo | LOCAL_UPAS_03 | NATURAL | NATURAL|UPA 01 | 61 |
| Ipe-roxo | LOCAL_UPAS_01 | ESPLANADA | ESPLANADA|UPA 01 | 128 |
| Ipe-roxo | LOCAL_UPAS_01 | PEDRA GRANDE | PEDRA GRANDE|UPA 01 | 80 |
| Ipe-roxo | LOCAL_UPAS_01 | SAUDADE | SAUDADE|UPA 01 | 186 |
| Ipe-roxo | LOCAL_UPAS_02 | GAÚCHO | GAÚCHO|UPA 03 | 145 |
| Ipe-roxo | LOCAL_UPAS_02 | MARIA EDUARDA | MARIA EDUARDA|UPA 01 | 88 |
| Ipe-roxo | LOCAL_UPAS_02 | PINHAL | PINHAL|UPA 01 | 166 |
| Ipe-roxo | LOCAL_UPAS_03 | ANTA GORDA | ANTA GORDA|UPA 01 | 176 |
| Ipe-roxo | LOCAL_UPAS_03 | HERMES | HERMES|UPA 03 | 212 |

## 4. Experimentos complementares, não para selecionar vencedor
- Recíprocos: HERMES UPA 01 ↔ UPA 03 (roxo) e LIMÃO UPA 02 ↔ UPA 03 (amarelo). A modelagem seria limitada às duas UPAs em cada direção e precisa de QA de textura/quantidades antes do ajuste.
- Referência 50/50: sorteio determinístico dentro de cada combinação espécie×UPA, com background dividido dentro de cada UPA. NÃO é validação espacial independente; não usar para escolher parâmetros finais.

## 5. Limitações e precauções
- A maior parte das UPAs reservadas toca outras UPAs disponíveis para treinamento. Portanto, esses painéis testam **transferência local**, não a independência regional.
- As UPAs do Fold 3 original não fornecem um desenho adequado de validação INTERNA por propriedade para o ipê-roxo. O desempenho regional problemático do Fold 3 permanece nos resultados históricos e não pode ser apagado.
- Testes por UPA não substituem os modelos por propriedade R19 nem o teste cego de sete propriedades.
- Não declarar melhor modelo por AUC alta no 50/50; não escolher outra alocação após ver métricas sem registrar viés exploratório.
- Recomenda-se ajustar primeiro seis modelos com uma configuração de referência comum, por exemplo LQH/RM4 com seis preditores, depois auditar; os objetos do R19 NÃO podem ser reutilizados para treinamento com novas partições.
- Background é disponibilidade, não ausência confirmada. UPAs sem registro de uma das espécies não são ausências confirmadas.
- Verificar a pendência de geometria da UPA 01 de Saudade antes do mapa final; a reserva de parte desta UPA é apenas planejamento.

## 6. Próxima execução
Execute `R27_AUDITAR_PLANO_UPAS_V1.R` na pasta extraída para verificar MD5, partições, números, teste externo e reciprocidade. O script não treina modelos e não escreve nas pastas R01–R26. Envie a nova pasta de auditoria após executar.
