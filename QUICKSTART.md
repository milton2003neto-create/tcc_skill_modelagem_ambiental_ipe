# Quick Start — TCC Ipês em 5 Minutos

**Para quem quer começar AGORA sem ler tudo.**

---

## 🎯 1. O Projeto em 1 Frase

Framework automatizado que aprende onde árvores (Ipês Roxo/Amarelo) ocorrem em florestas manejadas do Pará e prediz presença em novas áreas.

---

## ⚡ 2. Comece Aqui (Ordem)

### 2.1. Verificar Setup
```bash
python skill_modelagem_ipes.py
```

**Resultado esperado:**
```
✓ Python 3.11.5: OK
✓ R instalado: OK
✓ Diretórios projeto: OK
✓ SKILL COMPLETO
```

**Se falhar:** Leia [SKILL_COMO_USAR.md](SKILL_COMO_USAR.md) → Troubleshooting

### 2.2. Executar Análises (Opcional - Leva 4-5h)
```bash
python skill_modelagem_ipes.py
```

Roda R28-R30-R31 completos. Gera CSV + relatórios + gráficos.

---

## 📊 3. Ver Resultados Prontos (Recomendado - 5min)

**Já pronto, sem executar:**

1. Tabela consolidada:
   - [`00_CONSOLIDACAO_R28_R29_R30.csv`](00_CONSOLIDACAO_R28_R29_R30.csv) — 82 modelos, todas métricas

2. Análises:
   - [`01_RELATORIO_CONSOLIDADO_R28_R29_R30.md`](01_RELATORIO_CONSOLIDADO_R28_R29_R30.md) — 8 seções
   - [`02_ANALISES_ADICIONAIS_R28_R30.md`](02_ANALISES_ADICIONAIS_R28_R30.md) — 10 seções

3. Gráficos:
   - 6 PNGs (AUC, Boyce, features, RM, resumo, comparativo)

---

## 🔑 4. Descobertas Chave (TL;DR)

| Descoberta | Impacto |
|-----------|---------|
| **LQH >> L** | Features quadrática+hinge melhoram Boyce +1.2 |
| **RM=4 ótimo** | Regularização forte evita overfitting |
| **Amarelo > Roxo** | Amarelo AUC +0.2, mais previsível |
| **R29 viável** | Modelos transferem local (AUC ~0.60) |

**Conclusão:** LQH + RM=4 recomendado para produção.

---

## 🗂️ 5. Arquitetura em Mapa Mental

```
TCC MILTON/
├─ README.md ← LEIA PRIMEIRO
├─ QUICKSTART.md ← você está aqui
├─ RESUMO_EXECUTIVO.md ← para banca
├─ PLANO_ATUAL.md ← status + próximos passos
│
├─ Python Skill:
│  └─ skill_modelagem_ipes.py (orquestração)
│
├─ R28-R31 (resultados prontos):
│  ├─ 00_CONSOLIDACAO_*.csv
│  ├─ 01_RELATORIO_*.md
│  ├─ 02_ANALISES_*.md
│  └─ 6 gráficos PNG
│
└─ TCC - Ipes - Inicio do zero/
   └─ 05 - Modelagem no R/
      ├─ R28_... (6 modelos)
      ├─ R29_... (recíprocos)
      ├─ R30_... (72 grade)
      └─ R31_... (validação externa)
```

---

## 💡 6. Próximos Passos (Choose One)

### Opção A: Apenas Explorar (5min - Recomendado)
1. Abra [`RESUMO_EXECUTIVO.md`](RESUMO_EXECUTIVO.md)
2. Leia seções: problema, solução, descobertas, impacto
3. Olhe gráficos PNG
4. Pronto!

### Opção B: Executar (4-5h)
1. `python skill_modelagem_ipes.py`
2. Aguarde R28/R30/R31
3. Veja CSV + relatórios
4. Customize se necessário

### Opção C: Replicar em Outra Espécie (1-2 semanas)
1. Preparar dados nova espécie (R01-R25)
2. Executar skill com novos dados
3. Analisar, publicar

---

## 🎓 7. Para Dissertação

**Se você é Milton (autor TCC):**
1. Leia [`RESUMO_EXECUTIVO.md`](RESUMO_EXECUTIVO.md) → seções 1-5
2. Compile gráficos + tabelas em template .docx
3. Escreva capítulos (Intro, Métodos, Resultados, Discussão)
4. Use relatórios como base redação

**Timeline:** 4-6 semanas redação

---

## 🔧 8. Troubleshooting Rápido

| Erro | Solução |
|------|---------|
| "R não encontrado" | Instale https://cran.r-project.org/ |
| "Pacote X não instalado" | `Rscript -e "install.packages('X')"` |
| "Timeout" | Script demorou >timeout. Tente novamente |
| "Dados não encontrados" | Verifique `TCC - Ipes - Inicio do zero/` existe |

---

## 📞 9. Contato

**Autor:** Milton da Silva Tavares Neto  
**Email:** milton2003profissional@gmail.com  
**Instituição:** UFRA

---

## 📚 10. Docs Completos (Leia Depois)

- **[README.md](README.md)** — Overview completo
- **[SKILL_COMO_USAR.md](SKILL_COMO_USAR.md)** — Como usar skill
- **[INDICE_COMPLETO.md](INDICE_COMPLETO.md)** — Navegação centralizada
- **[PLANO_ATUAL.md](PLANO_ATUAL.md)** — Status + timeline

---

**Status:** 80% (R01-R30 ✓, R31 framework ✓, Dissertação ⏳)  
**Data:** 2026-11-24  
**Versão:** 1.0
