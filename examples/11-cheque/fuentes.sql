--@DOCS
with c as (
  select 1 doc_key, 'ALDERAAN SYSTEMS, S.A.' beneficiario, 123.45 importe, date '2002-09-07' fecha, 'MADRID' lugar,
         'DKN' serie, '05.084.580' numero, '5' numero_dc, '4103' cod, '1' cod_dc,
         '0079' entidad, '1346' oficina, '52' dc, '0127632984' cuenta, 'LISVA SOLUCIONES INTEGRADAS, S.L.' titular from dual union all
  select 2, 'NOVACODE, S.A.', 2750, date '2026-10-31', 'PANAMÁ', 'DKN', '05.084.581', '3', '4103', '1',
         '0079', '1346', '52', '0127632984', 'LISVA SOLUCIONES INTEGRADAS, S.L.' from dual union all
  select 3, 'JUAN CARLOS PÉREZ RODRÍGUEZ', 98765.4, date '2026-11-15', 'PANAMÁ', 'DKN', '05.084.582', '1', '4103', '1',
         '0079', '1346', '52', '0127632984', 'LISVA SOLUCIONES INTEGRADAS, S.L.' from dual
), d as (
  select c.*, to_char(c.importe, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.''') importe_txt from c
)
select d.*,
       '##' || d.importe_txt || '##' importe_prot,
       -- fuente de seguridad: dos letras bajo cada carácter del importe
       '####' || (select listagg(decode(substr(d.importe_txt, level, 1), '0','CE','1','UN','2','DS','3','TR','4','CU','5','CI',
                                        '6','SE','7','SI','8','OC','9','NU','.','PT',',','CM'), '')
                           within group (order by level)
                    from dual connect by level <= length(d.importe_txt)) || '####' seguridad,
       to_char(d.fecha, 'DD') dia,
       upper(to_char(d.fecha, 'FMMonth', 'NLS_DATE_LANGUAGE=SPANISH')) mes,
       to_char(d.fecha, 'YYYY') anio,
       '<' || replace(d.numero, '.') || d.numero_dc || '>' || d.entidad || '< ' || d.oficina || '> ' || d.cuenta || '; '
           || d.cod || ': ' || lpad(round(d.importe * 100), 10, '0') micr
  from d
