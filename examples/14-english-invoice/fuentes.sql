--@DOCS
select 1 doc_key, 'INV-000123' invoice_no, date '2026-11-12' invoice_date, 'Acme Corp.' customer,
       '12-3456789' tax_id, 'Y' paid, 1284 total
  from dual
--@ITEMS
select 1 doc_key, 'Oracle APEX consulting' description, 8 qty, 120 price, 960 amount from dual
union all
select 1, 'novaReport support (annual)', 1, 324, 324 from dual
