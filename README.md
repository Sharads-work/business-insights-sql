# Manual Japanese Cars Business Insights (SQL Project)
This was my first full SQL project — I cleaned, normalized, and analyzed data about manual Japanese cars to practice real-world skills.  
I answered 8 real-world business questions using SQL for a Japanese manual car dealership.

## Project Overview

This project simulates a car dealership that sells older Japanese manual-transmission cars amid the shift to EVs. It demonstrates SQL proficiency by transforming raw data into insights through normalization, cleaning, and complex querying.

## Project Objective

To apply core SQL concepts by analyzing a real-world-style dataset of Japanese manual cars — focusing on trims, performance, engine reuse, and fuel efficiency.

## Data Overview

- Source: Custom Excel dataset; (compiled from Edmunds, Cars.com, Car and Driver, etc.)
- Years covered: 1993–2012
- Focus: Manual transmission trims only
- Automatic trims are included for context but excluded from core analysis

## Data Cleaning Summary

- Removed duplicates
- Normalized make, models, trims, engines, and specs into separate tables
- Filled in missing/redundant curb weights
- Filtered out automatic transmissions to reflect the dealership’s business model

## Business Questions Answered

1. List all trims with MPG above the fleet average MPG.
2. Which trim of each model offers the best Horsepower-to-Curb Weight ratio?
3. Categorize trims by power-to-weight class.
4. Identify the fastest and oldest trim per model for marketing.
5. Are there duplicate trim names with the same model/year but different specs?
6. Do any trims reuse different engines across years?
7. Which trims had the highest MPG in their launch year?
8. Which trims performed better than the fleet average in performance-to-MPG ratio?

## Technologies Used

- SQL (T-SQL)
- Relational Database Design
- Window Functions (ROW_NUMBER, RANK)
- Common Table Expressions (CTEs)
- Aggregations and Joins

## How to Use

1. Open `original_data.xlsx` to view raw data.
2. Download `manual_cars_data.csv` to use as the staging dataset for bulk insert.
3. Run `staging_and_normalization.sql` to clean and normalize the dataset.
4. Use `manual_japanese_cars_queries.sql` to run the business insight queries.

## Notes

- This project reflects my passion for cars, performance specs, and hands-on SQL work.
- Automatic trims were included for completeness but excluded from core analysis. Their prices were left blank intentionally.
- Feedback is welcome — this project is part of my evolving data portfolio.
