/* Example 7:  word pairs */
/* What we want:  given lines of text, find how often two words show up together. */
--Example comes from Brad Schulz:  http://bradsruminations.blogspot.com/2009/07/word-pairs-revisited-cool-cross-apply.html

create table #t (Message varchar(100));
insert into #t (Message) values
('Farewell to you and you and you Volumnius'),
('Strato thou hast been all this while asleep'),
('Farewell to thee too Strato Countrymen'),
('My heart doth joy that yet in all my life'),
('I found no man but he was true to me'),
('I shall have glory by this losing day'),
('More than Octavius   and                     Mark       Antony'),
('By this vile conquest shall attain unto'),
('So fare you well at once for Brutus'' tongue'),
('Hath almost ended his life''s history'),
('Night hangs upon mine eyes my bones would rest'),
('That have but labour''d to attain this hour');

select 
	WordPair,
	Occurrences = count(*)
from 
	#t
	cross apply (select TrimMessage = ltrim(rtrim(Message))) f1
	inner join sp_tally 
		on substring(' ' + TrimMessage, N, 1) = ' '
        and substring(' ' + TrimMessage, N + 1, 1) <> ' '                
        and N < len(TrimMessage) + 1
	cross apply (select WorkString = substring(TrimMessage + ' ', N, 
												len(TrimMessage) + 1)) f2
	cross apply (select p1 = charindex(' ', WorkString)) f3
	cross apply (select Word1 = left(WorkString, p1 - 1)) f4
	cross apply (select RestOfString = ltrim(substring(WorkString, p1, 
												len(WorkString)))) f5
	cross apply (select p2 = charindex(' ', RestOfString)) f6
	cross apply (select Word2 = case 
									when p2 > 0 then left(RestOfString, p2 - 1) 
								end) f7
	cross apply (select WordPair = Word1 + ' ' + Word2) f8
where 
	WordPair is not null
group by 
	WordPair
order by 
	count(*) desc
	
/* 
What's going on:
	#t - Set of sentences (in this case, lines stripped of punctuation)
	f1 - Strip any leading or trailing spaces from messages
	sp_tally join - Find all words in Message--word defined as a set of 
		non-spaces with a length >= 1
	f2 - Starting at N, get everything up until the end of Message
	f3 - The character marking the space between the first word and the rest of 
		Message
	f4 - The first word in the Message block
	f5 - The remainder of the string, stripping out the first word
	f6 - The character marking the space between the second word and the rest of 
		Message
	f7 - The second word in the Message block
	f8 - A combination of Word1 and Word2:  a unique pairing
*/

/*
select 
	*
from 
	#t
	cross apply (select TrimMessage = ltrim(rtrim(Message))) f1
	inner join sp_tally 
		on substring(' ' + TrimMessage, N, 1) = ' '
        and substring(' ' + TrimMessage, N + 1, 1) <> ' '                
        and N < len(TrimMessage) + 1
    cross apply (select WorkString = substring(TrimMessage + ' ', N, len(TrimMessage) + 1)) f2
    cross apply (select p1 = charindex(' ', WorkString)) f3
    cross apply (select Word1 = left(WorkString, p1 - 1)) f4
	cross apply (select RestOfString = ltrim(substring(WorkString, p1, len(WorkString)))) f5
	cross apply (select p2 = charindex(' ', RestOfString)) f6
	cross apply (select Word2 = case when p2 > 0 then left(RestOfString, p2 - 1) end) f7
	cross apply (select WordPair = Word1 + ' ' + Word2) f8
*/
	
drop table #t;