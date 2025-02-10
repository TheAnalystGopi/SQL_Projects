-- netflix project
drop table if exists netflix;
create table netflix
(
show_id varchar(6),
type varchar(10),
title varchar(150),
director varchar(210),
casts varchar(1000),
country varchar(150),
date_added varchar(50),
release_year int,
rating varchar(50),
duration varchar(50),
listed_in varchar(80),
description varchar(350)
);

-- since data type for listed in is varchar and has more tha 80 char 
-- need to change it
select * from netflix;

-- lets see the distinct type of content

select count(*)
from netflix;




-- EDA
-- 14 business problems

-- 1. count the number movies and tvshows

select type, count(type) as count
from netflix
group by type;

-- 2. find the most common given rating for tv shows and movies

select type, rating, counted 
from (select type, rating, count(rating) as counted, rank() over(partition by type order by count(rating) desc) as ranking
from netflix
group by type, rating) as t1
        -- order by type, count(rating)desc
where ranking = 1;


-- 3. list all the movies which where released in specofic year(2020).
 select * from netflix;

 select * from netflix
 where type = 'Movie' and release_year = 2020;

 -- 4. 	find the top 5 countries with most content on netflix.


 select trim(unnest(string_to_array(country, ','))) as new_country, count(show_id) as show_id
 from netflix
 group by 1
 order by 2 desc
 limit 5;


 -- 5. identify the longest movei

 select * from netflix
 where type = 'Movie' and duration = (select max(duration) from netflix);

 -- 6. find all the movie shows and tv shows by director rohit chilaka

 select *,director from netflix
 where director like '%Rajiv Chilaka%'

-- 7 list all the tv shows more 5 seasons

select * from netflix 
where type = 'TV Show'
and split_part(duration, ' ', 1):: numeric > 5;
 

-- 8.count the number of content in each genre
select trim(unnest(string_to_array(listed_in, ','))), count(show_id) from netflix
group by 1
order by 2 desc;

-- 9. find each year and avg number of content release by india on netflix;
-- return top 5 year with highest avg content release
with t4 as
(
select release_year, trim(unnest(string_to_array(country, ','))) as country,  count(show_id) as counts from netflix
group by  release_year, trim(unnest(string_to_array(country, ','))) 
order by 1)
select release_year, country, avg(counts)
from t4
where country = 'India'
group by release_year, country
order by 3 desc
limit 5
;

-- 10.list all the movies that are documentries only

select title, count(title), trim(unnest(string_to_array(listed_in, ','))) from netflix
where listed_in = 'Documentaries'
group by 1,3;

--another way to find if content is documentary as well
select * from netflix
where listed_in like '%Documentaries%';

-- 11. find all the movies where there is no director

select * from netflix
where director is null;


-- 12. in last 10 year for how many movies salman khan appeared

select * from netflix
where casts like '%Salman Khan%'
and release_year >= extract(year from current_date)- 10;



-- 13. top 10 actors who appeared in highest number of movies in india.

select trim(unnest(string_to_array(casts,','))) as actors, count(show_id)as no_of_movies from netflix
where country ilike '%India'
group by 1
order by 2 desc
limit 10;

-- 14.categorize the content based on kill and violence  word in the description field and label it as bad and other movies as good
-- and count them
select count(show_id), 
case
when description like '%kill%' or description like '%violence%' then 'Bad'
else 'Good'
end as remarks
from netflix
group by 2;






