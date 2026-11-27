# -*- coding: utf-8 -*-
"""Formatacao ABNT (NBR 14724, 6024, 6027, 6028, 6023, 10520) do TCC gerado pelo pandoc.
Uso: python abnt_formatar.py TCC_Milton_UFRA_V2.docx
Faz: capa, folha de rosto, folha de aprovacao, resumo/abstract, listas de ilustracoes,
tabelas e siglas, sumario (campos do Word), secoes com numeracao de pagina no canto
superior direito a partir da introducao (contando desde a folha de rosto), titulos,
legendas acima e fontes abaixo das ilustracoes e tabelas, tabelas/quadros e referencias."""
import sys, copy, re
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

ARQ = sys.argv[1]
d = Document(ARQ)
body = d.element.body
W = qn

# ------------------------------------------------------------------ estilos
def fonte(st, tam=12, negrito=None, italico=None):
    f = st.font; f.name = 'Times New Roman'; f.size = Pt(tam); f.color.rgb = RGBColor(0, 0, 0)
    if negrito is not None: f.bold = negrito
    if italico is not None: f.italic = italico
    rpr = st.element.get_or_add_rPr(); rf = rpr.find(W('w:rFonts'))
    if rf is None: rf = OxmlElement('w:rFonts'); rpr.insert(0, rf)
    for a in list(rf.attrib): del rf.attrib[a]
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'): rf.set(W(a), 'Times New Roman')

def par(st, alin=WD_ALIGN_PARAGRAPH.JUSTIFY, recuo=1.25, entre=1.5, antes=0, depois=0):
    pf = st.paragraph_format; pf.alignment = alin; pf.first_line_indent = Cm(recuo) if recuo else Cm(0)
    pf.left_indent = Cm(0); pf.line_spacing = entre; pf.space_before = Pt(antes); pf.space_after = Pt(depois)

S = d.styles
for nome in ('Normal', 'Body Text', 'First Paragraph'):
    try: st = S[nome]
    except KeyError: continue
    fonte(st); par(st)
for nome, neg, ita in (('Heading 1', True, False), ('Heading 2', True, False), ('Heading 3', False, True)):
    st = S[nome]; fonte(st, 12, neg, ita); par(st, WD_ALIGN_PARAGRAPH.LEFT, 0, 1.5, 18, 18)   # 1 linha de 1,5 antes e depois (NBR 14724:2024, 5.2.2)
    st.paragraph_format.keep_with_next = True
S['Heading 1'].paragraph_format.page_break_before = True   # secao primaria inicia em pagina nova

def novo_estilo(nome, tam, alin, entre=1.0, antes=0, depois=0, negrito=None):
    try: st = S[nome]
    except KeyError: st = S.add_style(nome, WD_STYLE_TYPE.PARAGRAPH); st.base_style = S['Normal']
    fonte(st, tam, negrito); par(st, alin, 0, entre, antes, depois); return st
