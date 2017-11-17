USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B3_V2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B3_V2]
	-- Add the parameters for the stored procedure here
	@Site VARCHAR(50),@Quarter INT, @QuarterYear INT,@ReportType INT
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
		,PAS.ProgramName
		,PAS.ProgramID
		,PAS.Site
		,PAS.SiteID
		,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) State
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
		,EDD.EDD
		,ISNULL(CASE
			WHEN MAX(ISNULL(EDD.EDD,GETDATE())) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
						AND MIN(EAD.ProgramStartDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END,0) [Pregnancy Intake Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
					WHEN 40 + DATEDIFF(DAY,EDD.EDD,CAST(@QuarterDate AS DATE))/7 >= 36
						AND DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID) <=30
						AND (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL 
						OR (MAX(IBS.INFANT_BIRTH_0_DOB) > = @QuarterStart 
							AND MAX(IBS.INFANT_BIRTH_1_GEST_AGE) > = 36))
					THEN 1
				 END,0)
		 ELSE 0 END [36 Weeks Preg Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(MAX(CASE WHEN (IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate THEN 1 END),0) 
			ELSE 0 END [Birth]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END),0)
			WHEN 1 
			THEN ISNULL(CASE
			WHEN COUNT(DISTINCT 
							CASE 
								WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
							END
						  ) > 0 
					--AND DATEDIFF(WEEK,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 1 AND 15.9
					AND DATEADD(DAY,61,MAX(IBS.INFANT_BIRTH_0_DOB)) BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 
		 END,0) 
		 ELSE 0 END [1 - 8 Weeks Infancy Y/N]
		,CASE ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
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
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
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
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
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
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
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
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						AND (
							CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
							OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
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
				--AND DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) <> 'NJ'
				THEN 1
		 END),0) [Competitive]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
				--OR DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) = 'NJ'
				THEN 1
		 END),0) [Formula]
		,ISNULL(MAX(CASE 
			WHEN MHS.CL_EN_GEN_ID IS NOT NULL AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Maternal Health Assessment Y/N]
		,ISNULL(MAX(
				CASE WHEN IBS.CL_EN_GEN_ID IS NOT NULL
					AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 END),0) [Infant Birth Survey during Quarter]
		,ISNULL(MAX(
				CASE WHEN ISNULL(ISNULL(ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM),EAD.EndDate),GETDATE()) 
							> DATEADD(DAY,61,IBS.INFANT_BIRTH_0_DOB)
						AND DATEADD(DAY,61,IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 END),0) [Active at Infant DOB + 61 days]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Preg%36%' THEN 1
				END
			  ),0) [Depression Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND (dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%12%' THEN 1
				END
			  ),0) [Depression Survey Taken at Infancy 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Preg%36%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND (dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%4%6%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%12%' THEN ES.CLIENT_EPS_TOTAL_SCORE
				END
			  ),0) [Depression Score at Infancy 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND (dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%4%6%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%12%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at Infancy 12 mos]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND IHS2.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_LEARNING] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_LEARNING] AS BIGINT)
				END
			  ) [Learning Materials Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_Involvement] IS NOT NULL
					AND IHS2.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_Involvement] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_Involvement] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_Involvement] AS BIGINT)
				END
			  ) [Involvement Materials Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_0_TOTAL] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_0_TOTAL] AS BIGINT)
				END
			  ) [Total Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_ACCEPTANCE] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_ACCEPTANCE] AS BIGINT)
				END
			  ) [Acceptance Score - 18 mos agg]
		,MAX( 
				CASE
					WHEN IHS2.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS2.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 6 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 18 mos]
		,MAX( 
				CASE
					WHEN IHS.[INFANT_HOME_1_RESPONSIVITY] IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN CAST(IHS.[INFANT_HOME_1_RESPONSIVITY] AS BIGINT)
				END
			  ) [Responsivity Score - 18 mos agg]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND (dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 1-4 weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%4%6%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 4-6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%12%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at Infancy 12 mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 4 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 10 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 14 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 20 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 4 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 10 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 14 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 20 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 4 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 10 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 14 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 20 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ ASQ-SE Screening 6 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ ASQ-SE Screening 12 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ ASQ-SE Screening 18 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ ASQ-SE Screening 24 Mos]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 4 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 10 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 14 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 20 Mos - Agg]

		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 4 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 10 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 14 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 20 Mos - Agg]

		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 4 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 10 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 14 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 20 Mos - Agg]


		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 4 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 10 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 14 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 20 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 4 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 10 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 14 Mos - Agg]
		,MAX(
				CASE
					WHEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN ASQ.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 20 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 24 Mos - Agg]		
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening Agg]	  
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
							OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
							OR IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
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
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
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
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
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
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Weight/Height/Head Measured Screening 24 Mos]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
			THEN 1 
		 END) [Abnormal Height excluded 6 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
			THEN 1 
		 END) [Abnormal Height excluded 12 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
			THEN 1 
		 END) [Abnormal Height excluded 18 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
					OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
			THEN 1 
		 END) [Abnormal Height excluded 24 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
			THEN 1
			END) [Abnormal Weight excluded 6 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
			THEN 1
			END) [Abnormal Weight excluded 12 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
			THEN 1
			END) [Abnormal Weight excluded 18 Months]
		,MAX(CASE
			WHEN (
					IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
					OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
				 )
				AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
			THEN 1
			END) [Abnormal Weight excluded 24 Months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 6 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 12 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 18 months]
		,MAX(CASE
				WHEN (
						IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
						OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
					 )
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
					AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
					AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
				THEN 1
			 END) [Abnormal Head Circ excluded 24 months]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Head Measured Screening 24 Mos Agg]
