--====================================================================
-- Explore basic supplier metrics and current compliance standing
--====================================================================

------------------------------
-- Supplier count per region
------------------------------

SELECT region,
	   COUNT(*) number_of_suppliers
FROM suppliers
GROUP BY region
ORDER BY number_of_suppliers DESC;

-------------------------------
-- Contract length by supplier
-------------------------------

SELECT supplier_id,
	   supplier_name,
	   ROUND((CURRENT_DATE - contract_start_date)/365.25, 2) AS contract_length_years
FROM suppliers
ORDER BY contract_length_years DESC;

---------------------------------------
-- Most recent compliance audit status
---------------------------------------

-- Row number CTE to select most recent audit of each supplier
WITH latest_ranked_audits AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
	FROM sustainability_audits
)
SELECT s.supplier_id,
	   s.supplier_name,
	   audit_date,
	   waste_diversion_rate,
	   labor_compliance_score,
	   compliance_status
FROM latest_ranked_audits a
JOIN suppliers s
	ON s.supplier_id = a.supplier_id
WHERE rn = 1
ORDER BY compliance_status;

-------------------------------------------------------
-- Suppliers currently holding poor compliance status
-------------------------------------------------------

WITH latest_ranked_audits AS (
	SELECT *,
		   ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
	FROM sustainability_audits
)
SELECT s.supplier_id,
	   s.supplier_name,
	   audit_date,
	   waste_diversion_rate,
	   labor_compliance_score,
	   compliance_status
FROM latest_ranked_audits a
JOIN suppliers s
	ON s.supplier_id = a.supplier_id
WHERE rn = 1 AND
	  compliance_status != 'Pass'
ORDER BY compliance_status;

---------------------------------------
-- Supplier sustainability trajectory
---------------------------------------

-- Row number CTE to select first audit of each supplier
WITH first_ranked_audits AS (
		SELECT *,
			   ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date ASC) AS rn
		FROM sustainability_audits
),
	latest_ranked_audits AS (
		SELECT *,
		       ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
		FROM sustainability_audits
	)

SELECT f.supplier_id,
	   s.supplier_name,
	   f.audit_date AS first_audit_date,
	   l.audit_date AS latest_audit_date,
	   -- Conditional case/when statements to define supplier sustainability trajectory for each audit metric
	   CASE
	      WHEN f.waste_diversion_rate - l.waste_diversion_rate < 0 THEN 'Improving'
		  WHEN f.waste_diversion_rate - l.waste_diversion_rate > 0 THEN 'Worsening'
		  ELSE 'Stagnant'
	   END AS waste_diversion_trajectory,
	   CASE
	      WHEN f.water_liters_per_unit - l.water_liters_per_unit > 0 THEN 'Improving'
		  WHEN f.water_liters_per_unit - l.water_liters_per_unit < 0 THEN 'Worsening'
		  ELSE 'Stagnant'
	   END AS water_trajectory,
	   CASE
	      WHEN f.labor_compliance_score - l.labor_compliance_score < 0 THEN 'Improving'
		  WHEN f.labor_compliance_score - l.labor_compliance_score > 0 THEN 'Worsening'
		  ELSE 'Stagnant'
	   END AS labor_compliance_trajectory
FROM first_ranked_audits f
JOIN latest_ranked_audits l
	ON f.supplier_id = l.supplier_id
JOIN suppliers s
	ON f.supplier_id = s.supplier_id
WHERE f.rn = 1 AND
	  l.rn = 1
ORDER BY f.supplier_id;
