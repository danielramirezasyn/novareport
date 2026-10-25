/* Ejecuta los ejemplos de /examples en Node con datos EMP/DEPT de prueba y deja los archivos en test/out */
global.window = global;
global.document = { getElementById() { return null; }, addEventListener() {} };
window.jspdf = require('jspdf'); require('jspdf-autotable');
window.ExcelJS = require('exceljs'); window.JSZip = require('jszip'); window.docx = require('docx');
window.PizZip = require('pizzip'); window.docxtemplater = require('docxtemplater');
window.qrcode = require('qrcode-generator');
/* Chart.js se publica como UMD dentro de un paquete "type": "module": se evalúa como script */
{ const m = { exports: {} }; new Function('module', 'exports', require('fs').readFileSync(require.resolve('chart.js').replace(/[^\\/]+$/, '') + 'chart.umd.js', 'utf8'))(m, m.exports); window.Chart = m.exports; }
/* Gráficos y marca de agua en Word dibujan en un <canvas>: en Node se usa el paquete "canvas" (opcional) */
let CANVAS = false;
try { const { createCanvas } = require('canvas'); document.createElement = t => t === 'canvas' ? createCanvas(1, 1) : null; CANVAS = true; }
catch (e) { console.warn('Paquete "canvas" no disponible: se omiten los ejemplos con gráficos.'); }
const fs = require('fs'), path = require('path');
const EX = path.join(__dirname, '..', 'examples'), OUT = path.join(__dirname, 'out');
const logo = fs.readFileSync(path.join(EX, '03-constancia-posicion-fija', 'logo.png'));
/* #APP_FILES# se resuelve a un data URL para no depender de APEX */
window.apex = { item: () => ({ getValue: () => '' }), env: { APP_FILES: 'data:image/png;base64,' } };
/* Regresión: ninguna tabla PDF puede quedar con alto 0 */
const _at = window.jspdf.jsPDF.API.autoTable;
window.jspdf.jsPDF.API.autoTable = function (o) {
  const r = _at.call(this, o);
  if (o.body && o.body.length && !(this.lastAutoTable.finalY > o.startY)) { throw new Error('Tabla con alto 0 (startY ' + o.startY + ')'); }
  return r;
};
/* Plantillas Word: fetch() lee archivos locales de examples/ */
const nativeFetch = global.fetch;
global.fetch = async (u, o) => {
  if (/^data:/.test(String(u))) { return nativeFetch(u, o); }
  const f = path.join(EX, String(u));
  if (!fs.existsSync(f)) { return { ok: false, status: 404 }; }
  const b = fs.readFileSync(f);
  return { ok: true, status: 200, arrayBuffer: async () => b.buffer.slice(b.byteOffset, b.byteOffset + b.length) };
};
/* --min (o NOVAREPORT_MIN=1) prueba el archivo minificado, el que se publica en el plugin */
require(path.join(__dirname, '..', 'src', (process.env.NOVAREPORT_MIN || process.argv.includes('--min')) ? 'novareport.min.js' : 'novareport.js'));

const N = n => ({ name: n, type: 'VARCHAR2' }), U = n => ({ name: n, type: 'NUMBER' });
const DEPT = { 10: ['ACCOUNTING', 'NEW YORK'], 20: ['RESEARCH', 'DALLAS'], 30: ['SALES', 'CHICAGO'], 40: ['OPERATIONS', 'BOSTON'] };
const EMP = [[7839, 'KING', 'PRESIDENT', '17/11/1981', 5000, null, 10], [7698, 'BLAKE', 'MANAGER', '01/05/1981', 2850, null, 30],
  [7782, 'CLARK', 'MANAGER', '09/06/1981', 2450, null, 10], [7566, 'JONES', 'MANAGER', '02/04/1981', 2975, null, 20],
  [7788, 'SCOTT', 'ANALYST', '09/12/1982', 3000, null, 20], [7902, 'FORD', 'ANALYST', '03/12/1981', 3000, null, 20],
  [7369, 'SMITH', 'CLERK', '17/12/1980', 800, null, 20], [7499, 'ALLEN', 'SALESMAN', '20/02/1981', 1600, 300, 30],
  [7521, 'WARD', 'SALESMAN', '22/02/1981', 1250, 500, 30], [7654, 'MARTIN', 'SALESMAN', '28/09/1981', 1250, 1400, 30],
  [7844, 'TURNER', 'SALESMAN', '08/09/1981', 1500, 0, 30], [7876, 'ADAMS', 'CLERK', '12/01/1983', 1100, null, 20],
  [7900, 'JAMES', 'CLERK', '03/12/1981', 950, null, 30], [7934, 'MILLER', 'CLERK', '23/01/1982', 1300, null, 10]];
