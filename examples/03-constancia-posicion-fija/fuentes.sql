--@DOCS
select e.empno doc_key, 'RH-' || lpad(e.empno, 6, '0') || '-' || to_char(sysdate, 'YYYY') nro_doc,
       to_char(sysdate, 'DD') || ' de ' || initcap(to_char(sysdate, 'FMMonth', 'NLS_DATE_LANGUAGE=SPANISH')) || ' del ' || to_char(sysdate, 'YYYY') fecha_txt,
       e.ename, e.job, d.dname, e.hiredate, e.sal
  from emp e
  join dept d on d.deptno = e.deptno
 where e.empno = :EMPNO
