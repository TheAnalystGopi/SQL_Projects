## exploratory Data Analysis

select * from layoffs2;
-- max total laid off
select company, max(total_laid_off) from layoffs2
group by company
order by max(total_laid_off) desc;

-- all the layoffs by company
select company, sum(total_laid_off)
from layoffs2
group by company
order by 2 Desc; -- so highest lay offs was for amazon



-- now lets see total laid off by industry and company
select  industry, sum(total_laid_off) from layoffs2
group by industry
order by sum(total_laid_off) desc; -- so the consumer grup has highest laid off

-- lets see laid off by over per month
select substring(date,1,7), sum(total_laid_off) from layoffs2
where  substring(date,1,7) is not null	
group by substring(date,1,7)
order by  substring(date,1,7) asc;

with rolling as(
select substring(date,1,7) month , sum(total_laid_off) total from layoffs2
where  substring(date,1,7) is not null	
group by substring(date,1,7)
order by  1 asc)
select month, sum(total) over(order by month) from rolling;


-- will find 5 highest layoff each year
select company, year(date), sum(total_laid_off) from layoffs2
group by company, year(date)
order by company asc;

with total_laid as (
select company, year(date) year, sum(total_laid_off) total from layoffs2
where year(date) is not null
group by company, year(date)
order by company asc),
yearly as(
select *, dense_rank() over(partition by year order by total desc) ranking from total_laid
where year is not null)
select *
from yearly
where ranking <=5;
-- this is how we get top 5 companies who laid off employees for each year











