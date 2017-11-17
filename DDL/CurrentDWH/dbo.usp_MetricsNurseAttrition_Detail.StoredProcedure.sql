USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsNurseAttrition_Detail]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[usp_MetricsNurseAttrition_Detail] 
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
	SELECT CONVERT(VARCHAR(50),ST.Entity_Id) AS StaffID, ST.Full_Name, CONVERT(VARCHAR(50),ST.ProgramID) ProgramID, PAS.ProgramName, ST.Abbreviation, CONVERT(VARCHAR,ST.StartDate,101) StartDate, CONVERT(VARCHAR, ST.EndDate, 101) EndDate
	FROM fn_FID_Staff_list('1/1/1995', GETDATE()) ST
	INNER JOIN UV_PAS PAS ON ST.ProgramID = PAS.ProgramID
	WHERE (ST.StartDate BETWEEN @StartDate AND @EndDate OR ST.EndDate BETWEEN @StartDate AND @EndDate) AND (PrimRole = 'Nurse Home Visitor' OR SecRole = 'Nurse Home Visitor')
	ORDER BY Full_Name
END
GO
