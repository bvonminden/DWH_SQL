USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[Load_Calendar_Year]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 01/11/2016
-- Description:	Load a calendar year with work days and holidays to be used by the data extract process
-- =============================================
CREATE PROCEDURE [dbo].[Load_Calendar_Year] 
	@CalendarYear INT,
	@Holidays NVARCHAR(256)

AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @DAYCNT INT, @CURDATE DATE, @Holiday BIT, @CurMth INT, @NextMth INT, @DayOfWeek INT, @FirstDayOfYear DATE, @FirstDayOfNextYear DATE, @SQL VARCHAR(256)

	DECLARE @HolidayTable TABLE (HolidayDate DATE)

	SET @FirstDayOfYear = CAST(CAST(@CalendarYear AS CHAR(4)) + '-01-01' AS DATE)
	SET @FirstDayOfNextYear = CAST(CAST(@CalendarYear + 1 AS CHAR(4)) + '-01-01' AS DATE)

	DELETE FROM Calendar WHERE year([Date]) = @CalendarYear

	INSERT INTO @HolidayTable VALUES (@Holidays);

WITH mycte AS
(
  SELECT CAST(@FirstDayOfYear AS DATETIME) DateValue
  UNION ALL
  SELECT  DateValue + 1
  FROM    mycte   
  WHERE   DateValue + 1 < @FirstDayOfNextYear
)

INSERT INTO dbo.Calendar ([Date])
SELECT  DateValue
 FROM    mycte
 OPTION (MAXRECURSION 0)
	
UPDATE dbo.Calendar SET DayOfWeekNumber = DATEPART(dw,[DATE])

UPDATE dbo.Calendar SET DayOfWeekText = DATENAME(dw,[DATE])

UPDATE dbo.Calendar SET Holiday = 'FALSE'

--UPDATE dbo.Calendar SET Holiday = 'TRUE' WHERE [DATE] IN ('2016-01-01', '2016-01-18', '2016-02-15', '2016-05-30', '2016-07-04', '2016-09-05', '2016-11-24', '2016-12-25')
--SET @SQL = 'UPDATE dbo.Calendar SET Holiday = ''TRUE'' WHERE [DATE] IN (' + @Holidays + ')'
--exec sp_executeSQL @SQL
UPDATE dbo.Calendar SET Holiday = 'TRUE' WHERE [DATE] IN (SELECT HolidayDate FROM @HolidayTable)

SET @DAYCNT = 0
SET @CurMth = 1
	
DECLARE DATECURSOR CURSOR FOR
	SELECT [Date], Holiday, MONTH([Date]), DayOfWeekNumber FROM dbo.Calendar ORDER BY [Date]
	
OPEN DATECURSOR
FETCH NEXT FROM DATECURSOR INTO @CURDATE, @Holiday, @NextMth, @DayOfWeek

WHILE @@FETCH_STATUS = 0
BEGIN

print 'NextMth = ' + cast(@NextMth as char) + ' CurMth = ' + cast(@CurMth as char) + ' DayCnt = ' + cast(@DAYCNT as char)
	IF @NextMth > @CurMth
	BEGIN
		SET @DAYCNT = 0
		SET @CurMth = @NextMth
	END
		
	IF @Holiday = 'FALSE' AND @DayOfWeek BETWEEN 2 AND 6
	BEGIN
		SET @DAYCNT = @DAYCNT + 1
		UPDATE dbo.Calendar SET BusinessDayOfMonth = @DAYCNT WHERE [Date] = @CURDATE
	END
	
	FETCH NEXT FROM DATECURSOR INTO @CURDATE, @Holiday, @NextMth, @DayOfWeek
	
END

CLOSE DATECURSOR
DEALLOCATE DATECURSOR

select * from dbo.Calendar

END
GO
