# Olist E-Commerce Business Analysis (Brazil)

## Project Overview
This project analyzes transactional, customer, payment, delivery, and review data from **Olist**, a Brazilian e-commerce marketplace.

The goal is to answer key business questions related to growth, customer behavior, delivery performance, and customer satisfaction using **SQL-based analysis**.
The analysis focuses on delivered orders only where revenue and customer outcomes are fully observable.

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
##  Key Results

- **Strong growth in orders and revenue (2017–mid-2018):**  
  Order volume and total revenue increased significantly over time, while average order value remained relatively stable. This indicates that growth was driven primarily by higher transaction volume rather than increased customer spend per order.

- **Delivery performance improved as the platform matured:**  
  Average delivery time peaked at 15–17 days during late 2017 and early 2018, then improved steadily to under 8 days by mid-2018, reflecting meaningful operational and logistics improvements.

- **Most orders were delivered on time or early:**  
  Over 90% of delivered orders arrived early or on time. Late deliveries accounted for fewer than 7% of orders, with approximately 3% delayed by more than 8 days.

- **Late delivery is strongly associated with lower customer satisfaction:**  
  Orders delivered on time or early averaged review scores above 4, while orders delivered more than 8 days late averaged review scores below 2, demonstrating a clear negative relationship between delivery delays and customer sentiment.

- **Payment behavior is dominated by credit cards:**  
  Credit cards accounted for approximately 74% of all payments, followed by boleto at around 19%, highlighting the importance of card-based and deferred payment options in the Brazilian e-commerce market.

- **Installment payments enable higher-value purchases:**  
  Orders with higher installment counts were associated with substantially higher average order values, suggesting that installment options play a key role in supporting larger customer purchases.
  
> Full SQL queries supporting these findings can be found in `sql/03_analysis.sql`.

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

##  Data Source & Setup

This project uses the Olist Brazilian E-Commerce Dataset (Kaggle).
CSV files are not included in the repository.

To run the schema and load script locally, download the dataset and
update the `<PATH_TO_CSV>` placeholders in `sql/01_schema_load.sql`
to point to your local dataset directory.


---

##  Repository Structure

```text
olist-ecommerce-analysis/
├── README.md
├── LICENSE
├── sql/
│   ├── 01_schema_load.sql
│   ├── 02_data_validation.sql
│   └── 03_analysis.sql
└── notes/
    └── executive_summary.md
```
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
