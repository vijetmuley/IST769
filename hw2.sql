use fudgemart_v3;
go
--NetID: vmuley
select product_id as 'Product ID', product_name as 'Product name', case 
	when charindex(' ', reverse(product_name))=0
		then product_name
	else right(product_name, (charindex(' ', reverse(product_name)))-1)
end as 'Product Category', product_department as 'Product Department' from fudgemart_products;

--NetID: vmuley
if exists(select * from sys.objects where name='v_sales_tab')
	drop view v_sales_tab
go

create view v_sales_tab as
	select fp.product_id, fp.product_vendor_id, fp.product_wholesale_price, sum(fod.order_qty) as 'Total_Sale'
	from fudgemart_products fp inner join fudgemart_order_details fod 
	on fp.product_id=fod.product_id group by fp.product_id, fp.product_vendor_id, fp.product_wholesale_price;
go

--select * from v_sales_tab;

if exists(select * from sys.objects where name='f_total_vendor_sales')
	drop function f_total_vendor_sales
go

create function f_total_vendor_sales(
	@vendor_id varchar(100)
) returns table as
	return(select product_vendor_id, sum(product_wholesale_price * Total_Sale) as 'total' from v_sales_tab
	group by product_vendor_id having product_vendor_id=@vendor_id)
go

select fv.vendor_id as 'Vendor ID', total as 'Total Sales' 
from fudgemart_vendors fv cross apply f_total_vendor_sales(fv.vendor_id) order by fv.vendor_id;

--NetID:vmuley
use fudgemart_v3;
go
if exists(select * from sys.objects where name='p_write_vendor')
	drop procedure p_write_vendor
go

create procedure p_write_vendor(
	@vendor_name varchar(100),
	@vendor_phone varchar(10),
	@vendor_website varchar(50)
) as
begin
	if exists(select * from fudgemart_vendors where vendor_name=@vendor_name)
	begin
		if @vendor_website is null
		begin
			update fudgemart_vendors set vendor_phone=@vendor_phone 
			where vendor_name=@vendor_name; 
		end
		else
		begin
			update fudgemart_vendors set vendor_phone=@vendor_phone, vendor_website=@vendor_website
			where vendor_name=@vendor_name;
		end
	end
	
	else
	begin
		insert into fudgemart_vendors values (@vendor_name,@vendor_phone,@vendor_website);
	end
end
go

--Updating vendor with name 'Fudgeman' (Only changed the number):
execute p_write_vendor 'Fudgeman','123-4567','http://www.fudgeman.com';
--Adding a new vendor:
execute p_write_vendor 'Vijet','555-5555','http://vijetmuley.com';
select * from fudgemart_vendors;

--NetID: vmuley
if exists(select * from sys.objects where name='v_question_1')
	drop view v_question_1
go

create view v_question_1 as
	select product_id as 'Product ID', product_name as 'Product Name', case 
	when charindex(' ', reverse(product_name))=0
		then product_name
	else right(product_name, (charindex(' ', reverse(product_name)))-1)
end as 'Product Category', product_department as 'Product Department' from fudgemart_products;
go

select * from v_question_1;

--NetID: vmuley
if exists(select * from sys.objects where name='f_employee_timesheets')
	drop function f_employee_timesheets
go

create function f_employee_timesheets(
	@employee_id varchar(5)
) returns table as
return (
select fe.employee_id, fe.employee_firstname+' '+fe.employee_lastname as 'Name', fe.employee_department,
fet.timesheet_payrolldate, fe.employee_hourlywage, fet.timesheet_hours, fe.employee_hourlywage*fet.timesheet_hours as 'Gross Pay' 
from fudgemart_employees fe inner join fudgemart_employee_timesheets fet on fe.employee_id=fet.timesheet_employee_id where employee_id=@employee_id
)
go

use fudgemart_v3;
select fev.employee_id as 'Employee ID', Name, fev.employee_department as 'Employee Department', 
timesheet_payrolldate as 'Payroll Date', fev.employee_hourlywage as 'Hourly Wage', timesheet_hours as 'Hours Worked', 
[Gross Pay] 
from fudgemart_employees fe cross apply f_employee_timesheets(employee_id) fev