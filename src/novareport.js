/*!
 * novaReport 1.6.1 - Reportes PDF / Excel / Word para Oracle APEX
 * https://github.com/danielramirezasyn/novareport - Licencia MIT
 * NovaCode - plugin de Acción Dinámica COM.NOVACODE.NOVAREPORT
 *
 * Motor de layout: un mismo diseño (JSON) y unas mismas fuentes SQL generan
 * PDF (jsPDF + autotable), Excel con estilos (ExcelJS), Word (docx) o Word desde
 * plantilla (docxtemplater). Modo lote: un archivo por documento en un ZIP (JSZip).
 */
window.novaReport = (function () {
  'use strict';

  var VERSION = '1.6.1';

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
                     ok: function () { return !!window.docxtemplater; } }
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
                text: '#000000', muted: '#787878', fontSize: 7 };

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
    return String(v);
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
    return String(str).replace(/\{([A-Za-z0-9_$#.]+)(?:\|([A-Za-z0-9:]+))?\}/g, function (m, k, f) {
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
    return cols.map(function (c) {
      c = typeof c === 'string' ? { col: c } : c;
      var name = c.col ? String(c.col).toUpperCase() : null, t = name ? types[name] : null, f = c.fmt;
      if (!f && t === 'NUMBER' && !c.value) {
        f = rows.some(function (r) { return isNum(r[name]) && Math.round(r[name]) !== r[name]; }) ? 'money' : null;
      }
      return { col: name, value: c.value, label: c.label !== undefined ? c.label : label(name || ''),
               fmt: f, map: c.map, bold: !!c.bold, width: c.width,
               align: c.align || (t === 'NUMBER' || f === 'money' || f === 'int' || f === 'num' ? 'right' : (t === 'DATE' || f === 'date' ? 'center' : 'left')),
               cellStyle: c.cellStyle, color: c.color, isNum: (t === 'NUMBER' && !c.map && !c.value) || f === 'money' || f === 'int' || /^num/.test(f || '') };
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
  function totalOf(rows, col) {
    return rows.reduce(function (s, r) { return s + (Number(r[col]) || 0); }, 0);
  }
  function fieldText(f, ctx, row) {
    if (f.map) { var k = lookup(ctx, String(f.value).replace(/[{}]/g, '').split('|')[0], row); return f.map[k] !== undefined ? f.map[k] : String(k || ''); }
    var v = f.value;
    if (f.fmt && /^\{[^}|]+\}$/.test(v || '')) { return fmt(lookup(ctx, v.slice(1, -1), row), f.fmt); }
    return tpl(v, ctx, row);
  }
  function sectionsFor(layout, format) {
    return (layout.sections || []).filter(function (s) { return !s.formats || s.formats.indexOf(format) >= 0; });
  }
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
    function scan(list) { (list || []).forEach(function (s) { if (s && s.type === 'imagen' && s.url && !s.field) { out.push(s.url); } }); }
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
    return { w: w, h: h };
  }

  /* ================================================================== PDF */
  function renderPdf(layout, ctxs, hooks) {
    var page = layout.page || {}, th = themeOf(layout), sz = th.fontSize;
    var doc = new window.jspdf.jsPDF({ orientation: page.orientation || 'portrait', unit: 'mm', format: page.size || 'letter', compress: true });
    var W = doc.internal.pageSize.getWidth(), H = doc.internal.pageSize.getHeight(), M = page.margin || 8;
    var P = hexRgb(th.primary), HT = hexRgb(th.headText), Z = hexRgb(th.zebra), TT = hexRgb(th.totals);
    var y = M, firstDoc = true;

    function last() { return doc.lastAutoTable ? doc.lastAutoTable.finalY : y; }
    function gap(n) { y = last() + (n || 2); }

    ctxs.forEach(function (ctx) {
      if (!firstDoc) { doc.addPage(); }
      firstDoc = false;
      y = M;
      doc.lastAutoTable = null;
      sectionsFor(layout, 'pdf').forEach(function (sec) {
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
          var x0 = (sec.x !== undefined ? sec.x : M) + (sec.indent || 0), maxW = sec.width || (W - M - x0);
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
          var lw = sec.width || (W - 2 * M), lx = sec.align === 'center' ? (W - lw) / 2 : (sec.align === 'right' ? W - M - lw : M);
          doc.line(lx, y, lx + lw, y);
          y += sec.gap !== undefined ? sec.gap : 2; doc.lastAutoTable = { finalY: y };
          return;
        }
        if (t === 'espacio') { y = Math.max(y, doc.lastAutoTable ? doc.lastAutoTable.finalY : y) + (sec.height || 6); doc.lastAutoTable = { finalY: y }; return; }
        if (t === 'imagen') {
          var im = imgOf(sec, ctx);
          if (!im) { return; }
          var szI = imgSize(sec, im), fmtI = im.ext === 'jpg' ? 'JPEG' : 'PNG';
          var ix = sec.x !== undefined ? sec.x : (sec.align === 'right' ? W - M - szI.w : (sec.align === 'center' ? (W - szI.w) / 2 : M));
          if (sec.y !== undefined) { doc.addImage(im.data, fmtI, ix, sec.y, szI.w, szI.h); return; }
          y = Math.max(y, doc.lastAutoTable ? doc.lastAutoTable.finalY : y);
          if (y + szI.h > H - M - 10) { doc.addPage(); y = M; }
          doc.addImage(im.data, fmtI, ix, y, szI.w, szI.h);
          y += szI.h + (sec.gap !== undefined ? sec.gap : 3); doc.lastAutoTable = { finalY: y };
          return;
        }
        if (t === 'salto') { doc.addPage(); y = M; doc.lastAutoTable = { finalY: M }; return; }
        if (t === 'ficha') {
          var fr = rowsOf(sec, ctx)[0] || {}, n = sec.columns || 3, body = [], cur = [], cs = {};
          (sec.fields || []).filter(function (f) { return !f.when || cond(f.when, ctx, fr); }).forEach(function (f) {
            cur.push(tpl(f.label, ctx, fr), fieldText(f, ctx, fr));
            if (cur.length === n * 2) { body.push(cur); cur = []; }
          });
          if (cur.length) { while (cur.length < n * 2) { cur.push(''); } body.push(cur); }
          for (var i = 0; i < n * 2; i += 2) { cs[i] = { fontStyle: 'bold', cellWidth: sec.labelWidth || 32 }; }
          doc.autoTable({ startY: y, body: body, theme: 'plain', margin: { left: M, right: M },
                          styles: { fontSize: sec.size || 8.5, cellPadding: 0.9 }, columnStyles: cs });
          gap(2);
          return;
        }
        if (t === 'alerta') {
          rowsOf(sec, ctx).filter(function (r) { return cond(sec.when, ctx, r); }).slice(0, sec.each ? 999 : 1).forEach(function (r) {
            doc.autoTable({ startY: y, theme: 'plain', margin: { left: M, right: M }, body: [[tpl(sec.text, ctx, r)]],
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
          var body = rows.length ? rows.map(function (r) { return cols.map(function (c) { return cellText(c, r, ctx); }); })
                                 : [[{ content: tpl(sec.emptyText, ctx), colSpan: cols.length, styles: { halign: 'left', fontStyle: 'italic' } }]];
          var foot = null;
          if (sec.totals && rows.length) {
            var tset = sec.totals.map(function (x) { return String(x).toUpperCase(); }), lbl = false;
            foot = [cols.map(function (c) {
              if (c.col && tset.indexOf(c.col) >= 0) { return fmt(totalOf(rows, c.col), c.fmt || 'money'); }
              if (!lbl && !(c.col && tset.indexOf(c.col) >= 0)) { lbl = true; return sec.totalsLabel || 'Totales'; }
              return '';
            })];
          }
          doc.autoTable({
            startY: y, margin: { left: M, right: M }, head: head, body: body, foot: foot || undefined,
            showHead: sec.repeatHeader === false ? 'firstPage' : 'everyPage', showFoot: 'lastPage',
            styles: { fontSize: sec.size || sz, cellPadding: 0.8 },
            headStyles: { fillColor: P, textColor: HT, halign: 'center', fontSize: sec.size || sz },
            footStyles: { fillColor: TT, textColor: 0, fontStyle: 'bold', halign: 'right' },
            alternateRowStyles: { fillColor: Z },
            columnStyles: colSt,
            didParseCell: function (h) {
              if (h.section !== 'body' || !rows.length) { return; }
              var r = rows[h.row.index], c = cols[h.column.index];
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
        var maxC = 4, r = 1, widths = {}, tables = 0, freezeAt = null, filterRef = null;
        list.forEach(function (s) {
          if (s.type === 'tabla') { tables++; maxC = Math.max(maxC, columnsOf(s, ctx, rowsOf(s, ctx)).length); }
          if (s.type === 'ficha') { maxC = Math.max(maxC, (s.columns || 3) * 2); }
        });
        function setW(c, txt) { var l = String(txt === null || txt === undefined ? '' : txt).length; widths[c] = Math.min(60, Math.max(widths[c] || 8, l + 2)); }
        function band(text, f, font, height) {
          ws.mergeCells(r, 1, r, maxC);
          var cell = ws.getCell(r, 1);
          cell.value = text; cell.fill = f; cell.font = font; cell.alignment = { vertical: 'middle', wrapText: true };
          if (height) { ws.getRow(r).height = height; }
          r++;
        }
        list.forEach(function (sec) {
          var t = sec.type;
          if (t === 'header') {
            band(tpl(sec.title, ctx), fillP, { bold: true, size: 14, color: { argb: argb(th.headText) } }, 26);
            if (sec.right || sec.subtitle) {
              band([tpl(sec.subtitle, ctx), tpl(sec.right, ctx)].filter(Boolean).join('   |   '), fillP,
                   { size: 9, color: { argb: argb(th.headText) } }, 16);
            }
            r++;
          } else if (t === 'texto') {
            paragraphsOf(sec, ctx).forEach(function (para) {
              ws.mergeCells(r, 1, r, maxC);
              var cx = ws.getCell(r, 1);
              cx.value = { richText: richRuns(para, { font: sec.font || (layout.page && layout.page.font), color: sec.color }).map(function (x) {
                return { text: x.t, font: { bold: !!(x.b || sec.bold), italic: !!(x.i || sec.italic), underline: x.u || undefined, strike: x.s || undefined,
                                            name: FONTS[x.f][1], color: x.c ? { argb: argb(x.c) } : undefined, size: sec.size || 10 } }; }) };
              cx.alignment = { wrapText: true, vertical: 'top', horizontal: sec.align === 'justify' ? 'justify' : (sec.align || 'left') };
              ws.getRow(r).height = Math.max(15, Math.ceil(para.length / 140) * 15);
              r++;
            });
          } else if (t === 'espacio') {
            r++;
          } else if (t === 'imagen') {
            var imx = imgOf(sec, ctx);
            if (imx) {
              var szx = imgSize(sec, imx), idx = wb.addImage({ base64: imx.data, extension: imx.ext === 'jpg' ? 'jpeg' : 'png' });
              ws.addImage(idx, { tl: { col: 0, row: r - 1 }, ext: { width: szx.w * 3.78, height: szx.h * 3.78 } });
              r += Math.ceil(szx.h * 3.78 / 20) + 1;
            }
          } else if (t === 'salto') {
            r++;
          } else if (t === 'ficha') {
            var fr = rowsOf(sec, ctx)[0] || {}, n = sec.columns || 3, c = 1;
            (sec.fields || []).filter(function (f) { return !f.when || cond(f.when, ctx, fr); }).forEach(function (f, i) {
              if (i > 0 && i % n === 0) { r++; c = 1; }
              var lc = ws.getCell(r, c), vc = ws.getCell(r, c + 1), lt = tpl(f.label, ctx, fr);
              lc.value = lt; lc.font = { bold: true };
              var raw = (/^\{[^}|]+\}$/.test(f.value || '') && !f.map) ? lookup(ctx, f.value.slice(1, -1), fr) : null;
              if (isNum(raw)) { vc.value = raw; if (f.fmt === 'money') { vc.numFmt = '#,##0.00'; } vc.alignment = { horizontal: 'left' }; }
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
              ws.mergeCells(r, 1, r, cols.length);
              var tc = ws.getCell(r, 1);
              tc.value = tpl(sec.title, ctx); tc.font = { bold: true, color: { argb: argb(th.headText) } }; tc.fill = fillP;
              r++;
            }
            if (sec.groups) {
              var gc = 1;
              groupsOf(sec, cols).forEach(function (g) {
                if (g.cols > 1 && !g.gap) { ws.mergeCells(r, gc, r, gc + g.cols - 1); }
                var gcell = ws.getCell(r, gc);
                if (g.gap) {
                  for (var gi = 0; gi < g.cols; gi++) {
                    ws.mergeCells(r, gc + gi, r + 1, gc + gi);
                    var gx = ws.getCell(r, gc + gi);
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
              var h = ws.getCell(r, i + 1);
              h.value = c.label; h.fill = fillP; h.font = { bold: true, color: { argb: argb(th.headText) } };
              h.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
              setW(i + 1, c.label);
            });
            r++;
            if (!rows.length) {
              ws.mergeCells(r, 1, r, cols.length);
              ws.getCell(r, 1).value = tpl(sec.emptyText, ctx); ws.getCell(r, 1).font = { italic: true };
              r += 2; return;
            }
            var first = r;
            rows.forEach(function (row, ri) {
              var rs = styleOf(sec.rowStyle, ctx, row);
              cols.forEach(function (c, i) {
                var cell = ws.getCell(r, i + 1), raw = cellRaw(c, row, ctx);
                if (c.isNum && isNum(raw)) {
                  cell.value = raw;
                  cell.numFmt = c.fmt === 'int' ? '#,##0' : (c.fmt === 'money' || /^num/.test(c.fmt || '') ? '#,##0.' + new Array(((c.fmt || '').split(':')[1] || 2) * 1 + 1).join('0') : 'General');
                } else if ((c.fmt === 'date' || (ctx.T[String(sec.source).toUpperCase()] || {})[c.col] === 'DATE') && parseDate(raw)) {
                  cell.value = parseDate(raw); cell.numFmt = 'dd/mm/yyyy';
                } else {
                  cell.value = raw === null || raw === undefined ? null : String(raw);
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
            if (sec.totals) {
              var tset = sec.totals.map(function (x) { return String(x).toUpperCase(); }), lbl = false;
              cols.forEach(function (c, i) {
                var cell = ws.getCell(r, i + 1), L = ws.getColumn(i + 1).letter;
                if (c.col && tset.indexOf(c.col) >= 0) {
                  cell.value = { formula: 'SUM(' + L + first + ':' + L + (r - 1) + ')', result: Math.round(totalOf(rows, c.col) * 100) / 100 };
                  cell.numFmt = '#,##0.00';
                } else if (!lbl) { lbl = true; cell.value = sec.totalsLabel || 'Totales'; }
                cell.fill = fill(th.totals); cell.font = { bold: true };
              });
              r++;
            }
            if (tables === 1) {
              filterRef = { from: { row: hr, column: 1 }, to: { row: r - 1 - (sec.totals ? 1 : 0), column: cols.length } };
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

    var sections = ctxs.map(function (ctx) {
      var kids = [];
      sectionsFor(layout, 'docx').forEach(function (sec) {
        var t = sec.type;
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
          if (imd) {
            var szd = imgSize(sec, imd);
            kids.push(new D.Paragraph({
              alignment: sec.align === 'right' ? D.AlignmentType.RIGHT : (sec.align === 'center' ? D.AlignmentType.CENTER : D.AlignmentType.LEFT),
              spacing: { after: Math.round((sec.gap !== undefined ? sec.gap : 3) * 56.7) },
              children: [new D.ImageRun({ type: imd.ext === 'jpg' ? 'jpg' : 'png', data: imd.buf,
                                          transformation: { width: Math.round(szd.w * 3.78), height: Math.round(szd.h * 3.78) } })] }));
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
          rows.forEach(function (row, ri) {
            var rs = styleOf(sec.rowStyle, ctx, row);
            trs2.push(new D.TableRow({ cantSplit: true, children: cols.map(function (c) {
              var st = styleOf(c.cellStyle, ctx, row) || rs || {};
              return cell(cellText(c, row, ctx), { align: c.align, bold: c.bold || st.bold, color: st.color || c.color,
                                                   fill: st.fill || (ri % 2 === 1 && sec.zebra !== false ? th.zebra : null) });
            }) }));
          });
          if (sec.totals && rows.length) {
            var tset = sec.totals.map(function (x) { return String(x).toUpperCase(); }), lbl = false;
            trs2.push(new D.TableRow({ children: cols.map(function (c) {
              var txt = '';
              if (c.col && tset.indexOf(c.col) >= 0) { txt = fmt(totalOf(rows, c.col), c.fmt || 'money'); }
              else if (!lbl) { lbl = true; txt = sec.totalsLabel || 'Totales'; }
              return cell(txt, { bold: true, align: 'right', fill: th.totals });
            }) }));
          }
          var wts = cols.map(function (c) { return c.width ? c.width / 20 : 1; }), tw = wts.reduce(function (a, b) { return a + b; }, 0);
          var cws = wts.map(function (x) { return Math.floor(usable * x / tw); });
          kids.push(new D.Table({ rows: trs2, width: { size: usable, type: D.WidthType.DXA }, columnWidths: cws, borders: gridB }), spacer());
        }
      });
      var ft = layout.footer;
      return {
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

  /* API pública: novaReport.run({...}) */
  function run(o) {
    var formats = o.format === 'all' ? ['pdf', 'xlsx', 'docx'] : [o.format || 'pdf'];
    var openPdf = formats.length === 1 && formats[0] === 'pdf' && o.output !== 'zip' && o.pdfAction !== 'download';
    var w = openPdf && o.loader !== false ? loaderOpen(o.message || 'Consultando datos…') : null;
    var sp = (window.apex && apex.util) ? apex.util.showSpinner() : null;
    var layout;
    try { layout = parseLayout(o.layout); } catch (e) { if (sp) { sp.remove(); } if (w) { w.close(); } alertMsg('Diseño inválido: ' + e.message); return Promise.reject(e); }
    var opt = { layout: layout, format: o.format, output: o.output, params: o.params || {}, templateUrl: o.templateUrl, hooks: o.hooks || {} };
    fire('start', { format: o.format, output: o.output });
    var needZip = o.output !== 'merge';
    var libs = ensure(libsFor(formats, needZip));
    var req = o.data ? Promise.resolve(o.data) : new Promise(function (resolve, reject) {
      apex.server.plugin(o.ajaxIdentifier, { x01: JSON.stringify(opt.params), x02: o.output === 'zip' ? 'Y' : 'N', pageItems: o.items || undefined },
                         { dataType: 'json' }).then(function (r) {
        if (!r || !r.ok) { reject(new Error((r && r.msg) || 'Error al obtener los datos.')); return; }
        resolve(r.data);
      }, function (x, s, e) { reject(new Error('Error de comunicación: ' + (e || s))); });
    });
    return Promise.all([req, libs]).then(function (res) {
      if (sp) { sp.remove(); sp = null; }
      var data = o.transform ? (o.transform(res[0]) || res[0]) : res[0];
      loaderMsg(w, 'Armando el documento…');
      opt.onProgress = function (n, total) {
        if (n === -1) { toast('Comprimiendo ' + total + ' archivos…'); }
        else { toast('Generando ' + n + ' de ' + total + '…'); fire('progress', { done: n, total: total }); }
      };
      return build(opt, data);
    }).then(function (out) {
      toast();
      if (out.kind === 'pdf' && openPdf) {
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
    var params = {}, ds = (el && el.dataset) || {};
    var out = cfg.output || a.attribute03 || 'file', fmtV = cfg.format || a.attribute02 || 'pdf';
    Object.keys(ds).forEach(function (k) {
      if (k === 'output') { out = ds[k]; return; }
      if (k === 'format') { fmtV = ds[k]; return; }
      params[k.replace(/([A-Z])/g, '_$1').toUpperCase()] = ds[k];
    });
    var o = { layout: cfg.layout || a.attribute01, format: fmtV, output: out, items: cfg.items || a.attribute04 || '',
              pdfAction: cfg.pdfAction || a.attribute05 || 'open', templateUrl: cfg.templateUrl || a.attribute06,
              message: cfg.message || a.attribute07, params: params, ajaxIdentifier: cfg.ajaxIdentifier || a.ajaxIdentifier };
    if (typeof init === 'function') { o = init(o) || o; }
    busy = true;
    run(o).then(function () { busy = false; }, function () { busy = false; });
  }

  return { version: VERSION, libs: LIBS, run: run, da: da, build: build, ensure: ensure,
           _internals: { IMG: IMG, imgDims: imgDims, tpl: tpl, cond: cond, fmt: fmt, normalize: normalize, contexts: contexts } };
})();
