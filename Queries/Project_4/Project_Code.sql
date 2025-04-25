/* 
  -------------------------------------------------------------------------------
PROJECT: Maji Ndogo Water Services 
This script consolidates and analyzes data from multiple tables (visits, well_pollution, location, and water_source) to:
1. Join the data using different JOIN operations (LEFT JOIN and INNER JOIN) to handle missing and matching records.
2. Create a view combining relevant data for easier analysis.
3. Calculate the percentage distribution of people served by each water source type per province.
4. Calculate the source distribution per town while addressing duplicate town names by grouping with province.

  AUTHOR: [Nuhu Enoch]
  DATE: [25-04-2025]
  -------------------------------------------------------------------------------
*/


-- Joins multiple tables to consolidate data on water sources, locations, visits, and pollution results for analysis
SELECT
  water_source.type_of_water_source,
  location.town_name,
  location.province_name,
  location.location_type,
  water_source.number_of_people_served,
  visits.time_in_queue,
  well_pollution.results
FROM visits
LEFT JOIN well_pollution
  ON well_pollution.source_id = visits.source_id
INNER JOIN location
  ON location.location_id = visits.location_id
INNER JOIN water_source
  ON water_source.source_id = visits.source_id
WHERE visits.visit_count = 1;


-- Creates a view that combines data from multiple tables to simplify the analysis of water source, location, and related metrics
CREATE VIEW combined_analysis_table AS      -- This view assembles data from different tables into one to simplify analysis
  SELECT
    water_source.type_of_water_source AS source_type,
		location.town_name,
		location.province_name,
		location.location_type,
		water_source.number_of_people_served AS people_served,
		visits.time_in_queue,
		well_pollution.results
	FROM visits
	LEFT JOIN well_pollution
	  ON well_pollution.source_id = visits.source_id
	INNER JOIN location
	  ON location.location_id = visits.location_id
	INNER JOIN water_source
	  ON water_source.source_id = visits.source_id
	WHERE visits.visit_count = 1;
        
               
-- Calculate the percentage of people served by each water source type per province, based on total population served in each province.
WITH province_totals AS (
		SELECT
			province_name,
			SUM(people_served) AS total_ppl_serv
		FROM
			combined_analysis_table
		GROUP BY
			province_name
	)
SELECT
	ct.province_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN source_type = 'river'
	THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN source_type = 'shared_tap'
	THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
	THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
	THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN source_type = 'well'
	THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM combined_analysis_table ct
JOIN province_totals pt ON ct.province_name = pt.province_name
GROUP BY ct.province_name
ORDER BY ct.province_name;   


-- Group by province and town to handle duplicate town names and calculate source distribution per town
WITH town_totals AS (		-- This CTE calculates the population of each town --
			                  -- Since there are two Harare towns, we have to group by province_name and town_name
		SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
		FROM combined_analysis_table
		GROUP BY province_name,town_name
	)
SELECT
	ct.province_name,
	ct.town_name,
	ROUND((SUM(CASE WHEN source_type = 'river'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN source_type = 'shared_tap'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN source_type = 'well'
	THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM combined_analysis_table ct
JOIN town_totals tt								-- Since the town names are not unique, we have to join on a composite key
  ON ct.province_name = tt.province_name
AND ct.town_name = tt.town_name
GROUP BY 							-- We group by province first, then by town.
	ct.province_name,
	ct.town_name
ORDER BY ct.town_name;
