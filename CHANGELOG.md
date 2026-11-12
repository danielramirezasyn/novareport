# Cambios

## 1.24.0
- **Dos idiomas (inglés y español)** en los textos propios del plugin: mensajes de espera y de error, `Totales`, `Subtotal`, `Total`, `Van / Vienen`, `Prom. / Mín. / Máx. / Cant.`, `Sí / No` (`yn`), *Página X de Y* de Excel, el mensaje sin datos, los nombres por defecto (`reporte`, `Reporte`, `reportes.zip`) y los errores del servidor (PL/SQL).
- El idioma se resuelve en este orden: `"lang": "en" | "es"` en el diseño; atributo nuevo **Language** (`Automatic`, `English`, `Español`; opción `lang` de `novaReport.run`); idioma de la sesión de APEX. Sesión en español: español. Cualquier otro idioma: **inglés** (el idioma por defecto).
- Atributos del plugin en inglés en el Builder, con la ayuda en ambos idiomas. Los identificadores internos (`sources`, `layout`, `format`…) no cambian: las acciones existentes conservan sus valores. **Wait Message** ya no trae valor por defecto: vacío usa el texto del idioma (el valor anterior, `Consultando datos...`, se traduce si el idioma no es español).
- **Alias en inglés de las secciones**: `table`, `details`, `cards`, `text`, `image`, `chart`, `code`, `form`, `line`, `columns`, `group`, `alert`, `space` y `pagebreak`. Los nombres originales (`tabla`, `ficha`…) funcionan igual y se pueden mezclar.
- Formato **`words`**: monto en letras en inglés (`words`, `words:DOLLAR/DOLLARS`). `letras` no cambia.
- **`locale`**: separadores de números (`money`, `num`, `int`, `pct`) y formato de fecha en PDF y Word. `"locale": "es-ES"` (o `en-US`, `de-DE`, `pt-BR`…) o `{ "decimal": ",", "thousands": ".", "date": "dd-mon-yyyy" }`. Excel recibe el formato de fecha; sus separadores los pone la configuración regional del equipo. Sin `locale`: `1,234.50` y `dd/mm/yyyy`, como antes.
- **Tamaños de página** en Word y Excel: `a3`, `a5`, `b5`, `tabloid` y `executive` (además de `letter`, `legal` y `a4`). Word acepta también el tamaño propio en mm `[ancho, alto]`, como el PDF.
- `novaReport.lang()` devuelve el idioma del último reporte generado. El navegador envía el idioma al servidor en `x04`.
- Compatibilidad: con la sesión en español y sin las propiedades nuevas, los archivos de prueba de 1.23.0 salen idénticos byte a byte (fecha fija), también con el minificado. Lo único que cambia es una aplicación cuya sesión **no** está en español: los textos propios pasan a inglés. `Language = Español` en la acción o `"lang": "es"` en el diseño los deja como antes.
- Variante APEX 23.2: atributo 12 **Language**; el resto igual.
- Ejemplo nuevo: `14-english-invoice`. Pruebas nuevas en `test/run.js`, que ahora corre como una sesión en español.
- Designer 0.22.0: en Documento, grupo **Idioma y formato regional** (idioma de los textos y formato regional); tamaños `a5`, `b5`, `tabloid` y `executive`; formatos `words`; al cargar un diseño convierte los alias en inglés a los nombres originales.

## 1.23.0
- **Encabezado de página** (`pageHeader`): banda en cada página con imagen (`image.align`: izquierda, centro o derecha) y textos a la izquierda, centro y derecha, línea inferior y `firstPage: false` para omitirlo en la primera página. PDF (el contenido y las tablas largas continúan debajo de la banda), Word (encabezado de Word) y Excel (encabezado de impresión, solo texto).
- Marcadores **`{DOCPAGE}` / `{DOCPAGES}`**: página y total del documento en `footer` y `pageHeader`; en un archivo unido cada documento numera desde 1 (en Word, sección con numeración propia).
- **Quiebres anidados**: `breakBy` acepta una lista (`["REGION", "SUCURSAL"]`); `breakTitle` y `breakLabel` aceptan una lista por nivel. En Excel cada nivel usa `SUBTOTAL()` sobre su grupo.
- **`breakPage`**: cada grupo del primer nivel en una página nueva (PDF y Word; salto de impresión en Excel). El total general sale al final, sobre todas las filas.
- **Van / Vienen** (`carry`, PDF): acumulado de las columnas al pie de cada página y al inicio de la siguiente.
- Sección **`pivot`** (tabla cruzada): `rows`, `cols`, `value`, `fn` (`sum`, `avg`, `min`, `max`, `count`), orden de columnas (`colOrder`, `sortCols`), totales por fila y por columna. Se dibuja como una `tabla` y admite sus propiedades.
- **PDF con contraseña** (`pdf.password`, `ownerPassword`, `permissions`; opción `pdfPassword` en `novaReport.run`). Acepta plantillas: una contraseña por documento en un lote.
- **Anexar PDFs** (`append`): PDFs de una columna BLOB (del documento o de una fuente) o de una URL, después de las páginas de cada documento. Usa pdf-lib 1.17.1, que se carga solo si el diseño trae `append`.
- Sin cambios para diseños existentes: los archivos de prueba de 1.22.0 salen idénticos (fecha fija).
- Ejemplo nuevo: `13-estado-cuenta`. Pruebas nuevas en `test/run.js` (`pdf-lib` agregado a `devDependencies`).
- Designer 0.21.0: componente **Tabla cruzada**; en Documento, grupos **Encabezado de página**, **PDF: contraseña** y **PDF: anexar documentos**; en Tabla, **niveles de quiebre** (agregar, ordenar, quitar), **un grupo por página** y **Van / Vienen**; la galería de imágenes sirve también para el logo del encabezado de página.

