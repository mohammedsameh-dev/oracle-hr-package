create or replace package sameh_pkg is
function increase_emp_sal_check (emp_id number, increase_flag  varchar2 ,increase_value number )
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure increase_emp_sal (emp_id number , increase_flag varchar2 ,increase_value number );
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function  Is_number_fun (p_number varchar2)
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_full_address (p_id number, p_flag varchar2 )
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function Get_emp_count_fun (p_val varchar2 , p_ref varchar2) 
return number;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function Is_manager_fun (p_emp_id number, p_flag varchar2) 
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_department_name (p_ID number, p_flag varchar2)
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function Get_manager_full_name (p_ID number, p_flag varchar2)
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function my_to_char_fun (p_date date, p_format_id number)
return varchar2;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_top_salaries (emp_id    in  number,p_out_d   out number, p_out_j out number, p_out_l out number)
return number;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure export_data_proc (p_source_name varchar2);
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure import_and_update_proc;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure bulk_insert_emp_proc;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
end;

----------------------------------------------package body-------------------------------------------
create or replace package body sameh_pkg is
function new_emp_sal(emp_sal number , increase_flag varchar2 ,increase_value number ) return number;
procedure validate_emp_id(p_emp_id number); 
procedure validate_dept_id(p_dept_id number);

function increase_emp_sal_check (emp_id number, increase_flag  varchar2 ,increase_value number )
return varchar2
is
final_answer varchar2(2);
V_increase_flag varchar2(20);

emp_Sal number;
emp_job employees.job_id%type;
sal_aftr_inc number;
v_min_salary number ;
v_max_salary number;
mgr_sal number;

begin
V_increase_flag:=upper(increase_flag);

select e.salary , e.job_id , m.salary
into emp_Sal , emp_job , mgr_sal
from employees e, employees m
where e.manager_id = m.employee_id(+)
and e.employee_id = emp_id;
----------------------------------
select min_salary , max_salary
into v_min_salary , v_max_salary
from jobs
where job_id =emp_job ;
----------------------------------
sal_aftr_inc :=new_emp_sal(emp_sal,V_increase_flag,increase_value);
-----------------------------------
if sal_aftr_inc between v_min_salary and v_max_salary 
   and (mgr_sal is null or sal_aftr_inc <= mgr_sal)  then
    final_answer := 'Y';
else
    final_answer := 'N';
end if;
-------------------------------------
return final_answer;
exception
    when no_data_found then
        return 'Enter a Valid Employee_id';
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure increase_emp_sal (emp_id number , increase_flag varchar2 ,increase_value number )
is
check_emp_sal varchar2(5);
emp_Sal number;
sal_aftr_inc number;
begin 
select salary
into emp_Sal 
from employees 
where employee_id = emp_id;
---------------------------------
check_emp_sal := increase_emp_sal_check(emp_id,increase_flag,increase_value);
----------------------------------
if check_emp_sal = 'Y'then
sal_aftr_inc :=new_emp_sal(emp_sal,increase_flag,increase_value);

update employees
set salary  = sal_aftr_inc
where  employee_id = emp_id;

 insert into sal_log (
   emp_id, creation_date, created_by, 
   sal_before, sal_after) 
values ( emp_id/* EMP_ID */,
 sysdate/* CREATION_DATE */,
 user/* CREATED_BY */,
 emp_sal/* SAL_BEFORE */,
 sal_aftr_inc/* SAL_AFTER */ );
 
 commit;
else
dbms_output.put_line('You can''t  increase the salary');
end if;

exception when no_data_found then
dbms_output.put_line('Enter a valid Employee ID') ;
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function is_number_fun (p_number varchar2)
return varchar2
is
v_num number;
begin
    v_num := to_number(p_number);
    return 'Y';
exception
    when value_error then
        return 'N';
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_full_address (p_id number, p_flag varchar2)
return varchar2
is
    v_full_add varchar2(500);
    stm varchar2(500);
    v_flag varchar2(50);
