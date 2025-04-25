/* 
  -------------------------------------------------------------------------------
  PROJECT: Maji Ndogo Water Services 
This SQL script performs an in-depth analysis of discrepancies between auditor-reported and field surveyor-reported
water source quality scores during initial site visits.

The objective is to:
- Compare audit scores to field-collected scores.
- Identify mismatched entries indicating scoring errors.
- Correlate errors with individual employees to monitor performance.
- Flag potential anomalies, especially entries mentioning suspicious terms like "cash".

The logic includes:
- Table creation (commented out for optional execution).
- Several join operations across `auditor_report`, `visits`, `water_quality`, `water_source`, and `employee` tables.
- Filtering for first-time visits (`visit_count = 1`) to ensure consistency.
- Use of Common Table Expressions (CTEs) to:
  - Aggregate mismatches (errors).
  - Calculate and compare employee-level error rates.
  - Identify outlier employees with above-average errors.
  - Extract all potentially suspicious entries linked to those outliers.
- Creation of a reusable SQL view (`Incorrect_Records`) for convenience and testing.
- Final filtering of records that may indicate corrupt practices or quality assurance issues.

This script supports quality control, employee accountability, and early detection of data integrity risks.

  AUTHOR: [Nuhu Enoch]
  DATE: [25-04-2025]
  -------------------------------------------------------------------------------
*/


/*
	DROP TABLE IF EXISTS `auditor_report`;
	CREATE TABLE `auditor_report`
	(
		`location_id` VARCHAR(32),
		`type_of_water_source` VARCHAR(64),
		`true_water_source_score` int DEFAULT NULL,
		`statements` VARCHAR(255)
	);
*/


-- Getting the location_id and true_water_source_score columns from auditor_report. --
SELECT
	location_id,
  	true_water_source_score
FROM md_water_services.auditor_report;


-- Connecting the visits table using join to the auditor_report table.--
SELECT
	AR.location_id AS Audit_Location,
	AR.true_water_source_score,
	V.location_id AS Visit_Location,
	V.record_id
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id;

    
-- Retrieving corresponding scores from the water_quality table. Our interest is in the subjective_quality_score. 
SELECT
	AR.location_id AS Audit_Location,
	AR.true_water_source_score,
	V.location_id AS Visit_Location,
	V.record_id,
	WQ.subjective_quality_score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id;


-- Renaming the scores to surveyor_score and auditor_score to make it clear which scores we're looking at in the results set.
 SELECT
	AR.location_id,
	V.record_id,
	AR.true_water_source_score AS Auditor_Score,
	WQ.subjective_quality_score AS Surveyor_Score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id
WHERE V.visit_count = 1
AND WQ.subjective_quality_score = AR.true_water_source_score;


-- Lets get the 102 records that are incorrect --
SELECT
	AR.location_id,
	V.record_id,
	AR.true_water_source_score AS Auditor_Score,
	WQ.subjective_quality_score AS Surveyor_Score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id
WHERE V.visit_count = 1
AND WQ.subjective_quality_score != AR.true_water_source_score;
    
    
-- Checking if there are any errors.
SELECT
	AR.location_id,
	AR.type_of_water_source AS Auditor_Source,
	WS.type_of_water_source AS Surveyor_Source,
	V.record_id,
	AR.true_water_source_score AS Auditor_Score,
	WQ.subjective_quality_score AS Surveyor_Score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id
JOIN md_water_services.water_source AS WS
	ON V.source_id = WS.source_id
WHERE V.visit_count = 1
AND WQ.subjective_quality_score != AR.true_water_source_score;
    

-- Identifying mismatched scores, linking them to the employees who recorded them
SELECT
	AR.location_id,
	V.record_id,
	v.assigned_employee_id,
	AR.true_water_source_score AS Auditor_Score,
	WQ.subjective_quality_score AS Surveyor_Score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id
JOIN md_water_services.water_source AS WS
	ON V.source_id = WS.source_id
WHERE V.visit_count = 1
AND WQ.subjective_quality_score != AR.true_water_source_score;


