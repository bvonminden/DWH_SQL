USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ACCbDay_V3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_ACCbDay_V3] 
	-- Add the parameters for the stored procedure here
@StartDate Date
,@EndDate Date

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;
WITH HVES AS 
(
	SELECT 
		HV.CL_EN_GEN_ID
		,HV.SurveyDate
		,HV.CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
		,HV.NURSE_PERSONAL_0_NAME
		,HV.SurveyResponseID
		,'Home Visit' Form
	FROM DataWarehouse..Home_Visit_Encounter_Survey HV
	WHERE HV.CLIENT_COMPLETE_0_VISIT = 'Completed'
		OR HV.CLIENT_COMPLETE_0_VISIT = 'Attempted'
		--AND HV.SurveyDate < = @EndDate
	
	UNION 
	
	SELECT 
		HV.CL_EN_GEN_ID
		,HV.SurveyDate
		,'Completed' CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
		,HV.NURSE_PERSONAL_0_NAME 
		,HV.SurveyResponseID
		,'Alternative' Form
	FROM DataWarehouse..Alternative_Encounter_Survey HV
	--WHERE HV.SurveyDate < = @EndDate
)
,EADT AS
(
SELECT
	RANK() OVER(PARTITION BY EAD2.CaseNumber ORDER BY 
	EAD2.CLID,EAD2.ProgramStartDate,ISNULL(EAD2.EndDate,GETDATE()),EAD2.RecID) RankingOrig
	,RANK() OVER(PARTITION BY EAD2.CaseNumber ORDER BY 
	EAD2.CLID DESC,EAD2.ProgramStartDate DESC,ISNULL(EAD2.EndDate,GETDATE()) DESC,EAD2.RecID DESC) RankingLatest,EAD2.*
from DataWarehouse..EnrollmentAndDismissal  EAD2
		INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.ProgramID = EAD2.ProgramID 
			AND PAS.ProgramName LIKE '%NURSE%'
			AND PAS.ProgramName NOT LIKE '%TEST%'
			AND PAS.ProgramName NOT LIKE '%TRAIN%'
			AND PAS.ProgramName NOT LIKE '%PROOF%'
			AND PAS.ProgramName NOT LIKE '%DEMO%'
			AND PAS.Site NOT LIKE '%TEST%'
			AND PAS.Site NOT LIKE '%TRAIN%'
			AND PAS.Site NOT LIKE '%DEMO%'
			AND PAS.Site NOT LIKE '%PROOF%'
	WHERE EAD2.ProgramStartDate < = @EndDate
)
SELECT 
	EAD.CaseNumber
