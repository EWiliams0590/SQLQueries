-- The follow queries are from three tables: us_population_by_state, us_state_vaccinations, and us-counties

-- The us_population_by_state gives the estimated population for each state. I added in a column 'region' as
-- I wanted to group the states together by their common region when performing some data analysis and visualization

-- The us_state_vaccinations gives data, per state, on how many vaccinations the state had distributed, vaccinations given, fully
-- vaccinated people, and others cumulatively for each date. An issue with this table was missing data, since cumulative, should have been 
-- filled in with the prior date's corresponding data, but was instead labeled as null. I had to fix this below.

-- The us-counties table gives the running total of cases and deaths from covid for each county in the US.
-- To analyze trends, not only overall, but in recent data, I made new columns in the view CovidCaseStats to help.
-- I also aggregated the data per state since that is what I was interested in, and it would be easier to compare to the other two tables.


SELECT *
FROM [us-counties]

GO

CREATE VIEW CovidCaseStats
AS 
WITH CTE AS (
SELECT cast(date as date) as Date, 
       state as State, 
	   sum(cast(cases as int)) as TotalCases, 
	   sum(cast(deaths as int)) as TotalDeaths,
	   RANK() OVER(PARTITION BY State ORDER BY Date) as DateRank
FROM dbo.[us-counties]
GROUP BY state, date)

SELECT Date, State, TotalCases, TotalDeaths,
	   CASE WHEN DateRank > 1 THEN TotalCases - LAG(TotalCases, 1) OVER(ORDER BY C1.State, C1.Date)
			ELSE TotalCases
	   END AS NewCases,
	   CASE WHEN DateRank > 1 THEN TotalDeaths - LAG(TotalDeaths, 1) OVER(ORDER BY C1.State, C1.Date)
			ELSE TotalDeaths
	   END AS NewDeaths
FROM CTE;

GO

CREATE VIEW CovidVax
AS
WITH CTE1 as(
SELECT date as Date, 
       CASE WHEN location <> 'New York State' THEN location
	   ELSE 'New York' END as State, 
	   people_fully_vaccinated as FullVax, 
	   people_vaccinated as Vax,
	   COUNT(CASE WHEN people_fully_vaccinated IS NOT NULL THEN 1 END)
			OVER(PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS FullGrp,
	   COUNT(CASE WHEN people_vaccinated IS NOT NULL THEN 1 END)
			OVER(PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Grp
from us_state_vaccinations),

CTE2 as (
SELECT Date, 
       State, 
	   Min(FullVax) OVER(PARTITION BY State, FullGrp) as FullVaccinated, 
	   MIN(Vax) OVER(PARTITION BY State, Grp) AS Vaccinated
FROM CTE1
WHERE FullGrp > 0 OR Grp > 0)

SELECT *
FROM CTE2


GO

CREATE VIEW StatePopulation AS
SELECT STATE as State,
       POPESTIMATE2019 as Population,
	   CASE WHEN STATE in ('Maine', 'New Hampshire', 'Vermont', 'New York', 'Pennsylvania', 'Massachusetts', 
						   'Rhode Island', 'Connecticut', 'New Jersey', 'Delaware', 'Maryland', 'District of Columbia', 
						   'West Virginia', 'Virginia') THEN 'Northeast'
			WHEN STATE in ('Florida', 'Georgia', 'South Carolina', 'North Carolina', 'Tennessee', 'Alabama', 
			               'Mississippi', 'Louisiana', 'Arkansas') THEN 'Southeast'
			WHEN STATE in ('Kentucky', 'Ohio', 'Michigan', 'Indiana', 'Michigan', 'Illinois', 'Wisconsin',
			               'Minnesota', 'Iowa', 'Missouri') THEN 'Midwest'
			WHEN STATE in ('Texas', 'Oklahoma', 'New Mexico', 'Colorado', 'Kansas', 'Nebraska', 'Wyoming', 
			               'Montana', 'South Dakota', 'North Dakota') THEN 'Central'
			ELSE 'Pacific' END as Region
FROM us_population_by_state

