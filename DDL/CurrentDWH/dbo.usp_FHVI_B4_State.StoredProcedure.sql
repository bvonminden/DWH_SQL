USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B4_State]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B4_State]
	-- Add the parameters for the stored procedure here
	@State VARCHAR(5),@Quarter INT, @QuarterYear INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 

SET NOCOUNT ON;
WITH FHVI AS 
(
	SELECT 

		EAD.CaseNumber--,EAD.EndDate
		,CFS.[SurveyDate]
		,CFS.[AuditDate]
		,A.State
		,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_END_OTHER]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_START_OTHER]
		,MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE
		,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD

		,ISNULL(CASE
			WHEN MAX(ISNULL(ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),GETDATE())) > @QuarterStart
			THEN 1
		 END,0) [Pregnancy Intake Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
					WHEN 40 + DATEDIFF(WEEK,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD,CAST(@QuarterDate AS DATE)) >= 36
						AND (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL 
						OR (MAX(IBS.INFANT_BIRTH_0_DOB) > = @QuarterStart 
							AND MAX(IBS.INFANT_BIRTH_1_GEST_AGE) > = 36))
					THEN 1
				 END,0)
		 ELSE 0 END [36 Weeks Preg Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(MAX(CASE WHEN (IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate THEN 1 END),0) 
			ELSE 0 END [Birth]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(WEEK,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 1 AND 15.9
					AND MAX(IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 
		 END,0) 
		 ELSE 0 END [1 - 8 Weeks Infancy Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 4 AND 6
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 4 - 6 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 6 AND 11.9
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 6 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 12 AND 17.9 
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Infancy 12 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 18 AND 23.9
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Toddler 18 Months Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					AND DATEDIFF(MONTH,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) >=24
					AND MAX(IBS.INFANT_BIRTH_0_DOB) < @QuarterStart
				THEN 1 
		 END,0) 
		 ELSE 0 END [Toddler 24 Months Y/N]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
				AND A.State <> 'NJ'
				THEN 1
		 END),0) [Competitive]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
				OR A.State = 'NJ'
				THEN 1
		 END),0) [Formula]
		,ISNULL(MAX(CASE 
			WHEN MHS.CL_EN_GEN_ID IS NOT NULL AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Maternal Health Assessment Y/N]
		
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL THEN 1 
				END
			  ),0) [Domestic Violence Screening Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND MS_RS.SurveyName LIKE '%INTAKE%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy Intake Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND MS_RS.SurveyName LIKE '%36%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND MS_RS.SurveyName LIKE '%12%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Infancy 12 Months Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
				THEN 1
		 END),0) [Client Child Injury Prevention Training Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL 
				OR AES.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Home Visit Encounter Y/N]
		,ISNULL(MAX(CASE
				WHEN RSS.SERVICE_REFER_0_IPV LIKE '%Client%'
				THEN 1
		 END),0)[Domestic Violence Referral]
		,ISNULL(MAX(CASE
				WHEN ([CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER] NOT LIKE 'No%' 
						AND  [CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_HIT_0_SLAP_PARTNER] NOT LIKE 'No%' 
						AND  [CLIENT_ABUSE_HIT_0_SLAP_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HURT_LAST_YR] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HURT_LAST_YR] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER] IS NOT NULL) 
					OR ([CLIENT_ABUSE_FORCED_0_SEX] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_FORCED_0_SEX] IS NOT NULL) 
					OR ([CLIENT_ABUSE_FORCED_1_SEX_LAST_YR] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_FORCED_1_SEX_LAST_YR] IS NOT NULL) 
					OR ([CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME] IS NOT NULL) 
					OR ([CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME] IS NOT NULL) 
					OR ([CLIENT_ABUSE_AFRAID_0_PARTNER] NOT LIKE 'No%'  
						AND  [CLIENT_ABUSE_AFRAID_0_PARTNER] IS NOT NULL) 
					OR ([ABUSE_EMOTION_0_PHYSICAL_PARTNER] NOT LIKE 'No%'  
						AND  [ABUSE_EMOTION_0_PHYSICAL_PARTNER] IS NOT NULL) 
				THEN 1
		 END),0) [Domestic Violence Identified]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
				THEN 1
		 END),0) [Safety Plan discussed]
		,ISNULL(MAX(CASE
				WHEN RSS.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Families screened for need]
		 ,1 [Families in NFP]
		,ISNULL(MAX(
				CASE
					WHEN (
							EAD.EndDate > @QuarterDate
							OR EAD.EndDate IS NULL
						 )
						 AND EAD.ProgramStartDate < = @QuarterDate
					THEN 1
				END
			),0) [Active During Quarter]


	FROM DataWarehouse..EnrollmentAndDismissal EAD
		LEFT JOIN [DataWarehouse].[dbo].[Client_Funding_Survey] CFS
			ON CFS.CL_EN_GEN_ID = EAD.CLID
			AND CFS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
		LEFT JOIN DataWarehouse..Mstr_surveys MS_CFS
			ON MS_CFS.SurveyID = CFS.SurveyID
			AND MS_CFS.SurveyName NOT LIKE '%MASTER%'
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.SurveyDate < = @QuarterDate
		
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			
		LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
			ON MS_IHS.SurveyID = IHS.SurveyID
		
		LEFT JOIN DataWarehouse..Relationship_Survey RS
			ON RS.CL_EN_GEN_ID = EAD.CLID
			AND RS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_RS
			ON MS_RS.SurveyID = RS.SurveyID
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND HVES.CLIENT_COMPLETE_0_VISIT NOT LIKE '%CANC%'
		LEFT JOIN DataWarehouse..Alternative_Encounter_Survey AES
			ON AES.CL_EN_GEN_ID = EAD.CLID
			AND AES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Referrals_to_Services_Survey RSS
			ON RSS.CL_EN_GEN_ID = EAD.CLID
			AND RSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
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
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID

			
	WHERE A.State IN (@State)
		AND EAD.ProgramStartDate < = @QuarterDate
		AND PAS.SiteID NOT IN (286,292)
		AND EAD.ProgramStartDate > = '7/1/2011'
--(
--SELECT 
--	CASE 
--		WHEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_COM),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_FORM),GETDATE())
--			AND ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_COM),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_OTHER),GETDATE())
--			THEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_COM),GETDATE()) 
--		WHEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_FORM),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_COM),GETDATE())
--			AND ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_FORM),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_OTHER),GETDATE())
--			THEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_FORM),GETDATE())  
--		WHEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_OTHER),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_FORM),GETDATE())
--			AND ISNULL(MIN(CF.CLIENT_FUNDING_1_START_OTHER),GETDATE()) < = ISNULL(MIN(CF.CLIENT_FUNDING_1_START_MIECHVP_COM),GETDATE())
--			THEN ISNULL(MIN(CF.CLIENT_FUNDING_1_START_OTHER),GETDATE())
--	END
--FROM Client_Funding_Survey CF
--	INNER JOIN DataWarehouse..ProgramsAndSites PS
--		ON PS.ProgramID = CF.ProgramID 
--		AND PS.ProgramName LIKE '%NURSE%'
--		AND PS.ProgramName NOT LIKE '%TEST%'
--		AND PS.ProgramName NOT LIKE '%TRAIN%'
--		AND PS.ProgramName NOT LIKE '%PROOF%'
--		AND PS.ProgramName NOT LIKE '%DEMO%'
--		AND PS.Site NOT LIKE '%TEST%'
--		AND PS.Site NOT LIKE '%TRAIN%'
--		AND PS.Site NOT LIKE '%DEMO%'
--		AND PS.Site NOT LIKE '%PROOF%'
--)
	GROUP BY
		EAD.CaseNumber
		,CFS.[SurveyDate]
		,CFS.[AuditDate]
		,A.State
		,PAS.Site
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_END_OTHER]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_START_OTHER]
		,MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE
		,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
)

