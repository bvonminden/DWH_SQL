USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_Visits]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_Visits] 
(@StartDate		DATE
	,@EndDate		DATE
	,@ProgramID			VARCHAR(4000)
	,@Tribal	INT
	)


AS

--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@ProgramID			VARCHAR(4000)
--	,@Tribal		INT
--SET @StartDate		= CAST('7/1/2013' AS DATE)
--SET @EndDate		= CAST('6/30/2014' AS DATE)
--SET @ProgramID			= '1576'--,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'
--SET @Tribal			= 0

DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @ProgramID


;WITH AggFidelity AS
(SELECT 
	elem10_1.ProgramID
	,Elem10_1.Visits PregVisits
	,Elem10_1.PersonalHealthDomain PregPersonalHealthDomain
	,Elem10_1.EnvironHealthDomain PregEnvironHealthDomain
	,Elem10_1.LifeCourseDomain PregLifeCourseDomain
	,Elem10_1.MaternalDomain PregMaternalDomain
	,Elem10_1.FriendFamilyDomain PregFriendFamilyDomain
	,Elem10_2.Visits InfVisits
	,Elem10_2.PersonalHealthDomain InfPersonalHealthDomain
	,Elem10_2.EnvironHealthDomain InfEnvironHealthDomain
	,Elem10_2.LifeCourseDomain InfLifeCourseDomain
	,Elem10_2.MaternalDomain InfMaternalDomain
	,Elem10_2.FriendFamilyDomain InfFriendFamilyDomain
	,Elem10_3.Visits TodVisits
	,Elem10_3.PersonalHealthDomain TodPersonalHealthDomain
	,Elem10_3.EnvironHealthDomain TodEnvironHealthDomain
	,Elem10_3.LifeCourseDomain TodLifeCourseDomain
	,Elem10_3.MaternalDomain TodMaternalDomain
	,Elem10_3.FriendFamilyDomain TodFriendFamilyDomain
FROM


	(SELECT 
			P.StateID
			,P.SiteID
			,P.ProgramID
			,COUNT(FE.SurveyResponseID) Visits
			,SUM(FE.PersonalHealthDomain) PersonalHealthDomain
			,SUM(FE.EnvironHealthDomain) EnvironHealthDomain
			,SUM(FE.LifeCourseDomain) LifeCourseDomain
			,SUM(FE.MaternalDomain) MaternalDomain
			,SUM(FE.FriendFamilyDomain) FriendFamilyDomain
		FROM FactEncounter FE
		LEFT JOIN DimClient C ON FE.ClientID = C.ClientID
		FULL JOIN DimProgramsAndSites P ON FE.ProgramID = P.ProgramID
		LEFT JOIN DimNurse N ON FE.NurseID = N.NurseID  
		WHERE FE.Form = 'HVES' AND FE.VisitStatus = 'Completed' AND SurveyDate BETWEEN @rStartDate AND @rEndDate
			AND (C.InfantDOB IS NULL OR FE.SurveyDate <= C.InfantDOB)
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
		GROUP BY 
			P.StateID,P.SiteID,P.ProgramID
		) Elem10_1
	


	LEFT JOIN
	(SELECT 
			P.StateID
			,P.SiteID
			,P.ProgramID
			,COUNT(FE.SurveyResponseID) Visits
			,SUM(FE.PersonalHealthDomain) PersonalHealthDomain
			,SUM(FE.EnvironHealthDomain) EnvironHealthDomain
			,SUM(FE.LifeCourseDomain) LifeCourseDomain
			,SUM(FE.MaternalDomain) MaternalDomain
			,SUM(FE.FriendFamilyDomain) FriendFamilyDomain
		FROM FactEncounter FE
		LEFT JOIN DimClient C ON FE.ClientID = C.ClientID
		FULL JOIN DimProgramsAndSites P ON FE.ProgramID = P.ProgramID
		LEFT JOIN DimNurse N ON FE.NurseID = N.NurseID  
		WHERE FE.Form = 'HVES' AND FE.VisitStatus = 'Completed' AND SurveyDate BETWEEN @rStartDate AND @rEndDate
			AND (C.InfantDOB IS NOT NULL AND FE.SurveyDate BETWEEN C.InfantDOB AND DATEADD(YEAR,1,C.InfantDOB))
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
		GROUP BY 
		 P.StateID,P.SiteID,P.ProgramID
		) Elem10_2
		ON  Elem10_1.ProgramID = Elem10_2.ProgramID


	LEFT JOIN
	(SELECT 
			P.StateID
			,P.SiteID
			,P.ProgramID
			,COUNT(FE.SurveyResponseID) Visits
			,SUM(FE.PersonalHealthDomain) PersonalHealthDomain
			,SUM(FE.EnvironHealthDomain) EnvironHealthDomain
			,SUM(FE.LifeCourseDomain) LifeCourseDomain
			,SUM(FE.MaternalDomain) MaternalDomain
			,SUM(FE.FriendFamilyDomain) FriendFamilyDomain
		FROM FactEncounter FE
		LEFT JOIN DimClient C ON FE.ClientID = C.ClientID
		FULL JOIN DimProgramsAndSites P ON FE.ProgramID = P.ProgramID
		LEFT JOIN DimNurse N ON FE.NurseID = N.NurseID  
		WHERE FE.Form = 'HVES' AND FE.VisitStatus = 'Completed' AND SurveyDate BETWEEN @rStartDate AND @rEndDate
			AND (C.InfantDOB IS NOT NULL AND FE.SurveyDate BETWEEN DATEADD(YEAR,1,C.InfantDOB) AND DATEADD(YEAR,2,C.InfantDOB))
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
		GROUP BY 
			P.StateID,P.SiteID,P.ProgramID
		) Elem10_3 
		ON Elem10_1.ProgramID = Elem10_3.ProgramID
	)








