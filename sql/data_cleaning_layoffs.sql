-- Data Cleaning Project: Tech Layoffs (MySQL)
-- Steps:
--   1. Remove duplicates
--   2. Standardize the data
--   3. Handle NULL or blank values
--   4. Remove unnecessary columns and rows

SELECT * FROM layoffs;

-- -----------------------------------------------------
-- Create a staging table
-- We never clean the raw table directly. Working on a copy
-- keeps the original data safe if something goes wrong.
-- -----------------------------------------------------
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- -----------------------------------------------------
-- 1. Remove duplicates
-- -----------------------------------------------------
WITH duplicate_cte AS 
(
	SELECT *, ROW_NUMBER() OVER (
    PARTITION BY 
		company, 
        location, industry, 
        total_laid_off, 
        percentage_laid_off, 
        `date`, 
        stage, 
        country, 
        funds_raised_millions
	) AS row_num
	FROM layoffs_staging
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- MySQL doesn't allow DELETE on a CTE, so we create a second
-- staging table that includes the row_num column and delete from that.
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Fill the new table, calculating row_num as we insert
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY 
		company, 
        location, industry, 
        total_laid_off, 
        percentage_laid_off, 
        `date`, 
        stage, 
        country, 
        funds_raised_millions
	) AS row_num
FROM layoffs_staging;

-- Delete the duplicates 
DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- -----------------------------------------------------
-- 2. Stanardized the data
-- -----------------------------------------------------

-- Remove extra spaces from company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check the industry column for inconsistent labels
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Variations of "Crypto" exist (for example Crypto Currency), so merge them into one label
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check location and country for typos or formatting issues
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- "United States." has a trailing period, which would create a separate
-- group in any GROUP BY. TRIM(TRAILING '.' ...) removes it.
-- Preview the fix first, then apply it.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- The date column is stored as text (m/d/yyyy).
-- Step 1: convert the text into MySQL's standard date format (yyyy-mm-dd)
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- Step 2: change the column's data type to DATE so date functions work
-- (YEAR, MONTH, ordering, and so on)
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- -----------------------------------------------------
-- 3. Handle NULL and blank values
-- -----------------------------------------------------

-- Rows with no layoff numbers at all (reviewed here, deleted in step 4)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Find missing or blank industries
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

-- Check whether the same company has an industry filled in on another row
SELECT * 
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Turn blanks into real NULLs first so one condition (IS NULL) handles both
UPDATE layoffs_staging2 
SET industry = NULL 
WHERE industry = '';

-- Self join: match a row with a missing industry (t1) to another row
-- of the same company and location that has one (t2). Preview first.
SELECT t1.company, t1.location, t1.industry, t2.industry
FROM layoffs_staging2 t1 
JOIN layoffs_staging2 t2 
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL)
AND (t2.industry IS NOT NULL );

-- Apply it: copy the known industry into the rows where it is missing
UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2 
ON t1.company = t2.company
AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND (t2.industry IS NOT NULL );

-- -----------------------------------------------------
-- 4. Remove unnecessary rows and columns
-- -----------------------------------------------------

-- Rows with neither total_laid_off nor percentage_laid_off can't
-- support any layoff analysis, so they are deleted.
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2;

-- row_num was only needed to find duplicates, so drop it
ALTER TABLE  layoffs_staging2
DROP COLUMN row_num;

-- Final row count of the cleaned table
SELECT COUNT(*) as total_rows 
FROM layoffs_staging2;
