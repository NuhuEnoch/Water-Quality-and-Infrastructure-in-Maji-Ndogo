--  To show all tables
SHOW TABLES;

-- Location table limiting it by 10
SELECT *
FROM location
LIMIT 10;

-- Visit table limiting it by 5
SELECT *
FROM md_water_services.visits
LIMIT 5;

-- Water Source table limiting it by 5
SELECT *
FROM md_water_services.water_source
LIMIT 5;

-- Water Quality table limiting it by 5
SELECT *
FROM md_water_services.water_source
LIMIT 5;

-- Well_pollution table limiting it by 5
SELECT * 
FROM md_water_services.well_pollution
LIMIT 5;

/*
  This query retrieves all distinct types of water sources
  from the 'water_source' table in the 'md_water_services' schema.
  The DISTINCT clause ensures that each type appears only once in the result set.
*/
SELECT DISTINCT DISTINCT(type_of_water_source)
FROM md_water_services.water_source;

/* This query selects all columns from the 'well_pollution' table in the 'md_water_services' database where the
water sample result is labeled 'clean' and the biological contamination level is greater than 0.01.*/
SELECT *
FROM md_water_services.well_pollution
WHERE results = "clean"
AND biological > 0.01;
      
-- Creating a backup of the original table to test changes
CREATE TABLE well_pollution_backup AS
  SELECT *
  FROM md_water_services.well_pollution;

-- Case 1a: Updating descriptions for "Clean Bacteria: E. coli"
SET SQL_SAFE_UPDATES = 0;
UPDATE md_water_services.well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';
    
-- Case 1b: Updating descriptions for "Clean Bacteria: Giardia Lamblia"
UPDATE md_water_services.well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';
    
-- Case 2: Updating results for biological contamination
UPDATE md_water_services.well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';


-- Testing to know if the Update took effect --
SELECT *
FROM md_water_services.well_pollution
WHERE description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);
    
    
-- Dropping the Backup Table --

DROP TABLE md_water_services.well_pollution_backup;
