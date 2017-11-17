USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B3]
	-- Add the parameters for the stored procedure here
	@Site INT,@Quarter INT, @QuarterYear INT
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
		,PAS.ProgramName
		,PAS.Site
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
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Preg%36%' THEN 1
				END
			  ),0) [Depression Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%1%4%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%12%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Preg%36%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%1%4%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%4%6%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND MS_E.SurveyName LIKE '%Inf%12%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Preg%36%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%1%4%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%4%6%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%12%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 12 mos]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_LEARNING] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_Involvement] IS NOT NULL
					--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_Involvement] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_Involvement] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_0_TOTAL] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						THEN CAST(IHS2.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 18 mos agg]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Preg%36%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%1%4%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND MS_PHQ.SurveyName LIKE '%Inf%12%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 12 mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Communication Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Problem Solving Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ Personal-Social Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [ASQ ASQ-SE Screening 24 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ),0) [ASQ Communication Score 24 Mos - Agg]

		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ),0) [ASQ Gross Motor Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ),0) [ASQ Gross Motor Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ),0) [ASQ Gross Motor Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ),0) [ASQ Gross Motor Score 24 Mos - Agg]

		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ),0) [ASQ Fine Motor Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ),0) [ASQ Fine Motor Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ),0) [ASQ Fine Motor Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ),0) [ASQ Fine Motor Score 24 Mos - Agg]


		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ),0) [ASQ Problem Solving Score 24 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ),0) [ASQ Personal-Social Score 24 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 6 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 12 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 18 Mos - Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ),0) [ASQ ASQ-SE Score 24 Mos - Agg]			  
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening 6 Mos]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening 12 Mos]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening 18 Mos]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening 24 Mos]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND MS_IHS.SurveyName LIKE '%6%'
			THEN 1 
		 END) [Abnormal Height excluded 6 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND MS_IHS.SurveyName LIKE '%12%'
			THEN 1 
		 END) [Abnormal Height excluded 12 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND MS_IHS.SurveyName LIKE '%18%'
			THEN 1 
		 END) [Abnormal Height excluded 18 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND MS_IHS.SurveyName LIKE '%24%'
			THEN 1 
		 END) [Abnormal Height excluded 24 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND MS_IHS.SurveyName LIKE '%6%'
			THEN 1
			END) [Abnormal Weight excluded 6 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND MS_IHS.SurveyName LIKE '%12%'
			THEN 1
			END) [Abnormal Weight excluded 12 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND MS_IHS.SurveyName LIKE '%18%'
			THEN 1
			END) [Abnormal Weight excluded 18 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND MS_IHS.SurveyName LIKE '%24%'
			THEN 1
			END) [Abnormal Weight excluded 24 Months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND MS_IHS.SurveyName LIKE '%6%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 6 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND MS_IHS.SurveyName LIKE '%12%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 12 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND MS_IHS.SurveyName LIKE '%18%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 18 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND MS_IHS.SurveyName LIKE '%24%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 24 months]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 24 Mos Agg]
,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 24 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 24 Mos Agg]
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 24 Mos - Agg]	
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 24 Mos - Agg]
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 24 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%6%'
					THEN 1
				END
			) [Infant Health Survey 6 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%12%'
					THEN 1
				END
			) [Infant Health Survey 12 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
					THEN 1
				END
			) [Infant Health Survey 18 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%24%'
					THEN 1
				END
			) [Infant Health Survey 24 Mos Agg]		
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 6 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 12 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 18 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 24 Mos]		
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
			AND CFS.ProgramID = EAD.ProgramID
			AND CFS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
			AND C.Last_Name <> 'Fake'
		LEFT JOIN DataWarehouse..Mstr_surveys MS_CFS
			ON MS_CFS.SurveyID = CFS.SurveyID
			AND MS_CFS.SurveyName NOT LIKE '%MASTER%'
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.ProgramID = EAD.ProgramID
			AND MHS.SurveyDate < = @QuarterDate
		
		LEFT JOIN DataWarehouse..Edinburgh_Survey ES
			ON ES.CL_EN_GEN_ID = EAD.CLID
			AND ES.ProgramID = EAD.ProgramID
			AND ES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_E
			ON MS_E.SurveyID = ES.SurveyID
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
			AND IBS.ProgramID = EAD.ProgramID
			AND IBS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			AND IHS.ProgramID = EAD.ProgramID
			AND IHS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
			ON MS_IHS.SurveyID = IHS.SurveyID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS2
			ON IHS2.CL_EN_GEN_ID = EAD.CLID
			AND IHS2.ProgramID = EAD.ProgramID
			AND IHS2.SurveyDate < = @QuarterDate
			AND IHS2.SurveyID IN (
									SELECT MS_IHS2.SurveyID
									FROM DataWarehouse..Mstr_surveys MS_IHS2
									WHERE MS_IHS2.SurveyName LIKE '%INFANT%6%'
								)
		LEFT JOIN DataWarehouse..PHQ_Survey PHQ
			ON PHQ.CL_EN_GEN_ID = EAD.CLID
			AND PHQ.ProgramID = EAD.ProgramID
			AND PHQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_PHQ
			ON MS_PHQ.SurveyID = PHQ.SurveyID
		INNER JOIN DataWarehouse..ProgramsAndSites PAS
			ON PAS.ProgramID = EAD.ProgramID
			AND PAS.ProgramName LIKE '%NURSE%'
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID

	WHERE EAD.SiteID IN (@Site)
		AND EAD.ProgramStartDate < = @QuarterDate
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
		EAD.CaseNumber--,EAD.EndDate
		,CFS.[SurveyDate]
		,CFS.[AuditDate]
		,PAS.ProgramName
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
	,F.Site,F.ProgramName

	----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15E36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15E36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15E36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15E36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15E36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15E36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15E36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15E36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15E36
	,F.[36 Weeks Preg Y/N] DT_15E36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15E14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15E14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15E14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15E14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15E14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15E14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15E14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15E14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15E14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15E14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15E46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15E46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15E46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15E46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15E46
	,F.[Infancy 4 - 6 Months Y/N] DT_15E46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15E12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15E12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15E12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15E12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15E12
	,F.[Infancy 12 Months Y/N] DT_15E12	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15P36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15P36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15P36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15P36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15P36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15P36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15P36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15P36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15P36
	,F.[36 Weeks Preg Y/N] DT_15P36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15P14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15P14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15P14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15P14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15P14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15P14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15P14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15P14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15P14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15P14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15P46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15P46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15P46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15P46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15P46
	,F.[Infancy 4 - 6 Months Y/N] DT_15P46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15P12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15P12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15P12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15P12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15P12
	,F.[Infancy 12 Months Y/N] DT_15P12	
