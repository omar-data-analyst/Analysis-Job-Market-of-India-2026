/*===============================================
  Exploratory Data Analysis of India Job Market

  Analyst Name  : Omar Mohamad Said
  Date          : 2026/3
  Status: Ready : for Visualization Stage
================================================*/GO


USE master
GO

-- Organizational Stage
BEGIN

   BEGIN
    IF NOT EXISTS (SELECT * FROM sys.databases WHERE NAME = 'India_Job_Market')

    CREATE DATABASE India_Job_Market;
  
    USE India_Job_Market
    IF OBJECT_ID('Base_Tabel', 'U') IS NOT NULL DROP TABLE Base_Tabel;
    IF OBJECT_ID('Skill_Table', 'U') IS NOT NULL DROP TABLE Skill_Table; 
   END
    -- Create Required Tables :

    --[1] Craete Base_Tabel
    BEGIN
       SELECT *,
          CASE 
            WHEN experience_required_years < 3 THEN 'Junior'
            WHEN experience_required_years <= 7 THEN 'Mid-Level' 
            WHEN experience_required_years <= 12 THEN 'Senior'
            ELSE 'Lead'
          END AS [Level],
              (salary_max_inr + salary_min_inr) / 2 as [Average salary]
        INTO Base_Tabel
        FROM India_Job_Market_Salary_Trends_2026_CLEAN
    END

    --[2] Create Skill_Table
    BEGIN
        SELECT 
            [Level],
            [Average salary],
            Location,
            TRIM(value) AS Skill
        INTO Skill_Table
        FROM Base_Tabel
        CROSS APPLY STRING_SPLIT(skills,',')
    END

    --[3] Change Datatype at Average column
    BEGIN
        ALTER TABLE Base_Tabel
        ALTER COLUMN [Average salary] BIGINT
    END
END

/* ================================
Stage 1 : The Market Overview
================================= */

-- Total Jobs :
SELECT 
     Count(job_id) AS [Count of Jobs],
     Count(DISTINCT company_name) AS [Total Num of Companes],
     COUNT(DISTINCT location) AS [Total Num of States/Coutnries],
     AVG(experience_required_years) AS [Average of Required Years]
FROM Base_Tabel

-- The Demand of Jobs :
SELECT * FROM 
(
  SELECT
     job_title,
     COUNT(job_id) AS [Count Jobs],
     AVG(experience_required_years) AS [Average Required Years],
     (RANK() OVER(ORDER BY COUNT(job_id) DESC)) AS [Rank]
  FROM Base_Tabel
  WHERE experience_required_years IS NOT NULL
  GROUP BY job_title 
) t
WHERE [Rank] = 5

-- Destribution Of Jobs for each Level
SELECT 
    Level,
    COUNT(job_id) AS [Number of Jobs],
    FORMAT(COUNT(job_id) * 100/SUM(COUNT(job_id)) OVER(),'N1')+'%' AS Percentage
FROM Base_Tabel
GROUP BY Level
ORDER BY COUNT(job_id) DESC
/*Insights :
[1] The highest emphasis is on advanced experience, 
    with more than 60% of the demand for “Med-Level” and “Senior”

[2] The highest demand is for 'lead' at 18% by volume
*/
GO

-- Destribution Of Jobs for each Employment Type
SELECT 
    employment_type,
    COUNT(job_id) AS [No Jobs],
    FORmAT(COUNT(job_id) * 100/SUM(COUNT(job_id)) OVER(),'N1')+'%' AS Percentage
FROM Base_Tabel
GROUP BY employment_type
ORDER BY COUNT(job_id) DESC
GO
/* Insights :

[1] A third of the market is “full-time,” which indicates
    a large reliance on clients who work in small projects
    and then their employment period expires.

[2] The other third, “Internship,” refers to the frequent
    occurrence of companies creating their own employees to
    do customized jobs, or because of a gap between the
    educational paths qualified for graduates and the 
    companies’ requirements.

[3] The last third is “Contract.” This percentage is small
    , as more than two-thirds of the application is either
    full-time or internship, and this is evidence of job
    instability.

The market is attractive for money and experience, but it is
“anxious”for the employee looking for permanent job security.
*/
GO

