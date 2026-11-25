https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset

# Hr-analytics-advanced-window-functions-sql
Advanced SQL project implementing window functions (ROW_NUMBER, NTILE, LAG, running totals) and CTE-CASE conditional logic for workforce HR analytics.


# HR Analytics & Workforce Optimization: Advanced SQL Window & Case Analysis

## Project Overview
This repository contains production-grade SQL scripts engineered to perform advanced human resources and operational workforce analytics. Utilizing the `hr_analytics` database (`employee_data` and `training_and_development_data`), this project demonstrates complex analytical reporting capabilities beyond basic joins, targeting Senior Data Analyst and Business Intelligence competencies.

## Key Technical Concepts Demonstrated
* **Advanced Window Functions:** Mastered `ROW_NUMBER()`, `DENSE_RANK()`, `PERCENT_RANK()`, `NTILE()`, `SUM/AVG() OVER (PARTITION BY ...)`.
* **Frame Clause Control:** Implemented exact row-bounding configurations (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`) to execute rolling moving averages and cumulative running totals.
* **Conditional Logic Integration:** Combined CTEs and window calculations with dynamic `CASE` statements to automate cohort grouping, spend-tier classifications, and variance flagging.
* **Architecture Design:** Structured queries with clear separation of concerns—keeping raw calculation layers clean inside Common Table Expressions (CTEs) before presentation formatting in outer query layers.

## Business Questions Addressed
1. **Staff Seniority & Cohort Tiers:** Tracking departmental hiring order and categorizing personnel into expansion cohorts.
2. **Training Expense Benchmarking:** Comparing individual training costs against departmental averages to flag budget-heavy allocations.
3. **Financial Quartile Segmentation (`NTILE`):** Splitting training investments into 4 distinct economic bands for executive oversight.
4. **Expense Volatility Tracking (`LAG` & Moving Averages):** Detecting cost escalation trends and spikes across chronological training timelines.
5. **Cumulative Milestone Auditing (`SUM` Running Totals):** Auditing departmental spending growth against operational budget thresholds.

## Repository Structure
* `hr_analytics_advanced_window_functions.sql` - Main script containing all analytical queries, CTEs, window frames, and conditional case logic.

* ## 📂 Dataset Information
The queries in this repository run against the `hr_analytics` schema, which consists of two primary tables:
* **`employee_data`**: Contains staff demographics, hire dates, department classifications, and business units.
* **`training_and_development_data`**: Contains training session records, program names, costs, and training dates linked via `EmpID` = `EmployeeID`.

🔗 **Original Dataset Source:** You can download the raw dataset used for this project directly from [Kaggle Dataset](https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset)
