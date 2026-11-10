-- Estado de cuenta (1.23). Datos de demo FROM DUAL.
-- MOVS viene ordenada por SUCURSAL y TIPO: breakBy agrupa filas consecutivas.
--@DOCS
select 1 doc_key, 'NOVACODE, S.A.' cliente, '155771259-2-2025' ruc, 'CTA-000123' cuenta
  from dual
--@MOVS
with l as (select level n from dual connect by level <= 60),
     s as (select 'Casa Matriz' sucursal, 1 o from dual union all select 'Sucursal Arraiján', 2 from dual),
     t as (select 'Crédito' tipo, 1 o from dual union all select 'Débito', 2 from dual),
     m as (
       select s.sucursal, s.o so, t.tipo, t.o tor, l.n,
              add_months(date '2026-08-01', mod(l.n, 3)) + mod(l.n * 7, 27) fecha,
              case t.tipo when 'Débito' then -(20 + mod(l.n * 53, 400) + mod(l.n, 5) / 10)
                          else 50 + mod(l.n * 37, 950) + mod(l.n, 7) / 10 end monto
         from l cross join s cross join t
     )
select 1 doc_key, sucursal, tipo, fecha, to_char(fecha, 'YYYY-MM') periodo,
       'Operación ' || lpad(n, 4, '0') concepto, monto
  from m
 order by so, tor, fecha, n
