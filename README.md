# Olist E-Commerce Business Analysis (Brazil)

## Project Overview
This project analyzes transactional, customer, payment, delivery, and review data from **Olist**, a Brazilian e-commerce marketplace.

The goal is to answer key business questions related to growth, customer behavior, delivery performance, and customer satisfaction using **SQL-based analysis**.

Rather than focusing on dashboards alone, this project emphasizes:
- Data quality and validation
- Sound analytical reasoning
- Clear business interpretation of results

---

##  Business Questions Addressed
1. How has order volume and revenue changed over time?
2. Are customers placing higher-value orders over time?
3. How long does delivery usually take, and has this changed over time?
4. How often are orders delivered late?
5. How do customer review scores trend over time?
6. Is late delivery associated with lower review scores?
7. Which payment methods are most commonly used?
8. Do installment payments correlate with higher order values?

---

##  Key Findings
- Order volume and revenue grew strongly from early 2017 through mid-2018.
- Average order value remained relatively stable, indicating growth was driven primarily by increased order volume rather than higher spend per order.
- Delivery performance improved over time, with average delivery times decreasing into 2018.
- Over 90% of delivered orders arrived on or before the estimated delivery date.
- Late deliveries are strongly associated with lower review scores, with severely late orders averaging review scores below 2.
- Credit cards dominate payments (approximately 74% of transactions), followed by boleto.
- Orders with higher installment counts tend to have higher total order values.

---

##  Data Quality & Validation
Before analysis, extensive validation was performed to ensure data integrity:
- Row count verification across all tables
- Primary key and duplicate checks
- Orphan record checks between fact and dimension tables
- Null value analysis
- Date range validation
- Logical sequence checks (purchase → approval → delivery)
- Delivery delay sanity checks

All anomalies were investigated and addressed prior to analysis.

---

##  Tools & Technologies
- **Database:** MySQL  
- **Language:** SQL  
- **Dataset:** Olist Brazilian E-Commerce Dataset (Kaggle)

### Techniques Used
- Common Table Expressions (CTEs)
- Aggregations and window functions
- Date and time calculations
- CASE-based business logic
- Reusable analytical queries
- Data validation and integrity checks

---

##  Repository Structure
olist-ecommerce-analysis/
│
├── README.md
├── LICENSE
├── sql/
│   ├── 01_schema_load.sql
│   ├── 02_data_validation.sql
│   └── 03_analysis.sql
│
└── notes/
    └── executive_summary.md


---

##  Business Value
This project demonstrates the ability to:
- Translate raw transactional data into decision-ready insights
- Apply rigorous data validation before analysis
- Communicate findings clearly to non-technical stakeholders
- Structure SQL analysis in a maintainable, reusable way

---

##  Future Enhancements
- Customer cohort and retention analysis
- Seller-level performance evaluation
- Product category profitability analysis
- Predictive modeling for delivery delays or review outcomes

---

##  Author Notes
This project was created as a **portfolio-ready case study**, designed to highlight analytical thinking, SQL proficiency, and business insight rather than visualization complexity.
