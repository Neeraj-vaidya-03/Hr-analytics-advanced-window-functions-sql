CREATE DATABASE hr_analytics;
USE hr_analytics;  

CREATE TABLE employee_data (
    EmpID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    StartDate DATE,
    ExitDate DATE NULL,
    Title VARCHAR(100),
    Supervisor VARCHAR(100),
    ADEmail VARCHAR(150),
    BusinessUnit VARCHAR(50),
    EmployeeStatus VARCHAR(50),
    EmployeeType VARCHAR(50),
    PayZone VARCHAR(50),
    EmployeeClassification VARCHAR(50),
    TerminationType VARCHAR(50),
    TerminationDescription VARCHAR(255),
    DepartmentType VARCHAR(50),
    Division VARCHAR(100),
    DOB DATE,
    State VARCHAR(10),
    JobFunctionDescription VARCHAR(100),
    GenderCode VARCHAR(10),
    LocationCode INT,
    RaceDesc VARCHAR(50),
    MaritalDesc VARCHAR(50),
    PerformanceScore VARCHAR(50),
    CurrentEmployeeRating INT
); 

SELECT * FROM hr_analytics.employee_data ;

SELECT COUNT(*) FROM hr_analytics.employee_data;

SELECT COUNT(*) FROM hr_analytics.employee_data;

SELECT COUNT(*) FROM hr_analytics.employee_data; 

SELECT * FROM hr_analytics.employee_data;
select * from employee_data;

SELECT * FROM hr_analytics.employee_data
ORDER BY EmpID ASC; 

CREATE TABLE hr_analytics.recruitment_data (
    ApplicantID INT,
    ApplicationDate VARCHAR(50),
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(20),
    DateOfBirth VARCHAR(50),
    PhoneNumber VARCHAR(50),
    Email VARCHAR(100),
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(50),
    ZipCode VARCHAR(20),
    Country VARCHAR(100),
    EducationLevel VARCHAR(50),
    YearsOfExperience INT,
    DesiredSalary DECIMAL(10, 2),
    JobTitle VARCHAR(100),
    Status VARCHAR(50)
); 

SELECT COUNT(*) FROM hr_analytics.recruitment_data; 

TRUNCATE TABLE hr_analytics.recruitment_data;

SELECT COUNT(*) FROM hr_analytics.recruitment_data;

SELECT * FROM hr_analytics.recruitment_data; 

CREATE TABLE hr_analytics.training_and_development_data (
    EmployeeID INT,
    TrainingDate VARCHAR(50),
    TrainingProgramName VARCHAR(100),
    TrainingType VARCHAR(50),
    TrainingOutcome VARCHAR(50),
    Location VARCHAR(100),
    Trainer VARCHAR(100),
    TrainingDurationDays INT,
    TrainingCost DECIMAL(10, 2)
);

SELECT COUNT(*) FROM hr_analytics.training_and_development_data;

SELECT * FROM training_and_development_data; 

SELECT * FROM hr_analytics.training_and_development_data 
LIMIT 1000 OFFSET 2000;

CREATE TABLE hr_analytics.employee_engagement_survey_data (
    EmployeeID INT,
    SurveyDate VARCHAR(50),
    EngagementScore INT,
    SatisfactionScore INT,
    WorkLifeBalanceScore INT
);

select * From hr_analytics.employee_engagement_survey_data;

SELECT COUNT(*) FROM hr_analytics.employee_engagement_survey_data;

select 
    EmployeeID,
    trainingProgramName,
    TrainingType,
    TrainingCost,
   row_number() over(Partition by TrainingType Order by TrainingCost DESC) AS row_num,
   RANK() over(Partition by TrainingType Order by TrainingCost DESC) AS rnk,
   dense_rank() over(Partition by TrainingType Order by TrainingCost DESC) AS dense_rnk 
From  training_and_development_data;

With RankedTrainings as (
select
      EmployeeID,
      TrainingProgramName,
      TrainingCost,
      dense_rank() over (partition by trainingProgramName ORDER BY TrainingCost DESC) as rnk
      From training_and_development_data 
)
SELECT * from RankedTrainings where rnk <=3;

With RankedTrainings as (
    select 
        EmployeeID,
        TrainingProgramName,
        TrainingCost,
        dense_rank() over (partition by trainingProgramName ORDER BY TrainingCost DESC) as rnk
    From training_and_development_data
    WHERE TrainingCost IS NOT NULL
)
SELECT * from RankedTrainings where rnk <= 3;

select 
        EmployeeID,
        TrainingProgramName,
        TrainingCost,
        dense_rank() over (partition by trainingProgramName ORDER BY TrainingCost DESC) as rnk
    From training_and_development_data
    WHERE TrainingCost IS NOT NULL;
    
WITH SalaryRank AS(
SELECT
     ApplicantID,
     JobTitle,
     DesiredSalary,
     DENSE_Rank()over(Partition by Jobtitle order by desiredsalary DESC) AS salary_rank
FROM recruitment_data
)
SELECT * FROM SalaryRANK WHERE salary_rank = 2; 

