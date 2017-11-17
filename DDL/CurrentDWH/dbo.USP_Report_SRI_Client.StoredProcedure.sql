USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_Client]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_Client] 
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
--SET @StartDate		= CAST('7/1/2012' AS DATE)
--SET @EndDate		= CAST('6/30/2013' AS DATE)
--SET @ProgramID			= '1373'--'1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'
--SET @Tribal = 0

DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @ProgramID

	SELECT 
			--ROOT.ClientID,
			P.StateID
			,P.SiteID Site_ID
			,P.SiteName AGENCY_INFO_0_NAME
			,P.ProgramID
			,P.TeamName ProgramName
			,COUNT(DISTINCT CASE WHEN ROOT.ClientVoluntary = 'Yes' THEN ROOT.ClientID END) /*VoluntYes*/ VolPart_yes
			,COUNT(DISTINCT CASE WHEN ROOT.ClientVoluntary IS NOT NULL THEN ROOT.ClientID END) /*VoluntAns*/ VolPart_data
			,COUNT(DISTINCT CASE WHEN ROOT.ClientLowIncomeQualify = 'Yes' THEN ROOT.ClientID END) /*LowIncYes*/ LowIncCriteria_yes
			,COUNT(DISTINCT CASE WHEN ROOT.ClientLowIncomeQualify IS NOT NULL THEN ROOT.ClientID END) /*LowIncAns*/ LowIncCriteria_data
			,COUNT(DISTINCT CASE WHEN ROOT.ClientHealthPregnancy0LiveBirths =0 THEN ROOT.ClientID END) /*FirstTimeMotherYes*/ FirstTimeMthr_yes
			,COUNT(DISTINCT CASE WHEN ROOT.ClientHealthPregnancy0LiveBirths IS NOT NULL THEN ROOT.ClientID END) /*FirstTimeMotherAns*/ FirstTimeMthr_data
			,COUNT(DISTINCT CASE WHEN ROOT.ClientVoluntary = 'Yes' AND ROOT.ClientLowIncomeQualify = 'Yes' AND ROOT.ClientHealthPregnancy0LiveBirths =0 AND ROOT.GestAgeIntake BETWEEN 1 AND 28.999 THEN ROOT.ClientID END) All3_yes
			,COUNT(DISTINCT CASE WHEN ROOT.ClientVoluntary IS NOT NULL AND ROOT.ClientLowIncomeQualify IS NOT NULL AND ROOT.ClientHealthPregnancy0LiveBirths IS NOT NULL THEN ROOT.ClientID END) All3_data
			,COUNT(DISTINCT ROOT.ClientID) Total_Enrollment_curr --Enroll
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 1 AND 40.999 THEN ROOT.ClientID END) Total_Enrollment_btw1_40_curr --Enroll_1_40
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 1 AND 28.999 THEN ROOT.ClientID END) Enrollment_by_28_curr --Enroll_1_28
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 1 AND 16.999 THEN ROOT.ClientID END) Gest_int_1_16_curr --Enroll_1_16
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 17 AND 22.999 THEN ROOT.ClientID END) Gest_int_17_22_curr --Enroll_17_22
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 23 AND 28.999 THEN ROOT.ClientID END) Gest_int_23_28_curr --Enroll_23_28
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake BETWEEN 29 AND 40.999 THEN ROOT.ClientID END) Gest_int_29_40_curr --Enroll_29_40
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake > 40.999 THEN ROOT.ClientID END) Enroll_GT40
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake <= 0 THEN ROOT.ClientID END) Enroll_LT40
			,COUNT(DISTINCT CASE WHEN ROOT.GestAgeIntake IS NULL THEN ROOT.ClientID END) EDD_blank_curr --Enroll_EDDMissing
			--,COUNT(DISTINCT CASE WHEN ROOT.ClientHealthPregnancy0LiveBirths IS NULL OR ROOT.ClientHealthPregnancy0LiveBirths =0 THEN ROOT.ClientID END) FirstTimeMotherYes
			--,COUNT(DISTINCT CASE WHEN ROOT.ClientHealthPregnancy0LiveBirths > 0 THEN ROOT.ClientID END) FirstTimeMotherAns
		FROM
			(SELECT a.*,b.ClientHealthPregnancy0LiveBirths,b.GestAgeIntake
			FROM
			(SELECT -- root query for demographics survey data
				C.ClientID 
				,COALESCE(EAD.ProgramID,EAD2.ProgramID) ProgramID
				,EAD.SXStaffID
				,C.DSSurveyDate
				,C.ClientVoluntary
				,C.ClientLowIncomeQualify
				--,NULL ClientHealthPregnancy0LiveBirths
				--,NULL GestAgeIntake
			FROM DimClient C
			LEFT JOIN FactClientEAD EAD 
				ON C.ClientID = EAD.ClientID AND C.DSProgramID = EAD.ProgramID AND C.DSSurveyDate >= EAD.SXStartDate 
				AND (C.DSSurveyDate <=EAD.SXEndDate OR EAD.SXEnddate IS NULL) AND EAD.ProgramTypeID = 2
			LEFT JOIN FactClientEAD EAD2 ON EAD2.ClientID = C.ClientID AND EAD2.ProgramID = C.MHProgramID AND EAD.ProgramID IS NULL AND C.DSSurveyDate >= EAD2.ProgramStartDate 
				AND (C.DSSurveyDate <=EAD2.ProgramEndDate OR EAD2.ProgramEndDate IS NULL) AND EAD2.ProgramTypeID = 2
			WHERE (EAD.ClientID IS NOT NULL OR EAD2.ClientID IS NOT NULL) 
			AND C.DSSurveyDate BETWEEN @rStartDate AND @rEndDate
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
			) a
			
			LEFT JOIN

			(SELECT 
				C.ClientID 
				,COALESCE(EAD.ProgramID,EAD2.ProgramID) ProgramID
				,EAD.SXStaffID
				--,C.DSSurveyDate
				--,NULL ClientVoluntary
				--,NULL ClientLowIncomeQualify
				,C.ClientHealthPregnancy0LiveBirths
				,(40 - CAST(DATEDIFF(DAY, EAD.ProgramStartDate, C.EDD) AS DECIMAL(18, 2))/7) GestAgeIntake
			FROM DimClient C
			LEFT JOIN FactClientEAD EAD 
				ON C.ClientID = EAD.ClientID AND C.MHSSurveyDate >= EAD.SXStartDate 
				AND (C.MHSSurveyDate <=EAD.SXEndDate OR EAD.SXEnddate IS NULL) AND EAD.ProgramTypeID = 2
			LEFT JOIN FactClientEAD EAD2 ON EAD2.ClientID = C.ClientID AND EAD.ProgramID IS NULL AND C.MHSSurveyDate >= EAD2.ProgramStartDate 
				AND (C.MHSSurveyDate <=EAD2.ProgramEndDate OR EAD2.ProgramEndDate IS NULL) AND EAD2.ProgramTypeID = 2
			WHERE (EAD.ClientID IS NOT NULL OR EAD2.ClientID IS NOT NULL) 
			AND C.MHSSurveyDate BETWEEN @rStartDate AND @rEndDate
			AND ((C.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (C.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
			) b
			ON a.ClientID = b.ClientID AND a.ProgramID = b.ProgramID AND a.SXStaffID = b.SXStaffID )ROOT

		FULL JOIN DimProgramsAndSites P ON ROOT.ProgramID = P.ProgramID
		LEFT JOIN DimNurse N ON ROOT.SXStaffID = N.NurseID    
		WHERE (P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
		GROUP BY 
			P.StateID
			,P.SiteID
			,P.SiteName 
			,P.ProgramID
			,P.TeamName 
			--,ROOT.ClientID
		--ROLLUP (P.StateID,P.SiteID,P.ProgramID,N.NurseID)
GO
