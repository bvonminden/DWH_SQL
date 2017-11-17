USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_Meetings]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_Meetings] 
(@StartDate		DATE
	,@EndDate		DATE
	,@ProgramID			VARCHAR(4000)
	--,@Tribal	INT
	)


AS

--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@ProgramID			VARCHAR(4000)
--SET @StartDate		= CAST('7/1/2013' AS DATE)
--SET @EndDate		= CAST('6/30/2014' AS DATE)
--SET @ProgramID			= '1576'--,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'

DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @ProgramID


SELECT 	
	P.StateAbbr [State]
	,P.StateName [US State]
	,P.StateID StateID
	,P.SiteID [Site_ID]
	,P.SiteName AGENCY_INFO_0_NAME
	,P.ProgramID
	,P.TeamName Team_Name
	,SUM(TeamMeetings) Meetings_team_curr
	,SUM(CaseConferences) Meetings_case_curr
	,CAST(DATEDIFF(DAY,@StartDate,@EndDate)/7 AS INT) Weeks_in_Period_curr
FROM AggFidelity 
JOIN DimProgramsAndSites P ON AggFidelity.ProgramID = P.ProgramID
WHERE 
LastDay BETWEEN  @rStartDate AND @rEndDate
AND GroupID = 1
AND (P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))

GROUP BY 
	P.StateAbbr
	,P.StateName
	,P.StateID
	,P.SiteID
	,P.SiteName
	,P.ProgramID
	,P.TeamName
GO
