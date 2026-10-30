# novaReport — PDF, Excel and Word for Oracle APEX

[![Version](https://img.shields.io/badge/version-1.17.0-1F4E79)](CHANGELOG.md)
[![APEX](https://img.shields.io/badge/Oracle%20APEX-26.1%2B-C74634)](#requirements)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> 🇵🇦 [Leer en español](README.md)

**novaReport** is an Oracle APEX **Dynamic Action plugin** that renders **PDF**, **styled Excel** and **Word** documents from **SQL queries** plus a **JSON layout**.

The server only runs the queries; the document is assembled in the browser with jsPDF, ExcelJS and docx. **No print server is required** (BI Publisher, AOP, ORDS print server), so it works on **Autonomous Database and APEX Free Tier**.

The detailed reference ([docs/API.md](docs/API.md), [docs/DISENO.md](docs/DISENO.md)) is in Spanish; the property names and code samples are the same in both languages.

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Your first report in 5 minutes](#your-first-report-in-5-minutes)
- [Concepts](#concepts)
- [Layout cheat sheet](#layout-cheat-sheet)
- [JavaScript API](#javascript-api)
- [Examples](#examples)
- [Testing without APEX](#testing-without-apex)
- [Security](#security)
- [Known issues and limitations](#known-issues-and-limitations)
- [novaReport Designer](#novareport-designer)
- [License and author](#license-and-author)

## Features

| | |
|---|---|
| **One layout, three formats** | The same JSON produces PDF, Excel (`.xlsx` with colors, `=SUM()` totals, autofilter, multiple sheets) and Word (editable `.docx`). |
| **Batches** | One file per document inside a **ZIP**, with an optional **summary** document; or every document **merged into a single file**. |
| **Declarative layout** | Header band, key/value card, tables with totals (sum, average, min, max, count), control breaks with subtotals, grouped headers and conditional styles, alerts, rich text (bold, italic, underline, strike-through, colors, 3 fonts), images (URL or **BLOB**), charts, **QR** and **Code 128**, watermark, lines and **absolutely positioned** elements. |
| **Tiles and grids** | Summary **tiles** (label + highlighted value), key/value cards in a **grid** with colored labels, and tables with borders and left- or right-aligned headers, identical in all three formats. |
| **Fillable forms** | Text, list and checkbox fields the recipient fills in: AcroForm in PDF, content controls in Word (*forms only* protection with a password) and validated cells in Excel (protected sheet). |
| **Columns** | **Side-by-side** cells (logo and details, customer and totals, signatures) that look the same in PDF and Word, and become column blocks in Excel. |
| **Logic in the layout** | Sections and columns shown **conditionally** (`when`), amounts **in words** (Spanish: `MIL DOSCIENTOS BALBOAS CON 50/100`) and value formats. |
| **Save on the server** | Besides delivering it, uploads the generated file to a process in your application to **archive it, email it or log the run**. |
| **Word templates** | Fills a `.docx` built in Word using `{FIELD}` tags and `{#TABLE}…{/TABLE}` loops. |
| **One file per row** | `data-*` attributes on the link or button become bind variables (`:EMPNO`). |
| **No schema objects** | Creates no tables or packages: it runs the queries you write. |
| **On-demand loading** | Each library is downloaded the first time it is needed, from a CDN or from your *Static Files*. |

## Requirements

- **Oracle APEX 26.1** or later (plugin API v2). For **APEX 23.2** use the [`plugin/apex-23.2/`](plugin/apex-23.2) variant; the JavaScript engine is the same.
- A modern browser (Chrome, Edge, Firefox, Safari).
- Access to `cdnjs.cloudflare.com` and `cdn.jsdelivr.net`, or the libraries served from your application ([how](docs/API.md#librerías-locales-sin-internet)).

## Installation

1. Download [`plugin/dynamic_action_plugin_com_novacode_novareport.sql`](plugin/dynamic_action_plugin_com_novacode_novareport.sql) (APEX 23.2: [`plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql`](plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql)).
2. In your application: **Shared Components → Plug-ins → Import**, pick the file and confirm.
3. The action **NovaCode Report (PDF / Excel / Word)** is now available in every Dynamic Action.

To upgrade, import the new version over the old one; existing actions keep their settings.

## Your first report in 5 minutes

Using the **EMP / DEPT** sample tables (run [`examples/00-tablas-emp-dept.sql`](examples/00-tablas-emp-dept.sql) or use *SQL Workshop → Utilities → Sample Datasets*):

**1. Button.** Create a button `EMPLOYEES_PDF` with *Action* = **Defined by Dynamic Action**.

**2. Dynamic Action.** *Click* event on the button; action **NovaCode Report (PDF / Excel / Word)**.

**3. SQL sources** (*Fuentes SQL*)

```sql
--@EMP
select e.ename, e.job, d.dname, e.hiredate, e.sal
  from emp e
  join dept d on d.deptno = e.deptno
 order by d.dname, e.ename
```

**4. Layout** (*Diseño (JSON)*)

```json
{
  "page": { "size": "letter", "orientation": "portrait" },
  "fileName": "employees_{TODAY}",
  "sections": [
    { "type": "header", "title": "Employees", "right": "Generated: {NOW}" },
    { "type": "tabla", "source": "EMP", "totals": ["SAL"], "totalsLabel": "Total", "columns": [
      { "col": "ENAME",    "label": "Name", "bold": true },
      { "col": "JOB",      "label": "Job" },
      { "col": "DNAME",    "label": "Department" },
      { "col": "HIREDATE", "label": "Hired", "fmt": "date" },
      { "col": "SAL",      "label": "Salary", "fmt": "money" } ],
      "rowStyle": [ { "when": "SAL >= 3000", "fill": "#E8F3EC" } ] }
  ],
  "footer": { "left": "Internal use", "right": "Page {PAGE} of {PAGES}" }
}
```

**5. Format** (*Formato*) = PDF · **Output** (*Salida*) = File. Run the page and click the button: the PDF opens in a new tab.

Switch **Format** to Excel or Word and the same layout produces `employees_19_10_2026.xlsx` or `.docx`.

## Concepts

### SQL sources

One or more queries, each one named with a `--@NAME` line. The layout refers to them by that name in `"source"`.

```sql
--@CUSTOMER
select name, tax_id from customers where id = :P10_ID
--@MOVES
select move_date, detail, amount from moves where customer_id = :P10_ID order by move_date
```

| Rule | Detail |
|---|---|
| Flags | `--@NAME summary` runs only when the output is `zip` (batch summary). |
| Column names | Upper-case aliases: `e.ename` → `ENAME`. |
| Item binds | APEX page and application items (`:P10_ID`, `:APP_USER`) are bound from session state. |
| Other binds | Taken from the triggering element's `data-*` attributes, or `NULL`. |
| `DATE` | Sent as `DD/MM/YYYY` text, without time (real dates in Excel). |
| `BLOB` | Sent as base64, for `imagen` sections. |

### Documents (`DOCS` + `DOC_KEY`)

A source named **`DOCS`** defines the documents: **one row, one document**. Every other source that has a `DOC_KEY` column is split per document; sources without it are shared.

```sql
--@DOCS
select e.empno doc_key, e.ename, e.sal from emp e
--@HISTORY
select h.empno doc_key, h.change_date, h.position from history h
```

### Parameters from the element: `data-*`

```html
<a href="javascript:void(0)" class="js-letter" data-empno="7788">SCOTT's PDF</a>
<button class="js-letter" data-output="zip">All letters (ZIP)</button>
```

`data-empno` becomes `:EMPNO` in SQL and `{PARAM.EMPNO}` in the layout (`data-id-carga` → `ID_CARGA`). `data-format` and `data-output` override the format and output. Use a *jQuery Selector* trigger (`.js-letter`) with *Event Scope* = **Dynamic**.

### Format and output

| Output | One document | Several documents |
|---|---|---|
| `file` | One file | ZIP |
| `zip` | ZIP | ZIP + summary |
| `merge` | One file | One file with all documents (PDF pages, Word sections, one Excel sheet per document) |

**Format**: `pdf`, `xlsx`, `docx`, `docx-template` (Word from a template) or `all` (the three of them, in a ZIP).

### Action attributes

| Attribute (Spanish label) | Purpose |
|---|---|
| **Fuentes SQL** | The queries (`--@NAME`). |
| **Diseño (JSON)** | The layout, or the name of a global JS variable (`myLayouts.letter`). |
| **Origen** | `Atributos` (default), `Consulta` (layout and/or SQL from a table) or `Resolver` (PL/SQL function). |
| **Consulta del reporte** | With origin `Consulta`: `select layout, sql_text as sources from my_reports where code = :P5_REPORT`. No 4000-character limit ([docs/API.md §3.2](docs/API.md#32-origen-consulta)). |
| **Formato** | `pdf`, `xlsx`, `docx`, `docx-template`, `all`. |
| **Salida** | `file`, `zip`, `merge`. |
| **Ítems a enviar** | Items saved to session state before querying ([see note](#known-issues-and-limitations)). |
| **PDF de un documento** | Open in a new tab (with a waiting screen) or download. |
| **Plantilla Word (URL)** | `.docx` used by `docx-template`. |
| **Mensaje de espera** | Waiting-screen text. |
| *Initialization JavaScript Code* | Adjust options before running (format chosen on screen, extra parameters, hooks). |

## Layout cheat sheet

```json
{
  "page": { "size": "letter | legal | a4", "orientation": "portrait | landscape", "margin": 8, "font": "helvetica | times | courier",
            "theme": { "primary": "#1F4E79", "headText": "#FFFFFF", "zebra": "#F5F7FA", "totals": "#E6ECF2", "fontSize": 7 } },
  "title": "PDF title", "fileName": "statement_{DOC.CUSTOMER}", "emptyMessage": "No data.",
  "sections": [ ],
  "footer": { "left": "text", "right": "Page {PAGE} of {PAGES}" },
  "defs": { }, "xlsx": { "sheets": [ { "name": "Data", "sections": ["id1"] } ] },
  "batch": { "zipName": "batch_{TODAY}", "mergeName": "all", "chunkSize": 5, "maxDocs": 3000, "summary": { "sections": [ ] } },
  "watermark": { "text": "DRAFT", "when": "!PARAM.FINAL" },
  "save": { "process": "MY_SAVE_PROCESS", "mode": "only" }
}
```

| Section | Purpose | Key properties |
|---|---|---|
| `header` | Colored title band | `title`, `subtitle`, `right`, `size`, `subtitleSize`, `rightSize`, `font`, `fill`, `color` |
| `tarjetas` | Summary tiles: small label + highlighted value | `source`, `fields[{label, value, fmt, map, when, color}]`, `columns`, `fill`, `accent`, `labelColor`, `valueColor`, `size` |
| `ficha` | Label / value pairs | `source`, `columns`, `fields[{label, value, fmt, map, when, align, bold, color, fill, span, labelPosition, labelSize, labelColor, labelFill, labelBold, labelCase, labelAlign}]` (`{empty: true}` = gap), `grid`, `labelWidths`, `labelFill`, `labelColor`, `valueColor`, `labelPosition` (`left`, `top`, `none`) |
| `tabla` | Table | `source`, `columns[{col, label, fmt, align, bold, color, width, map, value, cellStyle, when}]`, `totals` (`sum`/`avg`/`min`/`max`/`count`), `breakBy`, `rowStyle`, `groups`, `filter`, `title`, `emptyText`, `headAlign`, `grid`, `totalsColor` |
| `formulario` | Fillable fields | `fields[{name, label, input (text/multiline/list/checkbox), value, options, optionsFrom, maxLength, lines, readOnly, span}]` (`{empty: true}` = gap), `columns`; `form.protect` / `form.password` |
| `alerta` | Colored banner when a condition holds | `source`, `when`, `each`, `text`, `color` |
| `texto` | Rich-text paragraphs | `text`, `align`, `size`, `lineHeight`, `font`, `color`, `x`/`y` (PDF) |
| `imagen` | PNG/JPG from URL or BLOB | `url` or `field`, `width`, `height`, `align`, `x`/`y` (PDF) |
| `linea` | Horizontal or positioned line | `width`, `align`, `thickness`, `color`, `x1…y2` (PDF) |
| `grafico` | Bar, line, area, pie or doughnut chart | `source`, `chart`, `category`, `series`, `colors`, `values`, `width`, `height` |
| `codigo` | QR or Code 128 | `kind`, `value`, `size`, `height`, `align` |
| `columnas` | 1–3 side-by-side cells | `cols[[sections]]`, `widths`, `colGap` |
| `espacio` / `salto` | Vertical space / page break | `height` |

**Templates:** `{COL}`, `{SOURCE.COL}`, `{DOC.COL}`, `{PARAM.X}`, `{ITEM.P1_X}`, `{NOW}`, `{TODAY}`, `{PAGE}`/`{PAGES}` (footer), `{COL|format}`.
**Formats:** `money`, `num:N`, `int`, `pct`, `date`, `upper`, `lower`, `yn` (`Y`/`S` → Sí), `letras` / `letras:BALBOA/BALBOAS` (amount in Spanish words).
**Any section:** `when` (show only if the condition holds), `formats` (`["pdf", "docx"]`).
**Conditions:** `COL == 'X'`, `!=`, `>`, `<`, `>=`, `<=`, `COL`, `!COL`, joined with `&&` / `||`.
**Rich text:** `**bold**`, `*italic*`, `***both***`, `~~strike~~`, `++underline++`, `[f=times]font[/f]`, `[c=#AA1E1E]color[/c]`.

Every property, default value and per-format behavior is listed in [docs/DISENO.md](docs/DISENO.md).

## JavaScript API

```js
// Run a report from your own code (same options the Dynamic Action builds)
novaReport.run({ ajaxIdentifier: '...', layout: myLayouts.letter, format: 'pdf', output: 'zip',
                 params: { EMPNO: '7788' } });

// Build only (no AJAX, no UI): useful for tests or custom delivery
novaReport.build({ layout, format: 'xlsx' }, { EMP: { cols: [{ name: 'ENAME', type: 'VARCHAR2' }], rows: [['KING']] } })
  .then(r => console.log(r.name, r.data));

// Serve libraries locally
novaReport.libs.jspdf.url = '#APP_FILES#lib/jspdf.umd.min.js';
```

*Initialization JavaScript Code* of the action:

```js
function (o) {
  o.format = apex.item('P5_FORMAT').getValue() || o.format;
  o.hooks = { pdfCell: function (h, row, col) { if (row.BALANCE < 0) { h.cell.styles.textColor = [170, 30, 30]; } } };
  return o;
}
```

Events on `document`: `novareport-start`, `novareport-progress`, `novareport-end`, `novareport-error`. Full reference, AJAX protocol, error messages and limits: [docs/API.md](docs/API.md).

## Examples

| Example | Shows |
|---|---|
| [01 · Employee list](examples/01-listado-empleados) | Header, two tables with totals, row and cell styles. |
| [02 · Letters in a ZIP](examples/02-cartas-zip) | Rich-text letter per employee, ZIP with summary or merged PDF. |
| [03 · Fixed-position certificate](examples/03-constancia-posicion-fija) | Logo, document number and footer at exact coordinates; one PDF per row. |
| [04 · Image from BLOB](examples/04-imagen-blob) | Photo stored in a BLOB column. |
| [05 · Multi-sheet Excel](examples/05-excel-multihoja) | Sheets by section `id`, grouped headers, reusable `defs`. |
| [06 · Word template](examples/06-plantilla-word) | A `.docx` built in Word with tags and a repeating table row. |
| [07 · Charts and codes](examples/07-graficos-codigos) | Bar and doughnut charts, a table with control breaks and subtotals, QR, Code 128 and a conditional watermark. |
| [08 · Invoice with columns](examples/08-factura-columnas) | Customer and barcode side by side, amount in words next to the totals and two signatures on one line. |
| [09 · Credit cover sheet](examples/09-cover-sheet) | Summary tiles, grid cards, bordered tables with left-aligned headers, colored totals and signatures. |

## Testing without APEX

```bash
cd test
npm install
npm test            # src/novareport.js     → test/out/
npm run test:min    # src/novareport.min.js (the file shipped in the plugin)
```

Requires Node 18 or later.

## Security

- **Queries run on the server**; their text never reaches the browser.
- **`data-*` values come from the browser and can be tampered with.** Validate access in every query (filter by `:APP_USER` or by protected session items).
- A `data-*` attribute cannot override an APEX item with the same name: items always use session state.

## Known issues and limitations

| Topic | Detail | Workaround |
|---|---|---|
| **Ítems a enviar** (1.6.1–1.10.0) | The attribute value (`P5_A,P5_B`) was passed as a jQuery selector, so the items were not submitted. | Fixed in 1.11.0. Older versions: `function (o) { if (o.items) { o.items = o.items.split(','); } return o; }` |
| **Plantilla Word (URL)** (1.6.1–1.10.0) | `#APP_FILES#` was not replaced. | Fixed in 1.11.0. Older versions: `function (o) { o.templateUrl = apex.env.APP_FILES + 'templates/letter.docx'; return o; }` |
| PDF fonts | Helvetica, Times and Courier lack some symbols, such as **₡**. | TTF font support is planned. |
| Dates | `DATE` columns travel as `DD/MM/YYYY`, without time. | `to_char(d, 'DD/MM/YYYY HH24:MI')` |
| PDF forms | Protection is not encrypted and every field uses Helvetica at the size of the first form. | Use Word or Excel for a password-protected form. |
| Word password | 1 to 15 ASCII characters (no accents). | |
| Size | 250,000 rows per request; batches and ZIPs are built in browser memory. | Split very large batches. |
| UI texts | Waiting screen, progress and error messages are in Spanish. | |

## novaReport Designer

**novaReport Designer** is an APEX application built on this plugin to design reports **without writing JSON**: a drag-and-drop canvas with PDF, Excel and Word preview, templates organized in folders, role-based publishing, a **My reports** page for end users (with parameters and favorites) and **Saved documents**.

The Designer is not part of this repository. The layouts it produces are the same JSON documented in [docs/DISENO.md](docs/DISENO.md), so anything built in the Designer runs on the plugin and vice versa. If you are interested in using it, open an *issue* in this repository.

## License and author

[MIT](LICENSE). Third-party libraries keep their own licenses: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

**Daniel Ramírez** — NovaCode, Panama · Oracle ACE Associate.
Issues and pull requests are welcome.
