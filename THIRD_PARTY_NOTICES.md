# Librerías de terceros

novaReport no incluye estas librerías en el repositorio: las carga en tiempo de ejecución desde un CDN
(o desde la ruta que usted configure en `novaReport.libs`). Cada una conserva su licencia.

| Librería | Versión | Uso | Licencia |
|---|---|---|---|
| [jsPDF](https://github.com/parallax/jsPDF) | 4.2.1 | PDF | MIT |
| [jsPDF-AutoTable](https://github.com/simonbengtsson/jsPDF-AutoTable) | 3.8.4 | Tablas en PDF | MIT |
| [ExcelJS](https://github.com/exceljs/exceljs) | 4.4.0 | Excel | MIT |
| [docx](https://github.com/dolanmiu/docx) | 9.5.1 | Word | MIT |
| [JSZip](https://github.com/Stuk/jszip) | 3.10.1 | ZIP | MIT o GPLv3 (dual) |
| [PizZip](https://github.com/open-xml-templating/pizzip) | 3.1.8 | Plantillas Word | MIT o GPLv3 (dual) |
| [docxtemplater](https://github.com/open-xml-templating/docxtemplater) | 3.60.0 | Plantillas Word | MIT (núcleo) |
| [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator) | 1.4.4 | Códigos QR (sección `codigo`) | MIT |
| [Chart.js](https://github.com/chartjs/Chart.js) | 4.4.9 | Gráficos (sección `grafico`) | MIT |

El código de barras Code 128 y el PNG de los códigos los genera novaReport, sin librerías.

Los módulos de pago de docxtemplater (imágenes, HTML, etc.) **no** se usan.