,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Height Measured Screening 24 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 6 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 12 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 18 Mos Agg]
		,MAX(
				CASE
					WHEN (
							IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						 )
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						THEN 1
				END
			  ) [ASQ Weight Measured Screening 24 Mos Agg]
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEIGHT_0_INCHES
				END
			  ) [ASQ Height 24 Mos - Agg]	
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_WEIGHT_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_WEIGHT_1_OZ
				END
			  ) [ASQ Weight 24 Mos - Agg]
			  
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
				END
			  ) [ASQ Head Circ 24 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
					THEN 1
				END
			) [Infant Health Survey Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
					THEN 1
				END
			) [Infant Health Survey 6 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
					THEN 1
				END
			) [Infant Health Survey 12 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
					THEN 1
				END
			) [Infant Health Survey 18 Mos Agg]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
					THEN 1
				END
			) [Infant Health Survey 24 Mos Agg]		
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 6 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 12 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 18 Mos]
		,MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [Infant Health Survey 24 Mos]		
		,MAX(
				CASE
					WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%4%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [ASQ3 4 Mos]		
		,MAX(
				CASE
					WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Inf%10%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [ASQ3 10 Mos]	
		,MAX(
				CASE
					WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%14%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [ASQ3 14 Mos]	
		,MAX(
				CASE
					WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ASQ.SurveyID) LIKE '%Tod%20%'
						AND ASQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			) [ASQ3 20 Mos]	
		,ISNULL(MAX(
				CASE
					WHEN ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						 AND (
								CFS.CLIENT_FUNDING_1_START_MIECHVP_COM < = @QuarterDate
								OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM < = @QuarterDate
								OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL < = @QuarterDate
							 )
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
					THEN 1
				END
			),0) [Active During Quarter]
			
FROM DataWarehouse..EnrollmentAndDismissal EAD
		INNER JOIN [DataWarehouse].[dbo].[Client_Funding_Survey] CFS
			ON CFS.CL_EN_GEN_ID = EAD.CLID
			AND CFS.ProgramID = EAD.ProgramID
			AND (
					CFS.CLIENT_FUNDING_1_START_MIECHVP_COM BETWEEN '10/1/2010' AND @QuarterDate
					OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM BETWEEN '10/1/2010' AND @QuarterDate
					OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL BETWEEN '10/1/2010' AND @QuarterDate
				)	
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
			AND C.Last_Name <> 'Fake'
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_CFS
		--	ON MS_CFS.SurveyID = CFS.SurveyID
		--	AND dbo.fngetFormName(CFS.SurveyID) NOT LIKE '%MASTER%'
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.ProgramID = EAD.ProgramID
			AND MHS.SurveyDate < = @QuarterDate
		
		LEFT JOIN DataWarehouse..Edinburgh_Survey ES
			ON ES.CL_EN_GEN_ID = EAD.CLID
			AND ES.ProgramID = EAD.ProgramID
			AND ES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_E
		--	ON MS_E.SurveyID = ES.SurveyID
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
			AND IBS.ProgramID = EAD.ProgramID
			AND IBS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			AND IHS.ProgramID = EAD.ProgramID
			AND IHS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..ASQ3_Survey ASQ
			ON ASQ.CL_EN_GEN_ID = EAD.CLID
			AND ASQ.ProgramID = EAD.ProgramID
			AND ASQ.SurveyDate < = @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
		--	ON MS_IHS.SurveyID = IHS.SurveyID
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
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_PHQ
		--	ON MS_PHQ.SurveyID = PHQ.SurveyID
		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID
			
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..UV_EDD EDD
			ON EDD.CaseNumber = EAD.CaseNumber

	WHERE CASE
			WHEN @ReportType = 1
			THEN '1'
			WHEN @ReportType = 2
			THEN DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
			WHEN @ReportType = 3
			THEN CAST(PAS.SiteID AS VARCHAR(50))
			WHEN @ReportType = 4
			THEN CAST(PAS.ProgramID AS VARCHAR(50))
		 END IN (CAST(@Site AS VARCHAR(50)))

	GROUP BY
		EAD.CaseNumber
		,PAS.ProgramName
		,PAS.ProgramID
		,PAS.Site
		,PAS.SiteID
		,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
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
		,EDD.EDD
		,DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID)
		,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
		,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL

)

