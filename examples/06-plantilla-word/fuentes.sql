--@DOCS
select d.deptno doc_key, d.dname, d.loc,
       count(e.empno) empleados, nvl(sum(e.sal), 0) salarios
  from dept d
  join emp e on e.deptno = d.deptno
 where (:DEPTNO is null or d.deptno = :DEPTNO)
 group by d.deptno, d.dname, d.loc
 order by d.dname
--@EQUIPO
select e.deptno doc_key, e.ename, e.job, e.hiredate, e.sal
  from emp e
 where (:DEPTNO is null or e.deptno = :DEPTNO)
 order by e.deptno, e.sal desc