WITH DeduplicatedSurvey AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY STR_TO_DATE(SurveyDate, '%d-%m-%Y') DESC) AS rn
    FROM employee_engagement_survey_data
)
SELECT EmployeeID, SurveyDate, EngagementScore, SatisfactionScore 
FROM DeduplicatedSurvey 
WHERE rn = 1;


WITH BestValueApplicants AS (
    SELECT 
        ApplicantID, EducationLevel, DesiredSalary, YearsOfExperience,
        ROW_NUMBER() OVER (
            PARTITION BY EducationLevel 
            ORDER BY DesiredSalary ASC, YearsOfExperience DESC
        ) AS rn
    FROM recruitment_data
)
SELECT * FROM BestValueApplicants WHERE rn <=11; 


SELECT 
    EmployeeID,
    SurveyDate,
    EngagementScore,
    RANK() OVER (ORDER BY EngagementScore DESC) AS global_rank,
    RANK() OVER (PARTITION BY SurveyDate ORDER BY EngagementScore DESC) AS daily_rank
FROM employee_engagement_survey_data; 


SELECT 
    EmployeeID,
    TrainingProgramName,
    TrainingDate,
    TrainingCost,
    LAG(TrainingCost, 1, 0) OVER (
        PARTITION BY TrainingProgramName 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y')
    ) AS prev_cost
FROM training_and_development_data
WHERE trainingCost is not null;

SELECT 
    Location,
    TrainingDate,
    TrainingCost,
    TrainingCost - LAG(TrainingCost) OVER (
        PARTITION BY Location 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y')
    ) AS cost_difference
FROM training_and_development_data;


WITH CostChanges AS (
    SELECT 
        Location,
        TrainingDate,
        TrainingCost,
        TrainingCost - LAG(TrainingCost) OVER (
            PARTITION BY Location 
            ORDER BY STR_TO_DATE(TrainingDate, '%d-%m-%Y')
        ) AS cost_difference
    FROM training_and_development_data
    WHERE Location IS NOT NULL 
      AND TrainingCost IS NOT NULL
)
SELECT * 
FROM CostChanges 
WHERE cost_difference IS NOT NULL;


SELECT 
    ApplicantID,
    JobTitle,
    ApplicationDate,
    DATEDIFF(
        STR_TO_DATE(ApplicationDate, '%d-%b-%y'),
        LAG(STR_TO_DATE(ApplicationDate, '%d-%b-%y')) OVER (
            PARTITION BY JobTitle 
            ORDER BY STR_TO_DATE(ApplicationDate, '%d-%b-%y')
        )
    ) AS days_since_last_application
FROM recruitment_data;

WITH ScoreShifts AS (
    SELECT 
        EmployeeID,
        SatisfactionScore,
        LAG(SatisfactionScore) OVER (ORDER BY EmployeeID) AS prev_emp_score
    FROM employee_engagement_survey_data
)
SELECT * FROM ScoreShifts WHERE SatisfactionScore > prev_emp_score;

