# Referencia del diseño (JSON)

El diseño describe **qué** se dibuja; las [fuentes SQL](API.md#3-fuentes-sql) dicen **con qué datos**. Un mismo diseño produce PDF, Excel y Word.

- [Estructura general](#estructura-general)
- [Plantillas de texto `{...}`](#plantillas-de-texto-)
- [Formatos de valor](#formatos-de-valor)
- [Condiciones](#condiciones)
- [Marca de agua](#marca-de-agua)
- [Secciones](#secciones): [header](#header) · [tarjetas](#tarjetas) · [ficha](#ficha) · [tabla](#tabla) · [alerta](#alerta) · [texto](#texto) · [imagen](#imagen) · [grafico](#grafico) · [codigo](#codigo) · [formulario](#formulario) · [linea](#linea) · [columnas](#columnas) · [grupo](#grupo) · [espacio y salto](#espacio-y-salto)
- [Qué soporta cada formato](#qué-soporta-cada-formato)
- [Excel: hojas](#excel-hojas)
- [Lotes y resumen](#lotes-y-resumen)
- [Reutilizar partes: `defs`](#reutilizar-partes-defs)
- [Word desde plantilla](#word-desde-plantilla-docx-template)

Unidades: todas las medidas (`margin`, `width`, `height`, `x`, `y`, `gap`…) están en **milímetros**; los tamaños de letra (`size`) en **puntos**.

---

## Estructura general

```json
{
  "page": {
    "size": "letter",
    "orientation": "portrait",
    "margin": 8,
    "font": "helvetica",
    "theme": { "primary": "#1F4E79", "headText": "#FFFFFF", "zebra": "#F5F7FA",
               "totals": "#E6ECF2", "muted": "#787878", "fontSize": 7 }
  },
  "title": "Propiedad Título del PDF / Word",
  "fileName": "estado_{DOC.CLIENTE}",
  "emptyMessage": "No hay datos para este filtro.",
  "watermark": { "text": "BORRADOR", "when": "ESTADO != 'APROBADO'" },
  "pageHeader": { "image": { "url": "#APP_FILES#logo.png" }, "left": "Mi empresa", "right": "Página {DOCPAGE} de {DOCPAGES}" },
  "pdf": { "password": "{DOC.CEDULA}", "permissions": ["print"] },
  "append": [ { "source": "ANEXOS", "field": "ARCHIVO" } ],
  "sections": [ ],
  "footer": { "left": "Confidencial", "right": "Página {PAGE} de {PAGES}", "size": 7 },
  "defs": { },
  "xlsx": { "sheets": [ { "name": "Datos", "sections": ["enc", "detalle"] } ] },
  "batch": { "zipName": "lote_{TODAY}", "mergeName": "todo", "chunkSize": 5, "maxDocs": 3000,
             "summary": { "fileName": "00_resumen", "sections": [ ], "footer": { } } }
}
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `page.size` | `letter` | `letter`, `legal` o `a4` (en PDF también otros formatos de jsPDF, como `a3`). Solo PDF: tamaño propio en mm, `[ancho, alto]`; con `orientation: "landscape"` el lado mayor queda horizontal (p. ej. un cheque `[210, 99]`). Excel y Word usan carta. |
| `page.orientation` | `portrait` | `portrait` o `landscape`. |
| `page.margin` | `8` (PDF), `12.7` (Word) | Margen en mm. Excel ajusta la impresión a una página de ancho. |
| `page.font` | `helvetica` | Letra por defecto de `texto`: `helvetica`, `times` o `courier` (alias: `arial`, `serif`, `mono`). |
| `page.theme.primary` | `#1F4E79` | Fondo de `header` y encabezados de tabla. |
| `page.theme.headText` | `#FFFFFF` | Texto sobre `primary`. |
| `page.theme.zebra` | `#F5F7FA` | Filas alternas. |
| `page.theme.totals` | `#E6ECF2` | Fila de totales. |
| `page.theme.muted` | `#787878` | Texto del pie de página. |
| `page.theme.fontSize` | `7` | Tamaño base de tablas (PDF y Word). |
| `page.theme.group` | `#DCE6F0` | Fila de encabezado de grupo en tablas con `breakBy`. |
| `page.theme.link` | `#0563C1` | Color de los [hipervínculos](#hipervínculos). |
| `title` | — | Propiedad *Título* del PDF y del Word. Acepta plantillas. |
| `fileName` | `reporte` | Nombre de cada documento, sin extensión. Acepta plantillas (`{DOC.X}`, `{TODAY}`). |
| `emptyMessage` | `No hay datos para generar el reporte.` | Mensaje si `DOCS` no trae filas. |
| `watermark` | — | Texto en diagonal sobre cada página. Ver [Marca de agua](#marca-de-agua). |
| `pageHeader` | — | Encabezado de cada página (logo y textos). Ver [Encabezado de página](#encabezado-de-página). |
| `pdf` | — | Contraseña y permisos del PDF. Ver [PDF con contraseña](#pdf-con-contraseña). |
| `append` | — | PDFs que se anexan al final de cada documento. Ver [Anexar PDFs](#anexar-pdfs). |
| `sections` | — | Lista de [secciones](#secciones), en orden. |
| `footer.left` / `footer.right` | — | Pie de cada página. `{PAGE}` y `{PAGES}` (todo el archivo) y `{DOCPAGE}` y `{DOCPAGES}` (el documento, en un archivo unido) solo funcionan aquí y en `pageHeader`. |
| `footer.size` | `7` | Tamaño de letra del pie (PDF y Word). |
| `defs` | — | Bloques reutilizables. Ver [defs](#reutilizar-partes-defs). |
| `xlsx` | — | Hojas de Excel. Ver [Excel](#excel-hojas). |
| `batch` | — | Nombres y resumen del lote. Ver [Lotes](#lotes-y-resumen). |

Sin `footer`, el PDF y el Word no llevan pie. En Excel el pie usa `footer.left` y siempre muestra *Página X de Y* a la derecha.

## Plantillas de texto `{...}`

Cualquier texto (`title`, `label`, `value`, `text`, `fileName`…) puede incluir marcadores:

| Marcador | Valor |
|---|---|
| `{COL}` | Columna de la fila actual. Busca en: la fila de la sección (`source`), luego el documento (`DOCS`), luego los parámetros. |
| `{FUENTE.COL}` | Columna de la **primera fila** de otra fuente: `{EMPRESA.RUC}`. |
| `{DOC.COL}` | Fila del documento actual (fuente `DOCS`). |
| `{PARAM.X}` | Parámetro (`data-x` del elemento o `params` de la API). |
| `{ITEM.P1_X}` | Valor **actual en pantalla** de un ítem (`apex.item().getValue()`), no el de sesión. |
| `{NOW}` | Fecha y hora local del navegador: `19/10/2026 14:05`. |
| `{TODAY}` | Fecha: `19/10/2026`. |
| `{PAGE}` / `{PAGES}` | Página actual / total del archivo. Solo en `footer` y `pageHeader`. |
| `{DOCPAGE}` / `{DOCPAGES}` | Página / total del documento: en un archivo unido (`merge`) cada documento cuenta desde 1. Solo en `footer` y `pageHeader`. |
| `{COL\|formato}` | Valor con [formato](#formatos-de-valor): `{SALDO\|money}`. |

Un marcador sin valor se reemplaza por texto vacío.

## Formatos de valor

Se usan en `{COL|formato}` o en la propiedad `"fmt"` de columnas y campos.

| Formato | Entrada | Resultado | En Excel |
|---|---|---|---|
| `money` | `1234.5` | `1,234.50` | número con `#,##0.00` |
| `num:3` | `1.23456` | `1.235` | número con 3 decimales |
| `int` | `1234.6` | `1,235` | número con `#,##0` |
| `pct` / `pct:1` | `12.5` | `12.50%` / `12.5%` | número sin formato (`12.5`) |
| `date` | `09/12/1982` | `09/12/1982` | fecha real `dd/mm/yyyy` |
| `upper` / `lower` | `Ana` | `ANA` / `ana` | texto |
| `yn` | `Y`, `S` / `N` | `Sí` / `No` | texto |
| `letras` | `1234.5` | `MIL DOSCIENTOS TREINTA Y CUATRO CON 50/100` | texto |
| `letras:BALBOA/BALBOAS` | `1` / `21.07` | `UN BALBOA CON 00/100` / `VEINTIÚN BALBOAS CON 07/100` | texto |
| `mask:B/. #,##0.00` | `1234.5` | `B/. 1,234.50` | número con el mismo formato |
| `mask:$#,##0.00;($#,##0.00)` | `-1234.5` | `($1,234.50)` | número |
| `mask:#,##0.00;-#,##0.00;"-"` | `0` | `-` | número |
| `mask:#,##0.000 "USD"` | `12.3456` | `12.346 USD` | número |
| `mask:0.0%` | `0.125` | `12.5%` | número |
| `mask:#,##0.0,, "M"` | `1234567` | `1.2 M` | número |
| `mask:000000` | `42` | `000042` | número |
| `B/. #.##0,00` | `1234.5` | `B/. 1.234,50` | número |
| `ora:FML999G999G990D00;nls=,.;cur='B/. '` | `1234.5` | `B/. 1.234,50` | número |
| `ora:FM999G990D00PR` | `-1234.5` | `<1,234.50>` | número |
| `ora:FM999G990D00MI` | `-1234.5` | `1,234.50-` | número |

- Los números usan coma para miles y punto para decimales (en Excel, los separadores los pone la configuración regional del equipo).
- `pct` no multiplica por 100: espera el porcentaje ya calculado.
- `letras` redondea a 2 decimales. Con moneda, `singular/plural` (`letras:DÓLAR/DÓLARES`) o un solo nombre (`letras:BALBOAS`). Agrega `DE` tras millones (`UN MILLÓN DE BALBOAS`). Negativos: `MENOS …`. En Excel queda como texto.
- **`mask:`** (1.20) es una máscara estilo Excel, igual en PDF, Excel y Word. En Excel la celda sigue siendo número (los totales suman) y recibe el mismo formato.
  - Secciones separadas por `;`: `positivo;negativo;cero`. Con una sola sección, los negativos llevan `-` delante.
  - `0` dígito obligatorio, `#` opcional, `,` separador de miles, `.` decimales. Comas al final del número dividen entre 1000 (`#,##0,` → miles).
  - Texto libre antes o después (`B/. `, `USD`, `€`), o entre comillas si tiene dígitos o `#`: `"Nro. "000`. `\x` escapa un carácter.
  - `%` multiplica por 100 (como Excel); `pct` no.
  - `[Red]` y similares solo aplican en Excel.
  - El prefijo `mask:` es opcional: `B/. #,##0.00` también funciona (cualquier formato que no sea una palabra de la tabla y tenga `#` o `0`).
  - En plantillas: `{SALDO|mask:B/. #,##0.00}` o `{SALDO|B/. #,##0.00}`.
  - **Coma decimal** (1.21): escriba la máscara con punto de miles y coma decimal, `B/. #.##0,00` → `B/. 1.234,50`. Se reconoce cuando hay un punto antes de la última coma, o sin punto cuando tras la coma no hay exactamente 3 dígitos (`0,00`). `0,000` y `#,##0` siguen siendo miles, como en Excel; para 3 decimales con coma use `#.##0,000`.
- **`ora:`** (1.21) es el modelo de formato de `TO_CHAR` de Oracle; la consulta devuelve el número sin formatear.
  - Elementos: `9`, `0`, `G`, `D`, `,`, `.`, `L`, `U`, `C`, `$`, `PR` (`<1,234.50>`), `MI` (`1,234.50-`), `S` (`+`/`-`), `B` (cero en blanco) y `FM`.
  - Opciones separadas por `;`: `nls=,.` (decimal y miles, como `NLS_NUMERIC_CHARACTERS`), `cur='B/. '` (símbolo de `L`/`U`, por defecto `$`), `iso=PAB` (código de `C`, por defecto `USD`). Las comillas permiten espacios.
  - Nunca rellena con espacios a la izquierda; `FM` además quita los ceros finales de los `9` decimales, como en Oracle.
  - En plantillas: `{SALDO|ora:FML999G990D00;nls=,.;cur='B/. '}`.
- En Excel la celda sigue siendo número con el formato equivalente; los separadores de miles y decimales los pone la configuración regional del equipo (Excel no permite fijarlos en el formato).
- Una columna `NUMBER` sin `fmt` usa `money` si alguna fila tiene decimales; si todas son enteras, se muestra tal cual.
- Cualquier otro valor de `fmt` deja el valor sin cambios (en Excel, número con formato *General*).

## Condiciones

Las usan `filter`, `when`, `rowStyle` y `cellStyle`.

| Expresión | Verdadera si |
|---|---|
| `ESTADO == 'ACTIVO'` | igual (comparación como texto) |
| `ESTADO != 'X'` | distinto |
| `MONTO > 0`, `<`, `>=`, `<=` | comparación numérica |
| `ALERTA` | tiene valor: no es vacío, `null`, `0` ni `'N'` |
| `!ALERTA` | no tiene valor |
| `MONTO > LIMITE` | compara contra otra columna (si el lado derecho no es un literal) |
| `A == 'X' && B > 0` | ambas |
| `A == 'X' \|\| B == 'Y'` | cualquiera (`&&` tiene prioridad) |

Literales: `'texto'`, `"texto"`, números y `null`. `COL == ''` y `COL == null` son verdaderos si la columna está vacía. No hay paréntesis.

## Marca de agua

Texto semitransparente y rotado, centrado en cada página del documento (PDF y Word).

```json
"watermark": { "text": "BORRADOR", "when": "ESTADO != 'APROBADO'", "color": "#C00000", "opacity": 0.12, "angle": 45 }
"watermark": "COPIA"
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `text` | — | Texto. Acepta plantillas (`{DOC.ESTADO}`). Vacío: no hay marca. |
| `when` | — | [Condición](#condiciones) evaluada **por documento** (contra la fila de `DOCS` y los parámetros). En un lote o en salida unida, cada documento decide. Ej.: `"!PARAM.FINAL"`. |
| `color` | `#C00000` | Color del texto. |
| `opacity` | `0.12` | De `0` (invisible) a `1`. |
| `angle` | `45` | Grados, en sentido contrario a las agujas del reloj. `0` = horizontal. |
| `size` | automático | Tamaño en pt. Sin `size`, el texto ocupa ~60 % de la diagonal de la página (80 % del ancho si `angle` es `0`). |

- **PDF:** se dibuja encima del contenido con la opacidad indicada.
- **Word:** imagen flotante detrás del texto, en el encabezado de la sección (se genera con `<canvas>` en el navegador).
- **Excel:** no aplica.

## Secciones

Propiedades comunes a todas:

| Propiedad | Descripción |
|---|---|
| `type` | Tipo de sección. |
| `id` | Nombre para usarla en `xlsx.sheets`. |
| `formats` | Limita los formatos donde aparece: `["pdf", "docx"]`. |
| `when` | La sección solo aparece si se cumple la [condición](#condiciones), evaluada **por documento** (fila de `DOCS`, parámetros y `{FUENTE.COL}`). Ej.: `"PARAM.DETALLE == 'S'"`. En `alerta`, `when` conserva su significado (por fila). |
| `source` | Fuente de datos (en mayúsculas o minúsculas). |

### `header`

Banda de color con título.

```json
{ "type": "header", "title": "Estado de cuenta - {DOC.CLIENTE}", "subtitle": "Corte al {TODAY}",
  "right": "Generado: {NOW}", "size": 14 }
{ "type": "header", "title": "Estado de cuenta", "subtitle": "{DOC.CLIENTE}", "right": "Corte al {DOC.FECHA}",
  "size": 24, "subtitleSize": 12, "rightSize": 11, "font": "times", "fill": "#14403F", "color": "#F5F0E1" }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `title` | — | Título (70 % del ancho en PDF). |
| `subtitle` | — | Segunda línea. |
| `right` | — | Texto a la derecha. En Excel se une al subtítulo con ` \| `. |
| `size` | `14` | Tamaño del título en pt. |
| `subtitleSize` | `9` | Tamaño del subtítulo en pt. En Excel, el de la segunda fila (subtítulo y texto derecho van juntos). |
| `rightSize` | `9` | Tamaño del texto de la derecha en pt. |
| `font` | `helvetica` | `helvetica`, `times` o `courier` (alias `arial`, `serif`, `mono`). Sin `font`, Word usa Calibri y Excel la letra por defecto. |
| `fill` | `theme.primary` | Fondo de la banda. |
| `color` | `theme.headText` | Color del texto. |
| `height` | automático | Alto mínimo de la banda en mm (PDF). La banda crece sola con títulos grandes. |

En PDF la banda siempre va en la parte superior de la página.

### `tarjetas`

Fila de tarjetas con una **etiqueta pequeña** y un **valor destacado**, fondo suave y barra de acento a la izquierda. Sirve para el resumen al inicio de un documento (número, fecha, estado…). Los valores se toman de la primera fila de `source` (o del documento).

```json
{ "type": "tarjetas", "source": "DOCS", "accent": "#4A90C2", "fields": [
  { "label": "COVER NO.", "value": "{COVER_NO}" },
  { "label": "DATE",      "value": "{FECHA}", "fmt": "date" },
  { "label": "STATUS",    "value": "{STATUS}", "color": { "by": "STATUS", "values": { "Rejected": "#AA1E1E" } } } ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `fields` | — | Tarjetas, en orden (también se acepta `items`). Mismas propiedades que los campos de [`ficha`](#ficha) (`label`, `value`, `fmt`, `map`, `when`) y además `color`: color del valor, fijo o según una columna (`{ "by", "values", "default" }`, como en [`alerta`](#alerta)). |
| `columns` | todas (máx. 6) | Tarjetas por fila. Si hay más, continúan en filas nuevas. |
| `fill` | `#F1F4F2` | Fondo. |
| `accent` | `theme.primary` | Barra de acento a la izquierda. `""`: sin barra. |
| `labelColor` | `#787878` | Color de la etiqueta. |
| `valueColor` | `theme.primary` | Color del valor. |
| `labelSize` / `size` | `7` / `11` | Tamaño de la etiqueta y del valor (pt). |
| `height` | automático | Alto mínimo en mm (PDF). Un valor largo se parte en varias líneas y la fila crece. |
| `cardGap` | `3` | Separación entre tarjetas en mm. |
| `gap` | `3` | Espacio después en mm (PDF). |

- **PDF:** rectángulos con la barra de acento; la fila no se parte entre páginas.
- **Word:** tabla de ancho fijo; cada tarjeta es una celda con fondo y borde izquierdo grueso; columnas vacías entre tarjetas.
- **Excel:** una columna por tarjeta; etiqueta en una fila y valor en la siguiente, con fondo y borde izquierdo grueso.
- Admitida dentro de [`columnas`](#columnas).

### `ficha`

Pares **etiqueta / valor** en N columnas, tomados de la primera fila de `source` (o del documento si no hay `source`).

```json
{ "type": "ficha", "source": "DOCS", "columns": 3, "labelWidth": 32, "size": 8.5, "fields": [
  { "label": "Cliente",  "value": "{CLIENTE}" },
  { "label": "Saldo",    "value": "{SALDO|money}" },
  { "label": "Tasa",     "value": "{TASA}% anual" },
  { "label": "Estado",   "value": "{ESTADO}", "map": { "A": "Activo", "I": "Inactivo" } },
  { "label": "Balón",    "value": "{MONTO_BALON}", "fmt": "money", "when": "MONTO_BALON > 0" },
  { "label": "Desembolso", "value": "{FECHA_DESEMBOLSO}", "fmt": "date" } ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `columns` | `3` | Pares por fila. |
| `labelWidth` | `32` | Ancho de la etiqueta en mm (PDF; en Word con `grid` o `labelWidths`). |
| `labelWidths` | — | Ancho de cada etiqueta de la fila, en mm: `[40, 45]`. Las que falten usan `labelWidth`. |
| `size` | `8.5` | Tamaño de letra (PDF). |
| `grid` | `false` | Cuadrícula: bordes finos en todas las celdas, más espacio interior y texto centrado en vertical. PDF, Excel y Word. |
| `borderColor` | `#D5DCE3` | Color de los bordes con `grid`. |
| `labelFill` | — | Fondo de las celdas de etiqueta. |
| `labelColor` / `valueColor` | — | Color del texto de etiquetas / valores. |
| `fields[].label` | — | Etiqueta (acepta plantillas). |
| `fields[].value` | — | Valor (plantilla). |
| `fields[].fmt` | — | Formato si `value` es un solo marcador (`"{SALDO}"`). En Excel deja el número o la fecha como valor real. |
| `fields[].map` | — | Traduce el valor: `{ "A": "Activo" }`. |
| `fields[].when` | — | El campo solo aparece si se cumple la [condición](#condiciones). |
| `fields[].align` | — | Alineación del valor: `left`, `center`, `right`. |
| `fields[].bold` | `false` | Valor en negrita. |
| `fields[].color` | `valueColor` | Color del valor, fijo (`"#1B7A3D"`) o según una columna: `{ "by", "values", "default" }`, como en [`alerta`](#alerta). |
| `fields[].fill` | — | Fondo de la celda del valor. |
| `fields[].href` | — | [Hipervínculo](#hipervínculos) del valor (plantilla): `"https://sitio/cliente/{ID}"`, `"mailto:{CORREO}"`. |

```json
{ "label": "Saldo",  "value": "{SALDO}", "fmt": "money", "align": "right", "bold": true, "color": "#1B7A3D" }
{ "label": "Estado", "value": "{ESTADO}", "align": "center", "fill": "#FDECEC",
  "color": { "by": "ESTADO", "values": { "M": "#A61B1B" }, "default": "#000000" } }
```

**Huecos y campos anchos** (`ficha` y `formulario`). Los campos se acomodan en orden, `columns` por fila. Dos propiedades cambian ese orden:

| Propiedad | Descripción |
|---|---|
| `{ "empty": true }` | Hueco: ocupa una casilla (etiqueta + valor) sin dibujar nada. Admite `span` y `when`. |
| `span` | Casillas que ocupa el campo (o el hueco): `2`, `3`… hasta `columns`, o `"row"` para el resto de la fila. El valor se extiende a lo ancho; la etiqueta queda a la izquierda. |

Un campo que no cabe en lo que queda de la fila empieza una fila nueva. Con huecos o `span`, en PDF las columnas de valor toman el mismo ancho para que la grilla quede pareja.

```json
"columns": 3, "fields": [
  { "label": "Cliente", "value": "{CLIENTE}" }, { "label": "Cuenta", "value": "{CUENTA}" }, { "empty": true },
  { "label": "Dirección", "value": "{DIRECCION}", "span": 2 }, { "label": "Tipo", "value": "{TIPO}" },
  { "label": "Observaciones", "value": "{OBS}", "span": "row" } ]
```

- **PDF:** celdas combinadas; los huecos van sin bordes ni fondo.
- **Excel:** el valor se combina a lo ancho; el hueco deja las celdas vacías.
- **Word:** celdas combinadas (`gridSpan`); en cuadrícula, el hueco va sin bordes.

**Posición y estilo de la etiqueta** (`ficha` y `formulario`, 1.16). Se definen en la sección y cada campo los puede cambiar.

| Propiedad | Valores | Descripción |
|---|---|---|
| `labelPosition` | `left` (defecto), `top`, `none` | `top`: la etiqueta va sobre el valor, en la misma casilla. `none`: sin etiqueta; el valor ocupa la casilla completa. |
| `labelSize` | pt | Tamaño de la etiqueta. Sin valor: el de la sección a la izquierda; arriba, un 15 % menor. |
| `labelColor` | `#RRGGBB` | Color de la etiqueta. |
| `labelFill` | `#RRGGBB` | Fondo de la etiqueta (arriba: una franja sobre el valor). |
| `labelBold` | `true` (defecto) / `false` | Etiqueta en negrita. |
| `labelCase` | `upper`, `none` | Etiqueta en mayúsculas. `none` en un campo anula el `upper` de la sección. |
| `labelAlign` | `left`, `center`, `right` | Alineación de la etiqueta. Arriba, sin valor sigue la alineación del valor (`align`). |

```json
{ "type": "ficha", "columns": 3, "grid": true, "labelPosition": "top", "labelCase": "upper", "labelColor": "#5A6B7B",
  "fields": [
    { "label": "Cliente", "value": "{CLIENTE}", "span": 2 },
    { "label": "Saldo",   "value": "{SALDO}", "fmt": "money", "align": "right" },
    { "label": "Cuenta",  "value": "{CUENTA}", "labelPosition": "left", "labelCase": "none" },
    { "label": "Firma",   "value": "{FIRMA}",  "labelPosition": "none" } ] }
```

Se combina con `span` y huecos. En una misma fila pueden convivir campos con la etiqueta a la izquierda, arriba y sin etiqueta.

- **PDF:** la casilla es una sola celda; la etiqueta se dibuja arriba y el valor (o el campo editable) debajo.
- **Excel:** una fila con etiquetas arriba ocupa dos filas reales: la de etiquetas y la de valores. Los campos de esa fila con la etiqueta a la izquierda combinan las dos filas. En `formulario`, el nombre definido apunta a la celda del valor.
- **Word:** una celda con dos párrafos; en `formulario`, el control de contenido va en una caja bajo la etiqueta.

### `tabla`

```json
{ "type": "tabla", "source": "PLAN", "title": "Plan de pagos - {DOC.NRO}",
  "filter": "ESCENARIO == 'ACTUAL'",
  "columns": [
    { "col": "NRO", "label": "#", "align": "center", "width": 10 },
    { "col": "FECHA", "label": "Fecha", "fmt": "date" },
    { "col": "CAPITAL", "label": "Capital", "fmt": "money",
      "cellStyle": [ { "when": "CAPITAL < 0", "color": "#AA1E1E", "bold": true } ] },
    { "col": "TIPO", "label": "Tipo", "map": { "N": "Normal", "B": "Balón" } },
    { "label": "Periodo", "value": "{NRO} de {DOC.PAGOS}" } ],
  "totals": ["CAPITAL"], "totalsLabel": "Totales",
  "rowStyle": [ { "when": "TIPO == 'B'", "fill": "#FFD699", "bold": true } ],
  "emptyText": "Sin pagos", "hideEmpty": true, "repeatHeader": true, "zebra": true, "size": 7, "gap": 3 }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `title` | — | Fila de título sobre el encabezado. |
| `filter` | — | Solo las filas que cumplen la [condición](#condiciones). |
| `columns` | todas | Columnas. Sin `columns` se usan todas las de la consulta (excepto `DOC_KEY`), con el alias como etiqueta (`FECHA_PAGO` → `Fecha pago`). Un elemento puede ser solo el nombre: `"ENAME"`. |
| `totals` | — | Columnas con total: `"COL"` (suma) u `{ "col": "COL", "fn": "sum\|avg\|min\|max\|count" }`. `min`/`max` admiten números, fechas y texto; `count` cuenta valores no vacíos. Con funciones distintas a la suma cada valor lleva un prefijo (Prom., Mín., Máx., Cant.). En Excel: `SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNTA` (con quiebres, `SUBTOTAL`). |
| `totalsLabel` | `Totales` | Texto de la fila de totales. Ocupa una celda combinada hasta la primera columna con total; si esa es la primera, va en su propia fila. Admite `{COUNT}`. |
| `rowStyle` | — | Reglas por fila: `when`, `fill`, `color`, `bold`. Se aplica la primera que se cumple. |
| `groups` | — | Encabezado agrupado. Ver abajo. |
| `emptyText` | — | Si no hay filas, muestra la tabla con este texto. |
| `hideEmpty` | `true` | Sin filas y sin `emptyText`, la tabla no se dibuja. `false` dibuja solo el encabezado. |
| `repeatHeader` | `true` | Repite el encabezado en cada página (PDF). |
| `zebra` | `true` | Filas alternas (Excel y Word; el PDF siempre las alterna). |
| `size` | `theme.fontSize` | Tamaño de letra (PDF). |
| `gap` | `3` | Espacio después de la tabla en mm (PDF). |
| `headAlign` | `center` | Alineación del encabezado: `left`, `center`, `right` o `auto` (la de los datos de cada columna). Cada columna puede cambiarla con su propio `headAlign`. |
| `grid` | — | `true`: bordes finos en PDF, Excel y Word. `false`: sin bordes también en Word. Sin definir: como antes (solo Word lleva bordes). |
| `borderColor` | `#D5DCE3` | Color de los bordes con `grid: true`. |
| `totalsColor` | — | Color del texto de la fila de totales y subtotales. |
| `breakBy` | — | Quiebre de control: agrupa filas **consecutivas** con el mismo valor de esta columna. Una lista (`["REGION", "SUCURSAL"]`) arma quiebres anidados. Ver abajo. |
| `breakTitle` | `{COL}` | Fila de encabezado de cada grupo. Acepta `{COL}` (primera fila del grupo) y `{COUNT}`. `false`: sin encabezado. Con varios niveles, una lista por nivel. |
| `breakLabel` | `Subtotal {COL}` | Texto de la fila de subtotal. Acepta `{COL}` y `{COUNT}`. Con varios niveles, una lista por nivel; `false` en un nivel omite su subtotal. |
| `breakPage` | `false` | Cada grupo del primer nivel empieza en una página nueva (PDF y Word; en Excel, salto de página de impresión). |
| `carry` | — | PDF: renglón **Van** al pie de cada página y **Vienen** al inicio de la siguiente, con el acumulado de las columnas. `true` (columnas de `totals`), `["COL"]` o `{ "cols": ["COL"], "label": "Van", "labelFrom": "Vienen" }`. Solo suma. |
| `breakTotals` | = `totals` | Columnas a subtotalizar (mismo formato que `totals`). `false`: sin fila de subtotal. |

**Columnas:**

| Propiedad | Descripción |
|---|---|
| `col` | Columna de la fuente (alias). |
| `label` | Encabezado. |
| `headAlign` | Alineación del encabezado de esta columna (`left`, `center`, `right`, `auto`). Tiene prioridad sobre el `headAlign` de la tabla. |
| `fmt` | [Formato](#formatos-de-valor). |
| `align` | `left`, `center`, `right`. Por defecto: números a la derecha, fechas al centro, texto a la izquierda. |
| `bold` | Negrita. |
| `color` | Color fijo del texto. |
| `width` | PDF: ancho en mm. Word: peso relativo. Excel calcula el ancho por contenido. |
| `map` | Traducción de valores: `{ "Y": "Sí" }`. |
| `value` | Columna calculada con plantilla: `"{NOMBRE} ({CODIGO})"`. Se exporta como texto. |
| `cellStyle` | Reglas para la celda: `when`, `fill`, `color`, `bold`. Tiene prioridad sobre `rowStyle`. |
| `when` | La columna solo aparece si se cumple la [condición](#condiciones), evaluada por documento (no por fila). Si oculta columnas, revise `groups`. |
| `valign` | Alineación vertical de las celdas de esta columna (`top`, `middle`, `bottom`). Tiene prioridad sobre el `valign` de la tabla. |
| `cell` | Contenido de la celda por fila: código QR o de barras, imagen, gráfico o texto. Ver [bloques en celdas](#bloques-en-celdas). |
| `href` | [Hipervínculo](#hipervínculos) de la celda, por fila: `"https://sitio/ver?id={ID}"`. También sirve dentro de `cell` (imagen o código). En Excel la celda pasa a texto con el formato de la columna. |

#### Bloques en celdas

```json
"columns": [
  { "col": "EMPNO", "label": "QR", "cell": { "type": "codigo", "kind": "qr", "value": "EMP-{EMPNO}", "size": 12 } },
  { "label": "Empleado", "cell": { "type": "texto", "text": "{ENAME} ({JOB})" } },
  { "label": "Foto", "cell": { "type": "imagen", "field": "FOTO", "height": 10 } },
  { "label": "Barras", "cell": { "type": "codigo", "kind": "code128", "value": "{EMPNO}", "width": 25, "height": 6 } },
  { "label": "Ventas", "cell": { "type": "grafico", "chart": "line", "source": "VENTAS",
                                 "link": { "EMPNO": "EMPNO" }, "category": "MES", "series": ["MONTO"] } } ]
```

| `cell.type` | Propiedades | Notas |
|---|---|---|
| `codigo` | `kind` (`qr`, `code128`), `value` (plantilla con columnas de la fila), `size` (QR, defecto 14 mm), `width` / `height` (barras, 30 × 8 mm), `ecc`, `color` | El texto bajo las barras no se dibuja dentro de la celda. |
| `imagen` | `field` (columna BLOB de la fila) o `url` (igual para todas), `width` (defecto 15 mm) / `height` | PNG o JPG. Una imagen inválida deja la celda vacía. |
| `grafico` | Las de [`grafico`](#grafico) + `link` y `filter`; `width` / `height` (defecto 40 × 15 mm) | `link: { "COL_FUENTE": "COL_FILA" }` toma solo las filas de la fuente que coinciden con la fila de la tabla. `filter` admite `{COL}` de la fila: `"EMPNO == {EMPNO}"`. Un gráfico por fila: úselo con pocas filas. |
| `texto` | `text` (plantilla) | Igual que `value`; se exporta como texto. |

Con celdas de imagen o código, las filas se centran en vertical; `valign` en la tabla (`top`, `middle`, `bottom`) lo cambia para todas las tablas. La columna toma el ancho del contenido (PDF: el mayor entre `width` y la imagen; Word: peso según el ancho; Excel: ancho y alto de fila ajustados). La alineación por defecto es centrada; `align` la cambia. Excel coloca la imagen sobre la celda (la celda queda vacía).

**Encabezado agrupado:**

```json
"groups": [ { "cols": 2 }, { "label": "Devengado", "cols": 2 }, { "label": "Aplicado", "cols": 3 } ]
```

Los grupos se aplican en orden, de izquierda a derecha. Un grupo sin `label` deja esas columnas con su etiqueta ocupando las dos filas del encabezado (en Word, la celda del grupo queda vacía). Las columnas que sobran quedan sin grupo.

**Excel:** números y fechas como valores reales, encabezado inmovilizado y autofiltro cuando la hoja tiene una sola tabla.

**Quiebres y subtotales:**

```json
{ "type": "tabla", "source": "EMP",
  "columns": [ "ENAME", "JOB", { "col": "SAL", "fmt": "money" }, { "col": "COMM", "fmt": "money" } ],
  "breakBy": "DNAME", "breakTitle": "Departamento: {DNAME} ({COUNT})", "breakLabel": "Subtotal {DNAME}",
  "totals": ["SAL", "COMM"], "totalsLabel": "Total general" }
```

Como en Oracle Reports, el grupo cambia cuando cambia el valor: **ordene la consulta por la columna de quiebre** (`ORDER BY dname, …`). La columna de quiebre no necesita estar en `columns`. Cada grupo lleva una fila de encabezado (`breakTitle`), sus filas y una fila de subtotal (`breakLabel`) con la suma de `breakTotals` (o de `totals`). El total general sigue saliendo en `totals`.

En Excel los subtotales son `=SUBTOTAL(9; …)` y el total general también, para no sumar dos veces; con `breakBy` la hoja no lleva autofiltro. En PDF las filas alternas se cuentan solo sobre filas de datos.

**Quiebres anidados (1.23):**

```json
{ "type": "tabla", "source": "MOVS", "columns": ["FECHA", "CONCEPTO", { "col": "MONTO", "fmt": "money" }],
  "breakBy": ["SUCURSAL", "TIPO"],
  "breakTitle": ["Sucursal: {SUCURSAL}", "{TIPO} ({COUNT})"],
  "breakLabel": ["Total {SUCURSAL}", "Total {TIPO}"],
  "totals": ["MONTO"], "breakPage": true, "carry": true }
```

Ordene la consulta por todas las columnas de quiebre, en el mismo orden (`ORDER BY sucursal, tipo, …`). Un cambio en un nivel cierra también los niveles internos. Los encabezados de niveles internos usan un tono más claro de `theme.group`. En Excel cada subtotal es `SUBTOTAL()` sobre su grupo: los subtotales internos no se suman dos veces.

**Van / vienen:** solo PDF. El renglón **Van** queda debajo de la última fila de la página y **Vienen** encima del encabezado de la tabla en la página siguiente, con la suma de las filas de datos ya impresas. Las filas no se parten entre páginas. Word y Excel paginan por su cuenta y no lo muestran.

### `pivot`

Tabla cruzada (matriz): una fila por cada combinación de `rows` y una columna por cada valor de `cols`, con el agregado de `value`. Se dibuja como una [`tabla`](#tabla), así que admite sus propiedades (`title`, `grid`, `breakBy`, `rowStyle`, `size`…).

```json
{ "type": "pivot", "title": "Ventas por sucursal y mes", "source": "VENTAS",
  "rows": ["REGION", "SUCURSAL"], "rowLabels": ["Región", "Sucursal"],
  "cols": "PERIODO", "sortCols": true, "value": "MONTO", "fn": "sum", "fmt": "money" }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `rows` | — | Columna o lista de columnas que forman cada fila. |
| `rowLabels` | nombre de la columna | Encabezado de las columnas de `rows`. |
| `cols` | — | Columna cuyos valores pasan a ser columnas. |
| `value` | — | Columna a agregar. |
| `fn` | `sum` | `sum`, `avg`, `min`, `max` o `count` (`count` sin `value` cuenta filas). |
| `fmt` | según `fn` | [Formato](#formatos-de-valor) de las celdas y totales. |
| `colLabel` | `{COLS}` | Encabezado de cada columna; plantilla con la primera fila de ese valor: `"Mes {NMES}"`. |
| `colOrder` | orden de aparición | Lista con el orden de las columnas; los valores que falten van al final. |
| `sortCols` | `false` | Ordena las columnas de menor a mayor (números o texto). |
| `maxCols` | — | Máximo de columnas. |
| `rowTotals` | `true` | Columna de total por fila (si hay más de una columna). |
| `colTotals` | `true` | Fila de totales por columna (usa `fn`; con `count`, suma los conteos). |
| `totalLabel` | `Total` | Texto de la columna y de la fila de totales. |
| `empty` | vacío | Valor de las celdas sin datos (p. ej. `0`). |

Sin `colOrder` ni `sortCols`, las columnas salen en el orden de la consulta. En Excel las celdas son números y los totales, fórmulas. Con `fn: "avg"`, el total de cada columna es el promedio de las filas, no de los datos originales.

### `alerta`

Franja de color con texto, solo si se cumple `when`.

```json
{ "type": "alerta", "source": "ESC", "when": "ALERTA", "each": true, "text": "{ESCENARIO}: {ALERTA}",
  "color": { "by": "ESTADO", "values": { "OK": "#D4EDDA", "VENCIDO": "#F8D7DA" }, "default": "#E6ECF2" },
  "size": 8 }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `when` | siempre | Condición evaluada por fila de `source`. |
| `each` | `false` | `true`: una franja por cada fila que cumpla. `false`: solo la primera. |
| `text` | — | Texto (plantilla con la fila). |
| `color` | `#E6ECF2` | Color fijo (`"#FFF4CE"`) o según una columna: `{ "by", "values", "default" }`. |
| `size` | `8` | Tamaño de letra (PDF). |

### `texto`

Uno o varios párrafos con texto enriquecido.

```json
{ "type": "texto", "source": "DOCS", "align": "justify", "size": 10, "lineHeight": 1.35,
  "paragraphGap": 2, "indent": 0, "color": "#000000", "font": "times", "bold": false, "italic": false,
  "text": [ "Estimado(a) **{NOMBRE}**:", "Su saldo al {TODAY} es [c=#AA1E1E]**{SALDO|money}**[/c]." ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `text` | — | Texto o arreglo de párrafos. En un texto, `\n` separa párrafos. |
| `align` | `left` | `left`, `center`, `right`, `justify`. |
| `size` | `10` | Tamaño de letra. |
| `lineHeight` | `1.35` (PDF), `1.15` (Word) | Interlineado. |
| `paragraphGap` | media línea | Espacio entre párrafos en mm. |
| `indent` | `0` | Sangría izquierda en mm. |
| `color`, `font`, `bold`, `italic` | — | Estilo base del párrafo. |
| `x`, `y`, `width` | — | **Posición fija** (solo PDF, en la página actual). Con `y` no mueve el flujo del resto del documento. |

**Marcas de texto enriquecido:**

| Marca | Resultado |
|---|---|
| `**texto**` | negrita |
| `*texto*` | cursiva |
| `***texto***` | negrita y cursiva |
| `~~texto~~` | tachado |
| `++texto++` | subrayado |
| `[f=times]…[/f]` | tipo de letra: `helvetica`, `times`, `courier` |
| `[c=#AA1E1E]…[/c]` | color |
| `[a=https://…]…[/a]` | [hipervínculo](#hipervínculos); la URL admite plantillas: `[a=mailto:{CORREO}]{CORREO}[/a]` |
| `\*` | asterisco literal (en JSON: `"\\*"`) |

Las marcas se pueden anidar: `[c=#19783C]***{SAL|money}***[/c]`, `[a={WEB}]**sitio**[/a]`.

### `imagen`

PNG o JPG desde una URL o desde una columna BLOB.

```json
{ "type": "imagen", "url": "#APP_FILES#logo.png", "width": 40, "align": "left", "gap": 3 }
{ "type": "imagen", "source": "DOCS", "field": "FOTO", "width": 35 }
{ "type": "imagen", "url": "#APP_FILES#logo.png", "width": 30, "x": 14, "y": 277 }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `url` | — | `#APP_FILES#`, `#WORKSPACE_FILES#` e `#IMAGE_PREFIX#` se resuelven con `apex.env`. Se descarga una vez y se reutiliza. |
| `field` | — | Columna BLOB (o texto base64 / *data URL*) de `source`, o del documento si no hay `source`. |
| `width` / `height` | `40` de ancho | Con uno solo se respeta la proporción. |
| `align` | `left` | `left`, `center`, `right` (PDF y Word). |
| `gap` | `3` | Espacio después, en mm. |
| `x`, `y` | — | Posición fija (solo PDF). |
| `href` | — | [Hipervínculo](#hipervínculos) de la imagen (plantilla). |

Si la columna viene vacía, la imagen se omite. En Excel la imagen se ancla en la columna A de la fila actual.

### `grafico`

Gráfico de barras, líneas, área, circular o anillo a partir de una fuente. Se dibuja con [Chart.js](https://www.chartjs.org) en un `<canvas>` y se inserta como imagen PNG (alta resolución) en PDF, Excel y Word.

```json
{ "type": "grafico", "chart": "bar", "source": "VENTAS", "category": "MES",
  "series": [ { "col": "TOTAL", "label": "Ventas", "color": "#1F4E79" }, "META" ],
  "title": "Ventas por mes", "values": true, "fmt": "int", "width": 120, "height": 70, "align": "center" }
{ "type": "grafico", "chart": "doughnut", "source": "DEPTOS", "category": "DNAME", "series": ["EMPLEADOS"], "values": "pct" }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `chart` | `bar` | `bar`, `hbar` (barras horizontales), `line`, `area`, `pie`, `doughnut`. |
| `source` | — | Fuente: una fila por categoría (por documento si la fuente trae `DOC_KEY`). |
| `category` | primera columna no numérica | Etiquetas del eje o de las porciones. |
| `series` | todas las numéricas | Columnas a graficar: `"TOTAL"` o `{ "col", "label", "color" }`. `pie` / `doughnut` usan solo la primera. |
| `title` | — | Título (acepta plantillas). |
| `values` | — | `true`: escribe el valor sobre cada barra / punto / porción. `"pct"`: porcentaje del total. |
| `fmt` | `int` o `num:2` | [Formato](#formatos-de-valor) de valores y del eje. |
| `legend` | automático | Se muestra si hay más de una serie o si es `pie` / `doughnut`. `true` / `false` para forzar. |
| `legendPosition` | `bottom` (`right` en circulares) | `top`, `bottom`, `left`, `right`. |
| `stacked` | `false` | Barras / áreas apiladas. |
| `smooth` | `false` | Líneas curvas. |
| `beginAtZero` | `true` | El eje de valores empieza en 0. |
| `colors` | tema + paleta | Colores por serie (o por porción en circulares). |
| `size` | `8` | Tamaño de letra en pt. |
| `width` / `height` | `120` / `70` | Tamaño en mm. |
| `align`, `gap`, `x`, `y` | | Igual que [`imagen`](#imagen). |

Sin filas, el gráfico se omite. Requiere navegador (usa `<canvas>`); en Node se puede probar con el paquete `canvas` (ver `test/run.js`).

### `codigo`

Código QR o código de barras **Code 128** con el valor de una plantilla.

```json
{ "type": "codigo", "kind": "qr", "value": "https://dgi-fep.mef.gob.pa/Consultas/FacturasPorCUFE?CUFE={DOC.CUFE}", "size": 30, "align": "right" }
{ "type": "codigo", "kind": "code128", "value": "{DOC.NRO_DOC}", "width": 60, "height": 12 }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `kind` | `qr` | `qr` o `code128`. |
| `value` | — | Texto a codificar (plantilla). Vacío: no se dibuja. QR admite UTF-8; Code 128 solo ASCII imprimible (otros caracteres se cambian por `?`). |
| `source` | — | Toma `{COL}` de la primera fila de esta fuente; sin `source`, del documento. |
| `size` | `30` | QR: lado en mm. |
| `ecc` | `M` | QR: corrección de errores `L`, `M`, `Q`, `H`. |
| `width` / `height` | automático / `12` | Code 128: ancho y alto de las barras en mm. |
| `showText` | `true` | Code 128: texto legible debajo de las barras. |
| `textSize` | `8` | Tamaño de ese texto. |
| `color` | `#000000` | Color de los módulos. |
| `align`, `gap`, `x`, `y` | | Igual que [`imagen`](#imagen). |

En PDF el código es vectorial (nítido a cualquier zoom). En Word y Excel va como PNG con una zona blanca alrededor. Code 128 elige solo entre los juegos B y C (los números en pares ocupan la mitad).

### `formulario`

Campos **editables** (texto, texto de varias líneas, lista y casilla de verificación) que el destinatario llena en el PDF, el Word o el Excel. Se dibujan como pares etiqueta / campo, igual que una [`ficha`](#ficha).

```json
{ "form": { "protect": true, "password": "clave" },
  "sections": [
    { "type": "formulario", "source": "DOCS", "columns": 2, "fields": [
      { "label": "Nombre",   "name": "NOMBRE", "value": "{CLIENTE}", "maxLength": 60 },
      { "label": "Sucursal", "name": "SUCURSAL", "input": "list", "options": ["Casa Matriz", "Chorrera"], "optionsFrom": "SUCURSALES.NOMBRE" },
      { "label": "Notas",    "name": "NOTAS", "input": "multiline", "lines": 4, "placeholder": "Escriba aquí" },
      { "label": "Acepta",   "name": "ACEPTA", "input": "checkbox", "value": "{ACEPTA}" },
      { "label": "Código",   "name": "CODIGO", "value": "{CODIGO}", "readOnly": true } ] } ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `columns` | `2` | Pares por fila. |
| `labelWidth` | `32` | Ancho de la etiqueta en mm. |
| `size` | `8.5` | Tamaño de letra. En PDF todos los campos usan el tamaño del primer formulario (Helvetica). |
| `fields[].name` | — | **Obligatorio.** Letras, números y `_` (hasta 40); no puede parecer una celda de Excel (`A1`, `R1C1`) y no se puede repetir en el documento. Con varios documentos en un solo archivo se agrega `_1`, `_2`… |
| `fields[].input` | `text` | `text`, `multiline`, `list` o `checkbox`. |
| `fields[].label` / `value` / `fmt` / `map` / `when` | — | Como en [`ficha`](#ficha). `value` es el valor inicial. En `checkbox` marca la casilla con `S`, `Sí`, `Y`, `1`, `X`, `true` u `on`. |
| `fields[].options` | — | `list`: opciones fijas. |
| `fields[].optionsFrom` | — | `list`: opciones desde una fuente, `FUENTE.COLUMNA` (sin columna, la primera). Se agregan a las fijas. Si el valor inicial no está entre las opciones, queda vacío. |
| `fields[].maxLength` | — | `text` / `multiline`: largo máximo (recorta el valor inicial). No aplica en Word. |
| `fields[].lines` | `3` | `multiline`: líneas visibles (2 a 20). |
| `fields[].placeholder` | — | Texto de ayuda (solo Word). |
| `fields[].readOnly` | `false` | Campo de solo lectura. |
| `fields[].span` | `1` | Casillas que ocupa (`2`, `3`… o `"row"`). Ver [huecos y campos anchos](#ficha). |
| `{ "empty": true }` | — | Hueco en la grilla. Ver [huecos y campos anchos](#ficha). |
| `{ "block": { … } }` | — | Bloque entre los campos (1.18): `tabla`, `ficha`, `tarjetas`, `texto`, `imagen`, `codigo`, `alerta`, `linea`, `grafico` o `espacio`. Ocupa una fila completa. Ver abajo. |
| `labelPosition`, `labelSize`, `labelColor`, `labelFill`, `labelBold`, `labelCase`, `labelAlign` | — | En la sección y en cada campo. Ver [posición y estilo de la etiqueta](#ficha). |
| `form.protect` | `true` | Protege el documento para que solo se editen los campos (Word: *solo formularios*; Excel: hoja protegida con las celdas de los campos desbloqueadas). |
| `form.password` | — | Contraseña de la protección (Word y Excel). `run({ formPassword })` tiene prioridad. En Word: 1 a 15 caracteres ASCII. |

- **PDF:** campos AcroForm (`NeedAppearances`). La protección del PDF no se cifra.
- **Word:** controles de contenido (texto, lista desplegable, casilla).
- **Excel:** celdas con nombre definido, validación de datos (lista, largo máximo) y casilla `☐` / `☒`. Las listas largas van a una hoja oculta `nr_listas`.

**Bloques dentro del formulario** (1.18):

```json
{ "type": "formulario", "columns": 2, "fields": [
  { "label": "Nombre", "name": "NOMBRE" }, { "label": "Código", "name": "CODIGO" },
  { "span": "row", "block": { "type": "tabla", "source": "DETALLE", "columns": ["PRODUCTO", "CANTIDAD"] } },
  { "label": "Notas", "name": "NOTAS", "input": "multiline", "span": "row" } ] }
```

Funciona igual en **`ficha`** y **`tarjetas`** (por ejemplo, un QR entre los campos de una ficha). La sección se parte en tramos (campos, bloque, campos) con la misma configuración; el título, si lo hay, va en el primer tramo. Un bloque sin `source` toma la de la sección. Un `when` en el campo se pasa al bloque si este no tiene uno. No se admite `formulario` como bloque; sí `columnas` y [`grupo`](#grupo).

### `linea`

```json
{ "type": "linea", "width": 70, "align": "center", "thickness": 0.25, "color": "#000000", "gapBefore": 1, "gap": 1 }
{ "type": "linea", "x1": 197, "y1": 275, "x2": 197, "y2": 291, "color": "#9BB5A3" }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `width` | todo el ancho | Largo en mm. |
| `align` | `left` | `left`, `center`, `right`. |
| `thickness` | `0.3` | Grosor en mm. |
| `color` | `#000000` | |
| `gapBefore` / `gap` | `0` / `2` | Espacio antes / después. |
| `x1`, `y1`, `x2`, `y2` | — | Línea en posición fija, horizontal o vertical (solo PDF). |

### `columnas`

Pone 2 o 3 casillas **lado a lado**; cada casilla lleva sus propias secciones. Sirve para facturas (emisor y cliente, logo y datos), recibos con QR junto al monto y firmas en una misma línea.

```json
{ "type": "columnas", "widths": [60, 40], "cols": [
  [ { "type": "texto", "text": "**Emisor**\nNovaCode, S.A." }, { "type": "ficha", "columns": 1, "fields": [ ... ] } ],
  [ { "type": "codigo", "kind": "qr", "value": "{DOC.NUMERO}", "align": "right" } ] ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `cols` | — | Arreglo de casillas (1 a 3); cada una es un arreglo de secciones. |
| `widths` | iguales | Ancho relativo de cada casilla, p. ej. `[60, 40]`. |
| `colGap` | `4` | Espacio entre casillas en mm. |
| `gap` | `1` | Espacio después de la fila en mm (PDF). |

- Dentro de una casilla van `ficha`, `formulario`, `tarjetas`, `texto`, `imagen`, `codigo`, `alerta`, `linea`, `tabla`, `grafico`, `espacio` y, desde 1.19, otra `columnas` o un [`grupo`](#grupo). `header` y `salto` se ignoran, igual que `x`/`y`.
- Las imágenes, gráficos y códigos más anchos que la casilla se reducen a su ancho.
- La fila **no se parte entre páginas**: si no cabe, pasa completa a la siguiente. Si ni en una página completa cabe, las casillas se apilan. Las tablas largas van a ancho completo, fuera de las columnas.
- Cada sección dentro de una casilla admite `when` y `formats`; la fila completa también.
- **PDF**: cada casilla en su franja. **Word**: tabla sin bordes, una celda por casilla. **Excel**: cada casilla ocupa un bloque de columnas de la hoja, una al lado de la otra (sin filtro ni panel inmovilizado dentro de las casillas).

### `grupo`

Contenedor (1.19): agrupa cualquier sección dentro de un marco con título, fondo, borde y margen interno. Admite `ficha`, `formulario`, `tarjetas`, `tabla`, `texto`, `imagen`, `codigo`, `grafico`, `alerta`, `linea`, `espacio`, `columnas` y otro `grupo`, a cualquier nivel.

```json
{ "type": "grupo", "title": "Datos del cliente", "border": true, "fill": "#F5F7FA", "padding": 3, "sections": [
  { "type": "ficha", "source": "CLIENTE", "columns": 2, "fields": [ ... ] },
  { "type": "columnas", "cols": [ [ { "type": "texto", "text": "..." } ], [ { "type": "codigo", "value": "{CODIGO}" } ] ] } ] }
```

**Repetir por fila** (como el *repeating frame* de Oracle Reports): con `each` y `source`, el grupo se dibuja una vez por cada fila. Dentro, esa fuente queda con la fila actual, sus columnas se leen como `{COL}` en cualquier sección, y `link` filtra otras fuentes por la fila:

```json
{ "type": "grupo", "source": "EMP", "each": true, "title": "Colaborador {ENAME}", "border": true,
  "link": { "VENTAS": { "EMPNO": "EMPNO" } },
  "sections": [
    { "type": "ficha", "source": "EMP", "columns": 2, "fields": [ { "label": "Puesto", "value": "{JOB}" } ] },
    { "type": "tabla", "source": "VENTAS", "columns": ["MES", "MONTO"], "totals": ["MONTO"] } ] }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `sections` | — | Secciones del grupo. Una sección sin `source` toma la del grupo. |
| `title` | — | Banda de título (plantilla). `titleFill`, `titleColor`, `titleSize`. |
| `border` | `false` | Borde exterior. `borderColor`, `borderWidth` (PDF, mm). |
| `fill` | — | Fondo. En Excel, solo las celdas sin fondo propio. |
| `padding` | `3` con borde o fondo, si no `0` | Margen interno en mm. |
| `keepTogether` | `true` | PDF: si el grupo cabe en una página, no se parte. Si no cabe ni en una página completa, sigue en la siguiente sin marco. |
| `source`, `each` | — | Repetir el grupo por cada fila de la fuente. `filter` y `max` limitan las filas. |
| `link` | — | `{ "FUENTE": { "COL_FUENTE": "COL_FILA" } }`: cada repetición ve solo las filas relacionadas. |

- Los campos de un `formulario` dentro de un grupo repetido llevan `_1`, `_2`… por repetición.
- **PDF:** marco dibujado alrededor del contenido. **Word:** tabla de una celda (título en su propia fila). **Excel:** banda de título, secciones y borde exterior del bloque.

### Hipervínculos

Desde 1.22 el texto, las celdas de tabla, los valores de ficha y las imágenes pueden llevar un vínculo:

```json
{ "type": "texto", "text": ["Consulte el [a=https://www.novacode-labs.com/tasas]tarifario vigente[/a] o escriba a [a=mailto:{CORREO}]{CORREO}[/a]."] }
{ "type": "tabla", "source": "MOVS", "columns": [ { "col": "NRO", "href": "{URL_DETALLE}" }, "CONCEPTO", "MONTO" ] }
{ "type": "ficha", "fields": [ { "label": "Sitio", "value": "{WEB}", "href": "{WEB}" } ] }
{ "type": "imagen", "url": "#APP_FILES#logo.png", "width": 30, "href": "https://www.novacode-labs.com" }
```

- La URL es una plantilla: `{COL}` toma el valor de la fila (tabla) o de la primera fila de la fuente (texto, ficha, imagen).
- Se aceptan `http(s)://`, `mailto:`, `tel:` y `ftp://`. `www.…` pasa a `https://www.…`. Una ruta relativa (`/ords/…`, `detalle?id=…`) se completa con la URL de la página que genera el reporte; para enlazar páginas de APEX arme la URL en la consulta con `apex_page.get_url` (con URLs amigables, un `f?p=` relativo no apunta a la raíz de ORDS). Cualquier otro esquema (`javascript:`, `data:`…) se descarta y el texto queda sin vínculo. Las sustituciones `&ITEM.` de APEX no se resuelven en el navegador: arme la URL en la consulta (`apex_page.get_url(p_page => 20, p_items => 'P20_NRO', p_values => nro) url_detalle`) o use `{ITEM.P1_X}`.
- Estilo: subrayado y en `page.theme.link` (`#0563C1` por defecto). Un `[c=…]` dentro del vínculo, el `color` de la columna o el color de una regla (`cellStyle`, `rowStyle`, `fields[].color`) tienen prioridad.
- **PDF:** zona cliqueable sobre el texto (o sobre toda la celda en tablas y fichas). **Word:** `w:hyperlink`. **Excel:** vínculo de celda; Excel admite uno por celda, así que un párrafo con varios vínculos toma el primero. Una celda numérica con `href` se exporta como texto con el formato de la columna.

### Encabezado de página

`pageHeader` dibuja una banda en la parte superior de cada página: una imagen (izquierda, centro o derecha) y tres textos (izquierda, centro y derecha) con una línea debajo.

```json
"pageHeader": {
  "image": { "url": "#APP_FILES#logo.png" },
  "left": { "text": "NovaCode, S.A.\nEstado de cuenta", "bold": true, "size": 9 },
  "center": "{DOC.CLIENTE}",
  "right": "Página {DOCPAGE} de {DOCPAGES}",
  "firstPage": true
}
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `left` / `center` / `right` | — | Texto (plantilla, `\n` para otra línea) o `{ "text", "size", "bold", "color" }`. Acepta `{PAGE}`, `{PAGES}`, `{DOCPAGE}` y `{DOCPAGES}`. |
| `image` | — | `{ "url" }` (o `field` con una columna BLOB del documento), `width` / `height` en mm y `align`: `left` (defecto), `center` o `right`. Sin tamaño, toma el alto de la banda. Al centro ocupa el lugar del texto central. |
| `height` | `12` | Alto de la banda en mm. |
| `top` | `5` | Distancia desde el borde superior (PDF). |
| `gap` | `3` | Espacio entre la banda y el contenido (PDF). |
| `size` / `bold` / `color` | `8` / `false` / `#000000` | Estilo por defecto de los tres textos. |
| `fill` | — | Fondo de la banda. |
| `line` | `true` | Línea inferior; `lineColor` (defecto `theme.primary`) y `lineWidth` (`0.3`). |
| `firstPage` | `true` | `false`: no se dibuja en la primera página de cada documento (por ejemplo, cuando la primera lleva un `header` grande). |

- **PDF:** el contenido de cada página empieza debajo de la banda; las tablas largas continúan debajo de ella. Un `header` de sección queda debajo de la banda.
- **Word:** tabla sin bordes en el encabezado de Word. `{DOCPAGES}` usa el total de páginas de la sección; en un archivo unido cada documento numera desde 1.
- **Excel:** encabezado de impresión (`&L &C &R`): solo texto; `{PAGE}` y `{DOCPAGE}` pasan a `&P`, y `{PAGES}` y `{DOCPAGES}` a `&N`.

### PDF con contraseña

```json
"pdf": { "password": "{DOC.CEDULA}", "ownerPassword": "admin", "permissions": ["print"] }
```

| Propiedad | Descripción |
|---|---|
| `password` | Contraseña para abrir el PDF. Acepta plantillas: cada documento de un lote puede tener la suya. |
| `ownerPassword` | Contraseña de propietario (quita las restricciones). Por defecto, la misma de `password`. |
| `permissions` | Lo que se permite con la contraseña de apertura: `print`, `copy`, `modify`, `annot-forms`. Defecto: `["print"]`. |

La opción `pdfPassword` de `novaReport.run` (por ejemplo, desde un ítem de la página en el *Initialization JavaScript Code*) reemplaza a `password`. Solo PDF. El cifrado de jsPDF es RC4 de 40 bits: sirve para que el archivo no se abra sin la clave, no para documentos que requieren cifrado fuerte. No se combina con `append`.

### Anexar PDFs

```json
"append": [
  { "source": "SOPORTES", "field": "ARCHIVO" },
  { "url": "#APP_FILES#terminos.pdf", "when": "TIPO == 'PRESTAMO'" }
]
```

Después de las páginas de cada documento se agregan, en orden, los PDFs de cada elemento:

| Propiedad | Descripción |
|---|---|
| `field` | Columna BLOB con un PDF. Sin `source`, se toma de `DOCS`; con `source`, se anexa el PDF de cada fila de esa fuente (que se reparte por `DOC_KEY`). |
| `url` | PDF fijo (admite `#APP_FILES#`). Se descarga una sola vez. |
| `when` | [Condición](#condiciones) por documento. |

Solo PDF; usa la librería **pdf-lib** (se carga sola cuando el diseño trae `append`). Las páginas anexas no llevan encabezado, pie ni marca de agua y no cuentan en `{PAGES}`. Un PDF anexo protegido con contraseña se agrega tal cual si el lector lo permite; uno dañado detiene el reporte con `No se pudo anexar el PDF: …`.

### `espacio` y `salto`

```json
{ "type": "espacio", "height": 10 }
{ "type": "salto" }
```

`espacio` agrega `height` mm (defecto `6`). `salto` empieza una página nueva. En Excel ambos dejan una fila vacía.

## Qué soporta cada formato

| Sección / opción | PDF | Excel | Word |
|---|:---:|:---:|:---:|
| `header` | ✓ | ✓ | ✓ |
| `tarjetas` | ✓ | ✓ | ✓ |
| `ficha` | ✓ | ✓ valores reales | ✓ |
| `ficha.grid`, `labelFill`, `labelColor`, `valueColor` | ✓ | ✓ | ✓ |
| `ficha.fields[]`: `align`, `bold`, `color`, `fill` | ✓ | ✓ | ✓ |
| `ficha` / `formulario`: `span`, `empty` | ✓ | ✓ | ✓ |
| `ficha` / `formulario`: `labelPosition` (`left`, `top`, `none`) y estilo de etiqueta | ✓ | ✓ | ✓ |
| `header`: `subtitleSize`, `rightSize`, `font`, `fill`, `color` | ✓ | ✓ | ✓ |
| `header.height` | ✓ | — | — |
| `formulario` | ✓ AcroForm | ✓ celdas editables | ✓ controles de contenido |
| `tabla` | ✓ | ✓ fórmulas, filtro | ✓ |
| `tabla.groups` | ✓ | ✓ | ✓ |
| `tabla.headAlign`, `grid`, `totalsColor` | ✓ | ✓ | ✓ |
| `tabla.repeatHeader` | ✓ | — | siempre |
| `tabla.columns[].cell` (código, imagen, gráfico, texto por fila) | ✓ | ✓ imagen sobre la celda | ✓ |
| `formulario` / `ficha` / `tarjetas`: `fields[].block` | ✓ | ✓ | ✓ |
| `grupo` (marco, repetición por fila, anidado) | ✓ | ✓ | ✓ |
| `columnas` dentro de `columnas` o `grupo` | ✓ | ✓ | ✓ |
| `alerta` | ✓ | ✓ | ✓ |
| `texto` enriquecido | ✓ | ✓ | ✓ |
| Hipervínculos: `[a=…]` en `texto`, `href` en columnas, campos de `ficha` e `imagen` | ✓ | ✓ uno por celda | ✓ |
| `texto` / `imagen` / `grafico` / `codigo` con `x`, `y` | ✓ | — | se ignora la posición |
| `imagen` | ✓ | ✓ | ✓ |
| `grafico` | ✓ | ✓ imagen | ✓ |
| `codigo` | ✓ vectorial | ✓ imagen | ✓ |
| `tabla.breakBy` | ✓ | ✓ `SUBTOTAL()` | ✓ |
| `tabla.breakBy` con varios niveles | ✓ | ✓ `SUBTOTAL()` anidado | ✓ |
| `tabla.breakPage` | ✓ página nueva | ✓ salto de impresión | ✓ página nueva |
| `tabla.carry` (van / vienen) | ✓ | — | — |
| `pivot` | ✓ | ✓ números y fórmulas | ✓ |
| `pageHeader` | ✓ | texto (encabezado de impresión) | ✓ |
| `pdf` (contraseña) y `append` | ✓ | — | — |
| `watermark` | ✓ | — | ✓ detrás del texto |
| `linea` | ✓ | — | ✓ horizontal |
| `linea` con `x1…y2` | ✓ | — | — |
| `espacio` | ✓ | fila vacía | ✓ |
| `salto` | ✓ | fila vacía | ✓ |
| `footer` | ✓ | izquierda + *Página X de Y* | ✓ |
| `hooks.pdfCell` | ✓ | — | — |
| `when` en secciones y columnas | ✓ | ✓ | ✓ |
| `columnas` (casillas lado a lado) | ✓ | ✓ bloques de columnas | ✓ tabla sin bordes |
| `fmt: letras` | ✓ | ✓ texto | ✓ |
| `save` (guardar en el servidor) | ✓ | ✓ | ✓ |

Use `"formats"` para ocultar una sección donde no aplica: `{ "type": "salto", "formats": ["pdf"] }`.

## Guardar en el servidor

Además de entregar el archivo al usuario (o en lugar de hacerlo), el plugin puede subirlo a un **proceso de aplicación** (*On Demand*) para archivarlo, enviarlo por correo o registrar la ejecución.

```json
"save": { "process": "NR_GUARDAR", "mode": "only" }
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `save.process` | — | Nombre del proceso de aplicación *On Demand*. Vacío: no se guarda. |
| `save.mode` | entregar | `only`: solo se guarda y se muestra un mensaje de éxito (el `msg` de la respuesta, si viene). Sin `mode`: se guarda y además se abre o descarga. |

También se puede indicar en `novaReport.run({ save: {...} })` o en el objeto de la acción; esa opción tiene prioridad sobre el diseño. Si el guardado falla, no se entrega el archivo y se muestra el error.

El proceso recibe:

| Variable | Valor |
|---|---|
| `apex_application.g_f01` | Archivo en base64, en trozos de 30 000 caracteres. |
| `apex_application.g_x01` | Nombre del archivo (`fileName` con extensión, o el ZIP). |
| `apex_application.g_x02` | Tipo MIME. |
| `apex_application.g_x03` | Reporte (`data-report`, origen *resolver*). |
| `apex_application.g_x04` | Parámetros en JSON. |
| `apex_application.g_x05` | `pdf`, `xlsx`, `docx` o `zip`. |

Debe responder JSON. `{ "ok": false, "msg": "..." }` se trata como error; cualquier otra respuesta, como éxito.

```sql
declare
  l_b64  clob;
  l_blob blob;
  l_id   number;
begin
  dbms_lob.createtemporary(l_b64, true);
  for i in 1 .. apex_application.g_f01.count loop
    dbms_lob.writeappend(l_b64, length(apex_application.g_f01(i)), apex_application.g_f01(i));
  end loop;
  l_blob := apex_web_service.clobbase642blob(l_b64);

  insert into mis_documentos (nombre, mime, contenido, reporte, parametros, creado_por, creado_en)
  values (apex_application.g_x01, apex_application.g_x02, l_blob, apex_application.g_x03,
          apex_application.g_x04, :APP_USER, systimestamp)
  returning id into l_id;

  apex_json.open_object;
  apex_json.write('ok', true);
  apex_json.write('id', l_id);
  apex_json.write('msg', 'Documento guardado con el número ' || l_id || '.');
  apex_json.close_object;
exception
  when others then
    apex_json.open_object;
    apex_json.write('ok', false);
    apex_json.write('msg', sqlerrm);
    apex_json.close_object;
end;
```

El evento `novareport-saved` recibe `{ name, kind, response }`.

## Excel: hojas

```json
"xlsx": {
  "sheets": [
    { "name": "Operación", "sections": ["enc", "ficha", "pend"] },
    { "name": "Plan {DOC.NRO}", "sections": ["plan"] }
  ]
}
```

| Propiedad | Descripción |
|---|---|
| `sheets[].name` | Nombre (plantilla, máx. 31 caracteres; se limpian `[ ] \ / : * ? " < > \|`). Nombres repetidos reciben `_2`, `_3`… |
| `sheets[].sections` | Secciones por `id` o por posición (`0`, `1`…). Sin `sections`, todas. |
| `sheets[].mergeName` | Nombre de la hoja en salida `merge` (una hoja por documento). Defecto: `{DOC.DOC_KEY}` o `{DOC.DOC_KEY} <name>`. |
| `sheetName` | Nombre de la única hoja si no define `sheets`. Defecto `Reporte`. |

## Lotes y resumen

```json
"batch": {
  "zipName": "planes_{PARAM.FORMATO}_{TODAY}",
  "mergeName": "planes_unidos",
  "chunkSize": 5,
  "maxDocs": 3000,
  "summary": {
    "fileName": "00_resumen",
    "footer": { "right": "Página {PAGE} de {PAGES}" },
    "xlsx": { "sheets": [ { "name": "Resumen" } ] },
    "sections": [
      { "type": "header", "title": "Resumen del lote {LOTE.ID}" },
      { "type": "tabla", "source": "RES" } ]
  }
}
```

| Propiedad | Defecto | Descripción |
|---|---|---|
| `zipName` | `reportes.zip` | Nombre del ZIP. Dispone de `{FORMATO}` (`pdf`, `excel`, `word`, `todos`). |
| `mergeName` | `zipName` o `fileName` | Nombre del archivo en salida `merge`. |
| `chunkSize` | `5` | Documentos por bloque antes de devolver el control al navegador. |
| `maxDocs` | sin límite | Rechaza lotes más grandes. |
| `summary` | — | Documento extra al inicio del ZIP (solo salida `zip`). Usa las fuentes marcadas `summary`. Hereda `page` y `footer`. |
| `summary.layout` | — | Diseño completo distinto para el resumen (en lugar de `sections`/`footer`/`xlsx`). |

En el resumen no hay documento actual: use `{FUENTE.COL}` o `source` para leer datos.

## Reutilizar partes: `defs`

`"@NOMBRE"` se reemplaza por `defs.NOMBRE` en cualquier lugar del diseño. Dentro de un arreglo, si `defs.NOMBRE` también es arreglo, sus elementos se insertan en ese lugar.

```json
{
  "defs": {
    "BASE": [ { "col": "NRO", "label": "#" }, { "col": "FECHA", "label": "Fecha", "fmt": "date" } ],
    "ROJO": [ { "when": "SALDO < 0", "color": "#AA1E1E" } ],
    "TABLA_PLAN": { "type": "tabla", "source": "PLAN", "columns": [ "@BASE", { "col": "SALDO", "cellStyle": "@ROJO" } ] }
  },
  "sections": [ "@TABLA_PLAN" ]
}
```

## Word desde plantilla (`docx-template`)

En lugar de dibujar secciones, llena un `.docx` hecho en Word. Del diseño solo se usan `fileName` y `batch`.

| Marcador en el `.docx` | Valor |
|---|---|
| `{CAMPO}` | Columna del documento (`DOCS`) o parámetro. |
| `{FUENTE.CAMPO}` | Primera fila de otra fuente. |
| `{DOC.CAMPO}`, `{PARAM.X}` | Documento / parámetro. |
| `{CAMPO\|money}` | Con [formato](#formatos-de-valor). |
| `{#FUENTE}…{/FUENTE}` | Repite el bloque por cada fila de la fuente. Dentro de una fila de tabla, repite la fila. |
| `{NOW}`, `{TODAY}` | Fecha y hora. |

Escriba cada marcador de corrido, sin cambiar el formato en medio: Word puede partirlo en fragmentos y no se reconocería. Ver el ejemplo [`06-plantilla-word`](../examples/06-plantilla-word).