SELECT
	F.CaseNumber
	,F.State
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NC_42
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NF_42
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END	NFC_42
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Screening Y/N]
		ELSE 0
	END NN_42
	,F.[Domestic Violence Screening Y/N] NT_42
	,CASE F.Competitive
		WHEN 1 THEN F.[Active During Quarter] 
		ELSE 0
	END DC_42
	,CASE F.Formula
		WHEN 1 THEN F.[Active During Quarter]
		ELSE 0
	END DF_42
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Active During Quarter]
		ELSE 0
	END DFC_42
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Active During Quarter]
		ELSE 0
	END DN_42
	,F.[Active During Quarter] DT_42
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END NC_42IN
	,CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END NF_42IN
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END	NFC_42IN
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N]
		ELSE 0
	END NN_42IN
	,CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy Intake Y/N] 
		ELSE 0
	END NT_42IN
	,CASE
		WHEN F.Competitive = 1 
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END DC_42IN
	,CASE
		WHEN  F.Formula = 1 
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DF_42IN
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1 )
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DFC_42IN
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DN_42IN
	,CASE
		WHEN F.[Pregnancy Intake Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END DT_42IN
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END NC_4236
	,CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END NF_4236
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END	NFC_4236
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		ELSE 0
	END NN_4236
	,CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Domestic Violence Screening Pregnancy 36 Weeks Y/N] 
		ELSE 0
	END NT_4236
	,CASE
		WHEN F.Competitive = 1 
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END DC_4236
	,CASE
		WHEN  F.Formula = 1 
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DF_4236
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1 )
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DFC_4236
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DN_4236
	,CASE
		WHEN F.[36 Weeks Preg Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END DT_4236
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END NC_4212
	,CASE
		WHEN F.Formula = 1 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END NF_4212
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END	NFC_4212
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N]
		ELSE 0
	END NN_4212
	,CASE
		WHEN F.[Active During Quarter] = 1
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Domestic Violence Screening Infancy 12 Months Y/N] 
		ELSE 0
	END NT_4212
	,CASE
		WHEN F.Competitive = 1 
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter] 
		ELSE 0
	END DC_4212
	,CASE
		WHEN  F.Formula = 1 
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DF_4212
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1 )
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DFC_4212
	,CASE 
		WHEN (F.Competitive <> 1 AND F.Formula <> 1)
			AND F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0
	END DN_4212
	,CASE
		WHEN F.[Infancy 12 Months Y/N] = 1
		THEN F.[Active During Quarter]
		ELSE 0 
	 END DT_4212
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NC_43
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NF_43
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END	NFC_43
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Referral]
		ELSE 0
	END NN_43
	,F.[Domestic Violence Referral] NT_43
	,CASE F.Competitive
		WHEN 1 THEN F.[Domestic Violence Identified] 
		ELSE 0
	END DC_43
	,CASE F.Formula
		WHEN 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DF_43
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DFC_43
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Domestic Violence Identified]
		ELSE 0
	END DN_43
	,F.[Domestic Violence Identified] DT_43
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NC_44
	,CASE F.Formula
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NF_44
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END	NFC_44
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END NN_44
	,F.[Safety Plan discussed] NT_44
	,CASE F.Competitive
		WHEN 1 THEN F.[Safety Plan discussed] 
		ELSE 0
	END DC_44
	,CASE F.Formula
		WHEN 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DF_44
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DFC_44
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Safety Plan discussed]
		ELSE 0
	END DN_44
	,F.[Safety Plan discussed] DT_44


FROM FHVI F

OPTION(RECOMPILE)

END

GO
