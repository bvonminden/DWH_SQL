USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B1]
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
					WHEN 40 + DATEDIFF(DAY,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD,CAST(@QuarterDate AS DATE))/7 >= 36
						AND DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID) <=30
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
					--AND DATEDIFF(WEEK,MAX(IBS.INFANT_BIRTH_0_DOB),CAST(@QuarterDate AS DATE)) BETWEEN 1 AND 15.9
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
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE < 13
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND MAX(EAD.ProgramStartDate) BETWEEN @QuarterStart AND @QuarterDate
				THEN '1st Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE BETWEEN 13 AND 27.99
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND MAX(EAD.ProgramStartDate) BETWEEN @QuarterStart AND @QuarterDate
				THEN '2nd Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE >= 28 
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND MAX(EAD.ProgramStartDate) BETWEEN @QuarterStart AND @QuarterDate
				THEN '3rd Trimester'
		END,'Blank') Trimester
		,ISNULL(MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT = 'YES' AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Prenatal Care Y/N]
		,MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%6-9 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%10-13 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%14-17 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%18-21 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%22-25 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%26-29 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%30-32 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%33-35 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%36 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%37 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%38 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%39 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%40 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%41 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1 ELSE 0 END) [Prenatal Visits]
		,CASE
			WHEN MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart
			THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
		 END [Gest age at end of quarter]
		,CASE
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END < 10
			THEN 1
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 10 AND 13.99
			THEN 2
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 14 AND 17.99
			THEN 3
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 18 AND 21.99
			THEN 4
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 22 AND 25.99
			THEN 5
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 26 AND 29.99
			THEN 6
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 30 AND 32.99
			THEN 7
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 33 AND 35.99
			THEN 8
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 36 AND 36.99
			THEN 9
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 37 AND 37.99
			THEN 10
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 38 AND 38.99
			THEN 11
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 39 AND 39.99
			THEN 12
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END BETWEEN 40 AND 40.99
			THEN 13
			WHEN CASE
					WHEN (MAX(IBS.INFANT_BIRTH_0_DOB) IS NULL OR MAX(IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS(MAX(DATEDIFF(DAY,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD),@QuarterDate)/7))
				 END > = 41
			THEN 14
		 END [Expected Visits]
		,ISNULL(MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT IS NOT NULL AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Answered Prenatal Question]
		,ISNULL(MAX(CASE 
			WHEN HHS.CL_EN_GEN_ID IS NOT NULL 
				AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1 
		 END),0) [Health Habits Assessment Y/N]
,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS IS NOT NULL 
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS >0)
								AND MS_H.SurveyName LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Alcohol use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%Intake%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS IS NOT NULL 
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS >0)
								AND MS_H.SurveyName LIKE '%36%' 
								THEN 1
					END)
				END,0) [Alcohol use at 36 Weeks]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								THEN HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0)
								AND MS_H.SurveyName LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Tobacco use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%Intake%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								THEN HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0)
								AND MS_H.SurveyName LIKE '%36%' 
								THEN 1
					END)
				END,0) [Tobacco use at 36 Weeks]
				
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_POT_0_14DAYS IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_POT_0_14DAYS > 0
										OR HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS > 0
										OR HHS.CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES > 0
										OR HHS.CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES > 0)
								AND MS_H.SurveyName LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Illicit Drug use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN MS_H.SurveyName LIKE '%Intake%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_POT_0_14DAYS IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES IS NOT NULL
										OR HHS.CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_POT_0_14DAYS > 0
										OR HHS.CLIENT_SUBSTANCE_COCAINE_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_OTHER_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS > 0
										OR HHS.CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES > 0
										OR HHS.CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES > 0)
								AND MS_H.SurveyName LIKE '%36%' 
								THEN 1
					END)
				END,0) [Illicit Drug use at 36 Weeks]  
		,ISNULL(MAX( 
				CASE 
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND GCSS.SurveyDate < = @QuarterDate
					THEN 1
				END
			  ),0) [Use of Gov't and Comm Svcs Assessment Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN  (GCSS.SERVICE_USE_0_MEDICAID_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_MEDICAID_CLIENT IS NOT NULL
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NOT NULL
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IS NOT NULL)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Insurance Section on Govt Svc Assmnt]
		,ISNULL(MAX( 
				CASE 
					WHEN  (GCSS.SERVICE_USE_0_MEDICAID_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IS NOT NULL
						OR GCSS.SERVICE_USE_0_MEDICAID_CLIENT IS NOT NULL
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NOT NULL
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IS NOT NULL)
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL
					THEN 1
				END
			  ),0) [Insurance Section on Govt Svc Assmnt - Child]
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
				END
			  ),0) [Pregnancy since 1st child]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN (GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN (2,5)) 
					AND GCSS.SurveyDate < = @QuarterDate
					THEN 1 
					END
		END),0) [Well Woman Care]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN (GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN (2,5)) 
					AND MS_G.SurveyName LIKE '%6%'
					THEN 1 
					END
		END),0) [Well Woman Care 6 mos]	
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN (GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN (2,5)) 
					AND MS_G.SurveyName LIKE '%12%'
					THEN 1 
					END
		END),0) [Well Woman Care 12 mos]
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN (GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN (2,5))  
					AND MS_G.SurveyName LIKE '%18%'
					THEN 1 
					END
		END),0) [Well Woman Care 18 mos]		
		,ISNULL(MAX(CASE 
			WHEN CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' THEN 1
						END = 1 
				THEN CASE
					WHEN (GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IN (2,5)
							OR GCSS.SERVICE_USE_PCP_CLIENT_POSTPARTUM IN (2,5))  
					AND MS_G.SurveyName LIKE '%24%'
					THEN 1 
					END
		END),0) [Well Woman Care 24 mos]	
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Pregnancy at 6 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Pregnancy at 12 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Pregnancy at 18 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND MS_D.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Pregnancy at 24 Mos]
		,ISNULL(MAX(CASE
					WHEN MS_D.SurveyName LIKE '%6%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 6 Months]
		,ISNULL(MAX(CASE
					WHEN MS_D.SurveyName LIKE '%12%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 12 Months]
		,ISNULL(MAX( 
				CASE
					WHEN MS_D.SurveyName LIKE '%18%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 18 Months]
		,ISNULL(MAX( 
				CASE
					WHEN MS_D.SurveyName LIKE '%24%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 24 Months]
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
					WHEN (IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'Yes'
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH2 = 'Yes'
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH3 = 'Yes'
						) AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at birth]
		,ISNULL(MAX( 
				CASE 
					WHEN (IBS.INFANT_BREASTMILK_0_EVER_BIRTH IS NOT NULL
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH2 IS NOT NULL
						OR IBS.INFANT_BREASTMILK_0_EVER_BIRTH3 IS NOT NULL
						) AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Breastfeeding question]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND MS_IHS.SurveyName LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 24 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND MS_IHS.SurveyName LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND MS_IHS.SurveyName LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND MS_IHS.SurveyName LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND MS_IHS.SurveyName LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%In the nursery%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%3-5 days after birth%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%By 1 month old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%2 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%4 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END),0) [Completed well child 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%6 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%9 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Completed well child 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%12 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%15 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Completed well child 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%18 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%24 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%24 month visit scheduled%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Completed well child 24 mos]

	,ISNULL(MAX( 
				CASE
					WHEN IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 5
				END),0) [Expected well child 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 2
				END),0) [Expected well child 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 2
				END),0) [Expected well child 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 3
				END),0) [Expected well child 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Child Health Insurance]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Child Health Ins 6 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Child Health Ins 12 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Child Health Ins 18 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CHILD IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Child Health Ins 24 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Client Health Insurance]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%Intake%'
						THEN 1
				END
			  ),0) [Client Health Ins Intake]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%Birt%'
						THEN 1
				END
			  ),0) [Client Health Ins Birth]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%6%'
						THEN 1
				END
			  ),0) [Client Health Ins 6 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%12%'
						THEN 1
				END
			  ),0) [Client Health Ins 12 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%18%'
						THEN 1
				END
			  ),0) [Client Health Ins 18 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
						OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
						OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
						AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND MS_G.SurveyName LIKE '%24%'
						THEN 1
				END
			  ),0) [Client Health Ins 24 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%Intake%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey Intake mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%Birt%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey Birth mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%6%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 6 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%12%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 12 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%18%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 18 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%24%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 24 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND MS_G.SurveyName LIKE '%6%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 6 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%12%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 12 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%18%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 18 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND MS_G.SurveyName LIKE '%24%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 24 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IBS.CL_EN_GEN_ID IS NOT NULL THEN 1
				END
			  ),0) [Infant Birth Survey Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL THEN 1
				END
			  ),0) [Infant Health Survey Y/N]
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
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%6%'
					THEN 1
				END
			),0) [Infant Health Survey 6 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%12%'
					THEN 1
				END
			),0) [Infant Health Survey 12 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
					THEN 1
				END
			),0) [Infant Health Survey 18 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%24%'
					THEN 1
				END
			),0) [Infant Health Survey 24 Mos Agg]		
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND MS_IHS.SurveyName LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 24 Mos]	
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
		LEFT JOIN DataWarehouse..Health_Habits_Survey HHS
			ON HHS.CL_EN_GEN_ID = EAD.CLID
			AND HHS.ProgramID = EAD.ProgramID
			AND HHS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_H
			ON MS_H.SurveyID = HHS.SurveyID
		LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GCSS
			ON GCSS.CL_EN_GEN_ID = EAD.CLID
			AND GCSS.ProgramID = EAD.ProgramID
			AND GCSS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_G
			ON MS_G.SurveyID = GCSS.SurveyID
		LEFT JOIN DataWarehouse..Demographics_Survey DS
			ON DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.ProgramID = EAD.ProgramID
			AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_D
			ON MS_D.SurveyID = DS.SurveyID
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
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END
															
			
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
		,DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID)
		,HVES.CLIENT_PRENATAL_VISITS

)

