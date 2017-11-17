USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_StaffMinutes]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 10/22/2013
-- Description:	This will return the total staff hours for a given Date Range
-- =============================================

CREATE PROCEDURE [dbo].[USP_StaffMinutes]
	@StartDate datetime,--StartDate used in search of data
	@EndDate datetime,  --Enddate used in search of data
	@HRMMSS varchar(20) --This will be added to the LogInTime where LogOutTime is NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--table which will hold our chosen data	
Declare @StaffTime table
(
	  [StaffId] int,
	  [FName] nvarchar(50),
	  [LName]nvarchar(50),
      [LogInTime] datetime,
      [LogOutTime] datetime,
      [DiffDays] smallint,
      [DiffMinutes]	int
 )
--Declare the time in minutes. This will be added to the LogInTime where LogOutTime is NULL

--Declare	@StartDate datetime --Used for testing
--Declare	@EndDate datetime,  --Used for testing
--Declare @HRMMSS varchar(20)   --Used for testing
--SET @HRMMSS = '00:20:00'      --Used for testing

Insert into @StaffTime    
SELECT 
	  [StaffId]
	  ,[FName]
	  ,[LName]
      ,[LogInTime]
      ,[LogOutTime]
	  ,DATEDIFF(DAY, [LogInTime],[LogOutTime]) AS [DiffDays]
	  ,DATEDIFF(MINUTE, [LogInTime],[LogOutTime]) AS [DiffMinutes]
FROM [DataWarehouse].[dbo].[JS_ETO_Logins102013]
WHERE
	LogInTime between @StartDate and @EndDate
Order by StaffID asc, LogInTime ASC

Update @StaffTime
SET LogOutTime = [LogInTime] + @HRMMSS
Where
	LogOutTime IS NULL

--ReCalculate times
Update @StaffTime
Set DiffDays = DATEDIFF(DAY, [LogInTime],[LogOutTime]), DiffMinutes = DATEDIFF(MINUTE, [LogInTime],[LogOutTime])
Where
	DiffDays IS NULL

--Report the Findings
Select 
	[STAFFID], 
	[FName], 
	[LName],
	Sum([DiffMinutes])AS [TotalMinutes]
from @StaffTime
Group By [STAFFID], [FName], [LName]

END
GO
