/* 
  -------------------------------------------------------------------------------
  PROJECT: Maji Ndogo Water Services - Data Cleaning & Insights Generation Script
  PURPOSE:
    This script is designed to clean and analyze survey data from the Maji Ndogo Water Services 
    database. It includes data standardization, performance metrics, water source analysis, and 
    accessibility insights to guide strategic planning and infrastructure improvement efforts.

  SECTIONS:
    1. Data Cleaning:
        - Disable safe mode to allow unrestricted updates
        - Standardize employee emails and trim phone numbers

    2. Employee Performance:
        - Analyze staff distribution across towns
        - Identify top-performing field surveyors by number of visits

    3. Location Analysis:
        - Count records per town and province
        - Identify prevalent location types and their coverage

    4. Water Source Analysis:
        - Total population served per water source type
        - Average and percentage usage of water source types
        - Rank sources based on usage to guide investment prioritization

    5. Visit and Queue Analysis:
        - Determine duration of the survey period
        - Average queue times by day and hour
        - Peak times and days for water collection activity

  OUTCOME:
    This script enables the Maji Ndogo Water Services team to assess the current state of water 
    infrastructure, employee distribution, and community access. It offers actionable insights 
    for improving water service delivery and reducing wait times.
  -------------------------------------------------------------------------------
*/


USE md_water_services;

-- DATA CLEANING --
-- Disabling MySQL's safe update mode to allow UPDATE/DELETE queries without a restrictive WHERE clause.
SET SQL_SAFE_UPDATES = 0;  


-- Reviewing the employee table
SELECT *
FROM md_water_services.employee;


-- Generating standardized email addresses by formatting employee names and appending '@ndogowater.gov'
SELECT
	CONCAT(LOWER(REPLACE(employee_name, ' ','.')),'@ndogowater.gov') AS New_Email
FROM md_water_services.employee;


-- UPDATING THE EMAIL COLUMN --
UPDATE md_water_services.employee
SET
	email = CONCAT(
		LOWER(REPLACE(employee_name, ' ','.')),
		'@ndogowater.gov'
	);


-- Testing the Phone Number Column --
SELECT LENGTH(phone_number)
FROM md_water_services.employee;


-- UPDATING THE Phone_Number COLUMN --
UPDATE md_water_services.employee
SET phone_number = TRIM(phone_number);


-- Using the employee table to count how many of our employees live in each town. --
SELECT
	town_name,
	COUNT(*) AS numb_of_employees
FROM md_water_services.employee  
GROUP BY town_name  
ORDER BY numb_of_employees DESC;


-- Getting the employee_ids and use them to get the names, email and phone numbers of the three field surveyors with the most location visits.  
SELECT
	assigned_employee_id,
	COUNT(visit_count) AS numb_of_visit
FROM md_water_services.visits
GROUP BY assigned_employee_id
ORDER BY numb_of_visit DESC;


-- Getting the names, email and phone numbers of the three field surveyors with the most location visits --
-- HONOURING THE WORKERS --
SELECT
	DISTINCT employee_name,
	phone_number,
	email
FROM md_water_services.employee
WHERE assigned_employee_id IN (1, 30, 34);


-- Alternatively we are using this Join Query for more clearity --
SELECT
	E.assigned_employee_id,
	E.employee_name,
	E.phone_number,
	E.email,
	COUNT(visit_count) AS numb_of_visit
FROM md_water_services.employee AS E
JOIN md_water_services.visits AS V
  ON E.assigned_employee_id = V.assigned_employee_id
GROUP BY
  E.assigned_employee_id,
  E.employee_name,
  E.phone_number,
  E.email
ORDER BY numb_of_visit DESC
LIMIT 3;


-- ANALYSING LOCATION --
-- We are looking at some of the tables in the dataset at a larger scale, identify some trends, summarise important data, and draw insights.

-- Viewing the Location Table --
SELECT *
FROM md_water_services.location;


-- Creating a query that counts the number of records per town --   
SELECT
    town_name,
    COUNT(town_name) AS Record_per_town
FROM md_water_services.location
GROUP BY town_name
ORDER BY Record_per_town DESC;


-- Query that counts the number of records per town --
SELECT
	province_name,
	COUNT(province_name) AS Record_per_province
FROM md_water_services.location
GROUP BY province_name
ORDER BY Record_per_province DESC;


-- Count records per town in each province, ordered by province and count descending      
SELECT
	province_name,
	town_name,
	COUNT(town_name) AS Record_per_town
FROM md_water_services.location
GROUP BY
	province_name,
	town_name
ORDER BY
	province_name ASC,
	Record_per_town DESC;


-- Looking at the number of records for each location type --
SELECT
	location_type,
	COUNT(location_type) AS number_of_sources
FROM md_water_services.location
GROUP BY location_type
ORDER BY number_of_sources DESC;
    