SELECT
	F.Trimester
	,F.Site,F.ProgramName
	,F.[Active During Quarter] Active
---------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NC_11
	,CASE F.Formula
		WHEN 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NF_11
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END	NFC_11
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Prenatal Care Y/N]
		ELSE 0
	END NN_11
	,F.[Prenatal Care Y/N] NT_11
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DC_11
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DF_11
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DFC_11
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Prenatal Question]
		ELSE 0
	END DN_11
	,F.[Answered Prenatal Question] DT_11

---------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Prenatal Visits]
		ELSE 0
	END NC_11_2
	,CASE F.Formula
		WHEN 1 THEN F.[Prenatal Visits]
		ELSE 0
	END NF_11_2
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Prenatal Visits]
		ELSE 0
	END	NFC_11_2
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Prenatal Visits]
		ELSE 0
	END NN_11_2
	,F.[Prenatal Visits] NT_11_2
	,CASE F.Competitive
		WHEN 1 THEN F.[Expected Visits]
		ELSE 0
	END DC_11_2
	,CASE F.Formula
		WHEN 1 THEN F.[Expected Visits]
		ELSE 0
	END DF_11_2
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected Visits]
		ELSE 0
	END DFC_11_2
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected Visits]
		ELSE 0
	END DN_11_2
	,F.[Expected Visits] DT_11_2

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NC_12A
	,CASE F.Formula
		WHEN 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NF_12A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END	NFC_12A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
		ELSE 0
	END NN_12A
	,F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake] NT_12A
	,CASE 
		WHEN F.Competitive = 1 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
		ELSE 0
	END DC_12A
	,CASE 
		WHEN F.Formula = 1 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
		ELSE 0
	END DF_12A
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Alcohol use at 36 Weeks] IS NOT NULL  THEN F.[Alcohol use at Intake]
		ELSE 0
	END DFC_12A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
		ELSE 0
	END DN_12A
	,CASE 
		WHEN  F.[Alcohol use at 36 Weeks] IS NOT NULL 
		THEN F.[Alcohol use at Intake] 
		ELSE 0
	END DT_12A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NC_12T
	,CASE F.Formula
		WHEN 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NF_12T
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END	NFC_12T
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
		ELSE 0
	END NN_12T
	,F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake] NT_12T
	,CASE 
		WHEN F.Competitive = 1 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
		ELSE 0
	END DC_12T
	,CASE 
		WHEN F.Formula = 1 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
		ELSE 0
	END DF_12T
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Tobacco use at 36 Weeks] IS NOT NULL  THEN F.[Tobacco use at Intake]
		ELSE 0
	END DFC_12T
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
		ELSE 0
	END DN_12T
	,CASE 
		WHEN  F.[Tobacco use at 36 Weeks] IS NOT NULL 
		THEN F.[Tobacco use at Intake] 
		ELSE 0
	END DT_12T
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NC_12I
	,CASE F.Formula
		WHEN 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NF_12I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END	NFC_12I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
		ELSE 0
	END NN_12I
	,F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake] NT_12I
	,CASE 
		WHEN F.Competitive = 1 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DC_12I
	,CASE 
		WHEN F.Formula = 1 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DF_12I
	,CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL  THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DFC_12I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
		ELSE 0
	END DN_12I
	,CASE 
		WHEN  F.[Illicit Drug use at 36 Weeks] IS NOT NULL 
		THEN F.[Illicit Drug use at Intake] 
		ELSE 0
	END DT_12I