LEG_IL = novo_estilo('Legenda Ilustracao', 10, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 12, 4)
LEG_TB = novo_estilo('Legenda Tabela', 10, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 12, 4)
FONTE = novo_estilo('Fonte ABNT', 10, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 4, 12)
REF = novo_estilo('Referencia ABNT', 12, WD_ALIGN_PARAGRAPH.LEFT, 1.0, 0, 12)
PRE = novo_estilo('Pre-textual', 12, WD_ALIGN_PARAGRAPH.CENTER, 1.5)
TIT_PRE = novo_estilo('Titulo pre-textual', 12, WD_ALIGN_PARAGRAPH.CENTER, 1.5, 0, 18, True)
RES = novo_estilo('Resumo ABNT', 12, WD_ALIGN_PARAGRAPH.JUSTIFY, 1.0, 0, 12)
for st in (LEG_IL, LEG_TB): st.paragraph_format.keep_with_next = True; st.paragraph_format.keep_together = True
# estilos do sumario e das listas (toc 1-3): sem recuo de primeira linha, espaco simples
stl = d.styles.element
for niv in (1, 2, 3, 4):
    nome_toc = 'toc %d' % niv
    el = next((s for s in stl.findall(W('w:style')) if (s.find(W('w:name')) is not None and s.find(W('w:name')).get(W('w:val')) == nome_toc)), None)
    if el is None:
        el = OxmlElement('w:style'); el.set(W('w:type'), 'paragraph'); el.set(W('w:styleId'), 'TOC%d' % niv)
        nm = OxmlElement('w:name'); nm.set(W('w:val'), nome_toc); el.append(nm)
        bo = OxmlElement('w:basedOn'); bo.set(W('w:val'), S['Normal'].style_id); el.append(bo); stl.append(el)
    for c in list(el):
        if c.tag in (W('w:pPr'), W('w:rPr')): el.remove(c)
    ppr = OxmlElement('w:pPr')
    tabs = OxmlElement('w:tabs'); tb = OxmlElement('w:tab'); tb.set(W('w:val'), 'right'); tb.set(W('w:leader'), 'dot'); tb.set(W('w:pos'), '9060'); tabs.append(tb); ppr.append(tabs)
    sp = OxmlElement('w:spacing'); sp.set(W('w:before'), '0'); sp.set(W('w:after'), '120'); sp.set(W('w:line'), '240'); sp.set(W('w:lineRule'), 'auto'); ppr.append(sp)
    ind = OxmlElement('w:ind'); ind.set(W('w:left'), '0'); ind.set(W('w:firstLine'), '0'); ind.set(W('w:right'), '400'); ppr.append(ind)
    jc = OxmlElement('w:jc'); jc.set(W('w:val'), 'left'); ppr.append(jc)
    el.append(ppr)
    rpr = OxmlElement('w:rPr')
    if niv == 1:
        b = OxmlElement('w:b'); rpr.append(b)
    if niv == 3:
        ii = OxmlElement('w:i'); rpr.append(ii)
    el.append(rpr)
LEG_IL.paragraph_format.keep_with_next = True
for st in (LEG_IL, LEG_TB):  # nivel de estrutura para as listas
    pass

def texto(el):
    return ''.join(x.text or '' for x in el.iter(W('w:t')))
def estilo_id(nome): return S[nome].style_id
def set_estilo(p_el, nome):
    ppr = p_el.find(W('w:pPr'))
    if ppr is None: ppr = OxmlElement('w:pPr'); p_el.insert(0, ppr)
    ps = ppr.find(W('w:pStyle'))
    if ps is None: ps = OxmlElement('w:pStyle'); ppr.insert(0, ps)
    ps.set(W('w:val'), estilo_id(nome))
def limpar_ppr(p_el, manter_estilo=True):
    ppr = p_el.find(W('w:pPr'))
    if ppr is None: return
    for c in list(ppr):
        if manter_estilo and c.tag == W('w:pStyle'): continue
        if c.tag in (W('w:sectPr'),): continue
        ppr.remove(c)

# ------------------------------------------------------------------ pre-textuais
filhos = list(body.iterchildren())
ANCORA = 'AGRADECIMENTOS' if any(k.tag == W('w:p') and texto(k).strip() == 'AGRADECIMENTOS' for k in filhos) else 'RESUMO'
i_res = next(i for i, k in enumerate(filhos) if k.tag == W('w:p') and texto(k).strip() == ANCORA)
for k in filhos[:i_res]:
    if k.tag != W('w:sectPr'): body.remove(k)
p_res = next(p for p in d.paragraphs if p.text.strip() == ANCORA)

TITULO = [('MODELAGEM AMBIENTAL PREDITIVA DA OCORRÊNCIA DE ', False), ('Handroanthus impetiginosus', True),
          (' E ', False), ('Handroanthus serratifolius', True),
          (' EM FLORESTAS NATIVAS SOB MANEJO FLORESTAL SUSTENTÁVEL NO ESTADO DO PARÁ', False)]
AUTOR = 'MILTON DA SILVA TAVARES NETO'
NATUREZA = ('Trabalho de Conclusão de Curso apresentado ao Curso de Engenharia Florestal da Universidade '
            'Federal Rural da Amazônia como requisito parcial para obtenção do grau de Bacharel em Engenharia Florestal.')

