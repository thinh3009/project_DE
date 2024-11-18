
--lay location cac port
SELECT distinct *
FROM (
    SELECT POR_ID AS LOCATION_ID, * FROM FactBooking
    UNION ALL
    SELECT POL_ID AS LOCATION_ID, * FROM FactBooking
    UNION ALL
    SELECT POD_ID AS LOCATION_ID, * FROM FactBooking
    UNION ALL
    SELECT FPD_ID AS LOCATION_ID, * FROM FactBooking
) AS FactBooking
JOIN DimLocation
ON FactBooking.LOCATION_ID = DimLocation.LOCATION_ID
--charge port
alter view vw_Booking_ChargePort
as
select f.BOOKING_ID,f.POR_ID,f.POL_ID,f.POD_ID,f.FPD_ID,v.CHARGENAME,v.CHARGENAMEVN,v.CURRENCY_ID,v.CURRENCYCODE,
v.CURRENCYNAME,v.CONTTYPE_ID,v.MINRATE,v.NUMOFCONT,v.RATE,v.APPROVEDRATE,d.[Day],d.[Month],d.[Year],d.[Quater],d.BOOKINGDATE
from [dbo].[VW_LIST_BOOKING_RATE] v  
inner join FactBooking f on v.BOOKING_ID =f.BOOKING_ID 
inner join DimDate d on f.DateID=d.DATE_ID

select * from vw_Booking_ChargePort

select * from VW_LIST_BOOKING_RATE

drop view vw_Booking_ChargePort
--port charge
select RATE*APPROVEDRATE as PORT_Charge,* from vw_Booking_ChargePort

--SALEMAN
select * from DimSaleMan s inner join DimSaleInfo i on s.SALEINFID=i.SALEINFID 
--view saleman
alter view vw_SaleMan
as
select s.SALESMAN_ID,s.SALEINFID,i.SALESMANCODE,i.SHORTNAME,i.FULLNAME,i.LOCALNAME,
i.[ADDRESS],i.TEL,i.FAX,i.MOBILE,i.EMAIL
from DimSaleMan s 
inner join DimSaleInfo i on s.SALEINFID=i.SALEINFID 
inner join FactBooking b on s.SALESMAN_ID=b.SALESMAN_ID 

select * from vw_SaleMan 
select * from vw_Booking_ChargePort
select * from [dbo].[VW_LIST_BOOKING_RATE] 
select * from FactBooking
select * from [dbo].[VW_SALEMAN_CHARGE]
--SALEMAN
alter VIEW VW_SALEMAN_CHARGE
AS
select s.SALESMAN_ID,i.SALEINFID,i.SALESMANCODE,
i.SHORTNAME,i.FULLNAME,i.[ADDRESS],i.MOBILE,i.EMAIL,f.BOOKING_ID,f.POR_ID,f.POL_ID,f.POD_ID,f.FPD_ID,f.DateID,v.NUMOFCONT,
v.APPROVEDRATE,v.RATE,v.MINRATE,v.CURRENCYCODE,v.CURRENCYNAME,(v.APPROVEDRATE*v.RATE)as SALE_RATE,v.VALIDITYFROM,d.[Day],d.[Month],
d.[Year],d.Quater,d.BOOKINGDATE
from DimSaleMan s 
inner join FactBooking f on s.SALESMAN_ID=f.SALESMAN_ID  
inner join [dbo].[VW_LIST_BOOKING_RATE] v on f.BOOKING_ID=v.BOOKING_ID 
inner join DimSaleInfo i on i.SALEINFID=s.SALEINFID 
inner join DimDate d on f.DateID=d.DATE_ID
WHERE d.BOOKINGDATE BETWEEN '2021-01-01' AND '2023-12-31'

select * from VW_SALEMAN_CHARGE
select * from VW_CUSTOMER
select * from DimCharge
select * from [dbo].[VW_LIST_BOOKING_RATE] where CHARGECODE like 'LSS'
select * from DimCharge
--location
select * from DimLocation l inner join FactBooking b on l.LOCATION_ID=b.POD_ID
----------------------

--booking trong 1 ngay
alter PROC proc_booking_day
	@d datetime
AS
BEGIN
	SELECT [Day], SUM(NUMOFCONT) AS totalContDay 
	FROM [dbo].[vw_Booking_ChargePort]
	WHERE [Day] = datename(d,@d)
	GROUP BY [Day]
END;

exec proc_booking_day @d =21
--booking trong 1 quy
CREATE PROC proc_booking_quater
	@q smallint
AS
BEGIN
	SELECT Quater, SUM(NUMOFCONT) AS totalCont 
	FROM [dbo].[vw_Booking_ChargePort]
	WHERE Quater = @q
	GROUP BY Quater
END;
exec proc_booking_quater @q=1

--booking  trong 1 thang
CREATE PROC proc_booking_month
	@m datetime
AS
BEGIN
	SELECT [Month], SUM(NUMOFCONT) AS totalCont 
	FROM [dbo].[vw_Booking_ChargePort]
	WHERE [Month]=@m
	GROUP BY [Month]
END;
exec proc_booking_month @m=1

--booking trong 1 nam

CREATE PROC proc_booking_year
	@y datetime
AS
BEGIN
	SELECT [Year], SUM(NUMOFCONT) AS totalCont 
	FROM [dbo].[vw_Booking_ChargePort]
	WHERE [Year]=@y
	GROUP BY [Year]
END;

exec proc_booking_year @y=2023 
--dich vu chi phi customer

select  v.APPROVEDRATE,v.RATE,v.MINRATE,v.CHARGENAME,v.CHARGENAMEVN,v.CURRENCYCODE,v.NUMOFCONT,
c.CUSTOMER_ID,c.FULLNAME,c.LOCALNAME,c.SHORTNAME
from [dbo].[VW_LIST_BOOKING_RATE] v 
inner join FactBooking b on v.BOOKING_ID=b.BOOKING_ID 
inner join DimCustomer c on c.CUSTOMER_ID=b.CUSTOMER_ID 
--vew customer
drop view VW_CUSTOMER
alter VIEW VW_CUSTOMER
AS
select c.CUSTOMER_ID,c.CUSTOMERCODE,c.COUNTRY_ID,c.[ADDRESS],d.BOOKINGDATE,d.Day,d.Year,d.Month,d.quater
c.TAXCODE,c.TEL,c.MOBILE,c.LOCALNAME,c.FULLNAME,c.SHORTNAME,l.BOOKING_ID,l.APPROVEDRATE,l.CHARGENAME,l.CHARGENAMEVN,
l.CURRENCYNAME,l.MINRATE,l.NUMOFCONT,l.RATE,c.SALESMAN_ID,l.CHARGECODE,l.VALIDITYFROM,(l.APPROVEDRATE*l.RATE) as Customer_rate
from DimCustomer c 
inner join FactBooking b on c.CUSTOMER_ID=b.CUSTOMER_ID 
inner join [dbo].[VW_LIST_BOOKING_RATE] l on l.BOOKING_ID=b.BOOKING_ID
inner join DimDate d on b.DateID=d.DATE_ID 
WHERE d.BOOKINGDATE BETWEEN '2021-01-01' AND '2023-12-31'
--chi phi customer
select * from VW_CUSTOMER 

select count(CUSTOMER_ID) from VW_CUSTOMER
--CUSTOMER
--so cont ma customer mua nhieu cont nhat
select  sum(NUMOFCONT) as maxCont,CUSTOMER_ID,CUSTOMERCODE,FULLNAME,SHORTNAME from VW_CUSTOMER 
GROUP BY CUSTOMER_ID, CUSTOMERCODE, FULLNAME, SHORTNAME 


--customer co doanh thu cao
select max(APPROVEDRATE*rate) as customerRate,CUSTOMER_ID,FULLNAME,CURRENCYNAME from VW_CUSTOMER
group by (APPROVEDRATE*rate),CUSTOMER_ID,FULLNAME,CURRENCYNAME 
having (APPROVEDRATE*rate)>=9200000
--phi dich vu cua customer
select * from VW_CUSTOMER where CHARGENAMEVN like '%PHÍ%'
select * from VW_CUSTOMER where CHARGENAMEVN like '%PHUÏ PHÍ NHIEÂN LIEÄU%'
select * from VW_CUSTOMER where CHARGENAMEVN like 'CÖÔÙC BIEÅN'
select distinct CHARGENAMEVN,CHARGECODE,CHARGENAME from VW_CUSTOMER
--PORT
select * from [dbo].[vw_Booking_ChargePort] 
where APPROVEDRATE =0



--SALEMAN
select distinct SALESMAN_ID,NUMOFCONT,SALEINFID from VW_SALEMAN_CHARGE

select distinct SALEINFID,NUMOFCONT,SALESMAN_ID from VW_SALEMAN_CHARGE 

select * from VW_SALEMAN_CHARGE 



--get location
alter VIEW vw_locationPort AS
SELECT 
    bk.BOOKING_ID,bk.POR_ID,bk.POL_ID,bk.POD_ID,bk.FPD_ID,bk.SALESMAN_ID,bk.BOOKINGNO,bk.CUSTOMER_ID,bk.ACCEPTEDAT,
	bk.BOOKINGTYPE,bk.DateID,bk.BKITEM_ID,d.BOOKINGDATE,d.Day,d.Month,d.Year,d.Quater,
    pol.LOCATIONNAME AS polLocationName,
    por.LOCATIONNAME AS porLocationName,
    pod.LOCATIONNAME AS podLocationName,
    fdp.LOCATIONNAME AS fdpLocationName,
	por.LOCATIONCODE as porCODE,
	pol.LOCATIONCODE as polCODE,
	pod.LOCATIONCODE as podCODE,
	fdp.LOCATIONCODE as fdpCODE 
