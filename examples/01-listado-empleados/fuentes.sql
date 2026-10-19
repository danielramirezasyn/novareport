--@DEPTOS
select d.dname, d.loc, count(e.empno) empleados, nvl(sum(e.sal), 0) salarios
  from dept d
  left join emp e on e.deptno = d.deptno
 group by d.dname, d.loc
 order by d.dname
--@EMP
select e.empno, e.ename, e.job, d.dname, e.hiredate, e.sal, e.comm
  from emp e
  join dept d on d.deptno = e.deptno
 order by d.dname, e.ename
