-- Convert Data types
UPDATE PortfolioProject..CovidDeaths
Set Continent = Nullif(Continent,'')

ALTER TABLE PortfolioProject..CovidDeaths 
ALTER COLUMN date datetime

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN Population Float
UPDATE PortfolioProject..CovidDeaths
Set Population = Nullif(Population,0)

ALTER TABLE PortfolioProject..CovidDeaths 
ALTER COLUMN total_cases Float

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths Float

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN new_cases Float
UPDATE PortfolioProject..CovidDeaths
Set new_cases = Nullif(new_cases,0)

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN new_deaths Float
UPDATE PortfolioProject..CovidDeaths
Set new_deaths= Nullif(new_deaths,0)

ALTER TABLE PortfolioProject..CovidVaccinations
ALTER COLUMN new_vaccinations Float


-- Total Cases vs Total Deaths
Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where Location = 'United Kingdom'
Order by 1,2

-- Total Cases vs Population
Select Location, Date, Population, total_cases, (total_cases/Population)*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
Where Location = 'United Kingdom'
Order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/Population)*100) as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
Order by PercentagePopulationInfected Desc

-- Countries with Highest Death Count per Population
Select Location, MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where Continent is not NULL
Group by Location
Order by TotalDeathCount Desc

-- Continents with Highest Death Count per Population
Select Location, MAX(Total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where Continent is NULL
Group by Location
Order by TotalDeathCount Desc

-- Global Numbers
Select Date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases))*100
From PortfolioProject..CovidDeaths
Where Continent is not NULL 
Group by Date
Order by 1,2

-- Total Population vs Vaccinations CTE approach
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.Location = vac.Location
	and dea.Date = vac.Date
Where dea.Continent is not NULL
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Total Population vs Vaccinations Temp Table approach
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population Float,
new_vaccinations Float,
RollingPeopleVaccinated Float
)

Insert into #PercentPopulationVaccinated
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.Location = vac.Location
	and dea.Date = vac.Date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- View to store data for later visualizations
Create view PercentPopulationVaccinated as
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.Location = vac.Location
	and dea.Date = vac.Date
Where dea.Continent is not NULL