,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,@StartDate) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,@StartDate,EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > @StartDate)
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,@StartDate)
				--			AND (
				--					EAD.EndDate > @StartDate or EAD.EndDate is null
				--				)
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@StartDate) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,@StartDate) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,@StartDate)
			  AND DATEADD(D,1,@StartDate) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > @StartDate or EAD.EndDate is null
				  )
		THEN 1
	 END) Start0
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,1,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,1,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,1,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,1,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,1,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,1,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,1,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,1,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,1,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,1,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start1
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,2,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,2,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,2,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,2,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,2,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,2,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,2,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,2,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,2,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,2,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start2
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,3,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,3,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,3,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,3,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,3,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,3,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,3,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,3,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,3,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,3,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start3
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,4,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,4,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,4,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,4,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,4,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,4,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,4,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,4,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,4,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,4,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start4
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,5,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,5,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,5,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,5,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,5,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,5,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,5,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,5,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,5,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,5,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start5
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,6,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,6,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,6,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,6,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,6,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,6,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,6,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,6,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,6,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,6,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start6
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,7,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,7,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,7,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,7,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,7,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,7,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,7,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,7,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,7,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,7,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start7
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,8,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,8,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,8,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,8,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,8,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,8,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,8,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,8,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,8,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,8,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start8
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,9,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,9,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,9,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,9,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,9,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,9,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,9,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,9,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,9,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,9,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start9
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,10,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,10,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,10,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,10,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,10,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,10,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,10,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,10,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,10,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,10,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start10
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,11,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,11,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,11,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,11,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,11,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,11,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,11,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,11,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,11,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,11,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start11
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,12,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,12,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,12,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,12,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,12,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,12,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,12,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,12,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,12,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,12,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start12
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,13,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,13,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,13,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,13,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,13,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,13,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,13,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,13,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,13,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,13,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start13
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,14,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,14,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,14,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,14,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,14,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,14,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,14,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,14,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,14,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,14,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start14
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,15,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,15,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,15,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,15,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,15,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,15,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,15,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,15,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,15,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,15,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start15
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,16,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,16,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,16,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,16,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,16,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,16,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,16,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,16,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,16,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,16,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start16
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,17,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,17,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,17,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,17,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,17,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,17,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,17,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,17,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,17,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,17,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start17
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,18,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,18,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,18,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,18,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,18,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,18,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,18,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,18,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,18,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,18,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start18
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,19,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,19,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,19,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,19,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,19,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,19,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,19,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,19,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,19,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,19,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start19
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,20,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,20,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,20,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,20,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,20,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,20,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,20,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,20,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,20,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,20,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start20
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,21,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,21,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,21,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,21,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,21,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,21,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,21,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,21,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,21,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,21,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start21
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,22,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,22,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,22,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,22,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,22,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,22,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,22,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,22,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,22,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,22,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start22
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,23,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,23,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,23,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,23,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,23,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,23,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,23,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,23,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,23,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,23,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start23
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,24,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,24,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,24,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,24,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,24,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,24,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,24,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,24,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,24,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,24,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start24
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,25,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,25,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,25,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,25,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,25,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,25,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,25,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,25,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,25,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,25,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start25
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,26,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,26,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,26,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,26,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,26,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,26,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,26,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,26,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,26,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,26,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start26
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,27,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,27,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,27,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,27,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,27,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,27,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,27,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,27,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,27,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,27,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start27
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,28,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,28,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,28,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,28,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,28,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,28,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,28,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,28,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,28,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,28,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start28
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,29,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,29,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,29,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,29,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,29,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,29,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,29,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,29,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,29,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,29,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start29
	,MAX(CASE
		WHEN (
				HVES.SurveyDate > DATEADD(D,-180,DATEADD(D,30,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,30,@StartDate),EAD.ProgramStartDate))<=60
				--			AND (HVES.SurveyDate IS NULL OR HVES.SurveyDate > DATEADD(D,30,@StartDate))
				--			AND EAD.ProgramStartDate  < DATEADD(D,1,DATEADD(D,30,@StartDate))
				--			AND (
				--					EAD.EndDate > DATEADD(D,30,@StartDate) or EAD.EndDate is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),DATEADD(D,30,@StartDate)) <= 730.5 
					OR ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) IS NULL
				  )
			  AND DATEDIFF(D,EAD.ProgramStartDate,DATEADD(D,30,@StartDate)) <= 1010
			  AND EAD.ProgramStartDate < DATEADD(D,1,DATEADD(D,30,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,30,@StartDate)) <= DATEADD(D,1,@EndDate)
			  AND (
					EAD.EndDate > DATEADD(D,30,@StartDate) or EAD.EndDate is null
				  )
		THEN 1
	 END) Start30
		 ,DATEADD(D,14,@StartDate)
	 
FROM DataWarehouse..Clients C
	INNER JOIN EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @EndDate 
	INNER JOIN EADT EAD2
		ON EAD2.CaseNumber = EAD.CaseNumber
		AND EAD2.RankingLatest = 1
		AND EAD2.ProgramStartDate < = @EndDate 
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
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
		ON MHS.CL_EN_GEN_ID = C.Client_Id
		AND MHS.SurveyDate < = @EndDate
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = C.Client_Id
		AND IBS.SurveyDate < = @EndDate
	LEFT JOIN HVES
		ON HVES.CL_EN_GEN_ID = EAD.CLID
		

WHERE EAD.RankingLatest = 1
--where ead.CaseNumber = 159062


GROUP BY EAD.CaseNumber

UNION

SELECT 
	CL.CLIENTID
