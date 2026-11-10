/* Ejecuta los ejemplos de /examples en Node con datos EMP/DEPT de prueba y deja los archivos en test/out */
global.window = global;
global.document = { getElementById() { return null; }, addEventListener() {} };
window.jspdf = require('jspdf'); require('jspdf-autotable');
window.ExcelJS = require('exceljs'); window.JSZip = require('jszip'); window.docx = require('docx');
window.PizZip = require('pizzip'); window.docxtemplater = require('docxtemplater');
window.qrcode = require('qrcode-generator');
/* pdf-lib: anexar PDFs (1.23). Si no está instalado se omite esa prueba */
try { window.PDFLib = require('pdf-lib'); } catch (e) { console.warn('Paquete "pdf-lib" no disponible: se omite la prueba de anexos.'); }
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
/* 09: Cover Sheet (tarjetas, ficha en cuadrícula, tabla con headAlign/grid) */
{ const T = o => ({ cols: Object.keys(o).map(k => typeof o[k] === 'number' ? U(k) : N(k)), rows: [Object.values(o)] });
  data['09-cover-sheet'] = {
    DOCS: T({ DOC_KEY: 1, COVER_NO: '16-26', FECHA: '15-Oct-26', PRESENTACION: 'Disminución de', CIF: 'CL-000003', STATUS: 'Approved',
      DEUDOR: 'Ana Lucía Castillo Herrera', IDENTIFICACION: 'Cédula 4-721-889', DIRECCION: 'Urbanización Vista Alegre, calle 3, casa 45, Arraiján',
      PAIS: 'Panamá', OFICINA: '1001 - Casa Matriz Panamá', CATEGORIA: 'Banca Personal', PARTE_RELACIONADA: 'N', OFICIAL: 'Héctor Iván Delgado',
      TIPO_PRESTAMO: 'Comercial', ENVIADO_POR: 'ADMIN', RESUELTO_POR: 'CHECKER', COMENTARIO: 'Aprobada', IMPRESO: '28-Oct-26 20:56' }),
    FACILIDAD: T({ MONEDA: 'NIO', MONTO: 5656656565, FORMA_PAGO: 'Capital e intereses al vencimiento' }),
    GARANTIA: T({ TIPO: 'Fianza corporativa', DESCRIPCION: 'YYYYYY', MONEDA: 'USD', VALOR: 343444, COBERTURA: 50, AVALUO: '21-Oct-26' }),
    FIRMAS: T({ F1_NOMBRE: 'Mónica Vega', F1_CARGO: 'Analista de Riesgo' }) }; }
/* 13: estado de cuenta (1.23) con los mismos datos que fuentes.sql */
{ const L = []; for (let n = 1; n <= 60; n++) { L.push(n); }
  const f2 = d => String(d.getUTCDate()).padStart(2, '0') + '/' + String(d.getUTCMonth() + 1).padStart(2, '0') + '/' + d.getUTCFullYear();
  const rows = [];
  for (const [suc, so] of [['Casa Matriz', 1], ['Sucursal Arraiján', 2]]) {
    for (const [tipo, to] of [['Crédito', 1], ['Débito', 2]]) {
      const m = L.map(n => { const d = new Date(Date.UTC(2026, 7 + n % 3, 1 + (n * 7) % 27));
        return { n, d, monto: tipo === 'Débito' ? -Math.round((20 + (n * 53) % 400 + (n % 5) / 10) * 100) / 100 : Math.round((50 + (n * 37) % 950 + (n % 7) / 10) * 100) / 100 }; });
      m.sort((a, b) => a.d - b.d || a.n - b.n).forEach(x => rows.push([1, suc, tipo, f2(x.d), x.d.toISOString().substr(0, 7), 'Operación ' + String(x.n).padStart(4, '0'), x.monto]));
    }
  }
  data['13-estado-cuenta'] = {
    DOCS: { cols: [U('DOC_KEY'), N('CLIENTE'), N('RUC'), N('CUENTA')], rows: [[1, 'NOVACODE, S.A.', '155771259-2-2025', 'CTA-000123']] },
    MOVS: { cols: [U('DOC_KEY'), N('SUCURSAL'), N('TIPO'), { name: 'FECHA', type: 'DATE' }, N('PERIODO'), N('CONCEPTO'), U('MONTO')], rows } }; }
const runs = [['01-listado-empleados', 'pdf', 'file'], ['01-listado-empleados', 'xlsx', 'file'], ['01-listado-empleados', 'docx', 'file'],
  ['02-cartas-zip', 'pdf', 'zip'], ['02-cartas-zip', 'pdf', 'merge'], ['03-constancia-posicion-fija', 'pdf', 'file'],
  ['04-imagen-blob', 'pdf', 'zip'], ['04-imagen-blob', 'docx', 'zip'],
  ['05-excel-multihoja', 'xlsx', 'file'], ['05-excel-multihoja', 'pdf', 'file'], ['05-excel-multihoja', 'docx', 'file'],
  ['05-excel-multihoja', 'all', 'zip'],
  ['06-plantilla-word', 'docx-template', 'zip', '06-plantilla-word/plantilla.docx'],
  ['07-graficos-codigos', 'pdf', 'file'], ['07-graficos-codigos', 'xlsx', 'file'], ['07-graficos-codigos', 'docx', 'file'],
  ['08-factura-columnas', 'pdf', 'file'], ['08-factura-columnas', 'xlsx', 'file'], ['08-factura-columnas', 'docx', 'file'],
  ['09-cover-sheet', 'pdf', 'file'], ['09-cover-sheet', 'xlsx', 'file'], ['09-cover-sheet', 'docx', 'file'],
  ['13-estado-cuenta', 'pdf', 'file'], ['13-estado-cuenta', 'xlsx', 'file'], ['13-estado-cuenta', 'docx', 'file']];

