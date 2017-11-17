USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B2_V3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B2_V3]
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
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		,CFS.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
		,CFS.[CLIENT_FUNDING_1_END_OTHER]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
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
						AND (40 - DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD)/7) <= 30
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
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL] IS NOT NULL
				--OR DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) = 'NJ'
				THEN 1
		 END),0) Tribal
		,ISNULL(MAX(CASE 
			WHEN MHS.CL_EN_GEN_ID IS NOT NULL AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate 
			THEN 1
		 END),0) [Maternal Health Assessment Y/N]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND dbo.fngetFormName(DS.SurveyID) LIKE '%Preg%'
			THEN 1
		 END),0) [Demographics Assessment Y/N Preg]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 6Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 12Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 18Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 24Mos]
		,ISNULL(MAX(CASE 
			WHEN dbo.fngetFormName(IHS.SurveyID) LIKE '%6%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 6 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN dbo.fngetFormName(IHS.SurveyID) LIKE '%12%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 12 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN dbo.fngetFormName(IHS.SurveyID) LIKE '%18%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 18 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN dbo.fngetFormName(IHS.SurveyID) LIKE '%24%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 24 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.CL_EN_GEN_ID IS NOT NULL 
						--AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Infant Birth Survey Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL 
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Infant Health Survey Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%EMERGENCY%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Ingestion]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%EMERGENCY%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Ingestion 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%EMERGENCY%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Ingestion 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%EMERGENCY%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Ingestion 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%EMERGENCY%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%EMERGENCY%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Ingestion 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0) [Visits - Injury/Ingestion Answered]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
					THEN 1
				END),0) [Visits - Injury/Ingestion Answered 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
					THEN 1
				END),0) [Visits - Injury/Ingestion Answered 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
					THEN 1
				END),0) [Visits - Injury/Ingestion Answered 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
					THEN 1
				END),0) [Visits - Injury/Ingestion Answered 24Mos]

		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%EMERGENCY%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visits - Other]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%EMERGENCY%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%EMERGENCY%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%EMERGENCY%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%EMERGENCY%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%EMERGENCY%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Visits - Other Answered]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
					
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Visits - Other Answered 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
					
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Visits - Other Answered 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
					
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Visits - Other Answered 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
					
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Visits - Other Answered 24Mos]

		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%Urgent%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Urgent Care Visits - Injury/Ingestion]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%Urgent%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Injury/Ingestion 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%Urgent%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Injury/Ingestion 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%Urgent%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Injury/Ingestion 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
					AND (
							IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INJ_ERvsUC3 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC1 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC2 LIKE '%Urgent%'
							OR IHS.INFANT_HEALTH_ER_1_INGEST_ERvsUC3 LIKE '%Urgent%'
						)
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Injury/Ingestion 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%Urgent%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Urgent Care Visits - Other]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%Urgent%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Other 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%Urgent%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Other 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%Urgent%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Other 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER = 'Yes'
						AND (
								IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC1 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC2 LIKE '%Urgent%'
								OR IHS.INFANT_HEALTH_ER_1_OTHER_ERvsUC3 LIKE '%Urgent%'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Other 24Mos]



		,ISNULL(MAX( 
				CASE
					WHEN (
							(
								IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes'
								AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%'
								AND (
										IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
									)
							 )
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT = 'Yes'
						)
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Injuries requiring treatment]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							(
								IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes'
								AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%'
								AND (
										IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
									)
							 )
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT = 'Yes'
						)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 6Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							(
								IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes'
								AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%'
								AND (
										IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
									)
							 )
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT = 'Yes'
						)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 12Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							(
								IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes'
								AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%'
								AND (
										IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
									)
							 )
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT = 'Yes'
						)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 18Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							(
								IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes'
								AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%'
								AND (
										IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
										OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
									)
							 )
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT = 'Yes'
						)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 24Mos]   


	,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT IS NOT NULL
						 )
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Treatment Question]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT IS NOT NULL
						 )
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Treatment Question 6Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT IS NOT NULL
						 )
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Treatment Question 12Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT IS NOT NULL
						 )
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Treatment Question 18Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_0_HAD_VISIT IS NOT NULL
							OR IHS.INFANT_HEALTH_HOSP_0_HAD_VISIT IS NOT NULL
						 )
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Treatment Question 24Mos]  
		
		--Client ER
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IN ('Yes','1')
						OR (IBS.INFANT_BIRTH_0_CLIENT_ER = 'YES'
							AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate)
						THEN 1
				END
			  ),0) [Emergency Visits - Client]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IS NOT NULL
						OR (IBS.INFANT_BIRTH_0_CLIENT_ER IS NOT NULL
							AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate)
						THEN 1
				END
			  ),0) [Emergency Visits - Client Answered]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.INFANT_BIRTH_0_CLIENT_ER = 'YES'
						AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Emergency Visits - Client Preg]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.INFANT_BIRTH_0_CLIENT_ER IS NOT NULL
						AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Emergency Visits - Client Preg Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 6Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 12Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 18Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 24Mos Answered]			  
		--Client ER times Preg
		,MAX(IBS.INFANT_BIRTH_0_CLIENT_ER_TIMES) [Client ER Visit Times Preg]
		--Client ER times 6-12Mos
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' AND ISNUMERIC(DS.CLIENT_CARE_0_ER_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' AND ISNUMERIC(DS.CLIENT_CARE_0_ER_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) [Client ER Visit Times 6-12Mos]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Injury Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Injury Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Ingestion Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Ingestion Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		--Client ER times 18-24Mos
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' AND ISNUMERIC(DS.CLIENT_CARE_0_ER_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' AND ISNUMERIC(DS.CLIENT_CARE_0_ER_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) [Client ER Visit Times 18-24Mos]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Injury Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Injury Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Ingestion Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Ingestion Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_ER_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		--Client Urgent Care	 
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IN ('Yes','1')
						OR (IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE] = 'YES'
							AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate)
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IS NOT NULL
						OR (IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE] IS NOT NULL
							AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate)
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client Answered]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE] = 'YES'
						AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Urgent Care Visits - Client Preg]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE] IS NOT NULL
						AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Urgent Care Visits - Client Preg Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 6Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 12Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 18Mos Answered]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IN ('Yes','1')
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT IS NOT NULL
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Urgent Care Visits - Client 24Mos Answered]
		--Client Urgent Care times Preg		  
		,MAX(IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]) [Client Urgent Care Visit Times Preg]
		--Client Urgent Care times 6-12Mos		  
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0)+ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) [Client Urgent Care Visit Times 6-12Mos]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Injury Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%6%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%12%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]			 
		--Client Urgent Care times 18-24Mos
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_TIMES) = 1
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) [Client Urgent Care Visit Times 18-24Mos]		 
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Injury Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
		,ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%18%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) + 
		ISNULL(MAX(CASE
						WHEN dbo.fngetFormName(DS.SurveyID)LIKE '%24%' 
							AND ISNUMERIC(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES) = 1
						THEN CAST(DS.CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES AS DECIMAL(18,2))
					 END),0) [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
			 
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 24Mos]
			  
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL IS NOT NULL
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL IS NOT NULL)
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Maltreatment Question]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL IS NOT NULL
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL IS NOT NULL)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Maltreatment Question 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL IS NOT NULL
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL IS NOT NULL)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Maltreatment Question 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL IS NOT NULL
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL IS NOT NULL)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Maltreatment Question 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL IS NOT NULL
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL IS NOT NULL)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Maltreatment Question 24Mos]
			  
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
				THEN 1
		 END),0) [Client Child Injury Prevention Training Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND (IBS.INFANT_BIRTH_0_DOB IS NULL
						  OR IBS.INFANT_BIRTH_0_DOB > HVES.SurveyDate)
				THEN 1
		 END),0) [Injury Prevention Training Pregnancy]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 62.99
				THEN 1
		 END),0) [Injury Prevention Training 1-8 Weeks]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 63 AND 182.624
				THEN 1
		 END),0) [Injury Prevention Training 6 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 182.625 AND 365.24 
				THEN 1
		 END),0) [Injury Prevention Training 12 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 365.25 AND 547.874 
				THEN 1
		 END),0) [Injury Prevention Training 18 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 547.875
				THEN 1
		 END),0) [Injury Prevention Training 24 Months]
		 ,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND (IBS.INFANT_BIRTH_0_DOB IS NULL
						  OR IBS.INFANT_BIRTH_0_DOB > HVES.SurveyDate)
				THEN 1
		 END),0) [Home Visit Rcvd Pregnancy]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 62.99
				THEN 1
		 END),0) [Home Visit Rcvd 1-8 Weeks]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 63 AND 182.624
				THEN 1
		 END),0) [Home Visit Rcvd 6 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 182.625 AND 365.24 
				THEN 1
		 END),0) [Home Visit Rcvd 12 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 365.25 AND 547.874
				THEN 1
		 END),0) [Home Visit Rcvd 18 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 547.875
				THEN 1
		 END),0) [Home Visit Rcvd 24 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL 
				OR AES.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Home Visit Encounter Y/N]
		 ,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND (IBS.INFANT_BIRTH_0_DOB IS NULL
						  OR IBS.INFANT_BIRTH_0_DOB > HVES.SurveyDate)
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits Pregnancy]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 62.99
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 1-8 Weeks]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 63 AND 182.624
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 6 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 182.625 AND 365.24 
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 12 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 365.25 AND 547.874
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 18 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 547.875
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 24 Months]
		 ,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND (IBS.INFANT_BIRTH_0_DOB IS NULL
						  OR IBS.INFANT_BIRTH_0_DOB > HVES.SurveyDate)
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training Pregnancy]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 62.99
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 1-8 Weeks]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 63 AND 182.624
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 6 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 182.625 AND 365.24 
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 12 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 365.25 AND 547.874
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 18 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(DAY,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 547.875
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 24 Months]
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
	,PAS.StateID

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
		LEFT JOIN DataWarehouse..Demographics_Survey DS
			ON DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.ProgramID = EAD.ProgramID
			AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_D
		--	ON dbo.fngetFormName(DS.SurveyID)= DS.SurveyID
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
			AND IBS.ProgramID = EAD.ProgramID
			AND IBS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			AND IHS.ProgramID = EAD.ProgramID
			AND IHS.SurveyDate < = @QuarterDate
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
		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND HVES.CLIENT_COMPLETE_0_VISIT NOT LIKE '%CANC%'
		LEFT JOIN DataWarehouse..Alternative_Encounter_Survey AES
			ON AES.CL_EN_GEN_ID = EAD.CLID
			AND AES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
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
		,(40 - DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD)/7)		 
		,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
		,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		,PAS.StateID
)

