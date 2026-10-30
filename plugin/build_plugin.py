#!/usr/bin/env python3
"""
novaReport - actualiza el export del plugin con el código fuente actual.

  python3 plugin/build_plugin.py [--app 118 --offset N --out archivo.sql]

Toma src/plugin.plsql (PL/SQL Code) y src/novareport.min.js (archivo novareport.js)
y los vuelve a escribir dentro de plugin/dynamic_action_plugin_com_novacode_novareport.sql,
junto con la versión de src/novareport.js. Con --app genera además un script listo para
instalar el plugin en esa aplicación (apex_application_install).
"""
import argparse
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EXPORT = os.path.join(HERE, 'dynamic_action_plugin_com_novacode_novareport.sql')
WS_ID = 9121565152053401
OWNER = 'WKSP_AQS'


def sq(s):
    if all(ord(c) < 128 for c in s):
        return "'" + s.replace("'", "''") + "'"
    out = []
    for c in s:
        if c == '\\':
            out.append('\\005C')
        elif c == "'":
            out.append("''")
        elif ord(c) < 128:
            out.append(c)
        else:
            out.append('\\%04X' % ord(c))
    return "unistr('" + ''.join(out) + "')"


def plsql_block(path):
    lines = open(path, encoding='utf-8').read().rstrip('\n').split('\n') + ['']
    return 'wwv_flow_string.join(wwv_flow_t_varchar2(\n' + ',\n'.join(sq(l) for l in lines) + '))'


def js_table(path):
    hx = open(path, 'rb').read().hex().upper()
    out = ['begin\nwwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;\n']
    for i, n in enumerate(range(0, len(hx), 200), 1):
        out.append("wwv_flow_imp.g_varchar2_table(%d) := '%s';\n" % (i, hx[n:n + 200]))
    out.append('null;\nend;\n/\n')
    return ''.join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--app', type=int)
    ap.add_argument('--offset', type=int, default=0)
    ap.add_argument('--out')
    a = ap.parse_args()

    s = open(EXPORT, encoding='utf-8').read()
    ver = re.search(r"var VERSION = '([0-9.]+)'", open(os.path.join(ROOT, 'src', 'novareport.js'), encoding='utf-8').read()).group(1)

    # PL/SQL Code
    i = s.index(',p_plsql_code=>')
    j = s.index('\n,p_api_version=>', i)
    s = s[:i] + ',p_plsql_code=>' + plsql_block(os.path.join(ROOT, 'src', 'plugin.plsql')) + s[j:]
    # versión del plugin y de los archivos (cambia la URL del JS)
    s = re.sub(r",p_version_identifier=>'[^']*'", ",p_version_identifier=>'%s'" % ver, s)
    fv = int(re.search(r',p_files_version=>(\d+)', s).group(1))
    old = bytes.fromhex(''.join(re.findall(r"g_varchar2_table\(\d+\) := '([0-9A-F]+)'", s)))
    if old != open(os.path.join(ROOT, 'src', 'novareport.min.js'), 'rb').read():
        fv += 1     # el JS cambió: nueva URL del archivo
        s = re.sub(r',p_files_version=>\d+', ',p_files_version=>%d' % fv, s)
    # archivo novareport.js
    i = s.index('begin\nwwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;')
    j = s.index('null;\nend;\n/\n', i) + len('null;\nend;\n/\n')
    s = s[:i] + js_table(os.path.join(ROOT, 'src', 'novareport.min.js')) + s[j:]
    open(EXPORT, 'w', encoding='utf-8').write(s)
    print('plugin %s, files_version %d -> %s' % (ver, fv, os.path.relpath(EXPORT, ROOT)))

    if a.app:
        pre = """begin
  apex_application_install.clear_all;
  apex_application_install.set_workspace_id(%d);
  apex_application_install.set_application_id(%d);
  apex_application_install.set_offset(%d);
  apex_application_install.set_schema('%s');
end;
/

""" % (WS_ID, a.app, a.offset, OWNER)
        body = s.replace('whenever sqlerror exit sql.sqlcode rollback', 'whenever sqlerror continue none')
        out = a.out or os.path.join(ROOT, 'test', 'out', 'deploy', '%d_plugin.sql' % a.app)
        open(out, 'w', encoding='utf-8').write(pre + body + '\nbegin apex_application_install.clear_all; end;\n/\n')
        print('-> ' + os.path.relpath(out, ROOT))


if __name__ == '__main__':
    main()
