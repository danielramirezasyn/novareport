--@DEPTOS
SELECT d.dname, COUNT(e.empno) AS empleados, SUM(e.sal) AS salarios, NVL(SUM(e.comm), 0) AS comisiones
  FROM dept d JOIN emp e ON e.deptno = d.deptno
 GROUP BY d.dname
 ORDER BY d.dname

--@EMP
-- Ordenada por la columna de quiebre (breakBy)
SELECT d.dname, e.empno, e.ename, e.job, e.sal, e.comm
  FROM emp e JOIN dept d ON d.deptno = e.deptno
 ORDER BY d.dname, e.sal DESC