SELECT
	F.CaseNumber
	,F.Site,F.ProgramName,F.State
	,F.[Active During Quarter] Active
		,CASE
		WHEN F.Formula > 0 THEN 2
		WHEN F.Competitive > 0 THEN 1
		WHEN F.Tribal > 0 THEN 3
	 END FundingType
	,CASE
		WHEN F.Formula > 0 THEN 'Formula'
		WHEN F.Competitive > 0 THEN 'Competitive'
		WHEN F.Tribal > 0 THEN 'Tribal'
	 END FundingDescription
	,CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN F.Stateid
		WHEN @ReportType = 3 THEN F.SiteID
		WHEN @ReportType = 4 THEN F.ProgramID
	 END [ReportGrouping]
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered] > 0
		THEN F.[Emergency Visits - Injury/Ingestion]
		ELSE 0
	END,0) NC_21I
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered] > 0
		THEN F.[Emergency Visits - Injury/Ingestion]
		ELSE 0
	END,0) NF_21I
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered] > 0THEN F.[Emergency Visits - Injury/Ingestion]
		ELSE 0
	END,0) NFC_21I
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered] > 0 THEN F.[Emergency Visits - Injury/Ingestion]
		ELSE 0
	END,0) NN_21I
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered] > 0 THEN F.[Emergency Visits - Injury/Ingestion]END ,0) NT_21I
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DC_21I
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DF_21I
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DFC_21I
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DN_21I
	,ISNULL(F.[Visits - Injury/Ingestion Answered],0) DT_21I
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NC_21I6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NF_21I6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0THEN F.[Emergency Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NFC_21I6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NN_21I6
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 6Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 6Mos]END ,0) NT_21I6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DC_21I6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DF_21I6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DFC_21I6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DN_21I6
	,ISNULL(F.[Visits - Injury/Ingestion Answered 6Mos],0) DT_21I6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NC_21I12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NF_21I12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0THEN F.[Emergency Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NFC_21I12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NN_21I12
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 12Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 12Mos]END ,0) NT_21I12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DC_21I12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DF_21I12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DFC_21I12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DN_21I12
	,ISNULL(F.[Visits - Injury/Ingestion Answered 12Mos],0) DT_21I12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NC_21I18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NF_21I18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0THEN F.[Emergency Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NFC_21I18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NN_21I18
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 18Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 18Mos]END ,0) NT_21I18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DC_21I18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DF_21I18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DFC_21I18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DN_21I18
	,ISNULL(F.[Visits - Injury/Ingestion Answered 18Mos],0) DT_21I18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NC_21I24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0
		THEN F.[Emergency Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NF_21I24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0THEN F.[Emergency Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NFC_21I24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NN_21I24
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 24Mos] > 0 THEN F.[Emergency Visits - Injury/Ingestion 24Mos]END ,0) NT_21I24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DC_21I24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DF_21I24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DFC_21I24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DN_21I24
	,ISNULL(F.[Visits - Injury/Ingestion Answered 24Mos],0) DT_21I24
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered] > 0
		THEN F.[Emergency Visits - Other]
		ELSE 0
	END,0) NC_21A
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered] > 0
		THEN F.[Emergency Visits - Other]
		ELSE 0
	END,0) NF_21A
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered] > 0THEN F.[Emergency Visits - Other]
		ELSE 0
	END,0) NFC_21A
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered] > 0 THEN F.[Emergency Visits - Other]
		ELSE 0
	END,0) NN_21A
	,ISNULL(CASE WHEN F.[Visits - Other Answered] > 0 THEN F.[Emergency Visits - Other]END ,0) NT_21A
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DC_21A
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DF_21A
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DFC_21A
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DN_21A
	,ISNULL(F.[Visits - Other Answered],0) DT_21A
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 6Mos] > 0
		THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END,0) NC_21O6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 6Mos] > 0
		THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END,0) NF_21O6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 6Mos] > 0THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END,0) NFC_21O6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 6Mos] > 0 THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END,0) NN_21O6
	,ISNULL(CASE WHEN F.[Visits - Other Answered 6Mos] > 0 THEN F.[Emergency Visits - Other 6Mos]END ,0) NT_21O6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DC_21O6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DF_21O6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DFC_21O6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DN_21O6
	,ISNULL(F.[Visits - Other Answered 6Mos],0) DT_21O6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 12Mos] > 0
		THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END,0) NC_21O12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 12Mos] > 0
		THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END,0) NF_21O12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 12Mos] > 0THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END,0) NFC_21O12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 12Mos] > 0 THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END,0) NN_21O12
	,ISNULL(CASE WHEN F.[Visits - Other Answered 12Mos] > 0 THEN F.[Emergency Visits - Other 12Mos]END ,0) NT_21O12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DC_21O12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DF_21O12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DFC_21O12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DN_21O12
	,ISNULL(F.[Visits - Other Answered 12Mos],0) DT_21O12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 18Mos] > 0
		THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END,0) NC_21O18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 18Mos] > 0
		THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END,0) NF_21O18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 18Mos] > 0THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END,0) NFC_21O18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 18Mos] > 0 THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END,0) NN_21O18
	,ISNULL(CASE WHEN F.[Visits - Other Answered 18Mos] > 0 THEN F.[Emergency Visits - Other 18Mos]END ,0) NT_21O18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DC_21O18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DF_21O18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DFC_21O18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DN_21O18
	,ISNULL(F.[Visits - Other Answered 18Mos],0) DT_21O18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 24Mos] > 0
		THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END,0) NC_21O24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 24Mos] > 0
		THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END,0) NF_21O24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 24Mos] > 0THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END,0) NFC_21O24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 24Mos] > 0 THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END,0) NN_21O24
	,ISNULL(CASE WHEN F.[Visits - Other Answered 24Mos] > 0 THEN F.[Emergency Visits - Other 24Mos]END ,0) NT_21O24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DC_21O24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DF_21O24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DFC_21O24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DN_21O24
	,ISNULL(F.[Visits - Other Answered 24Mos],0) DT_21O24
