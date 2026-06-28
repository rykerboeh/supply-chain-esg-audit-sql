--============================================================
-- Create table schemas to import dataset csv files
--============================================================

--------------
-- Suppliers
--------------

CREATE TABLE suppliers (
	supplier_id	INT,
	supplier_name TEXT,
	region TEXT,
	default_shipping_mode TEXT,
	status TEXT,
	lead_time_category TEXT,
	min_order_qty INT,	
	contract_start_date DATE
);

-------------
-- Products 
-------------

CREATE TABLE products (
	sku_id TEXT,
	product_name TEXT,	
	category TEXT,	
	sub_category TEXT,	
	brand TEXT,
	product_type TEXT,
	size_label TEXT,
	launch_date	DATE,
	shelf_life_months NUMERIC,
	parent_sku TEXT,
	default_price NUMERIC,	
	primary_supplier_id	INT,
	is_active BOOLEAN,
	country_of_origin TEXT,
	online_only	BOOLEAN,
	avg_rating NUMERIC,
	rating_count INT,
	is_discontinued BOOLEAN
);

--------------------
-- Purchase Orders 
--------------------

CREATE TABLE purchase_orders (
	po_id TEXT,
	sku_id TEXT,
	supplier_id	INT,
	po_date	DATE,
	promised_delivery_date DATE,
	delivery_date DATE,
	order_qty INT,	
	unit_cost NUMERIC,
	shipping_mode TEXT,
	status TEXT,
	incoterm TEXT,
	currency TEXT,
	freight_cost NUMERIC,
	duty_cost NUMERIC
);

--------------------------
-- Sustainability Audits
--------------------------

CREATE TABLE sustainability_audits (
	audit_id TEXT,
	supplier_id	INT,
	audit_date DATE,
	waste_diversion_rate NUMERIC,	
	water_liters_per_unit NUMERIC,
	labor_compliance_score NUMERIC,
	compliance_status TEXT
);
