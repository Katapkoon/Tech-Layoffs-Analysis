# Tech Layoffs Analysis

An end-to-end data analysis project on global tech layoffs (March 2020 to March 2023), built with **MySQL**. It covers the full workflow, from cleaning a messy real-world dataset to analyzing it and presenting the findings.

## Project Overview

Raw data is rarely analysis-ready, so the project starts with a SQL data cleaning stage that follows a repeatable workflow:

1. Remove duplicates
2. Standardize the data
3. Handle NULL and blank values
4. Remove unnecessary columns and rows

The cleaned table (`layoffs_staging2`) is the foundation for the exploratory data analysis (EDA) and visualization work in this project.

## Dataset

- **Credit:** Data originally from [Layoffs.fyi](https://layoffs.fyi)
- **Size:** about 2,360 rows before cleaning, _[add final row count]_ after cleaning
- **Time range:** March 2020 to March 2023

| Column | Description |
|---|---|
| `company` | Company that carried out the layoff |
| `location` | City or region of the layoff |
| `industry` | Industry sector (Retail, Crypto, Healthcare, etc.) |
| `total_laid_off` | Number of employees laid off |
| `percentage_laid_off` | Share of the workforce laid off (1 = 100%, the company shut down) |
| `date` | Date of the layoff |
| `stage` | Funding or lifecycle stage (Seed, Series A to H, Post-IPO, Acquired, etc.) |
| `country` | Country |
| `funds_raised_millions` | Total funds raised, in millions of USD |

## Tools

- MySQL
- MySQL Workbench

## Data Quality Issues Found

| Issue | Example |
|---|---|
| Exact duplicate rows | The same company, date and figures appearing twice |
| Inconsistent text | `United States.` with a trailing period, which splits groups in a `GROUP BY` |
| Inconsistent category names | Variations of the `Crypto` industry label |
| Dates stored as text | `m/d/yyyy` strings instead of a `DATE` type |
| Missing and blank values | Blank `industry` values and NULLs in the numeric columns |
| Rows with no useful data | Rows where both `total_laid_off` and `percentage_laid_off` are NULL |

## Key Decisions

- **Why delete rows with no layoff numbers?** They contribute nothing to analysis of how many people were laid off. Deleting them is a judgment call, and the staging approach means the raw data can still be recovered.
- **Why a staging table?** It keeps the original data safe and makes every cleaning step reversible.

## Repository Structure

```
.
├── README.md
├── data/
│   └── layoffs.csv                 # raw dataset
└── sql/
    └── data_cleaning_layoffs.sql   # full cleaning script
```

## How to Run

1. Install MySQL and MySQL Workbench.
2. Create a schema and import `data/layoffs.csv` into a table named `layoffs` using the Table Data Import Wizard.
3. Open `sql/data_cleaning_layoffs.sql` in Workbench.
4. Run the script section by section. The final table is `layoffs_staging2`.

## What I Learned

- Using window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`) to find duplicates
- Why you work on a staging copy instead of the raw table
- Cleaning text and converting date formats in MySQL
- Using self joins to fill in missing values
- Making and documenting judgment calls about what to delete