----------------------------------------
,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion]
		ELSE 0
	END,0) NC_21UI
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion]
		ELSE 0
	END,0) NF_21UI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered] > 0THEN F.[Urgent Care Visits - Injury/Ingestion]
		ELSE 0
	END,0) NFC_21UI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion]
		ELSE 0
	END,0) NN_21UI
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion]END ,0) NT_21UI
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DC_21UI
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DF_21UI
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DFC_21UI
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered]
		ELSE 0
	END,0) DN_21UI
	,ISNULL(F.[Visits - Injury/Ingestion Answered],0) DT_21UI
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NC_21UI6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NF_21UI6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0THEN F.[Urgent Care Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NFC_21UI6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 6Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 6Mos]
		ELSE 0
	END,0) NN_21UI6
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 6Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 6Mos]END ,0) NT_21UI6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DC_21UI6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DF_21UI6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DFC_21UI6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 6Mos]
		ELSE 0
	END,0) DN_21UI6
	,ISNULL(F.[Visits - Injury/Ingestion Answered 6Mos],0) DT_21UI6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NC_21UI12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NF_21UI12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0THEN F.[Urgent Care Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NFC_21UI12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 12Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 12Mos]
		ELSE 0
	END,0) NN_21UI12
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 12Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 12Mos]END ,0) NT_21UI12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DC_21UI12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DF_21UI12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DFC_21UI12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 12Mos]
		ELSE 0
	END,0) DN_21UI12
	,ISNULL(F.[Visits - Injury/Ingestion Answered 12Mos],0) DT_21UI12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NC_21UI18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NF_21UI18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0THEN F.[Urgent Care Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NFC_21UI18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 18Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 18Mos]
		ELSE 0
	END,0) NN_21UI18
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 18Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 18Mos]END ,0) NT_21UI18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DC_21UI18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DF_21UI18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DFC_21UI18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 18Mos]
		ELSE 0
	END,0) DN_21UI18
	,ISNULL(F.[Visits - Injury/Ingestion Answered 18Mos],0) DT_21UI18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NC_21UI24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0
		THEN F.[Urgent Care Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NF_21UI24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0THEN F.[Urgent Care Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NFC_21UI24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Injury/Ingestion Answered 24Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 24Mos]
		ELSE 0
	END,0) NN_21UI24
	,ISNULL(CASE WHEN F.[Visits - Injury/Ingestion Answered 24Mos] > 0 THEN F.[Urgent Care Visits - Injury/Ingestion 24Mos]END ,0) NT_21UI24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DC_21UI24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DF_21UI24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DFC_21UI24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Injury/Ingestion Answered 24Mos]
		ELSE 0
	END,0) DN_21UI24
	,ISNULL(F.[Visits - Injury/Ingestion Answered 24Mos],0) DT_21UI24
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered] > 0
		THEN F.[Urgent Care Visits - Other]
		ELSE 0
	END,0) NC_21UA
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered] > 0
		THEN F.[Urgent Care Visits - Other]
		ELSE 0
	END,0) NF_21UA
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered] > 0THEN F.[Urgent Care Visits - Other]
		ELSE 0
	END,0) NFC_21UA
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered] > 0 THEN F.[Urgent Care Visits - Other]
		ELSE 0
	END,0) NN_21UA
	,ISNULL(CASE WHEN F.[Visits - Other Answered] > 0 THEN F.[Urgent Care Visits - Other]END ,0) NT_21UA
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DC_21UA
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DF_21UA
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DFC_21UA
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered]
		ELSE 0
	END,0) DN_21UA
	,ISNULL(F.[Visits - Other Answered],0) DT_21UA
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 6Mos] > 0
		THEN F.[Urgent Care Visits - Other 6Mos]
		ELSE 0
	END,0) NC_21UO6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 6Mos] > 0
		THEN F.[Urgent Care Visits - Other 6Mos]
		ELSE 0
	END,0) NF_21UO6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 6Mos] > 0THEN F.[Urgent Care Visits - Other 6Mos]
		ELSE 0
	END,0) NFC_21UO6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 6Mos] > 0 THEN F.[Urgent Care Visits - Other 6Mos]
		ELSE 0
	END,0) NN_21UO6
	,ISNULL(CASE WHEN F.[Visits - Other Answered 6Mos] > 0 THEN F.[Urgent Care Visits - Other 6Mos]END ,0) NT_21UO6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DC_21UO6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DF_21UO6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DFC_21UO6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 6Mos]
		ELSE 0
	END,0) DN_21UO6
	,ISNULL(F.[Visits - Other Answered 6Mos],0) DT_21UO6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 12Mos] > 0
		THEN F.[Urgent Care Visits - Other 12Mos]
		ELSE 0
	END,0) NC_21UO12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 12Mos] > 0
		THEN F.[Urgent Care Visits - Other 12Mos]
		ELSE 0
	END,0) NF_21UO12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 12Mos] > 0THEN F.[Urgent Care Visits - Other 12Mos]
		ELSE 0
	END,0) NFC_21UO12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 12Mos] > 0 THEN F.[Urgent Care Visits - Other 12Mos]
		ELSE 0
	END,0) NN_21UO12
	,ISNULL(CASE WHEN F.[Visits - Other Answered 12Mos] > 0 THEN F.[Urgent Care Visits - Other 12Mos]END ,0) NT_21UO12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DC_21UO12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DF_21UO12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DFC_21UO12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 12Mos]
		ELSE 0
	END,0) DN_21UO12
	,ISNULL(F.[Visits - Other Answered 12Mos],0) DT_21UO12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 18Mos] > 0
		THEN F.[Urgent Care Visits - Other 18Mos]
		ELSE 0
	END,0) NC_21UO18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 18Mos] > 0
		THEN F.[Urgent Care Visits - Other 18Mos]
		ELSE 0
	END,0) NF_21UO18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 18Mos] > 0THEN F.[Urgent Care Visits - Other 18Mos]
		ELSE 0
	END,0) NFC_21UO18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 18Mos] > 0 THEN F.[Urgent Care Visits - Other 18Mos]
		ELSE 0
	END,0) NN_21UO18
	,ISNULL(CASE WHEN F.[Visits - Other Answered 18Mos] > 0 THEN F.[Urgent Care Visits - Other 18Mos]END ,0) NT_21UO18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DC_21UO18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DF_21UO18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DFC_21UO18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 18Mos]
		ELSE 0
	END,0) DN_21UO18
	,ISNULL(F.[Visits - Other Answered 18Mos],0) DT_21UO18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Visits - Other Answered 24Mos] > 0
		THEN F.[Urgent Care Visits - Other 24Mos]
		ELSE 0
	END,0) NC_21UO24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Visits - Other Answered 24Mos] > 0
		THEN F.[Urgent Care Visits - Other 24Mos]
		ELSE 0
	END,0) NF_21UO24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Visits - Other Answered 24Mos] > 0THEN F.[Urgent Care Visits - Other 24Mos]
		ELSE 0
	END,0) NFC_21UO24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Visits - Other Answered 24Mos] > 0 THEN F.[Urgent Care Visits - Other 24Mos]
		ELSE 0
	END,0) NN_21UO24
	,ISNULL(CASE WHEN F.[Visits - Other Answered 24Mos] > 0 THEN F.[Urgent Care Visits - Other 24Mos]END ,0) NT_21UO24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DC_21UO24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DF_21UO24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DFC_21UO24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Visits - Other Answered 24Mos]
		ELSE 0
	END,0) DN_21UO24
	,ISNULL(F.[Visits - Other Answered 24Mos],0) DT_21UO24
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Emergency Visits - Client Answered] > 0
		THEN F.[Emergency Visits - Client]
		ELSE 0
	END,0) NC_22
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Emergency Visits - Client Answered] > 0
		THEN F.[Emergency Visits - Client]
		ELSE 0
	END,0) NF_22
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Emergency Visits - Client Answered] > 0THEN F.[Emergency Visits - Client]
		ELSE 0
	END,0) NFC_22
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Emergency Visits - Client Answered] > 0 THEN F.[Emergency Visits - Client]
		ELSE 0
	END,0) NN_22
	,ISNULL(CASE WHEN F.[Emergency Visits - Client Answered] > 0 THEN F.[Emergency Visits - Client]END ,0) NT_22
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client Answered]
		ELSE 0
	END,0) DC_22
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client Answered]
		ELSE 0
	END,0) DF_22
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client Answered]
		ELSE 0
	END,0) DFC_22
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client Answered]
		ELSE 0
	END,0) DN_22
	,ISNULL(F.[Emergency Visits - Client Answered],0) DT_22
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Emergency Visits - Client Preg Answered] > 0
		THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END,0) NC_22P
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Emergency Visits - Client Preg Answered] > 0
		THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END,0) NF_22P
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Emergency Visits - Client Preg Answered] > 0THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END,0) NFC_22P
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Emergency Visits - Client Preg Answered] > 0 THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END,0) NN_22P
	,ISNULL(CASE WHEN F.[Emergency Visits - Client Preg Answered] > 0 THEN F.[Emergency Visits - Client Preg]END ,0) NT_22P
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client Preg Answered]
		ELSE 0
	END,0) DC_22P
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client Preg Answered]
		ELSE 0
	END,0) DF_22P
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client Preg Answered]
		ELSE 0
	END,0) DFC_22P
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client Preg Answered]
		ELSE 0
	END,0) DN_22P
	,ISNULL(F.[Emergency Visits - Client Preg Answered],0) DT_22P
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND [Emergency Visits - Client 6Mos Answered] > 0 
		THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END,0) NC_226
	,ISNULL(CASE WHEN F.Formula = 1  AND [Emergency Visits - Client 6Mos Answered] > 0
		THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END,0) NF_226
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND [Emergency Visits - Client 6Mos Answered] > 0 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END,0) NFC_226
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND [Emergency Visits - Client 6Mos Answered] > 0 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END,0) NN_226
	,ISNULL(CASE WHEN [Emergency Visits - Client 6Mos Answered] > 0 THEN F.[Emergency Visits - Client 6Mos]END ,0) NT_226
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DC_226
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DF_226
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DFC_226
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DN_226
	,ISNULL(F.[Emergency Visits - Client 6Mos Answered],0) DT_226
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Emergency Visits - Client 12Mos Answered] > 0
		THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END,0) NC_2212
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Emergency Visits - Client 12Mos Answered] > 0
		THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END,0) NF_2212
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Emergency Visits - Client 12Mos Answered] > 0THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END,0) NFC_2212
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Emergency Visits - Client 12Mos Answered] > 0 THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END,0) NN_2212
	,ISNULL(CASE WHEN F.[Emergency Visits - Client 12Mos Answered] > 0 THEN F.[Emergency Visits - Client 12Mos]END ,0) NT_2212
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DC_2212
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DF_2212
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DFC_2212
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DN_2212
	,ISNULL(F.[Emergency Visits - Client 12Mos Answered],0) DT_2212
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Emergency Visits - Client 18Mos Answered] > 0
		THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END,0) NC_2218
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Emergency Visits - Client 18Mos Answered] > 0
		THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END,0) NF_2218
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Emergency Visits - Client 18Mos Answered] > 0THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END,0) NFC_2218
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Emergency Visits - Client 18Mos Answered] > 0 THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END,0) NN_2218
	,ISNULL(CASE WHEN F.[Emergency Visits - Client 18Mos Answered] > 0 THEN F.[Emergency Visits - Client 18Mos]END ,0) NT_2218
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DC_2218
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DF_2218
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DFC_2218
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DN_2218
	,ISNULL(F.[Emergency Visits - Client 18Mos Answered],0) DT_2218
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Emergency Visits - Client 24Mos Answered] > 0
		THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END,0) NC_2224
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Emergency Visits - Client 24Mos Answered] > 0
		THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END,0) NF_2224
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Emergency Visits - Client 24Mos Answered] > 0THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END,0) NFC_2224
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Emergency Visits - Client 24Mos Answered] > 0 THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END,0) NN_2224
	,ISNULL(CASE WHEN F.[Emergency Visits - Client 24Mos Answered] > 0 THEN F.[Emergency Visits - Client 24Mos]END ,0) NT_2224
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Emergency Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DC_2224
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Emergency Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DF_2224
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Emergency Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DFC_2224
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Emergency Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DN_2224
	,ISNULL(F.[Emergency Visits - Client 24Mos Answered],0) DT_2224
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client ER Visit Times Preg]
		ELSE 0
	END,0) NC_22CVP
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client ER Visit Times Preg]
		ELSE 0
	END,0) NF_22CVP
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Client ER Visit Times Preg]
		ELSE 0
	END,0) NFC_22CVP
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Client ER Visit Times Preg]
		ELSE 0
	END,0) NN_22CVP
	,ISNULL(F.[Client ER Visit Times Preg],0) NT_22CVP
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client ER Visit Times 6-12Mos]
				+ [Client ER Visit Times 6-12Mos Injury Accidental]
				+ [Client ER Visit Times 6-12Mos Injury Declined]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Accidental]
				+ [Client ER Visit Times 6-12Mos Ingestion Declined]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		ELSE 0
	END,0) NC_22CV612
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client ER Visit Times 6-12Mos]
				+ [Client ER Visit Times 6-12Mos Injury Accidental]
				+ [Client ER Visit Times 6-12Mos Injury Declined]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Accidental]
				+ [Client ER Visit Times 6-12Mos Ingestion Declined]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		ELSE 0
	END,0) NF_22CV612
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
		THEN F.[Client ER Visit Times 6-12Mos]
				+ [Client ER Visit Times 6-12Mos Injury Accidental]
				+ [Client ER Visit Times 6-12Mos Injury Declined]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Accidental]
				+ [Client ER Visit Times 6-12Mos Ingestion Declined]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		ELSE 0
	END,0) NFC_22CV612
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  
		THEN F.[Client ER Visit Times 6-12Mos]
				+ [Client ER Visit Times 6-12Mos Injury Accidental]
				+ [Client ER Visit Times 6-12Mos Injury Declined]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Accidental]
				+ [Client ER Visit Times 6-12Mos Ingestion Declined]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		ELSE 0
	END,0) NN_22CV612	
	,ISNULL(F.[Client ER Visit Times 6-12Mos]
				+ [Client ER Visit Times 6-12Mos Injury Accidental]
				+ [Client ER Visit Times 6-12Mos Injury Declined]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Accidental]
				+ [Client ER Visit Times 6-12Mos Ingestion Declined]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 6-12Mos Ingestion Intentional Self Inflicted]
		,0) NT_22CV612
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client ER Visit Times 18-24Mos]
				+ [Client ER Visit Times 18-24Mos Injury Accidental]
				+ [Client ER Visit Times 18-24Mos Injury Declined]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Accidental]
				+ [Client ER Visit Times 18-24Mos Ingestion Declined]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NC_22CV1824
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client ER Visit Times 18-24Mos]
				+ [Client ER Visit Times 18-24Mos Injury Accidental]
				+ [Client ER Visit Times 18-24Mos Injury Declined]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Accidental]
				+ [Client ER Visit Times 18-24Mos Ingestion Declined]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NF_22CV1824
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
		THEN F.[Client ER Visit Times 18-24Mos]
				+ [Client ER Visit Times 18-24Mos Injury Accidental]
				+ [Client ER Visit Times 18-24Mos Injury Declined]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Accidental]
				+ [Client ER Visit Times 18-24Mos Ingestion Declined]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NFC_22CV1824
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  
		THEN F.[Client ER Visit Times 18-24Mos]
				+ [Client ER Visit Times 18-24Mos Injury Accidental]
				+ [Client ER Visit Times 18-24Mos Injury Declined]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Accidental]
				+ [Client ER Visit Times 18-24Mos Ingestion Declined]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NN_22CV1824	
	,ISNULL(F.[Client ER Visit Times 18-24Mos]
				+ [Client ER Visit Times 18-24Mos Injury Accidental]
				+ [Client ER Visit Times 18-24Mos Injury Declined]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Accidental]
				+ [Client ER Visit Times 18-24Mos Ingestion Declined]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client ER Visit Times 18-24Mos Ingestion Intentional Self Inflicted]	
		,0) NT_22CV1824
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Urgent Care Visits - Client Preg Answered] > 0
		THEN F.[Urgent Care Visits - Client Preg]
		ELSE 0
	END,0) NC_22UP
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Urgent Care Visits - Client Preg Answered] > 0
		THEN F.[Urgent Care Visits - Client Preg]
		ELSE 0
	END,0) NF_22UP
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Urgent Care Visits - Client Preg Answered] > 0THEN F.[Urgent Care Visits - Client Preg]
		ELSE 0
	END,0) NFC_22UP
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Urgent Care Visits - Client Preg Answered] > 0 THEN F.[Urgent Care Visits - Client Preg]
		ELSE 0
	END,0) NN_22UP
	,ISNULL(CASE WHEN F.[Urgent Care Visits - Client Preg Answered] > 0 THEN F.[Urgent Care Visits - Client Preg]END ,0) NT_22UP
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Urgent Care Visits - Client Preg Answered]
		ELSE 0
	END,0) DC_22UP
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Urgent Care Visits - Client Preg Answered]
		ELSE 0
	END,0) DF_22UP
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Urgent Care Visits - Client Preg Answered]
		ELSE 0
	END,0) DFC_22UP
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Urgent Care Visits - Client Preg Answered]
		ELSE 0
	END,0) DN_22UP
	,ISNULL(F.[Urgent Care Visits - Client Preg Answered],0) DT_22UP		
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Urgent Care Visits - Client 6Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 6Mos]
		ELSE 0
	END,0) NC_22U6
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Urgent Care Visits - Client 6Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 6Mos]
		ELSE 0
	END,0) NF_22U6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Urgent Care Visits - Client 6Mos Answered] > 0THEN F.[Urgent Care Visits - Client 6Mos]
		ELSE 0
	END,0) NFC_22U6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Urgent Care Visits - Client 6Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 6Mos]
		ELSE 0
	END,0) NN_22U6
	,ISNULL(CASE WHEN F.[Urgent Care Visits - Client 6Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 6Mos]END ,0) NT_22U6
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Urgent Care Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DC_22U6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Urgent Care Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DF_22U6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Urgent Care Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DFC_22U6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Urgent Care Visits - Client 6Mos Answered]
		ELSE 0
	END,0) DN_22U6
	,ISNULL(F.[Urgent Care Visits - Client 6Mos Answered],0) DT_22U6
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Urgent Care Visits - Client 12Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 12Mos]
		ELSE 0
	END,0) NC_22U12
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Urgent Care Visits - Client 12Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 12Mos]
		ELSE 0
	END,0) NF_22U12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Urgent Care Visits - Client 12Mos Answered] > 0THEN F.[Urgent Care Visits - Client 12Mos]
		ELSE 0
	END,0) NFC_22U12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Urgent Care Visits - Client 12Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 12Mos]
		ELSE 0
	END,0) NN_22U12
	,ISNULL(CASE WHEN F.[Urgent Care Visits - Client 12Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 12Mos]END ,0) NT_22U12
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Urgent Care Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DC_22U12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Urgent Care Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DF_22U12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Urgent Care Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DFC_22U12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Urgent Care Visits - Client 12Mos Answered]
		ELSE 0
	END,0) DN_22U12
	,ISNULL(F.[Urgent Care Visits - Client 12Mos Answered],0) DT_22U12
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Urgent Care Visits - Client 18Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 18Mos]
		ELSE 0
	END,0) NC_22U18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Urgent Care Visits - Client 18Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 18Mos]
		ELSE 0
	END,0) NF_22U18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Urgent Care Visits - Client 18Mos Answered] > 0THEN F.[Urgent Care Visits - Client 18Mos]
		ELSE 0
	END,0) NFC_22U18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Urgent Care Visits - Client 18Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 18Mos]
		ELSE 0
	END,0) NN_22U18
	,ISNULL(CASE WHEN F.[Urgent Care Visits - Client 18Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 18Mos]END ,0) NT_22U18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Urgent Care Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DC_22U18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Urgent Care Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DF_22U18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Urgent Care Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DFC_22U18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Urgent Care Visits - Client 18Mos Answered]
		ELSE 0
	END,0) DN_22U18
	,ISNULL(F.[Urgent Care Visits - Client 18Mos Answered],0) DT_22U18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Urgent Care Visits - Client 24Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 24Mos]
		ELSE 0
	END,0) NC_22U24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Urgent Care Visits - Client 24Mos Answered] > 0
		THEN F.[Urgent Care Visits - Client 24Mos]
		ELSE 0
	END,0) NF_22U24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Urgent Care Visits - Client 24Mos Answered] > 0THEN F.[Urgent Care Visits - Client 24Mos]
		ELSE 0
	END,0) NFC_22U24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Urgent Care Visits - Client 24Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 24Mos]
		ELSE 0
	END,0) NN_22U24
	,ISNULL(CASE WHEN F.[Urgent Care Visits - Client 24Mos Answered] > 0 THEN F.[Urgent Care Visits - Client 24Mos]END ,0) NT_22U24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Urgent Care Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DC_22U24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Urgent Care Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DF_22U24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Urgent Care Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DFC_22U24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Urgent Care Visits - Client 24Mos Answered]
		ELSE 0
	END,0) DN_22U24
	,ISNULL(F.[Urgent Care Visits - Client 24Mos Answered],0) DT_22U24
