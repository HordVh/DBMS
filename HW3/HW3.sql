create database globalpowerplants;
use globalpowerplants;

-- Tables --

CREATE TABLE countries (
    countrycode   CHAR(3)      PRIMARY KEY,
    countryname   VARCHAR(100) NOT NULL,
    continent     VARCHAR(50)  NOT NULL
);
 
CREATE TABLE operators (
    operatorid          INT          PRIMARY KEY,
    operatorname        VARCHAR(100) NOT NULL,
    headquarterscountry CHAR(3)      NOT NULL,
    FOREIGN KEY (headquarterscountry) REFERENCES countries (countrycode)
);
 
CREATE TABLE fuel_types (
    fuelid       INT         PRIMARY KEY,
    fuelcategory VARCHAR(50) NOT NULL,
    fuelname     VARCHAR(50) NOT NULL
);
 
CREATE TABLE power_plants (
    plantid        INT          PRIMARY KEY,
    plantname      VARCHAR(100) NOT NULL,
    countrycode    CHAR(3)      NOT NULL,
    operatorid     INT          NOT NULL,
    fuelid         INT          NOT NULL,
    capacitymw     INT          NOT NULL,
    commissionyear INT          NOT NULL,
    FOREIGN KEY (countrycode) REFERENCES countries (countrycode),
    FOREIGN KEY (operatorid)  REFERENCES operators (operatorid),
    FOREIGN KEY (fuelid)      REFERENCES fuel_types (fuelid)
);
 
CREATE TABLE generation_records (
    plantid       INT           NOT NULL,
    year          INT           NOT NULL,
    generationgwh DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (plantid, year),
    FOREIGN KEY (plantid) REFERENCES power_plants (plantid)
);
 
CREATE TABLE emission_metrics (
    plantid            INT           NOT NULL,
    year               INT           NOT NULL,
    co2emissionstonnes DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (plantid, year),
    FOREIGN KEY (plantid) REFERENCES power_plants (plantid)
);

-- 1) Retrieve the plant name, country name, operator name, 
-- fuel category, fuel name, capacity (in MW), and commission year 
-- for all power plants without using table aliases. Sort the results 
-- in descending order by capacity.

select power_plants.plantname,
       countries.countryname,
       operators.operatorname,
       fuel_types.fuelcategory,
       fuel_types.fuelname,
       power_plants.capacitymw,
       power_plants.commissionyear
from power_plants
join countries  using (countrycode)
join operators  using (operatorid)
join fuel_types using (fuelid)
order by power_plants.capacitymw desc;

-- 2) Retrieve the plant name, country code, calendar year, and annual generation (in GWh) 
-- for all power plants for the year 2024 without using table aliases. Sort the results in descending order by generation.

select 	plantname,
		countrycode,
		generation_records.year,
        generation_records.generationgwh
from power_plants
join generation_records using (plantid)
where generation_records.year = 2024
order by generation_records.generationgwh desc;

-- 3) Retrieve the plant name, country code, calendar year, annual generation (in GWh), 
-- and CO2 emissions (in tonnes) for all power plants for 
-- the year 2024 without using table aliases. Sort the results in ascending order by CO2 emissions.

select 	plantname,
		countrycode,
        generation_records.year,
		generation_records.generationgwh,
        emission_metrics.co2emissionstonnes
from power_plants
join generation_records on power_plants.plantid = generation_records.plantid
join emission_metrics 
on generation_records.plantid = emission_metrics.plantid
and generation_records.year = emission_metrics.year
where generation_records.year = 2024
order by emission_metrics.co2emissionstonnes;

-- 4) Write a SQL query using a Common Table Expression (CTE) to calculate 
-- the total cumulative power generation (in GWh) for each operator across 
-- all available years without using table aliases. 
-- Retrieve the operator name, headquarters country, and their total generated power, and 
-- sort the results in descending order by total generation.

with operator_generation as (
    select power_plants.operatorid,
           sum(generation_records.generationgwh) as totalgenerationgwh
    from power_plants
    join generation_records using (plantid)
    group by power_plants.operatorid
)
select operators.operatorname,
       operators.headquarterscountry,
       operator_generation.totalgenerationgwh
from operators
join operator_generation using (operatorid)
order by operator_generation.totalgenerationgwh desc;

-- 5) Write a SQL query using two separate Common Table Expressions (CTEs)
-- one to calculate total power generation by country code and 
-- another to calculate total CO2 emissions by country code without using table aliases. Then, 
-- join these CTEs with the countries table to display the country name, total generation (in GWh), 
-- and total CO2 emissions (in tonnes). Sort the results in descending order by total generation.

with country_generation as (
    select power_plants.countrycode,
           sum(generation_records.generationgwh) as totalgenerationgwh
    from power_plants
    join generation_records using (plantid)
    group by power_plants.countrycode
),
country_emissions as (
    select power_plants.countrycode,
           sum(emission_metrics.co2emissionstonnes) as totalco2emissionstonnes
    from power_plants
    join emission_metrics using (plantid)
    group by power_plants.countrycode
)
select countries.countryname,
       country_generation.totalgenerationgwh,
       country_emissions.totalco2emissionstonnes
FROM countries
JOIN country_generation using (countrycode)
JOIN country_emissions  using (countrycode)
ORDER BY country_generation.totalgenerationgwh DESC;

        