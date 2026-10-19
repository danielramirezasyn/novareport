-- Tabla de ejemplo (créela una vez):
--   create table emp_foto (empno number primary key, foto blob);
--   (cargue fotos PNG o JPG, p. ej. desde un File Browse de APEX)
--@DOCS
select e.empno doc_key, e.ename, e.job, f.foto
  from emp e
  left join emp_foto f on f.empno = e.empno
 where (:EMPNO is null or e.empno = :EMPNO)
 order by e.ename
