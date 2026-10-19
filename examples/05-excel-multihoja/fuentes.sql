--@DEPTOS
select d.deptno, d.dname, d.loc, count(e.empno) empleados,
       nvl(sum(e.sal), 0) salarios, nvl(sum(e.comm), 0) comisiones
  from dept d
  left join emp e on e.deptno = d.deptno
 group by d.deptno, d.dname, d.loc
 order by d.dname
--@EMP
select e.empno, e.ename, e.job, d.dname, e.hiredate, e.sal, e.comm,
       e.sal + nvl(e.comm, 0) total
  from emp e
  join dept d on d.deptno = e.deptno
 where (:P5_DEPTNO is null or e.deptno = :P5_DEPTNO)
 order by d.dname, e.ename
