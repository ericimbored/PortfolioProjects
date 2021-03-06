-- CREATE DATABASE PortfolioCOVID;
-- USE PortfolioCOVID;



SELECT * FROM PortfolioCOVID.coviddeaths
WHERE continent IS NOT NULL AND continent <> ''
ORDER BY 3,4

-- SELECT * FROM PortfolioCOVID.covidvaccinations
-- ORDER BY 3,4 


--------------------------------------------------------------------------------------------------------------------------


-- SELECTING THE DATA TO GET A VISUAL OF THE DATA

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioCOVID.coviddeaths
ORDER BY 1,2 


--------------------------------------------------------------------------------------------------------------------------


-- LOOKING AT TOTAL CASES VS TOTAL DEATHS
-- SHOWS LIKELIHOOD OF DYING IF CONTRACT COVID IN YOUR COUNTRY

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioCOVID.coviddeaths
WHERE location LIKE '%states%' AND
WHERE continent IS NOT NULL AND continent <> ''
ORDER BY 1,2


--------------------------------------------------------------------------------------------------------------------------


-- LOOK AT TOTAL CASES VS POPULATION
-- SHOWS WHAT PERCENTAGE OF POPULATION GOT COVID

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS GotCovid
FROM PortfolioCOVID.coviddeaths
WHERE location LIKE '%states%' AND
WHERE continent IS NOT NULL AND continent <> ''
ORDER BY 1,2


--------------------------------------------------------------------------------------------------------------------------


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE VS POPULATION

SELECT Location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentPopInfected
FROM PortfolioCOVID.coviddeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL AND continent <> ''
GROUP BY location, population
ORDER BY PercentPopInfected desc


--------------------------------------------------------------------------------------------------------------------------


-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT Location, MAX(CAST(total_deaths as SIGNED int)) AS TotalDeathCount
FROM PortfolioCOVID.coviddeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL AND continent <> ''
GROUP BY location
ORDER BY TotalDeathCount desc


--------------------------------------------------------------------------------------------------------------------------


--BREAKING IT DOWN BY CONTINENT. COULD ALSO BE DONE BY STATE BY ADDING THE WHERE CLAUSE

SELECT continent, MAX(CAST(total_deaths as SIGNED int)) AS TotalDeathCount
FROM PortfolioCOVID.coviddeaths
-- WHERE location LIKE '%states%'
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount desc


--------------------------------------------------------------------------------------------------------------------------


-- GLOBAL NUMBERS

SELECT -- date -- SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS SIGNED int)) as total_deaths, SUM(CAST(new_deaths AS SIGNED int))/SUM(new_cases)*100 DeathPercentage
FROM PortfolioCOVID.coviddeaths
-- WHERE location LIKE '%states%' AND
WHERE continent <> ''
-- GROUP BY date
ORDER BY 1,2


--------------------------------------------------------------------------------------------------------------------------


-- LOOKING AT TOTAL POPULATION VS VACCINATIONS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS SIGNED int)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population*100 -- Can't use a column just created to use in next one, have to create CTE or Temp table
FROM PortfolioCOVID.coviddeaths dea
JOIN PortfolioCOVID.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
-- ORDER BY 2, 3


--------------------------------------------------------------------------------------------------------------------------


-- USING CTE (Common Table Expression)

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS SIGNED int)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population*100
FROM PortfolioCOVID.coviddeaths dea
JOIN PortfolioCOVID.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
-- ORDER BY 2, 3
)
SELECT * , (RollingPeopleVaccinated/population)*100
FROM PopvsVac


--------------------------------------------------------------------------------------------------------------------------


-- USING TEMP TABLE

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date DATETIME,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT IGNORE INTO PercentPopulationVaccinated(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER 
(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population*100
FROM PortfolioCOVID.coviddeaths dea
JOIN PortfolioCOVID.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
-- WHERE dea.continent <> ''
-- ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PercentPopulationVaccinated;


--------------------------------------------------------------------------------------------------------------------------


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER 
(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population*100
FROM PortfolioCOVID.coviddeaths dea
JOIN PortfolioCOVID.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
WHERE dea.continent <> '';
-- ORDER BY 2, 3

-- SELECT * FROM PercentPopulationVaccinated