FROM 
    [dbo].[FactBooking] AS bk 
INNER JOIN 
    [dbo].[DimLocation] AS pol ON bk.POL_ID = pol.LOCATION_ID 
INNER JOIN 
    DimLocation AS pod ON bk.POD_ID = pod.LOCATION_ID 
INNER JOIN 
    DimLocation AS por ON bk.POR_ID = por.LOCATION_ID
INNER JOIN 
    DimLocation AS fdp ON bk.FPD_ID = fdp.LOCATION_ID
inner join DimDate d on bk.DateID=d.DATE_ID
WHERE d.BOOKINGDATE BETWEEN '2021-01-01' AND '2023-12-31'

select * from vw_locationPort
--tong customer
select  count(distinct CUSTOMER_ID) from VW_CUSTOMER
--tong so cont
select sum(NUMOFCONT) from VW_CUSTOMER
--customer nao booking cont nhieu nhat (tu 5 xuong la it tren 5 la nhieu)
SELECT CUSTOMER_ID, FULLNAME, SHORTNAME, COUNT(NUMOFCONT) AS TotalBooking
FROM VW_CUSTOMER
GROUP BY CUSTOMER_ID, FULLNAME, SHORTNAME, CURRENCYNAME
HAVING COUNT(NUMOFCONT) <=2000
ORDER BY TotalBooking DESC;

--customer co gia tri don dat cao
select CUSTOMER_ID, FULLNAME, SHORTNAME, CURRENCYNAME,MINRATE,RATE,APPROVEDRATE,APPROVEDRATE*RATE as TotalRate,
case
	when APPROVEDRATE=0 then MINRATE 
end
from VW_CUSTOMER
GROUP BY CUSTOMER_ID, FULLNAME, SHORTNAME, CURRENCYNAME,MINRATE,RATE,APPROVEDRATE
ORDER BY TotalRate DESC;
--customer co so cont la 1
select count(distinct CUSTOMER_ID),CUSTOMER_ID from VW_CUSTOMER where NUMOFCONT>=1 and NUMOFCONT<=5 
group by CUSTOMER_ID
--cos so cont tu 5 den 2000
select count(distinct CUSTOMER_ID),CUSTOMER_ID from VW_CUSTOMER where NUMOFCONT<=2000 and NUMOFCONT>=5
group by CUSTOMER_ID
--customer dung dich vu gif
select * from VW_CUSTOMER

SELECT COUNT(DISTINCT CUSTOMER_ID), CHARGENAMEVN, SHORTNAME 
FROM VW_CUSTOMER
GROUP BY CHARGENAMEVN, SHORTNAME
ORDER BY SHORTNAME DESC;

select sum(NUMOFCONT) from VW_CUSTOMER

--saleman book duoc nhieu cont nhat
SELECT SALESMAN_ID, FULLNAME, SHORTNAME, COUNT(NUMOFCONT) AS TotalBooking
FROM VW_SALEMAN_CHARGE
GROUP BY SALESMAN_ID, FULLNAME, SHORTNAME, CURRENCYNAME
HAVING COUNT(NUMOFCONT) <=2000
ORDER BY TotalBooking DESC;

select * from VW_SALEMAN_CHARGE where FULLNAME like 'CUSTOMER SERVICE'
--saleman co doanh thu cao
select SALESMAN_ID, FULLNAME, SHORTNAME, CURRENCYNAME,MINRATE,RATE,APPROVEDRATE,APPROVEDRATE*RATE as TotalRate,
case
	when APPROVEDRATE=0 then MINRATE 
end
from VW_SALEMAN_CHARGE
GROUP BY SALESMAN_ID, FULLNAME, SHORTNAME, CURRENCYNAME,MINRATE,RATE,APPROVEDRATE
ORDER BY TotalRate DESC;
--view salemanbookingdate
select d.BOOKINGDATE,c.SALESMAN_ID,c.APPROVEDRATE,d.Quater,d.Day,d.Month,d.Year,d.DATE_ID
from VW_SALEMAN_CHARGE c  
inner join DimDate d on d.DATE_ID=c.DateID
where d.Year between 2021 and 2022

select * from VW_SALEMAN_CHARGE

select count(BOOKINGDATE) from DimDate
--port di qua dau
select * from [dbo].[vw_locationPort] p inner join [dbo].[VW_LIST_BOOKING_RATE] b on p.BOOKING_ID=b.BOOKING_ID


select d.CONTSIZE,d.TEMPERATURE,d.CONTTYPE,d.SALESMAN_ID,d.NUMOFCONT 
from DimContType d inner join VW_LIST_BOOKING_RATE i on d.CONTTYPE_ID=i.CONTTYPE_ID

select * from vw_locationPort where FPD_ID like 'GMD001159'




select * from VW_LIST_BOOKING_RATE

SELECT @@servicename