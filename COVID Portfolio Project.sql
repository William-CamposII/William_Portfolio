-- The data did not load properly so I had to alter the data type for columns total_cases and population into a float
-- I also made it so that there would be no division by zero due to population, changing the zero values into null values
SELECT *
FROM [Portfolio Project]..CovidDeaths
WHERE ISNUMERIC(total_cases) = 0 OR ISNUMERIC(population) = 0;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN population FLOAT;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN [date] DATE;

ALTER TABLE [Portfolio Project]..CovidVaccinations
ALTER COLUMN [date] DATE;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN new_cases INT;

UPDATE [Portfolio Project]..CovidDeaths
SET population = NULL
WHERE population = 0;

UPDATE [Portfolio Project]..CovidDeaths
SET new_cases = NULL
WHERE new_cases = 0;

UPDATE [Portfolio Project]..CovidDeaths
SET total_cases = NULL
WHERE total_cases = 0;



-- Updated the data to have empty cells say null as opposed to staying blank

UPDATE [Portfolio Project]..CovidDeaths
SET continent = NULL
WHERE continent = ''

UPDATE [Portfolio Project]..CovidVaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations = ''

SELECT *
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM [Portfolio Project]..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY location, date 


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, CAST(date AS DATE) AS date, total_cases, total_deaths, (total_deaths/total_cases) *100 AS death_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT location, CAST(date AS DATE) AS date, population, total_cases, (total_cases/population) *100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
--WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases/population)) * 100 as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries with the highest death count per population

SELECT location, 
       MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Breaking things down by continent
-- Showing continents with the highest death count per population

SELECT continent, 
       MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
ORDER BY location, date


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated
ORDER BY location, date



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated