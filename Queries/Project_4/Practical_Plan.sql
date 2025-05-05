/* 
  -------------------------------------------------------------------------------
Project: Maji Ndogo Water Services
This script creates and manages the 'Project_progress' table to track water source improvement projects, including details like source type, location, improvement recommendations, and status.
It also includes queries for retrieving, filtering, and recommending improvements based on water source conditions, such as contamination levels, infrastructure issues, and queue times for shared taps.
The improvements are determined through control flow logic (CASE statements) for each source type and condition.
            -- Summary of improvements:
1. Rivers → Drill wells.
2. Wells with chemical contamination → Install RO filter.
3. Wells with biological contamination → Install UV and RO filter.
4. Shared taps with queue > 30 min → Install additional taps (calculated by FLOOR(time_in_queue / 30)).
5. Broken in-home taps → Diagnose local infrastructure.
Improvements for wells and shared taps require IF logic, which will be implemented using CASE functions.
  -------------------------------------------------------------------------------
*/


-- Creates a Project_progress table to track the status and details of water source improvement projects with data integrity constraints and predefined status values.
CREATE TABLE Project_progress (
		Project_id SERIAL PRIMARY KEY,         -- Unique key for sources in case we visit the same source more than once in the future.
		source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,           -- Each of the sources we want to improve should exist, and should refer to the source table. This ensures data integrity.
		Address VARCHAR(50),
		Town VARCHAR(30),
		Province VARCHAR(30),
		Source_type VARCHAR(50),
		Improvement VARCHAR(50),				-- What the engineers should do at that place
		Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),   /* We want to limit the type of information engineers can give us, so we limit Source_status.
																														− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
																														− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.*/
		Date_of_completion DATE,				-- Engineers will add this the day the source has been upgraded
		Comments TEXT							-- Engineers can leave comments. We use a TEXT type that has no limit on char length
	);


-- Query to retrieve project progress data, including location, water source details, and pollution results
SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
	well_pollution.results
FROM water_source
LEFT JOIN well_pollution
	ON water_source.source_id = well_pollution.source_id
INNER JOIN visits
  ON water_source.source_id = visits.source_id
INNER JOIN location
  ON location.location_id = visits.location_id;


-- Filter data for sources with visit_count = 1, including contaminated wells, rivers, broken taps, and shared taps with queue times >= 30 min.
SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results,
    visits.visit_count,
    visits.time_in_queue
FROM water_source
LEFT JOIN well_pollution 
  ON water_source.source_id = well_pollution.source_id
INNER JOIN visits
	ON water_source.source_id = visits.source_id
INNER JOIN location
  ON location.location_id = visits.location_id
WHERE visits.visit_count = 1  -- This must always be true
AND (  												-- AND one of the following (OR) options must be true as well.
		  well_pollution.results != 'Clean'  												-- Only include contaminated wells
      OR water_source.type_of_water_source IN ('River', 'tap_in_home_broken')  		-- Include all rivers and broken home taps
      OR (water_source.type_of_water_source = 'Shared Tap' AND visits.time_in_queue >= 30)  -- Include shared taps with queue time >= 30 min
    );


-- Apply control flow logic to assign appropriate filter installation or improvement based on water source contamination results and type
SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results,
    visits.visit_count,
    visits.time_in_queue,
    CASE
        -- Step 1: Wells
        WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results = 'Contaminated: Chemical' 
            THEN 'Install RO filter'
        WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results = 'Contaminated: Biological' 
            THEN 'Install UV and RO filter'
        -- Step 2: Rivers
        WHEN water_source.type_of_water_source = 'River' 
            THEN 'Drill well'
        ELSE NULL  -- Default case
    END AS Improvements
FROM water_source
LEFT JOIN well_pollution
  ON water_source.source_id = well_pollution.source_id
INNER JOIN visits
  ON water_source.source_id = visits.source_id
INNER JOIN location
  ON location.location_id = visits.location_id
WHERE visits.visit_count = 1  -- This must always be true
  AND (  -- AND one of the following (OR) options must be true as well.
        well_pollution.results != 'Clean'  -- Only include contaminated wells
        OR water_source.type_of_water_source IN ('River', 'tap_in_home_broken')  -- Include all rivers and broken home taps
        OR (water_source.type_of_water_source = 'Shared Tap' AND visits.time_in_queue >= 30)  -- Include shared taps with queue time >= 30 min
    );
    
      
-- Assigns improvement recommendations based on water source type, contamination status, and visit metrics, including diagnosing broken in-home taps
SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results,
    visits.visit_count,
    visits.time_in_queue,
  CASE
          -- Step 1: Wells
    WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results = 'Contaminated: Chemical' 
      THEN 'Install RO filter'
    WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results = 'Contaminated: Biological' 
      THEN 'Install UV and RO filter' 
          -- Step 2: Rivers
    WHEN water_source.type_of_water_source = 'River' 
      THEN 'Drill well'
          -- Step 3: Shared taps
    WHEN water_source.type_of_water_source = 'Shared Tap' AND visits.time_in_queue >= 30 
      THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
          -- Step 4: In-home taps (broken infrastructure)
    WHEN water_source.type_of_water_source = 'tap_in_home_broken' 
      THEN 'Inspect and repair infrastructure'
          -- Step 5: Diagnose local infrastructure for broken taps
    WHEN water_source.type_of_water_source = 'tap_in_home_broken' 
      THEN 'Diagnose local infrastructure'
    ELSE NULL  -- Default case, should now never happen!
  END AS Improvements
FROM water_source
LEFT JOIN well_pollution
  ON water_source.source_id = well_pollution.source_id
INNER JOIN visits
  ON water_source.source_id = visits.source_id
INNER JOIN location
  ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
    AND (  
          well_pollution.results != 'Clean'  -- Only include contaminated wells
          OR water_source.type_of_water_source IN ('River', 'tap_in_home_broken')  -- Include all rivers and broken home taps
          OR (water_source.type_of_water_source = 'Shared Tap' AND visits.time_in_queue >= 30)  -- Include shared taps with long queue times
    );
