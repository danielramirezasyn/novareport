# novaReport — PDF, Excel y Word para Oracle APEX

[![Versión](https://img.shields.io/badge/versión-1.11.0-1F4E79)](CHANGELOG.md)
[![APEX](https://img.shields.io/badge/Oracle%20APEX-26.1%2B-C74634)](#requisitos)
[![Licencia](https://img.shields.io/badge/licencia-MIT-green)](LICENSE)

> 🇺🇸 [Read in English](README.en.md)

**novaReport** es un plugin de **Acción Dinámica** para Oracle APEX que genera **PDF**, **Excel con estilos** y **Word** a partir de **consultas SQL** y un **diseño en JSON**.

El servidor solo ejecuta las consultas; el documento se arma en el navegador con jsPDF, ExcelJS y docx. Por eso **no necesita servidor de impresión** (BI Publisher, AOP, ORDS print server) y funciona en **Autonomous Database y APEX Free Tier**.

---

## Contenido

- [Qué hace](#qué-hace)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Primer reporte en 5 minutos](#primer-reporte-en-5-minutos)
- [Conceptos](#conceptos)
- [Ejemplos](#ejemplos)
- [Documentación](#documentación)
- [Probar sin APEX](#probar-sin-apex)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Seguridad](#seguridad)
- [Problemas conocidos y limitaciones](#problemas-conocidos-y-limitaciones)
- [novaReport Designer](#novareport-designer)
- [Licencia y autor](#licencia-y-autor)

## Qué hace

| | |
|---|---|
| **Un diseño, tres formatos** | El mismo JSON produce PDF, Excel (`.xlsx` con colores, totales con `=SUM()`, autofiltro, varias hojas) y Word (`.docx` editable). |
| **Lotes** | Un archivo por documento dentro de un **ZIP**, con un documento de **resumen** opcional; o todos los documentos **unidos en un solo archivo**. |
| **Diseño declarativo** | Encabezado, ficha de datos, tablas con totales (suma, promedio, mínimo, máximo, conteo), quiebres con subtotales, encabezados agrupados y estilos condicionales, alertas, texto enriquecido (negrita, cursiva, subrayado, tachado, colores, 3 letras), imágenes (URL o **BLOB**), gráficos, **QR** y **Code 128**, marca de agua, líneas y elementos en **posición fija**. |
| **Columnas** | Casillas **lado a lado** (logo y datos, cliente y totales, firmas) que se ven igual en PDF y Word, y como bloques de columnas en Excel. |
| **Lógica en el diseño** | Secciones y columnas que aparecen **según condiciones** (`when`), montos **en letras** (`MIL DOSCIENTOS BALBOAS CON 50/100`) y formatos de valor. |
| **Guardar en el servidor** | Además de entregarlo, sube el archivo generado a un proceso de su aplicación para **archivarlo, enviarlo por correo o registrar la ejecución**. |
| **Plantillas Word** | Llena un `.docx` hecho en Word con `{CAMPO}` y bucles `{#TABLA}…{/TABLA}`. |
| **Un archivo por fila** | Los atributos `data-*` del enlace o botón se convierten en binds (`:EMPNO`). |
| **Sin objetos propios** | No crea tablas ni paquetes: ejecuta las consultas que usted define. |
| **Carga bajo demanda** | Cada librería se descarga solo la primera vez que se necesita, desde CDN o desde sus *Static Files*. |

## Requisitos

- **Oracle APEX 26.1** o superior (API de plugins v2).
- Navegador moderno (Chrome, Edge, Firefox, Safari).
- Salida a `cdnjs.cloudflare.com` y `cdn.jsdelivr.net`, o las librerías servidas desde la aplicación ([cómo](docs/API.md#librerías-locales-sin-internet)).

## Instalación

1. Descargue [`plugin/dynamic_action_plugin_com_novacode_novareport.sql`](plugin/dynamic_action_plugin_com_novacode_novareport.sql).
2. En su aplicación: **Shared Components → Plug-ins → Import**, seleccione el archivo y confirme.
3. En cualquier Acción Dinámica aparecerá la acción **NovaCode Report (PDF / Excel / Word)**.

Para actualizar, importe la versión nueva sobre la anterior: las acciones existentes conservan su configuración.

## Primer reporte en 5 minutos

Con las tablas de ejemplo **EMP / DEPT** (ejecute [`examples/00-tablas-emp-dept.sql`](examples/00-tablas-emp-dept.sql) o use *SQL Workshop → Utilities → Sample Datasets*):

**1. Botón.** Cree un botón `EMPLEADOS_PDF` con *Action* = **Defined by Dynamic Action**.

**2. Acción Dinámica.** Evento *Click* sobre el botón; acción **NovaCode Report (PDF / Excel / Word)**.

**3. Fuentes SQL**

```sql
--@EMP
select e.ename, e.job, d.dname, e.hiredate, e.sal
  from emp e
  join dept d on d.deptno = e.deptno
 order by d.dname, e.ename
```

**4. Diseño (JSON)**

```json
{
  "page": { "size": "letter", "orientation": "portrait" },
  "fileName": "empleados_{TODAY}",
  "sections": [
    { "type": "header", "title": "Empleados", "right": "Generado: {NOW}" },
    { "type": "tabla", "source": "EMP", "totals": ["SAL"], "columns": [
      { "col": "ENAME",    "label": "Nombre", "bold": true },
      { "col": "JOB",      "label": "Puesto" },
      { "col": "DNAME",    "label": "Departamento" },
      { "col": "HIREDATE", "label": "Ingreso", "fmt": "date" },
      { "col": "SAL",      "label": "Salario", "fmt": "money" } ],
      "rowStyle": [ { "when": "SAL >= 3000", "fill": "#E8F3EC" } ] }
  ],
  "footer": { "left": "Uso interno", "right": "Página {PAGE} de {PAGES}" }
}
```

**5. Formato** = PDF · **Salida** = Archivo. Ejecute la página y presione el botón: el PDF se abre en una pestaña nueva.

Cambie **Formato** a *Excel* o *Word* y el mismo diseño genera `empleados_19_10_2026.xlsx` o `.docx`.

## Conceptos

### Fuentes SQL

Una o varias consultas, cada una con un nombre `--@NOMBRE`. El diseño las usa por ese nombre en `"source"`.

```sql
--@CLIENTE
select nombre, ruc from clientes where id = :P10_ID
--@MOVIMIENTOS
select fecha, detalle, monto from movimientos where cliente_id = :P10_ID order by fecha
```

Los ítems de APEX (`:P10_ID`, `:APP_USER`) se enlazan solos. Detalle completo en [API.md §3](docs/API.md#3-fuentes-sql).

### Documentos (`DOCS` + `DOC_KEY`)

Una fuente llamada **`DOCS`** define los documentos: **una fila, un documento**. Las demás fuentes que tengan la columna `DOC_KEY` se reparten por documento.

```sql
--@DOCS
select e.empno doc_key, e.ename, e.sal from emp e
--@HISTORIAL
select h.empno doc_key, h.fecha, h.cargo from historial h
```

Con salida **ZIP** obtiene un archivo por empleado; con **Un solo archivo**, todos en un PDF. Ver [API.md §4](docs/API.md#4-documentos-docs-y-doc_key).

### Parámetros desde el elemento: `data-*`

```html
<a href="javascript:void(0)" class="js-carta" data-empno="7788">PDF de SCOTT</a>
<button class="js-carta" data-output="zip">Todas las cartas (ZIP)</button>
```

`data-empno` llega como `:EMPNO` en el SQL y como `{PARAM.EMPNO}` en el diseño. `data-format` y `data-output` cambian el formato y la salida. Use como disparador un *jQuery Selector* (`.js-carta`) con *Event Scope* = **Dynamic**. Ver [API.md §5](docs/API.md#5-parámetros-data-).

### Formato y salida

| Salida | Un documento | Varios documentos |
|---|---|---|
| **Archivo** (`file`) | Un archivo | ZIP |
| **ZIP** (`zip`) | ZIP | ZIP + resumen |
| **Un solo archivo** (`merge`) | Un archivo | Un archivo con todos |

**Formato**: `pdf`, `xlsx`, `docx`, `docx-template` (Word desde plantilla) o `all` (los tres, en ZIP).

### Atributos de la acción

| Atributo | Para qué |
|---|---|
| **Fuentes SQL** | Las consultas (`--@NOMBRE`). |
| **Diseño (JSON)** | El diseño, o el nombre de una variable JS global si pasa de 4000 caracteres (`misDisenos.carta`). |
| **Formato** | `pdf`, `xlsx`, `docx`, `docx-template`, `all`. |
| **Salida** | `file`, `zip`, `merge`. |
| **Ítems a enviar** | Ítems que se guardan en sesión antes de consultar ([ver nota](#problemas-conocidos-y-limitaciones)). |
| **PDF de un documento** | Abrir en pestaña nueva o descargar. |
| **Plantilla Word (URL)** | `.docx` para `docx-template`. |
| **Mensaje de espera** | Texto mientras se consulta. |
| *Initialization JavaScript Code* | Ajustar opciones antes de ejecutar (formato elegido en pantalla, parámetros extra, *hooks*). |

## Ejemplos

En [`examples/`](examples) hay ocho ejemplos listos para copiar (del 01 al 07 con EMP / DEPT):

| Ejemplo | Qué muestra |
|---|---|
| [01 · Listado de empleados](examples/01-listado-empleados) | Encabezado, dos tablas con totales, estilos por fila y por celda. PDF, Excel o Word. |
| [02 · Cartas en ZIP](examples/02-cartas-zip) | Carta con texto enriquecido, una por empleado, en ZIP con listado resumen o unidas en un PDF. |
| [03 · Constancia con posición fija](examples/03-constancia-posicion-fija) | Logo, número de documento y pie en coordenadas exactas; línea de firma; un PDF por fila. |
| [04 · Imagen desde BLOB](examples/04-imagen-blob) | Foto guardada en una columna BLOB. |
| [05 · Excel con varias hojas](examples/05-excel-multihoja) | Hojas por `id`, encabezado agrupado, `defs` reutilizables, secciones solo para PDF. |
| [06 · Plantilla Word](examples/06-plantilla-word) | Un `.docx` hecho en Word con marcadores y una fila de tabla que se repite. |
| [07 · Gráficos y códigos](examples/07-graficos-codigos) | Gráfico de barras y de anillo, tabla con quiebres y subtotales, QR, Code 128 y marca de agua condicional. |
| [08 · Factura con columnas](examples/08-factura-columnas) | Cliente y código de barras lado a lado, monto en letras junto a los totales y dos firmas en la misma línea. |

Cada carpeta trae `fuentes.sql` (atributo **Fuentes SQL**) y `diseno.json` (atributo **Diseño**). Guía paso a paso en [examples/README.md](examples/README.md).

## Documentación

| Documento | Contenido |
|---|---|
| [docs/API.md](docs/API.md) | Atributos, fuentes SQL y binds, documentos, `data-*`, salidas, API JavaScript (`novaReport.run`, `build`, `libs`, *hooks*), eventos, protocolo AJAX, errores, límites y seguridad. |
| [docs/DISENO.md](docs/DISENO.md) | Referencia completa del diseño JSON: página y tema, plantillas `{...}`, formatos, condiciones, cada sección con todas sus propiedades, Excel por hojas, lotes, `defs` y plantillas Word. |
| [CHANGELOG.md](CHANGELOG.md) | Historial de versiones. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Cómo compilar, probar y publicar una versión. |

## Probar sin APEX

`test/run.js` genera todos los ejemplos en Node con datos EMP / DEPT de prueba, usando el mismo motor que corre en el navegador:

```bash
cd test
npm install
npm test            # src/novareport.js      → test/out/
npm run test:min    # src/novareport.min.js  (el que se publica en el plugin)
```

Requiere Node 18 o superior.

## Estructura del repositorio

```
plugin/      Export del plugin, listo para importar en APEX
src/         novareport.js (motor), novareport.min.js (versión publicada) y plugin.plsql (render / ajax)
examples/    00-tablas-emp-dept.sql y ejemplos con EMP / DEPT: fuentes.sql + diseno.json (+ logo y plantilla)
docs/        API.md y DISENO.md
test/        Prueba en Node que genera todos los ejemplos sin APEX
```

## Seguridad

- Las **consultas se ejecutan en el servidor**; su texto nunca llega al navegador.
- Los valores **`data-*` vienen del navegador y el usuario puede cambiarlos**. Cada consulta debe validar el acceso, por ejemplo filtrando por `:APP_USER` o por ítems de sesión protegidos.
- Un `data-*` no puede reemplazar un ítem de APEX con el mismo nombre: el ítem siempre toma el valor de sesión.
- Detalle en [API.md §13](docs/API.md#13-seguridad).

## Problemas conocidos y limitaciones

| Tema | Detalle | Solución temporal |
|---|---|---|
| **Ítems a enviar** (1.6.1 a 1.10.0) | El valor del atributo (`P5_A,P5_B`) se pasaba como selector jQuery y los ítems no se enviaban. | Corregido en 1.11.0. En versiones anteriores: `function (o) { if (o.items) { o.items = o.items.split(','); } return o; }` |
| **Plantilla Word (URL)** (1.6.1 a 1.10.0) | No reemplazaba `#APP_FILES#`. | Corregido en 1.11.0. En versiones anteriores: `function (o) { o.templateUrl = apex.env.APP_FILES + 'plantillas/carta.docx'; return o; }` |
| Letras del PDF | Helvetica, Times y Courier no incluyen algunos símbolos, como **₡**. | Pendiente: soporte de fuentes TTF. |
| Fechas | Las columnas `DATE` viajan como `DD/MM/YYYY`, sin hora. | `to_char(fecha, 'DD/MM/YYYY HH24:MI')` |
| Posición fija | `x` / `y` solo aplican al PDF, en la página donde se dibujan. | |
| Tamaño | Máximo 250,000 filas por petición; el lote y el ZIP se arman en memoria del navegador. | Divida lotes muy grandes. |
| Atributos | 4000 caracteres. | Diseño en una variable JavaScript global. |

## novaReport Designer

**novaReport Designer** es una aplicación APEX construida sobre este plugin para diseñar reportes **sin escribir JSON**: lienzo de arrastrar y soltar con vista previa en PDF, Excel y Word, plantillas organizadas en carpetas, publicación por roles, la página **Mis reportes** para los usuarios finales (con parámetros y favoritos) y **Documentos guardados**.

El Designer no forma parte de este repositorio. Los diseños que produce son el mismo JSON documentado en [docs/DISENO.md](docs/DISENO.md), así que lo que se arma en el Designer funciona con el plugin y viceversa. Si le interesa usarlo, abra un *issue* en este repositorio.

## Licencia y autor

[MIT](LICENSE). Las librerías de terceros conservan sus licencias: ver [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

**Daniel Ramírez** — NovaCode, Panamá · Oracle ACE Associate.
Las contribuciones son bienvenidas mediante *issues* y *pull requests*.
