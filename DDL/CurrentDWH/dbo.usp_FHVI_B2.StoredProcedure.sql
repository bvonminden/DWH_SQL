USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B2]
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
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND MS_D.SurveyName LIKE '%Preg%'
			THEN 1
		 END),0) [Demographics Assessment Y/N Preg]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND MS_D.SurveyName LIKE '%6%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 6Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND MS_D.SurveyName LIKE '%12%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 12Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND MS_D.SurveyName LIKE '%18%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 18Mos]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL 
				AND MS_D.SurveyName LIKE '%24%'
			THEN 1
		 END),0) [Demographics Assessment Y/N 24Mos]
		,ISNULL(MAX(CASE 
			WHEN MS_IHS.SurveyName LIKE '%6%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 6 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN MS_IHS.SurveyName LIKE '%12%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 12 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN MS_IHS.SurveyName LIKE '%18%' 
				AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Infant Health Care Assessment 18 mos Y/N]
		,ISNULL(MAX(CASE 
			WHEN MS_IHS.SurveyName LIKE '%24%' 
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
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Injestion]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Emergency Visits - Other]
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Injuries requiring treatment]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 6 Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 12 Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 18 Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 24 Mos]   

		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND MS_IHS.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Injestion 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
											AND MS_IHS.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 6Mos]  
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND MS_IHS.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Injestion 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
											AND MS_IHS.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 12Mos]  
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND MS_IHS.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Injestion 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
											AND MS_IHS.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 18Mos]  
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
					AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND MS_IHS.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Injury/Injestion 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
						AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
											AND MS_IHS.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Other 24Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (
							IHS.INFANT_HEALTH_ER_1_TYPE IN ('Injury','Injestion')
							OR (
									IHS.INFANT_HEALTH_ER_1_OTHER <> 'No'
									AND IHS.INFANT_HEALTH_ER_1_OTHER IS NOT NULL
								)
						)
						AND (
								IHS.INFANT_HEALTH_ER_1_INGEST_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT2 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INGEST_TREAT3 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT1 = 'Yes'
								OR IHS.INFANT_HEALTH_ER_1_INJ_TREAT2 = 'Yes'
							)
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Injuries requiring treatment 24Mos]   
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						THEN 1
				END
			  ),0) [Emergency Visits - Client]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						AND MS_D.SurveyName LIKE '%Preg%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client Preg]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						AND MS_D.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						AND MS_D.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						AND MS_D.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER_HOSP = 'Yes'
						AND MS_D.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Emergency Visits - Client 24Mos]
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
						AND MS_IHS.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_IHS.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Suspected cases of maltreatment 24Mos]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
				THEN 1
		 END),0) [Client Child Injury Prevention Training Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND IBS.INFANT_BIRTH_0_DOB IS NULL
				THEN 1
		 END),0) [Injury Prevention Training Pregnancy]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(WEEK,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 25.99
				THEN 1
		 END),0) [Injury Prevention Training 1-8 Weeks]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 6 AND 11
				THEN 1
		 END),0) [Injury Prevention Training 6 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 12 AND 17
				THEN 1
		 END),0) [Injury Prevention Training 12 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 18 AND 23
				THEN 1
		 END),0) [Injury Prevention Training 18 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 24
				THEN 1
		 END),0) [Injury Prevention Training 24 Months]
		 ,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND IBS.INFANT_BIRTH_0_DOB IS NULL
				THEN 1
		 END),0) [Home Visit Rcvd Pregnancy]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(WEEK,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 8
				THEN 1
		 END),0) [Home Visit Rcvd 1-8 Weeks]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 6 AND 11
				THEN 1
		 END),0) [Home Visit Rcvd 6 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 12 AND 17
				THEN 1
		 END),0) [Home Visit Rcvd 12 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 18 AND 23
				THEN 1
		 END),0) [Home Visit Rcvd 18 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 24
				THEN 1
		 END),0) [Home Visit Rcvd 24 Months]
		,ISNULL(MAX(CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL 
				OR AES.CL_EN_GEN_ID IS NOT NULL
				THEN 1
		 END),0) [Home Visit Encounter Y/N]
		 ,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND IBS.INFANT_BIRTH_0_DOB IS NULL
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits Pregnancy]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(WEEK,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 8
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 1-8 Weeks]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 6 AND 11
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 6 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 12 AND 17
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 12 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 18 AND 23
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 18 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CL_EN_GEN_ID IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 24
				THEN HVES.SurveyResponseID
		 END),0) [Count of Home Visits 24 Months]
		 ,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND IBS.INFANT_BIRTH_0_DOB IS NULL
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training Pregnancy]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(WEEK,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 1 AND 8
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 1-8 Weeks]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 6 AND 11
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 6 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 12 AND 17
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 12 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) BETWEEN 18 AND 23
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 18 Months]
		,ISNULL(COUNT(DISTINCT CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
					AND DATEDIFF(MONTH,(IBS.INFANT_BIRTH_0_DOB),CAST(HVES.SurveyDate AS DATE)) >= 24
				THEN HVES.SurveyResponseID
		 END),0) [Count of visits with Injury Prevention training 24 Months]
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
		LEFT JOIN DataWarehouse..Demographics_Survey DS
			ON DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.ProgramID = EAD.ProgramID
			AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_D
			ON MS_D.SurveyID = DS.SurveyID
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
		INNER JOIN DataWarehouse..ProgramsAndSites PAS
			ON PAS.ProgramID = EAD.ProgramID
			AND PAS.ProgramName LIKE '%NURSE%'
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND HVES.CLIENT_COMPLETE_0_VISIT NOT LIKE '%CANC%'
		LEFT JOIN DataWarehouse..Alternative_Encounter_Survey AES
			ON AES.CL_EN_GEN_ID = EAD.CLID
			AND AES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			
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
	F.Site,F.ProgramName
	,F.CaseNumber
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion]
		ELSE 0
	END NC_21I
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion]
		ELSE 0
	END NF_21I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Injury/Injestion]
		ELSE 0
	END	NFC_21I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Injury/Injestion]
		ELSE 0
	END NN_21I
	,F.[Emergency Visits - Injury/Injestion] NT_21I
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DC_21I
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DF_21I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DFC_21I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DN_21I
	,F.[Infant Health Survey Y/N] DT_21I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 6Mos]
		ELSE 0
	END NC_21I6
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 6Mos]
		ELSE 0
	END NF_21I6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Injury/Injestion 6Mos]
		ELSE 0
	END	NFC_21I6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Injury/Injestion 6Mos]
		ELSE 0
	END NN_21I6
	,F.[Emergency Visits - Injury/Injestion 6Mos] NT_21I6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DC_21I6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DF_21I6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DFC_21I6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DN_21I6
	,F.[Infant Health Care Assessment 6 mos Y/N] DT_21I6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 12Mos]
		ELSE 0
	END NC_21I12
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 12Mos]
		ELSE 0
	END NF_21I12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Injury/Injestion 12Mos]
		ELSE 0
	END	NFC_21I12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Injury/Injestion 12Mos]
		ELSE 0
	END NN_21I12
	,F.[Emergency Visits - Injury/Injestion 12Mos] NT_21I12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DC_21I12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DF_21I12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DFC_21I12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DN_21I12
	,F.[Infant Health Care Assessment 12 mos Y/N] DT_21I12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 18Mos]
		ELSE 0
	END NC_21I18
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 18Mos]
		ELSE 0
	END NF_21I18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Injury/Injestion 18Mos]
		ELSE 0
	END	NFC_21I18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Injury/Injestion 18Mos]
		ELSE 0
	END NN_21I18
	,F.[Emergency Visits - Injury/Injestion 18Mos] NT_21I18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DC_21I18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DF_21I18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DFC_21I18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DN_21I18
	,F.[Infant Health Care Assessment 18 mos Y/N] DT_21I18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 24Mos]
		ELSE 0
	END NC_21I24
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Injury/Injestion 24Mos]
		ELSE 0
	END NF_21I24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Injury/Injestion 24Mos]
		ELSE 0
	END	NFC_21I24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Injury/Injestion 24Mos]
		ELSE 0
	END NN_21I24
	,F.[Emergency Visits - Injury/Injestion 24Mos] NT_21I24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DC_21I24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DF_21I24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DFC_21I24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DN_21I24
	,F.[Infant Health Care Assessment 24 mos Y/N] DT_21I24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Other]
		ELSE 0
	END NC_21A
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Other]
		ELSE 0
	END NF_21A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Other]
		ELSE 0
	END	NFC_21A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Other]
		ELSE 0
	END NN_21A
	,F.[Emergency Visits - Other] NT_21A
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DC_21A
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DF_21A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DFC_21A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey Y/N]
		ELSE 0
	END DN_21A
	,F.[Infant Health Survey Y/N] DT_21A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END NC_21O6
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END NF_21O6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END	NFC_21O6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Other 6Mos]
		ELSE 0
	END NN_21O6
	,F.[Emergency Visits - Other 6Mos] NT_21O6
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DC_21O6
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DF_21O6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DFC_21O6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DN_21O6
	,F.[Infant Health Care Assessment 6 mos Y/N] DT_21O6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END NC_21O12
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END NF_21O12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END	NFC_21O12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Other 12Mos]
		ELSE 0
	END NN_21O12
	,F.[Emergency Visits - Other 12Mos] NT_21O12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DC_21O12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DF_21O12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DFC_21O12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DN_21O12
	,F.[Infant Health Care Assessment 12 mos Y/N] DT_21O12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END NC_21O18
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END NF_21O18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END	NFC_21O18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Other 18Mos]
		ELSE 0
	END NN_21O18
	,F.[Emergency Visits - Other 18Mos] NT_21O18
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DC_21O18
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DF_21O18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DFC_21O18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DN_21O18
	,F.[Infant Health Care Assessment 18 mos Y/N] DT_21O18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END NC_21O24
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END NF_21O24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END	NFC_21O24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Other 24Mos]
		ELSE 0
	END NN_21O24
	,F.[Emergency Visits - Other 24Mos] NT_21O24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DC_21O24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DF_21O24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DFC_21O24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DN_21O24
	,F.[Infant Health Care Assessment 24 mos Y/N] DT_21O24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client]
		ELSE 0
	END NC_22
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client]
		ELSE 0
	END NF_22
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client]
		ELSE 0
	END	NFC_22
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client]
		ELSE 0
	END NN_22
	,F.[Emergency Visits - Client] NT_22
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DC_22
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DF_22
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DFC_22
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N]
		ELSE 0
	END DN_22
	,F.[Demographics Assessment Y/N] DT_22
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END NC_22P
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END NF_22P
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END	NFC_22P
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client Preg]
		ELSE 0
	END NN_22P
	,F.[Emergency Visits - Client Preg] NT_22P
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N Preg]
		ELSE 0
	END DC_22P
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N Preg]
		ELSE 0
	END DF_22P
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N Preg]
		ELSE 0
	END DFC_22P
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N Preg]
		ELSE 0
	END DN_22P
	,F.[Demographics Assessment Y/N Preg] DT_22P
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END NC_226
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END NF_226
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END	NFC_226
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client 6Mos]
		ELSE 0
	END NN_226
	,F.[Emergency Visits - Client 6Mos] NT_226
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N 6Mos]
		ELSE 0
	END DC_226
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N 6Mos]
		ELSE 0
	END DF_226
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N 6Mos]
		ELSE 0
	END DFC_226
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N 6Mos]
		ELSE 0
	END DN_226
	,F.[Demographics Assessment Y/N 6Mos] DT_226
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END NC_2212
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END NF_2212
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END	NFC_2212
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client 12Mos]
		ELSE 0
	END NN_2212
	,F.[Emergency Visits - Client 12Mos] NT_2212
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N 12Mos]
		ELSE 0
	END DC_2212
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N 12Mos]
		ELSE 0
	END DF_2212
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N 12Mos]
		ELSE 0
	END DFC_2212
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N 12Mos]
		ELSE 0
	END DN_2212
	,F.[Demographics Assessment Y/N 12Mos] DT_2212
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END NC_2218
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END NF_2218
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END	NFC_2218
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client 18Mos]
		ELSE 0
	END NN_2218
	,F.[Emergency Visits - Client 18Mos] NT_2218
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N 18Mos]
		ELSE 0
	END DC_2218
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N 18Mos]
		ELSE 0
	END DF_2218
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N 18Mos]
		ELSE 0
	END DFC_2218
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N 18Mos]
		ELSE 0
	END DN_2218
	,F.[Demographics Assessment Y/N 18Mos] DT_2218
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END NC_2224
	,CASE F.Formula
		WHEN 1 THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END NF_2224
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END	NFC_2224
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Emergency Visits - Client 24Mos]
		ELSE 0
	END NN_2224
	,F.[Emergency Visits - Client 24Mos] NT_2224
	,CASE F.Competitive
		WHEN 1 THEN F.[Demographics Assessment Y/N 24Mos]
		ELSE 0
	END DC_2224
	,CASE F.Formula
		WHEN 1 THEN F.[Demographics Assessment Y/N 24Mos]
		ELSE 0
	END DF_2224
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Demographics Assessment Y/N 24Mos]
		ELSE 0
	END DFC_2224
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Demographics Assessment Y/N 24Mos]
		ELSE 0
	END DN_2224
	,F.[Demographics Assessment Y/N 24Mos] DT_2224
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NC_23
	,CASE F.Formula
		WHEN 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NF_23
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END	NFC_23
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Child Injury Prevention Training Y/N]
		ELSE 0
	END NN_23
	,F.[Client Child Injury Prevention Training Y/N] NT_23
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DC_23
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DF_23
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DFC_23
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Encounter Y/N]
		ELSE 0
	END DN_23
	,F.[Home Visit Encounter Y/N] DT_23
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END NC_23_18
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END NF_23_18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END	NFC_23_18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training 1-8 Weeks]
		ELSE 0
	END NN_23_18
	,F.[Injury Prevention Training 1-8 Weeks] NT_23_18
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END DC_23_18
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END DF_23_18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END DFC_23_18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd 1-8 Weeks]
		ELSE 0
	END DN_23_18
	,F.[Home Visit Rcvd 1-8 Weeks] DT_23_18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END NC_23Preg
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END NF_23Preg
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END	NFC_23Preg
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training Pregnancy]
		ELSE 0
	END NN_23Preg
	,F.[Injury Prevention Training Pregnancy] NT_23Preg
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END DC_23Preg
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END DF_23Preg
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END DFC_23Preg
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd Pregnancy]
		ELSE 0
	END DN_23Preg
	,F.[Home Visit Rcvd Pregnancy] DT_23Preg
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END NC_236
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END NF_236
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END	NFC_236
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training 6 Months]
		ELSE 0
	END NN_236
	,F.[Injury Prevention Training 6 Months] NT_236
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END DC_236
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END DF_236
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END DFC_236
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd 6 Months]
		ELSE 0
	END DN_236
	,F.[Home Visit Rcvd 6 Months] DT_236
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END NC_2312
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END NF_2312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END	NFC_2312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training 12 Months]
		ELSE 0
	END NN_2312
	,F.[Injury Prevention Training 12 Months] NT_2312
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END DC_2312
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END DF_2312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END DFC_2312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd 12 Months]
		ELSE 0
	END DN_2312
	,F.[Home Visit Rcvd 12 Months] DT_2312
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END NC_2318
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END NF_2318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END	NFC_2318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training 18 Months]
		ELSE 0
	END NN_2318
	,F.[Injury Prevention Training 18 Months] NT_2318
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END DC_2318
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END DF_2318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END DFC_2318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd 18 Months]
		ELSE 0
	END DN_2318
	,F.[Home Visit Rcvd 18 Months] DT_2318
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END NC_2324
	,CASE F.Formula
		WHEN 1 THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END NF_2324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END	NFC_2324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injury Prevention Training 24 Months]
		ELSE 0
	END NN_2324
	,F.[Injury Prevention Training 24 Months] NT_2324
	,CASE F.Competitive
		WHEN 1 THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END DC_2324
	,CASE F.Formula
		WHEN 1 THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END DF_2324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END DFC_2324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Home Visit Rcvd 24 Months]
		ELSE 0
	END DN_2324
	,F.[Home Visit Rcvd 24 Months] DT_2324
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NC_24
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NF_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END	NFC_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment]
		ELSE 0
	END NN_24
	,F.[Injuries requiring treatment] NT_24
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DC_24
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DF_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DFC_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DN_24
	,F.[Infant Birth Survey Y/N] DT_24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END NC_246
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END NF_246
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END	NFC_246
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment 6Mos]
		ELSE 0
	END NN_246
	,F.[Injuries requiring treatment 6Mos] NT_246
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DC_246
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DF_246
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DFC_246
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DN_246
	,F.[Infant Health Care Assessment 6 mos Y/N] DT_246
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END NC_2412
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END NF_2412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END	NFC_2412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment 12Mos]
		ELSE 0
	END NN_2412
	,F.[Injuries requiring treatment 12Mos] NT_2412
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DC_2412
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DF_2412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DFC_2412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DN_2412
	,F.[Infant Health Care Assessment 12 mos Y/N] DT_2412
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END NC_2418
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END NF_2418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END	NFC_2418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment 18Mos]
		ELSE 0
	END NN_2418
	,F.[Injuries requiring treatment 18Mos] NT_2418
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DC_2418
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DF_2418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DFC_2418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DN_2418
	,F.[Infant Health Care Assessment 18 mos Y/N] DT_2418
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END NC_2424
	,CASE F.Formula
		WHEN 1 THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END NF_2424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END	NFC_2424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Injuries requiring treatment 24Mos]
		ELSE 0
	END NN_2424
	,F.[Injuries requiring treatment 24Mos] NT_2424
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DC_2424
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DF_2424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DFC_2424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DN_2424
	,F.[Infant Health Care Assessment 24 mos Y/N] DT_2424

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NC_25
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NF_25
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END	NFC_25
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment]
		ELSE 0
	END NN_25
	,F.[Suspected cases of maltreatment] NT_25
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DC_25
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DF_25
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DFC_25
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Birth Survey Y/N]
		ELSE 0
	END DN_25
	,F.[Infant Birth Survey Y/N] DT_25
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END NC_256
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END NF_256
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END	NFC_256
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment 6Mos]
		ELSE 0
	END NN_256
	,F.[Suspected cases of maltreatment 6Mos] NT_256
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DC_256
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DF_256
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DFC_256
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 6 mos Y/N]
		ELSE 0
	END DN_256
	,F.[Infant Health Care Assessment 6 mos Y/N] DT_256
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END NC_2512
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END NF_2512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END	NFC_2512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment 12Mos]
		ELSE 0
	END NN_2512
	,F.[Suspected cases of maltreatment 12Mos] NT_2512
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DC_2512
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DF_2512
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DFC_2512
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 12 mos Y/N]
		ELSE 0
	END DN_2512
	,F.[Infant Health Care Assessment 12 mos Y/N] DT_2512
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END NC_2518
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END NF_2518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END	NFC_2518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment 18Mos]
		ELSE 0
	END NN_2518
	,F.[Suspected cases of maltreatment 18Mos] NT_2518
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DC_2518
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DF_2518
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DFC_2518
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 18 mos Y/N]
		ELSE 0
	END DN_2518
	,F.[Infant Health Care Assessment 18 mos Y/N] DT_2518
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END NC_2524
	,CASE F.Formula
		WHEN 1 THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END NF_2524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END	NFC_2524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Suspected cases of maltreatment 24Mos]
		ELSE 0
	END NN_2524
	,F.[Suspected cases of maltreatment 24Mos] NT_2524
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DC_2524
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DF_2524
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DFC_2524
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Care Assessment 24 mos Y/N]
		ELSE 0
	END DN_2524
	,F.[Infant Health Care Assessment 24 mos Y/N] DT_2524
	
FROM FHVI F


OPTION(RECOMPILE)
END

GO
