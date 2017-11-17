USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_DataFile]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_DataFile]
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
		,MAX(IHS.INFANT_BIRTH_0_DOB)[Infant DOB]
		,MAX(EAD.ProgramStartDate) [Program Start Date]
		,MAX(EAD.EndDate) [Program End Date]
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
,ISNULL(MAX(CASE
				WHEN  RSS.[SERVICE_REFER_0_TANF] IS NOT NULL
					OR RSS.[REFERRALS_TO_0_FORM_TYPE] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER2_DESC] IS NOT NULL
					OR RSS.[SERIVCE_REFER_0_OTHER3_DESC] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_ADOPTION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_ALCOHOL_ABUSE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHARITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHILD_CARE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CHILD_SUPPORT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_CPS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DENTAL] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_DRUG_ABUSE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_FOODSTAMP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_GED] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_HIGHER_EDUC] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_HOUSING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_INTERVENTION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_IPV] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_JOB_TRAINING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_LACTATION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_LEGAL_CLIENT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_MEDICAID] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_MENTAL] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_OTHER] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PATERNITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PCP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SCHIP] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SMOKE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL
					OR RSS.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL
 				THEN 1
		 END),0) [Received referral]
		 ,ISNULL(MAX(CASE
				WHEN (
						GCSS.[SERVICE_USE_0_ADOPTION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHARITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_CARE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER1] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER2] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_OTHER3] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CPS_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_CPS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DENTAL_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DENTAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_DRUG_ABUSE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_FOODSTAMP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_GED_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_HIGHER_EDUC_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_HOUSING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_INTERVENTION] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_IPV_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_JOB_TRAINING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_LACTATION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_LEGAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MEDICAID_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MEDICAID_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_MENTAL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER1] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER2] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_OTHER3] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PATERNITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_SICK_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_WELL_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PREVENT_INJURY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SCHIP_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SCHIP_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SMOKE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_TANF_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_TRANSPORTATION_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT] IN (2,5) 
						OR GCSS.[SERVICE_USE_0_WIC_CLIENT] IN (2,5) 
					) AND GCSS.SurveyDate < = @QuarterDate
				THEN 1
		 END),0) [Received Services]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_TANF] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_TANF]
,ISNULL(MAX(CASE
    WHEN RSS.[REFERRALS_TO_0_FORM_TYPE] IS NOT NULL     THEN 1
   END),0) [REFERRALS_TO_0_FORM_TYPE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL 
		OR RSS.[SERIVCE_REFER_0_OTHER2_DESC] IS NOT NULL  
		OR RSS.[SERIVCE_REFER_0_OTHER3_DESC] IS NOT NULL 
		OR RSS.[SERVICE_REFER_0_OTHER] IS NOT NULL      THEN 1
   END),0) [SERIVCE_REFER_0_OTHER]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_ADOPTION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_ADOPTION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_ALCOHOL_ABUSE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_ALCOHOL_ABUSE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_BIRTH_EDUC_CLASS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHARITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHARITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHILD_CARE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHILD_CARE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CHILD_SUPPORT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CHILD_SUPPORT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_CPS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_CPS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DENTAL] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DENTAL]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_DRUG_ABUSE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_DRUG_ABUSE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_FOODSTAMP] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_FOODSTAMP]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_GED] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_GED]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_HIGHER_EDUC] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_HIGHER_EDUC]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_HOUSING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_HOUSING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_INTERVENTION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_INTERVENTION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_IPV] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_IPV]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_JOB_TRAINING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_JOB_TRAINING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_LACTATION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_LACTATION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_LEGAL_CLIENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_LEGAL_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_MEDICAID] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_MEDICAID]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_MENTAL] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_MENTAL]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PATERNITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PATERNITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE '%Child - sick%' 
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%Child – sick%'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_SICK_CHILD]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE '%Child - well%' 
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%Child – well%'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_WELL_CHILD]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE 'Client - well%'
		OR RSS.[SERVICE_REFER_0_PCP] LIKE '%CLIENT;%' 
		OR RSS.[SERVICE_REFER_0_PCP] = 'Client' THEN 1
   END),0) [SERVICE_REFER_0_PCP_WELL_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PCP] LIKE 'Client - sick'     THEN 1
   END),0) [SERVICE_REFER_0_PCP_SICK_CLIENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PREVENT_INJURY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_PRIVATE_INSURANCE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SCHIP] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SCHIP]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SMOKE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SMOKE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SOCIAL_SECURITY]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SPECIAL_NEEDS]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_SUBSID_CHILD_CARE]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_TRANSPORTATION]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_UNEMPLOYMENT]
,ISNULL(MAX(CASE
    WHEN RSS.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL     THEN 1
   END),0) [SERVICE_REFER_0_WIC_CLIENT]

,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_ADOPTION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_ADOPTION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_ALCOHOL_ABUSE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_BIRTH_EDUC_CLASS] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHARITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_CHARITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHILD_CARE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_CARE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SUPPORT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_CPS_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CPS_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_CPS] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DENTAL_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_DENTAL_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_DENTAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_DRUG_ABUSE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_DRUG_ABUSE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_FOODSTAMP_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_FOODSTAMP] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_GED_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_GED] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_HIGHER_EDUC_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_HIGHER_EDUC] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_HOUSING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_HOUSING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_INTERVENTION]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_INTERVENTION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_IPV_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_IPV] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_JOB_TRAINING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_JOB_TRAINING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_LACTATION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_LACTATION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_LEGAL_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_LEGAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_MEDICAID_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_MEDICAID_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_MEDICAID] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_MENTAL_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_MENTAL] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_OTHER1]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER1]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_OTHER3]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER3]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_OTHER2]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_CHILD_OTHER2]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_OTHER1] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PATERNITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_PATERNITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PCP_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_SICK_CLIENT] 
,ISNULL(MAX(CASE
    WHEN  GCSS.[SERVICE_USE_0_PCP_SICK_CHILD]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_SICK_CHILD] 
,ISNULL(MAX(CASE
    WHEN  GCSS.[SERVICE_USE_0_PCP_WELL_CHILD]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_WELL_CHILD] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PCP_WELL_CLIENT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PREVENT_INJURY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_PREVENT_INJURY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_PRIVATE_INSURANCE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SCHIP_CHILD]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SCHIP] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SMOKE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SMOKE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SOCIAL_SECURITY] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]  IN (2,5)
     OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]  IN (2,5)
     THEN 1
   END),0) [SERVICE_USE_0_SPECIAL_NEEDS] 

,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_SUBSID_CARE] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_TANF_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_TANF] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_TRANSPORTATION_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_TRANSPORTATION] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_UNEMPLOYMENT] 
,ISNULL(MAX(CASE
    WHEN GCSS.[SERVICE_USE_0_WIC_CLIENT]  IN (2,5)     THEN 1
   END),0) [SERVICE_USE_0_WIC] 
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
			AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND HVES.CLIENT_COMPLETE_0_VISIT NOT LIKE '%CANC%'
		LEFT JOIN DataWarehouse..Alternative_Encounter_Survey AES
			ON AES.CL_EN_GEN_ID = EAD.CLID
			AND AES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Referrals_to_Services_Survey RSS
			ON RSS.CL_EN_GEN_ID = EAD.CLID
			AND RSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Relationship_Survey RS
			ON RS.CL_EN_GEN_ID = EAD.CLID
			AND RS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		LEFT JOIN DataWarehouse..Mstr_surveys MS_RS
			ON MS_RS.SurveyID = RS.SurveyID
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

--OPTION(RECOMPILE)
END

GO
