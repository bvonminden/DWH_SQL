USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ActiveClientCountByStateAgency]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_ActiveClientCountByStateAgency] ( @EndDate	Date )
AS

----================================================
----for testing

--DECLARE @EndDate As DATE = CAST('9/30/2014' AS DATE)

----================================================

;WITH UV_HVES AS
(
	SELECT   
		HV.CL_EN_GEN_ID
		,HV.SurveyDate
		, HV.ProgramID
	FROM Home_Visit_Encounter_Survey HV
	WHERE HV.CLIENT_COMPLETE_0_VISIT = 'Completed'

	UNION

	SELECT  
		HV.CL_EN_GEN_ID
		,HV.SurveyDate
		,HV.ProgramID
	FROM dbo.Alternative_Encounter_Survey HV
	WHERE HV.CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' 
		OR HV.CLIENT_TALKED_0_WITH_ALT = 'CLIENT'
)
,HV2_SSIS AS
(----this is the HV2 cte from the SSIS SQL
		SELECT 
				H.CL_EN_GEN_ID
				,MAX(H.SurveyDate) LastVisit
				,MIN(H.SurveyDate) FirstVisit
				,H.ProgramID
			FROM UV_HVES H --DataWarehouse..UV_HVES H			----VIEW REPLACED WITH ACTUAL SQL IN CTE, above
			
			----===================================
			--WHERE SurveyDate < = GETDATE()-1					----NOTE:  This was added to simulate the data/date the SSIS package 
																----		would have had when it ran the previous night

			WHERE SurveyDate <= @EndDate						----NOTE:  This was added to simulate the data/date the SSIS package 
			----===================================
			GROUP BY H.CL_EN_GEN_ID, H.ProgramID
)
----end CTEs
----=================================

