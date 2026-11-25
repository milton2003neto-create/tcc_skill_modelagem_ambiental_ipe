#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Consolidação de resultados R28, R29, R30
TCC Ipês - Modelagem Ambiental
"""

import pandas as pd
import numpy as np
from pathlib import Path

# Caminhos
base_path = Path(r"C:\Users\jotac\Downloads\TCC MILTON\TCC - Ipes - Inicio do zero\05 - Modelagem no R")

r28_metrics = base_path / r"R28_TCC_IPES_6_MODELOS_LOCAIS_V1_1_CORRIGIDO" / "03_RESULTADOS_R28_V1_1" / "28_METRICAS_6_MODELOS.csv"
r29_metrics = base_path / r"R29_TCC_IPES_BOYCE_RECIPROCOS_V1" / "03_RESULTADOS_R29_V1" / "02_TESTES_RECIPROCOS" / "29_METRICAS_4_RECIPROCOS.csv"
r30_metrics = base_path / r"R30_TCC_IPES_GRADE_72_UPAS_V1" / "03_RESULTADOS_R30_GRADE_72" / "30_METRICAS_72_AVALIACOES.csv"

# Leitura
print("Lendo R28...")
df_r28 = pd.read_csv(r28_metrics)
print(f"R28: {len(df_r28)} modelos")

print("Lendo R29...")
df_r29 = pd.read_csv(r29_metrics)
print(f"R29: {len(df_r29)} modelos recíprocos")

print("Lendo R30...")
df_r30 = pd.read_csv(r30_metrics)
print(f"R30: {len(df_r30)} avaliações")

# Adicionar coluna de fase
df_r28['fase'] = 'R28'
df_r29['fase'] = 'R29'
df_r30['fase'] = 'R30'

# Estandardizar colunas de interesse
print("\n" + "="*70)
print("RESUMO POR FASE")
print("="*70)

for fase, df in [('R28', df_r28), ('R29', df_r29), ('R30', df_r30)]:
    print(f"\n{fase}:")
    print(f"  Modelos: {len(df)}")

    if 'auc_validacao_b2' in df.columns:
        col_auc = 'auc_validacao_b2'
    elif 'auc_validacao' in df.columns:
        col_auc = 'auc_validacao'
    else:
        col_auc = None

    if col_auc:
        print(f"  AUC validação: {df[col_auc].mean():.4f} ± {df[col_auc].std():.4f}")
        print(f"    Min: {df[col_auc].min():.4f}, Max: {df[col_auc].max():.4f}")

    if 'boyce_validacao' in df.columns:
        print(f"  Boyce: {df['boyce_validacao'].mean():.4f} ± {df['boyce_validacao'].std():.4f}")

    if 'omissao_p10_validacao' in df.columns:
        print(f"  Omissão P10: {df['omissao_p10_validacao'].mean():.4f} ± {df['omissao_p10_validacao'].std():.4f}")

# Sumário por espécie
print("\n" + "="*70)
print("RESUMO POR ESPÉCIE")
print("="*70)

for fase, df in [('R28', df_r28), ('R29', df_r29), ('R30', df_r30)]:
    print(f"\n{fase}:")
    if 'especie' in df.columns:
        for esp in df['especie'].unique():
            df_esp = df[df['especie'] == esp]
            print(f"  {esp}: {len(df_esp)} modelos")

# Comparação R28 vs R29 vs R30 (apenas R28_..._LQH_RM4 que aparecem em todos)
print("\n" + "="*70)
print("COMPARAÇÃO LQH RM4 (R28 vs R30)")
print("="*70)

# R28 tem 6 modelos LQH RM4
# R30 tem os mesmos 6 reutilizados (marcados como REAPROVEITAR_R28)

r28_lqh_rm4 = df_r28[[('auc_validacao_b2' if 'auc_validacao_b2' in df_r28.columns else 'auc_validacao' if 'auc_validacao' in df_r28.columns else 'auc')]]

print("\nModelos LQH RM4 em R30 (reaproverados de R28):")
r30_lqh_rm4 = df_r30[df_r30['origem'] == 'REAPROVEITAR_R28']
print(r30_lqh_rm4[['id', 'especie', 'cenario_id', 'auc_validacao_b2', 'boyce_validacao', 'omissao_p10_validacao']])

print("\nModelos LQH RM4 novos em R30 (exploratoriedade de features/RM):")
r30_lqh_novos = df_r30[(df_r30['features'] == 'lqh') & (df_r30['origem'] == 'AJUSTAR_R30')]
print(f"Total novos LQH: {len(r30_lqh_novos)}")
if len(r30_lqh_novos) > 0:
    print(f"  AUC: {r30_lqh_novos['auc_validacao_b2'].mean():.4f}")
    print(f"  Boyce: {r30_lqh_novos['boyce_validacao'].mean():.4f}")

# Exploração da grade R30
print("\n" + "="*70)
print("EXPLORAÇÃO DA GRADE R30 (72 MODELOS)")
print("="*70)

r30_summary = df_r30.groupby(['especie', 'features']).agg({
    'auc_validacao_b2': ['mean', 'std', 'min', 'max'],
    'boyce_validacao': ['mean', 'std'],
    'omissao_p10_validacao': ['mean', 'std']
}).round(4)

print("\nAUC por features (Ipê-roxo):")
r30_roxo = df_r30[df_r30['especie'] == 'Ipe-roxo'].groupby('features')['auc_validacao_b2'].agg(['mean', 'count'])
print(r30_roxo)

print("\nAUC por features (Ipê-amarelo):")
r30_amarelo = df_r30[df_r30['especie'] == 'Ipe-amarelo'].groupby('features')['auc_validacao_b2'].agg(['mean', 'count'])
print(r30_amarelo)

print("\n" + "="*70)
print("ARQUIVO CONSOLIDADO GERADO")
print("="*70)

# Salvar sumário
output_path = base_path.parent / "00_CONSOLIDACAO_R28_R29_R30.csv"

# Criar tabela consolidada simples
consolidado = []

# R28
for _, row in df_r28.iterrows():
    consolidado.append({
        'fase': 'R28',
        'id': row['id'],
        'especie': row['especie'],
        'cenario': row['cenario_id'],
        'features': row.get('features', 'lqh'),
        'rm': row.get('RM', 4),
        'auc_validacao': row.get('auc_validacao_b2', np.nan),
        'boyce': row.get('boyce_validacao', np.nan),
        'omissao_p10': row.get('omissao_p10_validacao', np.nan),
        'n_modelos_fase': 6
    })

# R29
for _, row in df_r29.iterrows():
    consolidado.append({
        'fase': 'R29',
        'id': row['id'],
        'especie': row['especie'],
        'cenario': row['cenario_id'],
        'features': 'lqh',
        'rm': 4,
        'auc_validacao': row.get('auc_validacao', np.nan),
        'boyce': row.get('boyce_validacao', np.nan),
        'omissao_p10': row.get('omissao_p10_validacao', np.nan),
        'n_modelos_fase': 4
    })

# R30 (amostra)
for _, row in df_r30.iterrows():
    consolidado.append({
        'fase': 'R30',
        'id': row['id'],
        'especie': row['especie'],
        'cenario': row['cenario_id'],
        'features': row['features'],
        'rm': row['RM'],
        'auc_validacao': row.get('auc_validacao_b2', np.nan),
        'boyce': row.get('boyce_validacao', np.nan),
        'omissao_p10': row.get('omissao_p10_validacao', np.nan),
        'n_modelos_fase': 72
    })

df_consolidado = pd.DataFrame(consolidado)
df_consolidado.to_csv(output_path, index=False)
print(f"\nTabela consolidada salva em: {output_path}")

print(f"\nTotal de modelos processados: {len(df_consolidado)}")
print(f"  R28: {len(df_consolidado[df_consolidado['fase'] == 'R28'])}")
print(f"  R29: {len(df_consolidado[df_consolidado['fase'] == 'R29'])}")
print(f"  R30: {len(df_consolidado[df_consolidado['fase'] == 'R30'])}")