----------------------------------------
,CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NC_15EP36
	,CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NF_15EP36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END	NFC_15EP36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NN_15EP36
	,CASE F.[36 Weeks Preg Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END NT_15EP36
	,CASE F.Competitive
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DC_15EP36
	,CASE F.Formula
		WHEN 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DF_15EP36
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DFC_15EP36
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END DN_15EP36
	,F.[36 Weeks Preg Y/N] DT_15EP36	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NC_15EP14
	,CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NF_15EP14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END	NFC_15EP14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NN_15EP14
	,CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END NT_15EP14
	,CASE F.Competitive
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DC_15EP14
	,CASE F.Formula
		WHEN 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DF_15EP14
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DFC_15EP14
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END DN_15EP14
	,F.[1 - 8 Weeks Infancy Y/N] DT_15EP14	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15EP46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 4 - 6 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15EP46
	,CASE F.[Infancy 4 - 6 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15EP46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15EP46
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15EP46
	,F.[Infancy 4 - 6 Months Y/N] DT_15EP46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15EP12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infancy 12 Months Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15EP12
	,CASE F.[Infancy 12 Months Y/N]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15EP12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DC_15EP12
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N]
		ELSE 0
	END DN_15EP12
	,F.[Infancy 12 Months Y/N] DT_15EP12	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 
			AND (
					F.[PHQ-9 Score at 36 Weeks] >= 10 
					OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
					OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
					OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
					OR F.[Depression Score at 36 Weeks] >= 10
					OR F.[Depression Score at Infancy 1-4 weeks] >= 10
					OR F.[Depression Score at Infancy 12 mos] >= 10
					OR F.[Depression Score at Infancy 4-6 mos] >= 10
				)
		THEN 1
		ELSE 0
	END NC_15S10
	,CASE 
		WHEN F.Formula = 1 
			AND (
					F.[PHQ-9 Score at 36 Weeks] >= 10 
					OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
					OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
					OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
					OR F.[Depression Score at 36 Weeks] >= 10
					OR F.[Depression Score at Infancy 1-4 weeks] >= 10
					OR F.[Depression Score at Infancy 12 mos] >= 10
					OR F.[Depression Score at Infancy 4-6 mos] >= 10
				)
		THEN 1
		ELSE 0
	END NF_15S10
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1  
			AND (
					F.[PHQ-9 Score at 36 Weeks] >= 10 
					OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
					OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
					OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
					OR F.[Depression Score at 36 Weeks] >= 10
					OR F.[Depression Score at Infancy 1-4 weeks] >= 10
					OR F.[Depression Score at Infancy 12 mos] >= 10
					OR F.[Depression Score at Infancy 4-6 mos] >= 10
				)
		THEN 1
		ELSE 0
	END	NFC_15S10
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  
			AND (
					F.[PHQ-9 Score at 36 Weeks] >= 10 
					OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
					OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
					OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
					OR F.[Depression Score at 36 Weeks] >= 10
					OR F.[Depression Score at Infancy 1-4 weeks] >= 10
					OR F.[Depression Score at Infancy 12 mos] >= 10
					OR F.[Depression Score at Infancy 4-6 mos] >= 10
				)
		THEN 1
		ELSE 0
	END NN_15S10
	,CASE 
		WHEN  
			(
				F.[PHQ-9 Score at 36 Weeks] >= 10 
				OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
				OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
				OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
				OR F.[Depression Score at 36 Weeks] >= 10
				OR F.[Depression Score at Infancy 1-4 weeks] >= 10
				OR F.[Depression Score at Infancy 12 mos] >= 10
				OR F.[Depression Score at Infancy 4-6 mos] >= 10
			) 
		THEN 1
		ELSE 0
	END NT_15S10
	,CASE F.Competitive
		WHEN 1 THEN F.[Infancy 12 Months Y/N] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DC_15S10
	,CASE F.Formula
		WHEN 1 THEN F.[Infancy 12 Months Y/N] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DF_15S10
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infancy 12 Months Y/N] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DFC_15S10
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infancy 12 Months Y/N] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infancy 4 - 6 Months Y/N]
		ELSE 0
	END DN_15S10
	,F.[Infancy 12 Months Y/N] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infancy 4 - 6 Months Y/N] DT_15S10	

