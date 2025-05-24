# Manual Japanese Cars Business Insights (SQL Project)
This was my first full SQL project — I cleaned, normalized, and analyzed data about manual Japanese cars to practice real-world skills.  
I answered 8 real-world business questions using SQL for a Japanese manual car dealership.

## Project Overview

This project simulates a car dealership specializing in newly selling older Japanese manual transmission cars due to the rise of EVs and fall of gasoline vehicles. It showcases SQL skills by answering business-critical questions through a cleaned and normalized dataset.

## Project Objective

To demonstrate SQL proficiency through realistic business queries about Japanese manual cars — including performance analysis, trim comparisons, engine reuse, and fuel efficiency.

## Data Overview

- Source: Custom-made dataset in Excel; collected from multiple sources like Edmunds, Cars, & Cars and Drivers
- Years covered: 1995–2012
- Focus: Manual transmission trims only
- Automatic trims are included for context but excluded from analysis due to business mission

## Data Cleaning Summary

- Removed duplicates
- Normalized trim and model info into separate tables
- Filled in missing or repeated curb weights where possible
- Only included **manual transmission** cars for analysis
- Filtered out automatic transmissions to align with the company’s manual-only focus.

## Business Questions Answered

1. List all trims with MPG above the fleet average MPG.
2. Which trim of each model offers the best Horsepower-to-Curb Weight ratio?
3. Categorize trims by power-to-weight ratio.
4. We'd like to advertise our fastest and oldest cars, one from each model to show off our variety.
5. Are there any duplicate trim names with the same model/year but different specs?
6. Do any trims ever use multiple engines across different years?
7. Which trims had the highest combined MPG in their launch year?
8. Which trims had a performance-to-MPG ratio higher than the average across all years?

## Technologies Used

- SQL
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

This project is part of my data portfolio and reflects my interest in cars, performance data, and SQL analysis. Feedback and suggestions are welcome!

- This dataset focuses on **manual transmission Japanese cars**.
- Automatic trims are included for reference, but their prices are intentionally left blank as they were not part of the analysis scope.