const byName = EMP.slice().sort((a, b) => a[1] < b[1] ? -1 : 1);

const data = {
  '01-listado-empleados': {
    DEPTOS: { cols: [N('DNAME'), N('LOC'), U('EMPLEADOS'), U('SALARIOS')],
      rows: Object.keys(DEPT).map(k => { const e = EMP.filter(x => x[6] == k); return [DEPT[k][0], DEPT[k][1], e.length, e.reduce((s, x) => s + x[4], 0)]; }) },
    EMP: { cols: [U('EMPNO'), N('ENAME'), N('JOB'), N('DNAME'), { name: 'HIREDATE', type: 'DATE' }, U('SAL'), U('COMM')],
      rows: EMP.map(e => [e[0], e[1], e[2], DEPT[e[6]][0], e[3], e[4], e[5]]) } },
  '02-cartas-zip': {
    DOCS: { cols: [U('DOC_KEY'), N('ENAME'), N('JOB'), N('DNAME'), U('SAL'), { name: 'HIREDATE', type: 'DATE' }, U('SAL_NUEVO')],
      rows: byName.map(e => [e[0], e[1], e[2], DEPT[e[6]][0], e[4], e[3], Math.round(e[4] * 105) / 100]) },
    LISTA: { cols: [N('ENAME'), N('JOB'), U('SAL'), U('SAL_NUEVO')], rows: byName.map(e => [e[1], e[2], e[4], Math.round(e[4] * 105) / 100]) } },
  '03-constancia-posicion-fija': {
    DOCS: { cols: [U('DOC_KEY'), N('NRO_DOC'), N('FECHA_TXT'), N('ENAME'), N('JOB'), N('DNAME'), { name: 'HIREDATE', type: 'DATE' }, U('SAL')],
      rows: [[7788, 'RH-007788-2026', '17 de Octubre del 2026', 'SCOTT', 'ANALYST', 'RESEARCH', '09/12/1982', 3000]] } },
  '04-imagen-blob': {
    DOCS: { cols: [U('DOC_KEY'), N('ENAME'), N('JOB'), { name: 'FOTO', type: 'BLOB' }],
      rows: byName.slice(0, 3).map(e => [e[0], e[1], e[2], logo.toString('base64')]) } },
  '05-excel-multihoja': {
    DEPTOS: { cols: [U('DEPTNO'), N('DNAME'), N('LOC'), U('EMPLEADOS'), U('SALARIOS'), U('COMISIONES')],
      rows: Object.keys(DEPT).sort((a, b) => DEPT[a][0] < DEPT[b][0] ? -1 : 1).map(k => {
        const e = EMP.filter(x => x[6] == k);
        return [+k, DEPT[k][0], DEPT[k][1], e.length, e.reduce((s, x) => s + x[4], 0), e.reduce((s, x) => s + (x[5] || 0), 0)]; }) },
    EMP: { cols: [U('EMPNO'), N('ENAME'), N('JOB'), N('DNAME'), { name: 'HIREDATE', type: 'DATE' }, U('SAL'), U('COMM'), U('TOTAL')],
      rows: EMP.map(e => [e[0], e[1], e[2], DEPT[e[6]][0], e[3], e[4], e[5], e[4] + (e[5] || 0)]) } },
  '06-plantilla-word': {
    DOCS: { cols: [U('DOC_KEY'), N('DNAME'), N('LOC'), U('EMPLEADOS'), U('SALARIOS')],
      rows: [10, 20, 30].map(k => { const e = EMP.filter(x => x[6] == k); return [k, DEPT[k][0], DEPT[k][1], e.length, e.reduce((s, x) => s + x[4], 0)]; }) },
    EQUIPO: { cols: [U('DOC_KEY'), N('ENAME'), N('JOB'), { name: 'HIREDATE', type: 'DATE' }, U('SAL')],
      rows: EMP.slice().sort((a, b) => a[6] - b[6] || b[4] - a[4]).map(e => [e[6], e[1], e[2], e[3], e[4]]) } },
  '07-graficos-codigos': {
    DEPTOS: { cols: [N('DNAME'), U('EMPLEADOS'), U('SALARIOS'), U('COMISIONES')],
      rows: [10, 20, 30].sort((a, b) => DEPT[a][0] < DEPT[b][0] ? -1 : 1).map(k => {
        const e = EMP.filter(x => x[6] == k);
        return [DEPT[k][0], e.length, e.reduce((s, x) => s + x[4], 0), e.reduce((s, x) => s + (x[5] || 0), 0)]; }) },
    EMP: { cols: [N('DNAME'), U('EMPNO'), N('ENAME'), N('JOB'), U('SAL'), U('COMM')],
      rows: EMP.slice().sort((a, b) => (DEPT[a[6]][0] < DEPT[b[6]][0] ? -1 : DEPT[a[6]][0] > DEPT[b[6]][0] ? 1 : b[4] - a[4]))
        .map(e => [DEPT[e[6]][0], e[0], e[1], e[2], e[4], e[5]]) } }
};
/* 08: los mismos datos que fuentes.sql (solo DUAL) */
data['08-factura-columnas'] = {
  DOCS: { cols: [U('DOC_KEY'), N('NUMERO'), { name: 'FECHA', type: 'DATE' }, N('CLIENTE'), N('CEDULA'), N('DIRECCION'), U('SUBTOTAL'), U('ITBMS'), U('TOTAL')],
    rows: [[1, 'FAC-000123', '24/10/2026', 'Ana Pérez', '8-765-4321', 'Calle 50, Panamá', 1284, 89.88, 1373.88]] },
  ITEMS: { cols: [U('DOC_KEY'), N('DESCRIPCION'), U('CANTIDAD'), U('PRECIO'), U('IMPORTE')],
    rows: [[1, 'Consultoría Oracle APEX', 8, 120, 960], [1, 'Licencia novaReport (soporte anual)', 1, 324, 324]] },
  EMPRESA: { cols: [N('NOMBRE'), N('RUC'), N('DIRECCION')], rows: [['NovaCode, S.A.', '155771259-2-2025', 'Panamá Oeste, Arraiján']] } };
