#!/usr/bin/env node
/*
 * probar.js — genera y valida un reporte novaReport SIN base de datos.
 *
 *   node scripts/probar.js <carpeta> [pdf,xlsx,docx] [file|zip|merge]
 *
 * <carpeta> debe tener:
 *   diseno.json   el diseño
 *   datos.json    datos de prueba con las mismas columnas que fuentes.sql (ver SKILL.md)
 * Deja los archivos en <carpeta>/out/ e imprime advertencias de columnas o fuentes que no existen.
 *
 * Usa el motor y las librerías del repositorio novareport-oss (src/ y test/node_modules).
 * Si el skill está fuera del repositorio: NOVAREPORT_HOME=/ruta/novareport-oss node probar.js ...
 */
'use strict';
const fs = require('fs'), path = require('path'), { createRequire } = require('module');
const HOME = process.env.NOVAREPORT_HOME || path.resolve(__dirname, '..', '..', '..');
const TEST = path.join(HOME, 'test');
if (!fs.existsSync(path.join(TEST, 'node_modules'))) {
  console.error('No encuentro ' + TEST + '/node_modules. Ejecute: cd ' + TEST + ' && npm install');
  process.exit(2);
}
const req = createRequire(path.join(TEST, 'package.json'));

const dir = path.resolve(process.argv[2] || '.');
const formats = (process.argv[3] || 'pdf,xlsx,docx').split(',');
const output = process.argv[4] || 'file';

/* ---------- entorno de navegador mínimo (igual que test/run.js) ---------- */
global.window = global;
global.document = { getElementById() { return null; }, addEventListener() {} };
window.jspdf = req('jspdf'); req('jspdf-autotable');
window.ExcelJS = req('exceljs'); window.JSZip = req('jszip'); window.docx = req('docx');
window.PizZip = req('pizzip'); window.docxtemplater = req('docxtemplater');
window.qrcode = req('qrcode-generator');
{ const m = { exports: {} };
  new Function('module', 'exports', fs.readFileSync(req.resolve('chart.js').replace(/[^\\/]+$/, '') + 'chart.umd.js', 'utf8'))(m, m.exports);
  window.Chart = m.exports; }
let CANVAS = false;
try { const { createCanvas } = req('canvas'); document.createElement = t => t === 'canvas' ? createCanvas(1, 1) : null; CANVAS = true; } catch (e) { /* opcional */ }
/* Imagen de relleno (PNG 1x1 gris) para #APP_FILES#..., que no existe fuera de APEX */
const PIXEL = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mN8+P9/PQAJYAN4Ok6ARwAAAABJRU5ErkJggg==';
window.apex = { item: () => ({ getValue: () => '' }), env: { APP_FILES: 'data:image/png;base64,', WORKSPACE_FILES: 'data:image/png;base64,', IMAGE_PREFIX: 'data:image/png;base64,' } };
const nativeFetch = global.fetch;
global.fetch = async (u, o) => {
  u = String(u);
  if (/^data:/.test(u)) { return nativeFetch(u, o); }
  const f = path.resolve(dir, u);
  if (!fs.existsSync(f)) { return { ok: false, status: 404 }; }
  const b = fs.readFileSync(f);
  return { ok: true, status: 200, arrayBuffer: async () => b.buffer.slice(b.byteOffset, b.byteOffset + b.length) };
};
require(path.join(HOME, 'src', 'novareport.js'));

/* ---------- lectura ---------- */
const readJson = f => {
  try { return JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); }
  catch (e) { console.error('ERROR ' + f + ': ' + e.message); process.exit(1); }
};
const layout = readJson('diseno.json');
const raw = readJson('datos.json');
const params = raw._params || {};

/* datos.json acepta { FUENTE: [ {COL: valor}, ... ] } o el formato del servidor { FUENTE: { cols, rows } } */
const DATE = /^\d{2}\/\d{2}\/\d{4}$/;
const data = {};
Object.keys(raw).filter(k => k[0] !== '_').forEach(k => {
  const v = raw[k], K = k.toUpperCase();
  if (Array.isArray(v)) {
    const names = []; v.forEach(r => Object.keys(r).forEach(c => { if (names.indexOf(c.toUpperCase()) < 0) { names.push(c.toUpperCase()); } }));
    const cols = names.map(n => {
      const vals = v.map(r => r[n] !== undefined ? r[n] : r[n.toLowerCase()]).filter(x => x !== null && x !== undefined && x !== '');
      const type = vals.length && vals.every(x => typeof x === 'number') ? 'NUMBER' : vals.length && vals.every(x => DATE.test(x)) ? 'DATE' : 'VARCHAR2';
      return { name: n, type };
    });
    data[K] = { cols, rows: v.map(r => names.map(n => { const x = r[n] !== undefined ? r[n] : r[n.toLowerCase()]; return x === undefined ? null : x; })) };
  } else { data[K] = v; }
});

/* ---------- validación ---------- */
const warn = [];
const colsOf = s => data[s] ? data[s].cols.map(c => c.name) : null;
const allCols = new Set([].concat(...Object.keys(data).map(colsOf)));
const defs = layout.defs || {};
const RES = new Set(['NOW', 'TODAY', 'PAGE', 'PAGES', 'COUNT', 'FORMATO']);
if (data.DOCS && colsOf('DOCS').indexOf('DOC_KEY') < 0) { warn.push('DOCS no tiene DOC_KEY'); }

