-- Query 1: Basic selection from CovidDeaths table, ordered by specific columns
SELECT *
FROM CovidDeaths
ORDER BY 3,4;

-- Query 2: Basic selection from CovidDeaths for analysis purposes
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM CovidDeaths
ORDER BY 1,2;

-- Query 3: Analyze likelihood of dying if you contract COVID-19
SELECT location, date, total_cases, total_deaths, 
       (total_deaths / NULLIF(total_cases, 0)) * 100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Query 4: Analyze the percentage of the population that got COVID-19
SELECT location, date, total_cases, population, 
       (total_cases / NULLIF(population, 0)) * 100 as PercentPopulationInfected
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Query 5: Countries with the highest infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount, 
       population, MAX((total_cases / NULLIF(population, 0))) * 100 as PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;

-- Query 6: Countries with the Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc;

-- Query 7: Death count by continent
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- Query 8: Death count in locations without continent data
SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS
SELECT 
    SUM(COALESCE(new_cases, 0)) as total_cases, 
    SUM(COALESCE(CAST(new_deaths as int), 0)) as total_deaths, 
    (SUM(COALESCE(CAST(new_deaths as int), 0)) / NULLIF(SUM(COALESCE(new_cases, 0)), 0)) * 100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2;

-- CTE for RollingPeopleVaccinated
;WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (
            PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
)
-- Using CTE to analyze population vaccination
SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    RollingPeopleVaccinated, 
    (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM PopvsVac
ORDER BY continent, location, date;

-- Drop the temp table if it exists
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
DROP TABLE #PercentPopulationVaccinated;

-- TEMP TABLE
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Insert data into the temp table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

-- Select from the temp table
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Create view
CREATE VIEW PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null;







