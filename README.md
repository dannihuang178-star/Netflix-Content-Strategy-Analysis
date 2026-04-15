# Netflix Content Strategy Analysis

## Project Overview
This project analyzes 8,800+ Netflix titles to understand whether the post-2018 decline in annual releases reflects content contraction or a strategic shift in portfolio composition.

## Analysis Versions
This project is presented in two parallel workflows:
- A pandas-based notebook for exploratory analysis, visualization, and business interpretation
- A SQL-based version that reproduces selected KPIs and trend logic using structured queries

## Business Question
Is Netflix reducing content overall, or repositioning its catalog toward a different content strategy?

## Tools
- Python (Pandas, Matplotlib)
- Jupyter Notebook

## Methods
- Data cleaning
- Exploratory data analysis
- Aggregation and grouping
- Trend analysis
- Business interpretation

## Key Findings
- Annual title additions peaked in 2018 and declined afterward
- Netflix shifted from a movie-heavy catalog to a series-first model
- TV shows rose from 21% to 53% of annual releases
- Movie runtime trends suggest a move toward shorter-form films
- Geographic diversification increased over time

## Strategic Recommendation
The results suggest a deliberate pivot toward retention-oriented content strategy, with stronger emphasis on serialized content and more selective catalog expansion.

## Repository Structure

```text
Netflix-Content-Strategy-Analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── notebooks/
│   └── netflix_content_strategy_analysis.ipynb
├── data/
│   └── netflix_titles.csv
├── images/
│   └── 01_Netfilx Content Additions by Year 2010-2021.png
│   └── 02_Content Type Proportion 2010-2021.png
│   └── 03_Average Movie Duration Trend 2010-2021.png
│   └── 04_Top 8 Producing Countries 2010-2021.png
├── sql/
│   └── netflix_content_strategy_analysis.sql