----THIS IS FROM THE SSRS EMBEDDED SQL
SELECT 
	----=====================================
	---original columns needed for report
	EAD.CaseNumber
	,EAD.CLID
	,A.AGENCY_INFO_0_NAME [Agency]
	,A.State [Agency's State]
	
	,AC.ProgramStartDate acProgramStartDate
	,AC.ActualOrEstimatedEndDate

	------=====================================
	------added for troubleshooting
	
	,'' [Actual pgm start date will be selected as START DATE in WHERE clause]
	,AC.ProgramStartDate acProgramStartDate
	
	,AC.WhatEndDateUsed
	,AC.ActualOrEstimatedEndDate acActualOrEstimatedEndDate
	
	,'' [Actual OR the earlier of estimated end dates 1-4 will be selected as END DATE in WHERE clause]
	
	,AC.ActualEADEndDate acActualEADEndDate	

	,AC.EstEnd1_DismReas2_EnrollEndDate_IfNULLThenYr2050
	,AC.EstEnd1Date_DismissalReason_ChildReached2
	
	,AC.EstEnd2_CouldBe_DOB_or_EDD_IfNULLThenYr2050
	,AC.EstEnd2Date_DismissalReasonNULL_EDD_ChildReached2
	
	,AC.EstEnd3_CouldBe_LastVisit_Or_Yr2050
	,AC.EstEnd3Date_LastVisitOver180
	
	,AC.EstEnd4_Enroll_RnkOrig
	,AC.EstEnd4_EnrollEndDate_If_RnkOrig_Egual_1_EADPgmStartDate
	,AC.EstEnd4_EnrollEndDate_If_RnkOrig_Greater_1_E2EndDate
	,AC.EstEnd4Date_1010DaysInPgm
	
	,@EndDate RptEndDateParm
	
	,AC.origBODActClient
	
	---corrected data
	,AC.BODActClient	
	,AC.NumbDaysSinceLastVisit	
	,AC.NumbDaysInPgm
	,AC.NumbDaysInfAge	
	----=====================================
		
FROM 
	(		---this simulates what is created by table AC_Dates with the SSIS package, but somewhat corrected, like GETDATE() replaced with @EndDate
			SELECT 				
				----=====================================
				----original
				DATA.CLID
				,DATA.ProgramID
				,MIN(DATA.ProgramStartDate) ProgramStartDate
	----NOTE:
	----in the original, the WHERE clause uses 1 of these 5 different possible end dates 
	----to determines if a client is active for the Board of Director (BOD) report, 
	----ALONG with program start date
				,MAX(ISNULL(DATA.EndDate
								,CASE WHEN DATA.END1 <= DATA.END2 AND DATA.END1 <= DATA.END3 AND DATA.END1 <= DATA.END4 THEN DATA.END1
									  WHEN DATA.END2 <= DATA.END1 AND DATA.END2 <= DATA.END3 AND DATA.END2 <= DATA.END4 THEN DATA.END2
									  WHEN DATA.END3 <= DATA.END1 AND DATA.END3 <= DATA.END2 AND DATA.END3 <= DATA.END4 THEN DATA.END3
									  WHEN DATA.END4 <= DATA.END1 AND DATA.END4 <= DATA.END2 AND DATA.END4 <= DATA.END3 THEN DATA.END4 
									  END)) ActualOrEstimatedEndDate
				,DATA.FirstVisit
				,DATA.LastVisit
					
				----=====================================
				------added to original for troubleshooting

				,MAX(CASE 
						WHEN DATA.EndDate IS NOT NULL THEN 'Actual' 
						WHEN DATA.END1 <= DATA.END2 AND DATA.END1 <= DATA.END3 AND DATA.END1 <= DATA.END4 THEN 'END1'
						WHEN DATA.END2 <= DATA.END1 AND DATA.END2 <= DATA.END3 AND DATA.END2 <= DATA.END4 THEN 'END2'
						WHEN DATA.END3 <= DATA.END1 AND DATA.END3 <= DATA.END2 AND DATA.END3 <= DATA.END4 THEN 'END3'
						WHEN DATA.END4 <= DATA.END1 AND DATA.END4 <= DATA.END2 AND DATA.END4 <= DATA.END3 THEN 'END4'
						ELSE 'Unknown' 
					END) WhatEndDateUsed
				
	----NOTE:
	----in the original, the WHERE clause uses 1 of these 5 different possible end dates 
	----to determines if a client is active for the Board of Director (BOD) report, 
	----ALONG with program start date
	----this flag can be used instead of the dates in the WHERE clause
				,CASE WHEN (MIN(DATA.ProgramStartDate) <= @EndDate
							AND 
							MAX(ISNULL(DATA.EndDate
								,CASE WHEN DATA.END1 <= DATA.END2 AND DATA.END1 <= DATA.END3 AND DATA.END1 <= DATA.END4 THEN DATA.END1
									  WHEN DATA.END2 <= DATA.END1 AND DATA.END2 <= DATA.END3 AND DATA.END2 <= DATA.END4 THEN DATA.END2
									  WHEN DATA.END3 <= DATA.END1 AND DATA.END3 <= DATA.END2 AND DATA.END3 <= DATA.END4 THEN DATA.END3
									  WHEN DATA.END4 <= DATA.END1 AND DATA.END4 <= DATA.END2 AND DATA.END4 <= DATA.END3 THEN DATA.END4 
									  END))
									   > @EndDate )
						THEN 1
						ELSE 0
				END origBODActClient

				,MAX(DATA.EndDate) ActualEADEndDate
				
				,MAX(DismReas2_EnrollEndDate_IfEndDateNULLThenYr2050) EstEnd1_DismReas2_EnrollEndDate_IfNULLThenYr2050
				,MAX(DATA.End1) EstEnd1Date_DismissalReason_ChildReached2
	
				,MAX(DATA.CouldBe_DOB_or_EDD_or_Yr2050) EstEnd2_CouldBe_DOB_or_EDD_IfNULLThenYr2050
				,MAX(DATA.End2) EstEnd2Date_DismissalReasonNULL_EDD_ChildReached2
				
				,MAX(CouldBe_LastVisit_Or_Yr2050) EstEnd3_CouldBe_LastVisit_Or_Yr2050
				,MAX(DATA.End3) EstEnd3Date_LastVisitOver180
				
				,MAX(Enroll_RnkOrig) EstEnd4_Enroll_RnkOrig
				,MAX(EnrollEndDate_If_RnkOrig_Egual_1_EADPgmStartDate) EstEnd4_EnrollEndDate_If_RnkOrig_Egual_1_EADPgmStartDate
				,MAX(EnrollEndDate_If_RnkOrig_Greater_1_E2EndDate) EstEnd4_EnrollEndDate_If_RnkOrig_Greater_1_E2EndDate
				,MAX(DATA.End4) EstEnd4Date_1010DaysInPgm
				
				------=====================================
				------this is the logic supplied by the Business/Lisa to Reporting/Cathy
				------think 9/30/2014 when looking at this, historical data
				,CASE WHEN ( 	(MIN(DATA.ProgramStartDate) <= @EndDate
								AND 
								(MAX(DATA.EndDate) > @EndDate OR MAX(Data.EndDate) IS NULL ) )				
								AND ( MAX(DATA.NumbDaysSinceLastVisit) <= 180 OR MAX(DATA.NumbDaysSinceLastVisit) IS NULL )
								AND ( MAX(DATA.NumbDaysInPgm) <= 1010 OR MAX(DATA.NumbDaysInPgm) IS NULL )
								AND ( MAX(DATA.NumbDaysInfAge) <= 730 OR MAX(DATA.NumbDaysInfAge) IS NULL )
							)
						 THEN 1
						 ELSE 0
				END BODActClient	
				
				,MAX(DATA.NumbDaysSinceLastVisit) NumbDaysSinceLastVisit
				,MAX(DATA.NumbDaysInPgm) NumbDaysInPgm
				,MAX(DATA.NumbDaysInfAge) NumbDaysInfAge		
				--=====================================

			FROM(
				SELECT
					EAD.CLID
					,EAD.ProgramID
					,EAD.ProgramStartDate
					,EAD.EndDate
					
					----the following dates, END1-END4, are used IF the actual enrollment end date IS NULL
					
					--END1
					,EAD.EndDate DismReas2_EnrollEndDate_IfEndDateNULLThenYr2050
					,ISNULL(CASE WHEN EAD.ReasonForDismissal LIKE '%2%'
						  THEN EAD.EndDate END,CAST('1/1/2050' AS DATE)) END1
					
					--END2					
					,EDD.EDD CouldBe_DOB_or_EDD_or_Yr2050
					,ISNULL(CASE WHEN EAD.ReasonForDismissal IS NULL
						 THEN DATEADD(DAY,730,EDD.EDD) END,CAST('1/1/2050' AS DATE)) END2
					
					--END3
					,HV2_SSIS.LastVisit CouldBe_LastVisit_Or_Yr2050
					--,ISNULL(CASE WHEN DATEDIFF(DAY,HV2_SSIS.LastVisit, GETDATE()-1 ) >= 180
					--		THEN HV2_SSIS.LastVisit END,CAST('1/1/2050' AS DATE)) END3
---I don't think above is consistent ??? not adding 180 days to date ???					
					--,ISNULL(CASE WHEN DATEDIFF(DAY,HV2_SSIS.LastVisit, @EndDate ) >= 180
					--		THEN HV2_SSIS.LastVisit END,CAST('1/1/2050' AS DATE)) END3
					,ISNULL(CASE WHEN DATEDIFF(DAY,HV2_SSIS.LastVisit, @EndDate ) >= 180
							THEN DATEADD(DAY,180,HV2_SSIS.LastVisit) END,CAST('1/1/2050' AS DATE)) END3

					--END4		
					,EAD.RankingOrig Enroll_RnkOrig
					,E2.EndDate EnrollEndDate_If_RnkOrig_Egual_1_EADPgmStartDate
					,EAD.ProgramStartDate EnrollEndDate_If_RnkOrig_Greater_1_E2EndDate
					,ISNULL(DATEADD(DAY,1010,CASE WHEN EAD.RankingOrig > 1 THEN E2.EndDate ELSE EAD.ProgramStartDate END),CAST('1/1/2050' AS DATE)) END4
					
					,HV2_SSIS.FirstVisit
					,HV2_SSIS.LastVisit

				----===================================================
				----added for troubleshooting current logic
					,DATEDIFF(DAY,HV2_SSIS.LastVisit,@EndDate) NumbDaysSinceLastVisit
	----I have never been able to figure out END4's original logic---why, I mean
	----substituting what I think it should be
					----,DATEDIFF(DAY,CASE WHEN EAD.RankingOrig > 1 THEN E2.EndDate	ELSE EAD.ProgramStartDate END,@EndDate) NumbDaysInPgm_orig
					,DATEDIFF(DAY,EAD.ProgramStartDate,@EndDate) NumbDaysInPgm
					,DATEDIFF(DAY,EDD.EDD,@EndDate) NumbDaysInfAge
				----===================================================
							
				FROM DataWarehouse..Clients C
				
					INNER JOIN DataWarehouse..UV_EADT EAD
						ON EAD.CLID = C.Client_Id					
						
					INNER JOIN DataWarehouse..UV_EADT E2
						ON E2.CaseNumber = EAD.CaseNumber
						AND E2.RankingOrig = 1						
						
					INNER JOIN DataWarehouse..ProgramsAndSites PAS
						ON PAS.ProgramID = EAD.ProgramID 
							AND PAS.ProgramName LIKE '%NURSE%'
							AND PAS.ProgramName NOT LIKE '%TEST%'
							AND PAS.ProgramName NOT LIKE '%TRAIN%'
							AND PAS.ProgramName NOT LIKE '%PROOF%'
							AND PAS.ProgramName NOT LIKE '%DEMO%'
							AND PAS.Site NOT LIKE '%TEST%'
							AND PAS.Site NOT LIKE '%TRAIN%'
							AND PAS.Site NOT LIKE '%DEMO%'
							AND PAS.Site NOT LIKE '%PROOF%'

					LEFT JOIN	
					 (	----for whatever reason, this is grouped/joined on casenumber
						----so had to leave the join to EnrollmentAndDismissal
						----tried to handle without EAD, grouped/joined on Client ID instead
						----ended up with more nulls than with leaving as is
						----so left as is
						SELECT     
							E.CaseNumber
							,MAX(ISNULL(I.INFANT_BIRTH_0_DOB, M.CLIENT_HEALTH_PREGNANCY_0_EDD)) AS EDD
						FROM EnrollmentAndDismissal AS E 
							LEFT OUTER JOIN dbo.Infant_Birth_Survey AS I ON I.CL_EN_GEN_ID = E.CLID 
							LEFT OUTER JOIN dbo.Maternal_Health_Survey AS M ON M.CL_EN_GEN_ID = E.CLID
						WHERE (ISNULL(I.INFANT_BIRTH_0_DOB, M.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NOT NULL)
						GROUP BY E.CaseNumber
					 )  EDD ON EDD.CaseNumber = EAD.CaseNumber							

						
				INNER JOIN HV2_SSIS ---cte
					ON HV2_SSIS.CL_EN_GEN_ID = EAD.CLID
					AND HV2_SSIS.ProgramID = EAD.ProgramID
					
				WHERE HV2_SSIS.LastVisit IS NOT NULL
				
				) DATA
				GROUP BY DATA.CLID
					,DATA.ProgramID
					,DATA.FirstVisit
					,DATA.LastVisit
		
	)AC	---this simulates what is created by table AC_Dates with the SSIS package, but somewhat corrected, like GETDATE() replaced with @EndDate
	
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = AC.CLID
		AND EAD.ProgramID = AC.ProgramID
		AND EAD.RankingLatest = 1
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = EAD.SiteID

---===================================
---run this WHERE with the dates to get what report gets

WHERE AC.ProgramStartDate <= @EndDate
	AND AC.ActualOrEstimatedEndDate > @EndDate			----30229	run 7/1 for 9/30/2014	

-----OR can use flag, below, instead of dates from above---creates exact same output

--WHERE origBODActClient = 1							----30229	run 7/1 for 9/30/2014	

---===================================
-----corrected WITH AND logic
-----use this to only look at the active clients determined by corrected logic from Business/Lisa

--WHERE BODActClient = 1								----29322	run 7/1 for 9/30/2014, diff of 907
						
----===================================


----================================================
----for testing

----ORDER BY 1,2

----================================================



GO
