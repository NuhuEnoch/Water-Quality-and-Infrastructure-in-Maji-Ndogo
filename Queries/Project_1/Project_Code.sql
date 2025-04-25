/* 
  -------------------------------------------------------------------------------
PROJECT: Maji Ndogo Water Services
PURPOSE:
This script performs various operations on water service-related tables:
1. Displays all tables in the database.
2. Retrieves data from 'location', 'visits', 'water_source', 'well_pollution', limiting results to a specified number.
3. Retrieves distinct water source types from the 'water_source' table.
4. Selects all clean water samples with biological contamination above a specific threshold.
5. Creates a backup of the 'well_pollution' table for testing purposes.
6. Updates descriptions and results in the 'well_pollution' table based on specific conditions.
7. Verifies if the updates took effect by querying the 'well_pollution' table.
8. Drops the backup table after testing.

  AUTHOR: [Nuhu Enoch]
  DATE: [25-04-2025]
  -------------------------------------------------------------------------------
*/


-- Display all available tables in the current database
SHOW TABLES;


-- Retrieve the first 10 records from the 'location' table
SELECT *
FROM location
LIMIT 10;


-- Retrieve the first 5 records from the 'visits' table in the 'md_water_services' schema
SELECT *
FROM md_water_services.visits
LIMIT 5;


-- Retrieve the first 5 records from the 'water_source' table in the 'md_water_services' schema
SELECT *
FROM md_water_services.water_source
LIMIT 5;


-- Retrieve the first 5 records from the 'water_quality' table in the 'md_water_services' schema
SELECT *
FROM md_water_services.water_quality
LIMIT 5;


-- Retrieve the first 5 records from the 'well_pollution' table in the 'md_water_services' schema
SELECT * 
FROM md_water_services.well_pollution
LIMIT 5;


-- Get all unique types of water sources from the 'water_source' table
SELECT DISTINCT DISTINCT(type_of_water_source)
FROM md_water_services.water_source;


-- Select water samples marked 'clean' but with biological contamination greater than 0.01
SELECT *
FROM md_water_services.well_pollution
WHERE results = "clean"
AND biological > 0.01;


-- Create a backup of the 'well_pollution' table for safe testing
CREATE TABLE well_pollution_backup AS
  SELECT *
  FROM md_water_services.well_pollution;


-- Allow unsafe updates to proceed by disabling safe update mode
SET SQL_SAFE_UPDATES = 0;
UPDATE md_water_services.well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';


-- Standardize description for E. coli entries in the 'well_pollution' table
UPDATE md_water_services.well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';


-- Standardize description for Giardia Lamblia entries in the 'well_pollution' table
UPDATE md_water_services.well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.01 AND results = 'Clean';


-- Update 'results' field to indicate biological contamination where applicable
SELECT *
FROM md_water_services.well_pollution
WHERE description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);
    
    
-- Delete the backup table after confirming updates are correct
DROP TABLE md_water_services.well_pollution_backup;
