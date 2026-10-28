# Cambios

## 1.12.0
- Sección **`formulario`**: campos editables en el documento generado.
  - Tipos (`input`): `text`, `multiline`, `list` y `checkbox`.
  - `value` es una plantilla (`{COL}`) con `fmt` y `map`, igual que en `ficha`.
  - Listas: opciones fijas (`options`) o desde una fuente (`optionsFrom: "FUENTE.COLUMNA"`; sin columna usa la primera). Si el valor inicial no está en las opciones, queda vacío.
  - Casilla: la marcan `S`, `SI`, `SÍ`, `Y`, `YES`, `1`, `X`, `TRUE` u `ON`.
  - Por campo: `maxLength` (recorta el valor inicial), `lines` (2 a 20, solo `multiline`), `readOnly`, `placeholder` y `when`.
  - Sección: `source`, `columns` (defecto 2), `labelWidth` (32), `size` (8.5) y `when`. También va dentro de `columnas`.
- Diseño: **`form`** con `protect` (defecto `true`) y `password`. La opción `formPassword` de `run` / *Initialization Code* tiene prioridad sobre `form.password`.
- Validaciones:
  - `name`: letras, números y `_` (hasta 40), sin parecer una celda de Excel (`A1`, `R1C1`).
  - Nombres únicos por documento.
  - Toda lista con `options` u `optionsFrom`.
  - En salida unida (`merge`), los nombres llevan sufijo `_1`, `_2`…
- Por formato:
  - **PDF**: campos AcroForm (Helvetica, solo Latin-1) con el tamaño del primer formulario. La protección no cifra el archivo.
  - **Excel**: celdas desbloqueadas con validación de lista, de largo y de casilla (☐/☒); hoja protegida, con contraseña opcional. Con `columns: 1` el valor no se combina a lo ancho.
  - **Word**: controles de contenido (texto, lista desplegable y casilla) y protección "solo formularios", con contraseña opcional. `maxLength` no aplica; `placeholder` solo se ve en Word.
- **APEX 23.2**: variante del plugin en `plugin/apex-23.2/`, con las mismas funciones. Se genera desde el export 26.1 con `plugin/to_apex232.py`: render de la API v1 (`javascript_function` + `attribute_NN`), sin `p_apexlang_name` ni `p_static_id`. Conserva los IDs, así que reemplaza el plugin existente y las acciones mantienen su configuración.

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