SELECT
	F.CaseNumber
	,F.Site,F.ProgramName,F.State
	,F.[Active During Quarter] Active

	----------------------------------------
		,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NC_15E36
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NF_15E36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NFC_15E36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NN_15E36
	,ISNULL(CASE F.Birth
		WHEN 1
		THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15E36
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.Birth
		ELSE 0
	END,0) DC_15E36
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.Birth
		ELSE 0
	END,0) DF_15E36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.Birth
		ELSE 0
	END,0) DFC_15E36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.Birth
		ELSE 0
	END,0) DN_15E36
	,ISNULL( F.Birth,0) DT_15E36	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NC_15E14
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NF_15E14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NFC_15E14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NN_15E14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15E14
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DC_15E14
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DF_15E14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DFC_15E14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DN_15E14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15E14	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NC_15E46
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NF_15E46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NFC_15E46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NN_15E46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15E46
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DC_15E46
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DF_15E46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DFC_15E46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DN_15E46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15E46	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NC_15E12
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NF_15E12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NFC_15E12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NN_15E12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15E12
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DC_15E12
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DF_15E12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DFC_15E12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DN_15E12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15E12	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NC_15P36
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NF_15P36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NFC_15P36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NN_15P36
	,ISNULL(CASE F.[36 Weeks Preg Y/N]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15P36
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DC_15P36
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DF_15P36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DFC_15P36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DN_15P36
	,ISNULL( F.[36 Weeks Preg Y/N],0) DT_15P36	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NC_15P14
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NF_15P14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NFC_15P14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NN_15P14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15P14
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DC_15P14
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DF_15P14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DFC_15P14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DN_15P14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15P14	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NC_15P46
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NF_15P46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NFC_15P46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NN_15P46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15P46
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DC_15P46
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DF_15P46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DFC_15P46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DN_15P46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15P46	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NC_15P12
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NF_15P12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NFC_15P12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NN_15P12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15P12
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DC_15P12
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DF_15P12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DFC_15P12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DN_15P12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15P12	
----------------------------------------
,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NC_15EP36
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NF_15EP36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NFC_15EP36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NN_15EP36
	,ISNULL(CASE F.[36 Weeks Preg Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15EP36
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DC_15EP36
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DF_15EP36
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DFC_15EP36
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
		ELSE 0
	END,0) DN_15EP36
	,ISNULL( F.[36 Weeks Preg Y/N],0) DT_15EP36	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NC_15EP14
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NF_15EP14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NFC_15EP14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NN_15EP14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15EP14
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DC_15EP14
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DF_15EP14
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DFC_15EP14
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
		ELSE 0
	END,0) DN_15EP14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15EP14	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NC_15EP46
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NF_15EP46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NFC_15EP46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NN_15EP46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15EP46
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DC_15EP46
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DF_15EP46
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DFC_15EP46
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DN_15EP46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15EP46	
----------------------------------------
	,ISNULL(CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NC_15EP12
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NF_15EP12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NFC_15EP12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NN_15EP12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15EP12
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DC_15EP12
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DF_15EP12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DFC_15EP12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DN_15EP12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15EP12
----------------------------------------
	,ISNULL(CASE
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
				AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_15S10
	,ISNULL(CASE 
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
				AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_15S10
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  
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
				AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_15S10
	,ISNULL(CASE 
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
		AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_15S10
	,ISNULL(CASE 
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
			AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NT_15S10
	,ISNULL(CASE WHEN F.Competitive = 1
		THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DC_15S10
	,ISNULL(CASE WHEN F.Formula = 1
		THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DF_15S10
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DFC_15S10
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DN_15S10
	,ISNULL( F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos],0) DT_15S10	
------------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
		THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NC_31L
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
		THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NF_31L
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)) AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NFC_31L
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NN_31L
	,ISNULL(CASE
		WHEN F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 18 mos] - F.[Learning Materials Score - 6 mos] 
			ELSE 0
		END,0) NT_31L
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
		THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) DC_31L
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
		THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) DF_31L
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)) AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) DFC_31L
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) DN_31L
	,ISNULL(CASE
		WHEN F.[Learning Materials Score - 6 mos] IS NOT NULL AND F.[Learning Materials Score - 18 mos] IS NOT NULL
			THEN F.[Learning Materials Score - 6 mos] 
			ELSE 0
	 END,0) DT_31L
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NC_31L6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NF_31L6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NFC_31L6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Learning Materials Score - 6 mos]
		ELSE 0
	END,0) NN_31L6
	,ISNULL(F.[Learning Materials Score - 6 mos],0) NT_31L6
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Learning Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DC_31L6
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Learning Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DF_31L6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DFC_31L6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DN_31L6
	,ISNULL(CASE
		WHEN F.[Learning Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DT_31L6
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END,0) NC_31L18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END,0) NF_31L18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END,0) NFC_31L18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Learning Materials Score - 18 mos agg]
		ELSE 0
	END,0) NN_31L18
	,ISNULL(F.[Learning Materials Score - 18 mos agg],0) NT_31L18
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Learning Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DC_31L18
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Learning Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DF_31L18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DFC_31L18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DN_31L18
	,ISNULL(CASE
		WHEN F.[Learning Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DT_31L18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
		THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NC_31I
	,ISNULL(CASE 
		WHEN F.Formula = 1  AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
		THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NF_31I
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NFC_31I
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NN_31I
	,ISNULL(CASE
		WHEN F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 18 mos] - F.[Involvement Materials Score - 6 mos] 
			ELSE 0
		END,0) NT_31I
	,ISNULL(CASE 
		WHEN F.Competitive = 1  AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
		THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) DC_31I
	,ISNULL(CASE 
		WHEN F.Formula = 1  AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
		THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) DF_31I
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) DFC_31I
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) DN_31I
	,ISNULL(CASE
		WHEN F.[Involvement Materials Score - 6 mos] IS NOT NULL AND F.[Involvement Materials Score - 18 mos] IS NOT NULL
			THEN F.[Involvement Materials Score - 6 mos] 
			ELSE 0
	 END,0) DT_31I
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NC_31I6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NF_31I6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NFC_31I6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Involvement Materials Score - 6 mos]
		ELSE 0
	END,0) NN_31I6
	,ISNULL(F.[Involvement Materials Score - 6 mos],0) NT_31I6
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Involvement Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DC_31I6
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Involvement Materials Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DF_31I6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DFC_31I6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DN_31I6
	,ISNULL(CASE
		WHEN F.[Involvement Materials Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DT_31I6
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END,0) NC_31I18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END,0) NF_31I18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END,0) NFC_31I18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Involvement Materials Score - 18 mos agg]
		ELSE 0
	END,0) NN_31I18
	,ISNULL(F.[Involvement Materials Score - 18 mos agg],0) NT_31I18
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Involvement Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DC_31I18
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Involvement Materials Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DF_31I18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DFC_31I18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DN_31I18
	,ISNULL(CASE
		WHEN F.[Involvement Materials Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DT_31I18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
		THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END,0) NC_32
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
		THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END,0) NF_32
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END,0) NFC_32
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos]
		ELSE 0
	END,0) NN_32
	,ISNULL(CASE
		WHEN F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 18 mos] - F.[Total Score - 6 mos] 
			ELSE 0
		END,0) NT_32
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
		THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) DC_32
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
		THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) DF_32
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) DFC_32
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) DN_32
	,ISNULL(CASE
		WHEN F.[Total Score - 6 mos] IS NOT NULL AND F.[Total Score - 18 mos] IS NOT NULL
			THEN F.[Total Score - 6 mos] 
			ELSE 0
	 END,0) DT_32
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) NC_326
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) NF_326
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) NFC_326
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Total Score - 6 mos]
		ELSE 0
	END,0) NN_326
	,ISNULL(F.[Total Score - 6 mos] ,0) NT_326
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Total Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DC_326
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Total Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DF_326
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DFC_326
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DN_326
	,ISNULL(CASE
		WHEN F.[Total Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DT_326
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END,0) NC_3218
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END,0) NF_3218
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END,0) NFC_3218
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Total Score - 18 mos agg]
		ELSE 0
	END,0) NN_3218
	,ISNULL(F.[Total Score - 18 mos agg] ,0) NT_3218
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Total Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DC_3218
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Total Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DF_3218
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DFC_3218
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DN_3218
	,ISNULL(CASE
		WHEN F.[Total Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DT_3218
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
		THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NC_33R
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
		THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NF_33R
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NFC_33R
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NN_33R
	,ISNULL(CASE
		WHEN F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 18 mos] - F.[Responsivity Score - 6 mos] 
			ELSE 0
		END,0) NT_33R
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
		THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) DC_33R
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
		THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) DF_33R
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) DFC_33R
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) DN_33R
	,ISNULL(CASE
		WHEN F.[Responsivity Score - 6 mos] IS NOT NULL AND F.[Responsivity Score - 18 mos] IS NOT NULL
			THEN F.[Responsivity Score - 6 mos] 
			ELSE 0
	 END,0) DT_33R
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NC_33R6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NF_33R6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NFC_33R6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Responsivity Score - 6 mos]
		ELSE 0
	END,0) NN_33R6
	,ISNULL(F.[Responsivity Score - 6 mos],0) NT_33R6
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Responsivity Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DC_33R6
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Responsivity Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DF_33R6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DFC_33R6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DN_33R6
	,ISNULL(CASE
		WHEN F.[Responsivity Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DT_33R6
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END,0) NC_33R18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END,0) NF_33R18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END,0) NFC_33R18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Responsivity Score - 18 mos agg]
		ELSE 0
	END,0) NN_33R18
	,ISNULL(F.[Responsivity Score - 18 mos agg] ,0) NT_33R18
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Responsivity Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DC_33R18
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Responsivity Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DF_33R18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DFC_33R18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DN_33R18
	,ISNULL(CASE
		WHEN F.[Responsivity Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DT_33R18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
		THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NC_33A
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
		THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NF_33A
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NFC_33A
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NN_33A
	,ISNULL(CASE
		WHEN F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 18 mos] - F.[Acceptance Score - 6 mos] 
			ELSE 0
		END,0) NT_33A
	,ISNULL(CASE 
		WHEN F.Competitive =1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
		THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) DC_33A
	,ISNULL(CASE 
		WHEN F.Formula =1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
		THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) DF_33A
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) DFC_33A
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) DN_33A
	,ISNULL(CASE
		WHEN F.[Acceptance Score - 6 mos] IS NOT NULL AND F.[Acceptance Score - 18 mos] IS NOT NULL
			THEN F.[Acceptance Score - 6 mos] 
			ELSE 0
	 END,0) DT_33A
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NC_33A6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NF_33A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NFC_33A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Acceptance Score - 6 mos]
		ELSE 0
	END,0) NN_33A6
	,ISNULL(F.[Acceptance Score - 6 mos],0) NT_33A6
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Acceptance Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DC_33A6
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Acceptance Score - 6 mos] > 0 THEN 1
		ELSE 0
	END,0) DF_33A6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DFC_33A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DN_33A6
	,ISNULL(CASE
		WHEN F.[Acceptance Score - 6 mos] > 0
		THEN 1
		ELSE 0
	END,0) DT_33A6
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END,0) NC_33A18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END,0) NF_33A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END,0) NFC_33A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Acceptance Score - 18 mos agg]
		ELSE 0
	END,0) NN_33A18
	,ISNULL(F.[Acceptance Score - 18 mos agg],0) NT_33A18
	,ISNULL(CASE
		WHEN F.Competitive = 1  AND F.[Acceptance Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DC_33A18
	,ISNULL(CASE
		WHEN F.Formula = 1  AND F.[Acceptance Score - 18 mos agg] > 0 THEN 1
		ELSE 0
	END,0) DF_33A18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DFC_33A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DN_33A18
	,ISNULL(CASE
		WHEN F.[Acceptance Score - 18 mos agg] > 0
		THEN 1
		ELSE 0
	END,0) DT_33A18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Communication Screening 4 mos]
		ELSE 0
	END,0) NC_356
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Communication Screening 4 mos]
		ELSE 0
	END,0) NF_356
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Communication Screening 4 Mos]
		ELSE 0
	END,0) NFC_356
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Communication Screening 4 Mos]
		ELSE 0
	END,0) NN_356
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Communication Screening 4 mos] END,0) NT_356
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_356
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_356
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_356
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_356
	,ISNULL(F.[ASQ3 4 Mos],0) DT_356	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Communication Screening 10 mos]
		ELSE 0
	END,0) NC_3512
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Communication Screening 10 mos]
		ELSE 0
	END,0) NF_3512
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Communication Screening 10 mos]
		ELSE 0
	END,0) NFC_3512
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Communication Screening 10 mos]
		ELSE 0
	END,0) NN_3512
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Communication Screening 10 mos] END,0) NT_3512
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_3512
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_3512
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_3512
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_3512
	,ISNULL(F.[ASQ3 10 Mos],0) DT_3512	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Communication Screening 14 mos]
		ELSE 0
	END,0) NC_3518
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Communication Screening 14 mos]
		ELSE 0
	END,0) NF_3518
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Communication Screening 14 mos]
		ELSE 0
	END,0) NFC_3518
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Communication Screening 14 mos]
		ELSE 0
	END,0) NN_3518
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Communication Screening 14 mos] END,0) NT_3518
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_3518
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_3518
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_3518
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_3518
	,ISNULL(F.[ASQ3 14 Mos],0) DT_3518	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Communication Screening 20 mos]
		ELSE 0
	END,0) NC_3524
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Communication Screening 20 mos]
		ELSE 0
	END,0) NF_3524
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Communication Screening 20 mos]
		ELSE 0
	END,0) NFC_3524
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Communication Screening 20 mos]
		ELSE 0
	END,0) NN_3524
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Communication Screening 20 mos] END,0) NT_3524
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_3524
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_3524
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_3524
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_3524
	,ISNULL(F.[ASQ3 20 Mos],0) DT_3524	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Communication Score 4 Mos - Agg]
		ELSE 0
	END,0) NC_35A6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Communication Score 4 Mos - Agg]
		ELSE 0
	END,0) NF_35A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Communication Score 4 Mos - Agg]
		ELSE 0
	END,0) NFC_35A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Communication Score 4 Mos - Agg]
		ELSE 0
	END,0) NN_35A6
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Communication Score 4 Mos - Agg] END,0) NT_35A6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_35A6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_35A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_35A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_35A6
	,ISNULL(F.[ASQ3 4 Mos],0) DT_35A6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Communication Score 10 Mos - Agg]
		ELSE 0
	END,0) NC_35A12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Communication Score 10 Mos - Agg]
		ELSE 0
	END,0) NF_35A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Communication Score 10 Mos - Agg]
		ELSE 0
	END,0) NFC_35A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Communication Score 10 Mos - Agg]
		ELSE 0
	END,0) NN_35A12
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Communication Score 10 Mos - Agg] END,0) NT_35A12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_35A12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_35A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_35A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_35A12
	,ISNULL(F.[ASQ3 10 Mos],0) DT_35A12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Communication Score 14 Mos - Agg]
		ELSE 0
	END,0) NC_35A18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Communication Score 14 Mos - Agg]
		ELSE 0
	END,0) NF_35A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Communication Score 14 Mos - Agg]
		ELSE 0
	END,0) NFC_35A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Communication Score 14 Mos - Agg]
		ELSE 0
	END,0) NN_35A18
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Communication Score 14 Mos - Agg] END,0) NT_35A18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_35A18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_35A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_35A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_35A18
	,ISNULL(F.[ASQ3 14 Mos],0) DT_35A18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Communication Score 20 Mos - Agg]
		ELSE 0
	END,0) NC_35A24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Communication Score 20 Mos - Agg]
		ELSE 0
	END,0) NF_35A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Communication Score 20 Mos - Agg]
		ELSE 0
	END,0) NFC_35A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Communication Score 20 Mos - Agg]
		ELSE 0
	END,0) NN_35A24
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Communication Score 20 Mos - Agg] END,0) NT_35A24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_35A24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_35A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_35A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_35A24
	,ISNULL(F.[ASQ3 20 Mos],0) DT_35A24	
	
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] BETWEEN 0 AND 34.59
					OR F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					OR F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					OR F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
				) 
		THEN 1
		ELSE 0
	END,0) NC_35CO6
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] BETWEEN 0 AND 34.59
					OR F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					OR F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					OR F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
				)
		THEN 1
		ELSE 0
	END,0) NF_35CO6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
				AND (
					F.[ASQ Communication Score 4 Mos - Agg] BETWEEN 0 AND 34.59
					OR F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					OR F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					OR F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
				)
		THEN 1
		ELSE 0
	END,0) NFC_35CO6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] BETWEEN 0 AND 34.59
					OR F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					OR F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					OR F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
				)
		THEN 1
		ELSE 0
	END,0) NN_35CO6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Communication Score 4 Mos - Agg] BETWEEN 0 AND 34.59
					OR F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					OR F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					OR F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
				)
		THEN 1
	END,0) NT_35CO6
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DC_35CO6
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DF_35CO6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) 
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DFC_35CO6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Communication Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DN_35CO6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Communication Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1 
		ELSE 0
	END,0) DT_35CO6
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_35CO12
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_35CO12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
					AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_35CO12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_35CO12
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 10 Mos - Agg] BETWEEN 0 AND  22.87
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
	END,0) NT_35CO12
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_35CO12
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_35CO12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_35CO12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_35CO12
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos] 
		ELSE 0
	END,0) DT_35CO12

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_35CO18
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_35CO18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
					AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_35CO18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_35CO18
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 14 Mos - Agg] BETWEEN 0 AND  17.39
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
	END,0) NT_35CO18
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_35CO18
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_35CO18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_35CO18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_35CO18
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos] 
		ELSE 0
	END,0) DT_35CO18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_35CO24
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_35CO24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
					AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_35CO24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_35CO24
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 20 Mos - Agg] BETWEEN 0 AND  20.49
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
	END,0) NT_35CO24
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_35CO24
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_35CO24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_35CO24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_35CO24
	,ISNULL(CASE
		WHEN F.[ASQ Communication Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos] 
		ELSE 0
	END,0) DT_35CO24

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] BETWEEN 0 AND  34.97
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] BETWEEN 0 AND  32.51
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] BETWEEN 0 AND  22.55
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] BETWEEN 0 AND  28.83
				) 
		THEN 1
		ELSE 0
	END,0) NC_36PS6
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] BETWEEN 0 AND  34.97
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] BETWEEN 0 AND  32.51
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] BETWEEN 0 AND  22.55
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] BETWEEN 0 AND  28.83
				)
		THEN 1
		ELSE 0
	END,0) NF_36PS6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
				AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] BETWEEN 0 AND  34.97
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] BETWEEN 0 AND  32.51
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] BETWEEN 0 AND  22.55
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] BETWEEN 0 AND  28.83
				)
		THEN 1
		ELSE 0
	END,0) NFC_36PS6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] BETWEEN 0 AND  34.97
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] BETWEEN 0 AND  32.51
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] BETWEEN 0 AND  22.55
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] BETWEEN 0 AND  28.83
				)
		THEN 1
		ELSE 0
	END,0) NN_36PS6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Problem Solving Score 4 Mos - Agg] BETWEEN 0 AND  34.97
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] BETWEEN 0 AND  32.51
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] BETWEEN 0 AND  22.55
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] BETWEEN 0 AND  28.83
				)
		THEN 1
	END,0) NT_36PS6
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DC_36PS6
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DF_36PS6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) 
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DFC_36PS6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Problem Solving Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DN_36PS6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Problem Solving Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1 
		ELSE 0
	END,0) DT_36PS6
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_36PS12
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_36PS12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Problem Solving Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_36PS12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_36PS12
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 10 Mos - Agg] <	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
	END,0) NT_36PS12
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_36PS12
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_36PS12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_36PS12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_36PS12
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos] 
		ELSE 0
	END,0) DT_36PS12

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_36PS18
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_36PS18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Problem Solving Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_36PS18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_36PS18
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 14 Mos - Agg] <	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
	END,0) NT_36PS18
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_36PS18
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_36PS18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) 
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_36PS18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_36PS18
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos] 
		ELSE 0
	END,0) DT_36PS18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_36PS24
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_36PS24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Problem Solving Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_36PS24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Problem Solving'
															)
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_36PS24
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 20 Mos - Agg] <	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Problem Solving'
														)
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
	END,0) NT_36PS24
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_36PS24
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_36PS24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_36PS24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_36PS24
	,ISNULL(CASE
		WHEN F.[ASQ Problem Solving Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos] 
		ELSE 0
	END,0) DT_36PS24
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] BETWEEN 0 AND  33.15
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] BETWEEN 0 AND  27.25
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] BETWEEN 0 AND  23.17
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] BETWEEN 0 AND  33.35
				) 
		THEN 1
		ELSE 0
	END,0) NC_37PrsS6
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] BETWEEN 0 AND  33.15
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] BETWEEN 0 AND  27.25
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] BETWEEN 0 AND  23.17
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] BETWEEN 0 AND  33.35
				)
		THEN 1
		ELSE 0
	END,0) NF_37PrsS6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
				AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] BETWEEN 0 AND  33.15
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] BETWEEN 0 AND  27.25
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] BETWEEN 0 AND  23.17
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] BETWEEN 0 AND  33.35
				)
		THEN 1
		ELSE 0
	END,0) NFC_37PrsS6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] BETWEEN 0 AND  33.15
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] BETWEEN 0 AND  27.25
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] BETWEEN 0 AND  23.17
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] BETWEEN 0 AND  33.35
				)
		THEN 1
		ELSE 0
	END,0) NN_37PrsS6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Personal-Social Score 4 Mos - Agg] BETWEEN 0 AND  33.15
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] BETWEEN 0 AND  27.25
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] BETWEEN 0 AND  23.17
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] BETWEEN 0 AND  33.35
				)
		THEN 1
	END,0) NT_37PrsS6
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DC_37PrsS6
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DF_37PrsS6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) 
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DFC_37PrsS6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ Personal-Social Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DN_37PrsS6
	,ISNULL(CASE
		WHEN (
					F.[ASQ Personal-Social Score 4 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
					OR F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
				)
		THEN 1 
		ELSE 0
	END,0) DT_37PrsS6
	
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_37PrsS12
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_37PrsS12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Personal-Social Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_37PrsS12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] <	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_37PrsS12
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 10 Mos - Agg] <	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 10 Mos] > 0
		THEN 1
	END,0) NT_37PrsS12
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_37PrsS12
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_37PrsS12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_37PrsS12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1
			AND F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_37PrsS12
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 10 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 10 Mos] 
		ELSE 0
	END,0) DT_37PrsS12

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_37PrsS18
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_37PrsS18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Personal-Social Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_37PrsS18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] <	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_37PrsS18
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 14 Mos - Agg] <	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 14 Mos] > 0
		THEN 1
	END,0) NT_37PrsS18
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_37PrsS18
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_37PrsS18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_37PrsS18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_37PrsS18
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 14 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 14 Mos] 
		ELSE 0
	END,0) DT_37PrsS18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NC_37PrsS24
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NF_37PrsS24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ Personal-Social Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NFC_37PrsS24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] <	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'Personal-Social'
															)
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
		ELSE 0
	END,0) NN_37PrsS24
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 20 Mos - Agg] <	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'Personal-Social'
														)
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
			AND F.[ASQ3 20 Mos] > 0
		THEN 1
	END,0) NT_37PrsS24
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_37PrsS24
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_37PrsS24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_37PrsS24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_37PrsS24
	,ISNULL(CASE
		WHEN F.[ASQ Personal-Social Score 20 Mos - Agg] IS NOT NULL
		THEN F.[ASQ3 20 Mos] 
		ELSE 0
	END,0) DT_37PrsS24