-- Fetching mismatched water quality scores with employee names for first-time visits
SELECT
	AR.location_id,
	V.record_id,
	E.employee_name,
	AR.true_water_source_score AS Auditor_Score,
	WQ.subjective_quality_score AS Surveyor_Score
FROM md_water_services.auditor_report AS AR
JOIN md_water_services.visits AS V
	ON	AR.location_id = V.location_id
JOIN md_water_services.water_quality AS WQ
	ON V.record_id = WQ.record_id
JOIN md_water_services.employee AS E
	ON V.assigned_employee_id = E.assigned_employee_id
WHERE V.visit_count = 1
AND WQ.subjective_quality_score != AR.true_water_source_score;


-- Defining a CTE to identify mismatched water source scores between auditors and surveyors on first visits.
WITH Incorrect_Records AS (
		SELECT
			AR.location_id,
			V.record_id,
			E.employee_name,
			AR.true_water_source_score AS Auditor_Score,
			WQ.subjective_quality_score AS Surveyor_Score
		FROM md_water_services.auditor_report AS AR
		JOIN md_water_services.visits AS V
			ON	AR.location_id = V.location_id
		JOIN md_water_services.water_quality AS WQ
			ON V.record_id = WQ.record_id
		JOIN md_water_services.employee AS E
			ON V.assigned_employee_id = E.assigned_employee_id
		WHERE V.visit_count = 1
		AND WQ.subjective_quality_score != AR.true_water_source_score
    )
SELECT *
FROM Incorrect_Records;


-- Count the number of scoring mismatches (mistakes) made by each employee during first visits
WITH Incorrect_Records AS (
		SELECT
			AR.location_id,
			V.record_id,
			E.employee_name,
			AR.true_water_source_score AS Auditor_Score,
			WQ.subjective_quality_score AS Surveyor_Score
		FROM md_water_services.auditor_report AS AR
		JOIN md_water_services.visits AS V
			ON	AR.location_id = V.location_id
		JOIN md_water_services.water_quality AS WQ
			ON V.record_id = WQ.record_id
		JOIN md_water_services.employee AS E
			ON V.assigned_employee_id = E.assigned_employee_id
		WHERE V.visit_count = 1
		AND WQ.subjective_quality_score != AR.true_water_source_score
    )
SELECT
	employee_name,
	COUNT(*) AS Number_of_Mistakes
FROM Incorrect_Records
GROUP BY employee_name
ORDER BY Number_of_Mistakes DESC;


-- This query finds employees whose number of audit-survey mismatches exceeds the average mistake count across all employees
WITH Incorrect_Records AS (
    SELECT  
        AR.location_id,  
        V.record_id,  
        E.employee_name,  
        AR.true_water_source_score AS Auditor_Score,  
        WQ.subjective_quality_score AS Surveyor_Score  
    FROM md_water_services.auditor_report AS AR  
    JOIN md_water_services.visits AS V  
        ON AR.location_id = V.location_id  
    JOIN md_water_services.water_quality AS WQ  
        ON V.record_id = WQ.record_id  
    JOIN md_water_services.employee AS E  
        ON V.assigned_employee_id = E.assigned_employee_id  
    WHERE V.visit_count = 1  
    AND WQ.subjective_quality_score != AR.true_water_source_score  
), 
error_count AS (   -- Count the number of mistakes (mismatched scores) made by each employee
    SELECT  
        employee_name,  
        COUNT(*) AS Number_of_Mistakes  
    FROM Incorrect_Records  
    GROUP BY employee_name  
) 

SELECT   -- Select employees whose number of mistakes is greater than the average number of mistakes across all employees
    employee_name, 
    Number_of_Mistakes 
FROM error_count  
WHERE Number_of_Mistakes > (
    SELECT AVG(Number_of_Mistakes) 
    FROM error_count
);