SELECT 	
	P.StateAbbr [State]
	,P.StateName [US State]
	,P.StateID StateID
	,P.SiteID [Site_ID]
	,P.SiteName AGENCY_INFO_0_NAME
	,P.ProgramID
	,P.TeamName Team_Name
	,SUM(PregVisits) VisitperPhaseTotalPreg
	,SUM(PregPersonalHealthDomain) PhaseSumPreg_PERS
	,SUM(PregEnvironHealthDomain) PhaseSumPreg_ENV
	,SUM(PregLifeCourseDomain) PhaseSumPreg_LIFE
	,SUM(PregMaternalDomain) PhaseSumPreg_MAT
	,SUM(PregFriendFamilyDomain) PhaseSumPreg_FAM
	,SUM(InfVisits) VisitperPhaseTotalInf
	,SUM(InfPersonalHealthDomain) PhaseSumInf_PERS
	,SUM(InfEnvironHealthDomain) PhaseSumInf_ENV
	,SUM(InfLifeCourseDomain) PhaseSumInf_LIFE
	,SUM(InfMaternalDomain) PhaseSumInf_MAT
	,SUM(InfFriendFamilyDomain) PhaseSumInf_FAM
	,SUM(TodVisits) VisitperPhaseTotalTodd
	,SUM(TodPersonalHealthDomain) PhaseSumTodd_PERS
	,SUM(TodEnvironHealthDomain) PhaseSumTodd_ENV
	,SUM(TodLifeCourseDomain) PhaseSumTodd_LIFE
	,SUM(TodMaternalDomain) PhaseSumTodd_MAT
	,SUM(TodFriendFamilyDomain) PhaseSumTodd_FAM
FROM AggFidelity 
JOIN DimProgramsAndSites P ON AggFidelity.ProgramID = P.ProgramID
WHERE 
--LastDay BETWEEN  @rStartDate AND @rEndDate
--AND GroupID = 1
--AND 
(P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))

GROUP BY 
	P.StateAbbr
	,P.StateName
	,P.StateID
	,P.SiteID
	,P.SiteName
	,P.ProgramID
	,P.TeamName
GO
