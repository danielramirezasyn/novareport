-- Hipervínculos (1.22). Datos de demo FROM DUAL.
-- Las URL de páginas de APEX se arman en la consulta con apex_page.get_url (respeta URLs amigables y la sesión).
--@DOCS
select 1 doc_key, 'NOVACODE, S.A.' cliente, 'www.novacode-labs.com' web,
       'info@novacode-labs.com' correo, '+50765503739' telefono,
       'https://github.com/danielramirezasyn/novareport' repo,
       apex_page.get_url(p_page => 1) url_inicio
  from dual
--@MOVS
with m as (
  select 1 doc_key, 1001 nro, date '2026-11-02' fecha, 'Licencia Oracle APEX' concepto, 1500 monto, 'https://apex.oracle.com' sitio from dual union all
  select 1, 1002, date '2026-11-04', 'Soporte ORDS', 250.75, 'https://www.oracle.com/database/technologies/appdev/rest.html' from dual union all
  select 1, 1003, date '2026-11-06', 'Consultoría PL/SQL', 3200, 'https://docs.oracle.com/en/database/' from dual union all
  select 1, 1004, date '2026-11-08', 'Ajuste', -50.75, null from dual
)
select doc_key, nro, fecha, concepto, monto, sitio,
       apex_page.get_url(p_page => 1, p_request => 'NRO_' || nro) url_detalle
  from m
 order by nro
