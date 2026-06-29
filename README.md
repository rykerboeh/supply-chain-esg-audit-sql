# Supply Chain ESG Audit

![POSTGRESQL](https://img.shields.io/badge/PostgreSQL-4169E1.svg?style=for-the-badge&logo=PostgreSQL&logoColor=white)
![Microsoft Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)

An end-to-end relational data pipeline that ingests raw supplier audit data, structures transactional purchase histories, maps temporal point-in-time compliance windows, and quantifies organizational financial exposure to underperforming or un-audited vendors.

---

## Business Case & Objectives
Organizations shifting toward sustainable procurement often struggle to isolate where vendor compliance failures jeopardize active operations. Fragmented data hides when an order is placed with a failing supplier, leaving companies blind to financial, legal, and operational risks.

This project centralizes multi-source supply chain data to map historical compliance trajectories, trace point-in-time financial liabilities during active breach periods, and isolate how ESG compliance correlates with downstream logistics vulnerabilities like shipping delays, high-emissions transport modes, and premium cost penalties.

---

## Tech Stack & Tools
* **Database Engine & Core Language: SQL (PostgreSQL / ANSI Compliant)
* **Advanced Relational Modeling: Window Functions (LEAD(), ROW_NUMBER()), Conditional Aggregation (CASE WHEN), Left Anti-Joins, Defensive Math Architecture (NULLIF(), Type-Casting)

---

## Repository Structure
```text
├── data/
│   ├── raw/                        
│       └── products.csv            # Source Kaggle product data
│       └── purchase_orders.csv     # Source Kaggle purchase order data
│       └── suppliers.csv           # Source Kaggle supplier data
│       └── sustainability_audits   # Synthetic data for audit touchpoint
├── SQL/                            # Data modeling & analytics
│   └── 01_data_creation_queries.sql            # Defines table schemas for raw data import
│   └── 02_baseline_compliance_queries          # Basic supplier metrics and current compliance standing
│   └── 03_financial_liability_queries.sql      # Explores concentration points of organizational financial liability
│   └── 04_freight_impact_queries.sql           # Explore freight impact of poor performing suppliers
└── README.md                       # Master project documentation
```
---

## Data Pipeline Architecture

### Phase 1: Database Creation & Baseline Compliance (01_ & 02_)
* **Raw data is structured into a clean, relational architecture to isolate current operational statuses and establish supplier performance trajectories:

* **Schema Enforcement (01_data_creation_queries.sql): Builds optimized tables for suppliers, products, purchase_orders, and sustainability_audits using strict primary and foreign key constraints.

* **Descriptive Baselines (02_baseline_compliance_queries.sql): Tracks geographic vendor densities, contract lengths, and identifies current failing suppliers.

* **Trajectory Tracking: Implements dual windowed CTEs (FIRST_VALUE / LAST_VALUE equivalents via ROW_NUMBER()) to classify metrics like waste diversion, water intensity, and labor safety as Improving, Worsening, or Stagnant.

### Phase 2: Financial Liability & Concentration Modeling (03_)
* **The pipeline scales to quantify direct financial exposure using advanced historical data alignments:

* **Temporal Effective-Dating: Utilizes the LEAD() window function to construct rolling audit validity windows (status_start_date to status_end_date). This dynamically pairs each historical purchase order with the exact compliance status of the vendor at the exact millisecond the transaction occurred.

* **Risk Concentration Layers: Aggregates total spend proportions across distinct dimensions (Product Categories, Country of Origin, and Specific Vendors) to identify what percentage of organizational capital is actively tied to high-risk partners.

### Phase 3: Operational Freight & Vulnerability Audits (04_)
* **The final analytical layer connects sustainability performance to downstream logistical efficiency:

* **Reliability Benchmarking: Correlates audit ratings with shipping fulfillment speeds (delivery_date - promised_delivery_date) to see if failing suppliers present higher supply chain delay risks.

* **Logistical Footprint Analysis: Uses single-scan conditional aggregations (COUNT(CASE WHEN...) * 100.0 / NULLIF(...)) to evaluate whether failing vendors rely disproportionately on high-emissions transport (Air) vs. lower-emissions alternatives (Rail/Sea).

* **Financial Penalty Tracking: Measures average freight and duty premium costs incurred across compliance tiers to pinpoint hidden operational overhead.

* **System Leak Isolation: Employs relational Left Anti-Joins (WHERE right_table.id IS NULL) to map active purchase volume flowing to legacy, un-audited suppliers.

## How to Reproduce & Run Locally

### 1. Clone the Repository
```bash
git clone https://github.com/rykerboeh/supply-chain-esg-audit.git
cd supply-chain-esg-audit
```

### 2. Initialize the Relational Schema
* **Execute sql/01_data_creation_queries.sql in your PostgreSQL instance to establish core table definitions.

* **Import your local operational CSV files into the corresponding database tables.

### 3. Run the Analytics Pipeline
* **Run files 02_ through 04_ sequentially to explore baseline behaviors, extract point-in-time risk concentrations, and isolate logistical efficiency gaps.

---

Developed by Ryker Boeh — Connect with me on https://www.linkedin.com/in/rboeh
