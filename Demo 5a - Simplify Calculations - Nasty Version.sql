/* Example 5a:  simplifying nasty calculations */
/* What we want:  Pull out only the rows that have the 4th number in the 
	list less than 50 and sort the output by the 3rd number in the list. */

/* Original example from Brad Schulz
http://bradsruminations.blogspot.com/2011/04/t-sql-tuesday-017-it-slices-it-dices-it.html */

CREATE TABLE #t
(
	ID int identity(1,1),
	ListOfNums varchar(50)
);
INSERT INTO #t(ListOfNums) VALUES
	('279,37,972,15,175'),
	('17,72'),
	('672,52,19,23'),
	('153,798,266,52,29'),
	('77,349,14');

SELECT * FROM #t;

select 
	ID, 
	ListOfNums
from 
	#t
where 
	substring(ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
	charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1,
	(charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
	charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)+1)-
	charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
	charindex(',',ListOfNums+',,,,')+1)+1))-1)
	< 50
order by 
	substring(ListOfNums+',,,,',charindex(',',ListOfNums+',,,,',
	charindex(',',ListOfNums+',,,,')+1)+1,(charindex(',',ListOfNums+',,,,',
	charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1)+1)-
	charindex(',',ListOfNums+',,,,',charindex(',',ListOfNums+',,,,')+1))-1);


select 
	ID,
	ListOfNums
from 
	#t
	cross apply (select WorkString = ListOfNums + ',,,,') F_Str
	cross apply (select p1 = charindex(',', WorkString)) F_P1
	cross apply (select p2 = charindex(',', WorkString, p1 + 1)) F_P2
	cross apply (select p3 = charindex(',', WorkString, p2 + 1)) F_P3
	cross apply (select p4 = charindex(',', WorkString, p3 + 1)) F_P4      
	cross apply 
	(
		select 
			Num3 = convert(int,substring(WorkString, p2 + 1, p3 - p2 - 1)),
			Num4 = convert(int,substring(WorkString, p3 + 1, p4 - p3 - 1))
	) F_Nums
where 
	Num4 < 50
order by 
	Num3;