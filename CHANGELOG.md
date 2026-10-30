# Cambios

## 1.14.0
- `header`: **`subtitleSize`** y **`rightSize`** (tamaño del subtítulo y del texto derecho), **`font`** (`helvetica`, `times`, `courier`), **`fill`** y **`color`** (fondo y texto sin depender del tema) y `height` (alto mínimo, PDF). En PDF la banda crece con títulos grandes; `size` ahora también aplica en Excel y Word.
- `ficha`: estilo **por campo** con `align` (`left`, `center`, `right`), `bold`, `color` (fijo o según una columna) y `fill`. PDF, Excel y Word.
- Sin cambios para diseños existentes: todas las propiedades nuevas son opcionales (los archivos de prueba salen idénticos a 1.13.0).

## 1.13.0
- Sección **`tarjetas`**: etiqueta pequeña + valor destacado, fondo y barra de acento (`fields`, `columns`, `fill`, `accent`, `labelColor`, `valueColor`, `labelSize`, `size`, `height`, `cardGap`; `color` por tarjeta, fijo o según una columna). Los valores largos se parten en líneas. PDF, Excel y Word; también dentro de `columnas`.
- `ficha`: **`grid`** (cuadrícula), `borderColor`, `labelFill`, `labelColor`, `valueColor` y **`labelWidths`** (ancho por etiqueta). Con `grid` o `labelWidths`, Word respeta los anchos de etiqueta en mm.
- `tabla`: **`headAlign`** (tabla y columna: `left`, `center`, `right`, `auto`), **`grid`** (`true`: bordes en los tres formatos; `false`: Word también sin bordes), `borderColor` y `totalsColor`.
- Sin cambios para diseños existentes: todas las propiedades nuevas son opcionales (los 37 archivos de prueba salen idénticos a 1.12.0).

## 1.12.0
- Sección **`formulario`**: campos editables `text`, `multiline`, `list` (`options`, `optionsFrom`) y `checkbox`, con `maxLength`, `lines`, `placeholder`, `readOnly` y `when`. PDF: AcroForm. Word: controles de contenido. Excel: celdas con nombre y validación de datos.
- `form.protect` / `form.password` (y `run({ formPassword })`): Word protegido *solo formularios* (hash SHA-512 con sal) y hojas de Excel protegidas con las celdas de los campos desbloqueadas.
- Nombres de campo validados (formato y repetidos); en salida unida se agrega `_1`, `_2`… por documento.

## 1.11.0
- Sección **`columnas`**: 1 a 3 casillas lado a lado (`cols`, `widths`, `colGap`), cada una con sus secciones (ficha, texto, imagen, código, alerta, línea, tabla, gráfico, espacio). PDF: franjas; la fila no se parte entre páginas. Word: tabla sin bordes. Excel: bloques de columnas.
- Corregido **Ítems a enviar**: el atributo (`P5_A,P5_B`) se envía como lista de ítems (antes se pasaba como selector jQuery y no se enviaban). Sigue aceptando un arreglo o un selector `#P5_A,#P5_B`.
- Corregido **Plantilla Word (URL)**: reemplaza `#APP_FILES#`, `#WORKSPACE_FILES#` e `#IMAGE_PREFIX#`.
- Excel: el alto de textos y alertas considera el ancho disponible; la columna de totales se ensancha para que no muestre `###`.

## 1.10.0
- `when` en **cualquier sección** (excepto `alerta`, que ya lo usa por fila) y en **columnas** de tabla: se evalúa por documento contra `DOCS`, los parámetros y `{FUENTE.COL}`. Igual en PDF, Excel y Word.
- Formato **`letras`**: monto en letras (`MIL DOSCIENTOS BALBOAS CON 50/100`). Moneda con `letras:BALBOA/BALBOAS` (singular/plural). En Excel queda como texto.
- Excel: las columnas con formato de texto (`upper`, `lower`, `yn`, `letras`) se escriben formateadas (antes `upper`/`lower`/`yn` salían con el valor original).
- **Guardar en el servidor** (`save`): sube el archivo a un proceso de aplicación *On Demand* (`f01` en base64, `x01`…`x05`). `mode: "only"` solo guarda. Evento `novareport-saved`.
- Plantillas `{COL|formato}`: el formato admite `/` y vocales con tilde (`{MONTO|letras:DÓLAR/DÓLARES}`).

## 1.9.0
- `tabla`: totales y subtotales con función por columna: `"totals": ["SAL", { "col": "COMM", "fn": "avg" }]`. Funciones `sum` (por defecto), `avg`, `min`, `max`, `count`. `min`/`max` sirven para números, fechas y texto; `count` cuenta valores no vacíos. Si hay funciones distintas a la suma, cada valor lleva un prefijo (Prom., Mín., Máx., Cant.). En Excel: `SUM`/`AVERAGE`/`MIN`/`MAX`/`COUNTA` o `SUBTOTAL(9|1|5|4|3)` con quiebres. Compatible con `["COL"]`.
- `tabla`: el texto de totales y de subtotales ocupa una celda combinada desde la primera columna hasta la anterior a la primera con agregado (antes iba en la primera columna sin total y se cortaba). Si la primera columna tiene agregado, el texto va en su propia fila. `totalsLabel` admite `{COUNT}`.

