# T-SQL Functions Collection

This repository contains reusable SQL Server functions developed to support data transformation, time-based calculations, and custom logic inside ETL pipelines or reporting environments.

Each function is written in **T-SQL** and is compatible with SQL Server 2016 and later.

---

## Available Functions

# 1. `Function-CalculateEastern.sql`
- Purpose: Calculates the date of **Orthodox Easter** for any given year, based on the Julian calendar Algorithm.
- Location: `SQL-Functions/Function-CalcEastern.sql`
- Example: `SELECT dbo.CalcEastern(2025);`  -- Returns '2025-04-20'


# 2. Function-WorkDays.sql
Purpose: Returns the number of working days (Mon–Fri) between two dates.
Location: `SQL-Functions/Function-WorkDays.sql`
Example: `SELECT dbo.WorkDays('2025-04-01', '2025-04-10');`  -- Returns 8
