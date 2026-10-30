---
name: novareport-reportes
description: Desarrollar reportes novaReport (plugin Oracle APEX COM.NOVACODE.NOVAREPORT) sin acceso a la base de datos — escribir fuentes.sql (--@FUENTE), diseno.json (secciones PDF/Excel/Word) y datos.json de prueba, y validarlos offline. Usar cuando pidan un reporte, carta, constancia, factura, estado de cuenta o planilla con novaReport.
---

# Desarrollo de reportes novaReport sin base de datos

novaReport es un plugin de Acción Dinámica de Oracle APEX. El servidor **solo ejecuta las consultas** (Fuentes SQL) y devuelve filas; el navegador aplica el **diseño JSON** y genera PDF, Excel (.xlsx) o Word (.docx). Un mismo diseño sirve para los tres formatos.

Tú no tienes acceso a la base de datos. Trabajas contra un **contrato de columnas** (qué fuentes existen y qué columnas trae cada una) y lo pruebas con datos inventados. El usuario ejecuta el SQL real en APEX.

Referencias completas (léelas cuando necesites una propiedad que no está aquí):
- `references/DISENO.md` — todas las secciones, propiedades, formatos y condiciones del diseño.
- `references/FUENTES.md` — formato de Fuentes SQL, tipos, binds, `DOCS`/`DOC_KEY`, `data-*`, salidas, seguridad.
- `plantilla/` — ejemplo completo (factura) con `fuentes.sql`, `diseno.json` y `datos.json`.

**No inventes propiedades.** Si algo no está en `references/DISENO.md`, no existe. Las propiedades desconocidas se ignoran en silencio y el reporte sale distinto a lo esperado.

---

## 1. Entregables

Por cada reporte, una carpeta con:

| Archivo | Contenido | Dónde va en APEX |
|---|---|---|
| `fuentes.sql` | Consultas con encabezado `--@NOMBRE` | Atributo **Fuentes SQL** |
| `diseno.json` | Diseño | Atributo **Diseño (JSON)** (o variable global si pasa de 4000 caracteres) |
| `datos.json` | Datos de prueba con **exactamente** las columnas de `fuentes.sql` | Solo para probar offline |
| `LEEME.md` | Configuración de la Acción Dinámica, binds/`data-*` usados, supuestos sobre tablas | Para el usuario |

## 2. Flujo de trabajo

1. **Pide el modelo de datos** si no lo tienes: tablas, columnas y tipos (un `DESC tabla`, el DDL, o un ejemplo de filas). No adivines nombres de tablas ni columnas. Si el usuario no puede darlos, escribe el SQL con nombres marcados como supuesto (`-- SUPUESTO: tabla CLIENTES(id, nombre)`) y lístalos en `LEEME.md`.
2. **Define el contrato**: lista de fuentes y, por cada una, alias de columnas y tipo (`NUMBER`, `DATE`, `VARCHAR2`, `BLOB`). Decide si hay `DOCS` (un documento por fila) y qué fuentes se reparten por `DOC_KEY`.
3. **Escribe `fuentes.sql`** siguiendo las reglas de la §3.
4. **Escribe `datos.json`** con las mismas fuentes y alias (§5). Incluye casos borde: valores nulos, textos largos, negativos, varias filas por documento, una fuente vacía si el diseño usa `emptyText`/`hideEmpty`.
5. **Escribe `diseno.json`** siguiendo la §4.
6. **Prueba** (§6) y corrige hasta 0 avisos y 0 errores. Si puedes ver archivos, abre el PDF y revisa el resultado visualmente.
7. **Escribe `LEEME.md`** (§7).

## 3. Reglas de Fuentes SQL

```sql
-- Texto antes de la primera fuente: se ignora (comentarios).
--@DOCS
select c.id_cliente doc_key, c.nombre, c.saldo, c.fecha_corte
  from clientes c
 where (:ID_CLIENTE is null or c.id_cliente = :ID_CLIENTE)
--@MOVS
select m.id_cliente doc_key, m.fecha, m.descripcion, m.monto
  from movimientos m
 where m.id_cliente in (select c.id_cliente from clientes c where :ID_CLIENTE is null or c.id_cliente = :ID_CLIENTE)
 order by m.id_cliente, m.fecha
--@EMPRESA
select nombre, ruc from empresa
--@RESUMEN summary
select count(*) clientes, sum(saldo) saldo_total from clientes
```