----------------------------------------
,CASE F.Competitive
		WHEN 1 THEN F.[Health Habits Assessment Y/N]
		ELSE 0
	END NC_12S
	,CASE F.Formula
		WHEN 1 THEN F.[Health Habits Assessment Y/N]
		ELSE 0
	END NF_12S
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Health Habits Assessment Y/N]
		ELSE 0
	END	NFC_12S
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Health Habits Assessment Y/N]
		ELSE 0
	END NN_12S
	,F.[Health Habits Assessment Y/N] NT_12S
	,CASE
		WHEN F.Competitive = 1 THEN F.[Active During Quarter]
		ELSE 0
	END DC_12S
	,CASE F.Formula
		WHEN 1 THEN F.[Active During Quarter]
		ELSE 0
	END DF_12S
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Active During Quarter]
		ELSE 0
	END DFC_12S
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Active During Quarter]
		ELSE 0
	END DN_12S
	,F.[Active During Quarter] DT_12S
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care]
		ELSE 0
	END NC_13A
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care]
		ELSE 0
	END NF_13A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care]
		ELSE 0
	END	NFC_13A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care]
		ELSE 0
	END NN_13A
	,F.[Well Woman Care] NT_13A
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DC_13A
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DF_13A
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DFC_13A
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy since 1st child]
		ELSE 0
	END DN_13A
	,F.[Pregnancy since 1st child] DT_13A
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NC_136
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NF_136
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END	NFC_136
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 6 mos]
		ELSE 0
	END NN_136
	,F.[Well Woman Care 6 mos] NT_136
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DC_136
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DF_136
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DFC_136
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END DN_136
	,F.[Pregnancy at 6 Mos] DT_136
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NC_1312
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NF_1312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END	NFC_1312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 12 mos]
		ELSE 0
	END NN_1312
	,F.[Well Woman Care 12 mos] NT_1312
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DC_1312
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DF_1312
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DFC_1312
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END DN_1312
	,F.[Pregnancy at 12 Mos] DT_1312
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NC_1318
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NF_1318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END	NFC_1318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 18 mos]
		ELSE 0
	END NN_1318
	,F.[Well Woman Care 18 mos] NT_1318
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DC_1318
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DF_1318
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DFC_1318
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END DN_1318
	,F.[Pregnancy at 18 Mos] DT_1318
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NC_1324
	,CASE F.Formula
		WHEN 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NF_1324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END	NFC_1324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well Woman Care 24 mos]
		ELSE 0
	END NN_1324
	,F.[Well Woman Care 24 mos] NT_1324
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DC_1324
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DF_1324
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DFC_1324
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END DN_1324
	,F.[Pregnancy at 24 Mos] DT_1324
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NC_146
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NF_146
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END	NFC_146
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 6 Mos]
		ELSE 0
	END NN_146
	,F.[Pregnancy at 6 Mos] NT_146
	,CASE F.Competitive
		WHEN 1 THEN F.[Subseq Preg Question - 6 Months]
		ELSE 0
	END DC_146
	,CASE F.Formula
		WHEN 1 THEN F.[Subseq Preg Question - 6 Months]
		ELSE 0
	END DF_146
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Subseq Preg Question - 6 Months]
		ELSE 0
	END DFC_146
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 6 Months]
		ELSE 0
	END DN_146
	,F.[Subseq Preg Question - 6 Months] DT_146
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NC_1412
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NF_1412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END	NFC_1412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 12 Mos]
		ELSE 0
	END NN_1412
	,F.[Pregnancy at 12 Mos] NT_1412
	,CASE F.Competitive
		WHEN 1 THEN F.[Subseq Preg Question - 12 Months]
		ELSE 0
	END DC_1412
	,CASE F.Formula
		WHEN 1 THEN F.[Subseq Preg Question - 12 Months]
		ELSE 0
	END DF_1412
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Subseq Preg Question - 12 Months]
		ELSE 0
	END DFC_1412
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 12 Months]
		ELSE 0
	END DN_1412
	,F.[Subseq Preg Question - 12 Months] DT_1412
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NC_1418
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NF_1418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END	NFC_1418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 18 Mos]
		ELSE 0
	END NN_1418
	,F.[Pregnancy at 18 Mos] NT_1418
	,CASE F.Competitive
		WHEN 1 THEN F.[Subseq Preg Question - 18 Months]
		ELSE 0
	END DC_1418
	,CASE F.Formula
		WHEN 1 THEN F.[Subseq Preg Question - 18 Months]
		ELSE 0
	END DF_1418
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Subseq Preg Question - 18 Months]
		ELSE 0
	END DFC_1418
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 18 Months]
		ELSE 0
	END DN_1418
	,F.[Subseq Preg Question - 18 Months] DT_1418
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NC_1424
	,CASE F.Formula
		WHEN 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NF_1424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END	NFC_1424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 24 Mos]
		ELSE 0
	END NN_1424
	,F.[Pregnancy at 24 Mos] NT_1424
	,CASE F.Competitive
		WHEN 1 THEN F.[Subseq Preg Question - 24 Months]
		ELSE 0
	END DC_1424
	,CASE F.Formula
		WHEN 1 THEN F.[Subseq Preg Question - 24 Months]
		ELSE 0
	END DF_1424
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Subseq Preg Question - 24 Months]
		ELSE 0
	END DFC_1424
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 24 Months]
		ELSE 0
	END DN_1424
	,F.[Subseq Preg Question - 24 Months] DT_1424
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
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15E46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15E46
	,CASE F.[Infant Health Survey 6 Mos]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15E46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_15E46
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_15E46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_15E46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_15E46
	,F.[Infant Health Survey 6 Mos] DT_15E46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15E12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15E12
	,CASE F.[Infant Health Survey 12 Mos]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15E12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_15E12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_15E12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_15E12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_15E12
	,F.[Infant Health Survey 12 Mos] DT_15E12	
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
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15P46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15P46
	,CASE F.[Infant Health Survey 6 Mos]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15P46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_15P46
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_15P46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_15P46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_15P46
	,F.[Infant Health Survey 6 Mos] DT_15P46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15P12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15P12
	,CASE F.[Infant Health Survey 12 Mos]
		WHEN 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15P12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_15P12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_15P12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_15P12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_15P12
	,F.[Infant Health Survey 12 Mos] DT_15P12	
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
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NC_15EP46
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END	NFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NN_15EP46
	,CASE F.[Infant Health Survey 6 Mos]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END NT_15EP46
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_15EP46
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_15EP46
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_15EP46
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_15EP46
	,F.[Infant Health Survey 6 Mos] DT_15EP46	