-- Creating a view listing records where the surveyor's and auditor's water source scores differ on first visits
CREATE VIEW Incorrect_Records AS (
    SELECT  
        AR.location_id,  
        V.record_id,  
        E.employee_name,  
        AR.true_water_source_score AS Auditor_Score,  
        WQ.subjective_quality_score AS Surveyor_Score,
        AR.statements
    FROM md_water_services.auditor_report AS AR  
    JOIN md_water_services.visits AS V  
        ON AR.location_id = V.location_id  
    JOIN md_water_services.water_quality AS WQ  
        ON V.record_id = WQ.record_id  
    JOIN md_water_services.employee AS E  
        ON V.assigned_employee_id = E.assigned_employee_id  
    WHERE V.visit_count = 1  
    AND WQ.subjective_quality_score != AR.true_water_source_score  
);


-- Creating a CTE to count mistakes per employee and select all results from it for testing
WITH error_count AS (
	SELECT
		employee_name,
      		COUNT(employee_name) AS Number_of_Mistakes
	FROM Incorrect_Records
        GROUP BY employee_name
	ORDER BY Number_of_Mistakes DESC
    )
SELECT *
FROM error_count;


-- Identifying employees whose number of mistakes exceeds the average, using a CTE to first count mistakes per employee
WITH error_count AS ( -- Creating a CTE to count the number of mistakes per employee
	SELECT
		employee_name,
      		COUNT(employee_name) AS Number_of_Mistakes
	FROM incorrect_records
        GROUP BY employee_name
	ORDER BY Number_of_Mistakes
    )
SELECT *     -- Select employees with above-average mistakes
FROM error_count
WHERE Number_of_Mistakes >
	(
		SELECT AVG(Number_of_Mistakes)
		FROM error_count
	)
ORDER BY Number_of_Mistakes DESC;


-- Finds employees with more mistakes than average, and filters their records related to 'cash' for investigation of potential issues.
WITH error_count AS (  -- This CTE calculates the number of mistakes each employee made --
	SELECT  
		employee_name,  
		COUNT(*) AS Number_of_Mistakes  
	FROM Incorrect_Records     -- Incorrect_records is a view that joins the audit report to the database for records where the auditor and employees scores are different
	GROUP BY employee_name  
	), 
suspect_list AS	(	-- This CTE SELECTS the employees with above−average mistakes --
	SELECT *
	FROM error_count
	WHERE Number_of_Mistakes >
		(
			SELECT AVG(Number_of_Mistakes)
			FROM error_count
		)
	)
-- This query filters all of the records where the "corrupt" employees gathered data. --
SELECT
	employee_name,
  	Location_id,
  	statements
FROM Incorrect_Records
WHERE employee_name IN
	(
		SELECT employee_name
		FROM suspect_list
    )
AND statements LIKE '%cash%';   -- Filtering for records containing "cash"


-- Retrieving records containing “cash” from Incorrect_Records for employees not in the high-error CTE suspect_list.
WITH error_count AS (  -- This CTE calculates the number of mistakes each employee made --
	SELECT  
		employee_name,  
		COUNT(*) AS Number_of_Mistakes  
	FROM Incorrect_Records     -- Incorrect_records is a view that joins the audit report to the database for records where the auditor and employees scores are different			
	GROUP BY employee_name  
	), 
suspect_list AS	(	-- This CTE SELECTS the employees with above−average mistakes --
	SELECT *
	FROM error_count
	WHERE Number_of_Mistakes >
		(
			SELECT AVG(Number_of_Mistakes)
			FROM error_count
		)
	)
-- This query filters all of the records where the "corrupt" employees gathered data. --
SELECT
	employee_name,
	Location_id,
	statements
FROM Incorrect_Records
WHERE statements LIKE '%cash%'   -- Filtering for records containing "cash"
AND employee_name NOT IN
		(
			SELECT employee_name
			FROM suspect_list
		);


-- INSIGHT
/*
	Based on the data, Zuriel Matembo, Malachi Mavuso, Bello Azibo, and Lalitha Kaburi:
	1. Exceeded the average mistake rate among their peers.
	2. Are uniquely associated with incriminating statements.
	While not conclusive proof, this pattern raises significant concerns and warrants further investigation.
*/