## 1.22.0
- **Hipervínculos** en PDF, Excel y Word:
  - Texto enriquecido: `[a=https://…]texto[/a]` (la URL admite plantillas: `[a=mailto:{CORREO}]{CORREO}[/a]`).
  - `href` en columnas de tabla (por fila, también en celdas con imagen o código), en campos de `ficha` y en `imagen`.
- Se aceptan `http(s)`, `mailto`, `tel` y `ftp`; `www.` pasa a `https://`; las rutas relativas se completan con la URL de la página (para páginas de APEX, `apex_page.get_url` en la consulta). Otros esquemas (`javascript:`…) se descartan.
- Estilo: subrayado y color `page.theme.link` (`#0563C1`); un color propio (`[c=]`, `color` de la columna, reglas) tiene prioridad.
- Excel admite un vínculo por celda: un párrafo con varios toma el primero; una celda numérica con `href` pasa a texto con el formato de la columna.
- Sin cambios para diseños existentes: los archivos de prueba de 1.21.0 salen idénticos.
- Ejemplo nuevo: `12-hipervinculos` (URL de páginas de APEX con `apex_page.get_url`).
- Designer 0.20.0: propiedad **Hipervínculo (URL)** en columnas, contenido de celda (imagen y código), campos de ficha e imagen; ícono de vínculo en el lienzo y vista previa de `[a=…]` en el texto.

## 1.21.0
- Máscaras con **coma decimal**: `B/. #.##0,00` → `B/. 1.234,50` (también `0,00`). `0,000` y `#,##0` siguen siendo miles, como en Excel.
- Formato **`ora:`**: modelo de `TO_CHAR` de Oracle aplicado en la visualización, sin cambiar la consulta. Ej.: `ora:FML999G999G990D00;nls=,.;cur='B/. '` → `B/. 1.234,50`. Elementos `9 0 G D , . L U C $ PR MI S B FM`; opciones `nls` (decimal y miles), `cur` e `iso`.
- Excel: la celda sigue siendo número con el formato equivalente; los separadores los pone la configuración regional del equipo.
- Sin cambios para diseños existentes: los archivos de prueba de 1.19.0 salen idénticos byte a byte.
- Designer 0.19.0: sugerencias de máscaras con coma decimal y de modelos `ora:` en el campo **Formato**.

## 1.20.0
- Formato **`mask:`**: máscara numérica estilo Excel para símbolo de moneda, decimales, miles y negativos. Ej.: `mask:B/. #,##0.00;(B/. #,##0.00);"-"` (positivo;negativo;cero), `mask:#,##0.000 "USD"`, `mask:0.0%`, `mask:#,##0.0,, "M"`, `mask:000000`. Sirve en `fmt` de columnas, totales, ficha y formulario, y en plantillas `{COL|mask:…}`. El prefijo `mask:` es opcional (`B/. #,##0.00`).
- PDF y Word aplican la máscara en el plugin; Excel recibe el mismo formato en `numFmt`, así la celda sigue siendo número y los totales (`SUMA`, `PROMEDIO`…) toman el formato de la columna.
- Sin cambios para diseños existentes: los archivos de prueba de 1.19.0 salen idénticos byte a byte.
- Designer 0.18.0: el campo **Formato** sugiere máscaras listas (B/., $, €, 3-4 decimales, negativos entre paréntesis, porcentaje, millones, ceros a la izquierda) y acepta cualquier máscara escrita a mano.

