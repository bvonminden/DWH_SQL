USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_Meetings2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_Meetings2] 
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
	--,P.ProgramID
	--,P.TeamName Team_Name
	,NE.NurseID Entity_Id
	,NE.FullName Full_Name
	,MIN(NEStart.StartDate) StartDate
	,MAX(CASE WHEN NE.EndFlag = 1 THEN NE.EffectiveDate END) EndDate
	,NE.NHV HV_COUNT_curr
	,NE.NS Sup_curr
	,COUNT(DISTINCT FES.SurveyResponseID) Surv_Count_curr
	,COUNT(DISTINCT FES2.SurveyResponseID) Surv2_Count_curr
FROM 
(SELECT N.*
	,CASE WHEN (N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor') AND 
				(N.NursePrimaryRole <> 'Nurse Supervisor' OR N.NursePrimaryRole IS NULL) AND (N.NurseSecondaryRole <> 'Nurse Supervisor' OR N.NurseSecondaryRole IS NULL) THEN 1 END NHV
	,CASE WHEN N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' THEN 1 END NS
	,ROW_NUMBER() OVER(PARTITION BY N.NurseID, N.ProgramID ORDER BY N.EffectiveDate DESC) RowNum 
	,DimNurse.FullName
	FROM FactNurseEnrollment N
	JOIN DimNurse ON N.NurseID = DimNurse.NurseID 
	WHERE N.EffectiveDate < @rEndDate) NE
LEFT JOIN (SELECT NurseID,ProgramID,MIN(EffectiveDate) StartDate FROM FactNurseEnrollment GROUP BY NurseID,ProgramID) NEstart ON NE.NurseID = NEstart.NurseID and NE.ProgramID = NEstart.ProgramID
JOIN DimProgramsAndSites P ON NE.ProgramID = P.ProgramID
LEFT JOIN FactEncounter FES ON FES.MeetingDate BETWEEN @rStartDate AND @rEndDate
							AND FES.FormTypeID = 3
							AND NE.NurseID = FES.NurseID
							AND P.ProgramIDStaffSupervision = FES.ProgramID
LEFT JOIN FactEncounter FES2 ON FES2.MeetingDate BETWEEN @rStartDate AND @rEndDate
							AND FES2.FormTypeID = 3
							AND NE.NurseID = FES2.NurseSupervisorID
							AND P.ProgramIDStaffSupervision = FES2.ProgramID
		    
WHERE NE.RowNum = 1 
AND (NE.EndFlag IS NULL OR (NE.EffectiveDate > @rStartDate AND NE.EndFlag =1))
AND (P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
AND (NE.NHV IS NOT NULL OR NE.NS IS NOT NULL)
GROUP BY 
	P.StateAbbr 
	,P.StateName 
	,P.StateID 
	,P.SiteID 
	,P.SiteName 
	,NE.NurseID 
	,NE.FullName 
	,NE.NHV 
	,NE.NS
GO
