/*!
 * novaReport 1.11.0 - Reportes PDF / Excel / Word para Oracle APEX
 * https://github.com/danielramirezasyn/novareport - Licencia MIT
 * NovaCode - plugin de Acción Dinámica COM.NOVACODE.NOVAREPORT
 *
 * Motor de layout: un mismo diseño (JSON) y unas mismas fuentes SQL generan
 * PDF (jsPDF + autotable), Excel con estilos (ExcelJS), Word (docx) o Word desde
 * plantilla (docxtemplater). Modo lote: un archivo por documento en un ZIP (JSZip).
 */
window.novaReport = (function () {
  'use strict';

  var VERSION = '1.11.0';

  /* ------------------------------------------------------------------ librerías */
  var LIBS = {
    jspdf:         { url: 'https://cdnjs.cloudflare.com/ajax/libs/jspdf/4.2.1/jspdf.umd.min.js',
                     ok: function () { return !!(window.jspdf && window.jspdf.jsPDF); } },
    autotable:     { url: 'https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.4/jspdf.plugin.autotable.min.js',
                     ok: function () { return !!(window.jspdf && window.jspdf.jsPDF && window.jspdf.jsPDF.API.autoTable); } },
    exceljs:       { url: 'https://cdnjs.cloudflare.com/ajax/libs/exceljs/4.4.0/exceljs.min.js',
                     ok: function () { return !!window.ExcelJS; } },
    jszip:         { url: 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js',
                     ok: function () { return !!window.JSZip; } },
    docx:          { url: 'https://cdn.jsdelivr.net/npm/docx@9.5.1/dist/index.iife.js',
                     ok: function () { return !!(window.docx && window.docx.Document); } },
    pizzip:        { url: 'https://cdn.jsdelivr.net/npm/pizzip@3.1.8/dist/pizzip.min.js',
                     ok: function () { return !!window.PizZip; } },
    docxtemplater: { url: 'https://cdn.jsdelivr.net/npm/docxtemplater@3.60.0/build/docxtemplater.min.js',
                     ok: function () { return !!window.docxtemplater; } },
    qrcode:        { url: 'https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.js',
                     ok: function () { return typeof window.qrcode === 'function'; } },
    chartjs:       { url: 'https://cdn.jsdelivr.net/npm/chart.js@4.4.9/dist/chart.umd.js',
                     ok: function () { return !!(window.Chart && window.Chart.register); } }
  };
  var NEEDS = { pdf: ['jspdf', 'autotable'], xlsx: ['exceljs'], docx: ['docx'],
                'docx-template': ['pizzip', 'docxtemplater'], zip: ['jszip'] };

  function loadScript(url) {
    return new Promise(function (resolve, reject) {
      /* Si la página usa RequireJS (p. ej. JET), las UMD se registrarían como módulos AMD */
      var amd = window.define;
      window.define = undefined;
      var s = document.createElement('script');
      s.src = url;
      s.onload = function () { window.define = amd; resolve(); };
      s.onerror = function () { window.define = amd; reject(new Error('No se pudo cargar la librería: ' + url)); };
      document.head.appendChild(s);
    });
  }
  function ensure(names) {
    return names.reduce(function (p, n) {
      return p.then(function () { return LIBS[n].ok() ? null : loadScript(imgUrl(LIBS[n].url)); });
    }, Promise.resolve());
  }

  /* ------------------------------------------------------------------ utilidades */
  var THEME = { primary: '#1F4E79', headText: '#FFFFFF', zebra: '#F5F7FA', totals: '#E6ECF2',
                text: '#000000', muted: '#787878', fontSize: 7, group: '#DCE6F0' };

  function isNum(v) { return typeof v === 'number' && !isNaN(v); }
  function hexRgb(h) {
    h = String(h || '#000000').replace('#', '');
    if (h.length === 3) { h = h.replace(/(.)/g, '$1$1'); }
    return [parseInt(h.substr(0, 2), 16), parseInt(h.substr(2, 2), 16), parseInt(h.substr(4, 2), 16)];
  }
  function argb(h) { return 'FF' + String(h || '#000000').replace('#', '').toUpperCase(); }
  function hexNo(h) { return String(h || '#000000').replace('#', '').toUpperCase(); }
  function pad(n) { return (n < 10 ? '0' : '') + n; }
  function now() {
    var d = new Date();
    return pad(d.getDate()) + '/' + pad(d.getMonth() + 1) + '/' + d.getFullYear() + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
  }
  function today() { return now().substr(0, 10); }
  function label(col) { var s = String(col).toLowerCase().replace(/_/g, ' '); return s.charAt(0).toUpperCase() + s.slice(1); }
  function parseDate(s) {
    var m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(String(s || ''));
    return m ? new Date(Date.UTC(+m[3], +m[2] - 1, +m[1])) : null;
  }
  function safeName(s) { return String(s || 'archivo').replace(/[\\\/:*?"<>|]+/g, '_').trim(); }

  function fmt(v, f) {
    if (v === null || v === undefined || v === '') { return ''; }
    if (!f) { return String(v); }
    var p = f.split(':'), k = p[0];
    if (k === 'money' || k === 'num') {
      var d = p[1] !== undefined ? +p[1] : 2, n = Number(v);
      return isNaN(n) ? String(v) : n.toLocaleString('en-US', { minimumFractionDigits: d, maximumFractionDigits: d });
    }
    if (k === 'int') { return isNaN(Number(v)) ? String(v) : Math.round(Number(v)).toLocaleString('en-US'); }
    if (k === 'pct') { return fmt(v, 'num:' + (p[1] || 2)) + '%'; }
    if (k === 'upper') { return String(v).toUpperCase(); }
    if (k === 'lower') { return String(v).toLowerCase(); }
    if (k === 'yn') { return v === 'Y' || v === 'S' ? 'Sí' : (v === 'N' ? 'No' : String(v)); }
    if (k === 'letras') { return isNaN(Number(v)) ? String(v) : letras(Number(v), p.slice(1).join(':')); }
    return String(v);
  }
  /* Formatos que siempre producen texto (Excel no deja el número) */
  function textFmt(f) { return /^(upper|lower|yn|letras)(:|$)/.test(f || ''); }

  /* Monto en letras: letras -> MIL DOSCIENTOS TREINTA Y CUATRO CON 50/100; letras:BALBOA/BALBOAS -> ... BALBOAS CON 50/100 */
  var L_U = ['', 'UN', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE', 'DIEZ', 'ONCE', 'DOCE', 'TRECE',
             'CATORCE', 'QUINCE', 'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE', 'VEINTE', 'VEINTIÚN', 'VEINTIDÓS',
             'VEINTITRÉS', 'VEINTICUATRO', 'VEINTICINCO', 'VEINTISÉIS', 'VEINTISIETE', 'VEINTIOCHO', 'VEINTINUEVE'];
  var L_D = ['', '', '', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'];
  var L_C = ['', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS',
             'OCHOCIENTOS', 'NOVECIENTOS'];
  function letras999(n) {
    if (n === 100) { return 'CIEN'; }
    var c = Math.floor(n / 100), r = n % 100, out = [];
    if (c) { out.push(L_C[c]); }
    if (r) { out.push(r < 30 ? L_U[r] : L_D[Math.floor(r / 10)] + (r % 10 ? ' Y ' + L_U[r % 10] : '')); }
    return out.join(' ');
  }
  function letrasEntero(n) {
    if (n === 0) { return 'CERO'; }
    var out = [], g = [[1e12, 'BILLÓN', 'BILLONES'], [1e6, 'MILLÓN', 'MILLONES']];
    g.forEach(function (x) {
      var q = Math.floor(n / x[0]);
      if (q) { out.push(q === 1 ? 'UN ' + x[1] : letrasEntero(q) + ' ' + x[2]); n -= q * x[0]; }
    });
    var m = Math.floor(n / 1000), u = n % 1000;
    if (m) { out.push(m === 1 ? 'MIL' : letras999(m) + ' MIL'); }
    if (u) { out.push(letras999(u)); }
    return out.join(' ');
  }
  function letras(v, moneda) {
    var neg = v < 0, c = Math.round(Math.abs(v) * 100), e = Math.floor(c / 100), d = c % 100;
    var t = letrasEntero(e);
    if (!moneda) { t = t.replace(/ÚN$/, 'UNO').replace(/ UN$|^UN$/, function (x) { return x + 'O'; }); }
    else {
      if (/(MILLÓN|MILLONES|BILLÓN|BILLONES)$/.test(t)) { t += ' DE'; }
      var mm = String(moneda).toUpperCase().split('/');          // letras:BALBOA/BALBOAS = singular/plural
      t += ' ' + (e === 1 && mm.length > 1 ? mm[0] : mm[mm.length - 1]);
    }
    return (neg ? 'MENOS ' : '') + t + ' CON ' + (d < 10 ? '0' : '') + d + '/100';
  }

  /* ------------------------------------------------------------------ contexto y plantillas */
  function getItem(name) {
    try { return window.apex && apex.item ? apex.item(name).getValue() : ''; } catch (e) { return ''; }
  }
  function lookup(ctx, key, row) {
    var up = String(key).toUpperCase(), i = up.indexOf('.');
    if (i > 0) {
      var sc = up.substr(0, i), col = up.substr(i + 1);
      if (sc === 'DOC') { return ctx.doc ? ctx.doc[col] : undefined; }
      if (sc === 'PARAM') { return ctx.params ? ctx.params[col] : undefined; }
      if (sc === 'ITEM') { return getItem(col); }
      var r = (ctx.S[sc] || [])[0];
      return r ? r[col] : undefined;
    }
    if (up === 'NOW') { return now(); }
    if (up === 'TODAY') { return today(); }
    if (up === 'PAGE' || up === 'PAGES') { return '{' + up + '}'; }
    if (row && Object.prototype.hasOwnProperty.call(row, up)) { return row[up]; }
    if (ctx.doc && Object.prototype.hasOwnProperty.call(ctx.doc, up)) { return ctx.doc[up]; }
    return ctx.params ? ctx.params[up] : undefined;
  }
  function tpl(str, ctx, row) {
    if (str === null || str === undefined) { return ''; }
    return String(str).replace(/\{([A-Za-z0-9_$#.]+)(?:\|([A-Za-z0-9:/ÁÉÍÓÚÑÜáéíóúñü]+))?\}/g, function (m, k, f) {
      var v = lookup(ctx, k, row);
      return v === undefined || v === null ? '' : fmt(v, f);
    });
  }
  /* Condiciones simples: COL == 'X' && OTRA != 2 || !COL3 */
  function literal(s) {
    s = s.trim();
    if (/^'.*'$/.test(s) || /^".*"$/.test(s)) { return s.slice(1, -1); }
    if (s === 'null') { return null; }
    if (s !== '' && !isNaN(Number(s))) { return Number(s); }
    return undefined;
  }
  function atom(a, ctx, row) {
    var m = /^\s*(!?)\s*([A-Za-z0-9_$#.]+)\s*(==|!=|>=|<=|>|<)?\s*(.*)$/.exec(a);
    if (!m) { return false; }
    var v = lookup(ctx, m[2], row);
    if (!m[3]) { var t = !(v === null || v === undefined || v === '' || v === 0 || v === 'N'); return m[1] ? !t : t; }
    var l = literal(m[4]);
    if (l === undefined) { l = lookup(ctx, m[4].trim(), row); }
    var eq = (v === null || v === undefined || v === '') ? (l === null || l === '') : String(v) === String(l);
    switch (m[3]) {
      case '==': return eq;
      case '!=': return !eq;
      case '>': return Number(v) > Number(l);
      case '<': return Number(v) < Number(l);
      case '>=': return Number(v) >= Number(l);
      case '<=': return Number(v) <= Number(l);
    }
    return false;
  }
  function cond(expr, ctx, row) {
    if (expr === undefined || expr === null || expr === '') { return true; }
    if (typeof expr === 'function') { return !!expr(row, ctx); }
    return String(expr).split('||').some(function (o) {
      return o.split('&&').every(function (a) { return atom(a, ctx, row); });
    });
  }
  function rowsOf(sec, ctx) {
    var rows = ctx.S[String(sec.source || '').toUpperCase()] || [];
    return sec.filter ? rows.filter(function (r) { return cond(sec.filter, ctx, r); }) : rows;
  }
  function colorOf(c, ctx, row) {
    if (!c) { return null; }
    if (typeof c === 'string') { return c; }
    var v = lookup(ctx, c.by, row);
    return (c.values && c.values[v]) || c['default'] || null;
  }
  function styleOf(rules, ctx, row) {
    var out = null;
    (rules || []).some(function (r) { if (cond(r.when, ctx, row)) { out = r; return true; } return false; });
    return out;
  }

  /* Texto enriquecido:
     **negrita**  *cursiva*  ***ambas***  ~~tachado~~  ++subrayado++
     [f=times]...[/f] (helvetica | times | courier)   [c=#AA1E1E]...[/c] color   \* escapa */
  var FONTS = { helvetica: ['helvetica', 'Arial'], arial: ['helvetica', 'Arial'], times: ['times', 'Times New Roman'],
                serif: ['times', 'Times New Roman'], courier: ['courier', 'Courier New'], mono: ['courier', 'Courier New'] };
  function fontKey(f) { f = String(f || 'helvetica').toLowerCase(); return FONTS[f] ? f : 'helvetica'; }
  function richRuns(s, base) {
    base = base || {};
    var out = [], st = { b: false, i: false, u: false, s: false }, fonts = [base.font || 'helvetica'], colors = [base.color || null];
    var buf = '', k = 0, m;
    s = String(s === null || s === undefined ? '' : s);
    function push() {
      if (buf) { out.push({ t: buf, b: st.b, i: st.i, u: st.u, s: st.s, f: fontKey(fonts[fonts.length - 1]), c: colors[colors.length - 1] }); buf = ''; }
    }
    while (k < s.length) {
      var rest = s.substr(k);
      if (rest.charAt(0) === '\\' && rest.length > 1) { buf += rest.charAt(1); k += 2; continue; }
      if ((m = /^\[f=([A-Za-z]+)\]/.exec(rest))) { push(); fonts.push(m[1]); k += m[0].length; continue; }
      if (rest.substr(0, 4) === '[/f]') { push(); if (fonts.length > 1) { fonts.pop(); } k += 4; continue; }
      if ((m = /^\[c=(#[0-9A-Fa-f]{3,6})\]/.exec(rest))) { push(); colors.push(m[1]); k += m[0].length; continue; }
      if (rest.substr(0, 4) === '[/c]') { push(); if (colors.length > 1) { colors.pop(); } k += 4; continue; }
      if (rest.substr(0, 3) === '***') { push(); st.b = !st.b; st.i = !st.i; k += 3; continue; }
      if (rest.substr(0, 2) === '**') { push(); st.b = !st.b; k += 2; continue; }
      if (rest.substr(0, 2) === '~~') { push(); st.s = !st.s; k += 2; continue; }
      if (rest.substr(0, 2) === '++') { push(); st.u = !st.u; k += 2; continue; }
      if (rest.charAt(0) === '*') { push(); st.i = !st.i; k += 1; continue; }
      buf += rest.charAt(0); k++;
    }
    push();
    return out;
  }
  function paragraphsOf(sec, ctx) {
    var row = sec.source ? rowsOf(sec, ctx)[0] : null;
    var src = Array.isArray(sec.text) ? sec.text : String(sec.text === undefined ? '' : sec.text).split('\n');
    return src.map(function (p) { return tpl(p, ctx, row); });
  }
  function plainOf(runs) { return runs.map(function (r) { return r.t; }).join(''); }

  /* Columnas: definidas o automáticas desde los tipos de la fuente */
  function columnsOf(sec, ctx, rows) {
    var src = String(sec.source || '').toUpperCase(), types = ctx.T[src] || {};
    var cols = sec.columns;
    if (!cols || !cols.length) {
      cols = Object.keys(types).filter(function (c) { return c !== 'DOC_KEY'; }).map(function (c) { return { col: c }; });
    }
    cols = cols.filter(function (c) { return typeof c === 'string' || !c.when || cond(c.when, ctx, null); });
    return cols.map(function (c) {
      c = typeof c === 'string' ? { col: c } : c;
      var name = c.col ? String(c.col).toUpperCase() : null, t = name ? types[name] : null, f = c.fmt;
      if (!f && t === 'NUMBER' && !c.value) {
        f = rows.some(function (r) { return isNum(r[name]) && Math.round(r[name]) !== r[name]; }) ? 'money' : null;
      }
      return { col: name, value: c.value, label: c.label !== undefined ? c.label : label(name || ''),
               fmt: f, map: c.map, bold: !!c.bold, width: c.width,
               align: c.align || (textFmt(f) ? 'left' : (t === 'NUMBER' || f === 'money' || f === 'int' || f === 'num' ? 'right' : (t === 'DATE' || f === 'date' ? 'center' : 'left'))),
               cellStyle: c.cellStyle, color: c.color,
               isNum: !textFmt(f) && ((t === 'NUMBER' && !c.map && !c.value) || f === 'money' || f === 'int' || /^num/.test(f || '')) };
    });
  }
  function groupsOf(sec, cols) {
    var out = [], used = 0;
    (sec.groups || []).forEach(function (g) {
      var n = Math.max(1, Math.min(g.cols || 1, cols.length - used));
      if (used < cols.length) { out.push({ label: g.label || '', cols: n, from: used, gap: !g.label }); used += n; }
    });
    if (used < cols.length) { out.push({ label: '', cols: cols.length - used, from: used, gap: true }); }
    return out;
  }
  function cellRaw(c, row, ctx) {
    if (c.value !== undefined) { return tpl(c.value, ctx, row); }
    var v = row[c.col];
    if (c.map && v !== null && v !== undefined && c.map[v] !== undefined) { return c.map[v]; }
    return v;
  }
  function cellText(c, row, ctx) {
    var v = cellRaw(c, row, ctx);
    return c.map && c.map[row[c.col]] !== undefined ? String(v) : fmt(v, c.fmt);
  }
  /* Totales y subtotales: ["COL"] (suma) o [{ "col": "COL", "fn": "sum|avg|min|max|count" }] */
  var AGG_XL = { sum: 9, avg: 1, min: 5, max: 4, count: 3 };               // código de SUBTOTAL() en Excel
  var AGG_FX = { sum: 'SUM', avg: 'AVERAGE', min: 'MIN', max: 'MAX', count: 'COUNTA' };
  var AGG_PRE = { avg: 'Prom.', min: 'Mín.', max: 'Máx.', count: 'Cant.' };
  function aggList(a) {
    return (Array.isArray(a) ? a : []).map(function (x) {
      var o = x && typeof x === 'object' ? x : { col: x }, f = String(o.fn || 'sum').toLowerCase();
      return { col: String(o.col || '').toUpperCase(), fn: AGG_XL[f] ? f : 'sum' };
    }).filter(function (x) { return x.col; });
  }
  function aggFind(list, col) {
    for (var i = 0; i < list.length; i++) { if (list[i].col === col) { return list[i]; } }
    return null;
  }
  function aggMixed(list) { return list.some(function (x) { return x.fn !== 'sum'; }); }
  function numLike(v) { return isNum(v) || (typeof v === 'string' && v.trim() !== '' && !isNaN(Number(v))); }
  /* Valor del agregado; min/max devuelven el valor original (número, fecha o texto) */
  function aggValue(rows, col, fn) {
    var vals = rows.map(function (r) { return r[col]; }).filter(function (v) { return v !== null && v !== undefined && v !== ''; });
    if (fn === 'count') { return vals.length; }
    if (fn === 'sum' || fn === 'avg') {
      var nums = vals.filter(numLike).map(Number), t = nums.reduce(function (a, b) { return a + b; }, 0);
      return fn === 'sum' ? t : (nums.length ? t / nums.length : null);
    }
    var best = null, bk = null;
    vals.forEach(function (v) {
      var d = numLike(v) ? null : parseDate(v), k = numLike(v) ? Number(v) : (d ? d.getTime() : String(v));
      if (bk === null || (fn === 'min' ? k < bk : k > bk)) { best = v; bk = k; }
    });
    return best;
  }
  function aggText(c, a, rows, mixed) {
    var v = aggValue(rows, a.col, a.fn), t;
    if (v === null || v === undefined) { t = ''; }
    else if (a.fn === 'count') { t = fmt(v, 'int'); }
    else if (a.fn === 'min' || a.fn === 'max') { t = numLike(v) ? fmt(v, c.fmt || 'money') : fmt(v, c.fmt); }
    else if (a.fn === 'avg') { t = fmt(v, c.fmt && c.fmt !== 'int' ? c.fmt : 'money'); }
    else { t = fmt(v, c.fmt || 'money'); }
    return t && mixed && AGG_PRE[a.fn] ? AGG_PRE[a.fn] + ' ' + t : t;
  }
  /* Fila de totales: at = primera columna con agregado; el texto ocupa las columnas 0..at-1
     (si at = 0 el texto va en su propia fila, encima de los valores) */
  function aggRow(cols, list, rows, text) {
    var mixed = aggMixed(list), at = -1;
    var cells = cols.map(function (c, i) {
      var a = c.col ? aggFind(list, c.col) : null;
      if (a && at < 0) { at = i; }
      return a ? aggText(c, a, rows, mixed) : '';
    });
    return { at: at < 0 ? cols.length : at, cells: cells, text: text };
  }
  /* Texto de la fila de totales: plantilla; {COUNT} = filas de la tabla */
  function totText(sec, ctx, rows) { return tpl(sec.totalsLabel || 'Totales', ctx, { COUNT: rows.length }); }
  /* Filas de AutoTable para un aggRow */
  function pdfAgg(ar, n) {
    var lab = { content: ar.text, colSpan: ar.at || n, styles: { halign: 'left' } };
    return ar.at === 0 ? [[lab], ar.cells.slice()] : [[lab].concat(ar.cells.slice(ar.at))];
  }
  /* Quiebres: "breakBy" agrupa filas consecutivas con el mismo valor (la consulta debe venir ordenada).
     Devuelve la lista a dibujar: { k: 'head' | 'row' | 'sub', r: fila, rows: filas del grupo, i: n.º de fila de datos } */
  function subCols(sec) { return sec.breakTotals === false ? [] : aggList(Array.isArray(sec.breakTotals) ? sec.breakTotals : sec.totals); }
  function tableItems(sec, rows) {
    if (!sec.breakBy || !rows.length) { return rows.map(function (r, i) { return { k: 'row', r: r, i: i }; }); }
    var bc = String(sec.breakBy).toUpperCase(), out = [], g = null, i = 0, withSub = subCols(sec).length > 0;
    function close() { if (g && withSub) { out.push({ k: 'sub', r: g.r, rows: g.rows }); } }
    rows.forEach(function (r) {
      var key = String(r[bc] === null || r[bc] === undefined ? '' : r[bc]);
      if (!g || g.key !== key) {
        close();
        g = { key: key, r: r, rows: [] };
        if (sec.breakTitle !== false) { out.push({ k: 'head', r: r, rows: g.rows }); }
      }
      g.rows.push(r);
      out.push({ k: 'row', r: r, i: i++ });
    });
    close();
    return out;
  }
  /* Texto de encabezado / subtotal de un grupo: plantilla con la primera fila del grupo y {COUNT} */
  function breakText(sec, it, ctx) {
    var r = {}, k, bc = String(sec.breakBy).toUpperCase();
    for (k in it.r) { r[k] = it.r[k]; }
    r.COUNT = it.rows.length;
    var t = it.k === 'head' ? sec.breakTitle : sec.breakLabel;
    if (t === undefined || t === null || t === true) { t = it.k === 'head' ? '{' + bc + '}' : 'Subtotal {' + bc + '}'; }
    return tpl(t, ctx, r);
  }
  function fieldText(f, ctx, row) {
    if (f.map) { var k = lookup(ctx, String(f.value).replace(/[{}]/g, '').split('|')[0], row); return f.map[k] !== undefined ? f.map[k] : String(k || ''); }
    var v = f.value;
    if (f.fmt && /^\{[^}|]+\}$/.test(v || '')) { return fmt(lookup(ctx, v.slice(1, -1), row), f.fmt); }
    return tpl(v, ctx, row);
  }
  function sectionsFor(layout, format, ctx) {
    return (layout.sections || []).filter(function (s) { return (!s.formats || s.formats.indexOf(format) >= 0) && (!ctx || shown(s, ctx)); });
  }
  /* Columnas: 1 a 3 casillas lado a lado. Dentro solo van secciones que no dependen de la página completa. */
  var CELL_TYPES = { ficha: 1, texto: 1, imagen: 1, codigo: 1, alerta: 1, linea: 1, tabla: 1, grafico: 1, espacio: 1 };
  function fitCell(c, w) {
    var o = {}, k;
    for (k in c) { if (Object.prototype.hasOwnProperty.call(c, k)) { o[k] = c[k]; } }
    ['x', 'y', 'x1', 'y1', 'x2', 'y2'].forEach(function (p) { delete o[p]; });
    if (o.type === 'imagen') { o._maxW = w; }
    if (o.type === 'grafico') {
      var gw = o.width || 120, gh = o.height || 70;
      if (gw > w) { o.width = w; o.height = gh * w / gw; }
    }
    if (o.type === 'codigo') {
      if (String(o.kind || 'qr').toLowerCase() === 'qr' && (o.size || 30) > w) { o.size = w; }
      if (o.width && o.width > w) { o.width = w; }
    }
    if ((o.type === 'linea' || o.type === 'texto') && o.width && o.width > w) { o.width = w; }
    return o;
  }
  /* Casillas de una sección columnas: [{ x, w, secs }] con x y w en mm dentro de un ancho disponible */
  function cellsOf(sec, format, ctx, avail) {
    var cols = (Array.isArray(sec.cols) ? sec.cols : []).slice(0, 3), n = cols.length;
    if (!n) { return []; }
    var ws = cols.map(function (x, i) { var v = Number((sec.widths || [])[i]); return v > 0 ? v : 100 / n; });
    var sum = ws.reduce(function (a, b) { return a + b; }, 0), cg = sec.colGap !== undefined ? Number(sec.colGap) : 4;
    var free = avail - cg * (n - 1), x = 0;
    return cols.map(function (list, i) {
      var w = free * ws[i] / sum;
      var secs = (Array.isArray(list) ? list : []).filter(function (c) {
        return c && CELL_TYPES[c.type] && (!c.formats || c.formats.indexOf(format) >= 0) && shown(c, ctx);
      }).map(function (c) { return fitCell(c, w); });
      var o = { x: x, w: w, secs: secs };
      x += w + cg;
      return o;
    });
  }
  /* when de la sección: contra el documento, los parámetros y {FUENTE.COL}. En alerta, when es por fila. */
  function shown(s, ctx) { return s.type === 'alerta' || !s.when || cond(s.when, ctx, null); }
  function themeOf(layout) {
    var t = {}, k;
    for (k in THEME) { t[k] = THEME[k]; }
    var o = (layout.page && layout.page.theme) || {};
    for (k in o) { t[k] = o[k]; }
    return t;
  }

  /* ================================================================== imágenes */
  var IMG = {}, CW = {};
  function imgUrl(u) {
    var env = (window.apex && apex.env) || {};
    return String(u || '').replace('#APP_FILES#', env.APP_FILES || '').replace('#APP_IMAGES#', env.APP_FILES || '')
      .replace('#WORKSPACE_FILES#', env.WORKSPACE_FILES || '').replace('#IMAGE_PREFIX#', env.APEX_FILES || '');
  }
  function imgDims(buf) {
    var b = new Uint8Array(buf);
    if (b[0] === 0x89 && b[1] === 0x50) { return { w: (b[16] << 24 | b[17] << 16 | b[18] << 8 | b[19]) >>> 0, h: (b[20] << 24 | b[21] << 16 | b[22] << 8 | b[23]) >>> 0, ext: 'png' }; }
    if (b[0] === 0xFF && b[1] === 0xD8) {
      var i = 2;
      while (i < b.length) {
        if (b[i] !== 0xFF) { i++; continue; }
        var m = b[i + 1], len = b[i + 2] << 8 | b[i + 3];
        if (m >= 0xC0 && m <= 0xCF && m !== 0xC4 && m !== 0xC8 && m !== 0xCC) { return { h: b[i + 5] << 8 | b[i + 6], w: b[i + 7] << 8 | b[i + 8], ext: 'jpg' }; }
        i += 2 + len;
      }
    }
    throw new Error('Formato de imagen no soportado (use PNG o JPG).');
  }
  function toB64(buf) {
    var b = new Uint8Array(buf), s = '', CH = 0x8000;
    for (var i = 0; i < b.length; i += CH) { s += String.fromCharCode.apply(null, b.subarray(i, i + CH)); }
    return btoa(s);
  }
  function imagesOf(layout) {
    var out = [];
    function scan(list) { (list || []).forEach(function (s) { if (s && s.type === 'imagen' && s.url && !s.field) { out.push(s.url); } if (s && s.type === 'columnas') { (s.cols || []).forEach(scan); } }); }
    scan(layout.sections);
    if (layout.batch && layout.batch.summary) { scan(layout.batch.summary.sections); if (layout.batch.summary.layout) { scan(layout.batch.summary.layout.sections); } }
    return out;
  }
  function preloadImages(layout) {
    return Promise.all(imagesOf(layout).map(function (u) {
      var url = imgUrl(u);
      if (IMG[url]) { return null; }
      return fetch(url, { credentials: 'same-origin' }).then(function (r) {
        if (!r.ok) { throw new Error('No se pudo cargar la imagen ' + url + ' (' + r.status + ')'); }
        return r.arrayBuffer();
      }).then(function (buf) {
        var d = imgDims(buf);
        IMG[url] = { buf: buf, w: d.w, h: d.h, ext: d.ext, data: 'data:image/' + (d.ext === 'jpg' ? 'jpeg' : 'png') + ';base64,' + toB64(buf) };
      });
    }));
  }
  /* Imagen desde una columna BLOB (llega en base64) o un data URL */
  function imgFromB64(v) {
    var s = String(v).replace(/^data:[^,]*,/, '').replace(/\s+/g, '');
    if (!s) { return null; }
    var key = 'b64:' + s.length + ':' + s.substr(0, 64) + s.substr(-64);
    if (IMG[key]) { return IMG[key]; }
    var bin = atob(s), u = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) { u[i] = bin.charCodeAt(i); }
    var d = imgDims(u.buffer);
    IMG[key] = { buf: u.buffer, w: d.w, h: d.h, ext: d.ext, data: 'data:image/' + (d.ext === 'jpg' ? 'jpeg' : 'png') + ';base64,' + s };
    return IMG[key];
  }
  function imgOf(sec, ctx) {
    if (sec.field) {
      var r = (sec.source ? rowsOf(sec, ctx)[0] : ctx.doc) || {}, v = r[String(sec.field).toUpperCase()];
      try { return v ? imgFromB64(v) : null; } catch (e) { if (window.console) { console.warn('novaReport: imagen inválida en ' + sec.field, e); } return null; }
    }
    return IMG[imgUrl(sec.url)] || null;
  }
  function imgSize(sec, im) {
    var w = sec.width || 40, h = sec.height || (w * im.h / im.w);
    if (!sec.width && sec.height) { w = h * im.w / im.h; }
    if (sec._maxW && w > sec._maxW) { h = h * sec._maxW / w; w = sec._maxW; }
    return { w: w, h: h };
  }
  function b64ToBuf(s) {
    var bin = atob(s), u = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) { u[i] = bin.charCodeAt(i); }
    return u.buffer;
  }
  /* Imagen generada (gráfico, código, marca de agua) a partir de un data URL PNG */
  function pngImg(url, w, h) {
    return { buf: b64ToBuf(url.replace(/^data:[^,]*,/, '')), data: url, w: w, h: h, ext: 'png' };
  }
  function newCanvas(w, h) {
    if (typeof document === 'undefined' || !document.createElement) { throw new Error('Se requiere un navegador (canvas) para generar gráficos.'); }
    var c = document.createElement('canvas');
    c.width = w; c.height = h;
    return c;
  }

  /* ================================================================== PNG mínimo (1 bit, paleta) para códigos */
  var CRC = null;
  function crc32(u) {
    if (!CRC) {
      CRC = [];
      for (var n = 0; n < 256; n++) { var c = n; for (var k = 0; k < 8; k++) { c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; } CRC[n] = c >>> 0; }
    }
    var x = 0xFFFFFFFF;
    for (var i = 0; i < u.length; i++) { x = CRC[(x ^ u[i]) & 255] ^ (x >>> 8); }
    return (x ^ 0xFFFFFFFF) >>> 0;
  }
  function be32(n) { return [n >>> 24 & 255, n >>> 16 & 255, n >>> 8 & 255, n & 255]; }
  function pngChunk(type, data) {
    var t = [type.charCodeAt(0), type.charCodeAt(1), type.charCodeAt(2), type.charCodeAt(3)];
    var body = new Uint8Array(4 + data.length);
    body.set(t, 0); body.set(data, 4);
    var out = new Uint8Array(12 + data.length);
    out.set(be32(data.length), 0); out.set(body, 4); out.set(be32(crc32(body)), 8 + data.length);
    return out;
  }
  /* dark(x, y) -> true pinta el píxel con "color"; el resto queda blanco */
  function png1(w, h, dark, color) {
    var rl = Math.ceil(w / 8) + 1, raw = new Uint8Array(rl * h), x, y;
    for (y = 0; y < h; y++) { for (x = 0; x < w; x++) { if (dark(x, y)) { raw[y * rl + 1 + (x >> 3)] |= 0x80 >> (x & 7); } } }
    var nb = Math.ceil(raw.length / 65535), z = new Uint8Array(2 + raw.length + nb * 5 + 4), p = 2, a = 1, b = 0, i;
    z[0] = 0x78; z[1] = 0x01;
    for (i = 0; i < nb; i++) {  /* deflate sin compresión (bloques "stored"); docx/xlsx ya comprimen el ZIP */
      var st = i * 65535, len = Math.min(65535, raw.length - st);
      z[p++] = i === nb - 1 ? 1 : 0; z[p++] = len & 255; z[p++] = len >> 8; z[p++] = ~len & 255; z[p++] = (~len >> 8) & 255;
      z.set(raw.subarray(st, st + len), p); p += len;
    }
    for (i = 0; i < raw.length; i++) { a = (a + raw[i]) % 65521; b = (b + a) % 65521; }
    z.set(be32(((b << 16) | a) >>> 0), p);
    var ihdr = new Uint8Array(13), rgb = hexRgb(color || '#000000');
    ihdr.set(be32(w), 0); ihdr.set(be32(h), 4); ihdr[8] = 1; ihdr[9] = 3;
    var parts = [new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]), pngChunk('IHDR', ihdr),
                 pngChunk('PLTE', new Uint8Array([255, 255, 255, rgb[0], rgb[1], rgb[2]])), pngChunk('IDAT', z), pngChunk('IEND', new Uint8Array(0))];
    var tot = parts.reduce(function (s, q) { return s + q.length; }, 0), png = new Uint8Array(tot), o = 0;
    parts.forEach(function (q) { png.set(q, o); o += q.length; });
    return { buf: png.buffer, data: 'data:image/png;base64,' + toB64(png.buffer), w: w, h: h, ext: 'png' };
  }

  /* ================================================================== códigos: QR y Code 128 */
  var C128 = ('212222 222122 222221 121223 121322 131222 122213 122312 132212 221213 221312 231212 112232 122132 122231 113222 ' +
    '123122 123221 223211 221132 221231 213212 223112 312131 311222 321122 321221 312212 322112 322211 212123 212321 232121 ' +
    '111323 131123 131321 112313 132113 132311 211313 231113 231311 112133 112331 132131 113123 113321 133121 313121 211331 ' +
    '231131 213113 213311 213131 311123 311321 331121 312113 312311 332111 314111 221411 431111 111224 111422 121124 121421 ' +
    '141122 141221 112214 112412 122114 122411 142112 142211 241211 221114 413111 241112 134111 111242 121142 121241 114212 ' +
    '124112 124211 411212 421112 421211 212141 214121 412121 111143 111341 131141 114113 114311 411113 411311 113141 114131 ' +
    '311141 411131 211412 211214 211232 2331112').split(' ');
  /* Code 128 (B y C automáticos): devuelve los módulos (true = barra) */
  function code128(s) {
    s = String(s).replace(/[^\x20-\x7E]/g, '?');
    var toks = [], m, re = /(\d{4,})|([^\d]+|\d{1,3})/g;
    while ((m = re.exec(s))) {
      if (m[1] || (/^\d+$/.test(s) && s.length % 2 === 0)) {
        var d = m[0], ev = d.length - d.length % 2;
        toks.push({ set: 'C', t: d.substr(0, ev) });
        if (ev < d.length) { toks.push({ set: 'B', t: d.substr(ev) }); }
      } else { toks.push({ set: 'B', t: m[0] }); }
    }
    var vals = [], cur = null;
    toks.forEach(function (k) {
      if (cur === null) { vals.push(k.set === 'C' ? 105 : 104); }
      else if (cur !== k.set) { vals.push(k.set === 'C' ? 99 : 100); }
      cur = k.set;
      if (k.set === 'C') { for (var i = 0; i < k.t.length; i += 2) { vals.push(+k.t.substr(i, 2)); } }
      else { for (var j = 0; j < k.t.length; j++) { vals.push(k.t.charCodeAt(j) - 32); } }
    });
    var sum = vals[0];
    for (var q = 1; q < vals.length; q++) { sum += q * vals[q]; }
    vals.push(sum % 103, 106);
    var mods = [];
    vals.forEach(function (v) {
      C128[v].split('').forEach(function (w, i) { for (var n = 0; n < +w; n++) { mods.push(i % 2 === 0); } });
    });
    return mods;
  }
  function qrMatrix(text, ecc) {
    var Q = window.qrcode;
    if (!Q) { throw new Error('No se cargó la librería de códigos QR.'); }
    if (Q.stringToBytesFuncs && Q.stringToBytesFuncs['UTF-8']) { Q.stringToBytes = Q.stringToBytesFuncs['UTF-8']; }
    var q = Q(0, String(ecc || 'M').toUpperCase());
    q.addData(String(text));
    q.make();
    return { n: q.getModuleCount(), dark: function (x, y) { return q.isDark(y, x); } };
  }
  /* Sección "codigo": { kind: 'qr' | 'code128', value, size | width + height, color, showText } */
  function codeOf(sec, ctx) {
    var row = sec.source ? rowsOf(sec, ctx)[0] : null;
    if (sec.source && !row) { return null; }
    var v = tpl(sec.value, ctx, row);
    if (!v) { return null; }
    var kind = String(sec.kind || 'qr').toLowerCase(), color = sec.color || '#000000';
    if (kind === 'qr') {
      var qm = qrMatrix(v, sec.ecc), sz = sec.size || 30;
      return { kind: 'qr', text: v, cols: qm.n, rows: qm.n, dark: qm.dark, w: sz, h: sz, color: color, quiet: 2 };
    }
    if (kind === 'code128') {
      var bars = code128(v), bw = sec.width || Math.min(90, bars.length * 0.33);
      return { kind: 'bar', text: v, cols: bars.length, rows: 1, dark: function (x) { return bars[x]; }, w: bw, h: sec.height || 12,
               color: color, quiet: 8, label: sec.showText !== false, textSize: sec.textSize || 8 };
    }
    throw new Error('Tipo de código no soportado: ' + kind + ' (use qr o code128).');
  }
  /* PNG del código (Word / Excel) con zona blanca; wmm / hmm = tamaño final en mm */
  function codePng(c) {
    var q = c.quiet, sc = c.kind === 'qr' ? 8 : 3, wpx = (c.cols + 2 * q) * sc;
    var hpx = c.kind === 'qr' ? wpx : Math.max(8, Math.round(c.h / c.w * c.cols * sc));
    var im = png1(wpx, hpx, function (x, y) {
      var mx = Math.floor(x / sc) - q, my = c.kind === 'qr' ? Math.floor(y / sc) - q : 0;
      return mx >= 0 && my >= 0 && mx < c.cols && my < c.rows && c.dark(mx, my);
    }, c.color);
    im.wmm = c.w * (c.cols + 2 * q) / c.cols;
    im.hmm = c.kind === 'qr' ? im.wmm : c.h;
    return im;
  }

  /* ================================================================== gráficos (Chart.js -> PNG) */
  var PALETTE = ['#1F4E79', '#E07B39', '#2E8B57', '#C0392B', '#7D3C98', '#16A085', '#D4AC0D', '#5D6D7E', '#A04000', '#2874A6'];
  function rgba(h, a) { var c = hexRgb(h); return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + a + ')'; }
  /* Sección "grafico": { chart: bar | hbar | line | area | pie | doughnut, source, category, series[], width, height, ... } */
  function chartImg(sec, ctx, th) {
    var Ch = window.Chart;
    if (!Ch) { throw new Error('No se cargó la librería de gráficos (Chart.js).'); }
    var rows = rowsOf(sec, ctx);
    if (!rows.length) { return null; }
    var src = String(sec.source || '').toUpperCase(), types = ctx.T[src] || {}, names = Object.keys(types);
    var cat = sec.category ? String(sec.category).toUpperCase()
                           : names.filter(function (c) { return types[c] !== 'NUMBER' && c !== 'DOC_KEY'; })[0] || names[0];
    var ser = (sec.series && sec.series.length ? sec.series
               : names.filter(function (c) { return types[c] === 'NUMBER' && c !== cat && c !== 'DOC_KEY'; })).map(function (s) {
      s = typeof s === 'string' ? { col: s } : s;
      return { col: String(s.col).toUpperCase(), label: s.label !== undefined ? s.label : label(s.col), color: s.color };
    });
    var kind = sec.chart || 'bar', pie = kind === 'pie' || kind === 'doughnut', S = 3, K = 3.78 * S;
    if (pie) { ser = ser.slice(0, 1); }
    var wmm = sec.width || 120, hmm = sec.height || 70, cv = newCanvas(Math.round(wmm * K), Math.round(hmm * K));
    var px = function (pt) { return pt * 0.3528 * K; }, fs = sec.size || 8, fam = 'Helvetica, Arial, sans-serif';
    var font = { family: fam, size: px(fs) };
    var pal = sec.colors && sec.colors.length ? sec.colors : [th.primary].concat(PALETTE.slice(1));
    var nf = function (v) { return fmt(v, sec.fmt || (Math.round(v) === v ? 'int' : 'num:2')); };
    var labels = rows.map(function (r) { var v = r[cat]; return v === null || v === undefined ? '' : (sec.categoryFmt ? fmt(v, sec.categoryFmt) : String(v)); });
    var datasets = ser.map(function (s, i) {
      var c = s.color || pal[i % pal.length];
      var ds = { label: tpl(s.label, ctx), data: rows.map(function (r) { var v = r[s.col]; return v === null || v === undefined || v === '' ? null : Number(v); }) };
      if (pie) { ds.backgroundColor = rows.map(function (r, j) { return pal[j % pal.length]; }); ds.borderColor = '#FFFFFF'; ds.borderWidth = px(0.8); }
      else if (kind === 'line' || kind === 'area') {
        ds.borderColor = c; ds.backgroundColor = kind === 'area' ? rgba(c, 0.25) : c; ds.fill = kind === 'area';
        ds.borderWidth = px(1.4); ds.pointRadius = px(1.5); ds.pointBackgroundColor = c; ds.tension = sec.smooth ? 0.35 : 0;
      } else { ds.backgroundColor = c; ds.borderWidth = 0; }
      return ds;
    });
    var tk = { font: font, color: '#444444' }, scales = {};
    if (!pie) {
      var val = { beginAtZero: sec.beginAtZero !== false, stacked: !!sec.stacked, grace: sec.values ? (kind === 'hbar' ? '25%' : '12%') : 0, grid: { color: '#E3E7EC', lineWidth: px(0.4) },
                  border: { display: false }, ticks: { font: font, color: '#444444', callback: function (v) { return nf(v); } } };
      var ax = { stacked: !!sec.stacked, grid: { display: false }, ticks: tk };
      scales = kind === 'hbar' ? { x: val, y: ax } : { x: ax, y: val };
    }
    var showLegend = sec.legend !== undefined ? !!sec.legend : (pie || ser.length > 1);
    var chart = new Ch(cv.getContext('2d'), {
      type: pie ? kind : (kind === 'hbar' ? 'bar' : (kind === 'area' ? 'line' : kind)),
      data: { labels: labels, datasets: datasets },
      platform: Ch.BasicPlatform,
      options: {
        responsive: false, animation: false, devicePixelRatio: 1, indexAxis: kind === 'hbar' ? 'y' : 'x',
        layout: { padding: px(4) }, scales: scales,
        plugins: {
          legend: { display: showLegend, position: sec.legendPosition || (pie ? 'right' : 'bottom'),
                    labels: { font: font, color: '#333333', boxWidth: px(7), boxHeight: px(7) } },
          title: { display: !!sec.title, text: tpl(sec.title, ctx), color: '#222222',
                   font: { family: fam, size: px(fs + 2), weight: 'bold' }, padding: { bottom: px(4) } },
          tooltip: { enabled: false }
        }
      },
      plugins: [{
        id: 'nrFondo',
        beforeDraw: function (c) { var g = c.ctx; g.save(); g.fillStyle = '#FFFFFF'; g.fillRect(0, 0, c.width, c.height); g.restore(); }
      }, {
        id: 'nrValores',
        afterDatasetsDraw: function (c) {
          if (!sec.values) { return; }
          var g = c.ctx;
          g.save(); g.font = 'bold ' + px(fs - 0.5) + 'px ' + fam;
          c.data.datasets.forEach(function (ds, di) {
            if (!c.isDatasetVisible(di)) { return; }
            var tot = ds.data.reduce(function (a, b) { return a + (b || 0); }, 0);
            c.getDatasetMeta(di).data.forEach(function (el, i) {
              var v = ds.data[i];
              if (v === null || v === undefined) { return; }
              var txt = sec.values === 'pct' ? fmt(tot ? v * 100 / tot : 0, 'num:1') + '%' : nf(v);
              if (pie) { var p = el.tooltipPosition(); g.fillStyle = '#FFFFFF'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(txt, p.x, p.y); }
              else if (kind === 'hbar') { g.fillStyle = '#333333'; g.textAlign = 'left'; g.textBaseline = 'middle'; g.fillText(txt, el.x + px(1.5), el.y); }
              else { g.fillStyle = '#333333'; g.textAlign = 'center'; g.textBaseline = 'bottom'; g.fillText(txt, el.x, el.y - px(1.5)); }
            });
          });
          g.restore();
        }
      }]
    });
    var url = cv.toDataURL('image/png');
    chart.destroy();
    var im = pngImg(url, cv.width, cv.height);
    im.wmm = wmm; im.hmm = hmm;
    return im;
  }

  /* ================================================================== marca de agua */
  /* layout.watermark: { text, when, color, opacity, angle, size } -> null si no aplica al documento */
  function watermarkOf(layout, ctx) {
    var wm = layout.watermark;
    if (!wm || (typeof wm === 'object' && !cond(wm.when, ctx, ctx.doc))) { return null; }
    if (typeof wm === 'string') { wm = { text: wm }; }
    var text = tpl(wm.text, ctx, ctx.doc);
    if (!text) { return null; }
    return { text: text, color: wm.color || '#C00000', opacity: wm.opacity !== undefined ? wm.opacity : 0.12,
             angle: wm.angle !== undefined ? wm.angle : 45, size: wm.size };
  }
  /* Tamaño automático (pt): el texto ocupa ~60 % de la diagonal (o 80 % del ancho si no está inclinado) */
  function wmSize(wm, w100, W, H) {
    if (wm.size) { return wm.size; }
    var target = wm.angle % 180 === 0 ? W * 0.8 : Math.sqrt(W * W + H * H) * 0.6;
    return Math.max(20, Math.min(160, 100 * target / w100));
  }
  /* PNG de página completa (Word): texto rotado y semitransparente, centrado */
  function watermarkPng(wm, wmm, hmm) {
    var K = 3.78 * 2, cv = newCanvas(Math.round(wmm * K), Math.round(hmm * K)), g = cv.getContext('2d');
    var fam = 'Helvetica, Arial, sans-serif';
    g.font = 'bold ' + (100 * 0.3528 * K) + 'px ' + fam;
    var size = wmSize(wm, g.measureText(wm.text).width / K, wmm, hmm);
    g.font = 'bold ' + (size * 0.3528 * K) + 'px ' + fam;
    g.translate(cv.width / 2, cv.height / 2); g.rotate(-wm.angle * Math.PI / 180);
    g.globalAlpha = wm.opacity; g.fillStyle = wm.color; g.textAlign = 'center'; g.textBaseline = 'middle';
    g.fillText(wm.text, 0, 0);
    var im = pngImg(cv.toDataURL('image/png'), cv.width, cv.height);
    im.wmm = wmm; im.hmm = hmm;
    return im;
  }

  /* ================================================================== PDF */
  function renderPdf(layout, ctxs, hooks) {
    var page = layout.page || {}, th = themeOf(layout), sz = th.fontSize;
    var doc = new window.jspdf.jsPDF({ orientation: page.orientation || 'portrait', unit: 'mm', format: page.size || 'letter', compress: true });
    var W = doc.internal.pageSize.getWidth(), H = doc.internal.pageSize.getHeight(), M = page.margin || 8;
    var P = hexRgb(th.primary), HT = hexRgb(th.headText), Z = hexRgb(th.zebra), TT = hexRgb(th.totals);
    var y = M, firstDoc = true;
    var XL = M, XR = M;   /* marco horizontal: margen izquierdo y derecho (las columnas lo achican) */

    function last() { return doc.lastAutoTable ? doc.lastAutoTable.finalY : y; }
    function gap(n) { y = last() + (n || 2); }
    /* Bloque de w x h mm: posición fija (x, y) o en el flujo, con salto de página si no cabe */
    function place(sec, w, h, draw) {
      var x = sec.x !== undefined ? sec.x : (sec.align === 'right' ? W - XR - w : (sec.align === 'center' ? XL + (W - XL - XR - w) / 2 : XL));
      if (sec.y !== undefined) { draw(x, sec.y); return; }
      y = Math.max(y, last());
      if (y + h > H - M - 10) { doc.addPage(); y = M; }
      draw(x, y);
      y += h + (sec.gap !== undefined ? sec.gap : 3); doc.lastAutoTable = { finalY: y };
    }
    var ranges = [];

    ctxs.forEach(function (ctx) {
      if (!firstDoc) { doc.addPage(); }
      firstDoc = false;
      y = M;
      doc.lastAutoTable = null;
      var rg = { ctx: ctx, from: doc.internal.getNumberOfPages() };
      ranges.push(rg);
      sectionsFor(layout, 'pdf', ctx).forEach(function drawSec(sec) {
        var t = sec.type;
        if (t === 'header') {
          var hh = sec.subtitle ? 20 : 16;
          doc.setFillColor(P[0], P[1], P[2]); doc.rect(0, 0, W, hh, 'F');
          doc.setTextColor(HT[0], HT[1], HT[2]);
          doc.setFont('helvetica', 'bold'); doc.setFontSize(sec.size || 14);
          doc.text(tpl(sec.title, ctx), M, 10.5, { maxWidth: W * 0.7 });
          doc.setFont('helvetica', 'normal'); doc.setFontSize(9);
          if (sec.right) { doc.text(tpl(sec.right, ctx), W - M, 10.5, { align: 'right' }); }
          if (sec.subtitle) { doc.text(tpl(sec.subtitle, ctx), M, 16.5); }
          doc.setTextColor(0, 0, 0);
          y = hh + 4; doc.lastAutoTable = null;
          return;
        }
        if (t === 'texto') {
          var absT = sec.y !== undefined, savedY = y, savedLast = doc.lastAutoTable;
          var fs = sec.size || 10, lh = fs * 0.3528 * (sec.lineHeight || 1.35);
          var x0 = (sec.x !== undefined ? sec.x : XL) + (sec.indent || 0), maxW = sec.width || (W - XR - x0);
          var al = sec.align || 'left', col = hexRgb(sec.color || '#000000');
          var fontOf = function (r) { return (r.b || sec.bold) && (r.i || sec.italic) ? 'bolditalic' : ((r.b || sec.bold) ? 'bold' : ((r.i || sec.italic) ? 'italic' : 'normal')); };
          var baseFont = sec.font || (layout.page && layout.page.font) || 'helvetica';
          doc.setFontSize(fs); doc.setTextColor(col[0], col[1], col[2]);
          y = absT ? sec.y : Math.max(y, doc.lastAutoTable ? doc.lastAutoTable.finalY : y);
          paragraphsOf(sec, ctx).forEach(function (para) {
            /* palabras con estilo */
            var words = [];
            richRuns(para, { font: baseFont, color: sec.color }).forEach(function (r) {
              r.t.split(/( +)/).forEach(function (w) {
                if (w !== '') { words.push({ t: w, fam: FONTS[r.f][0], f: fontOf(r), sp: /^ +$/.test(w), u: r.u, s: r.s, c: r.c ? hexRgb(r.c) : col }); }
              });
            });
            /* Ancho sin kerning (jsPDF dibuja sin kerning, pero getTextWidth lo aplica): suma por carácter */
            var wOf = function (w) {
              doc.setFont(w.fam, w.f);
              var tw = 0, key = w.fam + w.f + fs;
              for (var ci = 0; ci < w.t.length; ci++) {
                var chK = key + w.t.charAt(ci);
                if (CW[chK] === undefined) { CW[chK] = doc.getTextWidth(w.t.charAt(ci)); }
                tw += CW[chK];
              }
              return tw;
            };
            var lines = [], cur = [], cw = 0;
            words.forEach(function (w) {
              var ww = wOf(w);
              if (!w.sp && cw + ww > maxW && cur.length) {
                while (cur.length && cur[cur.length - 1].sp) { cw -= cur.pop().w; }
                lines.push({ ws: cur, w: cw }); cur = []; cw = 0;
              }
              if (w.sp && !cur.length) { return; }
              w.w = ww; cur.push(w); cw += ww;
            });
            while (cur.length && cur[cur.length - 1].sp) { cw -= cur.pop().w; }
            lines.push({ ws: cur, w: cw, last: true });
            if (!para.trim()) { y += lh; return; }
            lines.forEach(function (ln) {
              if (!absT && y + lh > H - M - 10) { doc.addPage(); y = M; }
              var gaps = ln.ws.filter(function (w) { return w.sp; }).length;
              var extra = (al === 'justify' && !ln.last && gaps) ? (maxW - ln.w) / gaps : 0;
              var x = al === 'right' ? x0 + maxW - ln.w : (al === 'center' ? x0 + (maxW - ln.w) / 2 : x0);
              var base = y + lh * 0.75;
              ln.ws.forEach(function (w) {
                var ww = w.w + (w.sp ? extra : 0);
                doc.setTextColor(w.c[0], w.c[1], w.c[2]); doc.setDrawColor(w.c[0], w.c[1], w.c[2]); doc.setLineWidth(fs * 0.012);
                if (!w.sp) { doc.setFont(w.fam, w.f); doc.text(w.t, x, base); }
                if (w.u) { doc.line(x, base + fs * 0.06, x + ww, base + fs * 0.06); }
                if (w.s) { doc.line(x, base - fs * 0.11, x + ww, base - fs * 0.11); }
                x += ww;
              });
              y += lh;
            });
            y += sec.paragraphGap !== undefined ? sec.paragraphGap : lh * 0.5;
          });
          doc.setTextColor(0, 0, 0);
          if (absT) { y = savedY; doc.lastAutoTable = savedLast; } else { doc.lastAutoTable = { finalY: y }; }
          return;
        }
        if (t === 'linea') {
          var lc = hexRgb(sec.color || '#000000');
          doc.setDrawColor(lc[0], lc[1], lc[2]); doc.setLineWidth(sec.thickness || 0.3);
          if (sec.x1 !== undefined) { doc.line(sec.x1, sec.y1, sec.x2 !== undefined ? sec.x2 : sec.x1, sec.y2 !== undefined ? sec.y2 : sec.y1); return; }
          y = Math.max(y, doc.lastAutoTable ? doc.lastAutoTable.finalY : y) + (sec.gapBefore || 0);
          var lw = sec.width || (W - XL - XR), lx = sec.align === 'center' ? XL + (W - XL - XR - lw) / 2 : (sec.align === 'right' ? W - XR - lw : XL);
          doc.line(lx, y, lx + lw, y);
          y += sec.gap !== undefined ? sec.gap : 2; doc.lastAutoTable = { finalY: y };
          return;
        }
        if (t === 'espacio') { y = Math.max(y, doc.lastAutoTable ? doc.lastAutoTable.finalY : y) + (sec.height || 6); doc.lastAutoTable = { finalY: y }; return; }
        if (t === 'imagen') {
          var im = imgOf(sec, ctx);
          if (!im) { return; }
          var szI = imgSize(sec, im), fmtI = im.ext === 'jpg' ? 'JPEG' : 'PNG';
          place(sec, szI.w, szI.h, function (ix, iy) { doc.addImage(im.data, fmtI, ix, iy, szI.w, szI.h); });
          return;
        }
        if (t === 'grafico') {
          var gi = chartImg(sec, ctx, th);
          if (!gi) { return; }
          place(sec, gi.wmm, gi.hmm, function (gx, gy) { doc.addImage(gi.data, 'PNG', gx, gy, gi.wmm, gi.hmm, undefined, 'FAST'); });
          return;
        }
        if (t === 'codigo') {
          var cd = codeOf(sec, ctx);
          if (!cd) { return; }
          var txH = cd.label ? cd.textSize * 0.3528 * 1.4 : 0;
          place(sec, cd.w, cd.h + txH, function (cx, cy) {
            var mw = cd.w / cd.cols, mh = cd.h / cd.rows, rc = hexRgb(cd.color);
            doc.setFillColor(rc[0], rc[1], rc[2]);
            for (var ry = 0; ry < cd.rows; ry++) {
              for (var rx = 0; rx < cd.cols; rx++) {
                if (!cd.dark(rx, ry)) { continue; }
                var run0 = rx;
                while (rx + 1 < cd.cols && cd.dark(rx + 1, ry)) { rx++; }
                doc.rect(cx + run0 * mw, cy + ry * mh, (rx - run0 + 1) * mw, mh + (ry < cd.rows - 1 ? 0.02 : 0), 'F');
              }
            }
            if (cd.label) {
              doc.setFont('courier', 'normal'); doc.setFontSize(cd.textSize); doc.setTextColor(rc[0], rc[1], rc[2]);
              doc.text(cd.text, cx + cd.w / 2, cy + cd.h + cd.textSize * 0.3528 * 1.1, { align: 'center' });
              doc.setTextColor(0, 0, 0);
            }
          });
          return;
        }
        if (t === 'salto') { doc.addPage(); y = M; doc.lastAutoTable = { finalY: M }; return; }
        if (t === 'columnas') {
          var fx = XL, fr0 = XR, cs = cellsOf(sec, 'pdf', ctx, W - XL - XR);
          if (!cs.length) { return; }
          var frame = function (c) { XL = fx + c.x; XR = W - (fx + c.x + c.w); };
          /* Medir en un documento borrador: la fila no se parte entre páginas */
          var real = doc, hMax = 0, fits = true, ys = Math.max(y, last());
          cs.forEach(function (c) {
            doc = new window.jspdf.jsPDF({ orientation: page.orientation || 'portrait', unit: 'mm', format: page.size || 'letter' });
            frame(c); y = M; doc.lastAutoTable = null;
            c.secs.forEach(drawSec);
            if (doc.internal.getNumberOfPages() > 1) { fits = false; }
            hMax = Math.max(hMax, Math.max(y, last()) - M);
          });
          doc = real; XL = fx; XR = fr0;
          y = ys; doc.lastAutoTable = { finalY: ys };
          if (!fits) {   /* no cabe ni en una página completa: se apilan las casillas */
            cs.forEach(function (c) { c.secs.forEach(drawSec); });
            return;
          }
          if (y + hMax > H - M - 10) { doc.addPage(); y = M; }
          var y0 = y, yEnd = y;
          cs.forEach(function (c) {
            frame(c); y = y0; doc.lastAutoTable = { finalY: y0 };
            c.secs.forEach(drawSec);
            yEnd = Math.max(yEnd, y, last());
          });
          XL = fx; XR = fr0;
          y = yEnd + (sec.gap !== undefined ? sec.gap : 1); doc.lastAutoTable = { finalY: y };
          return;
        }
        if (t === 'ficha') {
          var fr = rowsOf(sec, ctx)[0] || {}, n = sec.columns || 3, body = [], cur = [], cs = {};
          (sec.fields || []).filter(function (f) { return !f.when || cond(f.when, ctx, fr); }).forEach(function (f) {
            cur.push(tpl(f.label, ctx, fr), fieldText(f, ctx, fr));
            if (cur.length === n * 2) { body.push(cur); cur = []; }
          });
          if (cur.length) { while (cur.length < n * 2) { cur.push(''); } body.push(cur); }
          for (var i = 0; i < n * 2; i += 2) { cs[i] = { fontStyle: 'bold', cellWidth: sec.labelWidth || 32 }; }
          doc.autoTable({ startY: y, body: body, theme: 'plain', margin: { left: XL, right: XR },
                          styles: { fontSize: sec.size || 8.5, cellPadding: 0.9 }, columnStyles: cs });
          gap(2);
          return;
        }
        if (t === 'alerta') {
          rowsOf(sec, ctx).filter(function (r) { return cond(sec.when, ctx, r); }).slice(0, sec.each ? 999 : 1).forEach(function (r) {
            doc.autoTable({ startY: y, theme: 'plain', margin: { left: XL, right: XR }, body: [[tpl(sec.text, ctx, r)]],
                            styles: { fontSize: sec.size || 8, fontStyle: 'bold', cellPadding: 1.4,
                                      fillColor: hexRgb(colorOf(sec.color, ctx, r) || '#E6ECF2') } });
            gap(1);
          });
          return;
        }
        if (t === 'tabla') {
          var rows = rowsOf(sec, ctx);
          if (!rows.length && sec.hideEmpty !== false && !sec.emptyText) { return; }
          var cols = columnsOf(sec, ctx, rows), head = [], colSt = {};
          if (sec.title) { head.push([{ content: tpl(sec.title, ctx), colSpan: cols.length, styles: { halign: 'left', fontSize: sz + 1 } }]); }
          if (sec.groups) {
            var g1 = [], g2 = [], vm = { halign: 'center', valign: 'middle' };
            groupsOf(sec, cols).forEach(function (g) {
              for (var gi = g.from; gi < g.from + g.cols; gi++) {
                if (g.gap) { g1.push({ content: cols[gi].label, rowSpan: 2, styles: vm }); } else { g2.push(cols[gi].label); }
              }
              if (!g.gap) { g1.push({ content: g.label, colSpan: g.cols, styles: vm }); }
            });
            head.push(g1, g2);
          } else {
            head.push(cols.map(function (c) { return c.label; }));
          }
          cols.forEach(function (c, i) {
            colSt[i] = { halign: c.align };
            if (c.color) { colSt[i].textColor = hexRgb(c.color); }
            if (c.bold) { colSt[i].fontStyle = 'bold'; }
            if (c.width) { colSt[i].cellWidth = c.width; }
          });
          var items = tableItems(sec, rows), sset = subCols(sec), GR = hexRgb(th.group), bodyIt = [];
          var body = rows.length ? [] : [[{ content: tpl(sec.emptyText, ctx), colSpan: cols.length, styles: { halign: 'left', fontStyle: 'italic' } }]];
          if (rows.length) {
            items.forEach(function (it) {   /* bodyIt: ítem de cada fila del cuerpo (un subtotal puede ocupar 2 filas) */
              if (it.k === 'head') { body.push([{ content: breakText(sec, it, ctx), colSpan: cols.length, styles: { halign: 'left', fontStyle: 'bold', fillColor: GR } }]); bodyIt.push(it); return; }
              if (it.k === 'sub') { pdfAgg(aggRow(cols, sset, it.rows, breakText(sec, it, ctx)), cols.length).forEach(function (rw) { body.push(rw); bodyIt.push(it); }); return; }
              body.push(cols.map(function (c) { return cellText(c, it.r, ctx); })); bodyIt.push(it);
            });
          }
          var foot = null, tlist = aggList(sec.totals);
          if (tlist.length && rows.length) {
            foot = pdfAgg(aggRow(cols, tlist, rows, totText(sec, ctx, rows)), cols.length);
          }
          doc.autoTable({
            startY: y, margin: { left: XL, right: XR }, head: head, body: body, foot: foot || undefined,
            showHead: sec.repeatHeader === false ? 'firstPage' : 'everyPage', showFoot: 'lastPage',
            styles: { fontSize: sec.size || sz, cellPadding: 0.8 },
            headStyles: { fillColor: P, textColor: HT, halign: 'center', fontSize: sec.size || sz },
            footStyles: { fillColor: TT, textColor: 0, fontStyle: 'bold', halign: 'right' },
            alternateRowStyles: sec.breakBy ? {} : { fillColor: Z },
            columnStyles: colSt,
            didParseCell: function (h) {
              if (h.section !== 'body' || !rows.length) { return; }
              var it = bodyIt[h.row.index];
              if (!it || it.k === 'head') { return; }
              if (it.k === 'sub') { h.cell.styles.fillColor = TT; h.cell.styles.fontStyle = 'bold'; return; }
              var r = it.r, c = cols[h.column.index];
              if (sec.breakBy) { h.cell.styles.fillColor = it.i % 2 === 1 && sec.zebra !== false ? Z : [255, 255, 255]; }
              var rs = styleOf(sec.rowStyle, ctx, r);
              if (rs) {
                if (rs.fill) { h.cell.styles.fillColor = hexRgb(rs.fill); }
                if (rs.color) { h.cell.styles.textColor = hexRgb(rs.color); }
                if (rs.bold) { h.cell.styles.fontStyle = 'bold'; }
              }
              var st = c && styleOf(c.cellStyle, ctx, r);
              if (st) {
                if (st.fill) { h.cell.styles.fillColor = hexRgb(st.fill); }
                if (st.color) { h.cell.styles.textColor = hexRgb(st.color); }
                if (st.bold) { h.cell.styles.fontStyle = 'bold'; }
              }
              if (hooks && hooks.pdfCell) { hooks.pdfCell(h, r, c, sec, ctx); }
            }
          });
          gap(sec.gap || 3);
        }
      });
      rg.to = doc.internal.getNumberOfPages();
    });

    ranges.forEach(function (g) {
      var wm = watermarkOf(layout, g.ctx);
      if (!wm) { return; }
      doc.setFont('helvetica', 'bold'); doc.setFontSize(100);
      var size = wmSize(wm, doc.getTextWidth(wm.text), W, H), a = wm.angle * Math.PI / 180, wc = hexRgb(wm.color);
      doc.setFontSize(size);
      var tw = doc.getTextWidth(wm.text), ch = size * 0.3528 * 0.7;
      var x0 = W / 2 - tw / 2 * Math.cos(a) + ch / 2 * Math.sin(a), y0 = H / 2 + tw / 2 * Math.sin(a) + ch / 2 * Math.cos(a);
      for (var pg = g.from; pg <= g.to; pg++) {
        doc.setPage(pg);
        doc.saveGraphicsState();
        doc.setGState(new doc.GState({ opacity: wm.opacity }));
        doc.setTextColor(wc[0], wc[1], wc[2]);
        doc.text(wm.text, x0, y0, { angle: wm.angle });
        doc.restoreGraphicsState();
      }
      doc.setTextColor(0, 0, 0);
    });

    var ft = layout.footer, n = doc.internal.getNumberOfPages(), c0 = ctxs[0] || { S: {}, T: {} };
    if (ft) {
      for (var p = 1; p <= n; p++) {
        doc.setPage(p);
        doc.setFont('helvetica', 'normal'); doc.setFontSize(ft.size || 7);
        var mu = hexRgb(th.muted); doc.setTextColor(mu[0], mu[1], mu[2]);
        var rep = function (s) { return tpl(s, c0).replace('{PAGE}', p).replace('{PAGES}', n); };
        if (ft.left) { var fl = doc.splitTextToSize(rep(ft.left), W * 0.78); doc.text(fl, M, H - 4 - (fl.length - 1) * (ft.size || 7) * 0.4); }
        if (ft.right) { doc.text(rep(ft.right), W - M, H - 5, { align: 'right' }); }
      }
      doc.setTextColor(0, 0, 0);
    }
    if (layout.title) { doc.setProperties({ title: tpl(layout.title, c0) }); }
    return Promise.resolve(doc.output('arraybuffer'));
  }

  /* ================================================================== EXCEL (ExcelJS) */
  function renderXlsx(layout, ctxs, merge) {
    var wb = new window.ExcelJS.Workbook(), th = themeOf(layout), used = {};
    wb.creator = 'novaReport';
    var defs = (layout.xlsx && layout.xlsx.sheets) || [{ name: layout.xlsx && layout.xlsx.sheetName || 'Reporte' }];
    var secs = sectionsFor(layout, 'xlsx'), page = layout.page || {};
    var fillP = { type: 'pattern', pattern: 'solid', fgColor: { argb: argb(th.primary) } };

    function uniq(name) {
      var base = safeName(name).replace(/[\[\]]/g, '').substr(0, 31) || 'Hoja', n = base, i = 2;
      while (used[n.toLowerCase()]) { n = base.substr(0, 31 - String(i).length - 1) + '_' + i; i++; }
      used[n.toLowerCase()] = true;
      return n;
    }
    function fill(h) { return { type: 'pattern', pattern: 'solid', fgColor: { argb: argb(h) } }; }

    ctxs.forEach(function (ctx) {
      defs.forEach(function (sd) {
        var sname = tpl(sd.name, ctx);
        if (merge && ctxs.length > 1) { sname = tpl(sd.mergeName || (defs.length > 1 ? '{DOC.DOC_KEY} ' + sd.name : '{DOC.DOC_KEY}'), ctx); }
        var ws = wb.addWorksheet(uniq(sname), {
          pageSetup: { orientation: page.orientation || 'portrait', paperSize: page.size === 'legal' ? 5 : (page.size === 'a4' ? 9 : 1),
                       fitToPage: true, fitToWidth: 1, fitToHeight: 0 } });
        var list = sd.sections ? sd.sections.map(function (id) {
          return typeof id === 'number' ? secs[id] : secs.filter(function (s) { return s.id === id; })[0];
        }).filter(Boolean) : secs;
        list = list.filter(function (s) { return shown(s, ctx); });
        var maxC = 4, r = 1, widths = {}, tables = 0, freezeAt = null, filterRef = null;
        /* Columnas de hoja que necesita cada casilla de una sección columnas */
        var need = function (secs) {
          return secs.reduce(function (m, x) {
            return Math.max(m, x.type === 'tabla' ? columnsOf(x, ctx, rowsOf(x, ctx)).length : (x.type === 'ficha' ? (x.columns || 3) * 2 : (x.type === 'texto' || x.type === 'alerta' ? 4 : 2)));
          }, 2);
        };
        list.forEach(function (s) {
          if (s.type === 'columnas') { maxC = Math.max(maxC, cellsOf(s, 'xlsx', ctx, 100).reduce(function (m, c) { return m + need(c.secs) + 1; }, -1)); }
          if (s.type === 'tabla') { tables++; maxC = Math.max(maxC, columnsOf(s, ctx, rowsOf(s, ctx)).length); }
          if (s.type === 'ficha') { maxC = Math.max(maxC, (s.columns || 3) * 2); }
        });
        function setW(c, txt) { var l = String(txt === null || txt === undefined ? '' : txt).length; c += C0; widths[c] = Math.min(60, Math.max(widths[c] || 8, l + 2)); }
        /* Casillas de columnas: C0 desplaza la columna de inicio; maxC es el ancho del bloque */
        var C0 = 0, inCols = false;
        function cellAt(rr, cc) { return ws.getCell(rr, cc + C0); }
        function merge(r1, c1, r2, c2) { ws.mergeCells(r1, c1 + C0, r2, c2 + C0); }
        function rowH(rr, h) { var R = ws.getRow(rr); R.height = Math.max(R.height || 0, h); }
        /* Imagen en la fila actual; avanza las filas que ocupa (20 px por fila) */
        function putImg(im, wmm, hmm, keepNext) {
          var id = wb.addImage({ base64: im.data, extension: im.ext === 'jpg' ? 'jpeg' : 'png' });
          ws.addImage(id, { tl: { col: C0, row: r - 1 }, ext: { width: wmm * 3.78, height: hmm * 3.78 } });
          r += Math.ceil(hmm * 3.78 / 20) + (keepNext ? 0 : 1);
        }
        function band(text, f, font, height) {
          merge(r, 1, r, maxC);
          var cell = cellAt(r, 1);
          cell.value = text; cell.fill = f; cell.font = font; cell.alignment = { vertical: 'middle', wrapText: true };
          if (height) { rowH(r, inCols ? Math.max(height, Math.ceil(String(text || '').length / Math.max(16, maxC * 9)) * 15) : height); }
          r++;
        }
        list.forEach(function drawSec(sec) {
          var t = sec.type;
          if (t === 'columnas') {
            var r0 = r, rEnd = r, c0s = C0, mx = maxC, off = 0;
            inCols = true;
            cellsOf(sec, 'xlsx', ctx, 100).forEach(function (c) {
              var k = need(c.secs);
              C0 = c0s + off; maxC = k; r = r0;
              c.secs.forEach(drawSec);
              rEnd = Math.max(rEnd, r); off += k + 1;
            });
            C0 = c0s; maxC = mx; inCols = false; r = rEnd;
            return;
          }
          if (t === 'header') {
            band(tpl(sec.title, ctx), fillP, { bold: true, size: 14, color: { argb: argb(th.headText) } }, 26);
            if (sec.right || sec.subtitle) {
              band([tpl(sec.subtitle, ctx), tpl(sec.right, ctx)].filter(Boolean).join('   |   '), fillP,
                   { size: 9, color: { argb: argb(th.headText) } }, 16);
            }
            r++;
          } else if (t === 'texto') {
            paragraphsOf(sec, ctx).forEach(function (para) {
              merge(r, 1, r, maxC);
              var cx = cellAt(r, 1);
              cx.value = { richText: richRuns(para, { font: sec.font || (layout.page && layout.page.font), color: sec.color }).map(function (x) {
                return { text: x.t, font: { bold: !!(x.b || sec.bold), italic: !!(x.i || sec.italic), underline: x.u || undefined, strike: x.s || undefined,
                                            name: FONTS[x.f][1], color: x.c ? { argb: argb(x.c) } : undefined, size: sec.size || 10 } }; }) };
              cx.alignment = { wrapText: true, vertical: 'top', horizontal: sec.align === 'justify' ? 'justify' : (sec.align || 'left') };
              rowH(r, Math.max(15, Math.ceil(para.length / (inCols ? Math.max(16, maxC * 9) : 140)) * 15));
              r++;
            });
          } else if (t === 'espacio') {
            r++;
          } else if (t === 'imagen') {
            var imx = imgOf(sec, ctx);
            if (imx) { var szx = imgSize(sec, imx); putImg(imx, szx.w, szx.h); }
          } else if (t === 'grafico') {
            var gx = chartImg(sec, ctx, th);
            if (gx) { putImg(gx, gx.wmm, gx.hmm); }
          } else if (t === 'codigo') {
            var cdx = codeOf(sec, ctx);
            if (cdx) {
              var cpx = codePng(cdx);
              putImg(cpx, cpx.wmm, cpx.hmm, cdx.label);
              if (cdx.label) { var ctc = cellAt(r, 1); ctc.value = cdx.text; ctc.font = { name: 'Courier New', size: cdx.textSize }; r += 2; }
            }
          } else if (t === 'salto') {
            r++;
          } else if (t === 'ficha') {
            var fr = rowsOf(sec, ctx)[0] || {}, n = sec.columns || 3, c = 1;
            (sec.fields || []).filter(function (f) { return !f.when || cond(f.when, ctx, fr); }).forEach(function (f, i) {
              if (i > 0 && i % n === 0) { r++; c = 1; }
              var lc = cellAt(r, c), vc = cellAt(r, c + 1), lt = tpl(f.label, ctx, fr);
              lc.value = lt; lc.font = { bold: true };
              var raw = (/^\{[^}|]+\}$/.test(f.value || '') && !f.map) ? lookup(ctx, f.value.slice(1, -1), fr) : null;
              if (isNum(raw) && !textFmt(f.fmt)) { vc.value = raw; if (f.fmt === 'money') { vc.numFmt = '#,##0.00'; } vc.alignment = { horizontal: 'left' }; }
              else if (f.fmt === 'date' && parseDate(raw)) { vc.value = parseDate(raw); vc.numFmt = 'dd/mm/yyyy'; vc.alignment = { horizontal: 'left' }; }
              else { vc.value = fieldText(f, ctx, fr); }
              setW(c, lt); setW(c + 1, fieldText(f, ctx, fr));
              c += 2;
            });
            r += 2;
          } else if (t === 'alerta') {
            rowsOf(sec, ctx).filter(function (x) { return cond(sec.when, ctx, x); }).slice(0, sec.each ? 999 : 1).forEach(function (x) {
              band(tpl(sec.text, ctx, x), fill(colorOf(sec.color, ctx, x) || '#E6ECF2'), { bold: true }, 30);
            });
            r++;
          } else if (t === 'tabla') {
            var rows = rowsOf(sec, ctx);
            if (!rows.length && sec.hideEmpty !== false && !sec.emptyText) { return; }
            var cols = columnsOf(sec, ctx, rows);
            if (sec.title) {
              merge(r, 1, r, cols.length);
              var tc = cellAt(r, 1);
              tc.value = tpl(sec.title, ctx); tc.font = { bold: true, color: { argb: argb(th.headText) } }; tc.fill = fillP;
              r++;
            }
            if (sec.groups) {
              var gc = 1;
              groupsOf(sec, cols).forEach(function (g) {
                if (g.cols > 1 && !g.gap) { merge(r, gc, r, gc + g.cols - 1); }
                var gcell = cellAt(r, gc);
                if (g.gap) {
                  for (var gi = 0; gi < g.cols; gi++) {
                    merge(r, gc + gi, r + 1, gc + gi);
                    var gx = cellAt(r, gc + gi);
                    gx.value = cols[g.from + gi].label; gx.fill = fillP; gx.font = { bold: true, color: { argb: argb(th.headText) } };
                    gx.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
                    setW(gc + gi, cols[g.from + gi].label);
                  }
                  gc += g.cols; return;
                }
                gcell.value = g.label || null; gcell.fill = fillP; gcell.font = { bold: true, color: { argb: argb(th.headText) } };
                gcell.alignment = { horizontal: 'center', vertical: 'middle' };
                gc += g.cols;
              });
              r++;
            }
            var hr = r;
            var gapCol = {};
            if (sec.groups) { groupsOf(sec, cols).forEach(function (g) { if (g.gap) { for (var gi = g.from; gi < g.from + g.cols; gi++) { gapCol[gi] = 1; } } }); }
            cols.forEach(function (c, i) {
              if (gapCol[i]) { return; }
              var h = cellAt(r, i + 1);
              h.value = c.label; h.fill = fillP; h.font = { bold: true, color: { argb: argb(th.headText) } };
              h.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
              setW(i + 1, c.label);
            });
            r++;
            if (!rows.length) {
              merge(r, 1, r, cols.length);
              cellAt(r, 1).value = tpl(sec.emptyText, ctx); cellAt(r, 1).font = { italic: true };
              r += 2; return;
            }
            var first = r, items = tableItems(sec, rows), sset = subCols(sec), gStart = null;
            /* Fila de totales/subtotal con fórmulas; devuelve la siguiente fila libre */
            var xlsAgg = function (r0, list, grows, text, r1, r2, sub) {
              var ar = aggRow(cols, list, grows, text), mixed = aggMixed(list);
              var paint = function (cell) { cell.fill = fill(th.totals); cell.font = { bold: true }; return cell; };
              if (ar.at > 1 || ar.at === 0) { merge(r0, 1, r0, ar.at || cols.length); }
              var tl = paint(cellAt(r0, 1));
              tl.value = text; tl.alignment = { horizontal: 'left' };
              if (ar.at === 0) { r0++; }
              cols.forEach(function (c, i) {
                if (i < ar.at) { return; }
                var cell = paint(cellAt(r0, i + 1)), a = c.col ? aggFind(list, c.col) : null;
                if (!a) { return; }
                var L = ws.getColumn(i + 1 + C0).letter, rng = L + r1 + ':' + L + r2, v = aggValue(grows, a.col, a.fn);
                var dt = (a.fn === 'min' || a.fn === 'max') && v !== null && !numLike(v) ? parseDate(v) : null;
                var res = v === null || v === undefined ? null : (dt || (numLike(v) ? Math.round(Number(v) * 100) / 100 : String(v)));
                cell.value = { formula: (sub ? 'SUBTOTAL(' + AGG_XL[a.fn] + ',' : AGG_FX[a.fn] + '(') + rng + ')', result: res };
                var nf = a.fn === 'count' ? '#,##0' : (dt ? 'dd/mm/yyyy' : '#,##0.00');
                cell.numFmt = mixed && AGG_PRE[a.fn] ? '"' + AGG_PRE[a.fn] + ' "' + nf : nf;
                cell.alignment = { horizontal: 'right' };
                if (res !== null && !dt) { setW(i + 1, numLike(res) ? fmt(res, 'money') : res); }
              });
              return r0 + 1;
            };
            items.forEach(function (it) {
              if (it.k === 'head') {
                merge(r, 1, r, cols.length);
                var hx = cellAt(r, 1);
                hx.value = breakText(sec, it, ctx); hx.font = { bold: true }; hx.fill = fill(th.group);
                r++; return;
              }
              if (it.k === 'sub') {
                r = xlsAgg(r, sset, it.rows, breakText(sec, it, ctx), gStart, r - 1, true);
                gStart = null; return;
              }
              if (gStart === null) { gStart = r; }
              var row = it.r, ri = it.i;
              var rs = styleOf(sec.rowStyle, ctx, row);
              cols.forEach(function (c, i) {
                var cell = cellAt(r, i + 1), raw = cellRaw(c, row, ctx);
                if (c.isNum && isNum(raw)) {
                  cell.value = raw;
                  cell.numFmt = c.fmt === 'int' ? '#,##0' : (c.fmt === 'money' || /^num/.test(c.fmt || '') ? '#,##0.' + new Array(((c.fmt || '').split(':')[1] || 2) * 1 + 1).join('0') : 'General');
                } else if ((c.fmt === 'date' || (ctx.T[String(sec.source).toUpperCase()] || {})[c.col] === 'DATE') && parseDate(raw)) {
                  cell.value = parseDate(raw); cell.numFmt = 'dd/mm/yyyy';
                } else {
                  cell.value = raw === null || raw === undefined ? null : (textFmt(c.fmt) && !c.map ? fmt(raw, c.fmt) : String(raw));
                }
                cell.alignment = { horizontal: c.align };
                var st = styleOf(c.cellStyle, ctx, row) || rs;
                if (st && st.fill) { cell.fill = fill(st.fill); } else if (ri % 2 === 1 && sec.zebra !== false) { cell.fill = fill(th.zebra); }
                var font = {};
                if (c.bold || (st && st.bold)) { font.bold = true; }
                if ((st && st.color) || c.color) { font.color = { argb: argb((st && st.color) || c.color) }; }
                if (font.bold || font.color) { cell.font = font; }
                setW(i + 1, c.isNum ? fmt(raw, c.fmt) : raw);
              });
              r++;
            });
            var lastData = r - 1, tlist = aggList(sec.totals);
            if (tlist.length) { r = xlsAgg(r, tlist, rows, totText(sec, ctx, rows), first, r - 1, !!sec.breakBy); }
            if (tables === 1 && !sec.breakBy && !inCols) {
              filterRef = { from: { row: hr, column: 1 }, to: { row: lastData, column: cols.length } };
              if (list.indexOf(sec) <= 1) { freezeAt = hr; }
            }
            r++;
          }
        });
        Object.keys(widths).forEach(function (c) { ws.getColumn(+c).width = widths[c]; });
        if (filterRef) { ws.autoFilter = filterRef; }
        if (freezeAt) { ws.views = [{ state: 'frozen', ySplit: freezeAt }]; }
        if (layout.footer) {
          ws.headerFooter.oddFooter = '&L&8' + tpl(layout.footer.left, ctx).replace(/&/g, '&&').substr(0, 200) + '&R&8Página &P de &N';
        }
      });
    });
    return wb.xlsx.writeBuffer();
  }

  /* ================================================================== WORD (docx) */
  var PAGES_TW = { letter: [12240, 15840], legal: [12240, 20160], a4: [11906, 16838] };
  /* Pie de página Word: solo si el diseño trae "footer"; {PAGE} y {PAGES} se vuelven campos de Word */
  function docxFooter(ft, ctx, th) {
    var D = window.docx, out = [], sz = Math.round((ft.size || 7) * 2), col = hexNo(th.muted);
    function runs(txt) {
      var parts = tpl(txt, ctx).split(/(\{PAGES?\})/), r = [];
      parts.forEach(function (x) {
        if (x === '{PAGE}') { r.push(new D.TextRun({ children: [D.PageNumber.CURRENT], size: sz, color: col })); }
        else if (x === '{PAGES}') { r.push(new D.TextRun({ children: [D.PageNumber.TOTAL_PAGES], size: sz, color: col })); }
        else if (x) { r.push(new D.TextRun({ text: x, size: sz, color: col })); }
      });
      return r;
    }
    if (ft.left) { out.push(new D.Paragraph({ children: runs(ft.left) })); }
    if (ft.right) { out.push(new D.Paragraph({ alignment: D.AlignmentType.RIGHT, children: runs(ft.right) })); }
    return out.length ? out : [new D.Paragraph({ children: [] })];
  }
  function renderDocx(layout, ctxs) {
    var D = window.docx, th = themeOf(layout), page = layout.page || {};
    var dims = PAGES_TW[page.size || 'letter'] || PAGES_TW.letter, land = page.orientation === 'landscape';
    var mg = Math.round((page.margin || 12.7) * 56.7), usable = (land ? dims[1] : dims[0]) - 2 * mg;
    var none = { style: D.BorderStyle.NONE, size: 0, color: 'FFFFFF' };
    var noB = { top: none, bottom: none, left: none, right: none, insideHorizontal: none, insideVertical: none };
    var thin = { style: D.BorderStyle.SINGLE, size: 2, color: 'BFC9D4' };
    var gridB = { top: thin, bottom: thin, left: thin, right: thin, insideHorizontal: thin, insideVertical: thin };
    var szT = Math.round((th.fontSize || 7) * 2);

    function run(text, o) {
      o = o || {};
      return new D.TextRun({ text: String(text === null || text === undefined ? '' : text), bold: !!o.bold, italics: !!o.italic,
                             size: o.size || szT, color: o.color ? hexNo(o.color) : undefined, font: 'Calibri' });
    }
    function para(text, o) {
      o = o || {};
      return new D.Paragraph({ children: [run(text, o)], spacing: { before: 0, after: 0 },
        alignment: o.align === 'right' ? D.AlignmentType.RIGHT : (o.align === 'center' ? D.AlignmentType.CENTER : D.AlignmentType.LEFT) });
    }
    function cell(text, o) {
      o = o || {};
      return new D.TableCell({ children: [para(text, o)], columnSpan: o.span, margins: { top: 30, bottom: 30, left: 60, right: 60 },
                               shading: o.fill ? { type: D.ShadingType.CLEAR, color: 'auto', fill: hexNo(o.fill) } : undefined });
    }
    function spacer() { return new D.Paragraph({ children: [], spacing: { before: 60, after: 60 } }); }
    function imgPara(im, wmm, hmm, sec, after) {
      return new D.Paragraph({
        alignment: sec.align === 'right' ? D.AlignmentType.RIGHT : (sec.align === 'center' ? D.AlignmentType.CENTER : D.AlignmentType.LEFT),
        spacing: { after: after !== undefined ? after : Math.round((sec.gap !== undefined ? sec.gap : 3) * 56.7) },
        children: [new D.ImageRun({ type: im.ext === 'jpg' ? 'jpg' : 'png', data: im.buf,
                                    transformation: { width: Math.round(wmm * 3.78), height: Math.round(hmm * 3.78) } })] });
    }
    var pgW = (land ? dims[1] : dims[0]) / 56.7, pgH = (land ? dims[0] : dims[1]) / 56.7;
    function wmHeader(ctx) {
      var wm = watermarkOf(layout, ctx), im;
      if (!wm) { return null; }
      try { im = watermarkPng(wm, pgW, pgH); } catch (e) { return null; }  /* sin canvas (fuera del navegador) */
      return new D.Header({ children: [new D.Paragraph({ children: [new D.ImageRun({
        type: 'png', data: im.buf, transformation: { width: Math.round(pgW * 3.78), height: Math.round(pgH * 3.78) },
        floating: { horizontalPosition: { relative: D.HorizontalPositionRelativeFrom.PAGE, align: D.HorizontalPositionAlign.CENTER },
                    verticalPosition: { relative: D.VerticalPositionRelativeFrom.PAGE, align: D.VerticalPositionAlign.CENTER },
                    behindDocument: true, allowOverlap: true, wrap: { type: D.TextWrappingType.NONE } } })] })] });
    }

    var sections = ctxs.map(function (ctx) {
      var kids = [];
      sectionsFor(layout, 'docx', ctx).forEach(function drawSec(sec) {
        var t = sec.type;
        if (t === 'columnas') {
          /* Tabla sin bordes, una celda por casilla; dentro, el ancho útil es el de la celda */
          var csd = cellsOf(sec, 'docx', ctx, usable / 56.7);
          if (!csd.length) { return; }
          var saveK = kids, saveU = usable, cgd = Math.round((sec.colGap !== undefined ? Number(sec.colGap) : 4) * 56.7);
          var tcs = [], cwd = [];
          csd.forEach(function (c, i) {
            var lastC = i === csd.length - 1, wd = Math.round(c.w * 56.7);
            kids = []; usable = wd;
            c.secs.forEach(drawSec);
            if (!kids.length || !(kids[kids.length - 1] instanceof D.Paragraph)) { kids.push(para('')); }
            tcs.push(new D.TableCell({ children: kids, width: { size: wd + (lastC ? 0 : cgd), type: D.WidthType.DXA },
                                       margins: { top: 0, bottom: 0, left: 0, right: lastC ? 0 : cgd }, verticalAlign: D.VerticalAlign.TOP }));
            cwd.push(wd + (lastC ? 0 : cgd));
          });
          kids = saveK; usable = saveU;
          kids.push(new D.Table({ rows: [new D.TableRow({ cantSplit: true, children: tcs })], width: { size: usable, type: D.WidthType.DXA },
                                  columnWidths: cwd, borders: noB, layout: D.TableLayoutType.FIXED }), spacer());
          return;
        }
        if (t === 'header') {
          var rowsH = [new D.TableRow({ children: [
            cell(tpl(sec.title, ctx), { bold: true, size: 28, color: th.headText, fill: th.primary }),
            cell(tpl(sec.right, ctx), { size: 18, color: th.headText, fill: th.primary, align: 'right' }) ] })];
          if (sec.subtitle) {
            rowsH.push(new D.TableRow({ children: [cell(tpl(sec.subtitle, ctx), { size: 18, color: th.headText, fill: th.primary, span: 2 })] }));
          }
          kids.push(new D.Table({ rows: rowsH, width: { size: usable, type: D.WidthType.DXA }, columnWidths: [Math.round(usable * 0.7), Math.round(usable * 0.3)], borders: noB }), spacer());
        } else if (t === 'texto') {
          var AL = { right: D.AlignmentType.RIGHT, center: D.AlignmentType.CENTER, justify: D.AlignmentType.JUSTIFIED };
          paragraphsOf(sec, ctx).forEach(function (para) {
            kids.push(new D.Paragraph({
              alignment: AL[sec.align] || D.AlignmentType.LEFT,
              indent: sec.indent ? { left: Math.round(sec.indent * 56.7) } : undefined,
              spacing: { after: sec.paragraphGap !== undefined ? Math.round(sec.paragraphGap * 56.7) : 120, line: Math.round(240 * (sec.lineHeight || 1.15)) },
              children: richRuns(para, { font: sec.font || (layout.page && layout.page.font), color: sec.color }).map(function (x) {
                return new D.TextRun({ text: x.t, bold: !!(x.b || sec.bold), italics: !!(x.i || sec.italic), size: (sec.size || 10) * 2,
                                       underline: x.u ? {} : undefined, strike: !!x.s,
                                       color: x.c ? hexNo(x.c) : undefined, font: FONTS[x.f][1] });
              }) }));
          });
        } else if (t === 'espacio') {
          kids.push(new D.Paragraph({ children: [], spacing: { after: Math.round((sec.height || 6) * 56.7) } }));
        } else if (t === 'linea') {
          if (sec.x1 === undefined) {
            var lwd = Math.round((sec.width || 0) * 56.7), side = lwd ? Math.max(0, Math.round((usable - lwd) / 2)) : 0;
            kids.push(new D.Paragraph({ children: [], spacing: { after: Math.round((sec.gap !== undefined ? sec.gap : 2) * 56.7) },
              indent: sec.align === 'center' ? { left: side, right: side } : (sec.align === 'right' ? { left: side * 2 } : { right: side * 2 }),
              border: { bottom: { style: D.BorderStyle.SINGLE, size: Math.max(2, Math.round((sec.thickness || 0.3) * 20)), color: hexNo(sec.color || '#000000'), space: 1 } } }));
          }
        } else if (t === 'imagen') {
          var imd = imgOf(sec, ctx);
          if (imd) { var szd = imgSize(sec, imd); kids.push(imgPara(imd, szd.w, szd.h, sec)); }
        } else if (t === 'grafico') {
          var gd = chartImg(sec, ctx, th);
          if (gd) { kids.push(imgPara(gd, gd.wmm, gd.hmm, sec)); }
        } else if (t === 'codigo') {
          var cdd = codeOf(sec, ctx);
          if (cdd) {
            var cpd = codePng(cdd);
            kids.push(imgPara(cpd, cpd.wmm, cpd.hmm, sec, cdd.label ? 0 : undefined));
            if (cdd.label) {
              kids.push(new D.Paragraph({ alignment: sec.align === 'right' ? D.AlignmentType.RIGHT : (sec.align === 'center' ? D.AlignmentType.CENTER : D.AlignmentType.LEFT),
                indent: sec.align === 'right' || sec.align === 'center' ? undefined : { left: Math.max(0, Math.round((cpd.wmm - cdd.text.length * cdd.textSize * 0.3528 * 0.6) / 2 * 56.7)) },
                spacing: { after: Math.round((sec.gap !== undefined ? sec.gap : 3) * 56.7) },
                children: [new D.TextRun({ text: cdd.text, font: 'Courier New', size: cdd.textSize * 2, color: hexNo(cdd.color) })] }));
            }
          }
        } else if (t === 'salto') {
          kids.push(new D.Paragraph({ children: [new D.PageBreak()] }));
        } else if (t === 'ficha') {
          var fr = rowsOf(sec, ctx)[0] || {}, n = sec.columns || 3, trs = [], cur = [];
          (sec.fields || []).filter(function (f) { return !f.when || cond(f.when, ctx, fr); }).forEach(function (f) {
            cur.push(cell(tpl(f.label, ctx, fr), { bold: true, size: 17 }), cell(fieldText(f, ctx, fr), { size: 17 }));
            if (cur.length === n * 2) { trs.push(new D.TableRow({ children: cur })); cur = []; }
          });
          if (cur.length) { while (cur.length < n * 2) { cur.push(cell('')); } trs.push(new D.TableRow({ children: cur })); }
          if (trs.length) {
            var cw = []; for (var i = 0; i < n * 2; i++) { cw.push(Math.round(usable / (n * 2))); }
            kids.push(new D.Table({ rows: trs, width: { size: usable, type: D.WidthType.DXA }, columnWidths: cw, borders: noB }), spacer());
          }
        } else if (t === 'alerta') {
          rowsOf(sec, ctx).filter(function (x) { return cond(sec.when, ctx, x); }).slice(0, sec.each ? 999 : 1).forEach(function (x) {
            kids.push(new D.Table({ rows: [new D.TableRow({ children: [cell(tpl(sec.text, ctx, x), { bold: true, size: 17, fill: colorOf(sec.color, ctx, x) || '#E6ECF2' })] })],
                                    width: { size: usable, type: D.WidthType.DXA }, columnWidths: [usable], borders: noB }), spacer());
          });
        } else if (t === 'tabla') {
          var rows = rowsOf(sec, ctx);
          if (!rows.length && sec.hideEmpty !== false && !sec.emptyText) { return; }
          var cols = columnsOf(sec, ctx, rows), trs2 = [];
          if (sec.title) {
            trs2.push(new D.TableRow({ tableHeader: true, children: [cell(tpl(sec.title, ctx), { bold: true, color: th.headText, fill: th.primary, span: cols.length, size: szT + 2 })] }));
          }
          if (sec.groups) {
            trs2.push(new D.TableRow({ tableHeader: true, children: groupsOf(sec, cols).map(function (g) {
              return cell(g.label || '', { bold: true, color: th.headText, fill: th.primary, align: 'center', span: g.cols }); }) }));
          }
          trs2.push(new D.TableRow({ tableHeader: true, children: cols.map(function (c) {
            return cell(c.label, { bold: true, color: th.headText, fill: th.primary, align: 'center' }); }) }));
          if (!rows.length) {
            trs2.push(new D.TableRow({ children: [cell(tpl(sec.emptyText, ctx), { italic: true, span: cols.length })] }));
          }
          var sset = subCols(sec);
          /* Fila(s) de totales: texto combinado hasta la primera columna con agregado */
          var wordAgg = function (ar) {
            var lab = cell(ar.text, { bold: true, align: 'left', fill: th.totals, span: ar.at || cols.length });
            var vals = ar.cells.slice(ar.at).map(function (t) { return cell(t, { bold: true, align: 'right', fill: th.totals }); });
            return ar.at === 0 ? [new D.TableRow({ cantSplit: true, children: [lab] }), new D.TableRow({ cantSplit: true, children: vals })]
                               : [new D.TableRow({ cantSplit: true, children: [lab].concat(vals) })];
          };
          tableItems(sec, rows).forEach(function (it) {
            if (it.k === 'head') {
              trs2.push(new D.TableRow({ cantSplit: true, children: [cell(breakText(sec, it, ctx), { bold: true, fill: th.group, span: cols.length })] }));
              return;
            }
            if (it.k === 'sub') {
              wordAgg(aggRow(cols, sset, it.rows, breakText(sec, it, ctx))).forEach(function (tr) { trs2.push(tr); });
              return;
            }
            var row = it.r, ri = it.i;
            var rs = styleOf(sec.rowStyle, ctx, row);
            trs2.push(new D.TableRow({ cantSplit: true, children: cols.map(function (c) {
              var st = styleOf(c.cellStyle, ctx, row) || rs || {};
              return cell(cellText(c, row, ctx), { align: c.align, bold: c.bold || st.bold, color: st.color || c.color,
                                                   fill: st.fill || (ri % 2 === 1 && sec.zebra !== false ? th.zebra : null) });
            }) }));
          });
          if (aggList(sec.totals).length && rows.length) {
            wordAgg(aggRow(cols, aggList(sec.totals), rows, totText(sec, ctx, rows))).forEach(function (tr) { trs2.push(tr); });
          }
          var wts = cols.map(function (c) { return c.width ? c.width / 20 : 1; }), tw = wts.reduce(function (a, b) { return a + b; }, 0);
          var cws = wts.map(function (x) { return Math.floor(usable * x / tw); });
          kids.push(new D.Table({ rows: trs2, width: { size: usable, type: D.WidthType.DXA }, columnWidths: cws, borders: gridB }), spacer());
        }
      });
      var ft = layout.footer, wh = wmHeader(ctx);
      return {
        headers: wh ? { default: wh } : undefined,
        properties: { page: { size: { width: dims[0], height: dims[1], orientation: land ? D.PageOrientation.LANDSCAPE : D.PageOrientation.PORTRAIT },
                              margin: { top: mg, bottom: mg, left: mg, right: mg } } },
        footers: ft ? { default: new D.Footer({ children: docxFooter(ft, ctx, th) }) } : undefined,
        children: kids.length ? kids : [para('')]
      };
    });
    var d = new D.Document({ creator: 'novaReport', title: tpl(layout.title || '', ctxs[0] || { S: {}, T: {} }), sections: sections });
    return D.Packer.toBlob ? D.Packer.toBlob(d).then(function (b) { return b.arrayBuffer ? b.arrayBuffer() : b; })
                           : D.Packer.toBuffer(d);
  }

  /* ================================================================== WORD desde plantilla */
  var tplCache = {};
  function getTemplate(url) {
    if (!url) { return Promise.reject(new Error('Defina la URL de la plantilla Word (atributo "Plantilla Word").')); }
    url = imgUrl(url);   /* #APP_FILES#, #WORKSPACE_FILES#, #IMAGE_PREFIX# */
    if (tplCache[url]) { return Promise.resolve(tplCache[url]); }
    return fetch(url, { credentials: 'same-origin' }).then(function (r) {
      if (!r.ok) { throw new Error('No se pudo descargar la plantilla (' + r.status + ')'); }
      return r.arrayBuffer();
    }).then(function (b) { tplCache[url] = b; return b; });
  }
  function tplData(ctx) {
    var d = {}, k;
    for (k in ctx.params || {}) { d[k] = ctx.params[k]; }
    for (k in ctx.doc || {}) { d[k] = ctx.doc[k]; }
    for (k in ctx.S) { d[k] = ctx.S[k]; }
    d.DOC = ctx.doc || {}; d.PARAM = ctx.params || {}; d.NOW = now(); d.TODAY = today();
    return d;
  }
  function tplParser(tag) {
    var parts = tag.split('|'), path = parts[0].trim(), f = parts[1] ? parts[1].trim() : null;
    return {
      get: function (scope, context) {
        if (path === '.') { return scope; }
        var keys = path.split('.'), list = (context && context.scopeList) ? context.scopeList.slice().reverse() : [scope];
        for (var i = 0; i < list.length; i++) {
          var v = list[i], ok = true;
          for (var j = 0; j < keys.length; j++) {
            if (Array.isArray(v) && j > 0) { v = v[0]; }
            if (v === null || v === undefined || typeof v !== 'object' || !(keys[j] in v)) { ok = false; break; }
            v = v[keys[j]];
          }
          if (ok) { return (f && !Array.isArray(v)) ? fmt(v, f) : v; }
        }
        return undefined;
      }
    };
  }
  function renderDocxTemplate(buf, ctx) {
    var zip = new window.PizZip(buf);
    var Dt = window.docxtemplater;
    var d = new Dt(zip, { paragraphLoop: true, linebreaks: true, parser: tplParser, nullGetter: function () { return ''; } });
    d.render(tplData(ctx));
    return Promise.resolve(d.getZip().generate({ type: 'arraybuffer', compression: 'DEFLATE' }));
  }

  /* ================================================================== datos */
  function normalize(data) {
    var S = {}, T = {};
    Object.keys(data || {}).forEach(function (n) {
      var src = data[n], cols = src.cols || [];
      T[n] = {};
      cols.forEach(function (c) { T[n][c.name] = c.type; });
      S[n] = (src.rows || []).map(function (r) {
        var o = {};
        cols.forEach(function (c, i) { o[c.name] = r[i]; });
        return o;
      });
    });
    return { S: S, T: T };
  }
  function contexts(norm, params) {
    var docs = norm.S.DOCS;
    if (!docs) { return [{ S: norm.S, T: norm.T, doc: {}, params: params }]; }
    var by = {};
    Object.keys(norm.S).forEach(function (n) {
      if (n === 'DOCS' || !Object.prototype.hasOwnProperty.call(norm.T[n], 'DOC_KEY')) { return; }
      var g = by[n] = {};
      norm.S[n].forEach(function (r) { var k = String(r.DOC_KEY); (g[k] = g[k] || []).push(r); });
    });
    return docs.map(function (d) {
      var S = {};
      Object.keys(norm.S).forEach(function (n) {
        S[n] = by[n] ? (by[n][String(d.DOC_KEY)] || []) : norm.S[n];
      });
      S.DOCS = [d];
      return { S: S, T: norm.T, doc: d, params: params };
    });
  }

  /* ================================================================== UI */
  function toast(txt) {
    var el = document.getElementById('nr-avance');
    if (!txt) { if (el) { el.remove(); } return; }
    if (!el) {
      el = document.createElement('div');
      el.id = 'nr-avance';
      el.setAttribute('role', 'status');
      el.style.cssText = 'position:fixed;right:24px;bottom:24px;z-index:1000;padding:14px 18px;border-radius:8px;' +
        'background:#1f4e79;color:#fff;font-size:13px;box-shadow:0 8px 24px rgba(0,0,0,.25);max-width:360px';
      document.body.appendChild(el);
    }
    el.innerHTML = '<span class="fa fa-spinner fa-anim-spin" aria-hidden="true"></span>&nbsp; ' +
      String(txt).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; });
  }
  function loaderOpen(msg) {
    var w = window.open('', '_blank');
    if (!w) { return null; }
    if (typeof window.cotLoader === 'function') {
      try { window.cotLoader(w); var h = w.document.getElementsByTagName('h1')[0]; if (h) { h.textContent = 'Generando reporte'; } } catch (e) {}
    } else {
      w.document.write('<!doctype html><html><head><meta charset="utf-8"><title>Generando reporte…</title><style>' +
        'body{margin:0;height:100vh;display:flex;align-items:center;justify-content:center;font-family:system-ui,sans-serif;background:#f4f6f9;color:#1f4e79}' +
        '.b{text-align:center}.s{width:56px;height:56px;border:5px solid #d6e0ea;border-top-color:#1f4e79;border-radius:50%;animation:r 1s linear infinite;margin:0 auto 18px}' +
        '@keyframes r{to{transform:rotate(360deg)}}h1{font-size:20px;margin:0 0 6px}p{margin:0;color:#5b6b7b}</style></head>' +
        '<body><div class="b"><div class="s"></div><h1>Generando reporte</h1><p id="msg"></p></div></body></html>');
      w.document.close();
    }
    loaderMsg(w, msg);
    return w;
  }
  function loaderMsg(w, msg) {
    if (!w || w.closed) { return; }
    try {
      if (typeof window.cotLoaderMsg === 'function') { window.cotLoaderMsg(w, msg); }
      else { var p = w.document.getElementById('msg'); if (p) { p.textContent = msg; } }
    } catch (e) {}
  }
  function download(data, name, mime) {
    var blob = data instanceof Blob ? data : new Blob([data], { type: mime || 'application/octet-stream' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a); a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 4000);
  }
  /* Guardar en el servidor: sube el archivo en base64 (trozos de 30 000 en f01) a un proceso AJAX de la aplicación.
     x01 = nombre, x02 = MIME, x03 = reporte, x04 = parámetros (JSON), x05 = tipo (pdf|xlsx|docx|zip).
     El proceso puede responder { "ok": false, "msg": "..." } para informar un error. */
  function saveServer(out, sv, info) {
    var mime = out.kind === 'zip' ? 'application/zip' : MIME[out.kind] || MIME.docx;
    var blob = out.data instanceof Blob ? out.data : new Blob([out.data], { type: mime });
    return new Promise(function (resolve, reject) {
      var fr = new FileReader();
      fr.onerror = function () { reject(new Error('No se pudo leer el archivo generado.')); };
      fr.onload = function () {
        var b = String(fr.result).replace(/^data:[^,]*,/, ''), parts = [], i;
        for (i = 0; i < b.length; i += 30000) { parts.push(b.substr(i, 30000)); }
        apex.server.process(sv.process, { x01: out.name, x02: mime, x03: info.report === undefined ? '' : String(info.report),
                                          x04: JSON.stringify(info.params || {}), x05: out.kind, f01: parts }, { dataType: 'json' })
          .then(function (r) {
            if (r && r.ok === false) { reject(new Error(r.msg || 'El servidor no guardó el documento.')); return; }
            resolve(r || {});
          }, function (x, st, e) { reject(new Error('No se pudo guardar en el servidor: ' + (e || st))); });
      };
      fr.readAsDataURL(blob);
    });
  }
  function fire(name, data) {
    try { if (window.apex && apex.event) { apex.event.trigger(document, 'novareport-' + name, data); } } catch (e) {}
  }
  function alertMsg(m) { if (window.apex && apex.message) { apex.message.alert(m); } else { window.alert(m); } }
  function okMsg(m) { if (window.apex && apex.message) { apex.message.showPageSuccess(m); } }

  /* ================================================================== generación */
  var MIME = { pdf: 'application/pdf', xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
               docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' };
  var EXT = { pdf: 'pdf', xlsx: 'xlsx', docx: 'docx', 'docx-template': 'docx' };

  function fileName(layout, ctx, f) {
    var n = tpl(layout.fileName || 'reporte', ctx), ext = EXT[f];
    n = n.replace(/\.(pdf|xlsx|docx)$/i, '');
    return safeName(n) + '.' + ext;
  }
  function renderOne(f, layout, ctxs, opt) {
    if (f === 'pdf') { return renderPdf(layout, ctxs, opt.hooks); }
    if (f === 'xlsx') { return renderXlsx(layout, ctxs, ctxs.length > 1); }
    if (f === 'docx') { return renderDocx(layout, ctxs); }
    if (f === 'docx-template') {
      return getTemplate(opt.templateUrl).then(function (b) { return renderDocxTemplate(b, ctxs[0]); });
    }
    return Promise.reject(new Error('Formato no soportado: ' + f));
  }

  /* Núcleo: recibe datos ya obtenidos (sirve también para pruebas sin APEX) */
  function build(opt, data) {
    var lay = parseLayout(opt.layout), o2 = {}, k;
    for (k in opt) { o2[k] = opt[k]; }
    o2.layout = lay;
    return preloadImages(lay).then(function () { return buildCore(o2, data); });
  }
  function buildCore(opt, data) {
    var layout = parseLayout(opt.layout), formats = opt.format === 'all' ? ['pdf', 'xlsx', 'docx'] : [opt.format || 'pdf'];
    var norm = normalize(data), ctxs = contexts(norm, opt.params || {});
    var output = opt.output || 'file';
    if (!ctxs.length) { return Promise.reject(new Error(opt.emptyMessage || layout.emptyMessage || 'No hay datos para generar el reporte.')); }
    if (layout.batch && layout.batch.maxDocs && ctxs.length > layout.batch.maxDocs) {
      return Promise.reject(new Error('El lote supera el máximo de ' + layout.batch.maxDocs + ' documentos.'));
    }
    var single = (output === 'file' && ctxs.length === 1 && formats.length === 1) || (output === 'merge' && formats.length === 1 && formats[0] !== 'docx-template');
    if (single) {
      var f0 = formats[0];
      return renderOne(f0, layout, ctxs, opt).then(function (buf) {
        var nm = fileName(layout, ctxs[0], f0);
        if (ctxs.length > 1) {  /* merge: nombre del lote, no del primer documento */
          var mb = (layout.batch && (layout.batch.mergeName || layout.batch.zipName)) || layout.fileName || 'reporte';
          nm = fileName({ fileName: String(mb).replace(/\.zip$/i, '') }, { S: norm.S, T: norm.T, doc: {}, params: opt.params || {} }, f0);
        }
        return { kind: f0, data: buf, name: nm, count: ctxs.length };
      });
    }
    /* ZIP: un archivo por documento y formato */
    var zip = new window.JSZip(), files = 0, i = 0, chunk = (layout.batch && layout.batch.chunkSize) || 5;
    var gp = {}, k0;
    for (k0 in opt.params || {}) { gp[k0] = opt.params[k0]; }
    gp.FORMATO = formats.length > 1 ? 'todos' : ({ pdf: 'pdf', xlsx: 'excel', docx: 'word', 'docx-template': 'word' }[formats[0]]);
    var gctx = { S: norm.S, T: norm.T, doc: {}, params: gp }, names = {};
    function add(name, buf) {
      var n = name, k = 2;
      while (names[n.toLowerCase()]) { n = name.replace(/(\.[^.]+)$/, '_' + k + '$1'); k++; }
      names[n.toLowerCase()] = true;
      zip.file(n, buf); files++;
    }
    var start = Promise.resolve();
    var sm = layout.batch && layout.batch.summary;
    if (sm && output === 'zip') {
      start = formats.filter(function (f) { return f !== 'docx-template'; }).reduce(function (p, f) {
        return p.then(function () {
          var sl = sm.layout || { page: layout.page, footer: sm.footer || layout.footer, sections: sm.sections, xlsx: sm.xlsx, fileName: sm.fileName };
          if (!sl.fileName) { sl.fileName = sm.fileName || '00_resumen'; }
          return renderOne(f, sl, [gctx], opt).then(function (b) { add(fileName(sl, gctx, f), b); });
        });
      }, start);
    }
    return start.then(function () {
      return new Promise(function (resolve, reject) {
        function step() {
          var end = Math.min(i + chunk, ctxs.length), p = Promise.resolve();
          for (; i < end; i++) {
            (function (c) {
              formats.forEach(function (f) {
                p = p.then(function () { return renderOne(f, layout, [c], opt).then(function (b) { add(fileName(layout, c, f), b); }); });
              });
            })(ctxs[i]);
          }
          p.then(function () {
            if (opt.onProgress) { opt.onProgress(i, ctxs.length); }
            if (i < ctxs.length) { setTimeout(step, 0); return; }
            if (opt.onProgress) { opt.onProgress(-1, files); }
            zip.generateAsync({ type: opt.zipType || 'blob', compression: 'DEFLATE', compressionOptions: { level: 6 } }).then(function (z) {
              var zn = tpl((layout.batch && layout.batch.zipName) || 'reportes.zip', gctx);
              resolve({ kind: 'zip', data: z, name: safeName(/\.zip$/i.test(zn) ? zn : zn + '.zip'), count: ctxs.length, files: files });
            }, reject);
          }, reject);
        }
        setTimeout(step, 0);
      });
    });
  }

  function libsFor(formats, needZip) {
    var l = [];
    formats.forEach(function (f) { (NEEDS[f] || []).forEach(function (x) { if (l.indexOf(x) < 0) { l.push(x); } }); });
    if (needZip) { l.push('jszip'); }
    return l;
  }
  /* Librerías que pide el diseño: códigos QR y gráficos */
  function layoutLibs(layout) {
    var l = [];
    function scan(list) {
      (list || []).forEach(function (s) {
        if (!s) { return; }
        if (s.type === 'codigo' && String(s.kind || 'qr').toLowerCase() === 'qr' && l.indexOf('qrcode') < 0) { l.push('qrcode'); }
        if (s.type === 'grafico' && l.indexOf('chartjs') < 0) { l.push('chartjs'); }
        if (s.type === 'columnas') { (s.cols || []).forEach(scan); }
      });
    }
    scan(layout.sections);
    var sm = layout.batch && layout.batch.summary;
    if (sm) { scan(sm.sections); if (sm.layout) { scan(sm.layout.sections); } }
    return l;
  }
  /* "@NOMBRE" se reemplaza por layout.defs.NOMBRE (reutilizar columnas, estilos, secciones) */
  function resolveDefs(node, defs) {
    if (typeof node === 'string' && node.charAt(0) === '@' && defs && defs[node.substr(1)] !== undefined) {
      return resolveDefs(defs[node.substr(1)], defs);
    }
    if (Array.isArray(node)) {  /* "@X" dentro de un arreglo, si X es arreglo, se expande en su lugar */
      return node.reduce(function (acc, x) {
        var isRef = typeof x === 'string' && x.charAt(0) === '@' && defs && Array.isArray(defs[x.substr(1)]);
        var v = resolveDefs(x, defs);
        return isRef ? acc.concat(v) : acc.concat([v]);
      }, []);
    }
    if (node && typeof node === 'object') {
      var o = {};
      Object.keys(node).forEach(function (k) { o[k] = k === 'defs' ? node[k] : resolveDefs(node[k], defs); });
      return o;
    }
    return node;
  }
  function parseLayout(v) {
    var o;
    if (v && typeof v === 'object') { o = v; }
    else {
      var s = String(v || '').trim();
      if (s.charAt(0) === '{') { o = JSON.parse(s); }
      else {
        /* Referencia a una variable global: p. ej. misLayouts.planPdf */
        o = s.split('.').reduce(function (a, k) { return a ? a[k] : undefined; }, window);
        if (!o) { throw new Error('No se encontró el diseño: ' + s); }
      }
    }
    return resolveDefs(o, o.defs);
  }

  /* Ítems a enviar: arreglo, selector jQuery ('#P5_A,#P5_B') o lista de nombres ('P5_A,P5_B', atributo del plugin) */
  function itemsOf(v) {
    if (!v) { return undefined; }
    if (Array.isArray(v) || typeof v !== 'string' || /[#.\[]/.test(v)) { return v; }
    var a = v.split(',').map(function (x) { return x.trim(); }).filter(Boolean);
    return a.length ? a : undefined;
  }
  /* API pública: novaReport.run({...}) */
  function run(o) {
    var formats = o.format === 'all' ? ['pdf', 'xlsx', 'docx'] : [o.format || 'pdf'];
    var openPdf = formats.length === 1 && formats[0] === 'pdf' && o.output !== 'zip' && o.pdfAction !== 'download';
    var w = openPdf && o.loader !== false ? loaderOpen(o.message || 'Consultando datos…') : null;
    var sp = (window.apex && apex.util) ? apex.util.showSpinner() : null;
    /* Origen "resolver": el diseño y las fuentes los decide el servidor a partir de o.report + o.params */
    var resolver = o.origin === 'resolver' && !o.data;
    var layout;
    if (!resolver) {
      try { layout = parseLayout(o.layout); } catch (e) { if (sp) { sp.remove(); } if (w) { w.close(); } alertMsg('Diseño inválido: ' + e.message); return Promise.reject(e); }
    }
    var opt = { layout: layout, format: o.format, output: o.output, params: o.params || {}, templateUrl: o.templateUrl, hooks: o.hooks || {} };
    fire('start', { format: o.format, output: o.output, report: resolver ? o.report : undefined });
    var needZip = o.output !== 'merge';
    var libs = ensure(libsFor(formats, needZip).concat(resolver ? [] : layoutLibs(layout)));
    var req = o.data ? Promise.resolve({ data: o.data }) : new Promise(function (resolve, reject) {
      var q = { x01: JSON.stringify(opt.params), x02: o.output === 'zip' ? 'Y' : 'N', pageItems: itemsOf(o.items) };
      if (resolver) {
        if (o.report === undefined || o.report === null || o.report === '') { reject(new Error('Indique el reporte a generar (data-report).')); return; }
        q.x03 = String(o.report);
      }
      apex.server.plugin(o.ajaxIdentifier, q, { dataType: 'json' }).then(function (r) {
        if (!r || !r.ok) { reject(new Error((r && r.msg) || 'Error al obtener los datos.')); return; }
        resolve(r);
      }, function (x, s, e) { reject(new Error('Error de comunicación: ' + (e || s))); });
    });
    return Promise.all([req, libs]).then(function (res) {
      var r = res[0], more = Promise.resolve();
      if (resolver) {
        try { layout = parseLayout(r.layout); } catch (e) { throw new Error('Diseño inválido: ' + e.message); }
        opt.layout = layout;
        if (r.params) { opt.params = r.params; }
        if (r.templateUrl) { opt.templateUrl = r.templateUrl; }
        more = ensure(layoutLibs(layout));
      }
      return more.then(function () { return r.data; });
    }).then(function (raw) {
      if (sp) { sp.remove(); sp = null; }
      var data = o.transform ? (o.transform(raw) || raw) : raw;
      loaderMsg(w, 'Armando el documento…');
      opt.onProgress = function (n, total) {
        if (n === -1) { toast('Comprimiendo ' + total + ' archivos…'); }
        else { toast('Generando ' + n + ' de ' + total + '…'); fire('progress', { done: n, total: total }); }
      };
      return build(opt, data);
    }).then(function (out) {
      var sv = o.save || (opt.layout && opt.layout.save);
      if (!sv || !sv.process) { return out; }
      if (!(window.apex && apex.server)) { throw new Error('Guardar en el servidor requiere APEX.'); }
      toast('Guardando en el servidor…');
      return saveServer(out, sv, { report: o.report, params: opt.params }).then(function (r) {
        out.saved = r; out.only = sv.mode === 'only';
        fire('saved', { name: out.name, kind: out.kind, response: r });
        return out;
      });
    }).then(function (out) {
      toast();
      if (out.only) {
        if (w) { w.close(); }
        okMsg((out.saved && out.saved.msg) || ('Documento guardado: ' + out.name));
      } else if (out.kind === 'pdf' && openPdf) {
        var url = URL.createObjectURL(new Blob([out.data], { type: MIME.pdf }));
        if (w && !w.closed) { w.location.href = url; } else { window.open(url, '_blank'); }
      } else {
        if (w) { w.close(); }
        download(out.data, out.name, out.kind === 'zip' ? 'application/zip' : MIME[out.kind] || MIME.docx);
        if (out.kind === 'zip') { okMsg('ZIP generado: ' + out.files + ' archivos de ' + out.count + ' documentos.'); }
      }
      fire('end', { name: out.name, count: out.count, files: out.files });
      return out;
    }).catch(function (e) {
      if (sp) { sp.remove(); }
      toast();
      if (w && !w.closed) { w.close(); }
      if (window.console) { console.error(e); }
      fire('error', { message: e.message });
      alertMsg(e.message || 'No se pudo generar el reporte.');
      throw e;
    });
  }

  /* Punto de entrada de la Acción Dinámica.
     APEX 26.1 (API v2): novaReport.da recibe un objeto con la configuración (function_param).
     Compatible con v1: this.action.attributeNN + función init. */
  var busy = false, lastEl = null;
  if (typeof document !== 'undefined' && document.addEventListener) {
    document.addEventListener('click', function (e) {
      lastEl = e.target && e.target.closest ? (e.target.closest('a,button,[data-output],[data-format]') || e.target) : e.target;
    }, true);
  }
  function da(p) {
    var self = (this && this.action) ? this : {}, a = self.action || {};
    var el = self.triggeringElement || lastEl, ev = self.browserEvent;
    if (ev && ev.preventDefault) { ev.preventDefault(); }
    if (busy) { return; }
    var cfg = (p && typeof p === 'object') ? p : {};
    var init = typeof p === 'function' ? p : cfg.init;
    var params = {}, ds = (el && el.dataset) || {}, report = cfg.report;
    var out = cfg.output || a.attribute03 || 'file', fmtV = cfg.format || a.attribute02 || 'pdf';
    Object.keys(ds).forEach(function (k) {
      if (k === 'output') { out = ds[k]; return; }
      if (k === 'format') { fmtV = ds[k]; return; }
      if (k === 'report') { report = ds[k]; return; }
      params[k.replace(/([A-Z])/g, '_$1').toUpperCase()] = ds[k];
    });
    var o = { layout: cfg.layout || a.attribute01, format: fmtV, output: out, items: cfg.items || a.attribute04 || '',
              pdfAction: cfg.pdfAction || a.attribute05 || 'open', templateUrl: cfg.templateUrl || a.attribute06,
              message: cfg.message || a.attribute07, params: params, ajaxIdentifier: cfg.ajaxIdentifier || a.ajaxIdentifier,
              origin: cfg.origin || 'attributes', report: report, save: cfg.save };
    if (typeof init === 'function') {
      var r0 = init(o);
      if (r0 === false) { return; }           /* init puede cancelar (p. ej. validación de un formulario) */
      o = r0 || o;
    }
    busy = true;
    run(o).then(function () { busy = false; }, function () { busy = false; });
  }

  return { version: VERSION, libs: LIBS, run: run, da: da, build: build, ensure: ensure, layoutLibs: layoutLibs,
           _internals: { IMG: IMG, imgDims: imgDims, tpl: tpl, cond: cond, fmt: fmt, normalize: normalize, contexts: contexts,
                         code128: code128, png1: png1, layoutLibs: layoutLibs } };
})();