def antes(txt='', negrito=True, estilo='Pre-textual', runs=None, quebra=False, recuo_esq=None, alin=None, entre=None):
    p = p_res.insert_paragraph_before('', estilo)
    for t, it in (runs or [(txt, False)]):
        r = p.add_run(t); r.bold = negrito; r.italic = it
    if quebra: p.runs[-1].add_break(WD_BREAK.PAGE) if p.runs else p.add_run().add_break(WD_BREAK.PAGE)
    if recuo_esq is not None: p.paragraph_format.left_indent = Cm(recuo_esq)
    if alin is not None: p.paragraph_format.alignment = alin
    if entre is not None: p.paragraph_format.line_spacing = entre
    return p
def vazio(n):
    for _ in range(n): antes('')

# CAPA
for l in ('MINISTÉRIO DA EDUCAÇÃO', 'UNIVERSIDADE FEDERAL RURAL DA AMAZÔNIA', 'INSTITUTO DE CIÊNCIAS AGRÁRIAS',
          'CURSO DE ENGENHARIA FLORESTAL'):
    antes(l)
vazio(4); antes(AUTOR); vazio(5); antes(runs=TITULO); vazio(9)
antes('BELÉM – PA'); p_capa_fim = antes('2026')
# FOLHA DE ROSTO
antes(AUTOR); vazio(5); antes(runs=TITULO); vazio(3)
antes(NATUREZA, False, 'Resumo ABNT', recuo_esq=8, entre=1.0)
antes('Orientadora: Prof.ª Dra. Gracialda Costa Ferreira.', False, 'Resumo ABNT', recuo_esq=8, entre=1.0)
antes('Coorientadora: Prof.ª Dra. Julia Isabella de Matos Rodrigues.', False, 'Resumo ABNT', recuo_esq=8, entre=1.0)
vazio(6); antes('BELÉM – PA'); antes('2026', quebra=True)
# FOLHA DE APROVACAO
antes(AUTOR); vazio(2); antes(runs=TITULO); vazio(2)
antes(NATUREZA, False, 'Resumo ABNT', recuo_esq=8, entre=1.0); vazio(1)
antes('Aprovado em: ____/____/________.', False, alin=WD_ALIGN_PARAGRAPH.LEFT); vazio(1)
antes('BANCA EXAMINADORA')
for nome, papel in (('Prof.ª Dra. Gracialda Costa Ferreira', 'Orientadora'),
                    ('Prof.(ª) Dr.(ª) ', 'Membro'), ('Prof.(ª) Dr.(ª) ', 'Membro')):
    vazio(1); antes('_' * 45, False, entre=1.0)
    antes(f'{nome} – {papel}', False, entre=1.0); antes('Universidade Federal Rural da Amazônia', False, entre=1.0)
antes('', quebra=True)

# RESUMO / ABSTRACT
def fmt_resumo(titulo, pchave):
    pt = next(p for p in d.paragraphs if p.text.strip() == titulo)
    set_estilo(pt._p, 'Titulo pre-textual'); limpar_ppr(pt._p)
    for r in pt.runs: r.bold = True
    if pt._p is not p_res._p: pt.paragraph_format.page_break_before = True
    el = pt._p.getnext()
    while el is not None and el.tag == W('w:p'):
        set_estilo(el, 'Resumo ABNT'); limpar_ppr(el)
        if texto(el).startswith(pchave): break
        el = el.getnext()
fmt_resumo('RESUMO', 'Palavras-chave'); fmt_resumo('ABSTRACT', 'Keywords')
if ANCORA == 'AGRADECIMENTOS':   # titulo centralizado; texto em 1,5 com recuo (elemento opcional, NBR 14724:2024)
    set_estilo(p_res._p, 'Titulo pre-textual'); limpar_ppr(p_res._p)
    for r in p_res.runs: r.bold = True
p_kw = next(p for p in d.paragraphs if p.text.startswith('Keywords'))

