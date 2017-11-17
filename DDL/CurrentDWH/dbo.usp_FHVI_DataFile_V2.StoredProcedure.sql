USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_DataFile_V2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_DataFile_V2]
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
WITH DEMOG AS (
				SELECT
					D.CL_EN_GEN_ID
					,D.ProgramID
					,D.SiteID
					,D.SurveyDate
					,D.CLIENT_MARITAL_0_STATUS
					,CASE 
						WHEN D.SurveyDate > = '10/1/2010'
						THEN D.CLIENT_EDUCATION_0_HS_GED
					 END CLIENT_EDUCATION_0_HS_GED
					,D.CLIENT_INCOME_0_HH_INCOME	
					,(CASE 
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Less than %6%000' THEN 3000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%9%000' THEN 7500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%12%000' THEN 9000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%9%001%12%000' THEN 10500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%16%000' THEN 14000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%20%000' THEN 16000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%16%001%20%000' THEN 18000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
						END) [Household Income]
					,DataWarehouse.dbo.udf_StateVSTribal(A.State,D.SiteID) State
					,DataWarehouse.dbo.fnGetFormName(D.SurveyID) [Form Name]
				FROM DataWarehouse..Demographics_Survey D
					INNER JOIN DataWarehouse..Agencies A
						ON A.Site_ID = D.SiteID
				WHERE CASE
						WHEN @ReportType = 1
						THEN '1'
						WHEN @ReportType = 2
						THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,D.SiteID),D.SiteID)
						WHEN @ReportType = 3
						THEN CAST(D.SiteID AS VARCHAR(50))
						WHEN @ReportType = 4
						THEN CAST(D.ProgramID AS VARCHAR(50))
					 END IN (CAST(@Site AS VARCHAR(50)))
					AND D.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND (
							DataWarehouse.dbo.fnGetFormName(D.SurveyID) LIKE '%INTAKE%'
							OR DataWarehouse.dbo.fnGetFormName(D.SurveyID) LIKE '%12%'
						)
)

	SELECT 

		EAD.CaseNumber--,EAD.EndDate
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
		,EDD.EDD
		,MAX(EAD.ProgramStartDate) [Client Enrollment Date]
		,MAX(EAD.EndDate) [Client Discharge from NHV Program Date]
		,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
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
		,ISNULL(MAX(
				CASE WHEN IBS.CL_EN_GEN_ID IS NOT NULL
					AND IBS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 END),0) [Infant Birth Survey during Quarter]
		,ISNULL(MAX(
				CASE WHEN ISNULL(ISNULL(ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM),EAD.EndDate),GETDATE()) 
							> DATEADD(DAY,61,IBS.INFANT_BIRTH_0_DOB)
						AND DATEADD(DAY,61,IBS.INFANT_BIRTH_0_DOB) BETWEEN @QuarterStart AND @QuarterDate
				THEN 1 END),0) [Active at Infant DOB + 61 days]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
				
				THEN 1
		 END),0) [Competitive]
		,ISNULL(MAX(CASE 
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL

				THEN 1
		 END),0) [Formula]
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE < 13
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL BETWEEN @QuarterStart AND @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				THEN '1st Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE BETWEEN 13 AND 27.99
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL  BETWEEN @QuarterStart AND @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				THEN '2nd Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE >= 28 
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM  BETWEEN @QuarterStart AND @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL  BETWEEN @QuarterStart AND @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				THEN '3rd Trimester'
		END,'Blank') Trimester
		,ISNULL(MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT = 'YES' AND (MHS.SurveyDate) BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		 END),0) [Prenatal Care Y/N]
		,MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%6-9 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%10-13 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%14-17 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%18-21 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%22-25 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%26-29 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%30-32 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%33-35 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%36 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%37 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%38 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%39 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%40 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END)
		+MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS_WEEKS LIKE '%41 weeks%' AND (IBS.INFANT_BIRTH_0_DOB IS NULL OR IBS.INFANT_BIRTH_0_DOB > @QuarterStart) AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END THEN 1 ELSE 0 END) [Prenatal Visits]
		,MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_EDD >= @QuarterDate
				AND ISNULL(ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL)),GETDATE()) > = @QuarterDate
			THEN 40 - (DATEDIFF(DAY,@QuarterDate,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD)/7)
		 END) [Gest age at end of quarter]
		,CASE
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) < 10
			THEN 1
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 10 AND 13.99
			THEN 2
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 14 AND 17.99
			THEN 3
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 18 AND 21.99
			THEN 4
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 22 AND 25.99
			THEN 5
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 26 AND 29.99
			THEN 6
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 30 AND 32.99
			THEN 7
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 33 AND 35.99
			THEN 8
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 36 AND 36.99
			THEN 9
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 37 AND 37.99
			THEN 10
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 38 AND 38.99
			THEN 11
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 39 AND 39.99
			THEN 12
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 40 AND 40.99
			THEN 13
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					AND HVES.SurveyDate BETWEEN @QuarterStart 
						AND CASE
								WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
								THEN @QuarterDate
								ELSE IBS.INFANT_BIRTH_0_DOB
							END
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) > = 41
			THEN 14
		 END 
		 [Expected Visits]
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
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS IS NOT NULL 
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS >0)
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Alcohol use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								AND HHS.SurveyDate < = @QuarterDate 
								AND (HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS IS NOT NULL 
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL)
								THEN 1
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
										OR HHS.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS >0)
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								THEN 1
					END)
				END,0) [Alcohol use at 36 Weeks]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								THEN HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0)
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Tobacco use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								AND HHS.SurveyDate < = @QuarterDate 
								THEN HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48
							 END) IS NOT NULL
					THEN MAX(CASE	
								WHEN (HHS.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0)
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
								THEN 1
					END)
				END,0) [Tobacco use at 36 Weeks]
				
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
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
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								THEN 1
					END)
				END,0) [Illicit Drug use at Intake]
		,ISNULL(CASE
					WHEN MAX(CASE	
								WHEN dbo.fngetFormName(HHS.SurveyID) LIKE '%Intake%' 
								AND HHS.SurveyDate < = @QuarterDate 
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
								AND dbo.fngetFormName(HHS.SurveyID) LIKE '%36%' 
								AND HHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate 
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
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%6%'
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
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%12%'
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
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%18%'
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
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%24%'
					THEN 1 
					END
		END),0) [Well Woman Care 24 mos]	
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Pregnancy at 6 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Pregnancy at 12 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Pregnancy at 18 Mos]
		,ISNULL(MAX(CASE
					WHEN DS.CLIENT_SUBPREG_0_BEEN_PREGNANT = 'Yes' 
						AND dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Pregnancy at 24 Mos]
		,ISNULL(MAX(CASE
					WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%6%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 6 Months]
		,ISNULL(MAX(CASE
					WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%12%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 12 Months]
		,ISNULL(MAX( 
				CASE
					WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%18%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 18 Months]
		,ISNULL(MAX( 
				CASE
					WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%24%' AND DS.CLIENT_SUBPREG_0_BEEN_PREGNANT IS NOT NULL
						THEN 1
				END
			  ),0) [Subseq Preg Question - 24 Months]
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
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%INF%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 6 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%INF%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 12 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%TOD%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 18 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT = 'Yes'
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding at 24 mos]
		,ISNULL(MAX( 
				CASE 
					WHEN IHS.INFANT_BREASTMILK_1_CONT IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%TOD%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Breastfeeding question 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Well-Child Visits 24 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Answered Well-Child 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 IS NOT NULL 
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%6%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%12%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%18%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%24%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%Intake%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%Birt%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%6%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%12%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%18%'
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
						AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Client Health Ins 24 Mos]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%Intake%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey Intake mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%Birt%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey Birth mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%6%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 6 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%12%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 12 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%18%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 18 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%24%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 24 mos Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%6%'
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 6 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%12%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 12 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%18%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 18 mos Child Y/N]
		,ISNULL(MAX( 
				CASE
					WHEN GCSS.CL_EN_GEN_ID IS NOT NULL 
					AND dbo.fngetFormName(GCSS.SurveyID) LIKE '%24%'
					AND IBS.CL_EN_GEN_ID IS NOT NULL
					AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			  ),0) [Govt Svc Survey 24 mos Child Y/N]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
					THEN 1
				END
			),0) [Infant Health Survey 6 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
					THEN 1
				END
			),0) [Infant Health Survey 12 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
					THEN 1
				END
			),0) [Infant Health Survey 18 Mos Agg]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
					THEN 1
				END
			),0) [Infant Health Survey 24 Mos Agg]		
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 6 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 12 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 18 Mos]
		,ISNULL(MAX(
				CASE
					WHEN IHS.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END
			),0) [Infant Health Survey 24 Mos]	
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
 
		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_ER = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_ER = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_ER = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_ER = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_ER = 'Yes'
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
		,MAX(IBS.INFANT_BIRTH_0_CLIENT_ER_TIMES) [Client ER Visit Times Preg]
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) [Client ER Visit Times 6-12Mos]
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
				THEN CAST(DS.CLIENT_CARE_0_ER_TIMES AS DECIMAL(18,2))
			 END),0) [Client ER Visit Times 18-24Mos]


		,ISNULL(MAX( 
				CASE
					WHEN DS.CLIENT_CARE_0_URGENT = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_URGENT = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_URGENT = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_URGENT = 'Yes'
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
					WHEN DS.CLIENT_CARE_0_URGENT = 'Yes'
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
		,MAX(IBS.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]) [Client Urgent Care Visit Times Preg]
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%6%'
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0)+ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%12%'
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) [Client Urgent Care Visit Times 6-12Mos]
		,ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%18%'
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) + ISNULL(MAX(CASE
				WHEN dbo.fngetFormName(DS.SurveyID) LIKE '%24%'
				THEN CAST(DS.CLIENT_CARE_0_URGENT_TIMES AS DECIMAL(18,2))
			 END),0) [Client Urgent Care Visit Times 18-24Mos]


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
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						--AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ),0) [Maltreatment Question]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
						THEN 1
				END
			  ),0) [Maltreatment Question 6Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
						THEN 1
				END
			  ),0) [Maltreatment Question 12Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
						THEN 1
				END
			  ),0) [Maltreatment Question 18Mos]
		,ISNULL(MAX( 
				CASE
					WHEN (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes'
						OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
						THEN 1
				END
			  ),0) [Maltreatment Question 24Mos]
			  
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
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Preg%36%' THEN 1
				END
			  ),0) [Depression Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' THEN 1
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
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' THEN ES.CLIENT_EPS_TOTAL_SCORE
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
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
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
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' THEN 1
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
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 6 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 12 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 18 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Communication Screening 24 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 6 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 12 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 18 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Problem Solving Screening 24 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 6 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 12 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 18 Mos]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
				END
			  ) [ASQ Personal-Social Screening 24 Mos]
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
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_COMM 
				END
			  ) [ASQ Communication Score 24 Mos - Agg]

		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_GMOTOR 
				END
			  ) [ASQ Gross Motor Score 24 Mos - Agg]

		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_FMOTOR 
				END
			  ) [ASQ Fine Motor Score 24 Mos - Agg]


		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOLVE
				END
			  ) [ASQ Problem Solving Score 24 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
						THEN IHS.INFANT_AGES_STAGES_1_PSOCIAL
				END
			  ) [ASQ Personal-Social Score 24 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%6%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 6 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Inf%12%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 12 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%18%'
	
						THEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL
				END
			  ) [ASQ ASQ-SE Score 18 Mos - Agg]
		,MAX(
				CASE
					WHEN IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
						AND dbo.fngetFormName(IHS.SurveyID) LIKE '%Tod%24%'
	
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
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
		--			OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
		--	THEN 1 
		-- END) [Abnormal Height excluded 6 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
		--			OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
		--	THEN 1 
		-- END) [Abnormal Height excluded 12 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
		--			OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
		--	THEN 1 
		-- END) [Abnormal Height excluded 18 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_HEIGHT_0_INCHES > 60
		--			OR IHS.INFANT_HEALTH_HEIGHT_0_INCHES < 9
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
		--	THEN 1 
		-- END) [Abnormal Height excluded 24 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
		--			OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
		--	THEN 1
		--	END) [Abnormal Weight excluded 6 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
		--			OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
		--	THEN 1
		--	END) [Abnormal Weight excluded 12 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
		--			OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
		--	THEN 1
		--	END) [Abnormal Weight excluded 18 Months]
		--,MAX(CASE
		--	WHEN (
		--			IHS.INFANT_HEALTH_WEIGHT_1_OZ < 8
		--			OR IHS.INFANT_HEALTH_WEIGHT_1_OZ > 1500
		--		 )
		--		AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
		--	THEN 1
		--	END) [Abnormal Weight excluded 24 Months]
		--,MAX(CASE
		--		WHEN (
		--				IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
		--				OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
		--			 )
		--			AND dbo.fngetFormName(IHS.SurveyID) LIKE '%6%'
		--			AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
		--			AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
		--		THEN 1
		--	 END) [Abnormal Head Circ excluded 6 months]
		--,MAX(CASE
		--		WHEN (
		--				IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
		--				OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
		--			 )
		--			AND dbo.fngetFormName(IHS.SurveyID) LIKE '%12%'
		--			AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
		--			AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
		--		THEN 1
		--	 END) [Abnormal Head Circ excluded 12 months]
		--,MAX(CASE
		--		WHEN (
		--				IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
		--				OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
		--			 )
		--			AND dbo.fngetFormName(IHS.SurveyID) LIKE '%18%'
		--			AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
		--			AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
		--		THEN 1
		--	 END) [Abnormal Head Circ excluded 18 months]
		--,MAX(CASE
		--		WHEN (
		--				IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES < 30
		--				OR IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 56
		--			 )
		--			AND dbo.fngetFormName(IHS.SurveyID) LIKE '%24%'
		--			AND IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES > 0
		--			AND IHS.INFANT_HEALTH_HEAD_1_REPORT IS NOT NULL
		--		THEN 1
		--	 END) [Abnormal Head Circ excluded 24 months]
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

		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy Intake Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Pregnancy 36 Weeks Y/N]
		,ISNULL(MAX( 
				CASE 
					WHEN RS.CL_EN_GEN_ID IS NOT NULL 
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
					THEN 1 
				END
			  ),0) [Domestic Violence Screening Infancy 12 Months Y/N]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_CHILD_INJURY_0_PREVENTION = 'Yes'
				THEN 1
		 END),0) [Client Child Injury Prevention Training Y/N]

		,ISNULL(MAX(CASE
				WHEN RSS.SERVICE_REFER_0_IPV LIKE '%Client%'
				THEN 1
		 END),0)[Domestic Violence Referral]
		,ISNULL(MAX(CASE
				WHEN (
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						)
				THEN 1
		 END),0) [Domestic Violence Identified]
