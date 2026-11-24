# TCC IPÊS — Auditoria do R29, Parte 1 (Boyce do R28)

**Entrada:** `01_AUDITORIA_BOYCE.zip` (enviado em 18/11/2026).  
**Conclusão:** auditoria computacional do recálculo Boyce, AUC, P10 e omissão concluída sem divergências reportadas; a robustez interpretativa do Boyce varia entre painéis. O pacote não contém os objetos RDS para reprodução independente dos modelos MaxEnt.

## Integridade

- ZIP legível sem erro de integridade (19 entradas, incluindo diretórios); seis gráficos P/E e seis gráficos de scores.
- `29_CONFERENCIA_BOYCE_R28.csv`: seis modelos; todos com status `BOYCE_REPRODUZIDO` e `status_ecospat = OK`; diferença do Boyce recalculado versus R28 igual a zero para os seis casos (na precisão exportada).
- `29_CURVAS_PE_R28.csv`: 600 linhas, com 100 intervalos por modelo; valores finitos, com intervalos P/E iguais a zero no início de diversas curvas.
- Configuração de Boyce declarada no relatório de execução: `ecospat`, `nclass=0`, `rm.duplicate=TRUE`, correlação de Spearman, background de validação como disponibilidade e presenças de validação como observações.

## Sensibilidade ao número de classes

| Espécie / painel | AUC | Boyce original | Boyce com 10 classes | Diferença | Omissão P10 | Fração BG acima P10 |
|---|---:|---:|---:|---:|---:|---:|
| Roxo / Local 1 | 0,557 | 0,842 | 0,438 | −0,404 | 0,25% | 90,83% |
| Roxo / Local 2 | 0,376 | 0,673 | 0,073 | −0,600 | 1,00% | 96,49% |
| Roxo / Local 3 | 0,470 | 0,735 | 0,650 | −0,085 | 0,00% | 99,06% |
| Amarelo / Local 1 | 0,678 | 0,890 | 0,867 | −0,023 | 5,19% | 82,53% |
| Amarelo / Local 2 | 0,642 | 0,897 | 0,456 | −0,441 | 1,04% | 90,89% |
| Amarelo / Local 3 | 0,681 | 0,934 | 0,976 | +0,042 | 15,06% | 56,61% |

A configuração de 10 classes é **análise de sensibilidade**, não substituição retroativa da métrica predefinida. Mudanças grandes (Roxo/Local 2, Amarelo/Local 2, Roxo/Local 1) recomendam cautela ao interpretar Boyce isoladamente. O sinal de AUC e a fraca seletividade do P10 não são anulados por Boyce elevado.

## Curvas P/E

Os gráficos apresentam, em geral, maiores razões presenças/disponibilidade em adequabilidades mais altas, mas há oscilações, alguns intervalos com P/E=0 e respostas localmente não monotônicas, especialmente no Roxo Local 2 e Roxo Local 3. Com 100 intervalos frente a cerca de 380–400 presenças de validação por painel, o resultado pode ser sensível ao esquema de classes. Não interpretar a curva como evidência de causalidade ou calibração de probabilidade.

## Decisão operacional

**Liberar R29, Parte 2 — quatro testes recíprocos**, mantendo os mesmos dados e configuração experimental LQH/RM4. Não modificar R28 nem escolher modelo final com base apenas em Boyce. Preservar a ressalva da classe de solo não presente no treino no sentido Limão UPA 02 → UPA 03, registrando qualquer extrapolação categórica. Os testes recíprocos são locais e não substituem as sete propriedades de teste externo.

**Limite da auditoria:** validamos os arquivos exportados e a consistência das curvas; não reexecutamos os seis modelos originais nem reproduzimos o cálculo Boyce de maneira independente em R a partir das previsões brutas nesta sessão.
