# R26 — Diagnóstico de elegibilidade das UPAs

**Etapa:** planejamento da validação entre UPAs, sem ajuste de MaxEnt nem modificação da base.  
**Área:** 27 propriedades de desenvolvimento e 64 UPAs inventariadas.  
**Dados:** 3.248 presenças deduplicadas de ipê-roxo; 5.432 de ipê-amarelo; 10.000 backgrounds B2.  
**Conferência:** 64/64 chaves de UPA consistentes entre R05, R18 e R24. Contagens também coincidem com o R20.

## Síntese de elegibilidade

| Medida | Ipê-roxo | Ipê-amarelo |
|---|---:|---:|
| UPAs com pelo menos uma ocorrência | 21 | 44 |
| UPAs com 30 ou mais presenças | 21 | 29 |
| Propriedades com pelo menos duas UPAs com presença | 8 | 16 |
| Propriedades com pelo menos duas UPAs de 30+ presenças | 8 | 10 |
| UPAs candidatas a reserva individual com treino local suficiente | 17 | 26 |

**Critério de triagem operacional:** para reservar uma UPA individual na validação da mesma propriedade, são exigidas 30 ou mais presenças da espécie e 30 ou mais pontos B2 nessa UPA, além de 30 presenças e 30 backgrounds nas outras UPAs da propriedade somadas. Não é regra universal de MaxEnt nem aval de independência; ajustar formalmente no R27 considerando também distâncias e semelhança ambiental.

**Alerta espacial:** 25 das 28 combinacoes reciprocas candidatas possuem distancia zero entre contornos de UPAs (contato ou sobreposicao). Esse desenho mede transferencia LOCAL e pode carregar dependencia espacial; nao substitui validacao regional.

**Achado importante:** somente 1 das 64 UPAs contém registros das duas espécies simultaneamente. Por isso, o desenho por UPA é naturalmente **específico para cada espécie**, embora os mesmos princípios de validação sejam mantidos.

## Cuidados metodológicos

- Zero ocorrência de uma das espécies numa UPA **inventariada** indica ausência de registro da espécie nessa UPA, não ausência confirmada em cada ponto de background; UPAs não inventariadas continuam excluídas.
- Presenças deduplicadas por espécie/pixel de 30 m foram preservadas; não reutilizar árvores brutas duplicadas.
- Todas as distâncias provêm dos limites geométricos de UPAs do R24, calculadas em projeção métrica regional; proximidade não prova dependência ecológica.
- Testes alternativos de UPAs dentro de uma propriedade avaliam transferência **local**. Não substituem avaliação entre propriedades/regiões nem teste final em sete propriedades externas.
- Os cenários locais e regionais não devem ser escolhidos para maximizar AUC observada em R19–R22.
- **Modelos R19 não podem ser reaproveitados para validar divisões novas por UPA**; eles continuam como *referência histórica* dos folds por propriedade. Uma nova divisão exige novos ajustes, com os dados de treino correspondentes.
- Os candidatos desta etapa são apenas elegibilidade matemática, não folds aprovados. A seleção de blocos, limiares de distância, regras de background e avaliação recíproca vem no R27.
- Registrar e revisar a pendência cadastral da UPA 01 de Saudade e pequenos recobrimentos do R24 sem alterar os originais.

## Critérios para concluir R26

1. 64 UPAs e 27 propriedades preservadas, sem dados das sete propriedades externas.
2. 8.680 presenças e 10.000 B2 exatamente localizados nas UPAs inventariadas.
3. Resultado por espécie/UPA documentado e com candidatos rastreáveis.
4. Nenhum modelo ajustado, nenhuma UPA excluída, nenhum fold modificado.