# ------------------------------------------------------------------ campos (sumario e listas)
def campo(p, instr):
    def fc(tipo):
        r = OxmlElement('w:r'); f = OxmlElement('w:fldChar'); f.set(W('w:fldCharType'), tipo); r.append(f); return r
    r_i = OxmlElement('w:r'); it = OxmlElement('w:instrText'); it.set(qn('xml:space'), 'preserve'); it.text = instr; r_i.append(it)
    r_t = OxmlElement('w:r'); tt = OxmlElement('w:t'); tt.text = 'Clique com o botão direito e escolha "Atualizar campo".'; r_t.append(tt)
    for x in (fc('begin'), r_i, fc('separate'), r_t, fc('end')): p._p.append(x)

primeiro_h1 = next(p for p in d.paragraphs if p.style.name == 'Heading 1')
def bloco(titulo, instr=None, linhas=None):
    pt = primeiro_h1.insert_paragraph_before(titulo, 'Titulo pre-textual'); pt.runs[0].bold = True
    pt.paragraph_format.page_break_before = True
    if instr:
        pc = primeiro_h1.insert_paragraph_before('', 'Resumo ABNT'); pc.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
        campo(pc, instr)
    for sig, sig_txt in (linhas or []):
        pl = primeiro_h1.insert_paragraph_before('', 'Resumo ABNT'); pl.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
        pl.paragraph_format.tab_stops.add_tab_stop(Cm(3)); pl.paragraph_format.space_after = Pt(4)
        pl.paragraph_format.left_indent = Cm(3); pl.paragraph_format.first_line_indent = Cm(-3)
        pl.add_run(sig + '\t' + sig_txt)
bloco('LISTA DE ILUSTRAÇÕES', ' TOC \\h \\z \\t "Legenda Ilustracao;4" ')
bloco('LISTA DE TABELAS', ' TOC \\h \\z \\t "Legenda Tabela;4" ')
SIGLAS = [('ACT', 'Acordo de Cooperação Técnica'), ('AUC', 'Área sob a curva ROC'),
          ('BIO12', 'Precipitação anual'), ('BIO17', 'Precipitação do trimestre mais seco'),
          ('CHELSA', 'Climatologies at High Resolution for the Earth’s Land Surface Areas'),
          ('CITES', 'Convenção sobre o Comércio Internacional das Espécies da Flora e Fauna Selvagens em Perigo de Extinção'),
          ('DAP', 'Diâmetro à altura do peito'), ('IBGE', 'Instituto Brasileiro de Geografia e Estatística'),
          ('L', 'Feature linear'), ('LOPO', 'Validação deixando uma propriedade de fora (leave-one-property-out)'),
          ('LQ', 'Features linear e quadrática'), ('LQH', 'Features linear, quadrática e hinge'),
          ('MaxEnt', 'Máxima entropia'), ('MTP', 'Mínima presença de treino'),
          ('P10', 'Limiar de 10% de omissão das presenças de treino'), ('PMFS', 'Plano de Manejo Florestal Sustentável'),
          ('RM', 'Multiplicador de regularização'), ('ROC', 'Receiver Operating Characteristic'),
          ('UFRA', 'Universidade Federal Rural da Amazônia'), ('UPA', 'Unidade de Produção Anual'),
          ('VIF', 'Fator de inflação da variância')]
bloco('LISTA DE ABREVIATURAS E SIGLAS', linhas=SIGLAS)
bloco('SUMÁRIO', ' TOC \\o "1-3" \\h \\z \\u ')

# ------------------------------------------------------------------ secoes e numeracao de pagina
sect_final = body.find(W('w:sectPr'))
def quebra_secao(p_el, inicio=None):
    """coloca um sectPr (fim de secao, proxima pagina) no paragrafo p_el"""
    s = copy.deepcopy(sect_final)
    for c in list(s):
        if c.tag in (W('w:headerReference'), W('w:footerReference'), W('w:pgNumType'), W('w:titlePg')): s.remove(c)
    tp = s.find(W('w:type'))
    if tp is None: tp = OxmlElement('w:type'); s.insert(0, tp)
    tp.set(W('w:val'), 'nextPage')
    if inicio:
        pn = OxmlElement('w:pgNumType'); pn.set(W('w:start'), str(inicio)); s.append(pn)
    ppr = p_el.find(W('w:pPr'))
    if ppr is None: ppr = OxmlElement('w:pPr'); p_el.insert(0, ppr)
    ppr.append(s)