fs.mkdirSync(OUT, { recursive: true });
(async () => {
  for (const [ex, format, output, templateUrl] of runs) {
    if (ex === '07-graficos-codigos' && !CANVAS) { console.log('OMITIDO', ex, format); continue; }
    const layout = JSON.parse(fs.readFileSync(path.join(EX, ex, 'diseno.json'), 'utf8'));
    (layout.sections || []).forEach(s => { if (s.type === 'imagen' && s.url) { s.url = '#APP_FILES#' + logo.toString('base64'); } });
    if (layout.pageHeader && layout.pageHeader.image && layout.pageHeader.image.url) { layout.pageHeader.image.url = '#APP_FILES#' + logo.toString('base64'); }
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
  /* 1.14: encabezado con tamaños, letra y colores propios + estilo por campo de ficha */
  {
    const layout = { fileName: 'estilos-114', sections: [
      { type: 'header', title: 'Estado de cuenta', subtitle: 'Sub {DEPTOS.DNAME}', right: 'Derecha', size: 24, subtitleSize: 12, rightSize: 11,
        font: 'times', fill: '#14403F', color: '#F5F0E1' },
      { type: 'ficha', source: 'DEPTOS', columns: 2, fields: [
        { label: 'Depto', value: '{DNAME}', bold: true },
        { label: 'Salarios', value: '{SALARIOS}', fmt: 'money', align: 'right', color: '#1B7A3D' },
        { label: 'Sede', value: '{LOC}', align: 'center', fill: '#FDECEC', color: { by: 'LOC', values: { 'NEW YORK': '#A61B1B' } } } ] }] };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, data['01-listado-empleados']);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'estilos-114__' + format + '__' + r.name), buf);
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0]; const cs = {};
        ws.eachRow(row => row.eachCell(c => { cs[String(c.value)] = c; }));
        const h = cs['Estado de cuenta'], d = cs.ACCOUNTING, sal = ws.getRow(d.row).getCell(d.col + 2), sede = ws.getRow(d.row + 1).getCell(d.col);
        if (!h || h.font.size !== 24 || h.font.name !== 'Times New Roman' || h.fill.fgColor.argb !== 'FF14403F') { throw new Error('xlsx header 1.14'); }
        if (!d.font.bold) { throw new Error('xlsx ficha bold'); }
        if (sal.alignment.horizontal !== 'right' || sal.font.color.argb !== 'FF1B7A3D') { throw new Error('xlsx ficha align/color'); }
        if (sede.alignment.horizontal !== 'center' || sede.fill.fgColor.argb !== 'FFFDECEC' || sede.font.color.argb !== 'FFA61B1B') { throw new Error('xlsx ficha center/fill/colorBy'); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        if (!/Times New Roman/.test(xml) || !/w:sz w:val="48"/.test(xml) || !/14403F/.test(xml)) { throw new Error('docx header 1.14'); }
        if (!/FDECEC/.test(xml) || !/A61B1B/.test(xml) || !/1B7A3D/.test(xml) || !/w:jc w:val="center"/.test(xml)) { throw new Error('docx ficha 1.14'); }
      }
      console.log('OK  ', 'estilos-114__' + format + '__' + r.name);
    }
  }
  /* 1.15: huecos (empty) y span en ficha y formulario */
  {
    const layout = { fileName: 'casillas-115', sections: [
      { type: 'ficha', source: 'DEPTOS', columns: 3, grid: true, fields: [
        { label: 'Depto', value: '{DNAME}' }, { empty: true }, { label: 'Sede', value: '{LOC}' },
        { label: 'Salarios', value: '{SALARIOS}', fmt: 'money', span: 2 }, { label: 'Emp.', value: '{EMPLEADOS}' },
        { empty: true }, { label: 'Resto', value: 'fila', span: 'row' }] },
      { type: 'formulario', columns: 3, fields: [
        { label: 'Nombre', name: 'NOMBRE', span: 2 }, { label: 'Cód', name: 'COD' },
        { empty: true, span: 2 }, { label: 'Activo', name: 'ACT', input: 'checkbox' },
        { label: 'Notas', name: 'NOTAS', input: 'multiline', span: 'row' }] }] };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, data['01-listado-empleados']);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'casillas-115__' + format + '__' + r.name), buf);
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0], m = ws.model.merges.slice().sort().join(' ');
        const top = ws.getCell('A1').value === 'Depto' ? 0 : -1;
        if (top < 0 || ws.getCell('E1').value !== 'Sede' || ws.getCell('C1').value) { throw new Error('xlsx ficha empty: ' + [ws.getCell('A1').value, ws.getCell('C1').value, ws.getCell('E1').value]); }
        if (m !== 'B2:D2 B5:D5 B7:F7 D3:F3') { throw new Error('xlsx merges: ' + m); }
        const dn = wb.definedNames.model.map(d => d.name + ':' + d.ranges[0]).sort().join(' ');
        if (dn !== 'ACT:Reporte!$F$6 COD:Reporte!$F$5 NOMBRE:Reporte!$B$5 NOTAS:Reporte!$B$7') { throw new Error('xlsx nombres: ' + dn); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        const rows = xml.split('<w:tr>').slice(1).map(t => (t.match(/<w:tc>/g) || []).length + '/' + (t.match(/w:gridSpan w:val="(\d+)"/g) || []).map(g => g.match(/\d+/)[0]).join(','));
        if (rows.join(' ') !== '5/2 4/3 3/2,3 4/3 3/4 2/5') { throw new Error('docx spans: ' + rows.join(' ')); }
      }
      console.log('OK  ', 'casillas-115__' + format + '__' + r.name);
    }
  }
  /* 1.16: posición de la etiqueta (left, top, none) y estilo de etiqueta por sección y por campo */
  {
    const layout = { fileName: 'etiquetas-116', sections: [
      { type: 'ficha', source: 'DEPTOS', columns: 3, grid: true, labelPosition: 'top', labelCase: 'upper', labelColor: '#5A6B7B', fields: [
        { label: 'Depto', value: '{DNAME}', span: 2 }, { label: 'Salarios', value: '{SALARIOS}', fmt: 'money', align: 'right' },
        { label: 'Sede', value: '{LOC}', labelPosition: 'left', labelCase: 'none' }, { label: 'Oculta', value: '{LOC}', labelPosition: 'none' },
        { label: 'Emp.', value: '{EMPLEADOS}', labelSize: 6, labelColor: '#A61B1B', labelAlign: 'center' }] },
      { type: 'formulario', columns: 2, labelPosition: 'top', fields: [
        { label: 'Nombre', name: 'NOMBRE' }, { label: 'Tipo', name: 'TIPO', input: 'list', options: ['A', 'B'], labelPosition: 'left' },
        { label: 'Notas', name: 'NOTAS', input: 'multiline', lines: 3, span: 'row' },
        { label: 'Acepta', name: 'ACEPTA', input: 'checkbox', labelPosition: 'none' }, { label: 'Correo', name: 'CORREO', labelBold: false }] }] };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, data['01-listado-empleados']);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'etiquetas-116__' + format + '__' + r.name), buf);
      if (format === 'pdf') {
        const t = buf.toString('latin1');
        for (const n of ['NOMBRE', 'TIPO', 'NOTAS', 'ACEPTA', 'CORREO']) { if (!new RegExp('/T \\(' + n + '\\)').test(t)) { throw new Error('pdf campo ' + n); } }
      }
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0]; const cs = {};
        ws.eachRow(row => row.eachCell(c => { if (c.value !== null && c.value !== '') { cs[String(c.value)] = c; } }));
        const dep = cs.DEPTO, acc = cs.ACCOUNTING, sal = cs.SALARIOS;
        if (!dep || !acc || acc.row !== dep.row + 1 || acc.col !== dep.col) { throw new Error('xlsx etiqueta arriba'); }
        if (!sal || sal.alignment.horizontal !== 'right') { throw new Error('xlsx etiqueta arriba alineada con el valor'); }
        if (!cs.Sede || cs.Oculta || cs.OCULTA) { throw new Error('xlsx left/none'); }
        if (!cs['EMP.'] || cs['EMP.'].font.size !== 6 || cs['EMP.'].font.color.argb !== 'FFA61B1B') { throw new Error('xlsx estilo por campo'); }
        const names = wb.definedNames.model.map(d => d.name);
        for (const n of ['NOMBRE', 'TIPO', 'NOTAS', 'ACEPTA', 'CORREO']) { if (names.indexOf(n) < 0) { throw new Error('xlsx nombre ' + n); } }
        if (!cs.Correo || cs.Correo.font.bold) { throw new Error('xlsx labelBold'); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        if (!/>DEPTO</.test(xml) || /Oculta|OCULTA/.test(xml) || !/>Sede</.test(xml) || !/A61B1B/.test(xml)) { throw new Error('docx etiquetas'); }
        if ((xml.match(/<w:sdt>/g) || []).length !== 5) { throw new Error('docx controles de contenido'); }
      }
      console.log('OK  ', 'etiquetas-116__' + format + '__' + r.name);
    }
  }
  /* 1.18: bloques dentro de celdas de tabla (codigo, imagen, texto, grafico) y tabla dentro de formulario */
  {
    const d118 = { EMP: { cols: [U('EMPNO'), N('ENAME'), N('JOB'), { name: 'FOTO', type: 'BLOB' }],
                          rows: byName.slice(0, 3).map(e => [e[0], e[1], e[2], logo.toString('base64')]) },
                   VENTAS: { cols: [U('EMPNO'), N('MES'), U('MONTO')],
                             rows: [].concat(...byName.slice(0, 3).map(e => ['ENE', 'FEB', 'MAR'].map((m, i) => [e[0], m, e[4] * (i + 1)]))) } };
    const layout = { fileName: 'celdas-118', sections: [
      { type: 'tabla', source: 'EMP', grid: true, columns: [
        { col: 'EMPNO', label: 'QR', cell: { type: 'codigo', kind: 'qr', value: 'EMP-{EMPNO}', size: 12 } },
        { label: 'Empleado', cell: { type: 'texto', text: '{ENAME} ({JOB})' } },
        { label: 'Foto', cell: { type: 'imagen', field: 'FOTO', height: 10 } },
        { label: 'Barras', cell: { type: 'codigo', kind: 'code128', value: '{EMPNO}', width: 25, height: 6 } },
        { label: 'Ventas', when: CANVAS ? '' : 'X == 1', cell: { type: 'grafico', chart: 'line', source: 'VENTAS', link: { EMPNO: 'EMPNO' }, category: 'MES', series: ['MONTO'] } }] },
      { type: 'formulario', title: 'Solicitud', columns: 2, fields: [
        { label: 'Nombre', name: 'NOMBRE' }, { label: 'Código', name: 'CODIGO' },
        { span: 'row', block: { type: 'tabla', source: 'EMP', columns: ['EMPNO', 'ENAME'] } },
        { label: 'Notas', name: 'NOTAS', input: 'multiline', span: 'row' }] },
      { type: 'ficha', source: 'EMP', columns: 2, fields: [
        { label: 'Nombre', value: '{ENAME}' }, { label: 'Puesto', value: '{JOB}' },
        { span: 'row', block: { type: 'codigo', kind: 'qr', value: 'FICHA-{EMPNO}', size: 15 } },
        { label: 'Código', value: '{EMPNO}' }] }] };
    const nImg = 10 + (CANVAS ? 3 : 0);
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, d118);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'celdas-118__' + format + '__' + r.name), buf);
      if (format === 'pdf') {
        const t = buf.toString('latin1'), n = (t.match(/\/Subtype \/Image/g) || []).length;
        if (n < 3) { throw new Error('pdf imágenes en celdas: ' + n); }
        for (const f of ['NOMBRE', 'CODIGO', 'NOTAS']) { if (!new RegExp('/T \\(' + f + '\\)').test(t)) { throw new Error('pdf campo ' + f); } }
      }
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0];
        if (ws.getImages().length !== nImg) { throw new Error('xlsx imágenes en celdas: ' + ws.getImages().length); }
        const vals = []; ws.eachRow(row => row.eachCell(c => { if (c.value !== null) { vals.push(String(c.value)); } }));
        if (vals.indexOf('ADAMS (CLERK)') < 0 || vals.indexOf('FICHA-7876') >= 0) { throw new Error('xlsx texto/valores: ' + vals.join('|')); }
        const names = wb.definedNames.model.map(d => d.name).sort().join(' ');
        if (names !== 'CODIGO NOMBRE NOTAS') { throw new Error('xlsx nombres: ' + names); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        const n = (xml.match(/<w:drawing>/g) || []).length;
        if (n !== nImg) { throw new Error('docx imágenes en celdas: ' + n); }
        if ((xml.match(/<w:sdt>/g) || []).length !== 3) { throw new Error('docx controles'); }
        const iN = xml.indexOf('Nombre'), iT = xml.indexOf('>ADAMS<'), iO = xml.indexOf('Notas');
        if (!(iN >= 0 && iT > iN && iO > iT)) { throw new Error('docx orden formulario/tabla/formulario'); }
      }
      console.log('OK  ', 'celdas-118__' + format + '__' + r.name);
    }
  }
  /* 1.19: grupos (contenedor con marco), repetición por fila con link y contenedores anidados */
  {
    const d = { EMP: { cols: [U('EMPNO'), N('ENAME'), N('JOB')], rows: byName.slice(0, 3).map(e => [e[0], e[1], e[2]]) },
                VENTAS: { cols: [U('EMPNO'), N('MES'), U('MONTO')],
                          rows: [].concat(...byName.slice(0, 3).map(e => ['ENE', 'FEB', 'MAR'].map((m, i) => [e[0], m, e[4] * (i + 1)]))) } };
    const layout = { fileName: 'grupos-119', sections: [
      { type: 'grupo', title: 'Resumen', border: true, fill: '#F5F7FA', sections: [
        { type: 'texto', text: ['Total de colaboradores: {EMP.EMPNO}'] },
        { type: 'columnas', cols: [
          [{ type: 'columnas', cols: [[{ type: 'texto', text: ['A1'] }], [{ type: 'texto', text: ['A2'] }]] }],
          [{ type: 'grupo', border: true, sections: [{ type: 'texto', text: ['Interno'] }] }]] }] },
      { type: 'grupo', source: 'EMP', each: true, title: 'Colaborador {ENAME}', border: true, link: { VENTAS: { EMPNO: 'EMPNO' } }, sections: [
        { type: 'ficha', source: 'EMP', columns: 2, fields: [{ label: 'Nombre', value: '{ENAME}' }, { label: 'Puesto', value: '{JOB}' }] },
        { type: 'tabla', source: 'VENTAS', columns: ['MES', 'MONTO'], totals: ['MONTO'] },
        { type: 'formulario', columns: 1, fields: [{ label: 'Observación', name: 'OBS' }] }] }] };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, d);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'grupos-119__' + format + '__' + r.name), buf);
      if (format === 'pdf') {
        const t = buf.toString('latin1');
        for (const n of ['OBS_1', 'OBS_2', 'OBS_3']) { if (!new RegExp('/T \\(' + n + '\\)').test(t)) { throw new Error('pdf campo ' + n); } }
      }
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0]; const vals = [];
        ws.eachRow(row => row.eachCell(c => { if (c.value !== null) { vals.push(c.value && c.value.formula ? 'F' : (c.value && c.value.richText ? c.value.richText.map(x => x.text).join('') : String(c.value))); } }));
        for (const v of ['Resumen', 'A1', 'A2', 'Interno', 'Colaborador ADAMS', 'Colaborador ALLEN', 'Colaborador BLAKE']) { if (vals.indexOf(v) < 0) { throw new Error('xlsx falta ' + v + ': ' + vals.join('|')); } }
        if (vals.filter(v => v === 'ENE').length !== 3) { throw new Error('xlsx link por fila: ' + vals.join('|')); }
        const names = wb.definedNames.model.map(x => x.name).sort().join(' ');
        if (names !== 'OBS_1 OBS_2 OBS_3') { throw new Error('xlsx nombres ' + names); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        for (const v of ['Resumen', 'A1', 'A2', 'Interno', 'Colaborador ADAMS', 'Colaborador BLAKE']) { if (xml.indexOf('>' + v + '<') < 0) { throw new Error('docx falta ' + v); } }
        if ((xml.match(/>ENE</g) || []).length !== 3) { throw new Error('docx link por fila'); }
        for (const n of ['OBS_1', 'OBS_2', 'OBS_3']) { if (xml.indexOf('w:val="' + n + '"') < 0) { throw new Error('docx campo ' + n); } }
        const iA = xml.indexOf('>ADAMS<'), iB = xml.indexOf('>Colaborador BLAKE<');
        if (!(iA > 0 && iB > iA)) { throw new Error('docx orden'); }
      }
      console.log('OK  ', 'grupos-119__' + format + '__' + r.name);
    }
  }
  /* 1.20: máscaras numéricas (mask:) en tabla, totales, ficha y texto */
  {
    const d = { DOCS: { cols: [U('SALDO'), U('TASA')], rows: [[-1250.5, 0.0625]] },
                MOVS: { cols: [N('CONCEPTO'), U('DEBITO'), U('CREDITO'), U('SALDO')],
                        rows: [['Apertura', 0, 1500, 1500], ['Pago', 250.75, 0, 1249.25], ['Ajuste', 1300, 0, -50.75]] } };
    const M = 'mask:B/. #,##0.00;(B/. #,##0.00);"-"';
    const layout = { fileName: 'mascaras-120', sections: [
      { type: 'tabla', source: 'MOVS', columns: ['CONCEPTO', { col: 'DEBITO', fmt: M }, { col: 'CREDITO', fmt: '$#,##0.000' }, { col: 'SALDO', fmt: M }],
        totals: ['DEBITO', 'CREDITO'] },
      { type: 'ficha', fields: [{ label: 'Saldo', value: '{SALDO}', fmt: M }, { label: 'Tasa', value: '{TASA}', fmt: 'mask:0.00%' },
                                { label: 'Oracle', value: '{SALDO}', fmt: "ora:FML999G990D00PR;nls=,.;cur='B/. '" }] },
      { type: 'texto', text: ['Saldo {SALDO|mask:B/. #,##0.00;(B/. #,##0.00)} tasa {TASA|0.0%}', 'EU {SALDO|B/. #.##0,00} ORA {SALDO|ora:FM999G990D99MI;nls=,.}'] }] };
    const want = ['(B/. 1,250.50)', '6.25%', 'Saldo (B/. 1,250.50) tasa 6.3%', 'EU -B/. 1.250,50 ORA 1.250,5-', '&lt;B/. 1.250,50&gt;', 'B/. 1,550.75', '$1,500.000', '(B/. 50.75)'];
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, d);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'mascaras-120__' + format + '__' + r.name), buf);
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0]; const f = {};
        ws.eachRow(row => row.eachCell(c => { if (typeof c.value === 'number' || (c.value && c.value.formula)) { f[c.numFmt] = 1; } }));
        for (const nf of ['"B/. "#,##0.00;"(B/. "#,##0.00")";"-"', '"$"#,##0.000', '0.00%', '"B/. "###,##0.00;"<B/. "###,##0.00">"']) { if (!f[nf]) { throw new Error('xlsx numFmt ' + nf + ': ' + Object.keys(f).join(' | ')); } }
      } else {
        const t = format === 'docx' ? await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string') : null;
        for (const w of want) {
          if (format === 'docx' && t.indexOf(w) < 0) { throw new Error('docx falta ' + w); }
        }
      }
      console.log('OK  ', 'mascaras-120__' + format + '__' + r.name);
    }
  }
  /* 1.22: hipervínculos en texto ([a=URL]...[/a]), columnas de tabla, campos de ficha e imágenes (href) */
  {
    const d = { DOCS: { cols: [N('CLIENTE'), N('WEB'), N('CORREO')], rows: [['Banco Demo', 'www.novacode-labs.com', 'info@novacode-labs.com']] },
                MOVS: { cols: [U('ID'), N('CONCEPTO'), U('MONTO')], rows: [[101, 'Apertura', 1500], [102, 'Pago', 250.75], [103, 'Ajuste', -50.75]] } };
    const layout = { fileName: 'vinculos-122', sections: [
      { type: 'texto', source: 'DOCS', text: ['Visite [a=https://apex.oracle.com]Oracle APEX[/a] o escriba a [a=mailto:{CORREO}]**{CORREO}**[/a].',
                                              'Color propio: [a={WEB}][c=#AA1E1E]sitio web[/c][/a]. Esquema inválido: [a=javascript:alert(1)]sin vínculo[/a].'] },
      { type: 'ficha', source: 'DOCS', columns: 2, fields: [{ label: 'Cliente', value: '{CLIENTE}' }, { label: 'Web', value: '{WEB}', href: '{WEB}' },
                                                            { label: 'Correo', value: '{CORREO}', href: 'mailto:{CORREO}', labelPosition: 'top' }] },
      { type: 'tabla', source: 'MOVS', columns: [{ col: 'ID', href: 'https://example.com/mov?id={ID}' }, 'CONCEPTO',
                                                  { col: 'MONTO', fmt: 'money', href: 'https://example.com/mov?id={ID}&m={MONTO}' }] },
      { type: 'imagen', url: 'data:image/png;base64,' + logo.toString('base64'), width: 30, href: 'https://www.novacode-labs.com' }] };
    const want = ['https://apex.oracle.com', 'mailto:info@novacode-labs.com', 'https://www.novacode-labs.com',
                  'https://example.com/mov?id=101', 'https://example.com/mov?id=103&m=-50.75'];
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const r = await window.novaReport.build({ layout, format, output: 'file', zipType: 'nodebuffer' }, d);
      const buf = Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data);
      fs.writeFileSync(path.join(OUT, 'vinculos-122__' + format + '__' + r.name), buf);
      let t;
      if (format === 'pdf') { t = (buf.toString('latin1').match(/\/URI \([^)]*\)/g) || []).join(' '); }
      else {
        const z = await window.JSZip.loadAsync(buf), parts = [];
        for (const n of Object.keys(z.files)) { if (/\.rels$/.test(n)) { parts.push(await z.file(n).async('string')); } }
        t = parts.join(' ').replace(/&amp;/g, '&');
      }
      for (const w of want) { if (t.indexOf(w) < 0) { throw new Error(format + ' falta vínculo ' + w); } }
      if (/javascript:/.test(t)) { throw new Error(format + ' aceptó javascript:'); }
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); let m = null;
        wb.worksheets[0].eachRow(row => row.eachCell(c => { if (c.value && c.value.hyperlink === 'https://example.com/mov?id=101&m=1500') { m = c.value.text; } }));
        if (m !== '1,500.00') { throw new Error('xlsx texto del vínculo ' + m); }
      }
      if (format === 'docx') {
        const xml = await (await window.JSZip.loadAsync(buf)).file('word/document.xml').async('string');
        if ((xml.match(/<w:hyperlink /g) || []).length < 10) { throw new Error('docx w:hyperlink'); }
      }
      console.log('OK  ', 'vinculos-122__' + format + '__' + r.name);
    }
  }
  /* 1.23: encabezado de página, quiebres multinivel, van/vienen, salto por grupo, pivot, contraseña y anexos */
  {
    const zlib = require('zlib');
    /* Texto de un PDF: une los streams (inflados si vienen comprimidos) */
    const pdfText = buf => {
      const s = buf.toString('latin1'), out = []; const re = /(?<!end)stream\r?\n/g; let m;
      while ((m = re.exec(s))) {
        const a = m.index + m[0].length, b = s.indexOf('endstream', a);
        if (b < 0) { break; }
        const raw = buf.subarray(a, b);
        try { out.push(zlib.inflateSync(raw).toString('latin1')); } catch (e) { out.push(raw.toString('latin1')); }
        re.lastIndex = b;
      }
      return out.join('\n');
    };
    const save = (name, buf) => fs.writeFileSync(path.join(OUT, name), buf);
    const B = async (layout, format, output, d, params) => {
      const r = await window.novaReport.build({ layout, format, output, params: params || {}, zipType: 'nodebuffer' }, d);
      return { r, buf: Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data) };
    };
    const xmlOf = async (buf, part) => (await window.JSZip.loadAsync(buf)).file(part).async('string');
    /* Encabezado de página: dos documentos unidos, sin encabezado en la primera página de cada uno */
    const rows = []; for (let i = 0; i < 120; i++) { const e = EMP[i % 14]; rows.push([i % 2 + 1, e[1] + '_' + i, e[2], DEPT[e[6]][0], e[4]]); }
    const dph = { DOCS: { cols: [U('DOC_KEY'), N('CLIENTE')], rows: [[1, 'Banco Uno'], [2, 'Banco Dos']] },
                  MOVS: { cols: [U('DOC_KEY'), N('ENAME'), N('JOB'), N('DNAME'), U('SAL')], rows } };
    const lph = { fileName: 'encabezado-123',
      pageHeader: { image: { url: 'data:image/png;base64,' + logo.toString('base64') }, left: { text: 'NovaCode, S.A.\nEstado de cuenta', bold: true },
                    center: '{DOC.CLIENTE}', right: 'Pag. {DOCPAGE} de {DOCPAGES}', firstPage: false },
      sections: [{ type: 'header', title: 'Estado {DOC.CLIENTE}' }, { type: 'tabla', source: 'MOVS', columns: ['ENAME', 'JOB', 'DNAME', 'SAL'], totals: ['SAL'] }],
      footer: { left: 'Uso interno', right: 'Pagina {PAGE} de {PAGES} doc {DOCPAGE}/{DOCPAGES}' } };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const { r, buf } = await B(lph, format, 'merge', dph);
      save('encabezado-123__' + format + '__' + r.name, buf);
      if (format === 'pdf') {
        const t = pdfText(buf);
        if ((t.match(/\(NovaCode, S\.A\.\) Tj/g) || []).length !== 2) { throw new Error('pdf encabezado de página: ' + (t.match(/\(NovaCode, S\.A\.\) Tj/g) || []).length); }
        for (const w of ['(Pag. 2 de 2) Tj', '(Pagina 3 de 4 doc 1/2) Tj', '(Pagina 4 de 4 doc 2/2) Tj']) { if (t.indexOf(w) < 0) { throw new Error('pdf falta ' + w); } }
      }
      if (format === 'xlsx') {
        const x = await xmlOf(buf, 'xl/worksheets/sheet1.xml');
        if (!/differentFirst="1"/.test(x) || !/&amp;CBanco Uno|&amp;C&amp;8Banco Uno/.test(x) || !/Pag\. &amp;P de &amp;N/.test(x)) { throw new Error('xlsx encabezado de impresión'); }
      }
      if (format === 'docx') {
        const z = await window.JSZip.loadAsync(buf), x = await z.file('word/document.xml').async('string');
        if ((x.match(/<w:titlePg\/>/g) || []).length !== 2 || (x.match(/<w:pgNumType w:start="1"\/>/g) || []).length !== 2) { throw new Error('docx secciones'); }
        const hs = await Promise.all(Object.keys(z.files).filter(n => /word\/header\d+\.xml$/.test(n)).map(n => z.file(n).async('string')));
        if (!hs.some(h => /NovaCode, S\.A\./.test(h) && /SECTIONPAGES/.test(h))) { throw new Error('docx encabezado de página'); }
      }
      console.log('OK  ', 'encabezado-123__' + format + '__' + r.name);
    }
    /* Quiebres multinivel + van / vienen, y salto de página por grupo */
    const qr = [];
    ['NORTE', 'SUR'].forEach(reg => ['Casa Matriz', 'Sucursal 2'].forEach(suc => { for (let i = 0; i < 40; i++) { const e = EMP[i % 14]; qr.push([reg, suc, e[1] + '_' + i, e[4]]); } }));
    const dq = { MOVS: { cols: [N('REGION'), N('SUCURSAL'), N('CLIENTE'), U('MONTO')], rows: qr } };
    const tq = { type: 'tabla', source: 'MOVS', columns: ['REGION', 'SUCURSAL', 'CLIENTE', { col: 'MONTO', fmt: 'money' }], totals: ['MONTO'],
                 breakBy: ['REGION', 'SUCURSAL'], breakTitle: ['Region {REGION}', 'Sucursal {SUCURSAL} ({COUNT})'],
                 breakLabel: ['Total region {REGION}', 'Total {SUCURSAL}'], carry: true };
    for (const bp of [false, true]) {
      const lq = { fileName: 'quiebres-123-' + (bp ? 'pagina' : 'multi'), sections: [Object.assign({}, tq, { breakPage: bp })], footer: { right: 'Pagina {PAGE} de {PAGES}' } };
      for (const format of ['pdf', 'xlsx', 'docx']) {
        const { r, buf } = await B(lq, format, 'file', dq);
        save('quiebres-123__' + format + '__' + r.name, buf);
        if (format === 'pdf') {
          const t = pdfText(buf), van = (t.match(/\(Van\) Tj/g) || []).length, vie = (t.match(/\(Vienen\) Tj/g) || []).length;
          if (!van || van !== vie) { throw new Error('pdf van/vienen ' + van + '/' + vie); }
          for (const w of ['(Total region NORTE) Tj', '(Total region SUR) Tj', '(339,300.00) Tj', '(Sucursal Sucursal 2 \\(40\\)) Tj']) { if (t.indexOf(w) < 0) { throw new Error('pdf falta ' + w); } }
          if (!bp && (!/\(110,500.00\) Tj/.test(t) || !/\(217,950.00\) Tj/.test(t))) { throw new Error('pdf monto de van/vienen'); }
        }
        if (format === 'xlsx') {
          const x = await xmlOf(buf, 'xl/worksheets/sheet1.xml'), f = (x.match(/<f>[^<]*<\/f>/g) || []).join(' ');
          const fw = 'SUBTOTAL(9,D4:D43) SUBTOTAL(9,D46:D85) SUBTOTAL(9,D4:D86) SUBTOTAL(9,D90:D129) SUBTOTAL(9,D132:D171) SUBTOTAL(9,D90:D172) SUBTOTAL(9,D2:D173)';
          if (f.replace(/<\/?f>/g, '') !== fw) { throw new Error('xlsx subtotales anidados: ' + f); }
          if (bp !== /<rowBreaks count="1"/.test(x)) { throw new Error('xlsx salto de página por grupo'); }
        }
        if (format === 'docx') {
          const x = await xmlOf(buf, 'word/document.xml');
          if ((x.match(/w:type="page"/g) || []).length !== (bp ? 1 : 0)) { throw new Error('docx salto de página por grupo'); }
          if (x.indexOf('>Total region SUR<') < 0) { throw new Error('docx subtotal de nivel 1'); }
        }
        console.log('OK  ', 'quiebres-123__' + format + '__' + r.name);
      }
    }
    /* Tabla cruzada */
    const pv = []; [['NORTE', 'Casa Matriz'], ['NORTE', 'Sucursal 2'], ['SUR', 'Sucursal 3']].forEach(([rg, sc], j) => ['ENE', 'FEB', 'MAR'].forEach((ms, i) => {
      if (!(j === 2 && i === 1)) { pv.push([rg, sc, ms, i + 1, 1000 * (j + 1) + i * 100.5]); } }));
    const dpv = { VENTAS: { cols: [N('REGION'), N('SUCURSAL'), N('MES'), U('NMES'), U('MONTO')], rows: pv } };
    const lpv = { fileName: 'pivot-123', sections: [
      { type: 'pivot', source: 'VENTAS', rows: ['REGION', 'SUCURSAL'], rowLabels: ['Region', 'Sucursal'], cols: 'MES', colOrder: ['MAR', 'ENE'], value: 'MONTO', fmt: 'money' },
      { type: 'pivot', source: 'VENTAS', rows: 'REGION', cols: 'NMES', sortCols: true, fn: 'count', colLabel: 'Mes {NMES}' }] };
    for (const format of ['pdf', 'xlsx', 'docx']) {
      const { r, buf } = await B(lpv, format, 'file', dpv);
      save('pivot-123__' + format + '__' + r.name, buf);
      if (format === 'xlsx') {
        const wb = new window.ExcelJS.Workbook(); await wb.xlsx.load(buf); const ws = wb.worksheets[0], got = [];
        ws.eachRow(row => got.push(row.values.slice(1).map(v => v && v.formula ? 'F' : v).join('|')));
        const want = ['Region|Sucursal|MAR|ENE|FEB|Total', 'NORTE|Casa Matriz|1201|1000|1100.5|3301.5', 'NORTE|Sucursal 2|2201|2000|2100.5|6301.5',
                      'SUR|Sucursal 3|3201|3000||6201', 'Totales|Totales|F|F|F|F', 'Region|Mes 1|Mes 2|Mes 3|Total', 'NORTE|2|2|2|6', 'SUR|1||1|2', 'Totales|F|F|F|F'];
        if (got.filter(Boolean).join(' / ') !== want.join(' / ')) { throw new Error('xlsx pivot: ' + got.filter(Boolean).join(' / ')); }
      }
      console.log('OK  ', 'pivot-123__' + format + '__' + r.name);
    }
    /* PDF con contraseña: una por documento (plantilla) */
    const dsec = { DOCS: { cols: [U('DOC_KEY'), N('CEDULA')], rows: [[1, '8-765-4321'], [2, '4-111-222']] }, EMP: { cols: [N('ENAME'), U('SAL')], rows: EMP.map(e => [e[1], e[4]]) } };
    const lsec = { fileName: 'clave-123-{DOC.DOC_KEY}', pdf: { password: '{DOC.CEDULA}', permissions: ['print'] }, sections: [{ type: 'tabla', source: 'EMP' }] };
    { const { r, buf } = await B(lsec, 'pdf', 'zip', dsec); save('clave-123__pdf__' + r.name, buf);
      const z = await window.JSZip.loadAsync(buf), names = Object.keys(z.files).sort();
      if (names.join(' ') !== 'clave-123-1.pdf clave-123-2.pdf') { throw new Error('pdf clave: ' + names.join(' ')); }
      for (const n of names) { const s = Buffer.from(await z.file(n).async('uint8array')).toString('latin1'); if (!/\/Encrypt \d+ 0 R/.test(s) || !/\/P -60/.test(s)) { throw new Error('pdf sin cifrado ' + n); } }
      const p2 = await B(Object.assign({}, lsec, { pdf: undefined }), 'pdf', 'merge', dsec);
      if (/\/Encrypt/.test(p2.buf.toString('latin1'))) { throw new Error('pdf cifrado sin contraseña'); }
      console.log('OK  ', 'clave-123__pdf__' + r.name); }
    /* Anexar PDFs (BLOB por documento): las páginas anexas van después de cada documento */
    if (window.PDFLib) {
      const mk = n => { const d = new window.jspdf.jsPDF(); for (let i = 1; i < n; i++) { d.addPage(); } return Buffer.from(d.output('arraybuffer')).toString('base64'); };
      const dap = { DOCS: { cols: [U('DOC_KEY'), N('CLIENTE'), { name: 'SOPORTE', type: 'BLOB' }], rows: [[1, 'Uno', mk(2)], [2, 'Dos', mk(3)]] } };
      const lap = { fileName: 'anexos-123', append: [{ field: 'SOPORTE' }], sections: [{ type: 'texto', text: 'Documento {DOC.CLIENTE}' }] };
      const { r, buf } = await B(lap, 'pdf', 'merge', dap); save('anexos-123__pdf__' + r.name, buf);
      const n = (await window.PDFLib.PDFDocument.load(buf)).getPageCount();
      if (n !== 7) { throw new Error('pdf anexos: ' + n + ' páginas'); }
      let err = null; try { await B(Object.assign({ pdf: { password: 'x' } }, lap), 'pdf', 'merge', dap); } catch (e) { err = e.message; }
      if (!/contraseña/.test(err || '')) { throw new Error('pdf anexos + contraseña debe fallar'); }
      console.log('OK  ', 'anexos-123__pdf__' + r.name);
    } else { console.log('OMITIDO anexos-123 (sin pdf-lib)'); }
  }
})().catch(e => { console.error('FALLÓ', e); process.exit(1); });