/* ================================
Stage 2 : Finance Analysis
================================= */
-- Extract Top 10 States by Average Salaries
SELECT *
FROM (
      SELECT
          location AS [State],
          FORMAT(AVG([Average salary]),'N0')+'$' AS [Avg Salary],
          RANK () OVER(ORDER BY AVG([Average salary]) DESC) AS Rank
      FROM Base_Tabel
      GROUP BY location
      ) t
WHERE rank <= 5
GO
/* Insights :
The provinces with the highest average salaries
are Chennai, Delhi NCR, Bangalore, Noida, and Pune.
Generally, averagesalaries are similar across all
these provinces,with no single province holding a 
dominant position.
*/
GO

-- Extract Top 5 Jobs by Salaries
SELECT *
FROM (
      SELECT
          job_title AS [Job Name],
          FORMAT(AVG([Average salary]),'N0')+'$' AS [Avg Salary],
          RANK() OVER(
                     ORDER BY AVG([Average salary]) DESC) AS Rank
      FROM Base_Tabel
      GROUP BY job_title
      ) t
WHERE Rank <= 5
GO
/* Insights :
Top 5 Jobs is :
ML Engineer,Data Scientist,Cloud Engineer,
DevOps Engineer and Cybersecurity Analyst

*/
GO

-- Anlaysis Salaries each remote option 
SELECT 
     *,
     [Avg Salary]
       - LAG([Avg Salary]) OVER(ORDER BY [Avg Salary]) AS [Salary Difference]
FROM (
    SELECT 
          remote_option AS [Remote Option],
          AVG(CAST([Average Salary] AS BIGINT)) AS [Avg Salary],
          COUNT(job_id) AS [Count Jobs]
    FROM Base_Tabel
    GROUP BY remote_option
) t
ORDER BY [Avg Salary]
       - LAG([Avg Salary]) OVER(ORDER BY [Avg Salary]) DESC
GO
/* Insights :
The order volume in each mode is relatively
constant (3300 to 3200 orders). However, the
average payouts for each mode vary significantly
,with the "Onsite" mode being the highest,
by a difference of 7394, compared to the next
highest mode, "Remote", which is 1027 higher than
the Hybrid mode.
*/
GO

/* ================================
Stage 3 : Geographical Analysis
================================= */

-- Analysis Demand for each State
SELECT * 
FROM(
     SELECT
       location AS [State],
       COUNT(job_id) AS [Count Jobs],
       FORMAT((CAST(COUNT(job_id) AS FLOAT)*100/SUM(COUNT(job_id)) OVER()),'N1')+'%' AS ratio,
       RANK() OVER(ORDER BY COUNT(job_id) DESC) AS Rank
     FROM Base_Tabel
     GROUP BY location
     ) t
WHERE Rank <= 5
GO

-- Extract Top Company Demand each Estate 
SELECT * 
FROM(
     SELECT
       Location AS [State],
       company_name AS [Company],
       COUNT(job_id) AS [Count Jobs],
       FORMAT(
              (CAST(COUNT(job_id) AS FLOAT)*100/SUM(COUNT(job_id)) 
              OVER()),'N1')+'%' AS Ratio,
       RANK() OVER(PARTITION BY Location
                   ORDER BY COUNT(job_id) DESC) AS Rank
     FROM Base_Tabel
     GROUP BY company_name,location
     ) t