----------------------------------------
	,CASE
		WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NC_15EP12
	,CASE 
		WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END	NFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NN_15EP12
	,CASE F.[Infant Health Survey 12 Mos]
		WHEN 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END NT_15EP12
	,CASE F.Competitive
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DC_15EP12
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DF_15EP12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DFC_15EP12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
		ELSE 0
	END DN_15EP12
	,F.[Infant Health Survey 12 Mos] DT_15EP12
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
		WHEN 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DC_15S10
	,CASE F.Formula
		WHEN 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DF_15S10
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DFC_15S10
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
		ELSE 0
	END DN_15S10
	,F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] DT_15S10	
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NC_16I
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NF_16I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END	NFC_16I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at birth]
		ELSE 0
	END NN_16I
	,F.[Breastfeeding at birth] NT_16I
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DC_16I
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DF_16I
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DFC_16I
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Breastfeeding question]
		ELSE 0
	END DN_16I
	,F.[Answered Breastfeeding question] DT_16I
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NC_166
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NF_166
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END	NFC_166
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 6 mos]
		ELSE 0
	END NN_166
	,F.[Breastfeeding at 6 mos] NT_166
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DC_166
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DF_166
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DFC_166
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 6 mos]
		ELSE 0
	END DN_166
	,F.[Breastfeeding Question 6 mos] DT_166
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NC_1612
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NF_1612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END	NFC_1612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 12 mos]
		ELSE 0
	END NN_1612
	,F.[Breastfeeding at 12 mos] NT_1612
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 12 mos] 
		ELSE 0
	END DC_1612
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DF_1612
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DFC_1612
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 12 mos]
		ELSE 0
	END DN_1612
	,F.[Breastfeeding Question 12 mos] DT_1612
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NC_1618
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NF_1618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END	NFC_1618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 18 mos]
		ELSE 0
	END NN_1618
	,F.[Breastfeeding at 18 mos] NT_1618
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DC_1618
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DF_1618
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DFC_1618
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 18 mos]
		ELSE 0
	END DN_1618
	,F.[Breastfeeding Question 18 mos] DT_1618
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NC_1624
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NF_1624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END	NFC_1624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding at 24 mos]
		ELSE 0
	END NN_1624
	,F.[Breastfeeding at 24 mos] NT_1624
	,CASE F.Competitive
		WHEN 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DC_1624
	,CASE F.Formula
		WHEN 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DF_1624
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DFC_1624
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 24 mos]
		ELSE 0
	END DN_1624
	,F.[Breastfeeding Question 24 mos] DT_1624
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NC_176
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NF_176
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END	NFC_176
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 6 mos]
		ELSE 0
	END NN_176
	,F.[Well-Child Visits 6 mos] NT_176
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Well-Child 6 Mos]
		ELSE 0
	END DC_176
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Well-Child 6 Mos]
		ELSE 0
	END DF_176
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Well-Child 6 Mos]
		ELSE 0
	END DFC_176
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 6 Mos]
		ELSE 0
	END DN_176
	,F.[Answered Well-Child 6 Mos] DT_176
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NC_1712
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NF_1712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END	NFC_1712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 12 mos]
		ELSE 0
	END NN_1712
	,F.[Well-Child Visits 12 mos] NT_1712
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Well-Child 12 Mos]
		ELSE 0
	END DC_1712
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Well-Child 12 Mos]
		ELSE 0
	END DF_1712
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Well-Child 12 Mos]
		ELSE 0
	END DFC_1712
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 12 Mos]
		ELSE 0
	END DN_1712
	,F.[Answered Well-Child 12 Mos] DT_1712
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NC_1718
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NF_1718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END	NFC_1718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 18 mos]
		ELSE 0
	END NN_1718
	,F.[Well-Child Visits 18 mos] NT_1718
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Well-Child 18 Mos]
		ELSE 0
	END DC_1718
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Well-Child 18 Mos]
		ELSE 0
	END DF_1718
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Well-Child 18 Mos]
		ELSE 0
	END DFC_1718
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 18 Mos]
		ELSE 0
	END DN_1718
	,F.[Answered Well-Child 18 Mos] DT_1718
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NC_1724
	,CASE F.Formula
		WHEN 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NF_1724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END	NFC_1724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Well-Child Visits 24 mos]
		ELSE 0
	END NN_1724
	,F.[Well-Child Visits 24 mos] NT_1724
	,CASE F.Competitive
		WHEN 1 THEN F.[Answered Well-Child 24 Mos]
		ELSE 0
	END DC_1724
	,CASE F.Formula
		WHEN 1 THEN F.[Answered Well-Child 24 Mos]
		ELSE 0
	END DF_1724
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Answered Well-Child 24 Mos]
		ELSE 0
	END DFC_1724
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 24 Mos]
		ELSE 0
	END DN_1724
	,F.[Answered Well-Child 24 Mos] DT_1724

