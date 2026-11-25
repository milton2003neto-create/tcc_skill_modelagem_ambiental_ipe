#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gráficos para consolidação R28-R29-R30
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

# Configuração de estilo
plt.style.use('seaborn-v0_8-darkgrid')
colors = {'Ipe-roxo': '#8B4513', 'Ipe-amarelo': '#FFD700'}

# Leitura de dados
consolidado_path = Path(r"C:\Users\jotac\Downloads\TCC MILTON\TCC - Ipes - Inicio do zero\00_CONSOLIDACAO_R28_R29_R30.csv")
df = pd.read_csv(consolidado_path)

output_dir = Path(r"C:\Users\jotac\Downloads\TCC MILTON\graficos_consolidacao")
output_dir.mkdir(exist_ok=True)

# ============================================================================
# GRÁFICO 1: Distribuição AUC por Fase
# ============================================================================
fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)
fig.suptitle('AUC de Validação por Fase e Espécie', fontsize=14, fontweight='bold')

for idx, (phase, ax) in enumerate(zip(['R28', 'R29', 'R30'], axes)):
    df_phase = df[df['fase'] == phase]

    for esp in ['Ipe-roxo', 'Ipe-amarelo']:
        data = df_phase[df_phase['especie'] == esp]['auc_validacao'].dropna()
        if len(data) > 0:
            ax.scatter([esp]*len(data), data, s=100, alpha=0.6,
                      color=colors.get(esp, '#999'), label=esp)
            ax.scatter([esp], [data.mean()], s=300, marker='_',
                      color=colors.get(esp, '#999'), linewidths=3)

    ax.set_title(f'{phase} (n={len(df_phase)})', fontweight='bold')
    ax.set_ylabel('AUC' if idx == 0 else '')
    ax.set_ylim(0.3, 0.75)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(output_dir / '01_AUC_por_Fase.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 1: {output_dir / '01_AUC_por_Fase.png'}")
plt.close()

# ============================================================================
# GRÁFICO 2: Boyce por Fase
# ============================================================================
fig, axes = plt.subplots(1, 3, figsize=(15, 5))
fig.suptitle('Boyce por Fase e Espécie', fontsize=14, fontweight='bold')

for idx, (phase, ax) in enumerate(zip(['R28', 'R29', 'R30'], axes)):
    df_phase = df[df['fase'] == phase]

    for esp in ['Ipe-roxo', 'Ipe-amarelo']:
        data = df_phase[df_phase['especie'] == esp]['boyce'].dropna()
        if len(data) > 0:
            ax.scatter([esp]*len(data), data, s=100, alpha=0.6,
                      color=colors.get(esp, '#999'), label=esp)
            ax.scatter([esp], [data.mean()], s=300, marker='_',
                      color=colors.get(esp, '#999'), linewidths=3)

    ax.axhline(y=0, color='r', linestyle='--', alpha=0.3, linewidth=1)
    ax.set_title(f'{phase} (n={len(df_phase)})', fontweight='bold')
    ax.set_ylabel('Boyce' if idx == 0 else '')
    ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(output_dir / '02_Boyce_por_Fase.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 2: {output_dir / '02_Boyce_por_Fase.png'}")
plt.close()

# ============================================================================
# GRÁFICO 3: R30 - AUC por Features (Boxplot)
# ============================================================================
df_r30 = df[df['fase'] == 'R30'].copy()

fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fig.suptitle('R30: AUC por Features (Exploração)', fontsize=14, fontweight='bold')

for idx, esp in enumerate(['Ipe-roxo', 'Ipe-amarelo']):
    df_esp = df_r30[df_r30['especie'] == esp]

    data_by_features = []
    features_list = []
    for feat in ['l', 'lq', 'lqh']:
        d = df_esp[df_esp['features'] == feat]['auc_validacao'].values
        if len(d) > 0:
            data_by_features.append(d)
            features_list.append(feat.upper())

    bp = axes[idx].boxplot(data_by_features, patch_artist=True)

    for patch in bp['boxes']:
        patch.set_facecolor(colors.get(esp, '#999'))
        patch.set_alpha(0.5)

    axes[idx].set_xticklabels(features_list)
    axes[idx].set_title(f'{esp}', fontweight='bold')
    axes[idx].set_ylabel('AUC')
    axes[idx].set_xlabel('Features')
    axes[idx].grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig(output_dir / '03_R30_AUC_por_Features.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 3: {output_dir / '03_R30_AUC_por_Features.png'}")
plt.close()

# ============================================================================
# GRÁFICO 4: R30 - Boyce por Features (Boxplot)
# ============================================================================
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fig.suptitle('R30: Boyce por Features', fontsize=14, fontweight='bold')

for idx, esp in enumerate(['Ipe-roxo', 'Ipe-amarelo']):
    df_esp = df_r30[df_r30['especie'] == esp]

    data_by_features = []
    features_list = []
    for feat in ['l', 'lq', 'lqh']:
        d = df_esp[df_esp['features'] == feat]['boyce'].values
        if len(d) > 0:
            data_by_features.append(d)
            features_list.append(feat.upper())

    bp = axes[idx].boxplot(data_by_features, patch_artist=True)

    for patch in bp['boxes']:
        patch.set_facecolor(colors.get(esp, '#999'))
        patch.set_alpha(0.5)

    axes[idx].set_xticklabels(features_list)
    axes[idx].axhline(y=0, color='r', linestyle='--', alpha=0.3, linewidth=1)
    axes[idx].set_title(f'{esp}', fontweight='bold')
    axes[idx].set_ylabel('Boyce')
    axes[idx].set_xlabel('Features')
    axes[idx].grid(True, alpha=0.3, axis='y')

plt.tight_layout()
plt.savefig(output_dir / '04_R30_Boyce_por_Features.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 4: {output_dir / '04_R30_Boyce_por_Features.png'}")
plt.close()

# ============================================================================
# GRÁFICO 5: R30 LQH - AUC por RM
# ============================================================================
df_r30_lqh = df_r30[df_r30['features'] == 'lqh'].copy()

fig, ax = plt.subplots(figsize=(10, 6))

for esp in ['Ipe-roxo', 'Ipe-amarelo']:
    df_esp = df_r30_lqh[df_r30_lqh['especie'] == esp]

    auc_by_rm = df_esp.groupby('rm')['auc_validacao'].agg(['mean', 'std'])

    ax.errorbar(auc_by_rm.index, auc_by_rm['mean'],
               yerr=auc_by_rm['std'],
               marker='o', markersize=8, linewidth=2,
               label=esp, color=colors.get(esp, '#999'), capsize=5)

ax.set_xlabel('Regularização (RM)', fontsize=12, fontweight='bold')
ax.set_ylabel('AUC de Validação', fontsize=12, fontweight='bold')
ax.set_title('R30 LQH: Efeito da Regularização', fontsize=14, fontweight='bold')
ax.set_xticks([1, 2, 3, 4])
ax.legend(fontsize=11)
ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(output_dir / '05_R30_LQH_AUC_por_RM.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 5: {output_dir / '05_R30_LQH_AUC_por_RM.png'}")
plt.close()

# ============================================================================
# GRÁFICO 6: Resumo comparativo — Fase vs Métrica
# ============================================================================
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Comparação Consolidada R28-R29-R30', fontsize=14, fontweight='bold')

# AUC por fase
df_summary = []
for fase in ['R28', 'R29', 'R30']:
    for esp in ['Ipe-roxo', 'Ipe-amarelo']:
        d = df[(df['fase'] == fase) & (df['especie'] == esp)]['auc_validacao'].mean()
        df_summary.append({'fase': fase, 'especie': esp, 'auc': d})

df_sum = pd.DataFrame(df_summary)
df_pivot_auc = df_sum.pivot(index='fase', columns='especie', values='auc')

ax = axes[0, 0]
df_pivot_auc.plot(kind='bar', ax=ax, color=[colors[e] for e in df_pivot_auc.columns], alpha=0.7)
ax.set_title('AUC por Fase', fontweight='bold')
ax.set_ylabel('AUC Médio')
ax.set_xlabel('')
ax.legend(title='Espécie', loc='best')
ax.grid(True, alpha=0.3, axis='y')
ax.set_xticklabels(ax.get_xticklabels(), rotation=0)

# Boyce por fase
df_summary_boyce = []
for fase in ['R28', 'R29', 'R30']:
    for esp in ['Ipe-roxo', 'Ipe-amarelo']:
        d = df[(df['fase'] == fase) & (df['especie'] == esp)]['boyce'].mean()
        df_summary_boyce.append({'fase': fase, 'especie': esp, 'boyce': d})

df_sum_boyce = pd.DataFrame(df_summary_boyce)
df_pivot_boyce = df_sum_boyce.pivot(index='fase', columns='especie', values='boyce')

ax = axes[0, 1]
df_pivot_boyce.plot(kind='bar', ax=ax, color=[colors[e] for e in df_pivot_boyce.columns], alpha=0.7)
ax.axhline(y=0, color='r', linestyle='--', alpha=0.3, linewidth=1)
ax.set_title('Boyce por Fase', fontweight='bold')
ax.set_ylabel('Boyce Médio')
ax.set_xlabel('')
ax.legend(title='Espécie', loc='best')
ax.grid(True, alpha=0.3, axis='y')
ax.set_xticklabels(ax.get_xticklabels(), rotation=0)

# Contagem de modelos por fase
ax = axes[1, 0]
counts = df.groupby('fase').size()
ax.bar(counts.index, counts.values, color=['#FF6B6B', '#4ECDC4', '#45B7D1'], alpha=0.7)
ax.set_title('Número de Modelos por Fase', fontweight='bold')
ax.set_ylabel('Contagem')
ax.set_xlabel('Fase')
for i, v in enumerate(counts.values):
    ax.text(i, v + 2, str(v), ha='center', fontweight='bold')
ax.grid(True, alpha=0.3, axis='y')

# Tabela resumida
ax = axes[1, 1]
ax.axis('tight')
ax.axis('off')

summary_table = [
    ['Métrica', 'R28', 'R29', 'R30'],
    ['AUC Médio', '0.567', '0.595', '0.499'],
    ['Boyce Médio', '0.829', '0.649', '0.218'],
    ['Omissão P10', '0.038', '0.220', '0.082'],
    ['N Modelos', '6', '4', '72'],
]

table = ax.table(cellText=summary_table, cellLoc='center', loc='center',
                colWidths=[0.25, 0.25, 0.25, 0.25])
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1, 2)

for i in range(len(summary_table)):
    for j in range(len(summary_table[0])):
        cell = table[(i, j)]
        if i == 0:
            cell.set_facecolor('#40466e')
            cell.set_text_props(weight='bold', color='white')
        else:
            cell.set_facecolor('#f0f0f0' if i % 2 == 0 else 'white')

plt.tight_layout()
plt.savefig(output_dir / '06_Resumo_Comparativo.png', dpi=150, bbox_inches='tight')
print(f"[OK] Grafico 6: {output_dir / '06_Resumo_Comparativo.png'}")
plt.close()

print(f"\n[DONE] Todos os gráficos salvos em: {output_dir}")