----------------------------------------
		,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 45
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 48
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 50
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 50
				) 
		THEN 1
		ELSE 0
	END,0) NC_38SE6
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 45
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 48
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 50
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 50
				)
		THEN 1
		ELSE 0
	END,0) NF_38SE6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
				AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 45
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 48
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 50
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 50
				)
		THEN 1
		ELSE 0
	END,0) NFC_38SE6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 45
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 48
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 50
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 50
				)
		THEN 1
		ELSE 0
	END,0) NN_38SE6
	,ISNULL(CASE
		WHEN (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] > = 45
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 48
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 50
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 50
				)
		THEN 1
	END,0) NT_38SE6
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DC_38SE6
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DF_38SE6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) 
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DFC_38SE6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] IS NOT NULL
				)
		THEN 1
		ELSE 0
	END,0) DN_38SE6
	,ISNULL(CASE
		WHEN (
					F.[ASQ ASQ-SE Score 6 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 12 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 18 Mos - Agg] IS NOT NULL
					OR F.[ASQ ASQ-SE Score 24 Mos - Agg] IS NOT NULL
				)
		THEN 1 
		ELSE 0
	END,0) DT_38SE6

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
			AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NC_38SE12
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
			AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NF_38SE12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
			AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NFC_38SE12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
																SELECT AC.[12_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
			AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NN_38SE12
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 12 Mos - Agg] >=	(
															SELECT AC.[12_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
			AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN 1
	END,0) NT_38SE12
	,ISNULL(CASE
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DC_38SE12
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DF_38SE12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DFC_38SE12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DN_38SE12
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 12 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 12 Mos Agg] 
	END,0) DT_38SE12