----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Completed well child 6 mos]
		ELSE 0
	END NC_17_2_6
	,CASE F.Formula
		WHEN 1 THEN F.[Completed well child 6 mos]
		ELSE 0
	END NF_17_2_6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Completed well child 6 mos]
		ELSE 0
	END	NFC_17_2_6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Completed well child 6 mos]
		ELSE 0
	END NN_17_2_6
	,F.[Completed well child 6 mos] NT_17_2_6
	,CASE F.Competitive
		WHEN 1 THEN F.[Expected well child 6 Mos]
		ELSE 0
	END DC_17_2_6
	,CASE F.Formula
		WHEN 1 THEN F.[Expected well child 6 Mos]
		ELSE 0
	END DF_17_2_6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 6 Mos]
		ELSE 0
	END DFC_17_2_6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 6 Mos]
		ELSE 0
	END DN_17_2_6
	,F.[Expected well child 6 Mos] DT_17_2_6
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Completed well child 12 mos]
		ELSE 0
	END NC_17_2_12
	,CASE F.Formula
		WHEN 1 THEN F.[Completed well child 12 mos]
		ELSE 0
	END NF_17_2_12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Completed well child 12 mos]
		ELSE 0
	END	NFC_17_2_12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Completed well child 12 mos]
		ELSE 0
	END NN_17_2_12
	,F.[Completed well child 12 mos] NT_17_2_12
	,CASE F.Competitive
		WHEN 1 THEN F.[Expected well child 12 Mos]
		ELSE 0
	END DC_17_2_12
	,CASE F.Formula
		WHEN 1 THEN F.[Expected well child 12 Mos]
		ELSE 0
	END DF_17_2_12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 12 Mos]
		ELSE 0
	END DFC_17_2_12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 12 Mos]
		ELSE 0
	END DN_17_2_12
	,F.[Expected well child 12 Mos] DT_17_2_12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Completed well child 18 mos]
		ELSE 0
	END NC_17_2_18
	,CASE F.Formula
		WHEN 1 THEN F.[Completed well child 18 mos]
		ELSE 0
	END NF_17_2_18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Completed well child 18 mos]
		ELSE 0
	END	NFC_17_2_18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Completed well child 18 mos]
		ELSE 0
	END NN_17_2_18
	,F.[Completed well child 18 mos] NT_17_2_18
	,CASE F.Competitive
		WHEN 1 THEN F.[Expected well child 18 Mos]
		ELSE 0
	END DC_17_2_18
	,CASE F.Formula
		WHEN 1 THEN F.[Expected well child 18 Mos]
		ELSE 0
	END DF_17_2_18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 18 Mos]
		ELSE 0
	END DFC_17_2_18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 18 Mos]
		ELSE 0
	END DN_17_2_18
	,F.[Expected well child 18 Mos] DT_17_2_18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Completed well child 24 mos]
		ELSE 0
	END NC_17_2_24
	,CASE F.Formula
		WHEN 1 THEN F.[Completed well child 24 mos]
		ELSE 0
	END NF_17_2_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Completed well child 24 mos]
		ELSE 0
	END	NFC_17_2_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Completed well child 24 mos]
		ELSE 0
	END NN_17_2_24
	,F.[Completed well child 24 mos] NT_17_2_24
	,CASE F.Competitive
		WHEN 1 THEN F.[Expected well child 24 Mos]
		ELSE 0
	END DC_17_2_24
	,CASE F.Formula
		WHEN 1 THEN F.[Expected well child 24 Mos]
		ELSE 0
	END DF_17_2_24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 24 Mos]
		ELSE 0
	END DFC_17_2_24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 24 Mos]
		ELSE 0
	END DN_17_2_24
	,F.[Expected well child 24 Mos] DT_17_2_24


