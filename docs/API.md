# Referencia de la API

Esta página documenta todo lo que novaReport expone: los atributos de la Acción Dinámica, el formato de las fuentes SQL, el protocolo entre el navegador y el servidor y la API JavaScript (`window.novaReport`).

El diseño JSON (secciones, columnas, estilos) está en [DISENO.md](DISENO.md).

- [1. Cómo funciona](#1-cómo-funciona)
- [2. Atributos de la Acción Dinámica](#2-atributos-de-la-acción-dinámica)
- [3. Fuentes SQL](#3-fuentes-sql)
- [4. Documentos: `DOCS` y `DOC_KEY`](#4-documentos-docs-y-doc_key)
- [5. Parámetros `data-*`](#5-parámetros-data-)
- [6. Formato y salida](#6-formato-y-salida)
- [7. API JavaScript](#7-api-javascript)
- [8. Código de inicialización](#8-código-de-inicialización)
- [9. Eventos](#9-eventos)
- [10. Protocolo AJAX](#10-protocolo-ajax)
- [11. Errores](#11-errores)
- [12. Límites](#12-límites)
- [13. Seguridad](#13-seguridad)

---

## 1. Cómo funciona

```
 clic en botón / enlace
        │
        ▼
 novaReport.da()  ── lee data-*, data-format, data-output del elemento
        │
        ├─► apex.server.plugin()  ──►  PL/SQL (ajax)  ── ejecuta las Fuentes SQL
        │                                              con apex_exec y devuelve JSON
        │
        ├─► carga bajo demanda jsPDF / ExcelJS / docx / JSZip (CDN o rutas locales)
        │
        ▼
 motor de diseño (navegador)  ──►  PDF · XLSX · DOCX · ZIP  ──►  abrir / descargar
```

1. El servidor **solo ejecuta las consultas**: el texto SQL vive en los atributos del plugin y nunca viaja al navegador.
2. El navegador recibe filas y tipos, aplica el diseño y arma el archivo.
3. No hay servidor de impresión ni tablas propias. Funciona en Autonomous Database y en APEX Free Tier.

## 2. Atributos de la Acción Dinámica

| # | Atributo | Clave interna | Tipo | Valor por defecto | Descripción |
|---|---|---|---|---|---|
| 1 | **Fuentes SQL** | `sources` | Textarea | — | Una o varias consultas, cada una precedida de `--@NOMBRE`. Ver [§3](#3-fuentes-sql). |
| 2 | **Diseño (JSON)** | `layout` | Textarea | — | El diseño en JSON, o la ruta a una variable JavaScript global que lo contenga (`misDisenos.carta`). |
| 3 | **Formato** | `format` | Lista | `pdf` | `pdf`, `xlsx`, `docx`, `docx-template` o `all` (PDF + Excel + Word). |
| 4 | **Salida** | `output` | Lista | `file` | `file`, `zip` o `merge`. Ver [§6](#6-formato-y-salida). |
| 5 | **Ítems a enviar** | `items` | Ítems de página | — | Ítems cuyo valor se envía a la sesión antes de ejecutar las consultas (como *Items to Submit*). Ver la nota abajo. |
| 6 | **PDF de un documento** | `pdf_action` | Lista | `open` | `open`: abre el PDF en una pestaña nueva con pantalla de espera. `download`: lo descarga. |
| 7 | **Plantilla Word (URL)** | `template_url` | Texto | — | URL del `.docx` usado por `docx-template`. Ver la nota abajo. |
| 8 | **Mensaje de espera** | `message` | Texto | `Consultando datos...` | Texto de la pantalla de espera del PDF. |
| — | *Initialization JavaScript Code* | estándar de APEX | Función JS | — | Permite modificar las opciones antes de ejecutar. Ver [§8](#8-código-de-inicialización). |

> **Diseños de más de 4000 caracteres.** Los atributos de APEX admiten 4000 caracteres. Para diseños más grandes defina el JSON en *Function and Global Variable Declaration* de la página (o en un archivo estático) y escriba en el atributo el nombre de la variable:
>
> ```js
> var misDisenos = { plan: { "page": { "size": "legal" }, "sections": [ ... ] } };
> ```
> Atributo **Diseño**: `misDisenos.plan`

> **Ítems a enviar.** En la versión 1.6.1 el atributo se pasa a `apex.server.plugin` tal como lo guarda APEX (`P5_A,P5_B`), y ese texto se interpreta como selector jQuery, por lo que los ítems **no** se envían. Mientras se corrige, conviértalo en el código de inicialización:
> ```js
> function (o) { if (o.items) { o.items = o.items.split(','); } return o; }
> ```
> Alternativa sin código: una acción *Execute Server-side Code* previa con *Items to Submit*, o ítems ya guardados en sesión.

> **Plantilla Word y `#APP_FILES#`.** En la versión 1.6.1 el atributo **Plantilla Word (URL)** se usa tal cual: no reemplaza `#APP_FILES#` ni las sustituciones de APEX. Use una URL completa o arme la ruta en el código de inicialización:
> ```js
> function (o) { o.templateUrl = apex.env.APP_FILES + 'plantillas/carta.docx'; return o; }
> ```

## 3. Fuentes SQL

```sql
--@DOCS
select e.empno doc_key, e.ename, e.job
  from emp e
 where (:EMPNO is null or e.empno = :EMPNO)
--@DETALLE
select e.empno doc_key, p.periodo, p.monto
  from pagos p join emp e on e.empno = p.empno
--@RESUMEN summary
select count(*) total from emp
```

| Regla | Detalle |
|---|---|
| Encabezado | Cada fuente empieza con una línea `--@NOMBRE`. El nombre se pasa a mayúsculas y es el que se usa en `"source"` del diseño. |
| Banderas | Texto después del nombre. Hoy existe `summary`: la fuente solo se ejecuta cuando la salida es `zip` (resumen del lote). |
| Texto antes de la primera fuente | Se ignora. Sirve para comentarios. |
| Terminadores | Se eliminan `;` y `/` al final de cada consulta. |
| Columnas | Se usan los alias en mayúsculas: `e.ename` → `ENAME`. |
| Error si no hay fuentes | `Defina al menos una fuente con una línea "--@NOMBRE" antes del SELECT.` |

### Tipos de dato

| Tipo Oracle | Llega al navegador como | Notas |
|---|---|---|
| `NUMBER` | número | Se formatea con `fmt`. En Excel queda como número real. |
| `DATE` | texto `DD/MM/YYYY` | **Sin hora.** En Excel se convierte a fecha real con formato `dd/mm/yyyy`. Si necesita la hora, use `to_char(fecha, 'DD/MM/YYYY HH24:MI')`. |
| `BLOB` | base64 | Para la sección `imagen` con `"field"` (PNG o JPG). |
| `CLOB` | texto | |
| Otros (`VARCHAR2`, `TIMESTAMP`, …) | texto | `TIMESTAMP` usa el formato NLS de la sesión. |

### Binds

| Bind | Valor |
|---|---|
| Ítem de página o de aplicación (`:P5_ID`, `:APP_USER`, `:APP_ID`…) | Valor en sesión. Se enlaza automáticamente. Envíe con **Ítems a enviar** los que cambian en pantalla. |
| Cualquier otro (`:EMPNO`, `:DET`) | Atributo `data-*` del elemento que disparó la acción ([§5](#5-parámetros-data-)), o `NULL` si no existe. |

Un bind se considera ítem si existe en la página actual, en la página 0 o como ítem de aplicación. Los binds dentro de literales (`'...'`) y comentarios (`--`) se ignoran.

## 4. Documentos: `DOCS` y `DOC_KEY`

Si existe una fuente llamada **`DOCS`**, cada fila es **un documento** y la fuente debe tener la columna **`DOC_KEY`**.

| Fuente | ¿Tiene `DOC_KEY`? | Comportamiento |
|---|---|---|
| `DOCS` | obligatoria | Una fila = un documento. En plantillas se accede como `{DOC.COL}` o `{COL}`. |
| Otra fuente | sí | Sus filas se reparten: cada documento solo ve las filas con su `DOC_KEY`. |
| Otra fuente | no | Se comparte completa en todos los documentos. |
| Sin `DOCS` | — | Todo el reporte es un único documento con todas las fuentes. |

```sql
--@DOCS
select c.id_cotizacion doc_key, c.cliente, c.monto from cotizacion c where c.id_lote = :P4_LOTE
--@PLAN                      -- se reparte por documento
select p.id_cotizacion doc_key, p.nro, p.cuota from plan p where p.id_lote = :P4_LOTE
--@EMPRESA                   -- se comparte
select nombre, ruc from empresa
```

Si `DOCS` no devuelve filas, se muestra `emptyMessage` del diseño o `No hay datos para generar el reporte.`

## 5. Parámetros `data-*`

Todos los atributos `data-*` del elemento que disparó la acción se convierten en parámetros:

| Atributo HTML | Parámetro | Uso en SQL | Uso en el diseño |
|---|---|---|---|
| `data-empno="7788"` | `EMPNO` | `:EMPNO` | `{PARAM.EMPNO}` |
| `data-id-carga="15"` | `ID_CARGA` | `:ID_CARGA` | `{PARAM.ID_CARGA}` |
| `data-format="xlsx"` | — | — | Sobrescribe **Formato** |
| `data-output="zip"` | — | — | Sobrescribe **Salida** |

`data-id-carga` → `dataset.idCarga` → `ID_CARGA` (los guiones pasan a `_` y todo a mayúsculas). Todos los valores llegan como texto.

**Patrón: un archivo por fila de un reporte.**

```sql
select empno, ename,
       '<a href="javascript:void(0)" class="js-nr-pdf" data-empno="' || empno || '">'
       || '<span class="fa fa-file-pdf-o"></span></a>' pdf
  from emp
```

- Columna `PDF` con *Escape special characters* = **No**.
- Acción Dinámica *Click* con *Selection Type* = **jQuery Selector** `.js-nr-pdf` y *Event Scope* = **Dynamic**.

**Patrón: un botón para la fila y otro para el lote.** Use la misma acción y el mismo SQL `(:EMPNO is null or e.empno = :EMPNO)`:

```html
<a class="js-nr-pdf" data-empno="7788">Solo SCOTT</a>
<button class="js-nr-pdf" data-output="zip">Todos (ZIP)</button>
```

**Patrón: botón de APEX.** En *Advanced → Custom Attributes* del botón, use sustituciones: `data-det="&P5_ID_DET." data-esc="&P5_ESCENARIO."`.

## 6. Formato y salida

| Salida | 1 documento, 1 formato | Varios documentos | `format = all` |
|---|---|---|---|
| `file` | Un archivo (PDF se abre o descarga según **PDF de un documento**) | ZIP con un archivo por documento | ZIP |
| `zip` | ZIP | ZIP + resumen (`batch.summary`) + fuentes `summary` | ZIP + resumen por formato |
| `merge` | Un archivo | **Un solo archivo**: PDF con todas las páginas, Word con una sección por documento, Excel con una hoja por documento | ZIP |

- `docx-template` con varios documentos siempre produce ZIP (no se une), y no genera resumen.
- Nombres de archivo: `fileName` (por documento), `batch.zipName` (ZIP), `batch.mergeName` o `batch.zipName` (merge). Se limpian los caracteres `\ / : * ? " < > |`; por eso `{TODAY}` (`19/10/2026`) queda `19_10_2026`.
- Nombres repetidos dentro del ZIP reciben sufijo `_2`, `_3`…
- En el nombre del ZIP está disponible `{PARAM.FORMATO}` / `{FORMATO}`: `pdf`, `excel`, `word` o `todos`.

## 7. API JavaScript

El archivo `novareport.js` define el objeto global `window.novaReport`.

| Miembro | Tipo | Descripción |
|---|---|---|
| `version` | `string` | Versión del motor, p. ej. `"1.6.1"`. |
| `run(opciones)` | `Promise<Resultado>` | Pide los datos al servidor (o usa `opciones.data`), genera y entrega el archivo con UI (espera, avance, mensajes). |
| `build(opciones, datos)` | `Promise<Resultado>` | Solo genera: sin AJAX, sin UI, sin descargar. Para pruebas o integraciones propias. |
| `da(config)` | `void` | Punto de entrada que APEX llama desde la Acción Dinámica. No lo invoque directamente. |
| `ensure(nombres)` | `Promise` | Carga librerías por nombre: `novaReport.ensure(['exceljs'])`. |
| `libs` | `object` | Catálogo de librerías: `{ jspdf, autotable, exceljs, jszip, docx, pizzip, docxtemplater }`, cada una con `url` y `ok()`. |
| `_internals` | `object` | Funciones internas expuestas para pruebas (`tpl`, `cond`, `fmt`, `normalize`, `contexts`…). **No es API estable.** |

### `novaReport.run(opciones)`

```js
novaReport.run({
  ajaxIdentifier: '...',            // de la acción (ver §8); omítalo si pasa data
  layout: 'misDisenos.carta',       // objeto, JSON en texto o ruta a variable global
  format: 'pdf',                    // pdf | xlsx | docx | docx-template | all
  output: 'file',                   // file | zip | merge
  params: { EMPNO: '7788' },        // binds no-ítem y {PARAM.X}
  items: ['P5_DEPTNO', 'P5_DESDE'], // ítems a enviar (arreglo o selector '#P5_DEPTNO,#P5_DESDE')
  pdfAction: 'open',                // open | download
  templateUrl: '/ruta/plantilla.docx',
  message: 'Consultando datos…',
  loader: true,                     // false: no abre la pestaña de espera del PDF
  hooks: { pdfCell: function (h, fila, col, seccion, ctx) {} },
  transform: function (datos) { return datos; },
  data: null                        // datos ya obtenidos: se omite el AJAX
}).then(function (r) { console.log(r.name); });
```

| Opción | Tipo | Defecto | Descripción |
|---|---|---|---|
| `ajaxIdentifier` | string | — | Identificador AJAX del plugin. Obligatorio si no se pasa `data`. |
| `layout` | object \| string | — | Diseño. Ver [DISENO.md](DISENO.md). |
| `format` | string | `pdf` | Formato. |
| `output` | string | `file` | Salida. |
| `params` | object | `{}` | Parámetros. Las claves deben ir en mayúsculas para coincidir con los binds. |
| `items` | array \| string | — | Ítems que se envían a la sesión: arreglo de nombres (`['P5_A','P5_B']`) o selector jQuery (`'#P5_A,#P5_B'`). Se pasa tal cual a `pageItems` de `apex.server.plugin`. |
| `pdfAction` | string | `open` | `download` evita abrir pestaña. |
| `templateUrl` | string | — | Solo `docx-template`. |
| `message` | string | `Consultando datos…` | Texto de la pantalla de espera. |
| `loader` | boolean | `true` | Pantalla de espera en pestaña nueva (solo PDF de un documento con `open`). |
| `hooks` | object | `{}` | Hoy existe `pdfCell` (ver abajo). |
| `transform` | function | — | Recibe los datos crudos del servidor ([§10](#10-protocolo-ajax)) y puede devolver otros. |
| `data` | object | — | Datos en el formato del [§10](#10-protocolo-ajax). Si se pasa, no se llama al servidor. |

**Resultado** (`Promise` resuelta):

| Campo | Descripción |
|---|---|
| `kind` | `pdf`, `xlsx`, `docx` o `zip` |
| `data` | `ArrayBuffer` o `Blob` |
| `name` | Nombre del archivo entregado |
| `count` | Documentos generados |
| `files` | Archivos dentro del ZIP (solo `zip`) |

Si falla, la promesa se rechaza, se muestra `apex.message.alert` y se dispara `novareport-error`.

### `hooks.pdfCell(h, fila, col, seccion, ctx)`

Se llama por cada celda del cuerpo de una `tabla` en PDF, después de aplicar `rowStyle` y `cellStyle`.

| Argumento | Contenido |
|---|---|
| `h` | Objeto `didParseCell` de jsPDF-AutoTable (`h.cell.styles`, `h.cell.text`…) |
| `fila` | Fila de datos (`{ COL: valor }`) |
| `col` | Definición resuelta de la columna (`col`, `label`, `fmt`, `align`…) |
| `seccion` | La sección `tabla` del diseño |
| `ctx` | Contexto del documento (`doc`, `params`, `S` fuentes, `T` tipos) |

```js
hooks: { pdfCell: function (h, fila, col) {
  if (col.col === 'SALDO' && fila.SALDO < 0) { h.cell.styles.textColor = [170, 30, 30]; }
} }
```

### `novaReport.build(opciones, datos)`

Mismas opciones de diseño que `run` (`layout`, `format`, `output`, `params`, `templateUrl`, `hooks`) más:

| Opción | Descripción |
|---|---|
| `zipType` | Tipo que devuelve JSZip: `blob` (defecto), `arraybuffer`, `nodebuffer`… |
| `onProgress(n, total)` | Avance del lote. `n = -1` al comprimir. |

Las librerías deben estar cargadas (`novaReport.ensure([...])`). Es lo que usa `test/run.js` para generar los ejemplos en Node.

### Librerías locales (sin internet)

Suba los archivos a *Static Application Files* y cambie las rutas antes del primer uso (por ejemplo en *Execute when Page Loads* o en un archivo JS de la aplicación):

```js
novaReport.libs.jspdf.url         = '#APP_FILES#lib/jspdf.umd.min.js';
novaReport.libs.autotable.url     = '#APP_FILES#lib/jspdf.plugin.autotable.min.js';
novaReport.libs.exceljs.url       = '#APP_FILES#lib/exceljs.min.js';
novaReport.libs.jszip.url         = '#APP_FILES#lib/jszip.min.js';
novaReport.libs.docx.url          = '#APP_FILES#lib/docx.iife.js';
novaReport.libs.pizzip.url        = '#APP_FILES#lib/pizzip.min.js';
novaReport.libs.docxtemplater.url = '#APP_FILES#lib/docxtemplater.min.js';
```

En estas rutas sí se resuelven `#APP_FILES#`, `#WORKSPACE_FILES#` e `#IMAGE_PREFIX#`. Las versiones esperadas están en [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

| Formato | Librerías |
|---|---|
| `pdf` | `jspdf`, `autotable` |
| `xlsx` | `exceljs` |
| `docx` | `docx` |
| `docx-template` | `pizzip`, `docxtemplater` |
| ZIP | `jszip` (se carga salvo en `merge`) |

## 8. Código de inicialización

En *Initialization JavaScript Code* de la acción puede escribir una función que recibe las opciones ya armadas (las de `run`) y devuelve las finales:

```js
function (o) {
  o.params.FECHA = apex.item('P5_FECHA').getValue();       // parámetro extra (:FECHA)
  o.format = apex.item('P5_FORMATO').getValue() || o.format; // formato elegido en pantalla
  o.templateUrl = apex.env.APP_FILES + 'plantillas/carta.docx';
  o.hooks = { pdfCell: function (h, fila) { if (fila.ESTADO === 'VENCIDO') { h.cell.styles.fillColor = [255, 228, 228]; } } };
  return o;
}
```

`o.ajaxIdentifier` ya viene cargado: no lo cambie.

## 9. Eventos

Se disparan en `document` con `apex.event.trigger`. Puede escucharlos con una Acción Dinámica *Custom Event* (selector `document`) o con jQuery.

| Evento | `this.data` | Cuándo |
|---|---|---|
| `novareport-start` | `{ format, output }` | Al iniciar |
| `novareport-progress` | `{ done, total }` | Cada bloque de un lote (`batch.chunkSize`) |
| `novareport-end` | `{ name, count, files }` | Al entregar el archivo |
| `novareport-error` | `{ message }` | Si falla |

```js
$(document).on('novareport-end', function (e, d) { apex.message.showPageSuccess('Generado: ' + d.name); });
```

Mientras una acción está en curso, los clics nuevos en cualquier acción novaReport se ignoran.

## 10. Protocolo AJAX

**Petición** (`apex.server.plugin`):

| Campo | Contenido |
|---|---|
| `x01` | JSON con los parámetros: `{"EMPNO":"7788"}` |
| `x02` | `Y` si la salida es `zip` (se ejecutan las fuentes `summary`), si no `N` |
| `pageItems` | **Ítems a enviar** |

**Respuesta correcta:**

```json
{
  "ok": true,
  "data": {
    "DOCS": {
      "cols": [ { "name": "DOC_KEY", "type": "NUMBER" }, { "name": "ENAME", "type": "VARCHAR2" },
                { "name": "HIREDATE", "type": "DATE" } ],
      "rows": [ [7788, "SCOTT", "09/12/1982"] ]
    }
  }
}
```

`type` es `NUMBER`, `DATE`, `BLOB`, `CLOB` o `VARCHAR2`. Este mismo formato es el que acepta `opciones.data` y el segundo argumento de `build`.

**Respuesta con error:**

```json
{ "ok": false, "msg": "ORA-00942: table or view does not exist" }
```

El prefijo `ORA-nnnnn:` del primer error se elimina antes de mostrarlo.

## 11. Errores

| Mensaje | Causa |
|---|---|
| `Defina al menos una fuente con una línea "--@NOMBRE" antes del SELECT.` | **Fuentes SQL** sin encabezados `--@`. |
| `El reporte supera el máximo de 250000 filas.` | Límite del servidor ([§12](#12-límites)). |
| `No hay datos para generar el reporte.` / `emptyMessage` | `DOCS` sin filas. |
| `El lote supera el máximo de N documentos.` | `batch.maxDocs`. |
| `Diseño inválido: …` | JSON mal formado. |
| `No se encontró el diseño: misDisenos.x` | La variable global no existe al ejecutar. |
| `No se pudo cargar la librería: URL` | CDN bloqueado o ruta local incorrecta. |
| `No se pudo cargar la imagen URL (404)` | Imagen de una sección `imagen`. |
| `Formato de imagen no soportado (use PNG o JPG).` | Imagen en otro formato (GIF, SVG, WEBP). |
| `Defina la URL de la plantilla Word (atributo "Plantilla Word").` | `docx-template` sin URL. |
| `No se pudo descargar la plantilla (404)` | URL de plantilla incorrecta. |
| `Formato no soportado: X` | Valor de `format` / `data-format` inválido. |
| `Error de comunicación: …` | Falla HTTP del AJAX (sesión expirada, error 500). |

## 12. Límites

| Límite | Valor | Dónde |
|---|---|---|
| Filas por petición | **250,000** en total, sumando todas las fuentes | `c_max_rows` en `plugin.plsql` |
| Documentos por lote | `batch.maxDocs` (sin límite si no se define) | Diseño |
| Documentos por bloque | `batch.chunkSize` (defecto 5) | Diseño. Bloques chicos mantienen la página receptiva. |
| Texto de atributos | 4000 caracteres | APEX. Use una variable global para el diseño. |
| Memoria | La del navegador | Todo el lote y el ZIP se arman en memoria. |

## 13. Seguridad

- **El SQL no viaja al navegador** y no puede alterarse desde el cliente.
- **Los `data-*` sí.** Cualquier usuario puede cambiar `data-empno="7788"` por otro valor en las herramientas del navegador. Cada fuente debe validar que el usuario tenga acceso a lo que pide:

  ```sql
  where e.empno = :EMPNO
    and exists (select 1 from acceso a where a.usuario = :APP_USER and a.deptno = e.deptno)
  ```
- Un `data-*` no puede reemplazar un ítem de APEX: si el bind existe como ítem, siempre se usa el valor de sesión. Para valores sensibles use ítems con *Session State Protection*.
- Las consultas corren con los privilegios del esquema de análisis de la aplicación, igual que cualquier región.
- Las librerías se cargan desde cdnjs y jsDelivr. Si su política lo exige, sírvalas localmente ([§7](#librerías-locales-sin-internet)).