----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
			AND F.[Infant Health Survey 18 Mos Agg]  > 0
		THEN 1
		ELSE 0
	END,0) NC_38SE18
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
			AND F.[Infant Health Survey 18 Mos Agg]  > 0
		THEN 1
		ELSE 0
	END,0) NF_38SE18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
			AND F.[Infant Health Survey 18 Mos Agg]  > 0
		THEN 1
		ELSE 0
	END,0) NFC_38SE18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
																SELECT AC.[18_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
			AND F.[Infant Health Survey 18 Mos Agg]  > 0
		THEN 1
		ELSE 0
	END,0) NN_38SE18
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 18 Mos - Agg] >=	(
															SELECT AC.[18_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
			AND F.[Infant Health Survey 18 Mos Agg]  > 0
		THEN 1
	END,0) NT_38SE18
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DC_38SE18
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DF_38SE18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DFC_38SE18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DN_38SE18
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 18 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END,0) DT_38SE18
----------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
			AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NC_38SE24
	,ISNULL(CASE 
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
			AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NF_38SE24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
					AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
			AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NFC_38SE24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
																SELECT AC.[24_Month]
																FROM DataWarehouse..UC_ASQ_Cutoff AC
																WHERE AC.ASQ_Category = 'ASQ-SE'
															)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
			AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN 1
		ELSE 0
	END,0) NN_38SE24
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 24 Mos - Agg] >=	(
															SELECT AC.[24_Month]
															FROM DataWarehouse..UC_ASQ_Cutoff AC
															WHERE AC.ASQ_Category = 'ASQ-SE'
														)
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
			AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN 1
	END,0) NT_38SE24
	,ISNULL(CASE 
		WHEN F.Competitive = 1  
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DC_38SE24
	,ISNULL(CASE
		WHEN F.Formula = 1  
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DF_38SE24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  )
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DFC_38SE24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 
			AND F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DN_38SE24
	,ISNULL(CASE
		WHEN F.[ASQ ASQ-SE Score 24 Mos - Agg] > = 0
		THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END,0) DT_38SE24
----------------------------------------

	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 4 mos]
		ELSE 0
	END,0) NC_366
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 4 mos]
		ELSE 0
	END,0) NF_366
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Problem Solving Screening 4 mos]
		ELSE 0
	END,0) NFC_366
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Problem Solving Screening 4 mos]
		ELSE 0
	END,0) NN_366
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Problem Solving Screening 4 mos] END,0) NT_366
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_366
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_366
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_366
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_366
	,ISNULL(F.[Infant Health Survey 6 Mos],0) DT_366	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 10 mos]
		ELSE 0
	END,0) NC_3612
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 10 mos]
		ELSE 0
	END,0) NF_3612
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Problem Solving Screening 10 mos]
		ELSE 0
	END,0) NFC_3612
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Problem Solving Screening 10 mos]
		ELSE 0
	END,0) NN_3612
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Problem Solving Screening 10 mos] END,0) NT_3612
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_3612
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_3612
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_3612
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_3612
	,ISNULL(F.[ASQ3 10 Mos],0) DT_3612	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 14 mos]
		ELSE 0
	END,0) NC_3618
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 14 mos]
		ELSE 0
	END,0) NF_3618
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Problem Solving Screening 14 mos]
		ELSE 0
	END,0) NFC_3618
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Problem Solving Screening 14 mos]
		ELSE 0
	END,0) NN_3618
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Problem Solving Screening 14 mos] END,0) NT_3618
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_3618
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_3618
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_3618
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_3618
	,ISNULL(F.[ASQ3 14 Mos],0) DT_3618	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 20 mos]
		ELSE 0
	END,0) NC_3624
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Problem Solving Screening 20 mos]
		ELSE 0
	END,0) NF_3624
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Problem Solving Screening 20 mos]
		ELSE 0
	END,0) NFC_3624
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Problem Solving Screening 20 mos]
		ELSE 0
	END,0) NN_3624
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Problem Solving Screening 20 mos] END,0) NT_3624
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_3624
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_3624
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_3624
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_3624
	,ISNULL(F.[ASQ3 20 Mos],0) DT_3624	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Problem Solving Score 4 Mos - Agg]
		ELSE 0
	END,0) NC_36A6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Problem Solving Score 4 Mos - Agg]
		ELSE 0
	END,0) NF_36A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Problem Solving Score 4 Mos - Agg]
		ELSE 0
	END,0) NFC_36A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Problem Solving Score 4 Mos - Agg]
		ELSE 0
	END,0) NN_36A6
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Problem Solving Score 4 Mos - Agg] END,0) NT_36A6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_36A6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_36A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_36A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_36A6
	,ISNULL(F.[ASQ3 4 Mos],0) DT_36A6	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Problem Solving Score 10 Mos - Agg]
		ELSE 0
	END,0) NC_36A12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Problem Solving Score 10 Mos - Agg]
		ELSE 0
	END,0) NF_36A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Problem Solving Score 10 Mos - Agg]
		ELSE 0
	END,0) NFC_36A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Problem Solving Score 10 Mos - Agg]
		ELSE 0
	END,0) NN_36A12
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Problem Solving Score 10 Mos - Agg] END,0) NT_36A12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_36A12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_36A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_36A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_36A12
	,ISNULL(F.[ASQ3 10 Mos],0) DT_36A12	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Problem Solving Score 14 Mos - Agg]
		ELSE 0
	END,0) NC_36A18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Problem Solving Score 14 Mos - Agg]
		ELSE 0
	END,0) NF_36A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Problem Solving Score 14 Mos - Agg]
		ELSE 0
	END,0) NFC_36A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Problem Solving Score 14 Mos - Agg]
		ELSE 0
	END,0) NN_36A18
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Problem Solving Score 14 Mos - Agg] END,0) NT_36A18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_36A18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_36A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_36A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_36A18
	,ISNULL(F.[ASQ3 14 Mos],0) DT_36A18	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Problem Solving Score 20 Mos - Agg]
		ELSE 0
	END,0) NC_36A24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Problem Solving Score 20 Mos - Agg]
		ELSE 0
	END,0) NF_36A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Problem Solving Score 20 Mos - Agg]
		ELSE 0
	END,0) NFC_36A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Problem Solving Score 20 Mos - Agg]
		ELSE 0
	END,0) NN_36A24
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Problem Solving Score 20 Mos - Agg] END,0) NT_36A24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_36A24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_36A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_36A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_36A24
	,ISNULL(F.[ASQ3 20 Mos],0) DT_36A24	