WHERE Rank <=2
GO
/* Insights:

[1] Flipkart and Zoho:
    These companies pursue a strategy of concentrating
    in specific strategic, technologically advanced, 
    and decision-making areas, rather than expanding widely.
    Explanation: This is to attract experts in programming,
    management, and decision-making.

    This makes them excellent choices for those with these skills 
    and the ability to afford living in major cities and capitals.
    Zoho is an exception, as it operates in less expensive cities.

[2] HCL Tech and Accenture:
    These companies excel in widespread expansion, focusing on
    leading in specific cities and expanding into India's 
    technologically advanced and decision-making areas. This makes
    them leading companies with a significant geographic footprint 
    in India. Explanation: The company seeks a comprehensive range
    of talent, including highly skilled, experienced, and loyal 
    employees with expertise in management, decision-making, 
    programming, financial management, and innovation. This makes it
    a popular choice for many job seekers across various specializations.
    The presence of numerous branches also contributes to varying cost of
    living.

[3] Companies such as Infosys, Capgemini, Accenture, Cognizant, and Tech Mahindra:
    These companies rank first or second in demand in some governorates, while 
    others lack branches in different governorates. The explanation for this is
    that they seek clients with specific attributes that align with their business
    model, or they target recent graduates, making them a good option for beginners
    with limited experience.
*/
GO

-- Extract Average Salary & Demand each job Category 
SELECT 
     [Category],
     COUNT(*) As [Count Jobs],
     AVG(CAST([Overall Avg Salary] AS BIGINT)) AS [Overall Avg Salary]
FROM (  
        SELECT
        (CAST([Average salary] AS BIGINT)) AS [Overall Avg Salary],
        CASE 
            WHEN job_title LIKE '%Machine Learning%' OR job_title LIKE '%AI%' 
              THEN 'Artificial Intelligence'

            WHEN job_title LIKE '%Data%' OR job_title LIKE '%Analyst%' 
              THEN 'Data Science & Analytics'

            WHEN job_title LIKE '%Engineer%' OR job_title LIKE '%Developer%' 
              THEN 'Software & Tech Engineering'

            WHEN job_title LIKE '%Manager%' OR job_title LIKE '%Lead%' 
              THEN 'Leadership & Management'

            ELSE 'Other Professional Roles' 
        END AS [Category]
        FROM Base_Tabel

) t
GROUP BY [Category]
GO
/* Insights :
Market demand is almost equal in both "Data Science & Analytics" and 
"Software & Tech Engineering," but the latter field surpasses the former in
average salaries, with a difference of $13,707.
*/
GO

-- Extract Average Salay & Demand each experiance year
SELECT
     experience_required_years AS [Experiance Year],
     COUNT(job_id) AS [Count Jobs],
     AVG([Average salary]) AS [Overall Avg Salary],
     RANK() OVER(ORDER BY AVG([Average Salary]) DESC) AS RANK
FROM Base_Tabel
WHERE experience_required_years IS NOT NULL
GROUP BY experience_required_years
GO
/* Insights :
The demand for each year of experience is relatively constant.

No years of experience ranks second.

Explanation: As previously mentioned, the high demand for trainees
indicates that those with no experience are the best option for companies 
looking to hire their own staff.

Average salaries are correlated with years of experience, with the highest 
average salary being 9 years, followed by 11 years of experience in third
place.

Explanation: This is often associated with leadership positions, where 
individuals manage projects, aligning with the previously mentioned high 
demand for "lead" candidates in the market.

This suggests that years of experience are not a strict measure in the Indian
market, as there is a general convergence across all years. Other factors, 
such as skills and specialization, influence average salaries.
*/
GO

-- Extract Average Salary & Demand each Level
SELECT 
     Level,
     COUNT(job_id) AS [Count Jobs],
     AVG([Average salary]) AS [Overall Avg Salary],
     RANK() OVER(ORDER BY AVG([Average salary]) DESC) AS RANK
FROM Base_Tabel
GROUP BY Level
GO
/* Insights :
The average salaries for Senior and Junior employees are the highest in the market,
by a relatively small margin (~$6000). This confirms the high demand for each.

The average salary for Mid-Level employees is the lowest, by a significant margin 
(~$14,000) compared to Junior employees. This indicates an illogical and unfair market
structure, which aligns with the high demand for this category.

Generally speaking, experience does not reflect the market salary range.
*/
GO

-- Extract Average Salary & Demand each Employment Type
SELECT 
     employment_type AS [Employment Type],
     COUNT(job_id) AS [Count Jobs],
     AVG([Average salary]) AS [Overall Avg Salary],
     RANK() OVER(ORDER BY AVG([Average salary]) DESC) AS RANK
