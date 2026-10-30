-- Ejemplo 09 · Cover Sheet de presentación de crédito: tarjetas, ficha en cuadrícula,
-- tablas con encabezado a la izquierda y bordes, totales en color. Solo DUAL.
--@DOCS
select 1 doc_key, '16-26' cover_no, '15-Oct-26' fecha, 'Disminución de' presentacion, 'CL-000003' cif, 'Approved' status,
       'Ana Lucía Castillo Herrera' deudor, 'Cédula 4-721-889' identificacion, '-' rep_legal,
       'Urbanización Vista Alegre, calle 3, casa 45, Vista Alegre, Arraiján, Panamá Oeste' direccion,
       '-' contacto, '-' act_economica, '-' sub_actividad, '-' ciiu, '-' cartera, '-' sub_cartera,
       'Banca Personal' categoria, 'Panamá' pais, '1001 - Casa Matriz Panamá' oficina, 'Centroamérica' area_geo,
       '-' pct_pais, '-' pct_ceg, '-' pct_exposicion, '-' exposicion_grupo, '-' grupo_economico,
       'N' parte_relacionada, '-' ultima_revision, 'Héctor Iván Delgado' oficial,
       '-' ranking, '-' prob_default, '-' rating_origen, 'Comercial' tipo_prestamo, '-' riesgo_amb,
       'ADMIN' enviado_por, '28-Oct-26 15:51' enviado_el, 'CHECKER' resuelto_por, '28-Oct-26 15:53' resuelto_el,
       'Aprobada desde la bandeja de tareas' comentario,
       to_char(sysdate, 'DD-Mon-RR HH24:MI', 'NLS_DATE_LANGUAGE=ENGLISH') impreso
  from dual
--@FACILIDAD
select 'NIO' moneda, 5656656565 monto, '-' plazo, '-' tasa, 'Capital e intereses al vencimiento' forma_pago, '-' desembolso from dual
--@GARANTIA
select 'Fianza corporativa' tipo, 'YYYYYY' descripcion, 'USD' moneda, 343444 valor, 50 cobertura, '21-Oct-26' avaluo from dual
--@FIRMAS
select 'Mónica Patricia Vega Luna' f1_nombre, 'Analista de Riesgo' f1_cargo,
       'Ricardo José Alvarado Pinto' f2_nombre, 'Gerente de Crédito' f2_cargo,
       'Carolina Isabel Tejeira' f3_nombre, 'Gerente de Negocios' f3_cargo,
       'Eduardo Miguel Sanjur Ortiz' f4_nombre, 'VP de Riesgo' f4_cargo,
       'Patricia Elena Quirós Díaz' f5_nombre, 'VP de Negocios' f5_cargo,
       'Luis Fernando Arango Mejía' f6_nombre, 'Gerente General' f6_cargo
  from dual
