-- Orginally typed with tabs of size 4


-- 1

SELECT SUM(new_cases) AS global_cases, SUM(CAST(new_deaths AS int)) AS global_deaths
, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS death_percentage
FROM COVID19..COVID19Deaths
WHERE location = 'World'
ORDER BY 1,2


-- 2

SELECT location, SUM(CAST(new_deaths AS int)) AS total_death_count
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


-- 3

SELECT location, population, MAX(total_cases) AS infection_count
, MAX((total_cases/population))*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- 4

SELECT location, population, date, total_cases AS infection_count
, new_cases/population AS percent_population_infected_that_day
, total_cases/population AS percent_population_infected
FROM COVID19..COVID19Deaths
ORDER BY percent_population_infected DESC