# secao 1 = capa (termina no "2026" da capa); secao 2 = folha de rosto ate o sumario (inicia em 1)
quebra_secao(p_capa_fim._p)
ult_pre = primeiro_h1._p.getprevious()
quebra_secao(ult_pre, inicio=None)
# a secao 2 comeca na folha de rosto: o sectPr que fecha a secao 2 recebe start=1
for old in sect_final.findall(W('w:pgNumType')): sect_final.remove(old)
def por_pgnum(sp_el, start):
    pn = OxmlElement('w:pgNumType'); pn.set(W('w:start'), str(start))
    ref = next((c for c in sp_el if c.tag in (W('w:cols'), W('w:formProt'), W('w:vAlign'), W('w:noEndnote'), W('w:titlePg'), W('w:textDirection'), W('w:bidi'), W('w:rtlGutter'), W('w:docGrid'), W('w:printerSettings'))), None)
    if ref is not None: ref.addprevious(pn)
    else: sp_el.append(pn)
por_pgnum(ult_pre.find(W('w:pPr')).find(W('w:sectPr')), 1)
# a ultima secao (textual) continua a contagem; cabecalho com o numero a direita
sec = d.sections[-1]
sec.header_distance = Cm(2); sec.header.is_linked_to_previous = False
hp = sec.header.paragraphs[0]; hp.text = ''; hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
hp.paragraph_format.first_line_indent = Cm(0)
campo(hp, ' PAGE ');
for r in hp.runs: r.font.size = Pt(10); r.font.name = 'Times New Roman'
# remove o texto provisorio do campo PAGE
for t in hp._p.iter(W('w:t')): t.text = ''
for s in d.sections: s.top_margin = Cm(3); s.left_margin = Cm(3); s.bottom_margin = Cm(2); s.right_margin = Cm(2)
# secoes anteriores sem cabecalho proprio (herdariam o da ultima no Word? nao: herdam da anterior). Garante cabecalho vazio:
for s in d.sections[:-1]:
    s.header.is_linked_to_previous = False
    for p in s.header.paragraphs: p.text = ''

# ------------------------------------------------------------------ titulos sem numero centralizados
for p in d.paragraphs:
    if p.style.name == 'Heading 1':
        if not re.match(r'^\d', p.text.strip()):
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if p._p is primeiro_h1._p: p.paragraph_format.page_break_before = False
        if re.match(r'^\d', p.text.strip()): p.paragraph_format.space_before = Pt(0)   # secao primaria no alto da pagina
# titulos com mais de uma linha: 2a linha alinhada sob a 1a letra da 1a palavra (recuo deslocado = largura do indicativo)
for p in d.paragraphs:
    if p.style.name in ('Heading 1', 'Heading 2', 'Heading 3'):
        m = re.match(r'^(\d+(?:\.\d+)*) ', p.text)
        if m:
            num = m.group(1); pts = 6 * sum(ch.isdigit() for ch in num) + 3 * num.count('.') + 3   # Times 12: algarismo 6 pt, ponto e espaco 3 pt
            p.paragraph_format.left_indent = Pt(pts); p.paragraph_format.first_line_indent = Pt(-pts)

# ------------------------------------------------------------------ ilustracoes
def dividir_fonte(p_el):
    """separa 'Fonte: ...' do fim da legenda; devolve o novo paragrafo (ou None)"""
    runs = [r for r in p_el.iter(W('w:r'))]
    for k, r in enumerate(runs):
        t = r.find(W('w:t'))
        if t is not None and t.text and 'Fonte:' in t.text:
            antes_t, depois_t = t.text.split('Fonte:', 1)
            t.text = antes_t.rstrip(); t.set(qn('xml:space'), 'preserve')
            np_ = OxmlElement('w:p'); ppr = OxmlElement('w:pPr'); np_.append(ppr)
            nr = copy.deepcopy(r); nr.find(W('w:t')).text = 'Fonte:' + depois_t
            nr.find(W('w:t')).set(qn('xml:space'), 'preserve'); np_.append(nr)
            for r2 in runs[k + 1:]: np_.append(r2)
            set_estilo(np_, 'Fonte ABNT')
            for rr in np_.iter(W('w:r')):
                rp = rr.find(W('w:rPr'))
                if rp is not None:
                    for b in rp.findall(W('w:b')): rp.remove(b)
            return np_
    return None

