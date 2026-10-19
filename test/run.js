/* Ejecuta los ejemplos de /examples en Node con datos EMP/DEPT de prueba y deja los archivos en test/out */
global.window = global;
global.document = { getElementById() { return null; }, addEventListener() {} };
window.jspdf = require('jspdf'); require('jspdf-autotable');
window.ExcelJS = require('exceljs'); window.JSZip = require('jszip'); window.docx = require('docx');
window.PizZip = require('pizzip'); window.docxtemplater = require('docxtemplater');
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
      rows: EMP.slice().sort((a, b) => a[6] - b[6] || b[4] - a[4]).map(e => [e[6], e[1], e[2], e[3], e[4]]) } }
};
const runs = [['01-listado-empleados', 'pdf', 'file'], ['01-listado-empleados', 'xlsx', 'file'], ['01-listado-empleados', 'docx', 'file'],
  ['02-cartas-zip', 'pdf', 'zip'], ['02-cartas-zip', 'pdf', 'merge'], ['03-constancia-posicion-fija', 'pdf', 'file'],
  ['04-imagen-blob', 'pdf', 'zip'], ['04-imagen-blob', 'docx', 'zip'],
  ['05-excel-multihoja', 'xlsx', 'file'], ['05-excel-multihoja', 'pdf', 'file'], ['05-excel-multihoja', 'docx', 'file'],
  ['05-excel-multihoja', 'all', 'zip'],
  ['06-plantilla-word', 'docx-template', 'zip', '06-plantilla-word/plantilla.docx']];

fs.mkdirSync(OUT, { recursive: true });
(async () => {
  for (const [ex, format, output, templateUrl] of runs) {
    const layout = JSON.parse(fs.readFileSync(path.join(EX, ex, 'diseno.json'), 'utf8'));
    (layout.sections || []).forEach(s => { if (s.type === 'imagen' && s.url) { s.url = '#APP_FILES#' + logo.toString('base64'); } });
    const t = Date.now();
    const r = await window.novaReport.build({ layout, format, output, templateUrl, zipType: 'nodebuffer' }, data[ex]);
    const name = ex + '__' + format + '_' + output + '__' + r.name;
    fs.writeFileSync(path.join(OUT, name), Buffer.from(r.data instanceof ArrayBuffer ? new Uint8Array(r.data) : r.data));
    console.log('OK  ', name.padEnd(70), (Date.now() - t) + ' ms');
  }
})().catch(e => { console.error('FALLÓ', e); process.exit(1); });