- Cada fuente empieza con `--@NOMBRE` en su propia línea. El nombre va en mayúsculas en el diseño (`"source": "MOVS"`).
- `summary` después del nombre: la fuente solo corre cuando la salida es `zip` (para `batch.summary`).
- **Siempre alias explícitos** y sin comillas dobles: llegan en mayúsculas (`c.nombre` → `NOMBRE`). Ese alias es lo que usa el diseño.
- **`DOCS` debe traer `DOC_KEY`.** Una fila de `DOCS` = un documento. Otra fuente con `DOC_KEY` se reparte por documento; sin `DOC_KEY` se comparte entera en todos.
- **Filtra las fuentes hijas igual que `DOCS`**: el reparto por `DOC_KEY` ocurre en el navegador, así que una fuente hija sin filtro trae toda la tabla.
- `DATE` llega como `DD/MM/YYYY` **sin hora**. Si se necesita la hora: `to_char(f, 'DD/MM/YYYY HH24:MI') alias` (llega como texto).
- Fechas en texto con formato propio (`15-Oct-26`, `17 de octubre de 2026`): `to_char` en SQL; no hay formato de fecha configurable en el diseño.
- `NUMBER` llega como número: no lo conviertas a texto con `to_char` si se va a sumar, formatear o exportar a Excel.
- `BLOB` (PNG/JPG) llega en base64, para `imagen` con `field`.
- Binds: ítems de página/aplicación (`:P5_ID`, `:APP_USER`) toman el valor de sesión. Cualquier otro (`:ID_CLIENTE`) viene del atributo `data-id-cliente` del elemento que se pulsó, siempre como **texto** o `NULL`. Usa el patrón `(:X is null or col = :X)` para que la misma acción sirva para uno o todos.
- **Seguridad**: los `data-*` los puede alterar el usuario. Si el reporte muestra datos por cliente, cuenta o empleado, valida acceso en el SQL (`and exists (select 1 from accesos a where a.usuario = :APP_USER and ...)`).
- Con `breakBy` en una tabla, **ordena la consulta por la columna de quiebre**.
- Máximo 250,000 filas sumando todas las fuentes. Agrega en SQL lo que se pueda (totales, resúmenes) en lugar de traer el detalle.
- Sin `;` ni `/` necesarios (se eliminan). Oracle 19c o superior: usa sintaxis compatible con 19c salvo que el usuario diga otra cosa.

## 4. Reglas del diseño JSON

