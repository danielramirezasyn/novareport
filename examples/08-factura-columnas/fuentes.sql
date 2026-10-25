--@DOCS
select 1 doc_key, 'FAC-000123' numero, date '2026-10-24' fecha, 'Ana Pérez' cliente,
       '8-765-4321' cedula, 'Calle 50, Panamá' direccion,
       1284 subtotal, 89.88 itbms, 1373.88 total
  from dual
--@ITEMS
select 1 doc_key, 'Consultoría Oracle APEX' descripcion, 8 cantidad, 120 precio, 960 importe from dual
union all
select 1, 'Licencia novaReport (soporte anual)', 1, 324, 324 from dual
--@EMPRESA
select 'NovaCode, S.A.' nombre, '155771259-2-2025' ruc, 'Panamá Oeste, Arraiján' direccion from dual
