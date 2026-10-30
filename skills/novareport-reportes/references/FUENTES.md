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

### 3.1 Origen "Resolver"

Con **Origen** = `resolver` el navegador **solo envía el ID del reporte y los parámetros**; las fuentes SQL y el diseño nunca viajan desde el navegador. El plugin llama a la función configurada en **Función resolver**:

```sql
function resolver(p_id in varchar2, p_params in clob) return clob;
-- p_id:     ID del reporte (data-report del elemento, o o.report en Initialization Code)
-- p_params: {"NOMBRE": "valor", ...} tal como llega del navegador
```

La función valida acceso y parámetros (levanta un error si no corresponde) y devuelve:

```json
{ "sources": "--@DOCS\nselect ...",
  "layout":  { "sections": [] },
  "params":  { "EMPLEADO": 7, "DESDE": "2026-10-01", "CUENTA": "1001-22" },
  "types":   { "EMPLEADO": "number", "DESDE": "date", "CUENTA": "text" },
  "templateUrl": "opcional, para docx-template" }
```

| Bind en las fuentes | Valor en modo resolver |
|---|---|
| `:APP_*` | Valor de sesión |
| Nombre presente en `params` | Valor devuelto por la función: `number` → NUMBER, `date` (`YYYY-MM-DD`) → DATE, otro → VARCHAR2 |
| Cualquier otro (incluidos ítems de página) | `NULL` (no hay enlace automático de ítems) |

Los `params` devueltos llegan al diseño como `{PARAM.X}`. El protocolo AJAX agrega `x03` = ID y la respuesta incluye `layout`, `params` y `templateUrl`.

El plugin no crea ni exige tablas: cualquier función con este contrato sirve. Una implementación típica guarda las plantillas en una tabla, verifica que el reporte esté publicado y que el usuario tenga acceso (por roles), y valida cada parámetro (obligatorio, número, fecha, valor de lista). [novaReport Designer](../../../README.md#novareport-designer) trae una implementación completa de este tipo.

```javascript
// Initialization JavaScript Code: armar ID y parámetros; devolver false cancela
function (o) { o.report = 21; o.params = { CUENTA: $v('P5_CUENTA') }; return o; }
```

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
