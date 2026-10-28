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
| `src/novareport.js` | Motor completo: carga de librerías, plantillas, condiciones, PDF, Excel, Word, formularios, plantillas Word, lotes y punto de entrada de la Acción Dinámica. |
| `src/novareport.min.js` | Versión minificada; es la que va dentro del plugin. |
| `src/plugin.plsql` | Código PL/SQL del plugin: `render` (pasa la configuración al navegador) y `ajax` (ejecuta las fuentes y devuelve JSON). |
| `plugin/dynamic_action_plugin_com_novacode_novareport.sql` | Export de APEX 26.1 listo para importar. |
| `plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql` | Variante para APEX 23.2 – 24.x. No se edita a mano: se genera con `plugin/to_apex232.py`. |
| `plugin/to_apex232.py` | Convierte el export 26.1 a 23.2: header, `attributes.get_varchar2` → `attribute_NN`, `render` de la API v1, sin `p_apexlang_name` ni `p_static_id`. El JavaScript no cambia. |

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

1. En una aplicación APEX 26.1 de desarrollo, en el plugin **COM.NOVACODE.NOVAREPORT**:
   - reemplace el archivo `novareport.js` en *Files* por `src/novareport.min.js` (con el nombre `novareport.js`);
   - pegue `src/plugin.plsql` en *PL/SQL Code* si cambió;
   - cambie *Version* a la nueva versión.
2. Exporte el plugin y reemplace `plugin/dynamic_action_plugin_com_novacode_novareport.sql`.
3. Genere la variante 23.2. `--ids-from` toma los IDs del export 23.2 anterior, para que la importación reemplace el plugin y las acciones conserven su configuración:

   ```bash
   python3 plugin/to_apex232.py \
     plugin/dynamic_action_plugin_com_novacode_novareport.sql \
     plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql \
     --ids-from plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql
   ```

   Si cambió el `render` o se agregó un atributo, revise el script antes de publicar: el `render` 23.2 está escrito en él y cada atributo se mapea por su secuencia.
4. Verifique que los dos exports llevan el minificado (cada uno debe imprimir `OK`):

   ```bash
   python3 - <<'PY'
   import re
   js = open('src/novareport.min.js', 'rb').read()
   for f in ['plugin/dynamic_action_plugin_com_novacode_novareport.sql',
             'plugin/apex-23.2/dynamic_action_plugin_com_novacode_novareport.sql']:
       s = open(f, encoding='utf-8').read()
       h = ''.join(re.findall(r"g_varchar2_table\(\d+\) := '([0-9A-F]+)'", s))
       print('OK' if bytes.fromhex(h) == js else 'DIFERENTE', f)
   PY
   ```

5. Si puede, importe cada export en su versión de APEX (26.1 y 23.2) y genere un reporte en PDF, Excel y Word.

## Estilo

- JavaScript ES5 compatible con el navegador, sin dependencias en tiempo de ejecución más allá de las librerías listadas en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- Mensajes al usuario en español.
- Las propiedades del diseño se mantienen compatibles hacia atrás: una propiedad nueva siempre tiene un valor por defecto que conserva el comportamiento anterior.
- Nada que dependa de APIs exclusivas de APEX 24.2+ en `src/novareport.js`: el mismo JavaScript corre en las dos variantes.