begin
    v_flag:= upper(p_flag);
    
    if v_flag = 'E' then
        stm := 'SELECT L.location_id || '' - '' || L.street_address || '' - '' || L.city || '' - '' || C.country_name || '' - '' || R.region_name
                from employees E, departments D, locations L, countries C, regions R
                where E.employee_id = :p_id
                and E.department_id = D.department_id(+)
                and D.location_id = L.location_id(+)
                and L.country_id = C.country_id(+)
                and C.region_id = R.region_id(+)';

    elsif v_flag = 'D' then
        stm := 'SELECT L.location_id || '' - '' || L.street_address || '' - '' || L.city || '' - '' || C.country_name || '' - '' || R.region_name
                from departments D, locations L, countries C, regions R
                where D.department_id = :p_id
                and D.location_id = L.location_id(+)
                and L.country_id = C.country_id(+)
                and C.region_id = R.region_id(+)';
    else
        return 'Enter valid input E or D';
    end if;

execute immediate stm  into v_full_add using p_id;

return v_full_add;
    
exception
    when no_data_found then
        if v_flag = 'E' then
            return 'Enter a valid Employee ID';
        elsif v_flag = 'D' then
            return 'Enter a valid Department ID';
        end if;
        when others then
            raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_emp_count_fun (p_val varchar2, p_ref varchar2)
return number
is
    v_count     number;
    v_emp_cat   varchar2(200);
    stm         varchar2(1000);
    V_ref varchar2(5);
begin
    v_emp_cat := 'CASE WHEN salary <= 5000  THEN ''A''
                       WHEN salary <= 10000 THEN ''B''
                       WHEN salary <= 20000 THEN ''C''
                       ELSE ''D'' END';
    -----------------------------------
    V_ref := upper(p_ref);
    if V_ref = 'D' then
        stm := 'SELECT COUNT(employee_id)
                FROM employees
                WHERE department_id = :val';

    elsif V_ref = 'J' then
        stm := 'SELECT COUNT(employee_id)
                FROM employees
                WHERE job_id = :val';

    elsif V_ref = 'M' then
        stm := 'SELECT COUNT(employee_id)
                FROM employees
                WHERE manager_id = :val';

    elsif V_ref = 'S' then
        stm := 'SELECT COUNT(employee_id)
                FROM employees
                WHERE ' || v_emp_cat || ' = :val';

    elsif V_ref = 'C' then
        stm := 'SELECT COUNT(e.employee_id)
                FROM   employees e, departments d, locations l, countries c
                WHERE  e.department_id = d.department_id(+)
                and    d.location_id   = l.location_id(+)
                and    l.country_id    = c.country_id(+)
                and    c.country_id    = :val';
    else
    raise_application_error(-20001, 'Error: Enter A valid cat to count [D , J ,M , C , S]');
    end if;
    -----------------------------------
    execute immediate stm into v_count using p_val;
    return v_count;
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function is_manager_fun (p_emp_id number, p_flag varchar2)
return varchar2
is
    final_ans           varchar2(5);
    v_count             number;
    stm                 varchar2(200);
    v_flag varchar2(5);
begin
    v_flag:=upper(p_flag);
    
        -- Validate Employee ID
     if v_flag not in ('E', 'D') then
        raise_application_error(-20001, 'Invalid flag! Enter E or D');
    end if;
        validate_emp_id(p_emp_id);
    -- Main Logic

    
    if v_flag= 'E' then
        stm := 'select count(*) from employees where manager_id = :val';
    elsif v_flag = 'D' then
        stm := 'select count(*) from departments where manager_id = :val';
    end if;

    execute immediate stm into v_count using p_emp_id;

    if v_count > 0 then
        final_ans := 'Y';
    else
        final_ans := 'N';
    end if;

    return final_ans;

exception
    when others then
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_department_name(p_id number, p_flag varchar2)
    return varchar2