------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NC_31L
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NF_31L
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END	NFC_31L
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NN_31L
	,F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos] NT_31L
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DC_31L
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DF_31L
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DFC_31L
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END DN_31L
	,F.[Learning Materials Score - 6 mos] DT_31L
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NC_31L6
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NF_31L6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END	NFC_31L6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END NN_31L6
	,F.[Learning Materials Score - 6 mos] NT_31L6
	,CASE
		WHEN F.Competitive = 1 AND F.[Learning Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DC_31L6
	,CASE
		WHEN F.Formula = 1 AND F.[Learning Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DF_31L6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DFC_31L6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DN_31L6
	,CASE
		WHEN F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DT_31L6
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END NC_31L18
	,CASE F.Formula
		WHEN 1 THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END NF_31L18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END	NFC_31L18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END NN_31L18
	,F.[Learning Materials Score - 18 mos agg] NT_31L18
	,CASE
		WHEN F.Competitive = 1 AND F.[Learning Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DC_31L18
	,CASE
		WHEN F.Formula = 1 AND F.[Learning Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DF_31L18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DFC_31L18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DN_31L18
	,CASE
		WHEN F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DT_31L18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NC_31I
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NF_31I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END	NFC_31I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NN_31I
	,F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos] NT_31I
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DC_31I
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DF_31I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DFC_31I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END DN_31I
	,F.[Involvement Materials Score - 6 mos] DT_31I
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NC_31I6
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NF_31I6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END	NFC_31I6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END NN_31I6
	,F.[Involvement Materials Score - 6 mos] NT_31I6
	,CASE
		WHEN F.Competitive = 1 AND F.[Involvement Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DC_31I6
	,CASE
		WHEN F.Formula = 1 AND F.[Involvement Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DF_31I6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DFC_31I6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DN_31I6
	,CASE
		WHEN F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DT_31I6
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END NC_31I18
	,CASE F.Formula
		WHEN 1 THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END NF_31I18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END	NFC_31I18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END NN_31I18
	,F.[Involvement Materials Score - 18 mos agg] NT_31I18
	,CASE
		WHEN F.Competitive = 1 AND F.[Involvement Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DC_31I18
	,CASE
		WHEN F.Formula = 1 AND F.[Involvement Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DF_31I18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DFC_31I18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DN_31I18
	,CASE
		WHEN F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DT_31I18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NC_32
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NF_32
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END	NFC_32
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END NN_32
	,F.[Total Score - 18 mos] - F.[Total Score - 6 mos] NT_32
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DC_32
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DF_32
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DFC_32
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END DN_32
	,F.[Total Score - 6 mos] DT_32
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END NC_326
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END NF_326
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END	NFC_326
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 6 mos]
		ELSE 0
	END NN_326
	,F.[Total Score - 6 mos] NT_326
	,CASE
		WHEN F.Competitive = 1 AND F.[Total Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DC_326
	,CASE
		WHEN F.Formula = 1 AND F.[Total Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DF_326
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DFC_326
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DN_326
	,CASE
		WHEN F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DT_326
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END NC_3218
	,CASE F.Formula
		WHEN 1 THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END NF_3218
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END	NFC_3218
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END NN_3218
	,F.[Total Score - 18 mos agg] NT_3218
	,CASE
		WHEN F.Competitive = 1 AND F.[Total Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DC_3218
	,CASE
		WHEN F.Formula = 1 AND F.[Total Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DF_3218
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DFC_3218
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DN_3218
	,CASE
		WHEN F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DT_3218
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NC_33R
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NF_33R
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END	NFC_33R
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END NN_33R
	,F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos] NT_33R
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DC_33R
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DF_33R
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DFC_33R
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END DN_33R
	,F.[Responsivity Score - 6 mos] DT_33R
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END NC_33R6
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END NF_33R6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END	NFC_33R6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END NN_33R6
	,F.[Responsivity Score - 6 mos] NT_33R6
	,CASE
		WHEN F.Competitive = 1 AND F.[Responsivity Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DC_33R6
	,CASE
		WHEN F.Formula = 1 AND F.[Responsivity Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DF_33R6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DFC_33R6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DN_33R6
	,CASE
		WHEN F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DT_33R6
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END NC_33R18
	,CASE F.Formula
		WHEN 1 THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END NF_33R18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END	NFC_33R18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END NN_33R18
	,F.[Responsivity Score - 18 mos agg] NT_33R18
	,CASE
		WHEN F.Competitive = 1 AND F.[Responsivity Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DC_33R18
	,CASE
		WHEN F.Formula = 1 AND F.[Responsivity Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DF_33R18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DFC_33R18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DN_33R18
	,CASE
		WHEN F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DT_33R18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NC_33A
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NF_33A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END	NFC_33A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END NN_33A
	,F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos] NT_33A
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DC_33A
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DF_33A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DFC_33A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END DN_33A
	,F.[Acceptance Score - 6 mos] DT_33A
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END NC_33A6
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END NF_33A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END	NFC_33A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END NN_33A6
	,F.[Acceptance Score - 6 mos] NT_33A6
	,CASE
		WHEN F.Competitive = 1 AND F.[Acceptance Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DC_33A6
	,CASE
		WHEN F.Formula = 1 AND F.[Acceptance Score - 6 mos] > 0 THEN 1
		ELSE 0
	END DF_33A6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DFC_33A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DN_33A6
	,CASE
		WHEN F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END DT_33A6
------------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END NC_33A18
	,CASE F.Formula
		WHEN 1 THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END NF_33A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END	NFC_33A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END NN_33A18
	,F.[Acceptance Score - 18 mos agg] NT_33A18
	,CASE
		WHEN F.Competitive = 1 AND F.[Acceptance Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DC_33A18
	,CASE
		WHEN F.Formula = 1 AND F.[Acceptance Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END DF_33A18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DFC_33A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DN_33A18
	,CASE
		WHEN F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END DT_33A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END NC_356
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END NF_356
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END	NFC_356
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 6 mos]
		ELSE 0
	END NN_356
	,F.[ASQ Communication Screening 6 mos] NT_356
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_356
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_356
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_356
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_356
	,F.[Infant Health Survey 6 Mos] DT_356	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NC_3512
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NF_3512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END	NFC_3512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 12 mos]
		ELSE 0
	END NN_3512
	,F.[ASQ Communication Screening 12 mos] NT_3512
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_3512
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_3512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_3512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_3512
	,F.[Infant Health Survey 12 Mos] DT_3512	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NC_3518
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NF_3518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END	NFC_3518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 18 mos]
		ELSE 0
	END NN_3518
	,F.[ASQ Communication Screening 18 mos] NT_3518
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DC_3518
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DF_3518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DFC_3518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DN_3518
	,F.[Infant Health Survey 18 Mos] DT_3518	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NC_3524
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NF_3524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END	NFC_3524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Screening 24 mos]
		ELSE 0
	END NN_3524
	,F.[ASQ Communication Screening 24 mos] NT_3524
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DC_3524
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DF_3524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DFC_3524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DN_3524
	,F.[Infant Health Survey 24 Mos] DT_3524	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NC_35A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NF_35A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END	NFC_35A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 6 Mos - Agg]
		ELSE 0
	END NN_35A6
	,F.[ASQ Communication Score 6 Mos - Agg] NT_35A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_35A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_35A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_35A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_35A6
	,F.[Infant Health Survey 6 Mos Agg] DT_35A6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NC_35A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NF_35A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END	NFC_35A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 12 Mos - Agg]
		ELSE 0
	END NN_35A12
	,F.[ASQ Communication Score 12 Mos - Agg] NT_35A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_35A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_35A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_35A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_35A12
	,F.[Infant Health Survey 12 Mos Agg] DT_35A12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NC_35A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NF_35A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END	NFC_35A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 18 Mos - Agg]
		ELSE 0
	END NN_35A18
	,F.[ASQ Communication Score 18 Mos - Agg] NT_35A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_35A18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_35A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_35A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_35A18
	,F.[Infant Health Survey 18 Mos Agg] DT_35A18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NC_35A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NF_35A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END	NFC_35A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Communication Score 24 Mos - Agg]
		ELSE 0
	END NN_35A24
	,F.[ASQ Communication Score 24 Mos - Agg] NT_35A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_35A24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_35A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_35A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_35A24
	,F.[Infant Health Survey 24 Mos Agg] DT_35A24	
	
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			--AND F.[ASQ Communication Score 6 Mos - Agg] > 0
		THEN 1
		ELSE 0
	END NC_35CO6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			--AND F.[ASQ Communication Score 6 Mos - Agg] > 0
		THEN 1
		ELSE 0
	END NF_35CO6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Communication Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			--AND F.[ASQ Communication Score 6 Mos - Agg] > 0
		THEN 1
		ELSE 0
	END	NFC_35CO6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			--AND F.[ASQ Communication Score 6 Mos - Agg] > 0
		THEN 1
		ELSE 0
	END NN_35CO6
	,CASE
		WHEN F.[ASQ Communication Score 6 Mos - Agg] <	(
															SELECT AC.[6_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Communication'
														)
			--AND F.[ASQ Communication Score 6 Mos - Agg] > 0
		THEN 1
	END NT_35CO6
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_35CO6
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_35CO6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
			AND F.[ASQ Communication Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_35CO6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_35CO6
	,CASE
		WHEN F.[ASQ Communication Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DT_35CO6
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_35CO12
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_35CO12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Communication Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_35CO12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_35CO12
	,CASE
		WHEN F.[ASQ Communication Score 12 Mos - Agg] <	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Communication'
														)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN 1
	END NT_35CO12
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_35CO12
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_35CO12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_35CO12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_35CO12
	,CASE
		WHEN F.[ASQ Communication Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DT_35CO12

----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_35CO18
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_35CO18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Communication Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_35CO18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_35CO18
	,CASE
		WHEN F.[ASQ Communication Score 18 Mos - Agg] <	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Communication'
														)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN 1
	END NT_35CO18
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_35CO18
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_35CO18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_35CO18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_35CO18
	,CASE
		WHEN F.[ASQ Communication Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DT_35CO18
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_35CO24
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_35CO24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Communication Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_35CO24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Communication'
															)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_35CO24
	,CASE
		WHEN F.[ASQ Communication Score 24 Mos - Agg] <	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Communication'
														)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN 1
	END NT_35CO24
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_35CO24
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_35CO24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_35CO24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_35CO24
	,CASE
		WHEN F.[ASQ Communication Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DT_35CO24

----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_36PS6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_36PS6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Problem Solving Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_36PS6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_36PS6
	,CASE
		WHEN F.[ASQ Problem Solving Score 6 Mos - Agg] <	(
															SELECT AC.[6_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN 1
	END NT_36PS6
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_36PS6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_36PS6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_36PS6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_36PS6
	,CASE
		WHEN F.[ASQ Problem Solving Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DT_36PS6
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_36PS12
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_36PS12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Problem Solving Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_36PS12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_36PS12
	,CASE
		WHEN F.[ASQ Problem Solving Score 12 Mos - Agg] <	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN 1
	END NT_36PS12
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_36PS12
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_36PS12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_36PS12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_36PS12
	,CASE
		WHEN F.[ASQ Problem Solving Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DT_36PS12

----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_36PS18
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_36PS18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Problem Solving Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_36PS18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_36PS18
	,CASE
		WHEN F.[ASQ Problem Solving Score 18 Mos - Agg] <	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN 1
	END NT_36PS18
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_36PS18
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_36PS18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_36PS18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_36PS18
	,CASE
		WHEN F.[ASQ Problem Solving Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DT_36PS18
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_36PS24
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_36PS24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Problem Solving Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_36PS24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_36PS24
	,CASE
		WHEN F.[ASQ Problem Solving Score 24 Mos - Agg] <	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN 1
	END NT_36PS24
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_36PS24
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_36PS24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_36PS24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_36PS24
	,CASE
		WHEN F.[ASQ Problem Solving Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DT_36PS24
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_37PrsS6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_37PrsS6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Personal-Social Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_37PrsS6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] <	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_37PrsS6
	,CASE
		WHEN F.[ASQ Personal-Social Score 6 Mos - Agg] <	(
															SELECT AC.[6_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN 1
	END NT_37PrsS6
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_37PrsS6
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_37PrsS6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_37PrsS6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_37PrsS6
	,CASE
		WHEN F.[ASQ Personal-Social Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DT_37PrsS6
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_37PrsS12
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_37PrsS12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Personal-Social Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_37PrsS12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_37PrsS12
	,CASE
		WHEN F.[ASQ Personal-Social Score 12 Mos - Agg] <	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN 1
	END NT_37PrsS12
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_37PrsS12
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_37PrsS12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_37PrsS12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1
			AND F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_37PrsS12
	,CASE
		WHEN F.[ASQ Personal-Social Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DT_37PrsS12

----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_37PrsS18
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_37PrsS18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Personal-Social Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_37PrsS18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_37PrsS18
	,CASE
		WHEN F.[ASQ Personal-Social Score 18 Mos - Agg] <	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN 1
	END NT_37PrsS18
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_37PrsS18
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_37PrsS18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_37PrsS18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_37PrsS18
	,CASE
		WHEN F.[ASQ Personal-Social Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DT_37PrsS18
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_37PrsS24
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_37PrsS24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ Personal-Social Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_37PrsS24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_37PrsS24
	,CASE
		WHEN F.[ASQ Personal-Social Score 24 Mos - Agg] <	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN 1
	END NT_37PrsS24
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_37PrsS24
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_37PrsS24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_37PrsS24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_37PrsS24
	,CASE
		WHEN F.[ASQ Personal-Social Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DT_37PrsS24
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] >=	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_38SE6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] >=	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_38SE6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ ASQ-SE Score 6 Mos - Agg] >=	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_38SE6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] >=	(
																SELECT AC.[6_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_38SE6
	,CASE
		WHEN F.[ASQ ASQ-SE Score 6 Mos - Agg] >=	(
															SELECT AC.[6_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN 1
	END NT_38SE6
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_38SE6
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_38SE6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_38SE6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_38SE6
	,CASE
		WHEN F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DT_38SE6
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_38SE12
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_38SE12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_38SE12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_38SE12
	,CASE
		WHEN F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN 1
	END NT_38SE12
	,CASE
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_38SE12
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_38SE12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_38SE12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_38SE12
	,CASE
		WHEN F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg] 
	END DT_38SE12

----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_38SE18
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_38SE18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_38SE18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_38SE18
	,CASE
		WHEN F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN 1
	END NT_38SE18
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_38SE18
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_38SE18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_38SE18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_38SE18
	,CASE
		WHEN F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DT_38SE18
----------------------------------------
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NC_38SE24
	,CASE 
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NF_38SE24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
					AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END	NFC_38SE24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN 1
		ELSE 0
	END NN_38SE24
	,CASE
		WHEN F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN 1
	END NT_38SE24
	,CASE 
		WHEN F.Competitive = 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_38SE24
	,CASE
		WHEN F.Formula = 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_38SE24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_38SE24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_38SE24
	,CASE
		WHEN F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DT_38SE24
----------------------------------------

	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END NC_366
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END NF_366
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END	NFC_366
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 6 mos]
		ELSE 0
	END NN_366
	,F.[ASQ Problem Solving Screening 6 mos] NT_366
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_366
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_366
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_366
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_366
	,F.[Infant Health Survey 6 Mos] DT_366	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NC_3612
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NF_3612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END	NFC_3612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 12 mos]
		ELSE 0
	END NN_3612
	,F.[ASQ Problem Solving Screening 12 mos] NT_3612
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_3612
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_3612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_3612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_3612
	,F.[Infant Health Survey 12 Mos] DT_3612	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NC_3618
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NF_3618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END	NFC_3618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 18 mos]
		ELSE 0
	END NN_3618
	,F.[ASQ Problem Solving Screening 18 mos] NT_3618
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DC_3618
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DF_3618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DFC_3618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DN_3618
	,F.[Infant Health Survey 18 Mos] DT_3618	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NC_3624
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NF_3624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END	NFC_3624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Screening 24 mos]
		ELSE 0
	END NN_3624
	,F.[ASQ Problem Solving Screening 24 mos] NT_3624
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DC_3624
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DF_3624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DFC_3624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DN_3624
	,F.[Infant Health Survey 24 Mos] DT_3624	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NC_36A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NF_36A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END	NFC_36A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 6 Mos - Agg]
		ELSE 0
	END NN_36A6
	,F.[ASQ Problem Solving Score 6 Mos - Agg] NT_36A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_36A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_36A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_36A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_36A6
	,F.[Infant Health Survey 6 Mos Agg] DT_36A6	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NC_36A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NF_36A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END	NFC_36A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 12 Mos - Agg]
		ELSE 0
	END NN_36A12
	,F.[ASQ Problem Solving Score 12 Mos - Agg] NT_36A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_36A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_36A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_36A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_36A12
	,F.[Infant Health Survey 12 Mos Agg] DT_36A12	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NC_36A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NF_36A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END	NFC_36A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 18 Mos - Agg]
		ELSE 0
	END NN_36A18
	,F.[ASQ Problem Solving Score 18 Mos - Agg] NT_36A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_36A18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_36A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_36A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_36A18
	,F.[Infant Health Survey 18 Mos Agg] DT_36A18	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NC_36A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NF_36A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END	NFC_36A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Problem Solving Score 24 Mos - Agg]
		ELSE 0
	END NN_36A24
	,F.[ASQ Problem Solving Score 24 Mos - Agg] NT_36A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_36A24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_36A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_36A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_36A24
	,F.[Infant Health Survey 24 Mos Agg] DT_36A24	

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END NC_376
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END NF_376
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END	NFC_376
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 6 mos]
		ELSE 0
	END NN_376
	,F.[ASQ Personal-Social Screening 6 mos] NT_376
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_376
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_376
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_376
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_376
	,F.[Infant Health Survey 6 Mos] DT_376	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NC_3712
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NF_3712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END	NFC_3712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 12 mos]
		ELSE 0
	END NN_3712
	,F.[ASQ Personal-Social Screening 12 mos] NT_3712
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_3712
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_3712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_3712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_3712
	,F.[Infant Health Survey 12 Mos] DT_3712	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NC_3718
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NF_3718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END	NFC_3718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 18 mos]
		ELSE 0
	END NN_3718
	,F.[ASQ Personal-Social Screening 18 mos] NT_3718
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DC_3718
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DF_3718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DFC_3718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DN_3718
	,F.[Infant Health Survey 18 Mos] DT_3718	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NC_3724
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NF_3724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END	NFC_3724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Screening 24 mos]
		ELSE 0
	END NN_3724
	,F.[ASQ Personal-Social Screening 24 mos] NT_3724
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DC_3724
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DF_3724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DFC_3724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DN_3724
	,F.[Infant Health Survey 24 Mos] DT_3724	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NC_37A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NF_37A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END	NFC_37A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 6 Mos - Agg]
		ELSE 0
	END NN_37A6
	,F.[ASQ Personal-Social Score 6 Mos - Agg] NT_37A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_37A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_37A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_37A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_37A6
	,F.[Infant Health Survey 6 Mos Agg] DT_37A6	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NC_37A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NF_37A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END	NFC_37A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 12 Mos - Agg]
		ELSE 0
	END NN_37A12
	,F.[ASQ Personal-Social Score 12 Mos - Agg] NT_37A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_37A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_37A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_37A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_37A12
	,F.[Infant Health Survey 12 Mos Agg] DT_37A12	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NC_37A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NF_37A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END	NFC_37A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 18 Mos - Agg]
		ELSE 0
	END NN_37A18
	,F.[ASQ Personal-Social Score 18 Mos - Agg] NT_37A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_37A18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_37A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_37A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_37A18
	,F.[Infant Health Survey 18 Mos Agg] DT_37A18	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NC_37A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NF_37A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END	NFC_37A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Personal-Social Score 24 Mos - Agg]
		ELSE 0
	END NN_37A24
	,F.[ASQ Personal-Social Score 24 Mos - Agg] NT_37A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_37A24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_37A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_37A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_37A24
	,F.[Infant Health Survey 24 Mos Agg] DT_37A24	

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END NC_386
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END NF_386
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END	NFC_386
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END NN_386
	,F.[ASQ ASQ-SE Screening 6 mos] NT_386
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_386
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_386
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_386
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_386
	,F.[Infant Health Survey 6 Mos] DT_386
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NC_3812
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NF_3812
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END	NFC_3812
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END NN_3812
	,F.[ASQ ASQ-SE Screening 12 mos] NT_3812
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_3812
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_3812
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_3812
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_3812
	,F.[Infant Health Survey 12 Mos] DT_3812
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NC_3818
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NF_3818
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END	NFC_3818
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END NN_3818
	,F.[ASQ ASQ-SE Screening 18 mos] NT_3818
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DC_3818
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DF_3818
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DFC_3818
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DN_3818
	,F.[Infant Health Survey 18 Mos] DT_3818
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NC_3824
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NF_3824
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END	NFC_3824
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END NN_3824
	,F.[ASQ ASQ-SE Screening 24 mos] NT_3824
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DC_3824
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DF_3824
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DFC_3824
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DN_3824
	,F.[Infant Health Survey 24 Mos] DT_3824	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NC_38A6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NF_38A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END	NFC_38A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END NN_38A6
	,F.[ASQ ASQ-SE Score 6 Mos - Agg] NT_38A6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DC_38A6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_38A6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_38A6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_38A6
	,F.[Infant Health Survey 6 Mos Agg] DT_38A6	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NC_38A12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NF_38A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END	NFC_38A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END NN_38A12
	,F.[ASQ ASQ-SE Score 12 Mos - Agg] NT_38A12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DC_38A12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_38A12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_38A12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_38A12
	,F.[Infant Health Survey 12 Mos Agg] DT_38A12	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NC_38A18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NF_38A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END	NFC_38A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END NN_38A18
	,F.[ASQ ASQ-SE Score 18 Mos - Agg] NT_38A18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DC_38A18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_38A18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_38A18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_38A18
	,F.[Infant Health Survey 18 Mos Agg] DT_38A18	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NC_38A24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NF_38A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END	NFC_38A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END NN_38A24
	,F.[ASQ ASQ-SE Score 24 Mos - Agg] NT_38A24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DC_38A24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_38A24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_38A24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_38A24
	,F.[Infant Health Survey 24 Mos Agg] DT_38A24	
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NC_39S6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NF_39S6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END	NFC_39S6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 6 Mos]
		ELSE 0
	END NN_39S6
	,F.[ASQ Weight/Height/Head Measured Screening 6 Mos] NT_39S6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_39S6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_39S6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_39S6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_39S6
	,F.[Infant Health Survey 6 Mos] DT_39S6
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NC_39S12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NF_39S12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END	NFC_39S12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END NN_39S12
	,F.[ASQ Weight/Height/Head Measured Screening 12 Mos] NT_39S12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_39S12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_39S12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_39S12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_39S12
	,F.[Infant Health Survey 12 Mos] DT_39S12
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NC_39S18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NF_39S18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END	NFC_39S18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END NN_39S18
	,F.[ASQ Weight/Height/Head Measured Screening 18 Mos] NT_39S18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DC_39S18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DF_39S18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DFC_39S18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END DN_39S18
	,F.[Infant Health Survey 18 Mos] DT_39S18
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NC_39S24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NF_39S24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END	NFC_39S24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END NN_39S24
	,F.[ASQ Weight/Height/Head Measured Screening 24 Mos] NT_39S24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DC_39S24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DF_39S24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DFC_39S24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END DN_39S24
	,F.[Infant Health Survey 24 Mos] DT_39S24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END NC_39H6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END NF_39H6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END	NFC_39H6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END NN_39H6
	,F.[ASQ Height Measured Screening 6 Mos Agg] NT_39H6
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DC_39H6
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_39H6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_39H6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_39H6
	,F.[Infant Health Survey 6 Mos Agg] DT_39H6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END NC_39H12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END NF_39H12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END	NFC_39H12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END NN_39H12
	,F.[ASQ Height Measured Screening 12 Mos Agg] NT_39H12
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DC_39H12
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_39H12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_39H12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_39H12
	,F.[Infant Health Survey 12 Mos Agg] DT_39H12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END NC_39H18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END NF_39H18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END	NFC_39H18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END NN_39H18
	,F.[ASQ Height Measured Screening 18 Mos Agg] NT_39H18
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DC_39H18
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_39H18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_39H18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_39H18
	,F.[Infant Health Survey 18 Mos Agg] DT_39H18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END NC_39H24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END NF_39H24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END	NFC_39H24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END NN_39H24
	,F.[ASQ Height Measured Screening 24 Mos Agg] NT_39H24
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DC_39H24
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_39H24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_39H24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_39H24
	,F.[Infant Health Survey 24 Mos Agg] DT_39H24

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END NC_39W6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END NF_39W6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END	NFC_39W6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END NN_39W6
	,F.[ASQ Weight Measured Screening 6 Mos Agg] NT_39W6
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DC_39W6
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_39W6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_39W6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_39W6
	,F.[Infant Health Survey 6 Mos Agg] DT_39W6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END NC_39W12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END NF_39W12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END	NFC_39W12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END NN_39W12
	,F.[ASQ Weight Measured Screening 12 Mos Agg] NT_39W12
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DC_39W12
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_39W12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_39W12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_39W12
	,F.[Infant Health Survey 12 Mos Agg] DT_39W12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END NC_39W18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END NF_39W18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END	NFC_39W18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END NN_39W18
	,F.[ASQ Weight Measured Screening 18 Mos Agg] NT_39W18
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DC_39W18
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_39W18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_39W18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_39W18
	,F.[Infant Health Survey 18 Mos Agg] DT_39W18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END NC_39W24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END NF_39W24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END	NFC_39W24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END NN_39W24
	,F.[ASQ Weight Measured Screening 24 Mos Agg] NT_39W24
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DC_39W24
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_39W24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_39W24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_39W24
	,F.[Infant Health Survey 24 Mos Agg] DT_39W24

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END NC_39HC6
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END NF_39HC6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END	NFC_39HC6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END NN_39HC6
	,F.[ASQ Head Measured Screening 6 Mos Agg] NT_39HC6
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END DC_39HC6
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DF_39HC6
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DFC_39HC6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END DN_39HC6
	,F.[Infant Health Survey 6 Mos Agg] DT_39HC6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END NC_39HC12
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END NF_39HC12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END	NFC_39HC12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END NN_39HC12
	,F.[ASQ Head Measured Screening 12 Mos Agg] NT_39HC12
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END DC_39HC12
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DF_39HC12
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DFC_39HC12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END DN_39HC12
	,F.[Infant Health Survey 12 Mos Agg] DT_39HC12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END NC_39HC18
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END NF_39HC18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END	NFC_39HC18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END NN_39HC18
	,F.[ASQ Head Measured Screening 18 Mos Agg] NT_39HC18
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END DC_39HC18
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DF_39HC18
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DFC_39HC18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END DN_39HC18
	,F.[Infant Health Survey 18 Mos Agg] DT_39HC18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END NC_39HC24
	,CASE F.Formula
		WHEN 1 THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END NF_39HC24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END	NFC_39HC24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END NN_39HC24
	,F.[ASQ Head Measured Screening 24 Mos Agg] NT_39HC24
	,CASE 
		WHEN F.Competitive = 1 THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END DC_39HC24
	,CASE 
		WHEN F.Formula = 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DF_39HC24
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DFC_39HC24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END DN_39HC24
	,F.[Infant Health Survey 24 Mos Agg] DT_39HC24

FROM FHVI F


OPTION(RECOMPILE)

END

GO
