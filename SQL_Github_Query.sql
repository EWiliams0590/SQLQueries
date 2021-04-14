-- tblAttendance has data with columns "EmployeeNumber, AttendanceMonth, and NumberAttendance"
-- EmployeeNumber is a foreign key to point to other tables
-- AttendanceMonth is the date of the first day of the month
-- AttendanceMonth and EmployeeNumber combine to be a unique identifier, and are the PK
-- NumberAttendance is the number of days attended by that employee for the given month

-- tblDepartment has data with columns "Department, DepartmentHead"
-- Department is the name of the department at the company. Department is the primary key.
-- Department head is the Head of the department (First Name only)

-- tblEmployee has data with columns "EmployeeNumber, EmployeeFirstName, EmployeeMiddleName, EmployeeLastName, EmployeeGovernmentID, 
-- DateOfBirth, and Department". Department is a FK linked to tblDepartment.
-- EmployeeNumber is the unique identifier (PK)
-- EmployeeMiddleName can be NULL

-- tblTransaction has columns "Amount, DateOfTransaction, EmployeeNumber"
-- EmployeeNumber is a FK to tblEmployee
-- DateOfTransaction is a smalldatetime, but the time is all 00:00:00
-- Amount is the amount of the specific transaction

-- Tasks:

-- Query the amount of transactions, amount spent, and average spent per transaction per year spent per employee.
-- Keep only those with average transaction amount > 400 for the year 2014.
-- Return only the EmployeeNumber, Total Transaction Amount, Number of Transactions, and Average Transaction Amount
WITH C AS (
SELECT E.EmployeeNumber, 
	   T.Amount,
	   YEAR(T.DateOfTransaction) as TransactionYear
FROM tblEmployee AS E
INNER JOIN tblTransaction AS T
ON E.EmployeeNumber = T.EmployeeNumber)

SELECT EmployeeNumber, 
	   SUM(Amount) AS TotalTransAmount,
	   COUNT(Amount) AS AmountOfTrans,
	   AVG(Amount) AS AvgTransAmount
FROM C
WHERE TransactionYear = 2014
GROUP BY EmployeeNumber, TransactionYear
HAVING Avg(Amount) > 400
ORDER BY EmployeeNumber ASC, TransactionYear ASC


-- Query the department head, department, number of employees per department, average age of employee in the department. Order by average age descending
SELECT D.Department, 
       D.DepartmentHead, 
	   COUNT(E.EmployeeNumber) AS NumberOfEmployees,
	   FLOOR(AVG(FLOOR(DATEDIFF(DAY, E.DateOfBirth, GETDATE()) / 365.25))) AS AverageAge
FROM tblDepartment AS D
INNER JOIN tblEmployee AS E
ON D.Department = E.Department
GROUP BY D.Department, D.DepartmentHead
ORDER BY AverageAge DESC

-- Query the Employee Number, First Name, and Last Name for the employees that had attendance of at least 12 for all months. Sort 
SELECT DISTINCT 
       A.EmployeeNumber, 
	   E.EmployeeFirstName, 
	   E.EmployeeLastName
FROM tblAttendance AS A
INNER JOIN tblEmployee AS E
ON A.EmployeeNumber = E.EmployeeNumber
WHERE A.EmployeeNumber IN (SELECT EmployeeNumber
						   FROM tblAttendance
						   GROUP BY EmployeeNumber
						   HAVING MIN(NumberAttendance) >= 12)

-- Reformat the Government ID in three columns. Format given is 2 letters, then 6 numbers, then 1 letter.
-- Recreate so the first two letters are in one column titled "Prefix", letters are in a second column titled "ID"
-- and last letter is a column titled "Class". Order by the Prefix ascending. If two have the same Prefix, then order by Class ascending.
-- If both Prefix and Class are the same, order by ID descending.

SELECT LEFT(REPLACE(TRIM(EmployeeGovernmentID), ' ', ''), 2) as 'Prefix',
	   SUBSTRING(REPLACE(TRIM(EmployeeGovernmentID),' ', ''), 3, 6) as 'ID',
	   RIGHT(REPLACE(TRIM(EmployeeGovernmentID),' ', ''), 1) as 'Class'
FROM tblEmployee
ORDER BY 'Prefix' ASC, 'Class' ASC, 'ID' DESC