,ISNULL(MAX(CASE
				WHEN ((
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						))
					AND RSS.SERVICE_REFER_0_IPV LIKE '%Client%'
					AND RSS.SurveyDate > = RS.SurveyDate
				THEN 1
		 END),0) [IPV Referral - IPV Identified]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
				THEN 1
		 END),0) [Safety Plan discussed]
,ISNULL(MAX(CASE
				WHEN ((
						(
							CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME = 'Yes' 
							OR (
									CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME <> 'None' 
									AND  CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME IS NOT NULL
								) 
							OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
						)
						AND dbo.fngetFormName(RS.SurveyID) LIKE '%INTAKE%'
					 ) 
					OR (
							(
								CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER = 'Yes'
								OR CLIENT_ABUSE_HIT_0_SLAP_PARTNER = 'Yes'
								OR (
										CLIENT_ABUSE_TIMES_0_HURT_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HURT_LAST_YR IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER IS NOT NULL
									)
								OR (
										CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER  <> 'None'
										AND CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER IS NOT NULL
									)
								OR CLIENT_ABUSE_FORCED_0_SEX  = 'Yes'
								OR (
										CLIENT_ABUSE_FORCED_1_SEX_LAST_YR  <> 'None'
										AND CLIENT_ABUSE_FORCED_1_SEX_LAST_YR IS NOT NULL
									)
								OR CLIENT_ABUSE_AFRAID_0_PARTNER = 'Yes'
							)
							AND (
									dbo.fngetFormName(RS.SurveyID) LIKE '%36%'
									OR dbo.fngetFormName(RS.SurveyID) LIKE '%12%'
								)
						))
					AND HVES.CLIENT_IPV_0_SAFETY_PLAN = 'Yes'
					AND HVES.SurveyDate > = RS.SurveyDate
				THEN 1
		 END),0) [Safety Plan Discussed - IPV Identified]
		,MAX(CASE 
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE 'Less than %6%000' THEN 3000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%6%001%9%000' THEN 7500
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%6%001%12%000' THEN 9000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%9%001%12%000' THEN 10500
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%12%001%16%000' THEN 14000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%12%001%20%000' THEN 16000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%16%001%20%000' THEN 18000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
			WHEN ISNULL(DIN.CLIENT_INCOME_0_HH_INCOME,DIN.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
		END) [Household Income Intake]
		,MAX(CASE 
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE 'Less than %6%000' THEN 3000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%6%001%9%000' THEN 7500
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%6%001%12%000' THEN 9000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%9%001%12%000' THEN 10500
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%12%001%16%000' THEN 14000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%12%001%20%000' THEN 16000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%16%001%20%000' THEN 18000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
			WHEN ISNULL(D12.CLIENT_INCOME_0_HH_INCOME,D12.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
		END) [Household Income 12Mos]
		,(SELECT
			(
				(
					SELECT CAST(MAX(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.SurveyDate < =  @QuarterDate
								AND DE.[Household Income] > 0
								AND DE.[Form Name] LIKE '%INTAKE%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
											--AND DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) <> 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income]
						 ) AS BottomHalf
				)
			 +
				(
					SELECT CAST(MIN(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.[Household Income] > 0
								AND DE.SurveyDate < = @QuarterDate
								AND DE.[Form Name] LIKE '%INTAKE%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
											--AND DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) <> 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income] DESC
						 ) AS TopHalf
				)
			) / 2) AS MedCompIncINT
		,(SELECT
			(
				(
					SELECT CAST(MAX(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.SurveyDate < =  @QuarterDate
								AND DE.[Household Income] > 0
								AND DE.[Form Name] LIKE '%INTAKE%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
											--OR DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) = 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income]
						 ) AS BottomHalf
				)
			 +
				(
					SELECT CAST(MIN(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.[Household Income] > 0
								AND DE.SurveyDate < = @QuarterDate
								AND DE.[Form Name] LIKE '%INTAKE%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
											--OR DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) = 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income] DESC
						 ) AS TopHalf
				)
			) / 2) AS MedFormIncINT
		,(SELECT
			(
				(
					SELECT CAST(MAX(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
								AND DE.[Household Income] > 0
								AND DE.[Form Name] LIKE '%12%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
											--AND DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) <> 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income]
						 ) AS BottomHalf
				)
			 +
				(
					SELECT CAST(MIN(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.[Household Income] > 0
								AND DE.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
								AND DE.[Form Name] LIKE '%12%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] IS NOT NULL
											--AND DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) <> 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income] DESC
						 ) AS TopHalf
				)
			) / 2) AS MedCompInc12M
		,(SELECT
			(
				(
					SELECT CAST(MAX(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
								AND DE.[Household Income] > 0
								AND DE.[Form Name] LIKE '%12%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
											--AND DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) = 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income]
						 ) AS BottomHalf
				)
			 +
				(
					SELECT CAST(MIN(DOB) AS DECIMAL(18,2)) 
					FROM (
							SELECT TOP 50 PERCENT DE.[Household Income] DOB
							FROM DEMOG DE
							WHERE CASE
									WHEN @ReportType = 1
									THEN '1'
									WHEN @ReportType = 2
									THEN DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID)
									WHEN @ReportType = 3
									THEN CAST(DE.SiteID AS VARCHAR(50))
									WHEN @ReportType = 4
									THEN CAST(DE.ProgramID AS VARCHAR(50))
								 END IN (CAST(@Site AS VARCHAR(50)))
								AND DE.[Household Income] > 0
								AND DE.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
								AND DE.[Form Name] LIKE '%12%'
								AND (CASE 
										WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] IS NOT NULL
											--OR DataWarehouse.dbo.udf_StateVSTribal(DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID),DE.SiteID) = 'NJ'
										THEN 1
									 END) = 1
							ORDER BY DE.[Household Income] DESC
						 ) AS TopHalf
				)
			) / 2) AS MedFormInc12M
		,CASE 
			WHEN 
				MAX(CASE 
						WHEN DIN.CLIENT_INCOME_IN_KIND IS NOT NULL
							AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
						THEN 1
					 END) = 1
				AND
				 MAX(CASE 
						WHEN D12.CLIENT_INCOME_IN_KIND IS NOT NULL
							AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
							AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1
					 END) =1
			THEN 1
		 END [In-Kind Benefits Intake and 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN DIN.CLIENT_INCOME_IN_KIND LIKE '%Energy Assistance%'
						AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN DIN.CLIENT_INCOME_IN_KIND LIKE '%Housing Vouchers%'
						AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN DIN.CLIENT_INCOME_IN_KIND LIKE '%Other%'
						AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN DIN.CLIENT_INCOME_IN_KIND LIKE '%SNAP/Food Stamps%'
						AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN DIN.CLIENT_INCOME_IN_KIND LIKE '%WIC%'
						AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%'
					THEN 1
				END),0) [In-Kind Benefits Count Intake]	
		,ISNULL(MAX(
				CASE
					WHEN D12.CLIENT_INCOME_IN_KIND LIKE '%Energy Assistance%'
						AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN D12.CLIENT_INCOME_IN_KIND LIKE '%Housing Vouchers%'
						AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN D12.CLIENT_INCOME_IN_KIND LIKE '%Other%'
						AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN D12.CLIENT_INCOME_IN_KIND LIKE '%SNAP/Food Stamps%'
						AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0)
			+ISNULL(MAX(
				CASE
					WHEN D12.CLIENT_INCOME_IN_KIND LIKE '%WIC%'
						AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0) [In-Kind Benefits Count 12Mos]	
		,CASE
			WHEN ISNULL(MAX(
						CASE
							WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
							THEN 1
						END),0) = 1
				AND ISNULL(MAX(
							CASE
								WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
									AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
								THEN 1
							END),0) = 1
			THEN 1
		 END [Currently Working Q Intake and 12Mos]
		,MAX(DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate))/365.25 [Age at Enrollment]
		,ISNULL(MAX(
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%' 
						AND DIN.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%YES%'
					THEN 1
				END),0) [Currently Working Intake]
		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%' 
					AND DIN.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
				THEN CASE 
						WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%FULL%'
						THEN 40
						WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND DIN.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%36%'
						THEN 28
						WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND DIN.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%19%'
						THEN 14.5
						WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND DIN.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%LESS%'
						THEN 5
						WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING = 'No'
						THEN 0
					END	
			END) [Currently Working Hours Intake]
		,ISNULL(MAX(
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%' 
						AND D12.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%YES%'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0) [Currently Working 12Mos]
		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%' 
					AND D12.CLIENT_WORKING_0_CURRENTLY_WORKING  IS NOT NULL
					AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
				THEN CASE 
						WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%FULL%'
						THEN 40
						WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND D12.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%36%'
						THEN 28
						WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND D12.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%19%'
						THEN 14.5
						WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%'
							AND D12.CLIENT_WORKING_1_CURRENTLY_WORKING_HRS LIKE '%LESS%'
						THEN 5
						WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING = 'No'
						THEN 0
					END	
			END) [Currently Working Hours 12Mos]

		,CASE
			WHEN ISNULL(MAX(
						CASE
							WHEN DIN.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
							THEN 1
						END),0) = 1
				AND ISNULL(MAX(
							CASE
								WHEN D12.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
								THEN 1
							END),0) = 1
			THEN 1
		 END [Childcare Q Intake and 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%' 
						AND DIN.CLIENT_PROVIDE_CHILDCARE <> 'None'
					THEN 1
				END),0) [Childcare Intake]
		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%' 
					AND DIN.CLIENT_PROVIDE_CHILDCARE IS NOT NULL
				THEN CASE 
						WHEN DIN.CLIENT_PROVIDE_CHILDCARE LIKE '%more%'
						THEN 30
						WHEN DIN.CLIENT_PROVIDE_CHILDCARE LIKE '%20%'
						THEN 25
						WHEN DIN.CLIENT_PROVIDE_CHILDCARE LIKE '%19%'
						THEN 14.5
						WHEN DIN.CLIENT_PROVIDE_CHILDCARE LIKE '%LESS%'
						THEN 5
						WHEN DIN.CLIENT_PROVIDE_CHILDCARE = 'None'
						THEN 0
					END	
			END) [Childcare Hours Intake]
		,ISNULL(MAX(
				CASE
					WHEN DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%' 
						AND D12.CLIENT_PROVIDE_CHILDCARE <> 'None'
						AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					THEN 1
				END),0) [Childcare 12Mos]
		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%' 
					AND D12.CLIENT_PROVIDE_CHILDCARE IS NOT NULL
					AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
				THEN CASE 
						WHEN D12.CLIENT_PROVIDE_CHILDCARE LIKE '%more%'
						THEN 30
						WHEN D12.CLIENT_PROVIDE_CHILDCARE LIKE '%20%'
						THEN 25
						WHEN D12.CLIENT_PROVIDE_CHILDCARE LIKE '%19%'
						THEN 14.5
						WHEN D12.CLIENT_PROVIDE_CHILDCARE LIKE '%LESS%'
						THEN 5
						WHEN D12.CLIENT_PROVIDE_CHILDCARE = 'None'
						THEN 0
					END	
			END) [Childcare Hours 12Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [No Diploma Intake]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND DIN.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'NO'
				THEN C.Client_ID
			END) [No Diploma Not in School Intake]

	,COUNT(DISTINCT
			CASE
				WHEN DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%'
					AND DIN.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NULL
				THEN C.Client_ID
			END) [No Diploma Missing Intake]	
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (D12.CLIENT_EDUCATION_0_HS_GED IS NOT NULL)
				THEN C.Client_ID
			END) [Education Question Answered 12 Mos]	
			
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (D12.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma 12 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
					AND DIN.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes'
					AND (
							D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
							OR D12.CLIENT_ED_PROG_TYPE IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP IS NOT NULL
						)
				THEN C.Client_ID
			END) [Completed Diploma in School Intake]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
					AND D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'Yes'
					AND (
							D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
							OR D12.CLIENT_ED_PROG_TYPE IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP IS NOT NULL
						)
				THEN C.Client_ID
			END) [Completed Diploma in School 12Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
					AND (
							D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
							OR D12.CLIENT_ED_PROG_TYPE IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP IS NOT NULL
						)
				THEN C.Client_ID
			END) [Completed Diploma Intake Answered Enrollment Q]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%No%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND DIN.CLIENT_SCHOOL_MIDDLE_HS LIKE '%Yes%'
					AND D12.CLIENT_SCHOOL_MIDDLE_HS IS NOT NULL
				THEN C.Client_ID
			END) [No Diploma in School Intake]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%No%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_SCHOOL_MIDDLE_HS LIKE '%Yes%'
					AND DIN.CLIENT_SCHOOL_MIDDLE_HS IS NOT NULL
				THEN C.Client_ID
			END) [No Diploma in School 12Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%No%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_SCHOOL_MIDDLE_HS IS NOT NULL
				THEN C.Client_ID
			END) [No Diploma Intake Answered Enrollment Q]

	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
					AND (
							DIN.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR DIN.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
						)
					AND (
							D12.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
						)
				THEN C.Client_ID
			END) [Completed Diploma Intake Answered Hours Q]		

		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%INTAKE%' 
					AND (
							DIN.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR DIN.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
						)
				THEN CASE 
						WHEN DIN.CLIENT_EDUCATION_1_ENROLLED_FTPT LIKE '%FULL%'
						THEN 12
						WHEN DIN.CLIENT_EDUCATION_1_ENROLLED_PT_HRS LIKE '%11%'
						THEN 9
						WHEN DIN.CLIENT_EDUCATION_1_ENROLLED_PT_HRS LIKE '%6%'
						THEN 3
						WHEN DIN.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'No'
						THEN 0
					END	
			END) [Education Hours Intake]
		,AVG(
			CASE
				WHEN DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%12%' 
					AND (
							D12.CLIENT_EDUCATION_1_ENROLLED_FTPT IS NOT NULL
							OR D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS IS NOT NULL
						)
				THEN CASE 
						WHEN D12.CLIENT_EDUCATION_1_ENROLLED_FTPT LIKE '%FULL%'
						THEN 12
						WHEN D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS LIKE '%11%'
						THEN 9
						WHEN D12.CLIENT_EDUCATION_1_ENROLLED_PT_HRS LIKE '%6%'
						THEN 3
						WHEN D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'No'
						THEN 0
					END	
			END) [Education Hours 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN GSIN.CL_EN_GEN_ID IS NOT NULL
						AND GS12.CL_EN_GEN_ID IS NOT NULL
					THEN 1
				END),0) [Use Gvt Svcs Intake and 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN GS12.CL_EN_GEN_ID IS NOT NULL
					THEN 1
				END),0) [Use Gvt Svcs 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN GSin.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5) 
						OR GSin.SERVICE_USE_0_SCHIP_CLIENT IN (2,5) 
						OR GSin.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5) 
						OR GSin.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5) 
					THEN 1
				END),0) [Client with Health Insurance Intake]
		,ISNULL(MAX(
				CASE
					WHEN GS12.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5) 
						OR GS12.SERVICE_USE_0_SCHIP_CLIENT IN (2,5) 
						OR GS12.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5) 
						OR GS12.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5) 
					THEN 1
				END),0) [Client with Health Insurance 12Mos]
		,ISNULL(MAX(
				CASE
					WHEN GS12.SERVICE_USE_0_MEDICAID_CHILD IN (2,5) 
						OR GS12.SERVICE_USE_0_SCHIP_CHILD IN (2,5) 
						OR GS12.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5) 
						OR GS12.[SERVICE_USE_MILITARY_INS_CHILD] IN (2,5) 
					THEN 1
				END),0) [Child with Health Insurance 12Mos]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_SCREENED_SRVCS = 'Yes'
					OR AES.CLIENT_SCREENED_SRVCS = 'Yes'
					OR HVES.CLIENT_NO_REFERRAL = 'No referral needed'
					OR AES.CLIENT_NO_REFERRAL = 'No referral needed'
				THEN 1
		 END),0) [Families screened for need]
