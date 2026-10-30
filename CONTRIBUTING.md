# Contribuir

Gracias por su interés en novaReport. Los *issues* y *pull requests* son bienvenidos.

## Reportar un problema

Incluya:

- Versión de novaReport (`novaReport.version` en la consola del navegador) y de APEX.
- Formato y salida usados.
- Las **Fuentes SQL** y el **Diseño** mínimos que reproducen el problema (con EMP / DEPT si es posible).
- El mensaje de error y lo que aparece en la consola del navegador.

## Estructura del código

| Archivo | Qué contiene |
|---|---|
| `src/novareport.js` | Motor completo: carga de librerías, plantillas, condiciones, PDF, Excel, Word, plantillas Word, lotes y punto de entrada de la Acción Dinámica. |
| `src/novareport.min.js` | Versión minificada; es la que va dentro del plugin. |
| `src/plugin.plsql` | Código PL/SQL del plugin: `render` (pasa la configuración al navegador) y `ajax` (ejecuta las fuentes y devuelve JSON). |
| `plugin/dynamic_action_plugin_com_novacode_novareport.sql` | Export de APEX 26.1 listo para importar. |
| `plugin/apex-23.2/` | Variante del export para APEX 23.2 (mismo JavaScript). |
| `plugin/build_plugin.py` | Regenera el export con `src/plugin.plsql`, `src/novareport.min.js` y la versión de `src/novareport.js`. |

## Flujo de trabajo

1. Haga el cambio en `src/novareport.js` (y en `src/plugin.plsql` si toca el servidor).
2. Si agrega una opción al diseño, actualice [`docs/DISENO.md`](docs/DISENO.md); si cambia atributos, opciones de `run` o el protocolo, [`docs/API.md`](docs/API.md).
3. Si es una función nueva, agregue o amplíe un ejemplo en `examples/` y su caso en `test/run.js`.
4. Pruebe:

   ```bash
   cd test
   npm install
   npm test
   ```

5. Genere el minificado y pruébelo:

   ```bash
   npx terser ../src/novareport.js -c -m --comments '/^!/' -o ../src/novareport.min.js
   npm run test:min
   ```

6. Actualice `VERSION` en `src/novareport.js`, el encabezado `/*! novaReport x.y.z */` y [`CHANGELOG.md`](CHANGELOG.md).

## Publicar una versión

1. Regenere el export (toma el PL/SQL, el minificado y la versión; sube `p_files_version` si cambió el JS):

   ```bash
   python3 plugin/build_plugin.py                 # actualiza plugin/dynamic_action_plugin_com_novacode_novareport.sql
   python3 plugin/build_plugin.py --app 118       # además genera test/out/deploy/118_plugin.sql para instalarlo en esa app
   ```

2. Actualice la variante de APEX 23.2 (`plugin/apex-23.2/`) con el mismo `novareport.min.js`, la versión y `p_files_version`. `plugin/to_apex232.py` genera una variante nueva desde el export 26.1 si cambian los atributos del plugin.
3. Verifique que el archivo exportado coincide con el minificado (debe imprimir `OK`):

   ```bash
   python3 - <<'PY'
   import re
   s = open('plugin/dynamic_action_plugin_com_novacode_novareport.sql', encoding='utf-8').read()
   h = ''.join(re.findall(r"g_varchar2_table\(\d+\) := '([0-9A-F]+)'", s))
   print('OK' if bytes.fromhex(h) == open('src/novareport.min.js', 'rb').read() else 'DIFERENTE')
   PY
   ```

## Estilo

- JavaScript ES5 compatible con el navegador, sin dependencias en tiempo de ejecución más allá de las librerías listadas en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- Mensajes al usuario en español.
- Las propiedades del diseño se mantienen compatibles hacia atrás: una propiedad nueva siempre tiene un valor por defecto que conserva el comportamiento anterior.