----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 4 mos]
		ELSE 0
	END,0) NC_376
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 4 mos]
		ELSE 0
	END,0) NF_376
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Personal-Social Screening 4 mos]
		ELSE 0
	END,0) NFC_376
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Personal-Social Screening 4 mos]
		ELSE 0
	END,0) NN_376
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Personal-Social Screening 4 mos] END,0) NT_376
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_376
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_376
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_376
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_376
	,ISNULL(F.[ASQ3 4 Mos],0) DT_376	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 10 mos]
		ELSE 0
	END,0) NC_3712
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 10 mos]
		ELSE 0
	END,0) NF_3712
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Personal-Social Screening 10 mos]
		ELSE 0
	END,0) NFC_3712
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Personal-Social Screening 10 mos]
		ELSE 0
	END,0) NN_3712
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Personal-Social Screening 10 mos] END,0) NT_3712
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_3712
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_3712
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_3712
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_3712
	,ISNULL(F.[ASQ3 10 Mos],0) DT_3712	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 14 mos]
		ELSE 0
	END,0) NC_3718
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 14 mos]
		ELSE 0
	END,0) NF_3718
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Personal-Social Screening 14 mos]
		ELSE 0
	END,0) NFC_3718
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Personal-Social Screening 14 mos]
		ELSE 0
	END,0) NN_3718
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Personal-Social Screening 14 mos] END,0) NT_3718
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_3718
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_3718
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_3718
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_3718
	,ISNULL(F.[ASQ3 14 Mos],0) DT_3718	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 20 mos]
		ELSE 0
	END,0) NC_3724
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Personal-Social Screening 20 mos]
		ELSE 0
	END,0) NF_3724
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Personal-Social Screening 20 mos]
		ELSE 0
	END,0) NFC_3724
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Personal-Social Screening 20 mos]
		ELSE 0
	END,0) NN_3724
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Personal-Social Screening 20 mos] END,0) NT_3724
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_3724
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_3724
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_3724
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_3724
	,ISNULL(F.[ASQ3 20 Mos],0) DT_3724	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Personal-Social Score 4 Mos - Agg]
		ELSE 0
	END,0) NC_37A6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 4 Mos] > 0
		THEN F.[ASQ Personal-Social Score 4 Mos - Agg]
		ELSE 0
	END,0) NF_37A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 4 Mos] > 0  THEN F.[ASQ Personal-Social Score 4 Mos - Agg]
		ELSE 0
	END,0) NFC_37A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Personal-Social Score 4 Mos - Agg]
		ELSE 0
	END,0) NN_37A6
	,ISNULL(CASE WHEN F.[ASQ3 4 Mos] > 0 THEN F.[ASQ Personal-Social Score 4 Mos - Agg] END,0) NT_37A6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DC_37A6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DF_37A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DFC_37A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 4 Mos]
		ELSE 0
	END,0) DN_37A6
	,ISNULL(F.[ASQ3 4 Mos],0) DT_37A6	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Personal-Social Score 10 Mos - Agg]
		ELSE 0
	END,0) NC_37A12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 10 Mos] > 0
		THEN F.[ASQ Personal-Social Score 10 Mos - Agg]
		ELSE 0
	END,0) NF_37A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 10 Mos] > 0  THEN F.[ASQ Personal-Social Score 10 Mos - Agg]
		ELSE 0
	END,0) NFC_37A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Personal-Social Score 10 Mos - Agg]
		ELSE 0
	END,0) NN_37A12
	,ISNULL(CASE WHEN F.[ASQ3 10 Mos] > 0 THEN F.[ASQ Personal-Social Score 10 Mos - Agg] END,0) NT_37A12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DC_37A12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DF_37A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DFC_37A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 10 Mos]
		ELSE 0
	END,0) DN_37A12
	,ISNULL(F.[ASQ3 10 Mos],0) DT_37A12	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Personal-Social Score 14 Mos - Agg]
		ELSE 0
	END,0) NC_37A18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 14 Mos] > 0
		THEN F.[ASQ Personal-Social Score 14 Mos - Agg]
		ELSE 0
	END,0) NF_37A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 14 Mos] > 0  THEN F.[ASQ Personal-Social Score 14 Mos - Agg]
		ELSE 0
	END,0) NFC_37A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Personal-Social Score 14 Mos - Agg]
		ELSE 0
	END,0) NN_37A18
	,ISNULL(CASE WHEN F.[ASQ3 14 Mos] > 0 THEN F.[ASQ Personal-Social Score 14 Mos - Agg] END,0) NT_37A18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DC_37A18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DF_37A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DFC_37A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 14 Mos]
		ELSE 0
	END,0) DN_37A18
	,ISNULL(F.[ASQ3 14 Mos],0) DT_37A18	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Personal-Social Score 20 Mos - Agg]
		ELSE 0
	END,0) NC_37A24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[ASQ3 20 Mos] > 0
		THEN F.[ASQ Personal-Social Score 20 Mos - Agg]
		ELSE 0
	END,0) NF_37A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[ASQ3 20 Mos] > 0  THEN F.[ASQ Personal-Social Score 20 Mos - Agg]
		ELSE 0
	END,0) NFC_37A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Personal-Social Score 20 Mos - Agg]
		ELSE 0
	END,0) NN_37A24
	,ISNULL(CASE WHEN F.[ASQ3 20 Mos] > 0 THEN F.[ASQ Personal-Social Score 20 Mos - Agg] END,0) NT_37A24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DC_37A24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DF_37A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DFC_37A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[ASQ3 20 Mos]
		ELSE 0
	END,0) DN_37A24
	,ISNULL(F.[ASQ3 20 Mos],0) DT_37A24	

