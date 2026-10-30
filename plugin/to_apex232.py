#!/usr/bin/env python3
"""Genera la variante APEX 23.2 del plugin a partir del export nativo 26.1.
Uso: python3 to_apex232.py <export_26.sql> <salida_232.sql> [workspace_id app_id owner] [--ids-from export_232_anterior.sql]
--ids-from: reutiliza los IDs del export 23.2 anterior (plugin, atributos por secuencia, valores por return_value),
para que el import reemplace el plugin existente y los DAs conserven sus valores.
Cambios: header 23.2, sin p_apexlang_name / p_static_id, attributes.get_varchar2('x') -> attribute_NN,
render v1 (javascript_function + attribute_01..07). El JS no cambia."""
import re, sys
args = sys.argv[1:]
ref = None
if '--ids-from' in args:
    k = args.index('--ids-from'); ref = args[k + 1]; del args[k:k + 2]
src, dst = args[0], args[1]
ws, app, owner = (args[2:5] if len(args) >= 5 else ('5173173563302459', '100', 'AQS'))
def idmap(t):
    """clave semántica -> id"""
    m = {}
    pid = re.search(r"create_plugin\(\n p_id=>wwv_flow_imp\.id\((\d+)\)", t).group(1); m['plugin'] = pid
    for a in re.finditer(r"create_plugin_attribute\(\n p_id=>wwv_flow_imp\.id\((\d+)\)(.*?)\n\);", t, re.S):
        m['att:' + re.search(r"p_attribute_sequence=>(\d+)", a.group(2)).group(1)] = a.group(1)
    att_seq = {v: k for k, v in m.items() if k.startswith('att:')}
    for v in re.finditer(r"create_plugin_attr_value\(\n p_id=>wwv_flow_imp\.id\((\d+)\)\n,p_plugin_attribute_id=>wwv_flow_imp\.id\((\d+)\)(.*?)\n\);", t, re.S):
        m['val:' + att_seq[v.group(2)] + ':' + re.search(r"p_return_value=>'([^']*)'", v.group(3)).group(1)] = v.group(1)
    for f in re.finditer(r"create_plugin_file\(\n p_id=>wwv_flow_imp\.id\((\d+)\)(.*?)\n\);", t, re.S):
        m['file:' + re.search(r"p_file_name=>'([^']*)'", f.group(2)).group(1)] = f.group(1)
    return m
s = open(src, encoding='utf-8').read()
def sub1(pat, rep, flags=0):
    global s
    s2, n = re.subn(pat, rep, s, flags=flags)
    assert n >= 1, pat
    s = s2
sub1(r"p_version_yyyy_mm_dd=>'[^']*'", "p_version_yyyy_mm_dd=>'2023.10.31'")
sub1(r"p_release=>'[^']*'", "p_release=>'23.2.0'")
sub1(r"p_default_workspace_id=>\d+", "p_default_workspace_id=>" + ws)
sub1(r"p_default_application_id=>\d+", "p_default_application_id=>" + app)
sub1(r"p_default_owner=>'[^']*'", "p_default_owner=>'" + owner + "'")
sub1(r"\n,p_apexlang_name=>'[^']*'", "")
sub1(r"\n,p_static_id=>'[^']*'", "")
# secuencia de cada atributo (static_id del export 26.1)
SEQ = {'sources': 1, 'layout': 2, 'format': 3, 'output': 4, 'items': 5, 'pdf_action': 6, 'report_query': 11,
       'template_url': 7, 'message': 8, 'origin': 9, 'resolver': 10}
# render v1
RENDER = """'function render(p_dynamic_action in apex_plugin.t_dynamic_action,',
'                p_plugin         in apex_plugin.t_plugin)',
'    return apex_plugin.t_dynamic_action_render_result is',
'    l_r    apex_plugin.t_dynamic_action_render_result;',
'    l_init varchar2(32767) := trim(p_dynamic_action.init_javascript_code);',
'begin',
'    apex_javascript.add_library(p_name => ''novareport'', p_directory => p_plugin.file_prefix,',
'                                p_check_to_add_minified => false);',
unistr('    -- APEX 23.2 (API v1): configuraci\\00F3n en this.action.attributeNN; origen e init en el objeto'),
'    l_r.ajax_identifier := apex_plugin.get_ajax_identifier;',
'    l_r.attribute_01 := p_dynamic_action.attribute_02;  -- layout',
'    l_r.attribute_02 := p_dynamic_action.attribute_03;  -- format',
'    l_r.attribute_03 := p_dynamic_action.attribute_04;  -- output',
'    l_r.attribute_04 := p_dynamic_action.attribute_05;  -- items',
'    l_r.attribute_05 := p_dynamic_action.attribute_06;  -- pdf_action',
'    l_r.attribute_06 := p_dynamic_action.attribute_07;  -- template_url',
'    l_r.attribute_07 := p_dynamic_action.attribute_08;  -- message',
'    l_r.javascript_function := ''function(){novaReport.da.call(this,{origin:''',
'        || apex_javascript.add_value(nvl(p_dynamic_action.attribute_09, ''attributes''), false)',
'        || case when l_init is not null then '',init:'' || l_init end',
'        || ''});}'';',
'    return l_r;',
'end render;',
"""
sub1(r"'function render\(p_dynamic_action.*?'end render;',\n", lambda m: RENDER, re.S)
def att(m):
    k = m.group(1)
    assert k in SEQ, k
    return 'p_dynamic_action.attribute_%02d' % SEQ[k]
sub1(r"p_dynamic_action\.attributes\.get_varchar2\(''([a-z_]+)''\)", att)
if ref:
    old, new = idmap(open(ref, encoding='utf-8').read()), idmap(s)
    assert set(old) <= set(new), set(old) - set(new)
    tr = {new[k]: old[k] for k in new if k in old}   # componentes nuevos conservan su ID del export 26.1
    s = re.sub(r"wwv_flow_imp\.id\((\d+)\)", lambda m: "wwv_flow_imp.id(%s)" % tr.get(m.group(1), m.group(1)), s)
    s = re.sub(r"(--     PLUGIN: )(\d+)", lambda m: m.group(1) + tr.get(m.group(2), m.group(2)), s)
s = re.sub(r"prompt APPLICATION \d+ - .*", "prompt APPLICATION " + app, s)
s = re.sub(r"(--   Application:     )\d+", r"\g<1>" + app, s)
s = re.sub(r"(--   Version:         )(\S+)", r"\g<1>23.2.0 (adaptado desde \2)", s)
s = s.replace("unistr('-- novaReport: c\\00F3digo PL/SQL del plugin (render + ajax)'),", "unistr('-- novaReport: c\\00F3digo PL/SQL del plugin (render + ajax) - APEX 23.2'),")
assert 'attributes.get_' not in s and 'function_param' not in s and 'apexlang' not in s and 'p_static_id' not in s
open(dst, 'w', encoding='utf-8').write(s)
print('ok', dst)
