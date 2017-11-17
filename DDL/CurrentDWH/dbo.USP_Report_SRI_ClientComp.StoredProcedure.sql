USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_ClientComp]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_ClientComp] 
(@StartDate		DATE
	,@EndDate		DATE
	,@ProgramID			VARCHAR(4000)
	,@Tribal	INT
	)

	AS
	
--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@ProgramID		VARCHAR(4000)
--	,@Tribal		INT
--SET @StartDate		= CAST('10/1/2010' AS DATE)
--SET @EndDate		= CAST('9/30/2011' AS DATE)
--SET @ProgramID		= '1007'--'1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'
--SET @Tribal			= 0

DECLARE
	@rStartDate DATE	 = @StartDate
	,@rEndDate DATE  	 = @EndDate
	,@rTeam VARCHAR(MAX) = @ProgramID


	SELECT 
		--StateID
		--,SiteID,
		ProgramID
		,CLID
		,CASE 
			WHEN MAX(PregLeft) = 1 THEN 'Preg_left'
			WHEN MAX(InfLeft) = 1 THEN 'Inf_left'
			WHEN MAX(TodLeft) = 1 THEN 'Tod_left'
			WHEN MAX(TodComp) = 1 THEN 'Tod_comp'
		END End_Phase
	FROM (
------------------------Start Table 1-----------------------------------------
		SELECT 
			P.StateID
			,P.SiteID
			,P.ProgramID
			,EAD.ClientID CLID
			,COUNT(DISTINCT CASE WHEN EAD.ProgramEndDate BETWEEN EAD.ProgramStartDate AND C.EDD 
										AND C.InfantDOB IS NULL 
										AND FE.Form IN('HVES','AltE')
										AND FE.VisitStatus = 'Completed' 
										AND SurveyDate BETWEEN EAD.ProgramStartDate AND C.EDD
								 THEN FE.ClientID END) PregLeft
			,COUNT(DISTINCT CASE WHEN EAD.ProgramEndDate BETWEEN C.InfantDOB AND DATEADD(YEAR,1,C.InfantDOB) 
										AND FE.Form IN('HVES','AltE')
										AND FE.VisitStatus = 'Completed' 
										AND SurveyDate BETWEEN C.InfantDOB AND DATEADD(YEAR,1,C.InfantDOB)
								  THEN FE.ClientID END) InfLeft
			,COUNT(DISTINCT CASE WHEN EAD.ProgramEndDate > DATEADD(YEAR,1,C.InfantDOB) 
										AND EAD.ReasonForDismissal = 'Child reached 2nd birthday' 
										AND FE.Form IN('HVES','AltE')
										AND FE.VisitStatus = 'Completed' 
										AND SurveyDate > DATEADD(YEAR,1,C.InfantDOB)
								  THEN FE.ClientID END) TodComp
			,COUNT(DISTINCT CASE WHEN EAD.ProgramEndDate > DATEADD(YEAR,1,C.InfantDOB) 
										AND (EAD.ReasonForDismissal <> 'Child reached 2nd birthday' 
										AND EAD.ReasonForDismissal IS NOT NULL) 
										AND FE.Form IN('HVES','AltE')
										AND FE.VisitStatus = 'Completed' 
										AND SurveyDate > DATEADD(YEAR,1,C.InfantDOB)
								  THEN FE.ClientID END) TodLeft
		FROM FactEncounter FE
		LEFT JOIN DimClient C ON FE.ClientID = C.ClientID
		LEFT JOIN (SELECT DISTINCT ClientID,ProgramID,ProgramStartDate,ProgramEndDate,ReasonForDismissal FROM FactClientEAD) EAD-- Causes some duplication of data if a client has two enrollments (5000+ total)
					ON FE.ClientID = EAD.ClientID and FE.ProgramID = EAD.ProgramID
		FULL JOIN DimProgramsAndSites P ON FE.ProgramID = P.ProgramID
		--LEFT JOIN DimNurse N ON FE.NurseID = N.NurseID  
		WHERE 

			 (EAD.ProgramStartDate BETWEEN @rStartDate AND @rEndDate)
			AND (P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
		GROUP BY 
			P.StateID,P.SiteID,P.ProgramID
			,EAD.ClientID 


		) DATA
	GROUP BY 
		--StateID
		--,SiteID,
		ProgramID
		,CLID
GO