n_fig = 0
for el in list(body.iterchildren()):
    if el.tag != W('w:p'): continue
    ps = el.find('.//' + W('w:pStyle')); sid = ps.get(W('w:val')) if ps is not None else ''
    if sid == 'CaptionedFigure':
        leg = el.getnext()
        if leg is None or 'Figura' not in texto(leg)[:12]: continue
        fon = dividir_fonte(leg)
        el.addprevious(leg); set_estilo(leg, 'Legenda Ilustracao'); limpar_ppr(leg)
        leg.find(W('w:pPr')).append(OxmlElement('w:keepNext')); leg.find(W('w:pPr')).append(OxmlElement('w:keepLines'))
        if fon is not None: el.addnext(fon)
        limpar_ppr(el); ppr = el.find(W('w:pPr'))
        jc = OxmlElement('w:jc'); jc.set(W('w:val'), 'center'); ppr.append(jc)
        ind = OxmlElement('w:ind'); ind.set(W('w:firstLine'), '0'); ppr.append(ind)
        kn = OxmlElement('w:keepNext'); ppr.insert(1, kn)
        # titulo e fonte acompanham as margens da ilustracao (NBR 14724:2024, 5.8)
        ext = el.find('.//{http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing}extent')
        if ext is not None:
            larg_cm = int(ext.get('cx')) / 360000.0
            if larg_cm < 15.8:
                rec = Cm((16 - larg_cm) / 2)
                for q in (leg, fon):
                    if q is None: continue
                    qp = q.find(W('w:pPr')) if q.find(W('w:pPr')) is not None else OxmlElement('w:pPr')
                    if q.find(W('w:pPr')) is None: q.insert(0, qp)
                    ind2 = OxmlElement('w:ind'); ind2.set(W('w:left'), str(int(rec.twips if hasattr(rec, 'twips') else rec / 635))); ind2.set(W('w:right'), ind2.get(W('w:left'))); ind2.set(W('w:firstLine'), '0')
                    qp.append(ind2)
        n_fig += 1

# ------------------------------------------------------------------ tabelas e quadros
def borda(cell, lados):
    tcPr = cell._tc.get_or_add_tcPr()
    for old in tcPr.findall(W('w:tcBorders')): tcPr.remove(old)
    b = OxmlElement('w:tcBorders'); tcPr.append(b)
    for lado in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']:
        e = OxmlElement('w:' + lado)
        if lado in lados: e.set(W('w:val'), 'single'); e.set(W('w:sz'), '8'); e.set(W('w:color'), '000000')
        else: e.set(W('w:val'), 'nil')
        b.append(e)