- **JSON estricto**: sin comentarios, sin comas finales, comillas dobles. Valida con `JSON.parse`.
- Medidas en **mm**, letras en **pt**. Página `letter` por defecto; margen 8 mm (PDF).
- Estructura: `page`, `title`, `fileName`, `emptyMessage`, `watermark`, `sections`, `footer`, `defs`, `xlsx`, `batch`, `save`, `form`.
- Secciones disponibles: `header`, `tarjetas`, `ficha`, `tabla`, `alerta`, `texto`, `imagen`, `grafico`, `codigo`, `formulario`, `linea`, `columnas`, `espacio`, `salto`. No hay otras.
- Plantillas `{...}`: `{COL}` (fila de la sección → documento → parámetro), `{FUENTE.COL}` (primera fila de otra fuente), `{DOC.COL}`, `{PARAM.X}`, `{COL|money}`, `{NOW}`, `{TODAY}`. `{PAGE}`/`{PAGES}` **solo en `footer`**. `{COUNT}` solo en `totalsLabel`, `breakTitle`, `breakLabel`.
- Formatos (`fmt` o `|fmt`): `money`, `num:N`, `int`, `pct`/`pct:N` (no multiplica por 100), `date`, `upper`, `lower`, `yn`, `letras`, `letras:SINGULAR/PLURAL`. Nada más.
- Usa `fmt` en la propiedad cuando el valor es un solo marcador (`"value": "{SALDO}", "fmt": "money"`): así Excel recibe un número real. `{SALDO|money}` dentro de un texto queda como texto.
- Condiciones (`when`, `filter`, `rowStyle`, `cellStyle`): `==`, `!=`, `>`, `<`, `>=`, `<=`, `COL` (tiene valor), `!COL`, `&&`, `||`. **Sin paréntesis.** Literales entre comillas simples: `"ESTADO == 'A'"`. Parámetros: `"PARAM.FINAL == 'S'"`.
- `when` en una sección o columna se evalúa **por documento**; en `alerta`, por fila de su `source`.
- `ficha`, `tarjetas`, `codigo` y `alerta` (sin `each`) toman la **primera fila** de su `source` (o del documento si no hay `source`).
- `tabla` sin `columns` muestra todas las columnas: siempre define `columns` en reportes finales.
- `columnas` (lado a lado) solo admite dentro: `ficha`, `texto`, `imagen`, `codigo`, `alerta`, `linea`, `tabla`, `grafico`, `espacio`. La fila no se parte entre páginas: no metas tablas largas dentro.
- Posición fija (`x`, `y`) solo funciona en PDF. Úsala solo si el usuario pide un formato preimpreso o coordenadas exactas.
- Imágenes: `"url": "#APP_FILES#logo.png"` (PNG o JPG; no SVG, GIF ni WEBP). Indica en `LEEME.md` qué archivo hay que subir a *Static Application Files*.
- Repetición: mueve bloques repetidos a `defs` y referencia con `"@NOMBRE"` (arreglos se insertan en el lugar).
- Excel: con `xlsx.sheets` las secciones se referencian por `id`; dale `id` a cada sección que vaya en una hoja. `linea` y `watermark` no aplican en Excel; usa `"formats": ["pdf", "docx"]` para secciones que solo tengan sentido impresas (`salto`, `alerta` decorativas).
- Paleta por `page.theme` (`primary`, `headText`, `zebra`, `totals`, `muted`, `fontSize`, `group`) antes que colores sueltos en cada sección.
- Textos de interfaz en el idioma del usuario. Montos en Panamá: `B/.` en la etiqueta (`"label": "Total B/."`), no dentro del valor.

### Elegir la sección

| Necesidad | Sección |
|---|---|
| Título con banda de color | `header` |
| Resumen de 3–6 indicadores arriba | `tarjetas` |
| Datos de un registro (etiqueta: valor) | `ficha` (`grid: true` para cuadrícula) |
| Listado, detalle, plan de pagos | `tabla` (`totals`, `breakBy`, `groups`, `rowStyle`) |
| Mensaje condicional destacado | `alerta` |
| Carta, párrafos, cláusulas | `texto` (`**negrita**`, `*cursiva*`, `[c=#hex]…[/c]`) |
| Logo, foto | `imagen` |
| Barras, líneas, circular | `grafico` |
| QR, código de barras | `codigo` |
| Campos que el destinatario llena | `formulario` |
| Emisor/cliente, firmas en línea | `columnas` |
| Firma | `espacio` + `linea` + `texto` centrado |
| Otra página | `salto` |
| Word con formato exacto hecho por el cliente | formato `docx-template` (ver `references/DISENO.md`) |

## 5. `datos.json` (datos de prueba)

Mismo nombre de fuentes y alias que `fuentes.sql`, en mayúsculas. Formato simple: arreglo de objetos por fuente. `_params` simula los `data-*` / parámetros.

```json
{
  "_params": { "ID_CLIENTE": "15" },
  "DOCS":  [ { "DOC_KEY": 15, "NOMBRE": "Ana Pérez", "SALDO": 1250.5, "FECHA_CORTE": "31/10/2026" } ],
  "MOVS":  [ { "DOC_KEY": 15, "FECHA": "02/10/2026", "DESCRIPCION": "Pago", "MONTO": -200 } ],
  "EMPRESA": [ { "NOMBRE": "NovaCode, S.A.", "RUC": "155771259-2-2025" } ]
}
```

