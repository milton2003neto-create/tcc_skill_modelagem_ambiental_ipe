# TCC Ipês — R28: seis ajustes locais entre UPAs

**Objetivo:** avaliar se os modelos de *Handroanthus impetiginosus* e *H. serratifolius* conseguem transferir previsões para UPAs inteiras não usadas no ajuste, em regiões que continuam parcialmente representadas no treinamento.

## Desenho congelado

| Espécie | Painel | Presenças de treino | Presenças de validação | Background de validação |
|---|---|---:|---:|---:|
| Ipê-roxo | Local 1 | 2.854 | 394 | 469 |
| Ipê-roxo | Local 2 | 2.849 | 399 | 484 |
| Ipê-roxo | Local 3 | 2.860 | 388 | 424 |
| Ipê-amarelo | Local 1 | 5.047 | 385 | 681 |
| Ipê-amarelo | Local 2 | 5.049 | 383 | 417 |
| Ipê-amarelo | Local 3 | 5.047 | 385 | 613 |

O background B2 completo possui 10.000 pontos distribuídos nas 64 UPAs inventariadas de 27 propriedades de desenvolvimento. Cada painel reserva UPAs completas para validação e mantém as demais para treinamento. Os grupos diferem entre espécies.

**Parâmetros fixos:** LQH, RM 4, seis preditores, textura do solo como fator; MaxEnt via `maxnet`; saída cloglog com clamping; limiar de omissão no percentil 10 das presenças de treinamento. Testes recíprocos e divisão aleatória 50/50 são etapas complementares, não executadas neste script.

## Métricas a interpretar

AUC presença–background global; AUC intra-propriedade ponderada por pares presença–background; AUC por UPA; Boyce; taxa de omissão P10; pior painel de cada espécie. Comparar essas métricas sem concluir causalidade ecológica, porque o background não corresponde a ausências confirmadas.

**Limite central:** UPAs contíguas de treinamento e validação não demonstram independência regional. Esta é uma validação **local exploratória**. O R19 continua sendo diagnóstico de transferência entre propriedades, e as sete propriedades externas permanecem reservadas para avaliação final após a escolha metodológica.