----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END,0) NC_386
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END,0) NF_386
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] > 0  THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END,0) NFC_386
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 6 mos]
		ELSE 0
	END,0) NN_386
	,ISNULL(CASE WHEN F.[Infant Health Survey 6 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 6 mos] END,0) NT_386
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DC_386
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DF_386
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DFC_386
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END,0) DN_386
	,ISNULL(F.[Infant Health Survey 6 Mos],0) DT_386
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END,0) NC_3812
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END,0) NF_3812
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] > 0  THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END,0) NFC_3812
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 12 mos]
		ELSE 0
	END,0) NN_3812
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 12 mos] END,0) NT_3812
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DC_3812
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DF_3812
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DFC_3812
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DN_3812
	,ISNULL(F.[Infant Health Survey 12 Mos],0) DT_3812
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END,0) NC_3818
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END,0) NF_3818
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos] > 0  THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END,0) NFC_3818
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 18 mos]
		ELSE 0
	END,0) NN_3818
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 18 mos] END,0) NT_3818
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DC_3818
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DF_3818
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DFC_3818
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DN_3818
	,ISNULL(F.[Infant Health Survey 18 Mos],0) DT_3818
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END,0) NC_3824
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos] > 0
		THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END,0) NF_3824
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos] > 0  THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END,0) NFC_3824
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 24 mos]
		ELSE 0
	END,0) NN_3824
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos] > 0 THEN F.[ASQ ASQ-SE Screening 24 mos] END,0) NT_3824
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DC_3824
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DF_3824
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DFC_3824
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DN_3824
	,ISNULL(F.[Infant Health Survey 24 Mos],0) DT_3824	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END,0) NC_38A6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END,0) NF_38A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos Agg] > 0  THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END,0) NFC_38A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg]
		ELSE 0
	END,0) NN_38A6
	,ISNULL(CASE WHEN F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 6 Mos - Agg] END,0) NT_38A6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DC_38A6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DF_38A6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DFC_38A6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DN_38A6
	,ISNULL(F.[Infant Health Survey 6 Mos Agg],0) DT_38A6	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END,0) NC_38A12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END,0) NF_38A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos Agg] > 0  THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END,0) NFC_38A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg]
		ELSE 0
	END,0) NN_38A12
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 12 Mos - Agg] END,0) NT_38A12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DC_38A12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DF_38A12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DFC_38A12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DN_38A12
	,ISNULL(F.[Infant Health Survey 12 Mos Agg],0) DT_38A12	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END,0) NC_38A18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END,0) NF_38A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos Agg] > 0  THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END,0) NFC_38A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg]
		ELSE 0
	END,0) NN_38A18
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 18 Mos - Agg] END,0) NT_38A18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DC_38A18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DF_38A18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DFC_38A18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DN_38A18
	,ISNULL(F.[Infant Health Survey 18 Mos Agg],0) DT_38A18	
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END,0) NC_38A24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END,0) NF_38A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos Agg] > 0  THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END,0) NFC_38A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg]
		ELSE 0
	END,0) NN_38A24
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ ASQ-SE Score 24 Mos - Agg] END,0) NT_38A24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DC_38A24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DF_38A24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DFC_38A24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DN_38A24
	,ISNULL(F.[Infant Health Survey 24 Mos Agg],0) DT_38A24	
----------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Infant Health Survey Agg] > 0 
		THEN [ASQ Weight/Height/Head Measured Screening Agg]
		ELSE 0
	END,0) NC_39S6
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey Agg] > 0
		THEN [ASQ Weight/Height/Head Measured Screening Agg]
		ELSE 0
	END,0) NF_39S6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey Agg] > 0 )
			
		THEN [ASQ Weight/Height/Head Measured Screening Agg]
		ELSE 0
	END,0) NFC_39S6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey Agg] > 0
		THEN [ASQ Weight/Height/Head Measured Screening Agg]
		ELSE 0
	END,0) NN_39S6
	,ISNULL(CASE WHEN F.[Infant Health Survey Agg] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening Agg] END,0) NT_39S6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey Agg]
		ELSE 0
	END,0) DC_39S6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey Agg]
		ELSE 0
	END,0) DF_39S6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey Agg]
		ELSE 0
	END,0) DFC_39S6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey Agg]
		ELSE 0
	END,0) DN_39S6
	,ISNULL(F.[Infant Health Survey Agg],0) DT_39S6