/*         --Some insights gained from the location table--
  1. The entire country was properly canvassed, and the dataset represents the situation on the ground.
  2. 60% of the water sources are in rural communities across Maji Ndogo
*/


-- DIVING INTO THE WATER SOURCES--

SELECT *
FROM md_water_services.water_source;
    

--  Query to know how many people were surveyed in total --    
SELECT SUM(number_of_people_served) AS Total_Served
FROM md_water_services.water_source;


-- Query to know how many wells, taps and rivers are there --
SELECT
	type_of_water_source,
	COUNT(*) AS source_count
FROM md_water_services.water_source
GROUP BY type_of_water_source;


-- Query to know how many people share particular types of water sources on average --
SELECT
	type_of_water_source,
	ROUND(AVG(number_of_people_served)) AS avg_people_per_source
FROM md_water_services.water_source
GROUP BY type_of_water_source;


-- Query to know how many people are getting water from each type of source --
SELECT
	type_of_water_source,
	SUM(number_of_people_served) AS population_served
FROM md_water_services.water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;


-- % using the total served gotten earlier (27,628,140) --    
SELECT
	type_of_water_source,
	ROUND((SUM(number_of_people_served)/27628140)*100) AS percentage_people_per_source
FROM md_water_services.water_source
GROUP BY type_of_water_source
ORDER BY percentage_people_per_source DESC;


/* #--START OF A SOLUTION--# */

-- Ranking --
SELECT  
    type_of_water_source,     
    SUM(number_of_people_served) AS total_people_served,     
    RANK() OVER (
        ORDER BY SUM(number_of_people_served) DESC
    ) AS rank_by_population
FROM md_water_services.water_source
GROUP BY type_of_water_source;


-- Ranking for Priority(Solution) --
SELECT  
    source_id,
    type_of_water_source,
    number_of_people_served,
    RANK() OVER (
        PARTITION BY type_of_water_source 
        ORDER BY number_of_people_served DESC
    ) AS priority_rank
FROM md_water_services.water_source
GROUP BY
	source_id,
  type_of_water_source,
  number_of_people_served
ORDER BY priority_rank DESC;


-- Row Number Priority --
SELECT  
    source_id,
    type_of_water_source,
    number_of_people_served,
    ROW_NUMBER() OVER (
        PARTITION BY type_of_water_source 
        ORDER BY number_of_people_served DESC
    ) AS priority_rank
FROM md_water_services.water_source
ORDER BY priority_rank ASC;  -- Show the highest-priority sources first


/* #--ANALYSING QUEUES--# */

-- Viewing the Visit Table --
SELECT *
FROM md_water_services.visits;


-- How long the survey took --
SELECT
	MIN(time_of_record) AS Start_Survey,
	MAX(time_of_record) AS End_Survey,
	TIMESTAMPDIFF(SECOND, MIN(time_of_record), MAX(time_of_record) ) AS Duration_in_Seconds,
	TIMESTAMPDIFF(MINUTE, MIN(time_of_record), MAX(time_of_record) ) AS Duration_in_Minutes,
	TIMESTAMPDIFF(HOUR, MIN(time_of_record), MAX(time_of_record) ) AS Duration_in_Hours,
	TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record) ) AS Duration_in_Days
FROM md_water_services.visits;


-- The average total queue time for water --
SELECT 
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS avg_queue_time
FROM md_water_services.visits;


-- The average queue time on different days --
SELECT 
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue,0))) AS avg_queue_time_minutes
FROM md_water_services.visits
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');


-- Time during the day people collect water --
SELECT 
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0))) AS avg_queue_time
FROM md_water_services.visits
GROUP BY hour_of_day
ORDER BY hour_of_day;
    
    
SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
	-- Sunday --
	ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Sunday,         
	-- Monday --
	ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Monday,   
	-- Tuesday --
    ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Tuesday,   
	-- Wednesday --
    ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Wednesday,
	-- Thursday --
    ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Thursday,
	-- Friday --
    ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Friday,
	-- Saturday --
    ROUND(AVG(
		CASE
			WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
			ELSE NULL
		END
			),0) AS Saturday
FROM md_water_services.visits
WHERE time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY hour_of_day
ORDER BY hour_of_day;

/* 
          #--Water Accessibility and infrastructure summary report--#
This survey aimed to identify the water sources people use and determine both the total and average number of users for
each source. Additionally, it examined the duration citizens typically spend in queues to access water.

			#--INSIGHTs--#
1. Most water sources are rural.
2. 43% of our people are using shared taps. 2000 people often share one tap.
3. 31% of our population has water infrastructure in their homes, but within that group, 45% face
   non-functional systems due to issues with pipes, pumps, and reservoirs.
4. 18% of our people are using wells of which, but within that, only 28% are clean..
5. Our citizens often face long wait times for water, averaging more than 120 minutes.
6. In terms of queues:
	- Queues are very long on Saturdays.
	- Queues are longer in the mornings and evenings.
	- Wednesdays and Sundays have the shortest queues.
*/