FROM Base_Tabel
GROUP BY employment_type
GO
/* Insights :
The demand for each work model is almost equal, but "Contract" work models 
have an advantage in terms of average salaries.
*/GO


/* ================================
Stage 4 : The Final Report
================================*/GO

/* [ Report of Stage 1 ]:
------------------------------------------------------------
The market generally operates on four key factors: experience,
speed, customization, and agility.

Companies generally focus on experienced mid-level and senior
clients who work full-time, or for internships or other specialized
projects, or due to a general lack of qualifications for the
higher-level positions required by the company.

The demand for "lead" is also increasing, indicating the need for
someone to lead agile teams of experienced employees to expedite
work, handle organizational tasks, or train new clients in the field.
This aligns with the growing demand for internships.
*/ GO

/* [ Report of Stage 2 ] :
[1] Financial Balance by Region and Job:

    Top regions include:
    (Chennai, Delhi NCR, Bangalore, etc.)
    In terms of average annual income, 
    there are small differences between 
    each city and the next in the ranking.

[2] Similarly, top jobs include:
    (ML Engineer, Data Scientist, Cloud 
    Engineer)
    There are small differences in annual
    income between them.

    This indicates that the market is 
    generally balanced, offering job seekers
    multiple positions in different locations
    with minimal income variations.

[3] Priority for On-Site Work:
    The data reveals a significant difference in
    salaries based on work style. On-site work is
    the highest-paying option, with an average
    annual increase of approximately $7,300 
    compared to remote work. Remote work, on the
    other hand, outperforms hybrid work by about
    $1,000.

    This suggests that the Indian market pays higher 
    for on-site employees.
*/ GO

/* [ Report of Stage 3 ] :
[1] Breaking the Seniority Scale:

    The market generally doesn't strictly rely on experience. There's an opportunity 
    for beginners to earn a higher average income than those with average experience.
    However, those with average experience are in higher demand than beginners.

[2] The On-site Work Category:
    Employees who are physically present at the workplace (on-site work) also earn more
    than remote and hybrid workers.

    Company Geography and Cost of Living:
    HCL Tech and Accenture are popular choices for job seekers, as they are located in
    major cities and regional cities. This presents a choice between staying in bustling
    metropolises with high living costs or staying in more affordable regional cities.

    However, Zoho remains a strong contender.

    It follows a smart regional expansion strategy, focusing on regions with low living
    costs, making it the best option for those seeking a lower cost of living.
*/ GO

/* [ Executive Summary & Career Guide ]
Top Recommended Jobs:
ML Engineer, Data Scientist, Cloud Engineer, DevOps Engineer, 
and Cybersecurity Analyst are among the highest-paying jobs in 
the Indian market.

Top Recommended Work Types:

On-site work is the best option as it offers higher income compared
to remote and hybrid work.

Seeker's Experience Level:
[1] If you are new to your field:
There is an opportunity to work as a junior graduate to earn a higher 
salary than those with average experience, but overall demand is lower 
than average experience.

[2] If you have average experience in the field:
You have numerous job opportunities as more than 30% of the market demand
is for average experience, but you may earn a relatively lower salary than
a beginner.

[3] If you are Senior or above:
You have high demand for jobs that are competitive with those with average
experience, but with the advantage of higher salary. However, if you are a
Leader, there is relatively high demand for Leader positions, but with lower
salaries. For beginners, this is an unfair choice.

Work-Life Balance:

If you're a high-performing employee striving for excellence and advancement,
 and you can tolerate the hustle and bustle of major cities and their high 
 cost of living, some of the best companies in this field are Flipkart, 
 HCLTech, Zoho, and Accenture.

These companies are leaders in major cities like Chennai, Kolkata, Bangalore,
Hyderabad, and Mumbai.

If you're looking for a more affordable lifestyle, Kolkata is an excellent 
option, as Zoho is also a leading company there and a top performer in major
cities.
*/ GO