is
    v_name          varchar2(50);
    v_flag          varchar2(5);
    stm             varchar2(500);
    begin
    v_flag := upper(p_flag);

    -- Validation
    if v_flag not in ('E', 'D') then
        raise_application_error(-20001, 'Invalid flag! Enter E or D');
    end if;

    -- Main Logic
    if v_flag = 'E' then
    validate_emp_id(p_id); 
        stm := 'select nvl(d.department_name, ''No Department Assigned'')
                from departments d, employees e
                where e.department_id = d.department_id(+)
                and e.employee_id = :val';
    elsif v_flag = 'D' then
    validate_dept_id(p_id);
        stm := 'select department_name
                from departments
                where department_id = :val';
    end if;

    execute immediate stm
        into v_name
        using p_id;

    return v_name;

exception
    when others then
        raise_application_error(-20003, 'Unexpected error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function Get_manager_full_name (p_ID number, p_flag varchar2)
return varchar2
is
    v_flag              varchar2(50);
    v_name           varchar2(50);
    stm               varchar2 (200);
begin
        v_flag:=upper(p_flag);

        -- Validation
    if v_flag not in ('E', 'D') then
        raise_application_error(-20001, 'Invalid flag! Enter E or D');
    end if;
    
    -- Main Logic
    if v_flag = 'E'
    then
    validate_emp_id(p_ID); 
        stm := 'select m.first_name || '' '' ||m.last_name
from employees e , employees m
where e.manager_id = m.employee_id
and e.employee_id = :val';
    elsif v_flag = 'D'
    then
    validate_dept_id(p_ID);
        stm := 'select e.first_name || '' '' || e.last_name
from   departments d, employees e     
where  d.manager_id = e.employee_id 
and d.department_id = :val';
    end if;

    execute immediate stm
        into v_name
        using p_id;

    return v_name;
exception
when no_data_found then
    if v_flag = 'E' then
        raise_application_error(-20004, 'This Employee has no Manager');
    elsif v_flag = 'D' then
        raise_application_error(-20004, 'This Department has no Manager');
    end if;
      when others then
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function my_to_char_fun (p_date date, p_format_id number)
    return varchar2
is
    v_format   varchar2 (50);
    v_date     varchar2 (50);
begin

select data_format into v_format from setup_table where format_id = p_format_id;
v_date := to_char(p_date, v_format);
return v_date;
    
    exception 
    when no_data_found then 
    raise_application_error(-20009,'This Option Invalid Choose Another One'); 
    when others then
    raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
function get_top_salaries (emp_id    in  number,
                                             p_out_d   out number,
                                             p_out_j   out number,
                                             p_out_l   out number)
    return number
is
    v_result   number;
    v_dept     number;
    v_job      varchar2(50);
    v_loc      number;
begin
    -- Validate Employee ID
    validate_emp_id(emp_id);
----------------------------------------------------------------------------
    select e.department_id, e.job_id, d.location_id
    into   v_dept, v_job, v_loc
    from   employees e, departments d
    where  e.department_id = d.department_id(+)
    and    e.employee_id   = emp_id;
-----------------------------------------

    select max(salary) , 
    max( case when  department_id = v_dept then salary end),
    max(case when job_id = v_job then salary  end)
    into   v_result ,p_out_d,p_out_j
    from   employees ;
       
select max(salary)
into p_out_l
from employees e , departments d
 where  e.department_id = d.department_id(+)
 and  d.location_id   = v_loc;
    
-----------------------------------------
return v_result;

exception
    when others then
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure export_data_proc (p_source_name varchar2)
is
  v_header   varchar2(4000);
    v_line     varchar2(4000);
    v_file     utl_file.file_type;
    stm        varchar2(4000);
    type data_cur is ref cursor;
    my_cur     data_cur;
    
begin
    select 
    listagg (column_name, ', ') within group (order by column_id) , 
     'select ' ||
           listagg('nvl(to_char(' || column_name || '),''null'')', '||'',''||')
           within group (order by column_id) ||
           ' from ' || p_source_name
      into v_header ,  stm
      from user_tab_columns
     where table_name = upper (p_source_name);
    ---------------------------------------------------------------------
     v_file := utl_file.fopen('MY_DIR', p_source_name || '.csv', 'w');
    utl_file.put_line(v_file, v_header);
    ---------------------------------------------------------------------
    open my_cur for stm;
    loop
        fetch my_cur into v_line;
        exit when my_cur%notfound;
        utl_file.put_line (v_file,v_line);
    end loop;
  ---------  
    close my_cur;
    utl_file.fclose (v_file);
    
exception
    when utl_file.invalid_path then
        raise_application_error(-20001, 'Invalid Directory Path');
    when utl_file.invalid_operation then
        raise_application_error(-20002, 'Invalid File Operation');
    when others then
        if utl_file.is_open(v_file) then
            utl_file.fclose(v_file);
        end if;
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure import_and_update_proc
    is 
    v_line varchar2(200);
    v_sal number;
    v_emp_id number;
    file utl_file.file_type;
    type emp_id_tab is table of number;
type sal_tab    is table of number;
    begin
    file := utl_file.fopen('MY_DIR','emp_new_sals.csv','r');
    utl_file.get_line(file , v_line);
    loop
    begin
    utl_file.get_line(file, v_line);
    v_emp_id:= to_number(substr(v_line,1,instr(v_line,',')-1));
    v_sal := to_number(substr(v_line, instr(v_line, ',') + 1));
    insert into emp_new_sals values (v_emp_id, v_sal);
exception
            when no_data_found then exit;
                end;
    end loop;
    utl_file.fclose(file);
    
update employees e
set  salary  = (select new_salary from emp_new_sals n where n.employee_id = e.employee_id )
where  employee_id in (select employee_id from emp_new_sals);
commit;

exception
    when utl_file.invalid_path then
          rollback;
        raise_application_error(-20001, 'Invalid Directory Path');
    when utl_file.invalid_operation then
          rollback;
        raise_application_error(-20002, 'Invalid File Operation');
    when others then
        rollback;
        if utl_file.is_open(file) then
            utl_file.fclose(file);
        end if;
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------
procedure bulk_insert_emp_proc
is
    type emp_tab is table of emp_temp%rowtype;
    v_emps   emp_tab;
begin
    select * 
    bulk collect into v_emps
    from emp_temp;
    
    if v_emps.count = 0 then
        raise_application_error(-20001, 'emp_temp table is empty');
    end if;
   
 forall i in 1..v_emps.count
        insert into employees values (
            v_emps(i).employee_id,
            v_emps(i).first_name,
            v_emps(i).last_name,
            v_emps(i).email,
            v_emps(i).phone_number,
            v_emps(i).hire_date,
            v_emps(i).job_id,
            v_emps(i).salary,
            v_emps(i).commission_pct,
            v_emps(i).manager_id,
            v_emps(i).department_id
        );

    commit;
exception
    when others then
        rollback;
        raise_application_error(-20003, 'Unexpected Error: ' || sqlerrm);
end;
---------------------------------------------&&&&&&&&&&&&&&&&&-------------------------------------

------------------------------------------Service Funcs----------------------------------------------

function new_emp_sal(emp_sal number , increase_flag varchar2 ,increase_value number )
return number
is
sal_aftr_inc number;
v_increase_flag varchar2(20);
begin
v_increase_flag := upper(increase_flag);
if V_increase_flag= 'PCT' then
    sal_aftr_inc := (increase_value/100) * emp_sal + emp_sal;
elsif V_increase_flag = 'AMT' then
    sal_aftr_inc := emp_sal + increase_value;
    else
        raise_application_error(-20001, 'Invalid flag! Enter PCT or AMT');
end if ;

return sal_aftr_inc;
end;
-----------------------------------------------------------------------------------------------------------------
    procedure validate_emp_id(p_emp_id number) 
    is 
    v_check number;
    begin
    select count(employee_id)
    into   v_check
    from   employees
    where  employee_id = p_emp_id;

    if v_check = 0 then
         raise_application_error(-20002, 'Enter a valid Employee ID');
    end if;
    end;
-----------------------------------------------------------------------------------------------------------------
procedure validate_dept_id(p_dept_id number)
is
    v_check number;
begin
    select count(department_id) into v_check
    from departments
    where department_id = p_dept_id;
    if v_check = 0 then
        raise_application_error(-20002, 'Enter a valid Department ID');
    end if;
end;
-----------------------------------------------------------------------------------------------------------------
end;
-----------------------------------------------------------------------------------------------------------------
