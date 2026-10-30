# Factura (plantilla de ejemplo)

**Acción Dinámica:** *Click* en botón → *NovaCode Report*. Formato `pdf` (también `xlsx` o `docx`) · Salida `file`.

**Parámetros:** `data-firmas="N"` en el botón quita la fila de firmas (`{PARAM.FIRMAS}`).

**Archivos estáticos:** ninguno.

**Supuestos:** usa solo `DUAL`; reemplazar por las tablas de facturas reales (`DOCS` = encabezado, `ITEMS` = líneas con el mismo `DOC_KEY`).