const runs = [['01-listado-empleados', 'pdf', 'file'], ['01-listado-empleados', 'xlsx', 'file'], ['01-listado-empleados', 'docx', 'file'],
  ['02-cartas-zip', 'pdf', 'zip'], ['02-cartas-zip', 'pdf', 'merge'], ['03-constancia-posicion-fija', 'pdf', 'file'],
  ['04-imagen-blob', 'pdf', 'zip'], ['04-imagen-blob', 'docx', 'zip'],
  ['05-excel-multihoja', 'xlsx', 'file'], ['05-excel-multihoja', 'pdf', 'file'], ['05-excel-multihoja', 'docx', 'file'],
  ['05-excel-multihoja', 'all', 'zip'],
  ['06-plantilla-word', 'docx-template', 'zip', '06-plantilla-word/plantilla.docx'],
  ['07-graficos-codigos', 'pdf', 'file'], ['07-graficos-codigos', 'xlsx', 'file'], ['07-graficos-codigos', 'docx', 'file'],
  ['08-factura-columnas', 'pdf', 'file'], ['08-factura-columnas', 'xlsx', 'file'], ['08-factura-columnas', 'docx', 'file']];

fs.mkdirSync(OUT, { recursive: true });
(async () => {
  for (const [ex, format, output, templateUrl] of runs) {
    if (ex === '07-graficos-codigos' && !CANVAS) { console.log('OMITIDO', ex, format); continue; }
    const layout = JSON.parse(fs.readFileSync(path.join(EX, ex, 'diseno.json'), 'utf8'));
    (layout.sections || []).forEach(s => { if (s.type === 'imagen' && s.url) { s.url = '#APP_FILES#' + logo.toString('base64'); } });
    const t = Date.now();
    const r = await window.novaReport.build({ layout, format, output, templateUrl, zipType: 'nodebuffer' }, data[ex]);
    const name = ex + '__' + format + '_' + output + '__' + r.name;
    fs.writeFileSync(path.join(OUT, name), Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data));
    console.log('OK  ', name.padEnd(70), (Date.now() - t) + ' ms');
  }
  /* Agregados en la primera columna: el texto de totales va en su propia fila */
  {
    const layout = JSON.parse(fs.readFileSync(path.join(EX, '01-listado-empleados', 'diseno.json'), 'utf8'));
    const t = layout.sections.filter(s => s.type === 'tabla' && s.source === 'EMP')[0];
    t.totals = [{ col: 'EMPNO', fn: 'count' }, { col: 'HIREDATE', fn: 'min' }, { col: 'SAL', fn: 'avg' }, 'COMM'];
    t.breakBy = 'DNAME';
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, data['01-listado-empleados']);
      const name = 'agregados-primera-col__' + format + '__' + r.name;
      fs.writeFileSync(path.join(OUT, name), Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data));
      console.log('OK  ', name);
    }
  }
  /* when en secciones y columnas + monto en letras */
  {
    const layout = { fileName: 'when-letras', sections: [
      { type: 'header', title: 'Prueba when / letras' },
      { type: 'tabla', source: 'EMP', columns: ['ENAME', { col: 'SAL', label: 'En letras', fmt: 'letras:BALBOA/BALBOAS' },
        { col: 'COMM', when: "PARAM.COMISION == 'S'" }] },
      { type: 'tabla', source: 'DEPTOS', when: "PARAM.DEPTOS == 'S'" },
      { type: 'ficha', fields: [{ label: 'Total', value: '{DEPTOS.SALARIOS}', fmt: 'letras:BALBOAS' }] }] };
    const ExcelJS = window.ExcelJS, texts = async buf => {
      const wb = new ExcelJS.Workbook(); await wb.xlsx.load(buf); const out = [];
      wb.eachSheet(ws => ws.eachRow(r => r.eachCell(c => out.push(String(c.value)))));
      return out;
    };
    for (const [prm, ver] of [[{ COMISION: 'N', DEPTOS: 'N' }, false], [{ COMISION: 'S', DEPTOS: 'S' }, true]]) {
      for (const format of ['pdf', 'xlsx', 'docx']) {
        const r = await window.novaReport.build({ layout, format, output: 'file', params: prm, zipType: 'nodebuffer' }, data['01-listado-empleados']);
        const name = 'when-letras__' + (ver ? 'si' : 'no') + '__' + format + '__' + r.name;
        const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
        fs.writeFileSync(path.join(OUT, name), buf);
        if (format === 'xlsx') {
          const t = await texts(buf), has = s => t.indexOf(s) >= 0;
          if (!has('CINCO MIL BALBOAS CON 00/100')) { throw new Error('letras: falta CINCO MIL BALBOAS'); }
          if (!has('OCHOCIENTOS BALBOAS CON 00/100')) { throw new Error('letras: falta OCHOCIENTOS BALBOAS'); }
          if (has('Comm') !== ver) { throw new Error('when columna: Comm ' + (ver ? 'no aparece' : 'aparece')); }
          if (has('NEW YORK') !== ver) { throw new Error('when sección: DEPTOS ' + (ver ? 'no aparece' : 'aparece')); }
        }
        console.log('OK  ', name);
      }
    }
  }
  /* Columnas: casillas lado a lado (factura) + fila que no cabe y pasa a la página siguiente */
  {
    const lay = (rel) => ({ fileName: 'columnas-' + rel, sections: [
      { type: 'header', title: 'Factura de prueba', right: 'N.º 000123' },
      { type: 'columnas', widths: [60, 40], cols: [
        [ { type: 'texto', text: '**Emisor**\nNovaCode, S.A.\nRUC 155771259-2-2025' },
          { type: 'ficha', source: 'DEPTOS', columns: 1, fields: [{ label: 'Depto', value: '{DNAME}' }, { label: 'Sede', value: '{LOC}' }] } ],
        [ { type: 'codigo', kind: 'code128', value: 'FAC-000123', height: 10, align: 'right' },
          { type: 'alerta', source: 'DEPTOS', text: 'Total: {SALARIOS|letras:BALBOAS}', color: '#FFF4CE' } ] ] },
      { type: 'tabla', source: 'EMP', columns: ['ENAME', 'JOB', 'SAL'], totals: ['SAL'] },
      { type: 'columnas', widths: [50, 50], when: "PARAM.FIRMAS == 'S'", cols: [
        [ { type: 'espacio', height: 12 }, { type: 'linea', width: 60, align: 'center' }, { type: 'texto', text: 'Entregado por', align: 'center' } ],
        [ { type: 'espacio', height: 12 }, { type: 'linea', width: 60, align: 'center' }, { type: 'texto', text: 'Recibido por', align: 'center' },
          { type: 'header', title: 'NO DEBE SALIR' } ] ] }] });
    const ExcelJS = window.ExcelJS;
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout: lay(format), format, output: 'file', params: { FIRMAS: 'S' }, zipType: 'nodebuffer' }, data['01-listado-empleados']);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'columnas__' + format + '__' + r.name), buf);
      if (format === 'xlsx') {
        const wb = new ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0];
        let emisor = null, total = null, recibido = null, entregado = null, nodebe = false;
        ws.eachRow(row => row.eachCell(c => {
          const v = String(c.value && c.value.richText ? c.value.richText.map(x => x.text).join('') : c.value);
          if (/Emisor/.test(v)) { emisor = [c.row, c.col]; }
          if (/^Total: /.test(v)) { total = [c.row, c.col]; }
          if (v === 'Entregado por') { entregado = [c.row, c.col]; }
          if (v === 'Recibido por') { recibido = [c.row, c.col]; }
          if (/NO DEBE SALIR/.test(v)) { nodebe = true; }
        }));
        if (!emisor || !total || total[1] <= emisor[1]) { throw new Error('xlsx columnas: casilla derecha no está a la derecha ' + JSON.stringify([emisor, total])); }
        if (!entregado || !recibido || entregado[0] !== recibido[0] || recibido[1] <= entregado[1]) { throw new Error('xlsx firmas no quedaron en la misma fila ' + JSON.stringify([entregado, recibido])); }
        if (nodebe) { throw new Error('header dentro de una casilla no debe dibujarse'); }
      }
      if (format === 'docx') {
        const x = (await window.JSZip.loadAsync(buf)).file('word/document.xml');
        const xml = await x.async('string');
        if (/NO DEBE SALIR/.test(xml)) { throw new Error('docx: header dentro de casilla'); }
        if (!/Entregado por[\s\S]*<\/w:tc>[\s\S]*Recibido por/.test(xml)) { throw new Error('docx: firmas no están en celdas distintas'); }
      }
      console.log('OK  ', 'columnas__' + format + '__' + r.name);
    }
  }
})().catch(e => { console.error('FALLÓ', e); process.exit(1); });