n_tab = n_qua = 0
for t in d.tables:
    ant = t._tbl.getprevious(); leg_txt = texto(ant) if ant is not None else ''
    quadro = leg_txt.startswith('Quadro')
    if leg_txt.startswith(('Tabela', 'Quadro')):
        set_estilo(ant, 'Legenda Ilustracao' if quadro else 'Legenda Tabela'); limpar_ppr(ant)
        n_qua += quadro; n_tab += not quadro
    pos = t._tbl.getnext()
    if pos is not None and pos.tag == W('w:p') and texto(pos).startswith('Fonte:'):
        set_estilo(pos, 'Fonte ABNT'); limpar_ppr(pos)
    tblPr = t._tbl.tblPr
    for old in tblPr.findall(W('w:tblBorders')): tblPr.remove(old)
    jc = tblPr.find(W('w:jc'))
    if jc is None: jc = OxmlElement('w:jc'); tblPr.append(jc)
    jc.set(W('w:val'), 'center')
    LARG = 9070  # 16 cm em twips
    ncol = len(t.columns)
    peso = []
    for j in range(ncol):
        tam = [max((len(w) for w in t.cell(i, j).text.split()), default=1) for i in range(len(t.rows))]
        tot = [len(t.cell(i, j).text) for i in range(len(t.rows))]
        peso.append(max(max(tam) * 1.0, min(sorted(tot)[len(tot) // 2] * 0.6 + 2, 40), 4))
    # largura minima de cada coluna = maior palavra (Times 10: ~105 twips por caractere) + margens da celula
    minimo = [max(max((len(w) for w in t.cell(i, j).text.split()), default=1) for i in range(len(t.rows))) * 105 + 260 for j in range(ncol)]
    if sum(minimo) >= LARG: larg = [int(LARG * m / sum(minimo)) for m in minimo]
    else:
        resto = LARG - sum(minimo); larg = [int(m + resto * w / sum(peso)) for m, w in zip(minimo, peso)]
    if quadro and ncol == 4:   # Quadro 1: programa, versao, finalidade, referencia
        larg = [int(LARG * f) for f in (0.20, 0.11, 0.40, 0.29)]
    tw = tblPr.find(W('w:tblW'))
    if tw is None: tw = OxmlElement('w:tblW'); tblPr.append(tw)
    tw.set(W('w:type'), 'dxa'); tw.set(W('w:w'), str(LARG))
    lay = tblPr.find(W('w:tblLayout'))
    if lay is None: lay = OxmlElement('w:tblLayout'); tblPr.append(lay)
    lay.set(W('w:type'), 'fixed')
    grid = t._tbl.find(W('w:tblGrid'))
    for gc, wv in zip(grid.findall(W('w:gridCol')), larg): gc.set(W('w:w'), str(wv))
    for row in t.rows:
        for j, c in enumerate(row.cells[:ncol]):
            tcPr = c._tc.get_or_add_tcPr(); tcw = tcPr.find(W('w:tcW'))
            if tcw is None: tcw = OxmlElement('w:tcW'); tcPr.insert(0, tcw)
            tcw.set(W('w:type'), 'dxa'); tcw.set(W('w:w'), str(larg[j]))
    n = len(t.rows)
    for i, row in enumerate(t.rows):
        if i == 0:  # repete o cabecalho em tabelas que mudam de pagina
            trPr = row._tr.get_or_add_trPr(); h = OxmlElement('w:tblHeader'); trPr.append(h)
        for c in row.cells:
            if quadro: lados = ['top', 'bottom', 'left', 'right']
            else:
                lados = []
                if i == 0: lados += ['top', 'bottom']
                if i == n - 1: lados += ['bottom']
            borda(c, lados)
            for p in c.paragraphs:
                pf = p.paragraph_format
                pf.space_before = Pt(1); pf.space_after = Pt(1); pf.first_line_indent = Cm(0); pf.line_spacing = 1.0
                if p.alignment in (None, WD_ALIGN_PARAGRAPH.JUSTIFY): p.alignment = WD_ALIGN_PARAGRAPH.LEFT
                if n <= 15: pf.keep_with_next = True   # tabela curta nao se divide entre paginas
                for r in p.runs: r.font.size = Pt(10); r.font.name = 'Times New Roman'
                if i == 0:
                    for r in p.runs: r.bold = True

# ------------------------------------------------------------------ referencias
dentro = False
for p in d.paragraphs:
    if p.style.name == 'Heading 1':
        dentro = p.text.strip() == 'REFERÊNCIAS'; continue
    if dentro and p.text.strip():
        set_estilo(p._p, 'Referencia ABNT'); limpar_ppr(p._p)
# nota explicativa do apendice A (siglas da tabela) sem recuo
for p in d.paragraphs:
    if p.text.startswith('Alt: altitude; Decl:'):
        set_estilo(p._p, 'Fonte ABNT'); limpar_ppr(p._p)

# ------------------------------------------------------------------ atualizar campos ao abrir
st = d.settings.element
uf = st.find(W('w:updateFields'))
if uf is None: uf = OxmlElement('w:updateFields'); st.append(uf)
uf.set(W('w:val'), 'true')
d.core_properties.title = 'Modelagem ambiental preditiva da ocorrência de Handroanthus impetiginosus e Handroanthus serratifolius'
d.core_properties.author = 'Milton da Silva Tavares Neto'
d.save(ARQ)
print(f'ok: {n_fig} figuras, {n_tab} tabelas, {n_qua} quadro(s), {len(d.sections)} secoes')
