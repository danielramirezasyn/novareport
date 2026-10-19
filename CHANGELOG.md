# Cambios

## Sin publicar
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