----------------------------------------
,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END,0) NC_39S12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END,0) NF_39S12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] > 0  THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END,0) NFC_39S12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos]
		ELSE 0
	END,0) NN_39S12
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 12 Mos] END,0) NT_39S12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DC_39S12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DF_39S12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DFC_39S12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END,0) DN_39S12
	,ISNULL(F.[Infant Health Survey 12 Mos],0) DT_39S12
----------------------------------------
,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END,0) NC_39S18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END,0) NF_39S18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos] > 0  THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END,0) NFC_39S18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos]
		ELSE 0
	END,0) NN_39S18
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 18 Mos] END,0) NT_39S18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DC_39S18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DF_39S18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DFC_39S18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos]
		ELSE 0
	END,0) DN_39S18
	,ISNULL(F.[Infant Health Survey 18 Mos],0) DT_39S18
----------------------------------------
,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END,0) NC_39S24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos] > 0
		THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END,0) NF_39S24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos] > 0  THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END,0) NFC_39S24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos]
		ELSE 0
	END,0) NN_39S24
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos] > 0 THEN F.[ASQ Weight/Height/Head Measured Screening 24 Mos] END,0) NT_39S24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DC_39S24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DF_39S24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)   THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DFC_39S24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos]
		ELSE 0
	END,0) DN_39S24
	,ISNULL(F.[Infant Health Survey 24 Mos],0) DT_39S24
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NC_39H6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NF_39H6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos Agg] > 0  THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NFC_39H6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NN_39H6
	,ISNULL(CASE WHEN F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 6 Mos Agg] END,0) NT_39H6
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END,0) DC_39H6
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DF_39H6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DFC_39H6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DN_39H6
	,ISNULL(F.[Infant Health Survey 6 Mos Agg],0) DT_39H6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NC_39H12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NF_39H12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos Agg] > 0  THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NFC_39H12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NN_39H12
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 12 Mos Agg] END,0) NT_39H12
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END,0) DC_39H12
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DF_39H12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DFC_39H12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DN_39H12
	,ISNULL(F.[Infant Health Survey 12 Mos Agg],0) DT_39H12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NC_39H18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NF_39H18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos Agg] > 0  THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NFC_39H18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NN_39H18
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 18 Mos Agg] END,0) NT_39H18
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END,0) DC_39H18
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DF_39H18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DFC_39H18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DN_39H18
	,ISNULL(F.[Infant Health Survey 18 Mos Agg],0) DT_39H18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NC_39H24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NF_39H24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos Agg] > 0  THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NFC_39H24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NN_39H24
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Height Measured Screening 24 Mos Agg] END,0) NT_39H24
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END,0) DC_39H24
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DF_39H24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DFC_39H24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DN_39H24
	,ISNULL(F.[Infant Health Survey 24 Mos Agg],0) DT_39H24

----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NC_39W6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NF_39W6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos Agg] > 0  THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NFC_39W6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NN_39W6
	,ISNULL(CASE WHEN F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 6 Mos Agg] END,0) NT_39W6
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END,0) DC_39W6
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DF_39W6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DFC_39W6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DN_39W6
	,ISNULL(F.[Infant Health Survey 6 Mos Agg],0) DT_39W6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NC_39W12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NF_39W12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos Agg] > 0  THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NFC_39W12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NN_39W12
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 12 Mos Agg] END,0) NT_39W12
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END,0) DC_39W12
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DF_39W12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DFC_39W12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DN_39W12
	,ISNULL(F.[Infant Health Survey 12 Mos Agg],0) DT_39W12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NC_39W18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NF_39W18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos Agg] > 0  THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NFC_39W18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NN_39W18
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 18 Mos Agg] END,0) NT_39W18
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END,0) DC_39W18
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DF_39W18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DFC_39W18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DN_39W18
	,ISNULL(F.[Infant Health Survey 18 Mos Agg],0) DT_39W18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NC_39W24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NF_39W24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos Agg] > 0  THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NFC_39W24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NN_39W24
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Weight Measured Screening 24 Mos Agg] END,0) NT_39W24
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END,0) DC_39W24
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DF_39W24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DFC_39W24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DN_39W24
	,ISNULL(F.[Infant Health Survey 24 Mos Agg],0) DT_39W24

----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NC_39HC6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NF_39HC6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos Agg] > 0  THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NFC_39HC6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 6 Mos Agg]
		ELSE 0
	END,0) NN_39HC6
	,ISNULL(CASE WHEN F.[Infant Health Survey 6 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 6 Mos Agg] END,0) NT_39HC6
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 6 Mos Agg] 
		ELSE 0
	END,0) DC_39HC6
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DF_39HC6
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DFC_39HC6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 6 Mos Agg]
		ELSE 0
	END,0) DN_39HC6
	,ISNULL(F.[Infant Health Survey 6 Mos Agg],0) DT_39HC6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NC_39HC12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NF_39HC12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos Agg] > 0  THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NFC_39HC12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 12 Mos Agg]
		ELSE 0
	END,0) NN_39HC12
	,ISNULL(CASE WHEN F.[Infant Health Survey 12 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 12 Mos Agg] END,0) NT_39HC12
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 12 Mos Agg] 
		ELSE 0
	END,0) DC_39HC12
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DF_39HC12
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DFC_39HC12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 12 Mos Agg]
		ELSE 0
	END,0) DN_39HC12
	,ISNULL(F.[Infant Health Survey 12 Mos Agg],0) DT_39HC12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NC_39HC18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 18 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NF_39HC18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 18 Mos Agg] > 0  THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NFC_39HC18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 18 Mos Agg]
		ELSE 0
	END,0) NN_39HC18
	,ISNULL(CASE WHEN F.[Infant Health Survey 18 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 18 Mos Agg] END,0) NT_39HC18
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 18 Mos Agg] 
		ELSE 0
	END,0) DC_39HC18
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DF_39HC18
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DFC_39HC18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 18 Mos Agg]
		ELSE 0
	END,0) DN_39HC18
	,ISNULL(F.[Infant Health Survey 18 Mos Agg],0) DT_39HC18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NC_39HC24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Infant Health Survey 24 Mos Agg] > 0
		THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NF_39HC24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 24 Mos Agg] > 0  THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NFC_39HC24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 24 Mos Agg]
		ELSE 0
	END,0) NN_39HC24
	,ISNULL(CASE WHEN F.[Infant Health Survey 24 Mos Agg] > 0 THEN F.[ASQ Head Measured Screening 24 Mos Agg] END,0) NT_39HC24
	,ISNULL(CASE 
		WHEN F.Competitive = 1  THEN F.[Infant Health Survey 24 Mos Agg] 
		ELSE 0
	END,0) DC_39HC24
	,ISNULL(CASE 
		WHEN F.Formula = 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DF_39HC24
	,ISNULL(CASE
		WHEN ((F.Competitive = 1 OR F.Formula = 1)  ) THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DFC_39HC24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Infant Health Survey 24 Mos Agg]
		ELSE 0
	END,0) DN_39HC24
	,ISNULL(F.[Infant Health Survey 24 Mos Agg],0) DT_39HC24

FROM FHVI F


OPTION(RECOMPILE)

END

GO
