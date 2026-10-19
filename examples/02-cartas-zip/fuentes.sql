--@DOCS
select e.empno doc_key, e.ename, e.job, d.dname, e.sal, e.hiredate,
       round(e.sal * 1.05, 2) sal_nuevo
  from emp e
  join dept d on d.deptno = e.deptno
 where (:EMPNO is null or e.empno = :EMPNO)
 order by e.ename
--@LISTA summary
select e.ename, e.job, e.sal, round(e.sal * 1.05, 2) sal_nuevo
  from emp e
 order by e.ename
