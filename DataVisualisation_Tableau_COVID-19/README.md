Using a previously used COVID-19 dataset (for 'SQLDataExploration_COVID-19'), I made a dashboard using tableau:
https://public.tableau.com/views/COVID19Dashboard_16237087506970/Dashboard1?:language=en-GB&:display_count=n&:origin=viz_share_link

I have also attached a copy of the dataset and the .sql file containing the queries used to extract the data.
The data was sourced from: https://ourworldindata.org/covid-deaths
I split .csv into two Excel workbooks: 
1) The population column was inserted behind the 'total_deaths' column. 
2) The first workbook includes the columns 'iso_code' to 'weekly_hosp_admissions_per_million' (26 columns)
3) The second workbook includes the columns 'iso_code' to 'population' (5 columns) + 'new_tests' to 'human_development_index' (32 columns)

NOTE: As I was using Tableau Public and could not connect directly to SQL server, I copied the data from SQL (SMSS) to Microsoft Excel and imported the Excel workbook into Tableau.