Tipos inferidos: número JSON → `NUMBER`; texto `DD/MM/YYYY` → `DATE`; lo demás → `VARCHAR2`. Para forzar tipos (p. ej. `BLOB`) usa el formato del servidor: `"FOTOS": { "cols": [{"name":"DOC_KEY","type":"NUMBER"},{"name":"FOTO","type":"BLOB"}], "rows": [[1,"<base64>"]] }`.

## 6. Probar offline

Requiere el repositorio novareport-oss con `cd test && npm install` hecho.

```bash
node skills/novareport-reportes/scripts/probar.js <carpeta> [pdf,xlsx,docx] [file|zip|merge]
# fuera del repositorio:
NOVAREPORT_HOME=/ruta/novareport-oss node probar.js <carpeta>
```

Genera los archivos en `<carpeta>/out/` y avisa de:
- `source` que no existe en `datos.json`;
- `{COL}`, `col`, `totals`, `breakBy`, `category`, `field` y columnas en condiciones que no existen;
- `@NOMBRE` sin `defs`, `xlsx.sheets` con `id` inexistente, `DOCS` sin `DOC_KEY`.

Criterio de terminado: **0 avisos, 0 errores** en los tres formatos (o en los que el reporte use). Un aviso de una columna que sí existe en la BD significa que `datos.json` no refleja `fuentes.sql`: corrige `datos.json`, no lo ignores.

Sin Node: revisa a mano que cada `source`, `{COL}` y `col` del diseño exista como alias en `fuentes.sql`.

## 7. `LEEME.md` del reporte

Incluye solo lo necesario para instalarlo:

1. **Acción Dinámica**: evento y elemento (botón / enlace con selector jQuery y *Event Scope* = Dynamic), acción *NovaCode Report*, **Formato** (`pdf`, `xlsx`, `docx`, `docx-template`, `all`), **Salida** (`file`, `zip`, `merge`), **Ítems a enviar**.
2. **Parámetros**: cada bind no-ítem y el `data-*` que lo alimenta (`:ID_CLIENTE` ← `data-id-cliente`). Si es un enlace por fila, la columna HTML del reporte (con *Escape special characters* = No).
3. **Archivos estáticos** a subir (logos, plantilla .docx).
4. **Supuestos** sobre tablas/columnas que el usuario debe confirmar.
5. Si el diseño pasa de 4000 caracteres: cómo declararlo como variable global (`var misDisenos = { estado: {...} };` en *Function and Global Variable Declaration*) y qué escribir en el atributo (`misDisenos.estado`).

Notas de versión que conviene incluir cuando aplique (plugin 1.6.1 a 1.8.0):
- **Ítems a enviar** no se envían: agregar en *Initialization JavaScript Code* `function (o) { if (o.items) { o.items = o.items.split(','); } return o; }`.
- **Plantilla Word (URL)** no resuelve `#APP_FILES#`: `function (o) { o.templateUrl = apex.env.APP_FILES + 'plantillas/x.docx'; return o; }`.

## 8. Errores frecuentes

| Síntoma | Causa |
|---|---|
| Campo vacío en el documento | Alias distinto al del diseño (`{NOMBRE_CLIENTE}` vs `NOMBRE`), o la columna está en otra fuente sin `source`/`{FUENTE.COL}`. |
| Todos los documentos muestran el mismo detalle | La fuente hija no trae `DOC_KEY`. |
| Un documento trae filas de otros | `DOC_KEY` de la hija no coincide en tipo/valor con el de `DOCS`. |
| Subtotales repetidos o mezclados | Consulta no ordenada por `breakBy`. |
| Excel con montos como texto | Se usó `{X|money}` dentro de texto o `to_char` en SQL; usar `fmt` y dejar `NUMBER`. |
| Fecha sin hora | `DATE` llega sin hora; usar `to_char` en SQL. |
| `Diseño inválido` | JSON con comentarios o comas finales. |
| Condición siempre falsa | Paréntesis, comillas dobles mal escapadas o literal sin comillas (`ESTADO == A`). |
| Imagen no sale | SVG/GIF/WEBP, o archivo no subido a *Static Application Files*. |
