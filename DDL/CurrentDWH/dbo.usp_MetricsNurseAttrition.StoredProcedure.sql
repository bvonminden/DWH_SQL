USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsNurseAttrition]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 1/2/2015
-- Description:	Lists NHV nurses who started and/or left in the month containing the ref date.
--				Some nurses leave one team and start on another.
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsNurseAttrition] 
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @StartDate DATETIME
	DECLARE @EndDate DATETIME

	--First day of month containing RefDate
	SET @StartDate = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)

	--First day of the month AFTER the month containing RefDate
	SET @EndDate = DATEADD(dd, -(DAY(DATEADD(mm,1,@RefDate))-1), DATEADD(mm,1,@RefDate))

	--ALL NHV who started or terminated in the month
	SELECT CONVERT(VARCHAR(50),ST.Entity_Id) AS StaffID, ST.Full_Name, CONVERT(VARCHAR(50),ST.ProgramID) ProgramID, PAS.ProgramName, ST.Abbreviation, ST.StartDate, ST.EndDate
	INTO #StartEndNHV
	FROM fn_FID_Staff_list('1/1/1995', GETDATE()) ST
	INNER JOIN UV_PAS PAS ON ST.ProgramID = PAS.ProgramID
	WHERE (ST.StartDate BETWEEN @StartDate AND @EndDate OR ST.EndDate BETWEEN @StartDate AND @EndDate) AND (PrimRole = 'Nurse Home Visitor' OR SecRole = 'Nurse Home Visitor')
	ORDER BY Full_Name
	
	--Only NHV who terminated in the month
	SELECT * 
	INTO #EndNHV
	FROM #StartEndNHV
	WHERE EndDate IS NOT NULL
	
	SELECT * FROM #EndNHV E
	INNER JOIN #StartEndNHV S ON E.StaffID = S.StaffID
	ORDER BY E.Full_Name
	
	DROP TABLE #StartEndNHV
	DROP TABLE #EndNHV
END
GO