----------------------------------------
,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client Urgent Care Visit Times Preg]
		ELSE 0
	END,0) NC_22UCVP
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client Urgent Care Visit Times Preg]
		ELSE 0
	END,0) NF_22UCVP
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Client Urgent Care Visit Times Preg]
		ELSE 0
	END,0) NFC_22UCVP
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Client Urgent Care Visit Times Preg]
		ELSE 0
	END,0) NN_22UCVP
	,ISNULL(F.[Client Urgent Care Visit Times Preg],0) NT_22UCVP
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client Urgent Care Visit Times 6-12Mos]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NC_22UCV612
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client Urgent Care Visit Times 6-12Mos]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NF_22UCV612
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
		THEN F.[Client Urgent Care Visit Times 6-12Mos]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NFC_22UCV612
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  
		THEN F.[Client Urgent Care Visit Times 6-12Mos]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
		+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]	
		ELSE 0
	END,0) NN_22UCV612	
	,ISNULL(F.[Client Urgent Care Visit Times 6-12Mos]
			+ [Client Urgent Care Visit Times 6-12Mos Injury Accidental]
			+ [Client Urgent Care Visit Times 6-12Mos Injury Declined]
			+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 6-12Mos Injury Intentional Self Inflicted]
			+ [Client Urgent Care Visit Times 6-12Mos Ingestion Accidental]
			+ [Client Urgent Care Visit Times 6-12Mos Ingestion Declined]
			+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 6-12Mos Ingestion Intentional Self Inflicted]	
		,0) NT_22UCV612
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Client Urgent Care Visit Times 18-24Mos]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]		
		ELSE 0
	END,0) NC_22UCV1824
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Client Urgent Care Visit Times 18-24Mos]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]		
		ELSE 0
	END,0) NF_22UCV1824
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
		THEN F.[Client Urgent Care Visit Times 18-24Mos]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]		
		ELSE 0
	END,0) NFC_22UCV1824
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  
		THEN F.[Client Urgent Care Visit Times 18-24Mos]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
			+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]		
		ELSE 0
	END,0) NN_22UCV1824	
	,ISNULL(F.[Client Urgent Care Visit Times 18-24Mos]
				+ [Client Urgent Care Visit Times 18-24Mos Injury Accidental]
				+ [Client Urgent Care Visit Times 18-24Mos Injury Declined]
				+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Other Inflicted]
				+ [Client Urgent Care Visit Times 18-24Mos Injury Intentional Self Inflicted]
				+ [Client Urgent Care Visit Times 18-24Mos Ingestion Accidental]
				+ [Client Urgent Care Visit Times 18-24Mos Ingestion Declined]
				+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Other Inflicted]
				+ [Client Urgent Care Visit Times 18-24Mos Ingestion Intentional Self Inflicted]		
		,0) NT_22UCV1824			
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Encounter Y/N] > 0
		THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END,0) NC_23
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Encounter Y/N] > 0
		THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END,0) NF_23
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Encounter Y/N] > 0THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END,0) NFC_23
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Encounter Y/N] > 0 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END,0) NN_23
	,ISNULL(CASE WHEN F.[Home Visit Encounter Y/N] > 0 THEN F.[Client Child Injury Prevention Training Y/N]END ,0) NT_23
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END,0) DC_23
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END,0) DF_23
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END,0) DFC_23
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END,0) DN_23
	,ISNULL(F.[Home Visit Encounter Y/N],0) DT_23
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd 1-8 Weeks] > 0
		THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END,0) NC_23_18
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd 1-8 Weeks] > 0
		THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END,0) NF_23_18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd 1-8 Weeks] > 0THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END,0) NFC_23_18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd 1-8 Weeks] > 0 THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END,0) NN_23_18
	,ISNULL(CASE WHEN F.[Home Visit Rcvd 1-8 Weeks] > 0 THEN F.[Injury Prevention Training 1-8 Weeks]END ,0) NT_23_18
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END,0) DC_23_18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END,0) DF_23_18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END,0) DFC_23_18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END,0) DN_23_18
	,ISNULL(F.[Home Visit Rcvd 1-8 Weeks],0) DT_23_18
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd Pregnancy] > 0
		THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END,0) NC_23Preg
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd Pregnancy] > 0
		THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END,0) NF_23Preg
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd Pregnancy] > 0THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END,0) NFC_23Preg
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd Pregnancy] > 0 THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END,0) NN_23Preg
	,ISNULL(CASE WHEN F.[Home Visit Rcvd Pregnancy] > 0 THEN F.[Injury Prevention Training Pregnancy]END ,0) NT_23Preg
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END,0) DC_23Preg
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END,0) DF_23Preg
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END,0) DFC_23Preg
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END,0) DN_23Preg
	,ISNULL(F.[Home Visit Rcvd Pregnancy],0) DT_23Preg
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd 6 Months] > 0
		THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END,0) NC_236
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd 6 Months] > 0
		THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END,0) NF_236
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd 6 Months] > 0THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END,0) NFC_236
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd 6 Months] > 0 THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END,0) NN_236
	,ISNULL(CASE WHEN F.[Home Visit Rcvd 6 Months] > 0 THEN F.[Injury Prevention Training 6 Months]END ,0) NT_236
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END,0) DC_236
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END,0) DF_236
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END,0) DFC_236
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END,0) DN_236
	,ISNULL(F.[Home Visit Rcvd 6 Months],0) DT_236
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd 12 Months] > 0
		THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END,0) NC_2312
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd 12 Months] > 0
		THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END,0) NF_2312
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd 12 Months] > 0THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END,0) NFC_2312
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd 12 Months] > 0 THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END,0) NN_2312
	,ISNULL(CASE WHEN F.[Home Visit Rcvd 12 Months] > 0 THEN F.[Injury Prevention Training 12 Months]END ,0) NT_2312
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END,0) DC_2312
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END,0) DF_2312
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END,0) DFC_2312
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END,0) DN_2312
	,ISNULL(F.[Home Visit Rcvd 12 Months],0) DT_2312
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd 18 Months] > 0
		THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END,0) NC_2318
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd 18 Months] > 0
		THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END,0) NF_2318
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd 18 Months] > 0THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END,0) NFC_2318
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd 18 Months] > 0 THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END,0) NN_2318
	,ISNULL(CASE WHEN F.[Home Visit Rcvd 18 Months] > 0 THEN F.[Injury Prevention Training 18 Months]END ,0) NT_2318
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END,0) DC_2318
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END,0) DF_2318
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END,0) DFC_2318
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END,0) DN_2318
	,ISNULL(F.[Home Visit Rcvd 18 Months],0) DT_2318
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Home Visit Rcvd 24 Months] > 0
		THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END,0) NC_2324
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Home Visit Rcvd 24 Months] > 0
		THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END,0) NF_2324
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Home Visit Rcvd 24 Months] > 0THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END,0) NFC_2324
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Home Visit Rcvd 24 Months] > 0 THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END,0) NN_2324
	,ISNULL(CASE WHEN F.[Home Visit Rcvd 24 Months] > 0 THEN F.[Injury Prevention Training 24 Months]END ,0) NT_2324
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END,0) DC_2324
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END,0) DF_2324
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END,0) DFC_2324
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END,0) DN_2324
	,ISNULL(F.[Home Visit Rcvd 24 Months],0) DT_2324
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits Pregnancy]
		ELSE 0
	END,0) NC_23CHVP
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits Pregnancy]
		ELSE 0
	END,0) NF_23CHVP
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits Pregnancy]
		ELSE 0
	END,0) NFC_23CHVP
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits Pregnancy]
		ELSE 0
	END,0) NN_23CHVP
	,ISNULL(F.[Count of Home Visits Pregnancy],0) NT_23CHVP
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits 1-8 Weeks]
		ELSE 0
	END,0) NC_23CHV18W
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits 1-8 Weeks]
		ELSE 0
	END,0) NF_23CHV18W
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits 1-8 Weeks]
		ELSE 0
	END,0) NFC_23CHV18W
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits 1-8 Weeks]
		ELSE 0
	END,0) NN_23CHV18W
	,ISNULL(F.[Count of Home Visits 1-8 Weeks],0) NT_23CHV18W
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits 6 Months]
		ELSE 0
	END,0) NC_23CHV6
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits 6 Months]
		ELSE 0
	END,0) NF_23CHV6
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits 6 Months]
		ELSE 0
	END,0) NFC_23CHV6
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits 6 Months]
		ELSE 0
	END,0) NN_23CHV6
	,ISNULL(F.[Count of Home Visits 6 Months],0) NT_23CHV6
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits 12 Months]
		ELSE 0
	END,0) NC_23CHV12
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits 12 Months]
		ELSE 0
	END,0) NF_23CHV12
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits 12 Months]
		ELSE 0
	END,0) NFC_23CHV12
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits 12 Months]
		ELSE 0
	END,0) NN_23CHV12
	,ISNULL(F.[Count of Home Visits 12 Months],0) NT_23CHV12
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits 18 Months]
		ELSE 0
	END,0) NC_23CHV18
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits 18 Months]
		ELSE 0
	END,0) NF_23CHV18
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits 18 Months]
		ELSE 0
	END,0) NFC_23CHV18
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits 18 Months]
		ELSE 0
	END,0) NN_23CHV18
	,ISNULL(F.[Count of Home Visits 18 Months],0) NT_23CHV18
