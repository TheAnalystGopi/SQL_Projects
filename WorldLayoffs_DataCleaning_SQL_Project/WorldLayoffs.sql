# Data Cleaning
select * from layoffs; 

-- Remove Duplicates
-- standardize The Data
-- Null values
-- Blank Values
-- Remove Columns

## in order to not make any changes to raw data, a temp data is required like staging database.

create table layoffs1
like layoffs;

select	* from layoffs1;
insert layoffs1
select * from layoffs;

select * from layoffs1;

-- first need to remove all the duplicate values
select *, row_number() over(partition by company, location, industry, percentage_laid_off, total_laid_off, date, stage, country, funds_raised_millions) as row_num from layoffs1;

-- with the help of cte will remove duplicate
with dupli as
(select *,row_number() over(partition by company, location, industry, percentage_laid_off, total_laid_off, date, stage, country) as row_num  from layoffs1)
select * from dupli
where row_num >1;

select * from layoffs1
where company = "cazoo"; -- we checked if we are removing the duplicates only

-- these are the rows with dupliate values
-- now need to create the another tale so that we can update values there like deleting column

CREATE TABLE `layoffs2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` double DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs2
select *,row_number() over(partition by company, location, industry, percentage_laid_off, total_laid_off, date, stage, country) 
from layoffs1;


set sql_safe_updates = 0;
delete from layoffs2
where row_num > 1;

select * from layoffs2
where row_num > 1; -- all the duplicates have been removed.



## standardizing the data by column to column

select * from layoffs2;
update layoffs2
set company = trim(company);
select * from layoffs2;
select distinct company from layoffs2;
-- so there are 1885 distinct companies--  first column standardized

select distinct industry from layoffs1
order by industry;

update layoffs2
set industry = "Crypto"
where industry like "Crypto%";
select distinct industry from layoffs2
order by industry;
-- Column industry dtandardized

update layoffs2
set `date` = str_to_date(date, '%m/%d/%Y');
select date from layoffs2layoffs2date;
-- here date column is registered as text data type so need to change that

alter table layoffs2
modify column `date` date;

-- let's check
select * from layoffs2;

select distinct country from layoffs2
order by country;

-- we found a error
update layoffs2
set country = "Unied States"
where country like "United%";
## country column has been standardized


## now lets remove null values
## prior removing the data need to check if we can update anything for the given data like standardizing 

select * from layoffs2
where industry is null or industry = "";

select * from layoffs2
where company = "juul";

-- so lets update all the data for blanks null values

select l1.industry, l2.industry from  layoffs2 as l1
join layoffs2 as l2
on l1.company = l2.company
where(l1.industry is null or l1.industry= '') and (l2.industry is not null and l2.industry != "");
-- particular company has the data but it's not added

update layoffs2 l1
join layoffs l2
on l1.company - l2.company
set l1.industry = l2.industry
where(l1.industry is null or l1.industry= '') and (l2.industry is not null and l2.industry != "");
-- so we added data for the null values blank values where from the same table where values where just not added

select * from layoffs2
where company = "airbnb";
-- verified the data
select * from layoffs2
where total_laid_off is null and percentage_laid_off is null;
## removing unnecessary coln

select * from layoffs2;
alter table layoffs2
drop column rowsnum;

## deleting all the rows where total laid off values and percentage of laid off is null

delete from layoffs2
where total_laid_off is null and percentage_laid_off is null;
select * from layoffs2;





