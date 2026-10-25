--------------------------------------------------------------------------------
-- novaReport - tablas y datos de ejemplo EMP / DEPT
--
-- Crea DEPT y EMP (el esquema clásico SCOTT) con sus 4 departamentos y
-- 14 empleados. Lo usan todos los ejemplos de esta carpeta.
--
-- Es seguro ejecutarlo más de una vez: no crea una tabla si ya existe y solo
-- inserta los datos cuando la tabla está vacía. No borra nada.
--
-- Ejecutar en SQL Workshop > SQL Scripts, SQLcl o SQL Developer.
-- Compatible con Oracle 19c, 23ai / 26ai y Autonomous Database.
--------------------------------------------------------------------------------

declare
    procedure crear (p_tabla in varchar2, p_ddl in varchar2) is
        l_n pls_integer;
    begin
        select count(*) into l_n from user_tables where table_name = p_tabla;
        if l_n = 0 then
            execute immediate p_ddl;
            dbms_output.put_line('Creada ' || p_tabla);
        else
            dbms_output.put_line(p_tabla || ' ya existe: no se modifica');
        end if;
    end crear;
begin
    crear('DEPT', q'[
        create table dept (
            deptno  number(2)     constraint dept_pk primary key,
            dname   varchar2(14),
            loc     varchar2(13)
        )]');

    crear('EMP', q'[
        create table emp (
            empno     number(4)     constraint emp_pk primary key,
            ename     varchar2(10),
            job       varchar2(9),
            mgr       number(4),
            hiredate  date,
            sal       number(7,2),
            comm      number(7,2),
            deptno    number(2)     constraint emp_dept_fk references dept (deptno)
        )]');

    -- Solo para el ejemplo 04 (foto desde BLOB)
    crear('EMP_FOTO', q'[
        create table emp_foto (
            empno  number(4)  constraint emp_foto_pk primary key
                              constraint emp_foto_emp_fk references emp (empno),
            foto   blob
        )]');
end;
/

declare
    l_n pls_integer;
begin
    select count(*) into l_n from dept;
    if l_n = 0 then
        insert into dept values (10, 'ACCOUNTING', 'NEW YORK');
        insert into dept values (20, 'RESEARCH',   'DALLAS');
        insert into dept values (30, 'SALES',      'CHICAGO');
        insert into dept values (40, 'OPERATIONS', 'BOSTON');
        dbms_output.put_line('DEPT: 4 filas');
    end if;

    select count(*) into l_n from emp;
    if l_n = 0 then
        insert into emp values (7839, 'KING',   'PRESIDENT', null, date '1981-11-17', 5000, null, 10);
        insert into emp values (7698, 'BLAKE',  'MANAGER',   7839, date '1981-05-01', 2850, null, 30);
        insert into emp values (7782, 'CLARK',  'MANAGER',   7839, date '1981-06-09', 2450, null, 10);
        insert into emp values (7566, 'JONES',  'MANAGER',   7839, date '1981-04-02', 2975, null, 20);
        insert into emp values (7788, 'SCOTT',  'ANALYST',   7566, date '1982-12-09', 3000, null, 20);
        insert into emp values (7902, 'FORD',   'ANALYST',   7566, date '1981-12-03', 3000, null, 20);
        insert into emp values (7369, 'SMITH',  'CLERK',     7902, date '1980-12-17',  800, null, 20);
        insert into emp values (7499, 'ALLEN',  'SALESMAN',  7698, date '1981-02-20', 1600,  300, 30);
        insert into emp values (7521, 'WARD',   'SALESMAN',  7698, date '1981-02-22', 1250,  500, 30);
        insert into emp values (7654, 'MARTIN', 'SALESMAN',  7698, date '1981-09-28', 1250, 1400, 30);
        insert into emp values (7844, 'TURNER', 'SALESMAN',  7698, date '1981-09-08', 1500,    0, 30);
        insert into emp values (7876, 'ADAMS',  'CLERK',     7788, date '1983-01-12', 1100, null, 20);
        insert into emp values (7900, 'JAMES',  'CLERK',     7698, date '1981-12-03',  950, null, 30);
        insert into emp values (7934, 'MILLER', 'CLERK',     7782, date '1982-01-23', 1300, null, 10);
        dbms_output.put_line('EMP: 14 filas');
    end if;
    commit;
end;
/

-- Verificación: debe devolver 4 departamentos (OPERATIONS sin empleados) y totales 14 / 29,025
select d.dname, d.loc, count(e.empno) empleados, nvl(sum(e.sal), 0) salarios
  from dept d
  left join emp e on e.deptno = d.deptno
 group by d.dname, d.loc
 order by d.dname;