------------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Count of Home Visits 24 Months]
		ELSE 0
	END,0) NC_23CHV24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Count of Home Visits 24 Months]
		ELSE 0
	END,0) NF_23CHV24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Count of Home Visits 24 Months]
		ELSE 0
	END,0) NFC_23CHV24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Count of Home Visits 24 Months]
		ELSE 0
	END,0) NN_23CHV24
	,ISNULL(F.[Count of Home Visits 24 Months],0) NT_23CHV24
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Treatment Question] > 0
		THEN F.[Injuries requiring treatment]
		ELSE 0
	END,0) NC_24
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Treatment Question] > 0
		THEN F.[Injuries requiring treatment]
		ELSE 0
	END,0) NF_24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Treatment Question] > 0THEN F.[Injuries requiring treatment]
		ELSE 0
	END,0) NFC_24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Treatment Question] > 0 THEN F.[Injuries requiring treatment]
		ELSE 0
	END,0) NN_24
	,ISNULL(CASE WHEN F.[Treatment Question] > 0 THEN F.[Injuries requiring treatment]END ,0) NT_24
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Treatment Question]
		ELSE 0
	END,0) DC_24
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Treatment Question]
		ELSE 0
	END,0) DF_24
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Treatment Question]
		ELSE 0
	END,0) DFC_24
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Treatment Question]
		ELSE 0
	END,0) DN_24
	,ISNULL(F.[Treatment Question],0) DT_24
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Treatment Question 6Mos] > 0
		THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END,0) NC_246
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Treatment Question 6Mos] > 0
		THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END,0) NF_246
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Treatment Question 6Mos] > 0THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END,0) NFC_246
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Treatment Question 6Mos] > 0 THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END,0) NN_246
	,ISNULL(CASE WHEN F.[Treatment Question 6Mos] > 0 THEN F.[Injuries requiring treatment 6Mos]END ,0) NT_246
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Treatment Question 6Mos]
		ELSE 0
	END,0) DC_246
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Treatment Question 6Mos]
		ELSE 0
	END,0) DF_246
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Treatment Question 6Mos]
		ELSE 0
	END,0) DFC_246
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Treatment Question 6Mos]
		ELSE 0
	END,0) DN_246
	,ISNULL(F.[Treatment Question 6Mos],0) DT_246
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Treatment Question 12Mos] > 0
		THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END,0) NC_2412
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Treatment Question 12Mos] > 0
		THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END,0) NF_2412
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Treatment Question 12Mos] > 0THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END,0) NFC_2412
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Treatment Question 12Mos] > 0 THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END,0) NN_2412
	,ISNULL(CASE WHEN F.[Treatment Question 12Mos] > 0 THEN F.[Injuries requiring treatment 12Mos]END ,0) NT_2412
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Treatment Question 12Mos]
		ELSE 0
	END,0) DC_2412
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Treatment Question 12Mos]
		ELSE 0
	END,0) DF_2412
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Treatment Question 12Mos]
		ELSE 0
	END,0) DFC_2412
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Treatment Question 12Mos]
		ELSE 0
	END,0) DN_2412
	,ISNULL(F.[Treatment Question 12Mos],0) DT_2412
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Treatment Question 18Mos] > 0
		THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END,0) NC_2418
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Treatment Question 18Mos] > 0
		THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END,0) NF_2418
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Treatment Question 18Mos] > 0THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END,0) NFC_2418
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Treatment Question 18Mos] > 0 THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END,0) NN_2418
	,ISNULL(CASE WHEN F.[Treatment Question 18Mos] > 0 THEN F.[Injuries requiring treatment 18Mos]END ,0) NT_2418
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Treatment Question 18Mos]
		ELSE 0
	END,0) DC_2418
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Treatment Question 18Mos]
		ELSE 0
	END,0) DF_2418
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Treatment Question 18Mos]
		ELSE 0
	END,0) DFC_2418
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Treatment Question 18Mos]
		ELSE 0
	END,0) DN_2418
	,ISNULL(F.[Treatment Question 18Mos],0) DT_2418
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Treatment Question 24Mos] > 0
		THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END,0) NC_2424
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Treatment Question 24Mos] > 0
		THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END,0) NF_2424
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Treatment Question 24Mos] > 0THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END,0) NFC_2424
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Treatment Question 24Mos] > 0 THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END,0) NN_2424
	,ISNULL(CASE WHEN F.[Treatment Question 24Mos] > 0 THEN F.[Injuries requiring treatment 24Mos]END ,0) NT_2424
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Treatment Question 24Mos]
		ELSE 0
	END,0) DC_2424
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Treatment Question 24Mos]
		ELSE 0
	END,0) DF_2424
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Treatment Question 24Mos]
		ELSE 0
	END,0) DFC_2424
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Treatment Question 24Mos]
		ELSE 0
	END,0) DN_2424
	,ISNULL(F.[Treatment Question 24Mos],0) DT_2424