## 1.19.0
- Sección **`grupo`**: contenedor con título, borde, fondo y margen interno que admite cualquier sección (incluidos `columnas` y otro `grupo`). PDF, Excel y Word.
- **Repetir por fila**: `grupo` con `source` + `each` se dibuja una vez por fila (como el *repeating frame* de Oracle Reports). Las columnas de la fila se leen como `{COL}` y `link` filtra fuentes relacionadas. Los campos de formularios repetidos llevan `_1`, `_2`…
- Una sección dentro de un grupo sin `source` toma la del grupo.
- **Anidamiento libre**: `columnas` dentro de `columnas`, `grupo` dentro de `columnas`, y `columnas` o `grupo` como bloque dentro de formulario, ficha o tarjetas.
- Sin cambios para diseños existentes: los archivos de prueba de 1.17.0 salen idénticos byte a byte.
- Documentado `page.size: [ancho, alto]` (mm, solo PDF). Ejemplos nuevos: `10-reclamo-gastos-medicos` y `11-cheque`.
- Designer 0.17.0: componente Grupo en la barra; se puede arrastrar cualquier componente dentro de grupos y columnas a cualquier nivel (y sacarlo); propiedades del grupo con repetición por fila; selector para cambiar de reporte junto al nombre; tamaño de página personalizado.

## 1.18.0
- **Bloques en celdas de tabla**: `columns[].cell` con `type` `codigo` (QR o Code 128), `imagen` (columna BLOB de la fila o URL), `grafico` (por fila, con `link` o `filter` para tomar solo las filas relacionadas) o `texto` (plantilla). La columna se ajusta al contenido. PDF, Excel (imagen sobre la celda) y Word.
- `tabla.valign` (`top`, `middle`, `bottom`): alineación vertical de las filas. Sin definir: centro si la tabla tiene celdas con imagen o código; arriba en el resto (como antes). `columns[].valign` la cambia por columna.
- **Bloques dentro de un formulario, ficha o tarjetas**: un campo `{ "span": "row", "block": { "type": "tabla", … } }` pone una tabla (u otro bloque: ficha, tarjetas, texto, imagen, código, alerta, línea, gráfico, espacio) entre los campos. La sección se parte en tramos con la misma configuración; un bloque sin fuente toma la de la sección.
- Sin cambios para diseños existentes: las propiedades nuevas son opcionales.
- Designer 0.16.0: arrastrar Código, Imagen, Gráfico o Texto (desde la barra o desde el lienzo) sobre el encabezado de una tabla crea una columna con ese contenido; arrastrar un bloque sobre un formulario lo inserta entre los campos. Se pueden sacar de nuevo al lienzo arrastrándolos. Panel de propiedades propio para el contenido de la celda.

## 1.17.0
- Origen **Consulta** (`query`): el diseño y/o las fuentes SQL se leen de una tabla propia con una consulta que devuelve una fila (`LAYOUT`, `SOURCES` y opcional `TEMPLATE_URL`). Quita el límite de 4000 caracteres de los atributos sin depender de una función resolver ni del Designer. Lo que la consulta no devuelva se toma de los atributos.
- Atributo nuevo **Consulta del reporte**. Con este origen, **Fuentes SQL** y **Diseño (JSON)** pasan a ser opcionales.
- La consulta admite ítems de APEX y binds desde `data-*`, igual que las fuentes. Errores claros: sin filas, varias filas, columnas faltantes o `LAYOUT` que no es JSON.
- Sin cambios para acciones existentes: los orígenes Atributos y Resolver funcionan igual (los archivos de prueba salen idénticos a 1.16.0).

## 1.16.0
- `ficha` y `formulario`: **`labelPosition`** (`left`, `top`, `none`) en la sección y **por campo**. `top` pone la etiqueta sobre el valor en la misma casilla (estilo formulario bancario); `none` deja el valor solo. Se combina con `span` y huecos, y una misma fila puede mezclar posiciones.
- Estilo de etiqueta en la sección y por campo: `labelSize`, `labelColor`, `labelFill`, `labelBold`, `labelCase` (`upper`) y `labelAlign`.
- PDF: etiqueta dibujada sobre la celda y el valor o el campo AcroForm debajo. Excel: las filas con etiquetas arriba usan dos filas reales; los nombres definidos del formulario apuntan al valor. Word: dos párrafos por celda; en formulario, el control de contenido va en una caja bajo la etiqueta.
- Sin cambios para diseños existentes: todas las propiedades nuevas son opcionales (los archivos de prueba salen idénticos a 1.15.0).

## 1.15.0
- `ficha` y `formulario`: **huecos** (`{ "empty": true }`) y campos **anchos** con `span` (`2`, `3`… o `"row"` para el resto de la fila). Un campo que no cabe en lo que queda de la fila empieza una nueva. PDF, Excel (celdas combinadas) y Word (`gridSpan`).
- Con huecos o `span`, en PDF las columnas de valor toman el mismo ancho.
- Sin cambios para diseños existentes (los archivos de prueba salen idénticos a 1.14.0).

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