SELECT 
    EmployeeID,
    TrainingDate,
    TrainingCost,
    SUM(TrainingCost) OVER (
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y'), EmployeeID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_cost
FROM training_and_development_data;

SELECT 
    EmployeeID,
    TrainingDate,
    TrainingCost,
    SUM(TrainingCost) OVER (
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%Y'), EmployeeID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_cost
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL; 

SELECT 
    TrainingType,
    TrainingDate,
    TrainingCost,
    SUM(TrainingCost) OVER (
        PARTITION BY TrainingType 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y'), EmployeeID
    ) AS type_running_cost
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL;


SELECT 
    TrainingProgramName,
    TrainingDate,
    TrainingCost,
    ROUND(AVG(TrainingCost) OVER (
        PARTITION BY TrainingProgramName 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3_sessions
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL; 

SELECT 
    ApplicantID,
    YearsOfExperience,
    DesiredSalary,
    ROUND(AVG(DesiredSalary) OVER (
        ORDER BY YearsOfExperience 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ), 2) AS centered_moving_avg
FROM recruitment_data;

SELECT 
    EmployeeID,
    TrainingDate,
    TrainingCost,
    SUM(TrainingCost) OVER (
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y'), EmployeeID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_cost
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL;  

SELECT 
    TrainingType,
    TrainingDate,
    TrainingCost,
    SUM(TrainingCost) OVER (
        PARTITION BY TrainingType 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y'), EmployeeID
    ) AS type_running_cost
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL;  

SELECT 
    TrainingProgramName,
    TrainingDate,
    TrainingCost,
    ROUND(AVG(TrainingCost) OVER (
        PARTITION BY TrainingProgramName 
        ORDER BY STR_TO_DATE(TrainingDate, '%d-%b-%y')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3_sessions
FROM training_and_development_data
WHERE TrainingCost IS NOT NULL; 

SELECT 
    ApplicantID,
    YearsOfExperience,
    DesiredSalary,
    ROUND(AVG(DesiredSalary) OVER (
        ORDER BY YearsOfExperience 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ), 2) AS centered_moving_avg
FROM recruitment_data; 

WITH RankedApplicants AS (
    SELECT 
        ApplicantID,
        YearsOfExperience,
        DesiredSalary,
        ROUND(AVG(DesiredSalary) OVER (
            ORDER BY YearsOfExperience 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ), 2) AS centered_moving_avg,
        DENSE_RANK() OVER (
            PARTITION BY YearsOfExperience 
            ORDER BY DesiredSalary DESC
        ) AS salary_rank
    FROM recruitment_data
    WHERE YearsOfExperience IS NOT NULL 
      AND DesiredSalary IS NOT NULL
)
SELECT * 
FROM RankedApplicants 
WHERE salary_rank <= 5;


WITH RankedApplicants AS(
select
    ApplicantID,
    YearsofExperience,
    DesiredSalary,
    ROUND(AVG(Desiredsalary) over(
    order by YearsofExperience
    ROWS between 2 preceding and 2 following), 2) AS centerd_moving_avg,
	Dense_rank() over (partition by YearsofExperience order by DesiredSalary DESC) AS salary_rank
FROM recruitment_data
WHERE Yearsofexperience IS NOT NULL
   AND DesiredSalary IS NOT NULL 
)

Select* from RankedApplicants
where salary_rank <= 5;

WITH RankedApplicants AS (
    SELECT 
        ApplicantID,
        YearsOfExperience,
        DesiredSalary,
        ROUND(AVG(DesiredSalary) OVER (
            ORDER BY YearsOfExperience 
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ), 2) AS centered_moving_avg,
        DENSE_RANK() OVER (
            PARTITION BY YearsOfExperience 
            ORDER BY DesiredSalary DESC
        ) AS salary_rank
    FROM recruitment_data
    WHERE YearsOfExperience IS NOT NULL 
      AND DesiredSalary IS NOT NULL
)
SELECT * 
FROM RankedApplicants 
WHERE salary_rank <= 5;


SELECT 
    ApplicantID,
    JobTitle,
    DesiredSalary,
    NTILE(4) OVER (ORDER BY DesiredSalary ASC) AS salary_quartile
FROM recruitment_data;

WITH Percentiles AS(
select 
      EmployeeID, TrainingProgramName, TrainingCost,
      percent_rank() over (order by TrainingCost ASC) AS pct_rank
From training_and_development_data
WHERE Trainingcost is not null
)

select * FROM Percentiles WHERE pct_rank >= 0.90; 


SELECT 
    ApplicantID,
    Country,
    DesiredSalary,
    FIRST_VALUE(DesiredSalary) OVER (PARTITION BY Country ORDER BY DesiredSalary DESC) - DesiredSalary AS diff_from_top
FROM recruitment_data; 

WITH RankedSalaries AS (
select 
 ApplicantID,
 JobTitle,
 DesiredSalary,
 NTH_Value(DesiredSalary,3) over(
 partition by JobTitle
 order by DesiredSalary DESC
 ROWS between unbounded preceding and unbounded following ) AS third_highest_salary
 From recruitment_data
 where Jobtitle IS NOT NULL
  AND DesiredSalary IS NOT NULL
) 

select * FROM RankedSalaries where third_highest_salary IS NOT NULL;


SELECT 
    e.EmployeeID,
    e.Department,
    t.TrainingProgramName,
    t.TrainingCost
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmployeeID = t.EmployeeID;
    
DESCRIBE employee_data;

SELECT 
    e.EmpID,
    e.FirstName,
    e.LastName,
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID; 
    
SELECT 
    e.EmpID,
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
LEFT JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID;
    
    DESCRIBE employee_data;
    DESCRIBE training_and_development_data; 
DESCRIBE recruitment_data;

DESCRIBE employee_engagement_survey_data;

SELECT 
    e.EmpID,
    e.FirstName,
    e.LastName,
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingCost IS NOT NULL; 
  
SELECT 
    e.EmpID,
    e.FirstName,
    e.DepartmentType,
    s.SurveyDate,
    s.EngagementScore,
    s.SatisfactionScore
FROM employee_data e
INNER JOIN employee_engagement_survey_data s
    ON e.EmpID = s.EmployeeID
WHERE e.DepartmentType IS NOT NULL 
  AND s.EngagementScore IS NOT NULL;
  
SELECT 
    e.EmpID,
    e.FirstName,
    t.TrainingProgramName,
    t.TrainingCost,
    s.EngagementScore
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
INNER JOIN employee_engagement_survey_data s
    ON e.EmpID = s.EmployeeID
WHERE t.TrainingCost > 500
  AND s.EngagementScore IS NOT NULL;
  
SELECT 
    e.DepartmentType,
    SUM(t.TrainingCost) AS total_department_training_cost,
    COUNT(DISTINCT e.EmpID) AS trained_employee_count
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingCost IS NOT NULL
GROUP BY e.DepartmentType
ORDER BY total_department_training_cost DESC;


SELECT 
    t.TrainingProgramName,
    ROUND(AVG(s.SatisfactionScore), 2) AS avg_satisfaction_score,
    COUNT(t.EmployeeID) AS total_participants
FROM training_and_development_data t
INNER JOIN employee_engagement_survey_data s
    ON t.EmployeeID = s.EmployeeID
WHERE t.TrainingProgramName IS NOT NULL
  AND s.SatisfactionScore IS NOT NULL
GROUP BY t.TrainingProgramName
ORDER BY avg_satisfaction_score DESC;


select 
 e.DepartmentType,
 sum(t.trainingCost) AS total_department_training_cost,
 count(DISTINCT e.EmpID) AS trained_employee_count
From employee_data e
INNER JOIN training_and_development_data t
        ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL
 AND t.TrainingCost IS NOT NULL
GROUP BY e.DepartmentType
ORDER By total_department_training_cost DESC; 

SELECT 
    e.EmpID,
    e.FirstName,
    e.LastName,
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
LEFT JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL;


SELECT 
    e.EmpID,
    e.FirstName,
    e.LastName,
    e.DepartmentType,
    s.EngagementScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s
    ON e.EmpID = s.EmployeeID
WHERE s.EngagementScore IS NOT NULL; 


SELECT 
    e.EmpID,
    e.Title,
    e.BusinessUnit,
    s.EngagementScore,
    s.WorkLifeBalanceScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s
    ON e.EmpID = s.EmployeeID
WHERE e.BusinessUnit IS NOT NULL; 

SELECT 
    e.DepartmentType,
    COUNT(e.EmpID) AS total_employees,
    COUNT(t.EmployeeID) AS trained_employees,
    ROUND(COUNT(t.EmployeeID) * 100.0 / COUNT(e.EmpID), 2) AS training_coverage_pct
FROM employee_data e
LEFT JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL
GROUP BY e.DepartmentType; 

SELECT 
    t.EmployeeID,
    t.TrainingProgramName,
    t.TrainingCost
FROM training_and_development_data t
LEFT JOIN employee_data e
    ON t.EmployeeID = e.EmpID
WHERE e.EmpID IS NOT NULL; 

SELECT 
    t.EmployeeID,
    t.TrainingProgramName,
    t.TrainingCost,
    e.FirstName,
    e.DepartmentType
FROM employee_data e
RIGHT JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID
WHERE t.TrainingProgramName IS NOT NULL;

SELECT 
    s.EmployeeID,
    s.EngagementScore,
    s.SatisfactionScore,
    e.DepartmentType
FROM employee_data e
RIGHT JOIN employee_engagement_survey_data s
    ON e.EmpID = s.EmployeeID
WHERE s.EngagementScore IS NOT NULL; 

SELECT 
    e.EmpID AS MasterEmpID,
    t.EmployeeID AS TrainingEmpID,
    e.FirstName,
    t.TrainingProgramName
FROM employee_data e
LEFT JOIN training_and_development_data t ON e.EmpID = t.EmployeeID

UNION

SELECT 
    e.EmpID AS MasterEmpID,
    t.EmployeeID AS TrainingEmpID,
    e.FirstName,
    t.TrainingProgramName
FROM employee_data e
RIGHT JOIN training_and_development_data t ON e.EmpID = t.EmployeeID; 



SELECT 
    e.EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID

UNION

SELECT 
    e.EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
RIGHT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID; 

SELECT 
    e.EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID
WHERE e.EmpID IS NOT NULL

UNION

SELECT 
    e.EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
RIGHT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID
WHERE e.EmpID IS NOT NULL;


SELECT 
    COALESCE(e.EmpID, s.EmployeeID) AS Unified_EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID

UNION

SELECT 
    COALESCE(e.EmpID, s.EmployeeID) AS Unified_EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
RIGHT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID;


SELECT 
    e1.EmpID AS EmployeeID,
    CONCAT(e1.FirstName, ' ', e1.LastName) AS EmployeeName,
    e1.Supervisor AS SupervisorName
FROM employee_data e1
WHERE e1.Supervisor IS NOT NULL;


SELECT 
    emp.EmpID AS EmployeeID,
    emp.FirstName AS EmployeeFirstName,
    mgr.FirstName AS ManagerFirstName
FROM employee_data emp
INNER JOIN employee_data mgr
    ON emp.Supervisor = mgr.EmpID; 
    

SELECT DISTINCT
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
CROSS JOIN training_and_development_data t
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingProgramName IS NOT NULL;
  
  
SELECT 
    d.DepartmentType,
    t.TrainingProgramName
FROM (
    SELECT DISTINCT DepartmentType 
    FROM employee_data 
    WHERE DepartmentType IS NOT NULL
) d
CROSS JOIN (
    SELECT DISTINCT TrainingProgramName 
    FROM training_and_development_data 
    WHERE TrainingProgramName IS NOT NULL
) t;

SELECT 
    e.DepartmentType,
    COUNT(DISTINCT e.EmpID) AS total_department_staff,
    ROUND(SUM(t.TrainingCost), 2) AS total_training_investment,
    ROUND(AVG(s.EngagementScore), 2) AS average_engagement_score
FROM employee_data e
LEFT JOIN training_and_development_data t 
    ON e.EmpID = t.EmployeeID
LEFT JOIN employee_engagement_survey_data s 
    ON e.EmpID = s.EmployeeID
WHERE e.DepartmentType IS NOT NULL
GROUP BY e.DepartmentType
ORDER BY average_engagement_score DESC;


SELECT 
    e.EmpID,
    e.FirstName,
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost,
    s.EngagementScore
FROM employee_data e
INNER JOIN training_and_development_data t 
    ON e.EmpID = t.EmployeeID
INNER JOIN employee_engagement_survey_data s 
    ON e.EmpID = s.EmployeeID
WHERE t.TrainingCost > 300
  AND s.EngagementScore >= 4;
  
  
SELECT 
    e.EmpID,
    e.FirstName,
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost,
    s.EngagementScore
FROM employee_data e
LEFT JOIN training_and_development_data t 
    ON e.EmpID = t.EmployeeID
LEFT JOIN employee_engagement_survey_data s 
    ON e.EmpID = s.EmployeeID
WHERE e.DepartmentType IS NOT NULL;


SELECT DISTINCT
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
CROSS JOIN training_and_development_data t
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingProgramName IS NOT NULL;
  
  
SELECT 
    emp.EmpID AS EmployeeID,
    emp.FirstName AS EmployeeFirstName,
    mgr.FirstName AS ManagerFirstName
FROM employee_data emp
INNER JOIN employee_data mgr
    ON emp.Supervisor = mgr.EmpID; 
    
    
SELECT 
    d.DepartmentType,
    t.TrainingProgramName
FROM (
    SELECT DISTINCT DepartmentType 
    FROM employee_data 
    WHERE DepartmentType IS NOT NULL
) d
CROSS JOIN (
    SELECT DISTINCT TrainingProgramName 
    FROM training_and_development_data 
    WHERE TrainingProgramName IS NOT NULL
) t;


SELECT DISTINCT 
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
CROSS JOIN training_and_development_data t
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingProgramName IS NOT NULL
LIMIT 100;


SELECT 
    e.DepartmentType,
    t.TrainingProgramName
FROM employee_data e
INNER JOIN training_and_development_data t
    ON e.EmpID = t.EmployeeID   
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingProgramName IS NOT NULL;
  
  
SELECT 
    t.EmployeeID,
    t.TrainingProgramName,
    t.TrainingCost
FROM training_and_development_data t
LEFT JOIN employee_data e
    ON t.EmployeeID = e.EmpID
WHERE e.EmpID IS  NULL; 



WITH RankedSalaries AS (
    SELECT 
        ApplicantID,
        JobTitle,
        DesiredSalary,
        NTH_VALUE(DesiredSalary, 3) OVER (
            PARTITION BY JobTitle
            ORDER BY DesiredSalary DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS third_highest_salary 
    FROM recruitment_data
    WHERE JobTitle IS NOT NULL 
      AND DesiredSalary IS NOT NULL
)
SELECT * 
FROM RankedSalaries 
WHERE third_highest_salary IS NOT NULL;



select
     e.DepartmentType,
     t.TrainingProgramName,
     t.TrainingCost
From employee_data e
INNER JOIN training_and_development_data t
      ON e.EmpID = t.EmployeeID;
      
SELECT 
    TrainingDate,
    TrainingProgramName,
    TrainingCost,
    SUM(TrainingCost) OVER (ORDER BY TrainingDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total_cost
FROM training_and_development_data
WHERE TrainingDate IS NOT NULL AND TrainingCost IS NOT NULL;


SELECT 
    EducationLevel,
    FirstName,
    DesiredSalary,
    RANK() OVER (PARTITION BY EducationLevel ORDER BY DesiredSalary DESC) as salary_rank
FROM recruitment_data
WHERE EducationLevel IS NOT NULL AND DesiredSalary IS NOT NULL;

SELECT 
    BusinessUnit,
    EmpID,
    FirstName,
    StartDate,
    ROW_NUMBER() OVER (PARTITION BY BusinessUnit ORDER BY StartDate ASC) as onboarding_sequence
FROM employee_data
WHERE BusinessUnit IS NOT NULL AND StartDate IS NOT NULL;


SELECT 
    e.EmpID,
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost,
    ROUND(AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType), 2) as dept_avg_cost
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL;

SELECT 
    e.DepartmentType,
    t.TrainingProgramName,
    t.TrainingCost,
    SUM(t.TrainingCost) OVER (PARTITION BY e.DepartmentType) as total_dept_cost,
    ROUND((t.TrainingCost / SUM(t.TrainingCost) OVER (PARTITION BY e.DepartmentType)) * 100, 2) as cost_share_percentage
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL;


SELECT 
    TrainingDate,
    TrainingCost,
    ROUND(AVG(TrainingCost) OVER (ORDER BY TrainingDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_cost
FROM training_and_development_data
WHERE TrainingDate IS NOT NULL AND TrainingCost IS NOT NULL;


WITH EngagmentAnalysis AS(
SELECT 
    EmployeeID,
    SurveyDate,
    EngagementScore,
    LAG(EngagementScore, 1) OVER (PARTITION BY EmployeeID ORDER BY SurveyDate) as previous_engagement_score,
    EngagementScore - LAG(EngagementScore, 1) OVER (PARTITION BY EmployeeID ORDER BY SurveyDate) as score_delta
FROM employee_engagement_survey_data
WHERE EmployeeID IS NOT NULL AND EngagementScore IS NOT NULL
)

select *
FROM EngagmentAnalysis 
where previous_engagement_score IS NOT NULL
    AND score_delta IS NOT NULL;


SELECT 
    EmployeeID,
    COUNT(*) AS total_surveys_submitted
FROM employee_engagement_survey_data
GROUP BY EmployeeID
ORDER BY total_surveys_submitted DESC;


select * from training_and_development_data ;

select 
      TrainingProgramName,
      TrainingCost,
      ROUND(PERCENT_RANK() OVER (order by TrainingCost),4) AS cost_percentile_rank
from training_and_development_data 
Where TrainingCost IS NOT NULL;

select * from employee_data;

select * from employee_engagement_survey_data; 

select
       e.DepartmentType,
       e.EmpID,
       e.FirstName,
       s.EngagementScore,
       dense_rank()over (partition by e.DepartmentType order by s.EngagementScore DESC) as  dept_engagment_rank
From employee_data e
INNER JOIN  employee_engagement_survey_data s  
ON e. EmpID = s. EmployeeID
Where  e.DepartmentType IS NOT NULL AND s.EngagementScore IS not NULL;

SELECT 
    COALESCE(e.EmpID, s.EmployeeID) AS Unified_EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
LEFT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID

UNION

SELECT 
    COALESCE(e.EmpID, s.EmployeeID) AS Unified_EmpID,
    s.SurveyDate,
    s.EngagementScore
FROM employee_data e
RIGHT JOIN employee_engagement_survey_data s ON e.EmpID = s.EmployeeID;


SELECT 
    EmployeeID,
    TrainingDate,
    LAG(TrainingDate, 1) OVER (PARTITION BY EmployeeID ORDER BY TrainingDate) as prior_training_date
FROM training_and_development_data
WHERE EmployeeID IS NOT NULL AND TrainingDate IS NOT NULL; 

WITH DeptSpending AS (
select 
     e.EmpID,
     e.DepartmentType,
     t.TrainingCost,
     AVG(t.TrainingCost) over(partition by  e.DepartmentType) as dept_avg
	 From employee_data e
INNER join training_and_development_data t
ON e.EmpID = t.EmployeeID
)
select EmpID, DepartmentType, TrainingCost, dept_avg
From DeptSpending
Where TrainingCost > dept_avg;


SELECT 
    BusinessUnit,
    EmpID,
    FirstName,
    StartDate,
    DENSE_RANK() OVER (PARTITION BY BusinessUnit ORDER BY StartDate ASC) as tenure_sequence
FROM employee_data
WHERE BusinessUnit IS NOT NULL AND StartDate IS NOT NULL;


SELECT 
    e.DepartmentType,
    e.EmpID,
    t.TrainingCost,
    SUM(t.TrainingCost) OVER (PARTITION BY e.DepartmentType) as total_dept_investment,
    COUNT(e.EmpID) OVER (PARTITION BY e.DepartmentType) as total_dept_headcount,
    ROUND(AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType), 2) as dept_average_cost
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL;


SELECT 
    EmployeeNumber,
    Department,
    JobRole,
    MonthlyIncome,
    DENSE_RANK() OVER (
        PARTITION BY Department 
        ORDER BY MonthlyIncome DESC
    ) AS dept_salary_rank
FROM hr_employees
WHERE Department IS NOT NULL 
  AND MonthlyIncome IS NOT NULL;
  
  
  SELECT 
    EmpID,
    DepartmentType,
    DENSE_RANK() OVER (
        PARTITION BY DepartmentType 
        ORDER BY EmpID DESC 
    ) AS dept_rank
FROM employee_data
WHERE DepartmentType IS NOT NULL;


WITH SalaryQuartiles AS (
    SELECT 
        EmpID,
        DepartmentType,
        MonthlyIncome,
        NTILE(4) OVER (
            PARTITION BY DepartmentType 
            ORDER BY MonthlyIncome ASC
        ) AS salary_quartile
    FROM employee_data
    WHERE DepartmentType IS NOT NULL 
      AND MonthlyIncome IS NOT NULL
)
SELECT 
    EmpID,
    DepartmentType,
    MonthlyIncome,
    salary_quartile,
    CASE salary_quartile
        WHEN 1 THEN 'Bottom 25%'
        WHEN 2 THEN 'Lower Mid'
        WHEN 3 THEN 'Upper Mid'
        WHEN 4 THEN 'Top 25%'
    END AS compensation_band
FROM SalaryQuartiles
ORDER BY DepartmentType, MonthlyIncome DESC;


DESCRIBE employee_data;


WITH TrainingCostQuartiles AS (
    SELECT 
        e.EmpID,
        e.DepartmentType,
        t.TrainingProgramName,
        t.TrainingCost,
        NTILE(4) OVER (
            PARTITION BY e.DepartmentType 
            ORDER BY t.TrainingCost ASC
        ) AS cost_quartile
    FROM employee_data e
    INNER JOIN training_and_development_data t 
        ON e.EmpID = t.EmployeeID
    WHERE e.DepartmentType IS NOT NULL 
      AND t.TrainingCost IS NOT NULL
)
SELECT 
    EmpID,
    DepartmentType,
    TrainingProgramName,
    TrainingCost,
    cost_quartile,
    CASE cost_quartile
        WHEN 1 THEN 'Bottom 25% Cost'
        WHEN 2 THEN 'Lower Mid Cost'
        WHEN 3 THEN 'Upper Mid Cost'
        WHEN 4 THEN 'Top 25% Cost'
    END AS cost_tier_band
FROM TrainingCostQuartiles
ORDER BY DepartmentType, TrainingCost DESC; 



SELECT 
    e.EmpID,
    e.DepartmentType,
    t.TrainingCost,
    ROUND(AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType), 2) AS dept_avg_cost,
    ROUND(
        t.TrainingCost - AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType), 
        2
    ) AS diff_from_dept_avg,
    ROUND(
        ((t.TrainingCost - AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType)) 
        / AVG(t.TrainingCost) OVER (PARTITION BY e.DepartmentType)) * 100, 
        2
    ) AS pct_diff_from_avg
FROM employee_data e
INNER JOIN training_and_development_data t 
    ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL 
  AND t.TrainingCost IS NOT NULL;
  
  SELECT 
    Department,
    JobRole,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS attrited_employees,
    ROUND(
        (SUM(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS attrition_rate_pct
FROM hr_employees
WHERE Department IS NOT NULL 
  AND JobRole IS NOT NULL
GROUP BY Department, JobRole
ORDER BY attrition_rate_pct DESC, total_employees DESC;


SELECT 
    DepartmentType,
    BusinessUnit,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN EmployeeStatus = 'Active' THEN 1 ELSE 0 END) AS active_employees,
    ROUND(
        (SUM(CASE WHEN EmployeeStatus = 'Active' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) AS active_rate_pct
FROM employee_data
WHERE DepartmentType IS NOT NULL 
  AND BusinessUnit IS NOT NULL
GROUP BY DepartmentType, BusinessUnit
ORDER BY active_rate_pct DESC, total_employees DESC;

SELECT 
    TrainingDate,
    TrainingProgramName,
    TrainingCost,
    SUM(TrainingCost) OVER (
        ORDER BY TrainingDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_cost
FROM training_and_development_data
WHERE TrainingDate IS NOT NULL AND TrainingCost IS NOT NULL;

SELECT 
    e.DepartmentType,
    t.TrainingDate,
    t.TrainingCost,
    SUM(t.TrainingCost) OVER (
        PARTITION BY e.DepartmentType 
        ORDER BY t.TrainingDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS dept_running_total
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL; 


select 
      TrainingDate,
      TrainingProgramName,
      count(EmployeeID)over(
      order by TrainingDate
      ROWS between unbounded PRECEDING and current row
      ) AS cumulative_sessions
FROM training_and_development_data
WHERE TrainingDate is not NULL;

select 
     TrainingDate,
     TrainingProgramName,
     TrainingCost,
     MAX(TrainingCost) over (
     order by  TrainingDate
     ROWS between unbounded preceding and  current row
     )AS running_max_cost
FROM training_and_development_data
where TrainingDate is not null 
AND TrainingCost IS NOT NULL;



SELECT 
    e.DepartmentType,
    t.TrainingDate,
    t.TrainingCost,
    SUM(t.TrainingCost) OVER (
        PARTITION BY e.DepartmentType 
        ORDER BY t.TrainingDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS dept_running_total,
    ROUND(
        AVG(t.TrainingCost) OVER (
            PARTITION BY e.DepartmentType 
            ORDER BY t.TrainingDate 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS dept_rolling_avg_3_row
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL;
 
 
WITH RankStaff AS(
Select 
     EmpID,
     FirstName,
     DepartmentType,
     StartDate,
     row_number() OVER (partition by DepartmentType order by StartDate ASC) as hire_rnk
From employee_data
where DepartmentType is not null and StartDate is not null
)
select 
     EmpID,
     FirstName,
     DepartmentType,
     StartDate,
     hire_rnk,
     case
         when hire_rnk = 1  THEN  'Department Pioneer'
		 when hire_rnk between 2 AND 5  THEN  'Early Growth Cohort'
         ELSE 	'Core Established Staff'
	 END AS 'Seniority_tier'
FROM Rankstaff
order by DepartmentType, hire_rnk ASC;

WITH CostComparison AS(
select 
      e.DepartmentType,
      t.TrainingProgramName,
      t.TrainingCost,
      AVG(t.TrainingCost) over ( partition by  e.DepartmentType) AS dept_avg_cost
FROM employee_data e
INNER JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
WHERE e.DepartmentType IS NOT NULL AND t.TrainingCost IS NOT NULL 
) 
select
      DepartmentType,
      TrainingProgramName,
      TrainingCost,
      ROUND(dept_avg_cost,2) as dept_avg_cost,
      CASE 
          WHEN  TrainingCost > dept_avg_cost THEN ' Budget Heavy (Above Avg)'
          WHEN  TrainingCost > dept_avg_cost THEN  'Right on Average'
          ELSE 'Cost Effecient (Below Avg)'
	  END AS budget_status_flag
FROM CostComparison
ORDER BY DepartmentType, TrainingCost DESC;
      
WITH MovingAverageCheck AS (
    SELECT 
        TrainingDate,
        TrainingProgramName,
        TrainingCost,
        AVG(TrainingCost) OVER (
            ORDER BY TrainingDate 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3_row
    FROM training_and_development_data
    WHERE TrainingDate IS NOT NULL AND TrainingCost IS NOT NULL
)
SELECT 
    TrainingDate,
    TrainingProgramName,
    TrainingCost,
    ROUND(moving_avg_3_row, 2) AS moving_avg_3_row,
    CASE 
        WHEN TrainingCost > (moving_avg_3_row * 1.25) THEN 'Volatility Alert: 25% Above Recent Trend'
        WHEN TrainingCost < (moving_avg_3_row * 0.75) THEN 'Volatility Alert: 25% Below Recent Trend'
        ELSE 'Stable Within Normal Range'
    END AS expense_volatility_flag
FROM MovingAverageCheck
ORDER BY TrainingDate ASC;


WITH TimelineAnalysis AS (
    SELECT 
        TrainingDate,
        TrainingProgramName,
        TrainingCost,
        LAG(TrainingCost, 1) OVER (ORDER BY TrainingDate ASC) AS prev_training_cost
    FROM training_and_development_data
    WHERE TrainingDate IS NOT NULL AND TrainingCost IS NOT NULL
)
SELECT 
    TrainingDate,
    TrainingProgramName,
    TrainingCost,
    prev_training_cost,
    CASE 
        WHEN prev_training_cost IS NULL THEN 'First Recorded Session'
        WHEN TrainingCost > prev_training_cost THEN 'Cost Increased'
        WHEN TrainingCost < prev_training_cost THEN 'Cost Decreased'
        ELSE 'Cost Unchanged'
    END AS cost_trend_flag
FROM TimelineAnalysis
ORDER BY TrainingDate ASC;

WITH DeptHeadcounts AS (
    SELECT 
        EmpID,
        FirstName,
        DepartmentType,
        COUNT(EmpID) OVER (PARTITION BY DepartmentType) as dept_headcount
    FROM employee_data
    WHERE DepartmentType IS NOT NULL
)
SELECT DISTINCT
    DepartmentType,
    dept_headcount,
    CASE 
        WHEN dept_headcount >= 1000 THEN 'Mega Enterprise Unit'
        WHEN dept_headcount BETWEEN 500 AND 999 THEN 'Core Business Unit'
        ELSE 'Lean / Specialized Unit'
    END AS department_scale_category
FROM DeptHeadcounts
ORDER BY dept_headcount DESC;


WITH EmployeeParticipation AS (
    SELECT 
        e.EmpID,
        e.FirstName,
        e.DepartmentType,
        COUNT(t.TrainingProgramName) OVER (PARTITION BY e.EmpID) AS total_trainings_attended
    FROM employee_data e
    LEFT JOIN training_and_development_data t ON e.EmpID = t.EmployeeID
    WHERE e.DepartmentType IS NOT NULL
)
SELECT DISTINCT
    EmpID,
    FirstName,
    DepartmentType,
    total_trainings_attended,
    CASE 
        WHEN total_trainings_attended = 0 THEN 'Inactive / Unengaged'
        WHEN total_trainings_attended BETWEEN 1 AND 2 THEN 'Moderate Learner'
        ELSE 'High Development Engagement'
    END AS learning_engagement_status
FROM EmployeeParticipation
ORDER BY total_trainings_attended DESC;








