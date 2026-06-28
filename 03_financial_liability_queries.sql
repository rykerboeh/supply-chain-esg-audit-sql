--=====================================================================
-- Explore concentration points of organizational financial liability
--=====================================================================

---------------------------------------------------------------------------------------------
-- Purchase order count and total units for suppliers with current "fail" compliance status
---------------------------------------------------------------------------------------------

WITH latest_ranked_audits AS (
		SELECT *,
		       ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
		FROM sustainability_audits
)

SELECT po.supplier_id,
	   s.supplier_name,
	   COUNT(DISTINCT po_id) AS total_purchase_orders,
	   SUM(order_qty) AS total_units
FROM purchase_orders po
JOIN suppliers s
	ON po.supplier_id = s.supplier_id
JOIN latest_ranked_audits a
	ON po.supplier_id = a.supplier_id
WHERE a.rn = 1 AND
	  a.compliance_status = 'Fail'
GROUP BY po.supplier_id, s.supplier_name;

---------------------------------------------------
-- Total financial liability per supplier by year
---------------------------------------------------

-- CTE to calculate total cost per purchase order
WITH purchase_order_totals AS (
	SELECT *,
		   (order_qty * unit_cost) + freight_cost + duty_cost AS total_cost
	FROM purchase_orders
),
-- CTE to create defined compliance status timelines
audit_timelines AS (
	SELECT *,
		   audit_date AS status_start_date,
		   -- Selects next chronological audit as compliance status end date
	       LEAD(audit_date) OVER (PARTITION BY supplier_id ORDER BY audit_date) AS status_end_date
	FROM sustainability_audits
)

SELECT po.supplier_id,
	   s.supplier_name,
	   EXTRACT(YEAR FROM po.po_date) AS year,
	   po.currency,
	   SUM(total_cost) AS total_liability,
	   a.compliance_status
FROM purchase_order_totals po
JOIN suppliers s
	ON po.supplier_id = s.supplier_id
-- Ensures that purchase orders in most recent audit timeline bucket are retained in query output
JOIN audit_timelines a 
  ON po.supplier_id = a.supplier_id
  AND po.po_date >= a.status_start_date 
  AND po.po_date < COALESCE(a.status_end_date, '2027-01-01')
WHERE a.compliance_status IN ('Fail', 'Conditional')
GROUP BY po.supplier_id, s.supplier_name, po.currency, a.compliance_status, year
ORDER BY po.supplier_id, year;

-----------------------------------
-- Risk Concentration by Category
-----------------------------------

WITH latest_ranked_audits AS (
		SELECT *,
		       ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
		FROM sustainability_audits
),
-- CTE calculates total cost per product category
category_totals AS (
	SELECT p.category AS category,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_cost
	FROM products p
	JOIN purchase_orders po
	 	 ON po.sku_id = p.sku_id
	GROUP BY p.category
),
-- CTE calculates total cost per product category from poorly performing suppliers
risk_totals AS (
	SELECT p.category AS category,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_risk_cost
	FROM purchase_orders po
	JOIN products p
	 	 ON p.sku_id = po.sku_id
	JOIN latest_ranked_audits a
		 ON a.supplier_id = po.supplier_id
	WHERE a.rn = 1 AND
		  a.compliance_status IN ('Fail', 'Conditional')
	GROUP BY p.category
)

SELECT c.category,
	   COALESCE(r.total_risk_cost, 0) AS total_risk_cost,
	   c.total_cost,
	   ROUND(COALESCE(r.total_risk_cost, 0) / c.total_cost * 100, 2) AS perc_at_risk
FROM category_totals c
LEFT JOIN risk_totals r
	 ON r.category = c.category
ORDER BY perc_at_risk DESC;

---------------------------------
-- Risk Concentration by Region
---------------------------------

WITH latest_ranked_audits AS (
		SELECT *,
		       ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
		FROM sustainability_audits
),
-- CTE calculates total cost per country
country_totals AS (
	SELECT p.country_of_origin AS country,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_cost
	FROM products p
	JOIN purchase_orders po
	 	 ON po.sku_id = p.sku_id
	GROUP BY p.country_of_origin
),
-- CTE calculates total cost per country from poorly performing suppliers
risk_totals AS (
	SELECT p.country_of_origin AS country,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_risk_cost
	FROM purchase_orders po
	JOIN products p
	 	 ON p.sku_id = po.sku_id
	JOIN latest_ranked_audits a
		 ON a.supplier_id = po.supplier_id
	WHERE a.rn = 1 AND
		  a.compliance_status IN ('Fail', 'Conditional')
	GROUP BY p.country_of_origin
)

SELECT c.country,
	   COALESCE(r.total_risk_cost, 0) AS total_risk_cost,
	   c.total_cost,
	   ROUND(COALESCE(r.total_risk_cost, 0) / c.total_cost * 100, 2) AS perc_at_risk
FROM country_totals c
LEFT JOIN risk_totals r
	 ON r.country = c.country
ORDER BY perc_at_risk DESC;

------------------------------
-- Vendor Concentration Risk
------------------------------

WITH latest_ranked_audits AS (
		SELECT *,
		       ROW_NUMBER() OVER (PARTITION BY supplier_id ORDER BY audit_date DESC) AS rn
		FROM sustainability_audits
),
-- CTE calculates total cost per product category
category_totals AS (
	SELECT p.category AS category,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_cost
	FROM products p
	JOIN purchase_orders po
	 	 ON po.sku_id = p.sku_id
	GROUP BY p.category
),
-- CTE calculates total supplier cost per category
supplier_totals AS (
	SELECT po.supplier_id,
		   p.category AS category,
	   	   SUM((po.order_qty * po.unit_cost) + po.freight_cost + po.duty_cost) AS total_supplier_cost
	FROM purchase_orders po
	JOIN products p
	 	 ON p.sku_id = po.sku_id
	GROUP BY po.supplier_id, p.category
)

SELECT s.supplier_id,
	   s.category,
	   s.total_supplier_cost,
	   c.total_cost AS total_category_cost,
	   ROUND(s.total_supplier_cost/ c.total_cost * 100, 2) AS perc_of_category
FROM supplier_totals s
JOIN category_totals c
	 ON s.category = c.category
JOIN latest_ranked_audits a
	 ON a.supplier_id = s.supplier_id
WHERE a.rn = 1 AND
	  a.compliance_status IN ('Fail', 'Conditional')
ORDER BY perc_of_category DESC;