function checkName(name, src, where) {
  name = name.toUpperCase();
  const p = name.split('.');
  if (p.length === 1) {
    if (RES.has(name)) { return; }
    const ok = (src && colsOf(src) && colsOf(src).indexOf(name) >= 0) || allCols.has(name) || name in params;
    if (!ok) { warn.push(where + ': columna ' + name + ' no existe en ' + (src || 'ninguna fuente')); }
    return;
  }
  const [f, c] = p;
  if (f === 'PARAM' || f === 'ITEM') { return; }
  const fuente = f === 'DOC' ? 'DOCS' : f;
  if (!data[fuente]) { warn.push(where + ': fuente ' + fuente + ' no existe (' + name + ')'); return; }
  if (colsOf(fuente).indexOf(c) < 0) { warn.push(where + ': ' + fuente + ' no tiene la columna ' + c); }
}
function checkTpl(s, src, where) {
  String(s).replace(/\{([#/]?)([A-Za-z_][\w.]*)(\|[^}]*)?\}/g, (m, loop, n) => { if (!loop) { checkName(n, src, where); } return m; });
}
function checkCond(s, src, where) {
  String(s).replace(/'[^']*'|"[^"]*"/g, '').split(/&&|\|\|/).forEach(part => {
    part.replace(/!?\s*([A-Za-z_][\w.]*)/g, (m, n) => { if (!/^(null|true|false)$/i.test(n) && !/^\d/.test(n)) { checkName(n, src, where); } return m; });
  });
}
const COND_KEYS = ['when', 'filter'];
function walk(node, src, where) {
  if (typeof node === 'string') {
    if (/^@\w+$/.test(node)) { if (!(node.slice(1) in defs)) { warn.push(where + ': ' + node + ' no está en defs'); } return; }
    checkTpl(node, src, where); return;
  }
  if (Array.isArray(node)) { node.forEach((x, i) => walk(x, src, where + '[' + i + ']')); return; }
  if (!node || typeof node !== 'object') { return; }
  if (node.source) {
    src = String(node.source).toUpperCase();
    if (!data[src]) { warn.push(where + ': source ' + src + ' no existe en datos.json'); }
  }
  Object.keys(node).forEach(k => {
    const v = node[k], w = where + '.' + k;
    if (COND_KEYS.indexOf(k) >= 0 && typeof v === 'string') { checkCond(v, (node.type || k === 'filter') ? src : src, w); }
    else if (['col', 'breakBy', 'category', 'field', 'by'].indexOf(k) >= 0 && typeof v === 'string') { checkName(v, src, w); }
    else if (k === 'totals' || k === 'breakTotals') { (Array.isArray(v) ? v : []).forEach(t => checkName(typeof t === 'string' ? t : t.col, src, w)); }
    else if (k === 'optionsFrom' && typeof v === 'string') { checkName(v.indexOf('.') > 0 ? v : v + '.X', null, w); }
    else if (k === 'map' || k === 'values' || k === 'theme' || k === 'defs' || k === 'source' || k === 'type') { /* no son plantillas */ }
    else { walk(v, src, w); }
  });
}
walk(layout.sections || [], null, 'sections');
['title', 'fileName', 'footer', 'watermark', 'xlsx'].forEach(k => layout[k] && walk(layout[k], 'DOCS', k));
if (layout.batch) { walk(layout.batch, null, 'batch'); }
Object.keys(defs).forEach(k => walk(defs[k], null, 'defs.' + k));
const ids = new Set(); (function ids_(n) { if (Array.isArray(n)) { n.forEach(ids_); } else if (n && typeof n === 'object') { if (n.id) { ids.add(n.id); } Object.values(n).forEach(ids_); } })(layout.sections);
((layout.xlsx && layout.xlsx.sheets) || []).forEach((s, i) => (s.sections || []).forEach(x => {
  if (typeof x === 'string' && !ids.has(x)) { warn.push('xlsx.sheets[' + i + ']: no hay sección con id "' + x + '"'); }
}));
const usa = re => re.test(JSON.stringify(layout));
if (!CANVAS && (usa(/"grafico"/) || (layout.watermark && formats.indexOf('docx') >= 0))) {
  warn.push('Sin el paquete "canvas" no se pueden probar gráficos ni la marca de agua de Word (cd test && npm i canvas)');
}
const unique = [...new Set(warn)];
unique.forEach(w => console.log('AVISO ', w));

/* ---------- generación ---------- */
const OUT = path.join(dir, 'out');
fs.mkdirSync(OUT, { recursive: true });
(async () => {
  let fail = 0;
  for (const format of formats) {
    try {
      const r = await window.novaReport.build({ layout: JSON.parse(JSON.stringify(layout)), format, output, params, zipType: 'nodebuffer' }, data);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      const name = format + '__' + r.name;
      fs.writeFileSync(path.join(OUT, name), buf);
      console.log('OK    ' + path.join('out', name) + '  (' + buf.length + ' bytes, ' + r.count + ' doc.)');
    } catch (e) { fail++; console.log('FALLÓ ' + format + ': ' + (e && e.message || e)); }
  }
  console.log(unique.length + ' aviso(s), ' + fail + ' error(es)');
  process.exit(fail ? 1 : 0);
})();
