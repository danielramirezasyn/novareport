# Ejemplos

Siete ejemplos listos para copiar en una aplicación APEX. Todos usan las tablas de muestra **EMP / DEPT**.

**Antes de empezar:** ejecute [`00-tablas-emp-dept.sql`](00-tablas-emp-dept.sql) en su esquema (*SQL Workshop → SQL Scripts*). Crea `DEPT`, `EMP` y `EMP_FOTO` con los 4 departamentos y 14 empleados clásicos. Si las tablas ya existen no las toca, y solo inserta datos cuando están vacías. También puede instalarlas desde *SQL Workshop → Utilities → Sample Datasets*.

| Archivo | Va en el atributo |
|---|---|
| `fuentes.sql` | **Fuentes SQL** |
| `diseno.json` | **Diseño (JSON)** |

Todos se pueden generar sin APEX con `cd test && npm install && npm test` (ver [README](../README.md#probar-sin-apex)).

| # | Ejemplo | Formato · Salida | Qué muestra |
|---|---|---|---|
| 01 | [Listado de empleados](#01--listado-de-empleados) | PDF / Excel / Word · Archivo | Encabezado, dos tablas, totales, `rowStyle` y `cellStyle` |
| 02 | [Cartas en ZIP](#02--cartas-en-zip) | PDF · ZIP o Un solo archivo | `DOCS`, texto enriquecido, resumen del lote, bind `:EMPNO` opcional |
| 03 | [Constancia con posición fija](#03--constancia-con-posición-fija) | PDF · Archivo | `x`/`y`, imagen estática, línea de firma, un PDF por fila |
| 04 | [Imagen desde BLOB](#04--imagen-desde-blob) | PDF / Word · ZIP | `imagen` con `field` |
| 05 | [Excel con varias hojas](#05--excel-con-varias-hojas) | Excel (también PDF / Word) · Archivo | `xlsx.sheets`, `groups`, `defs`, `formats` |
| 06 | [Plantilla Word](#06--plantilla-word) | Word desde plantilla · ZIP o Archivo | `docx-template`, bucle en fila de tabla |
| 07 | [Gráficos y códigos](#07--gráficos-y-códigos) | PDF / Excel / Word · Archivo | `grafico`, `codigo` (QR y Code 128), `breakBy` con subtotales, `watermark` |
| 08 | [Factura con columnas](#08--factura-con-columnas) | PDF / Excel / Word · Archivo | `columnas`, `fmt: letras`, `when` en una sección |

---

## Configuración común

1. Cree un botón con *Action* = **Defined by Dynamic Action**.
2. Cree una Acción Dinámica *Click* sobre el botón con la acción **NovaCode Report (PDF / Excel / Word)**.
3. Copie `fuentes.sql` y `diseno.json` en los atributos y ajuste **Formato** y **Salida** según la tabla.

Para los ejemplos que generan **un archivo por fila** (02, 03, 04, 06) use, en lugar del botón, un enlace en un reporte y una Acción Dinámica con *Selection Type* = **jQuery Selector** y *Event Scope* = **Dynamic** (ver 03).

---

## 01 · Listado de empleados

[`01-listado-empleados`](01-listado-empleados)

Reporte de una sola página con dos fuentes independientes:

- `DEPTOS`: resumen por departamento, con totales de empleados y salarios.
- `EMP`: detalle con totales de salario y comisión.

**Qué observar en el diseño**

| Elemento | Dónde |
|---|---|
| `fileName` con fecha | `"empleados_{TODAY}"` → `empleados_19_10_2026.pdf` |
| Totales | `"totals": ["SAL", "COMM"]` |
| Fila resaltada | `"rowStyle": [ { "when": "SAL >= 3000", "fill": "#E8F3EC" } ]` |
| Celda condicional | `COMM` en verde y negrita si es mayor que 0 (`cellStyle`) |
| Formatos | `int`, `money`, `date` |
| Pie | `"left": "Confidencial"`, `"right": "Página {PAGE} de {PAGES}"` |

**Configuración:** Formato **PDF**, **Excel** o **Word** · Salida **Archivo**. El mismo diseño sirve para los tres; en Excel cada tabla conserva números reales y la fila de totales usa `=SUM()`.

---

## 02 · Cartas en ZIP

[`02-cartas-zip`](02-cartas-zip)

Una carta de ajuste salarial **por empleado**.

- `DOCS` devuelve una fila por empleado con `doc_key = empno`: cada fila es un documento.
- `LISTA summary` solo se ejecuta cuando la salida es **ZIP** y alimenta el documento de resumen (`batch.summary`), que queda primero en el ZIP como `00_listado.pdf`.
- `where (:EMPNO is null or e.empno = :EMPNO)`: sin `data-empno` genera todas; con `data-empno="7788"`, solo la de SCOTT.

**Qué observar en el diseño**

| Elemento | Dónde |
|---|---|
| Letra base Times | `"page": { "font": "times" }`, con títulos en `[f=helvetica]…[/f]` |
| Texto enriquecido | `~~{SAL\|money}~~` tachado, `[c=#19783C]***{SAL_NUEVO\|money}***[/c]` verde en negrita y cursiva, `++*Ajuste salarial*++` subrayado |
| Párrafo justificado | `"align": "justify"` |
| Línea de firma | `{ "type": "linea", "width": 60 }` |
| Nombre por documento | `"fileName": "carta_{DOC.ENAME}"` → `carta_SCOTT.pdf` |
| Lote | `"batch": { "zipName": "cartas_{TODAY}", "chunkSize": 10, "maxDocs": 2000, "summary": {...} }` |

**Configuración**

| Botón | Formato · Salida | Resultado |
|---|---|---|
| *Cartas (ZIP)* | PDF · **ZIP** | `cartas_19_10_2026.zip` con `00_listado.pdf` + 14 cartas |
| *Cartas (un PDF)* | PDF · **Un solo archivo** | `cartas_19_10_2026.pdf` con 14 páginas |
| Enlace por fila con `data-empno` | PDF · Archivo | `carta_SCOTT.pdf` en pestaña nueva |

Con una sola acción y dos botones: deje Salida = Archivo y agregue `data-output="zip"` o `data-output="merge"` en *Custom Attributes* de cada botón.

---

## 03 · Constancia con posición fija

[`03-constancia-posicion-fija`](03-constancia-posicion-fija)

Constancia de trabajo en A4 con elementos colocados en coordenadas exactas (mm desde la esquina superior izquierda).

**Antes de usarlo:** suba `logo.png` a *Shared Components → Static Application Files*.

**Qué observar en el diseño**

| Elemento | Dónde |
|---|---|
| Logo arriba a la izquierda | `{ "type": "imagen", "url": "#APP_FILES#logo.png", "width": 34, "x": 18, "y": 12 }` |
| Número de documento alineado con el logo | `{ "type": "texto", "text": "**{NRO_DOC}**", "align": "right", "y": 16 }` |
| Pie de página dibujado | logo pequeño en `y: 277`, línea vertical (`x1`…`y2`) y bloque de contacto en `x: 110, width: 80` |
| Firma centrada | `{ "type": "linea", "width": 70, "align": "center" }` |
| Fecha en letras | se arma en SQL (`fecha_txt`) |

Los elementos con `y` no empujan el resto del contenido.

**Configuración:** Formato **PDF** · Salida **Archivo**. Se genera desde un reporte, un PDF por fila:

```sql
select e.empno, e.ename, e.job,
       '<a href="javascript:void(0)" class="js-constancia" data-empno="' || e.empno || '">'
       || '<span class="fa fa-file-pdf-o" aria-hidden="true"></span> Constancia</a>' constancia
  from emp e
 order by e.ename
```

- Columna `CONSTANCIA`: *Escape special characters* = **No**.
- Acción Dinámica *Click*: *Selection Type* = **jQuery Selector**, *jQuery Selector* = `.js-constancia`, *Event Scope* = **Dynamic**.

`data-empno` llega como `:EMPNO` en `fuentes.sql`.

---

## 04 · Imagen desde BLOB

[`04-imagen-blob`](04-imagen-blob)

Ficha por empleado con su foto guardada en una columna BLOB.

**Antes de usarlo:** la tabla `EMP_FOTO` la crea [`00-tablas-emp-dept.sql`](00-tablas-emp-dept.sql). Cargue fotos **PNG o JPG** (por ejemplo con un *File Browse* de APEX que guarde en `emp_foto`).

**Qué observar**

- La columna `FOTO` es BLOB: el servidor la envía en base64.
- `{ "type": "imagen", "field": "FOTO", "width": 35 }` la toma del documento actual. Si el empleado no tiene foto, la sección se omite.
- `"columns": 1` en la `ficha` muestra un dato por renglón.

**Configuración:** Formato **PDF** o **Word** · Salida **ZIP** (una ficha por empleado) o **Archivo** con `data-empno`.

---

## 05 · Excel con varias hojas

[`05-excel-multihoja`](05-excel-multihoja)

Planilla pensada para Excel: un resumen y un detalle en **hojas separadas**. El mismo diseño también produce un PDF de dos páginas.

**Qué observar en el diseño**

| Elemento | Dónde |
|---|---|
| Hojas | `"xlsx": { "sheets": [ { "name": "Resumen", "sections": ["enc", "deptos"] }, { "name": "Detalle", "sections": ["detalle"] } ] }` |
| Secciones con `id` | `enc`, `deptos`, `aviso`, `salto`, `detalle` |
| Solo en PDF / Word | `aviso` (`alerta`) y `salto` usan `"formats"` |
| Encabezado agrupado | `"groups": [ { "cols": 3 }, { "label": "Asignación", "cols": 2 }, { "label": "Compensación", "cols": 3 } ]` |
| Columnas reutilizadas | `"@IDENT"` se expande con las tres columnas de `defs.IDENT` |
| Estilo reutilizado | `"cellStyle": "@VERDE"` |
| Tema propio | `"theme": { "primary": "#14532D", ... }` |
| Mensaje sin datos | `"emptyMessage"` |
| Filtro opcional | `:P5_DEPTNO` (ítem de página): si está vacío, trae todos |

En Excel, cada hoja con una sola tabla recibe autofiltro y encabezado inmovilizado; los totales son fórmulas `=SUM()`.

**Configuración:** Formato **Excel** · Salida **Archivo**. Con Formato **Todos** obtiene `planilla_todos_19_10_2026.zip` con el PDF, el Excel y el Word.

Si `P5_DEPTNO` cambia en pantalla, envíelo antes de consultar (ver la nota de **Ítems a enviar** en [API.md](../docs/API.md#2-atributos-de-la-acción-dinámica)).

---

## 06 · Plantilla Word

[`06-plantilla-word`](06-plantilla-word)

Llena [`plantilla.docx`](06-plantilla-word/plantilla.docx), un documento de Word normal con marcadores. Genera un documento por departamento con la lista de su equipo.

**Antes de usarlo:** suba `plantilla.docx` a *Static Application Files* (por ejemplo como `plantillas/equipo.docx`).

**Marcadores de la plantilla**

| Marcador | Origen |
|---|---|
| `{DNAME}`, `{LOC}` | Columnas de `DOCS` |
| `{EMPLEADOS\|int}`, `{SALARIOS\|money}` | Columnas de `DOCS` con formato |
| `{#EQUIPO}{ENAME}` … `{SAL\|money}{/EQUIPO}` | Fila de tabla que se repite por cada empleado (fuente `EQUIPO`, repartida por `DOC_KEY`) |
| `{TODAY}`, `{NOW}` | Fecha y hora |

Abra `plantilla.docx` en Word para ver dónde está cada marcador. Puede cambiar textos, letras, colores y la tabla: mientras cada marcador quede escrito de corrido, se sigue reconociendo.

**Configuración:** Formato **Word desde plantilla** · Salida **ZIP** (un `.docx` por departamento). Para un solo departamento, use un enlace con `data-deptno="20"` y Salida **Archivo**.

**Plantilla Word (URL):** en la versión 1.6.1 este atributo no reemplaza `#APP_FILES#`; arme la URL en *Initialization JavaScript Code*:

```js
function (o) { o.templateUrl = apex.env.APP_FILES + 'plantillas/equipo.docx'; return o; }
```

Del diseño solo se usan `fileName` y `batch`; el formato visual lo da la plantilla.

La plantilla del repositorio se genera con `npm run plantilla` (en `test/`).

---

## 07 · Gráficos y códigos

[`07-graficos-codigos`](07-graficos-codigos)

Resumen de planilla con las secciones nuevas de la versión 1.7.0:

| Qué | Cómo |
|---|---|
| Barras agrupadas con valores | `grafico` con `"chart": "bar"`, dos `series` y `"values": true` |
| Anillo con porcentajes | `grafico` con `"chart": "doughnut"` y `"values": "pct"` |
| Quiebre por departamento con subtotales | `tabla` con `"breakBy": "DNAME"`, `breakTitle` con `{COUNT}`, `breakLabel` y `totals` |
| QR | `codigo` con `"kind": "qr"` |
| Código de barras | `codigo` con `"kind": "code128"` |
| Marca de agua condicional | `"watermark": { "text": "BORRADOR", "when": "!PARAM.FINAL" }` |

La consulta `EMP` viene ordenada por `DNAME`: los quiebres agrupan filas consecutivas.

La marca de agua sale mientras no llegue el parámetro `FINAL`. Para la versión final, use un botón con `data-final="S"`.

**Configuración:** Formato **PDF**, **Excel** o **Word** · Salida **Archivo**. En Excel no hay marca de agua; los gráficos y códigos van como imagen y los subtotales como `=SUBTOTAL()`.

---

## 08 · Factura con columnas

[`08-factura-columnas`](08-factura-columnas)

Factura con las secciones de la versión 1.11.0. Usa solo `DUAL`: no necesita EMP / DEPT.

| Qué | Cómo |
|---|---|
| Cliente a la izquierda; código de barras y fecha a la derecha | `columnas` con `"widths": [60, 40]` |
| Monto en letras junto a los totales | `alerta` con `{DOC.TOTAL\|letras:BALBOA/BALBOAS}` y `ficha` en otra fila de `columnas` |
| Dos firmas en la misma línea | `columnas` de 50 / 50 con `espacio`, `linea` y `texto` |
| Firmas opcionales | `"when": "PARAM.FIRMAS != 'N'"` en la fila de firmas: un botón con `data-firmas="N"` las quita |

**Configuración:** Formato **PDF**, **Excel** o **Word** · Salida **Archivo**. PDF y Word se ven iguales; en Excel cada casilla ocupa su propio bloque de columnas.