,ISNULL(MAX(CASE
				WHEN (
						HVES.CLIENT_SCREENED_SRVCS = 'Yes'
						OR AES.CLIENT_SCREENED_SRVCS = 'Yes'
					 )
					AND (
						RSS.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL
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
							OR RSS.[SERVICE_REFER_0_PCP_R2] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_SCHIP] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_SMOKE] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_TANF] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL
							OR RSS.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL
							OR RSS.[SERVICE_REFER_INDIAN_HEALTH] IS NOT NULL
							OR RSS.[SERVICE_REFER_MILITARY_INS] IS NOT NULL
						)
				THEN 1
		 END),0) [Families with need]
		,ISNULL(MAX(CASE
				WHEN HVES.CLIENT_SCREENED_SRVCS IS NOT NULL
					OR AES.CLIENT_SCREENED_SRVCS IS NOT NULL
				THEN 1
		 END),0) [Families screened Question]
		 ,1 [Families in NFP]
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
			WHEN GCSS.[SERVICE_USE_0_ADOPTION_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_ADOPTION IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_ADOPTION] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_ALCOHOL_ABUSE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_ALCOHOL_ABUSE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_BIRTH_EDUC_CLASS IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_BIRTH_EDUC_CLASS] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_CHARITY_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_CHARITY IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_CHARITY] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_CHILD_CARE_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_CHILD_CARE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_CARE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_CHILD_SUPPORT IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_SUPPORT] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_CPS_CHILD]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_CPS_CLIENT]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_CPS IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_CPS] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_DENTAL_CHILD]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_DENTAL_CLIENT]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_DENTAL IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_DENTAL] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_DEVELOPMENTAL_DISABILITY] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_DRUG_ABUSE_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_DRUG_ABUSE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_DRUG_ABUSE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_FOODSTAMP_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_FOODSTAMP IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_FOODSTAMP] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_GED_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_GED IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_GED] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_HIGHER_EDUC_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_HIGHER_EDUC IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_HIGHER_EDUC] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_HOUSING_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_HOUSING IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_HOUSING] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_INTERVENTION]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_INTERVENTION IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_INTERVENTION] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_IPV_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_IPV IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_IPV] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_JOB_TRAINING_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_JOB_TRAINING IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_JOB_TRAINING] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_LACTATION_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_LACTATION IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_LACTATION] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_LEGAL_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_LEGAL_CLIENT IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_LEGAL] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_MEDICAID_CHILD]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_MEDICAID_CLIENT]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_MEDICAID IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate			
			 THEN 1
		   END),0) [SERVICE_USE_0_MEDICAID] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_MENTAL_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_MENTAL IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_MENTAL] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_OTHER1]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_CHILD_OTHER1]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_OTHER3]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_CHILD_OTHER3]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_OTHER2]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_CHILD_OTHER2]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_OTHER IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_OTHER1] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_PATERNITY_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_PATERNITY IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_PATERNITY] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_PCP_CLIENT]  IN (2,5)
				AND (RSS2.SERVICE_REFER_0_PCP IS NOT NULL OR RSS2.SERVICE_REFER_0_PCP_R2 IS NOT NULL)
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_PCP_SICK_CLIENT] 
		,ISNULL(MAX(CASE
			WHEN  GCSS.[SERVICE_USE_0_PCP_SICK_CHILD]  IN (2,5)
				AND (RSS2.SERVICE_REFER_0_PCP IS NOT NULL OR RSS2.SERVICE_REFER_0_PCP_R2 IS NOT NULL)
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_PCP_SICK_CHILD] 
		,ISNULL(MAX(CASE
			WHEN  GCSS.[SERVICE_USE_0_PCP_WELL_CHILD]  IN (2,5)
				AND (RSS2.SERVICE_REFER_0_PCP IS NOT NULL OR RSS2.SERVICE_REFER_0_PCP_R2 IS NOT NULL)
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_PCP_WELL_CHILD] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_PCP_WELL_CLIENT]  IN (2,5)
				AND (RSS2.SERVICE_REFER_0_PCP IS NOT NULL OR RSS2.SERVICE_REFER_0_PCP_R2 IS NOT NULL)
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_PCP_WELL_CLIENT] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_PREVENT_INJURY_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_PREVENT_INJURY IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_PREVENT_INJURY] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_PRIVATE_INSURANCE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_PRIVATE_INSURANCE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_RELATIONSHIP_COUNSELING IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_RELATIONSHIP_COUNSELING] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_SCHIP_CHILD]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_SCHIP IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_SCHIP] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_SMOKE_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_SMOKE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_SMOKE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_SOCIAL_SECURITY IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_SOCIAL_SECURITY] 
		,ISNULL(MAX(CASE
			WHEN (GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]  IN (2,5)
			 OR GCSS.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]  IN (2,5))
				AND RSS2.SERVICE_REFER_0_SPECIAL_NEEDS IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			 THEN 1
		   END),0) [SERVICE_USE_0_SPECIAL_NEEDS] 

		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_SUBSID_CHILD_CARE IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_SUBSID_CARE] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_TANF_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_TANF IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_TANF] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_TRANSPORTATION_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_TRANSPORTATION IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_TRANSPORTATION] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_UNEMPLOYMENT IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_UNEMPLOYMENT] 
		,ISNULL(MAX(CASE
			WHEN GCSS.[SERVICE_USE_0_WIC_CLIENT]  IN (2,5)
				AND RSS2.SERVICE_REFER_0_WIC_CLIENT IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_0_WIC] 
		,ISNULL(MAX(CASE
			WHEN (
					GCSS.SERVICE_USE_MILITARY_INS_CHILD  IN (2,5)
					OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ]  IN (2,5)
				)
				AND RSS2.SERVICE_REFER_MILITARY_INS IS NOT NULL
				AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			THEN 1
		   END),0) [SERVICE_USE_MILITARY_INS]
 
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_TANF] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for TANF]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERIVCE_REFER_0_OTHER1_DESC] IS NOT NULL 
				OR RSS2.[SERIVCE_REFER_0_OTHER2_DESC] IS NOT NULL  
				OR RSS2.[SERIVCE_REFER_0_OTHER3_DESC] IS NOT NULL 
				OR RSS2.[SERVICE_REFER_0_OTHER] IS NOT NULL      AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for OTHER]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_ADOPTION] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for ADOPTION]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_ALCOHOL_ABUSE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for ALCOHOL_ABUSE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_BIRTH_EDUC_CLASS] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for BIRTH_EDUC_CLASS]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_CHARITY] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for CHARITY]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_CHILD_CARE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for CHILD_CARE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_CHILD_SUPPORT] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for CHILD_SUPPORT]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_CPS] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for CPS]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_DENTAL] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for DENTAL]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for DEVELOPMENTAL_DISABILITY]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_DRUG_ABUSE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for DRUG_ABUSE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_FOODSTAMP] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for FOODSTAMP]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_GED] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for GED]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_HIGHER_EDUC] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for HIGHER_EDUC]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_HOUSING] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for HOUSING]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_INTERVENTION] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for INTERVENTION]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_IPV] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for IPV]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_JOB_TRAINING] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for JOB_TRAINING]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_LACTATION] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for LACTATION]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_LEGAL_CLIENT] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for LEGAL_CLIENT]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_MEDICAID] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for MEDICAID]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_MENTAL] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for MENTAL]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PATERNITY] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PATERNITY]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PCP] LIKE '%Child - sick%' 
				OR RSS2.[SERVICE_REFER_0_PCP] LIKE '%Child – sick%'     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PCP_SICK_CHILD]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PCP] LIKE '%Child - well%' 
				OR RSS2.[SERVICE_REFER_0_PCP] LIKE '%Child – well%'     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PCP_WELL_CHILD]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PCP] LIKE 'Client - well%'
				OR RSS2.[SERVICE_REFER_0_PCP] LIKE '%CLIENT;%' 
				OR RSS2.[SERVICE_REFER_0_PCP] = 'Client' AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PCP_WELL_CLIENT]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PCP] LIKE 'Client - sick'     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PCP_SICK_CLIENT]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PREVENT_INJURY] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PREVENT_INJURY]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_PRIVATE_INSURANCE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for PRIVATE_INSURANCE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for RELATIONSHIP_COUNSELING]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_SCHIP] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for SCHIP]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_SMOKE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for SMOKE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_SOCIAL_SECURITY] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for SOCIAL_SECURITY]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_SPECIAL_NEEDS] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for SPECIAL_NEEDS]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_SUBSID_CHILD_CARE] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for SUBSID_CHILD_CARE]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_TRANSPORTATION] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for TRANSPORTATION]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_UNEMPLOYMENT] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for UNEMPLOYMENT]
		,ISNULL(MAX(CASE
			WHEN RSS2.[SERVICE_REFER_0_WIC_CLIENT] IS NOT NULL     AND RSS2.SurveyDate < = GCSS.SurveyDate AND Datawarehouse.dbo.fngetformname(GCSS.SurveyID) NOT LIKE '%INTAKE%' AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate THEN 1
		   END),0) [Referral for WIC_CLIENT] 
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
		LEFT JOIN DataWarehouse..Health_Habits_Survey HHS
			ON HHS.CL_EN_GEN_ID = EAD.CLID
			AND HHS.ProgramID = EAD.ProgramID
			AND HHS.SurveyDate < = @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_H
		--	ON MS_H.SurveyID = HHS.SurveyID
		LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GCSS
			ON GCSS.CL_EN_GEN_ID = EAD.CLID
			AND GCSS.ProgramID = EAD.ProgramID
			AND GCSS.SurveyDate < = @QuarterDate
			--AND DataWarehouse.dbo.fnGetFormName(GCSS.SurveyID) NOT LIKE '%INTAKE%'
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_G
		--	ON MS_G.SurveyID = GCSS.SurveyID
		LEFT JOIN DataWarehouse..Demographics_Survey DS
			ON DS.CL_EN_GEN_ID = EAD.CLID
			AND DS.ProgramID = EAD.ProgramID
			AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_D
		--	ON dbo.fngetFormName(DS.SurveyID) = DS.SurveyID
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
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
		--	ON MS_IHS.SurveyID = IHS.SurveyID
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS2
			ON IHS2.CL_EN_GEN_ID = EAD.CLID
			AND IHS2.ProgramID = EAD.ProgramID
			AND IHS2.SurveyDate < = @QuarterDate
			AND dbo.fnGetFormName(IHS2.SurveyID) LIKE '%INFANT%6%'
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
		LEFT JOIN DataWarehouse..Referrals_to_Services_Survey RSS2
			ON RSS2.CL_EN_GEN_ID = EAD.CLID
			AND RSS2.SurveyDate < = @QuarterDate
			AND RSS2.SurveyDate < = GCSS.SurveyDate
		LEFT JOIN DataWarehouse..Relationship_Survey RS
			ON RS.CL_EN_GEN_ID = EAD.CLID
			AND RS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_RS
		--	ON MS_RS.SurveyID = RS.SurveyID
		LEFT JOIN DataWarehouse..UV_EDD EDD
			ON EDD.CaseNumber = EAD.CaseNumber
	LEFT JOIN DataWarehouse..Demographics_Survey D12
		ON D12.CL_EN_GEN_ID = EAD.CLID
		AND D12.ProgramID = EAD.ProgramID
		AND D12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%DEMOGRAP%12%'
	LEFT JOIN DataWarehouse..Demographics_Survey DIN
		ON DIN.CL_EN_GEN_ID = EAD.CLID
		AND DIN.SurveyDate < = @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID)  LIKE '%DEMOGRAP%Intake%'
	LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GSIN
		ON GSIN.CL_EN_GEN_ID = EAD.CLID
		AND GSIN.ProgramID = EAD.ProgramID
		AND GSIN.SurveyDate < = @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(GSIN.SurveyID) LIKE '%INTAKE%'
	LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GS12
		ON GS12.CL_EN_GEN_ID = EAD.CLID
		AND GS12.ProgramID = EAD.ProgramID
		AND GS12.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(GS12.SurveyID) LIKE '%12%'
													
			
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
		
--OPTION(RECOMPILE)
END

GO
