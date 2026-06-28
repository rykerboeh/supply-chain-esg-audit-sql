--=====================================================================
-- Explore concentration points of organizational financial liability
--=====================================================================

--------------------------------------------------------------------------------
-- Do suppliers with worse compliance status experience worse shipping delays?
--------------------------------------------------------------------------------

WITH shipment_delays AS(
	SELECT *,
		   delivery_date - promised_delivery_date AS days_late
	FROM purchase_orders
),
audit_timelines AS (
	SELECT *,
		   audit_date AS status_start_date,
	       LEAD(audit_date) OVER (PARTITION BY supplier_id ORDER BY audit_date) AS status_end_date
	FROM sustainability_audits
)

SELECT a.compliance_status,
	   ROUND(AVG(days_late), 2) as avg_days_late
FROM audit_timelines a
JOIN shipment_delays s
  ON s.supplier_id = a.supplier_id
  AND s.po_date >= a.status_start_date 
  AND s.po_date < COALESCE(a.status_end_date, '2027-01-01')
GROUP BY a.compliance_status;

-------------------------------------------------------
-- Are failing suppliers driving up carbon footprint?
-------------------------------------------------------

WITH audit_timelines AS (
	SELECT *,
		   audit_date AS status_start_date,
	       LEAD(audit_date) OVER (PARTITION BY supplier_id ORDER BY audit_date) AS status_end_date
	FROM sustainability_audits
)

SELECT 
    -- Ensures pre-audit purchase orders are retained in query output
    COALESCE(a.compliance_status, 'No Audit History') AS compliance_status,
	-- Build count statements per shipping mode and calculate percent of total purchase orders
    ROUND(COUNT(CASE WHEN po.shipping_mode = 'Air' THEN 1 END) * 100.0 / NULLIF(COUNT(po.po_id), 0), 2) AS perc_air,
    ROUND(COUNT(CASE WHEN po.shipping_mode = 'Rail' THEN 1 END) * 100.0 / NULLIF(COUNT(po.po_id), 0), 2) AS perc_rail,
    ROUND(COUNT(CASE WHEN po.shipping_mode = 'Sea' THEN 1 END) * 100.0 / NULLIF(COUNT(po.po_id), 0), 2) AS perc_sea,
    ROUND(COUNT(CASE WHEN po.shipping_mode = 'Land' THEN 1 END) * 100.0 / NULLIF(COUNT(po.po_id), 0), 2) AS perc_land,
    COUNT(po.po_id) AS total_purchase_orders
FROM purchase_orders po
-- Left join prevents potential data loss
LEFT JOIN audit_timelines a
  ON po.supplier_id = a.supplier_id
  AND po.po_date >= a.status_start_date 
  AND po.po_date < COALESCE(a.status_end_date, '2027-01-01')
GROUP BY COALESCE(a.compliance_status, 'No Audit History');

------------------------------------------------------------------------
-- Do failing suppliers incure higher freight and duty cost penalties?
------------------------------------------------------------------------

WITH audit_timelines AS (
	SELECT *,
		   audit_date AS status_start_date,
	       LEAD(audit_date) OVER (PARTITION BY supplier_id ORDER BY audit_date) AS status_end_date
	FROM sustainability_audits
)

SELECT COALESCE(a.compliance_status, 'No Audit History') AS compliance_status,
	   ROUND(AVG(freight_cost), 2) AS avg_freight_cost,
	   ROUND(AVG(duty_cost), 2) AS avg_duty_cost
FROM purchase_orders po
LEFT JOIN audit_timelines a
  ON po.supplier_id = a.supplier_id
  AND po.po_date >= a.status_start_date 
  AND po.po_date < COALESCE(a.status_end_date, '2027-01-01')
GROUP BY COALESCE(a.compliance_status, 'No Audit History');

----------------------------------------------------------------------------------------------
-- Are there any suppliers without an audit history that the organization still orders from?
----------------------------------------------------------------------------------------------

SELECT po.supplier_id,
       COUNT(DISTINCT po.po_id) AS number_of_orders
FROM purchase_orders po
LEFT JOIN sustainability_audits a
     ON a.supplier_id = po.supplier_id
WHERE a.supplier_id IS NULL
GROUP BY po.supplier_id
ORDER BY number_of_orders DESC;