,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,@StartDate) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,@StartDate,CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > @StartDate)
				--			AND CL.ADD_DATE  < DATEADD(D,1,@StartDate)
				--			AND (
				--					CL.CNSNDAT > @StartDate or CL.CNSNDAT is null
				--				)
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,@StartDate) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,@StartDate) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,@StartDate)
			  AND DATEADD(D,1,@StartDate) <= DATEADD(D,1,@EndDate)

		THEN 1
	 END) Start0
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,1,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,1,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,1,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,1,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,1,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,1,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,1,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,1,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,1,@StartDate)) <= DATEADD(D,1,@EndDate)

		THEN 1
	 END) Start1
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,2,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,2,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,2,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,2,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,2,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,2,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,2,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,2,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,2,@StartDate)) <= DATEADD(D,1,@EndDate)

		THEN 1
	 END) Start2
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,3,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,3,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,3,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,3,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,3,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,3,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,3,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,3,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,3,@StartDate)) <= DATEADD(D,1,@EndDate)

		THEN 1
	 END) Start3
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,4,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,4,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,4,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,4,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,4,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,4,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,4,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,4,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,4,@StartDate)) <= DATEADD(D,1,@EndDate)

		THEN 1
	 END) Start4
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,5,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,5,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,5,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,5,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,5,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,5,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,5,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,5,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,5,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start5
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,6,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,6,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,6,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,6,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,6,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,6,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,6,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,6,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,6,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start6
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,7,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,7,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,7,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,7,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,7,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,7,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,7,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,7,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,7,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start7
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,8,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,8,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,8,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,8,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,8,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,8,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,8,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,8,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,8,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start8
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,9,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,9,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,9,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,9,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,9,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,9,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,9,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,9,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,9,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start9
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,10,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,10,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,10,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,10,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,10,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,10,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,10,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,10,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,10,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start10
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,11,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,11,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,11,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,11,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,11,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,11,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,11,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,11,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,11,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start11
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,12,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,12,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,12,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,12,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,12,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,12,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,12,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,12,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,12,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start12
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,13,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,13,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,13,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,13,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,13,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,13,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,13,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,13,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,13,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start13
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,14,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,14,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,14,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,14,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,14,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,14,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,14,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,14,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,14,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start14
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,15,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,15,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,15,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,15,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,15,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,15,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,15,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,15,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,15,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start15
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,16,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,16,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,16,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,16,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,16,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,16,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,16,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,16,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,16,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start16
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,17,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,17,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,17,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,17,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,17,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,17,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,17,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,17,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,17,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start17
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,18,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,18,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,18,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,18,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,18,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,18,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,18,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,18,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,18,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start18
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,19,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,19,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,19,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,19,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,19,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,19,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,19,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,19,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,19,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start19
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,20,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,20,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,20,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,20,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,20,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,20,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,20,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,20,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,20,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start20
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,21,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,21,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,21,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,21,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,21,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,21,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,21,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,21,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,21,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start21
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,22,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,22,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,22,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,22,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,22,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,22,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,22,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,22,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,22,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start22
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,23,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,23,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,23,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,23,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,23,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,23,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,23,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,23,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,23,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start23
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,24,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,24,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,24,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,24,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,24,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,24,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,24,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,24,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,24,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start24
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,25,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,25,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,25,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,25,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,25,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,25,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,25,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,25,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,25,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start25
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,26,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,26,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,26,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,26,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,26,@StartDate) or CL.CNSNDAT is null
				--				)
							
				   --)
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,26,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,26,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,26,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,26,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start26
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,27,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,27,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,27,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,27,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,27,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,27,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,27,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,27,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,27,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start27
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,28,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,28,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,28,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,28,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,28,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,28,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,28,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,28,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,28,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start28
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,29,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,29,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,29,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,29,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,29,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,29,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,29,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,29,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,29,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start29
	,MAX(CASE
		WHEN (
				V.FORMDATE > DATEADD(D,-180,DATEADD(D,30,@StartDate)) 
				--OR 
				--(
				--		ABS(DATEDIFF(D,DATEADD(D,30,@StartDate),CL.ADD_DATE))<=60
				--			AND (V.FORMDATE IS NULL OR V.FORMDATE > DATEADD(D,30,@StartDate))
				--			AND CL.ADD_DATE  < DATEADD(D,1,DATEADD(D,30,@StartDate))
				--			AND (
				--					CL.CNSNDAT > DATEADD(D,30,@StartDate) or CL.CNSNDAT is null
				--				)
							
				--   )
			 )
			  AND (
					DATEDIFF(D,INF.INFDOB,DATEADD(D,30,@StartDate)) <= 730.5 
					OR INF.INFDOB IS NULL
				  )
			  AND DATEDIFF(D,CL.ADD_DATE,DATEADD(D,30,@StartDate)) <= 1010
			  AND CL.ADD_DATE < DATEADD(D,1,DATEADD(D,30,@StartDate))
			  AND DATEADD(D,1,DATEADD(D,30,@StartDate)) <= DATEADD(D,1,@EndDate)
		THEN 1
	 END) Start30
		 ,DATEADD(D,14,@StartDate)
	 
	 	 
 
FROM [NFP_Master].[PRCLIVE].[CLIENT_TBL] CL
	INNER JOIN NFP_Master.PRCLIVE.SITE_TBL S
		ON S.SITECODE = CL.SITECODE
		AND S.NAME LIKE '%CLOSE%'
	LEFT JOIN NFP_Master.PRCLIVE.VISIT_TBL V
		ON V.CLIENTID = CL.CLIENTID
		AND V.SITECODE = S.SITECODE
	LEFT JOIN [NFP_Master].[PRCLIVE].[INFANT_TBL] INF
		ON INF.CLIENTID = CL.CLIENTID
		AND INF.SITECODE = S.SITECODE

GROUP BY CL.CLIENTID
END
GO
