# Edmonton-Municipal-Fleet-Analytics
Analysis of Edmonton municipal fleet activity (2012–2014) using Python, MySQL, and Tableau to identify trends, reporting gaps, and investigation priorities.

## Interactive Tableau Dashboard
[View the Fleet Investigation Dashboard on Tableau Public](https://public.tableau.com/app/profile/shreyash.ghagare/viz/Edmonton_Fleet_Analytics/FleetInvestigationDashboard)


## Project Overview

This project analyzes historical City of Edmonton municipal fleet activity data from 2012 to 2014 using Python, MySQL, and Tableau.

The analysis focuses on identifying changes in reported fleet kilometers across departments and vehicle asset classes. It also examines reporting completeness to ensure that comparisons are based on consistent reporting periods.

An Investigation Priority Score was developed to identify department and asset class combinations that showed significant changes in fleet activity and may require further investigation.

The findings are presented through an interactive Tableau dashboard and a detailed analytical report.

## Tools and Methodology

### Python (Pandas)
- Imported and inspected 2,042 fleet activity records.
- Checked missing values, duplicates, and inconsistencies in department names.
- Prepared reporting dates for monthly and annual analysis.
- Evaluated reporting completeness across department and asset class combinations.

### MySQL
- Used Common Table Expressions (CTEs) and window functions such as `LAG()` to analyze year-over-year changes.
- Calculated absolute and percentage changes in reported kilometers.
- Created SQL views for annual activity, reporting completeness, and investigation rankings.
- Developed an Investigation Priority Score using equally weighted percentile ranks of absolute kilometer change and absolute percentage change.

### Tableau
- Built an interactive dashboard to explore fleet activity trends.
- Visualized the top 10 investigation priorities.
- Added department-level activity trends and interactive filtering.
- Presented key findings through KPI cards and charts.


## Key Findings

- **Overall Fleet Activity:** Reported municipal fleet kilometers increased from 78.41 million in 2012 to 81.34 million in 2014, an overall increase of 3.74%.

- **Reporting Completeness:** Out of 64 department–asset class combinations, only 43 had complete monthly reporting across all three years. The remaining 21 combinations were excluded from the investigation ranking.

- **Edmonton Police Service:** Reported kilometers for Cars/Motorcycles decreased by 17.93%, while Light Trucks/Vans increased by 102.92% between 2012 and 2014.

- **Highest Investigation Priority:** Edmonton Police Service – Light Trucks/Vans ranked first with an Investigation Priority Score of 96.51.

- **Second Investigation Priority:** Waste Management Processing and Disposal – Trailers ranked second with a score of 93.02.

These findings highlight changes in reported fleet activity that may require further investigation. The Investigation Priority Score is not a measure of fleet efficiency or operational performance.

## Project Report

The complete analytical report includes the business problem, data preparation, SQL methodology, key findings, recommendations, and limitations.

[Read the Full Project Report](report/Edmonton_Municipal_Fleet_Analytics_Report.pdf)