----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Maltreatment Question] > 0
		THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END,0) NC_25
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Maltreatment Question] > 0
		THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END,0) NF_25
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Maltreatment Question] > 0THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END,0) NFC_25
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Maltreatment Question] > 0 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END,0) NN_25
	,ISNULL(CASE WHEN F.[Maltreatment Question] > 0 THEN F.[Suspected cases of maltreatment]END ,0) NT_25
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Maltreatment Question]
		ELSE 0
	END,0) DC_25
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Maltreatment Question]
		ELSE 0
	END,0) DF_25
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Maltreatment Question]
		ELSE 0
	END,0) DFC_25
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Maltreatment Question]
		ELSE 0
	END,0) DN_25
	,ISNULL(F.[Maltreatment Question],0) DT_25
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Maltreatment Question 6Mos] > 0
		THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END,0) NC_256
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Maltreatment Question 6Mos] > 0
		THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END,0) NF_256
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Maltreatment Question 6Mos] > 0THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END,0) NFC_256
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Maltreatment Question 6Mos] > 0 THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END,0) NN_256
	,ISNULL(CASE WHEN F.[Maltreatment Question 6Mos] > 0 THEN F.[Suspected cases of maltreatment 6Mos]END ,0) NT_256
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Maltreatment Question 6Mos]
		ELSE 0
	END,0) DC_256
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Maltreatment Question 6Mos]
		ELSE 0
	END,0) DF_256
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Maltreatment Question 6Mos]
		ELSE 0
	END,0) DFC_256
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Maltreatment Question 6Mos]
		ELSE 0
	END,0) DN_256
	,ISNULL(F.[Maltreatment Question 6Mos],0) DT_256
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Maltreatment Question 12Mos] > 0
		THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END,0) NC_2512
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Maltreatment Question 12Mos] > 0
		THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END,0) NF_2512
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Maltreatment Question 12Mos] > 0THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END,0) NFC_2512
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Maltreatment Question 12Mos] > 0 THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END,0) NN_2512
	,ISNULL(CASE WHEN F.[Maltreatment Question 12Mos] > 0 THEN F.[Suspected cases of maltreatment 12Mos]END ,0) NT_2512
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Maltreatment Question 12Mos]
		ELSE 0
	END,0) DC_2512
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Maltreatment Question 12Mos]
		ELSE 0
	END,0) DF_2512
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Maltreatment Question 12Mos]
		ELSE 0
	END,0) DFC_2512
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Maltreatment Question 12Mos]
		ELSE 0
	END,0) DN_2512
	,ISNULL(F.[Maltreatment Question 12Mos],0) DT_2512
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Maltreatment Question 18Mos] > 0
		THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END,0) NC_2518
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Maltreatment Question 18Mos] > 0
		THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END,0) NF_2518
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Maltreatment Question 18Mos] > 0THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END,0) NFC_2518
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Maltreatment Question 18Mos] > 0 THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END,0) NN_2518
	,ISNULL(CASE WHEN F.[Maltreatment Question 18Mos] > 0 THEN F.[Suspected cases of maltreatment 18Mos]END ,0) NT_2518
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Maltreatment Question 18Mos]
		ELSE 0
	END,0) DC_2518
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Maltreatment Question 18Mos]
		ELSE 0
	END,0) DF_2518
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Maltreatment Question 18Mos]
		ELSE 0
	END,0) DFC_2518
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Maltreatment Question 18Mos]
		ELSE 0
	END,0) DN_2518
	,ISNULL(F.[Maltreatment Question 18Mos],0) DT_2518
----------------------------------------
	,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Maltreatment Question 24Mos] > 0
		THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END,0) NC_2524
	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Maltreatment Question 24Mos] > 0
		THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END,0) NF_2524
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Maltreatment Question 24Mos] > 0THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END,0) NFC_2524
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Maltreatment Question 24Mos] > 0 THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END,0) NN_2524
	,ISNULL(CASE WHEN F.[Maltreatment Question 24Mos] > 0 THEN F.[Suspected cases of maltreatment 24Mos]END ,0) NT_2524
	,ISNULL(CASE WHEN F.Competitive = 1 
		THEN F.[Maltreatment Question 24Mos]
		ELSE 0
	END,0) DC_2524
	,ISNULL(CASE WHEN F.Formula = 1 
		THEN F.[Maltreatment Question 24Mos]
		ELSE 0
	END,0) DF_2524
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)  THEN F.[Maltreatment Question 24Mos]
		ELSE 0
	END,0) DFC_2524
	,ISNULL(CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  THEN F.[Maltreatment Question 24Mos]
		ELSE 0
	END,0) DN_2524
	,ISNULL(F.[Maltreatment Question 24Mos],0) DT_2524
	
FROM FHVI F
--OPTION(RECOMPILE)
END

GO