## 1.8.0
- Plugin: atributo **Origen** (`attributes` | `resolver`) y **Función resolver**. En `resolver` el navegador solo envía ID + parámetros; una función PL/SQL valida rol y parámetros y devuelve fuentes + diseño. Nunca se acepta SQL del navegador. Los binds se enlazan con tipo (NUMBER, DATE) y sin enlace automático de ítems. Ver `docs/API.md` §3.1.
- Plugin: el *Initialization Code* puede devolver `false` para cancelar; `data-report` en el elemento indica el reporte.
- `plugin/build_plugin.py`: regenera el export del plugin desde `src/plugin.plsql` y `src/novareport.min.js` (`--app N` genera el script de instalación para esa aplicación).

## 1.7.0
- Nueva sección `grafico`: barras, barras horizontales, líneas, área, circular y anillo (Chart.js 4.4.9), con valores o porcentajes sobre el gráfico (el eje deja margen para las etiquetas). PDF, Excel y Word.
- Nueva sección `codigo`: QR (qrcode-generator 1.4.4) y Code 128 propio. Vectorial en PDF; PNG en Word y Excel.
- `tabla`: quiebres de control con subtotales (`breakBy`, `breakTitle`, `breakLabel`, `breakTotals`, `{COUNT}`). En Excel con `=SUBTOTAL()`.
- `watermark` en el diseño: texto rotado y semitransparente por documento, con condición `when`. PDF y Word.
- `page.theme.group`: color de la fila de encabezado de grupo.
- Las librerías de QR y gráficos solo se cargan si el diseño las usa (`novaReport.layoutLibs(layout)`).
- Ejemplo nuevo `07-graficos-codigos`.

## Sin publicar (1.6.x)
- Documentación: README nuevo (español e inglés), `docs/API.md` (atributos, binds, salidas, API JavaScript, eventos, protocolo AJAX, errores, límites) y `docs/DISENO.md` completo (todas las propiedades y qué soporta cada formato).
- Ejemplos nuevos: `05-excel-multihoja` (hojas, encabezado agrupado, `defs`) y `06-plantilla-word` (`docx-template` con `plantilla.docx`).
- Pruebas: jsPDF 4.2.1 (la misma versión que carga el plugin), `npm run test:min` para probar el archivo minificado y soporte de plantillas Word en Node.
- Documentados dos problemas de 1.6.1 con su solución temporal: **Ítems a enviar** no se envía y **Plantilla Word (URL)** no reemplaza `#APP_FILES#`.

## 1.6.1
- Word: el pie de página solo se agrega si el diseño tiene `footer`, y usa `footer.left` / `footer.right` con `{PAGE}` / `{PAGES}` (antes siempre ponía "Página X de Y").

## 1.6.0
- `tabla`: `"groups"` agrega una fila de encabezado agrupado (`colSpan`); las columnas fuera de un grupo ocupan las dos filas (PDF y Excel).
- Columnas con `"color"` fijo de texto (PDF, Excel y Word).
- `ficha`: cada campo acepta `"when"` para mostrarse solo si se cumple la condición.
- `emptyMessage` en el diseño: mensaje cuando la fuente `DOCS` no devuelve filas.
- `"@NOMBRE"` dentro de un arreglo se expande si `defs.NOMBRE` es un arreglo (reutilizar grupos de columnas).

## 1.5.2
- Rutas de librerías aceptan `#APP_FILES#` / `#WORKSPACE_FILES#` (para servirlas localmente).
- En modo `merge`, el archivo toma `batch.mergeName` / `batch.zipName` en lugar del nombre del primer documento.

## 1.5.1
- Corrección: las tablas PDF se dibujaban con alto 0 cuando el diseño tenía una sección `imagen`.

## 1.5.0
- Imágenes desde columnas **BLOB** (`"field"`); BLOB y CLOB viajan en base64 / texto.

## 1.4.0
- Texto e imágenes en **posición fija** (`x`, `y`) en PDF.
- Nueva sección `linea` (horizontal o vertical).
- Corrección de espacios entre palabras (ancho sin kerning).

## 1.3.0
- Nueva sección `imagen` (URL, `#APP_FILES#`).

## 1.2.0
- Texto enriquecido: tachado `~~`, subrayado `++`, tipos de letra `[f=…]` y colores `[c=…]`.

## 1.1.0
- Texto enriquecido: `**negrita**`, `*cursiva*`; alineación justificada; sección `espacio`.

## 1.0.1
- Compatibilidad con la API v2 de plugins de APEX 26.1 (`function_name` / `function_param`).

## 1.0.0
- Primera versión: PDF, Excel y Word desde SQL + diseño JSON; lotes en ZIP con resumen.