----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NC_18M
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NF_18M
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Insurance]
		ELSE 0
	END	NFC_18M
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Insurance]
		ELSE 0
	END NN_18M
	,F.[Client Health Insurance] NT_18M
	,CASE F.Competitive
		WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt]
		ELSE 0
	END DC_18M
	,CASE F.Formula
		WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt]
		ELSE 0
	END DF_18M
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Insurance Section on Govt Svc Assmnt]
		ELSE 0
	END DFC_18M
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Insurance Section on Govt Svc Assmnt]
		ELSE 0
	END DN_18M
	,F.[Insurance Section on Govt Svc Assmnt] DT_18M
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins Intake]
		ELSE 0
	END NC_18MIntake
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins Intake]
		ELSE 0
	END NF_18MIntake
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins Intake]
		ELSE 0
	END	NFC_18MIntake
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins Intake]
		ELSE 0
	END NN_18MIntake
	,F.[Client Health Ins Intake] NT_18MIntake
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey Intake mos Y/N]
		ELSE 0
	END DC_18MIntake
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey Intake mos Y/N]
		ELSE 0
	END DF_18MIntake
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey Intake mos Y/N]
		ELSE 0
	END DFC_18MIntake
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey Intake mos Y/N]
		ELSE 0
	END DN_18MIntake
	,F.[Govt Svc Survey Intake mos Y/N] DT_18MIntake
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins Birth]
		ELSE 0
	END NC_18MBirth
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins Birth]
		ELSE 0
	END NF_18MBirth
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins Birth]
		ELSE 0
	END	NFC_18MBirth
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins Birth]
		ELSE 0
	END NN_18MBirth
	,F.[Client Health Ins Birth] NT_18MBirth
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey Birth mos Y/N]
		ELSE 0
	END DC_18MBirth
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey Birth mos Y/N]
		ELSE 0
	END DF_18MBirth
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey Birth mos Y/N]
		ELSE 0
	END DFC_18MBirth
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey Birth mos Y/N]
		ELSE 0
	END DN_18MBirth
	,F.[Govt Svc Survey Birth mos Y/N] DT_18MBirth
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NC_18M6
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NF_18M6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END	NFC_18M6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 6 Mos]
		ELSE 0
	END NN_18M6
	,F.[Client Health Ins 6 Mos] NT_18M6
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DC_18M6
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DF_18M6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DFC_18M6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Y/N]
		ELSE 0
	END DN_18M6
	,F.[Govt Svc Survey 6 mos Y/N] DT_18M6
	----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NC_18M12
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NF_18M12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END	NFC_18M12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 12 Mos]
		ELSE 0
	END NN_18M12
	,F.[Client Health Ins 12 Mos] NT_18M12
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DC_18M12
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DF_18M12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DFC_18M12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Y/N]
		ELSE 0
	END DN_18M12
	,F.[Govt Svc Survey 12 mos Y/N] DT_18M12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NC_18M18
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NF_18M18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END	NFC_18M18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 18 Mos]
		ELSE 0
	END NN_18M18
	,F.[Client Health Ins 18 Mos] NT_18M18
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DC_18M18
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DF_18M18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DFC_18M18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Y/N]
		ELSE 0
	END DN_18M18
	,F.[Govt Svc Survey 18 mos Y/N] DT_18M18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NC_18M24
	,CASE F.Formula
		WHEN 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NF_18M24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END	NFC_18M24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Client Health Ins 24 Mos]
		ELSE 0
	END NN_18M24
	,F.[Client Health Ins 24 Mos] NT_18M24
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DC_18M24
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DF_18M24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DFC_18M24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Y/N]
		ELSE 0
	END DN_18M24
	,F.[Govt Svc Survey 24 mos Y/N] DT_18M24
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NC_18C
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NF_18C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Insurance]
		ELSE 0
	END	NFC_18C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Insurance]
		ELSE 0
	END NN_18C
	,F.[Child Health Insurance] NT_18C
	,CASE F.Competitive
		WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
		ELSE 0
	END DC_18C
	,CASE F.Formula
		WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
		ELSE 0
	END DF_18C
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
		ELSE 0
	END DFC_18C
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
		ELSE 0
	END DN_18C
	,F.[Insurance Section on Govt Svc Assmnt - Child] DT_18C
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NC_18C6
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NF_18C6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END	NFC_18C6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 6 Mos]
		ELSE 0
	END NN_18C6
	,F.[Child Health Ins 6 Mos] NT_18C6
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
		ELSE 0
	END DC_18C6
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
		ELSE 0
	END DF_18C6
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
		ELSE 0
	END DFC_18C6
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
		ELSE 0
	END DN_18C6
	,F.[Govt Svc Survey 6 mos Child Y/N] DT_18C6
	----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NC_18C12
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NF_18C12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END	NFC_18C12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 12 Mos]
		ELSE 0
	END NN_18C12
	,F.[Child Health Ins 12 Mos] NT_18C12
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
		ELSE 0
	END DC_18C12
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
		ELSE 0
	END DF_18C12
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
		ELSE 0
	END DFC_18C12
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
		ELSE 0
	END DN_18C12
	,F.[Govt Svc Survey 12 mos Child Y/N] DT_18C12
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NC_18C18
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NF_18C18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END	NFC_18C18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 18 Mos]
		ELSE 0
	END NN_18C18
	,F.[Child Health Ins 18 Mos] NT_18C18
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
		ELSE 0
	END DC_18C18
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
		ELSE 0
	END DF_18C18
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
		ELSE 0
	END DFC_18C18
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
		ELSE 0
	END DN_18C18
	,F.[Govt Svc Survey 18 mos Child Y/N] DT_18C18
----------------------------------------
	,CASE F.Competitive
		WHEN 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NC_18C24
	,CASE F.Formula
		WHEN 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NF_18C24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END	NFC_18C24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Child Health Ins 24 Mos]
		ELSE 0
	END NN_18C24
	,F.[Child Health Ins 24 Mos] NT_18C24
	,CASE F.Competitive
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
		ELSE 0
	END DC_18C24
	,CASE F.Formula
		WHEN 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
		ELSE 0
	END DF_18C24
	,CASE
		WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
		ELSE 0
	END DFC_18C24
	,CASE 
		WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
		ELSE 0
	END DN_18C24
	,F.[Govt Svc Survey 24 mos Child Y/N] DT_18C24

FROM FHVI F

OPTION(RECOMPILE)
END

GO
