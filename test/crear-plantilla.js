/* Crea examples/06-plantilla-word/plantilla.docx con marcadores de docxtemplater */
const fs = require('fs'), path = require('path');
const d = require('docx');
const P = (t, o = {}) => new d.Paragraph({ children: [new d.TextRun({ text: t, bold: !!o.bold, size: o.size })], alignment: o.align });
const cell = (t, head) => new d.TableCell({ children: [P(t, { bold: head })],
  shading: head ? { type: d.ShadingType.CLEAR, color: 'auto', fill: 'D9E2F3' } : undefined });
const doc = new d.Document({ creator: 'novaReport', sections: [{ children: [
  P('EMPRESA DE EJEMPLO, S.A.', { bold: true, size: 32 }),
  P('Ciudad, {TODAY}', { align: d.AlignmentType.RIGHT }),
  P(''),
  P('Equipo del departamento {DNAME}', { bold: true, size: 28 }),
  P('Ubicación: {LOC}. Personas: {EMPLEADOS|int}. Planilla mensual: {SALARIOS|money}.'),
  P(''),
  new d.Table({ width: { size: 100, type: d.WidthType.PERCENTAGE }, rows: [
    new d.TableRow({ tableHeader: true, children: ['Nombre', 'Puesto', 'Ingreso', 'Salario'].map(t => cell(t, true)) }),
    new d.TableRow({ children: [cell('{#EQUIPO}{ENAME}'), cell('{JOB}'), cell('{HIREDATE}'), cell('{SAL|money}{/EQUIPO}')] })
  ] }),
  P(''),
  P('Documento generado el {NOW} con novaReport.')
] }] });
d.Packer.toBuffer(doc).then(b => {
  const out = path.join(__dirname, '..', 'examples', '06-plantilla-word', 'plantilla.docx');
  fs.writeFileSync(out, b); console.log('OK', out, b.length);
});
