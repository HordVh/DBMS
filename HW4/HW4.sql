CREATE DATABASE space_missions;
USE space_missions;
 
CREATE TABLE countries (
    countrycode  CHAR(3)      NOT NULL,
    countryname  VARCHAR(100) NOT NULL,
    continent    VARCHAR(50)  NOT NULL,
    PRIMARY KEY (countrycode)
);
 
CREATE TABLE organizations (
    orgid               INT          NOT NULL,
    orgname             VARCHAR(100) NOT NULL,
    headquarterscountry CHAR(3)      NOT NULL,
    orgtype             VARCHAR(20)  NOT NULL,
    PRIMARY KEY (orgid),
    FOREIGN KEY (headquarterscountry) REFERENCES countries (countrycode)
);
 
CREATE TABLE launch_sites (
    siteid       INT          NOT NULL,
    sitename     VARCHAR(100) NOT NULL,
    countrycode  CHAR(3)      NOT NULL,
    status       VARCHAR(20)  NOT NULL,
    PRIMARY KEY (siteid),
    FOREIGN KEY (countrycode) REFERENCES countries (countrycode)
);
 
CREATE TABLE rockets (
    rocketid           INT          NOT NULL,
    rocketname         VARCHAR(100) NOT NULL,
    orgid              INT          NOT NULL,
    payloadcapacitykg  INT          NOT NULL,
    operationalstatus  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (rocketid),
    FOREIGN KEY (orgid) REFERENCES organizations (orgid)
);
 
CREATE TABLE missions (
    missionid    INT          NOT NULL,
    missionname  VARCHAR(100) NOT NULL,
    rocketid     INT          NOT NULL,
    siteid       INT          NOT NULL,
    destination  VARCHAR(50)  NOT NULL,
    launchyear   INT          NOT NULL,
    outcome      VARCHAR(20)  NOT NULL,
    PRIMARY KEY (missionid),
    FOREIGN KEY (rocketid) REFERENCES rockets (rocketid),
    FOREIGN KEY (siteid)   REFERENCES launch_sites (siteid)
);
 
CREATE TABLE payloads (
    payloadid    INT            NOT NULL,
    missionid    INT            NOT NULL,
    payloadname  VARCHAR(100)   NOT NULL,
    payloadtype  VARCHAR(50)    NOT NULL,
    masskg       DECIMAL(10,2)  NOT NULL,
    PRIMARY KEY (payloadid),
    FOREIGN KEY (missionid) REFERENCES missions (missionid)
);

-- Queries --

-- 1) Retrieve the mission name, rocket name, organization name, launch site name, destination, launch year, and outcome 
-- for all space missions without using table aliases. Sort the results in descending order by launch year and ascending 
-- order by mission name.

SELECT missions.missionname,
       rockets.rocketname,
       organizations.orgname,
       launch_sites.sitename,
       missions.destination,
       missions.launchyear,
       missions.outcome
FROM missions
INNER JOIN rockets USING(rocketid)
INNER JOIN organizations USING(orgid)
INNER JOIN launch_sites USING(siteid)
ORDER BY missions.launchyear DESC, missions.missionname ASC;

-- 2) Retrieve the mission name, rocket name, payload name, payload type, and payload mass (in kg) for all payloads launched in 2024 
-- without using table aliases. Sort the results in descending order by payload mass.

SELECT missions.missionname,
       rockets.rocketname,
       payloads.payloadname,
       payloads.payloadtype,
       payloads.masskg
FROM payloads
INNER JOIN missions USING(missionid)
INNER JOIN rockets USING(rocketid)
WHERE missions.launchyear = 2024
ORDER BY payloads.masskg DESC;

-- 3) Retrieve all launch sites along with their matching mission names, rockets, and launch years for missions that took place in 
-- 2024 without using table aliases, ensuring that launch sites with no recorded 2024 missions still appear in the results with
-- null values for the mission fields. Sort the results in alphabetical order by launch site name.

SELECT launch_sites.sitename,
       missions.missionname,
       rockets.rocketname,
       missions.launchyear
FROM launch_sites
LEFT JOIN missions ON launch_sites.siteid = missions.siteid AND missions.launchyear = 2024
LEFT JOIN rockets USING(rocketid)
ORDER BY launch_sites.sitename ASC;

-- 4) Write a SQL query using a Common Table Expression (CTE) to calculate the total payload mass (in kg) 
-- deployed by each organization across all missions without using table aliases. 
-- Retrieve the organization name, headquarters country, organization type, and total payload mass, 
-- and sort the results in descending order by total payload mass.

WITH OrgPayloadTotals AS (
    SELECT rockets.orgid, SUM(payloads.masskg) AS TotalPayloadMassKg
    FROM payloads
    INNER JOIN missions USING(missionid)
    INNER JOIN rockets USING(rocketid)
    GROUP BY rockets.orgid
)
SELECT organizations.orgname,
       organizations.headquarterscountry,
       organizations.orgtype,
       OrgPayloadTotals.TotalPayloadMassKg
FROM organizations
LEFT JOIN OrgPayloadTotals USING(orgid)
ORDER BY TotalPayloadMassKg DESC;

-- 5) Write a SQL query using two separate Common Table Expressions (CTEs)—one to calculate total missions by 
-- country code and another to calculate total payload mass by country code without using table aliases. Then, 
-- combine these CTEs with the countries table to display the country name, total number of missions, and total 
-- payload mass (in kg). Sort the results in descending order by total payload mass.

WITH CountryMissionTotals AS (
    SELECT launch_sites.countrycode, COUNT(missions.missionid) AS TotalMissions
    FROM missions
    INNER JOIN launch_sites USING(siteid)
    GROUP BY launch_sites.countrycode
),
CountryPayloadTotals AS (
    SELECT launch_sites.countrycode, SUM(payloads.masskg) AS TotalPayloadMassKg
    FROM payloads
    INNER JOIN missions USING(missionid)
    INNER JOIN launch_sites USING(siteid)
    GROUP BY launch_sites.countrycode
)
SELECT countries.countryname, CountryMissionTotals.TotalMissions, CountryPayloadTotals.TotalPayloadMassKg
FROM countries
LEFT JOIN CountryMissionTotals USING(countrycode)
LEFT JOIN CountryPayloadTotals USING(countrycode)
ORDER BY TotalPayloadMassKg DESC;