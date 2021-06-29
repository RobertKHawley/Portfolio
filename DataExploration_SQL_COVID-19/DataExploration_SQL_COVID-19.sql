-- Total Cases  vs. Total Deaths

-- Countries
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries
ORDER BY 1,2

-- UK
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVID19..COVID19Deaths
WHERE location LIKE '%kingdom%'
ORDER BY 1,2

-- Continental breakdown
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
ORDER BY 1,2

-- Global (using new_cases and new_deaths columns)
SELECT SUM(new_cases) AS global_cases, SUM(CAST(new_deaths AS int)) AS global_deaths
, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS death_percentage
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries


-- Total Cases vs. Population

-- Countries
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries
ORDER BY 1,2

-- UK
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
WHERE location LIKE '%kingdom%'
ORDER BY 1,2

-- Continental breakdown
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
ORDER BY 1,2


-- Highest infection rate per person

-- Countries
SELECT location, population, MAX(total_cases) AS infection_count
, MAX((total_cases/population))*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Continental breakdown of infection rate per person
SELECT location, population, MAX(total_cases) AS infection_count
, MAX((total_cases/population))*100 AS percent_population_infected
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
GROUP BY location, population
ORDER BY percent_population_infected DESC


-- Highest death count

-- Countries
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries
GROUP BY location
ORDER BY total_death_count DESC

-- Continental breakdown
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
GROUP BY location
ORDER BY total_death_count DESC


-- Highest Death count per person

-- Countries
SELECT location, 100*MAX(cast(total_deaths AS int))/population AS percent_population_deceased
FROM COVID19..COVID19Deaths
WHERE continent IS NOT NULL -- All 'NULL' in continents column are not countries
GROUP BY location, population
ORDER BY percent_population_deceased DESC

-- Continental breakdown
SELECT location, 100*MAX(cast(total_deaths AS int))/population AS percent_population_deceased
FROM COVID19..COVID19Deaths
WHERE continent IS NULL -- All 'NULL' in continents column are not countries
GROUP BY location, population
ORDER BY percent_population_deceased DESC


-- Total Population vs. Vaccinations (countries)

-- Rolling vaccination count
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS rolling_vaccinations_count
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- CTE for vaccinations per person
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_vaccinations_count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date)/2 AS rolling_vaccinations_count
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_vaccinations_count/population) AS vaccinations_per_person
FROM popvsvac
ORDER BY 2,3

-- Temp table for vaccinations per person
DROP TABLE IF EXISTS #vaccinations_per_person

CREATE TABLE #vaccinations_per_person
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations_count numeric
)

INSERT INTO #vaccinations_per_person
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS RollingPeopleVaccinated
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_vaccinations_count/population) AS vaccinations_per_person
FROM #vaccinations_per_person
ORDER BY 2,3

-- View for vaccinations per person
DROP VIEW IF EXISTS vaccinations_per_person

CREATE VIEW vaccinations_per_person AS
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_vaccinations_count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS rolling_vaccinations_count
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
)
SELECT *, (rolling_vaccinations_count/population) AS vaccinations_per_person
FROM popvsvac

-- Categorise countries based on vaccination status
WITH cte
AS
(
SELECT *, MAX(rolling_vaccinations_count/population) OVER (PARTITION BY location) AS latest_vaccinations_per_person
FROM #vaccinations_per_person
)
SELECT location, ROUND(CAST(latest_vaccinations_per_person AS float), 3) AS latest_vaccinations_per_person,
CASE
    WHEN latest_vaccinations_per_person > 1 THEN 'EXCELLENT'
    WHEN latest_vaccinations_per_person > 0.50 THEN 'GOOD'
    WHEN latest_vaccinations_per_person > 0.10 THEN 'FAIR'
    ELSE 'POOR' -- Assume NULL means 0 vaccinations
END AS vaccination_status
FROM cte
GROUP BY location, latest_vaccinations_per_person
ORDER BY latest_vaccinations_per_person DESC

-- GDP per capita and population vs the date 'GOOD' vaccination status (>0.5 vaccinations per person) was achieved 
SELECT VPP.location, gdp_per_capita, population, MIN(VPP.date) AS date_GOOD_status_achieved
FROM vaccinations_per_person VPP
JOIN COVID19..COVID19Vaccinations vac
    ON VPP.location = vac.location AND VPP.date = vac.date
WHERE vaccinations_per_person > 0.5
AND VPP.continent IS NOT NULL
GROUP BY VPP.location, gdp_per_capita, population
ORDER BY date_GOOD_status_achieved


-- How much did age, population, population density and GDP per capita impact reproduction rate?

-- With respect to max reproduction rate
WITH cte 
AS 
(
SELECT dea.continent, dea.location, dea.date, median_age, population, population_density, gdp_per_capita
, reproduction_rate, MAX(reproduction_rate) OVER (PARTITION BY dea.location) AS max_reproduction_rate, new_cases_smoothed
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE new_cases_smoothed > 100 -- Reliable sample size for calculating max reproduction rate
)
SELECT cte.location, median_age, population, population_density, gdp_per_capita, max_reproduction_rate
, MIN(cte.date) AS earliest_MRR_reached
FROM cte
JOIN (SELECT location, date, reproduction_rate FROM cte) cte_partial -- Self-join to retrieve corresponding dates
    ON cte.location = cte_partial.location AND cte.max_reproduction_rate = cte_partial.reproduction_rate
WHERE cte.continent IS NOT NULL
GROUP BY cte.location, median_age, population, population_density, gdp_per_capita, max_reproduction_rate
ORDER BY max_reproduction_rate DESC

-- With respect to average reproduction rate during high rates of infection (over 100+ days of high infection rate)
SELECT dea.location, median_age, population, population_density, gdp_per_capita
, AVG(CAST(reproduction_rate AS float)) AS avg_reproduction_rate, COUNT(*) AS high_infection_rate_days
FROM COVID19..COVID19Deaths dea
JOIN COVID19..COVID19Vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE new_cases_smoothed > 10 -- Reliable sample size for calculating avg reproduction rate
AND new_cases_smoothed/population > 0.00001 -- High infection rate relative to population?
AND dea.continent IS NOT NULL
GROUP BY dea.location, median_age, population, population_density, gdp_per_capita
HAVING COUNT(*) > 100 -- Measure long term effects of selected features
ORDER BY avg_reproduction_rate DESC
