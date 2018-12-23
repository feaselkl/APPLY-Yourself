/* Example 6:  string splitting */
/* What we want:  split our product array out into separate columns for subsequent normalization. */
--Example comes from Brad Schulz:  http://bradsruminations.blogspot.com/2009/07/cool-cross-apply-tricks-part-2.html

/* Check relative performance of each.  Be sure to turn on execution plans (Ctrl+M). */
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

create table #t
(
	ProductId int,
	ProductName varchar(25),
	SupplierId int,
	Descr varchar(50)
);
insert into #t(ProductId, ProductName, SupplierId, Descr)
select 1,'Product1',1,'A1,10in,30in,2lbs'
union all select 2,'Product2',2,'T6,15in,30in'
union all select 3,'Product3',1,'A2,1in,,0.5lbs'
union all select 4,'Product4',1,'X5,3in';

--Basic comma-delimited string problem here.  
--Note that Product4 doesn't have all 4 attributes!
select * from #t;

--This ensures that we have all of the commas we need.
select 
	ProductID,
	SupplierID,
	string
from 
	#t
	cross apply (select string=Descr+',,,,') f1;

--Get the locations of the first four commas in each row--these demarcate 
--the four attributes we care about.
select 
	ProductID,
	SupplierID,
	string,
	p1,
	p2,
	p3,
	p4
from 
	#t
	cross apply (select string = Descr + ',,,,') f1
	cross apply (select p1 = charindex(',', string)) f2
	cross apply (select p2 = charindex(',', string, p1+1)) f3
	cross apply (select p3 = charindex(',', string, p2+1)) f4
	cross apply (select p4 = charindex(',', string, p3+1)) f5;

--Cross Apply solution
select 
	ProductID,
	SupplierID,
	[Type],
	Length,
	Height,
	Weight
from 
	#t
	cross apply (select string = Descr+',,,,') f1
	cross apply (select p1 = charindex(',',string)) f2
	cross apply (select p2 = charindex(',',string,p1+1)) f3
	cross apply (select p3 = charindex(',',string,p2+1)) f4
	cross apply (select p4 = charindex(',',string,p3+1)) f5
	cross apply 
	(
		select 
			[Type] = substring(string, 1, p1-1),
			Length = substring(string, p1+1, p2-p1-1),
			Height = substring(string, p2+1, p3-p2-1),
			Weight = substring(string, p3+1, p4-p3-1)
	) f6
order by 
	ProductId;
                   
--Tally table version, for comparison:
with tally as
(
	SELECT
		ProductId,
		ROW_NUMBER() over (partition by ProductId order by N) as rownum,
		SUBSTRING(',' + t.Descr + ',', N+1, 
					CHARINDEX(',', ',' + t.Descr + ',', N+1 ) - N-1) as Value
	FROM
		dbo.sp_tally tally
		cross join #t t
	WHERE
		N < LEN(',' + t.Descr + ',')
		AND SUBSTRING(',' + t.Descr + ',', N, 1) = ','
)
select
	t.ProductId,
	t.SupplierId,
	MAX(case when t2.rownum = 1 then t2.Value end) as [Type],
	MAX(case when t2.rownum = 2 then t2.Value end) as [Length],
	MAX(case when t2.rownum = 3 then t2.Value end) as [Height],
	MAX(case when t2.rownum = 4 then t2.Value end) as [Weight]
from
	#t t
	inner join tally t2 on t.ProductId = t2.ProductId
group by
	t.ProductId,
	t.SupplierId
order by
	t.ProductId;
                   

drop table #t;