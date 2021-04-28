--Section 1. DDL
CREATE DATABASE [Service]
GO
USE Service
GO
CREATE TABLE Users
(
	Id INT PRIMARY KEY IDENTITY,
	Username NVARCHAR(30) UNIQUE NOT NULL,
    [Password] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(50), 
    Birthdate DATETIME,
	Age INT CHECK(Age > 14 and Age <= 110),
	Email NVARCHAR(50) NOT NULL
)
CREATE TABLE Departments
(
		Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(50) NOT NULL
)
CREATE TABLE Employees
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(25),
	LastName NVARCHAR(25),
	Birthdate DATETIME,
	Age INT CHECK(Age BETWEEN 18 AND 110),
	DepartmentId INT FOREIGN KEY REFERENCES Departments(Id),

)
CREATE TABLE Categories
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] NVARCHAR(50) NOT NULL,
	DepartmentId INT REFERENCES Departments(Id) NOT NULL,
)
CREATE TABLE [Status]
(
	Id INT PRIMARY KEY IDENTITY,
	[Label] NVARCHAR(30) NOT NULL

)
CREATE TABLE Reports
(
	Id INT IDENTITY,
	CategoryId INT FOREIGN KEY REFERENCES Categories(Id) NOT NULL,
	StatusId INT FOREIGN KEY REFERENCES [Status](Id) NOT NULL,
    OpenDate DATETIME NOT NULL,
	CloseDate DATETIME ,
	[Description] NVARCHAR(200) NOT NULL,
	UserId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL,
    EmployeeId INT FOREIGN KEY REFERENCES Employees(Id)
)
--Section 2. DML 
--2.Insert
INSERT INTO Employees (FirstName, LastName, Birthdate, DepartmentId)
VALUES
('Marlo', 'O''Malley', '1958-9-21', 1),
('Niki', 'Stanaghan', '1969-11-26', 4),
('Ayrton', 'Senna', '1960-03-21', 9),
('Ronnie', 'Peterson', '1944-02-14', 9),
('Giovanna', 'Amati', '1959-07-20', 5)

INSERT INTO Reports(CategoryId, StatusId, OpenDate, CloseDate, [Description], UserId, EmployeeId)
VALUES
(1, 1, '2017-04-13', NULL, 'Stuck Road on Str.133', 6, 2),
(6, 3, '2015-09-05', '2015-12-06', 'Charity trail running', 3, 5),
(14, 2, '2015-09-07', NULL,  'Falling bricks on Str.58', 5, 2),
(4, 3, '2017-07-03', '2017-07-06', 'Cut off streetlight on Str.11', 1, 1)

--3.Update
UPDATE Reports
SET CloseDate = GETDATE()
WHERE CloseDate IS NULL

--4.Delete

DELETE Reports
WHERE StatusId = 4

--Section 3. Querying
--5.Unassigned Reports

SELECT [Description],
	FORMAT(OpenDate, 'dd-MM-yyyy') OpenDate
FROM Reports
WHERE EmployeeId IS NULL
ORDER BY OpenDate ASC,
	[Description] ASC

--7.Most Reported Category

SELECT TOP(5)
	COUNT(*) AS ReportsNumber,
	c.[Name] AS CategoryName
FROM Reports AS r
JOIN Categories AS c ON c.Id = r.CategoryId
GROUP BY r.CategoryId, c.[Name]
ORDER BY  ReportsNumber DESC,
	CategoryName ASC

--8.Birthday Report
SELECT u.[Username], c.[Name] 
FROM Reports AS r
JOIN Users AS u ON u.Id = r.UserId
AND CAST(DATEPART(MONTH, u.Birthdate) AS VARCHAR(10)) + '/' + 
	CAST(DATEPART(DAY, u.Birthdate) AS VARCHAR(10)) =
	CAST(DATEPART(MONTH, r.OpenDate) AS VARCHAR(10)) + '/' + 
	CAST(DATEPART(DAY, r.OpenDate) AS VARCHAR(10))
JOIN Categories AS c ON r.CategoryId = c.Id
ORDER BY u.Username ASC, c.[Name]


--9.Users per Emplyees
SELECT FullName,
	COUNT(*) AS UsersCount	
	FROM
	(SELECT CONCAT(e.FirstName,' ',e.LastName) AS FullName,
		UserId 
	FROM Employees AS e
		JOIN Reports AS r ON r.EmployeeId = e.Id
GROUP BY e.FirstName, e.LastName, UserId) AS Curent
GROUP BY FullName
ORDER BY  UsersCount DESC


--10.Full Info

SELECT CONCAT(e.FirstName, ' ', e.LastName) AS Employee,
	d.[Name] AS Department,
	c.[Name] AS Category,
	r.[Description],
	FORMAT(r.OpenDate ,'dd.MM.yyyy') as OpenDate,
	s.[Label] AS Status,
	u.[Name] AS [User]
	FROM Reports AS r
JOIN Employees AS e ON r.EmployeeId = e.Id 
JOIN Departments AS d ON e.DepartmentId = d.Id 
JOIN Categories AS c ON r.CategoryId = c.Id 
JOIN [Status] AS s ON r.StatusId = s.Id
JOIN Users AS u ON r.UserId = u.Id
ORDER BY e.FirstName DESC,
	e.LastName DESC,
	d.[Name] ASC,
	c.[Name] ASC,
	r.[Description] ASC,
	r.OpenDate ASC,
	s.[Label] ASC,
	u.[Name] ASC

--Section 4. Programmability 
--11.Hours to Complete

CREATE OR ALTER FUNCTION udf_HoursToComplete
(
	@StartDate DATETIME,
	@EndDate DATETIME
) 
RETURNS INT
AS
BEGIN
	DECLARE @Result INT;
	IF(@StartDate IS NULL OR @EndDate IS NULL)
		BEGIN
			SET	@Result = 0;
		
		END
	ELSE
		BEGIN
			SET @Result = DATEDIFF(HOUR,@StartDate,@EndDate);
		
		END
	RETURN @Result;
END
SELECT dbo.udf_HoursToComplete(OpenDate, CloseDate) AS DiffTime  FROM Reports

-- 11.Hours to Complete
CREATE OR ALTER PROC [dbo].[usp_AssignEmployeeToReport]
	(
		 @EmployeeId INT
		,@ReportId INT
	) 
	AS
	BEGIN

		DECLARE	@Curent_EmployeeId INT,
				@Curent_ReportId INT;

		SELECT @Curent_EmployeeId = DepartmentId
		FROM Employees 
		WHERE Id = @EmployeeId 

		SELECT @Curent_ReportId = c.DepartmentId
		FROM Reports AS r
		JOIN Categories AS c ON c.Id = r.Id
		where r.Id = @ReportId
		
		IF(@Curent_EmployeeId = @Curent_ReportId)
			BEGIN
				UPDATE Reports
				SET EmployeeId = @EmployeeId 			
				WHERE Id = @ReportId			
			END		
		ELSE
			BEGIN 
				 ;THROW 50001, 'Employee doesn''t belong to the appropriate department!', 1;
			END
	END

	EXEC usp_AssignEmployeeToReport 30 ,1
	
	EXEC usp_AssignEmployeeToReport 17 ,2