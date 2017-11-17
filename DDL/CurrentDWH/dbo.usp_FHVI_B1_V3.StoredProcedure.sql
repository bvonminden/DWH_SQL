USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B1_V3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B1_V3]
	-- Add the parameters for the stored procedure here
	@Site VARCHAR(50),@Quarter INT, @QuarterYear INT,@ReportType INT
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
--	-- interfering with SELECT statements.

--declare
--@Site VARCHAR(50),@Quarter INT, @QuarterYear INT,@ReportType INT
--set @Site = '358'
--set @Quarter = 4
--set @QuarterYear = 2013
--set @ReportType = 3


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
			WHEN CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL] IS NOT NULL
				--OR DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) = 'NJ'
				THEN 1
		 END),0) Tribal
		,ISNULL(MAX(CASE 
			WHEN DS.CL_EN_GEN_ID IS NOT NULL THEN 1
		 END),0) [Demographics Assessment Y/N]
		,ISNULL(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE < 13
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL <= @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate
				THEN '1st Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE BETWEEN 13 AND 27.99
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL <= @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate
				THEN '2nd Trimester'
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE >= 28 
				--AND MAX(MHS.SurveyDate) <= @QuarterDate
				AND (
						CFS.CLIENT_FUNDING_1_START_MIECHVP_COM  <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM  <= @QuarterDate
						OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL <= @QuarterDate
					)
						AND (
								ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,GETDATE()) >= @QuarterStart
								AND ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,GETDATE()) >= @QuarterStart
							)
				AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate
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
		,MAX(CASE
			WHEN MHS.CLIENT_HEALTH_PREGNANCY_0_EDD >= @QuarterDate
				AND ISNULL(ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_COM,ISNULL(CFS.CLIENT_FUNDING_1_END_MIECHVP_FORM,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL)),GETDATE()) > = @QuarterDate
			THEN 40 - (DATEDIFF(DAY,@QuarterDate,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD)/7)
		 END) [Gest age at end of quarter]
		,CASE
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) < 10
			THEN 1
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 10 AND 13.99
			THEN 2
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 14 AND 17.99
			THEN 3
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 18 AND 21.99
			THEN 4
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 22 AND 25.99
			THEN 5
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 26 AND 29.99
			THEN 6
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 30 AND 32.99
			THEN 7
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 33 AND 35.99
			THEN 8
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 36 AND 36.99
			THEN 9
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 37 AND 37.99
			THEN 10
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 38 AND 38.99
			THEN 11
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 39 AND 39.99
			THEN 12
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) BETWEEN 40 AND 40.99
			THEN 13
			WHEN MAX(CASE
					WHEN ((IBS.INFANT_BIRTH_0_DOB) IS NULL OR (IBS.INFANT_BIRTH_0_DOB) > @QuarterStart) AND HVES.CLIENT_PRENATAL_VISITS = 'Yes'
					THEN 40 - ABS((DATEDIFF(DAY,EDD.EDD,@QuarterDate)/7))
				 END) > = 41
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
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(ES.SurveyID) LIKE '%Preg%36%' THEN 1
				END
			  ),0) [Depression Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN ES.CL_EN_GEN_ID IS NOT NULL
						AND ((dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') THEN 1
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
						AND ((dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(ES.SurveyID) LIKE '%Inf%1%4%') THEN ES.CLIENT_EPS_TOTAL_SCORE
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
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%3-5 days after birth%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%By 1 month old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%2 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%4 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END),0) [Completed well child 6 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%6 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%9 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END
			  ),0) [Completed well child 12 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%12 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%15 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END
			  ),0) [Completed well child 18 mos]
		,ISNULL(MAX( 
				CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%18 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%24 months old%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
				END + CASE
					WHEN IHS.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2 LIKE '%24 month visit scheduled%'
						AND IHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
						THEN 1 ELSE 0
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
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN 1
				END
			  ),0) [PHQ-9 Survey Taken at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND ((dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN 1
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

		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
				END
			  ),0) [PHQ-9 Score at 36 Weeks]
		,ISNULL(MAX( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND ((dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
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
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_D
		--	ON dbo.fngetFormName(DS.SurveyID)= DS.SurveyID
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
		LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
			ON HVES.CL_EN_GEN_ID = EAD.CLID
			AND HVES.SurveyDate BETWEEN @QuarterStart AND CASE
																WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
																THEN @QuarterDate
																ELSE IBS.INFANT_BIRTH_0_DOB
															END
															
			
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
		,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
		,PAS.StateID
		,EAD.ProgramStartDate
)

SELECT
	F.Trimester
	,F.CaseNumber
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
---------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Prenatal Question] > 0
	--	THEN F.[Prenatal Care Y/N]
	--	ELSE 0
	--END,0) NC_11
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Prenatal Question] > 0
	--	THEN F.[Prenatal Care Y/N]
	--	ELSE 0
	--END,0) NF_11
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Prenatal Question] > 0 THEN F.[Prenatal Care Y/N]
	--	ELSE 0
	--END,0) NFC_11
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Prenatal Question] > 0 THEN F.[Prenatal Care Y/N]
	--	ELSE 0
	--END,0) NN_11
	,ISNULL(CASE WHEN F.[Answered Prenatal Question] > 0 THEN F.[Prenatal Care Y/N] END,0) NT_11
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Prenatal Question]
	--	ELSE 0
	--END,0) DC_11
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Prenatal Question]
	--	ELSE 0
	--END,0) DF_11
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Prenatal Question]
	--	ELSE 0
	--END,0) DFC_11
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Prenatal Question]
	--	ELSE 0
	--END,0) DN_11
	,ISNULL( F.[Answered Prenatal Question],0) DT_11

---------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Expected Visits] > 0
	--	THEN F.[Prenatal Visits]
	--	ELSE 0
	--END,0) NC_11_2
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Expected Visits] > 0
	--	THEN F.[Prenatal Visits]
	--	ELSE 0
	--END,0) NF_11_2
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Expected Visits] > 0 THEN F.[Prenatal Visits]
	--	ELSE 0
	--END,0) NFC_11_2
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Expected Visits] > 0 THEN F.[Prenatal Visits]
	--	ELSE 0
	--END,0) NN_11_2
	,ISNULL(CASE WHEN F.[Expected Visits] > 0 THEN F.[Prenatal Visits] END,0) NT_11_2
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Expected Visits]
	--	ELSE 0
	--END,0) DC_11_2
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Expected Visits]
	--	ELSE 0
	--END,0) DF_11_2
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Expected Visits]
	--	ELSE 0
	--END,0) DFC_11_2
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected Visits]
	--	ELSE 0
	--END,0) DN_11_2
	,ISNULL( F.[Expected Visits],0) DT_11_2

----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Alcohol use at Intake] > 0 AND F.[Alcohol use at 36 Weeks] IS NOT NULL
	--	THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) NC_12A
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Alcohol use at Intake] > 0 AND F.[Alcohol use at 36 Weeks] IS NOT NULL
	--	THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) NF_12A
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Alcohol use at Intake] > 0 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) NFC_12A
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Alcohol use at Intake] > 0 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) NN_12A
	,ISNULL(CASE WHEN F.[Alcohol use at Intake] > 0 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at 36 Weeks] - F.[Alcohol use at Intake] END,0) NT_12A
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) DC_12A
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) DF_12A
	--,ISNULL(CASE
	--	WHEN ((F.Competitive = 1 OR F.Formula = 1)) AND F.[Alcohol use at 36 Weeks] IS NOT NULL  THEN F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) DFC_12A
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Alcohol use at 36 Weeks] IS NOT NULL THEN F.[Alcohol use at Intake]
	--	ELSE 0
	--END,0) DN_12A
	,ISNULL(CASE 
		WHEN  F.[Alcohol use at 36 Weeks] IS NOT NULL 
		THEN F.[Alcohol use at Intake] 
		ELSE 0
	END,0) DT_12A
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Tobacco use at Intake] > 0 AND F.[Tobacco use at 36 Weeks] IS NOT NULL
	--	THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) NC_12T
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Tobacco use at Intake] > 0 AND F.[Tobacco use at 36 Weeks] IS NOT NULL
	--	THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) NF_12T
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Tobacco use at Intake] > 0 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) NFC_12T
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Tobacco use at Intake] > 0 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) NN_12T
	,ISNULL(CASE WHEN F.[Tobacco use at Intake] > 0 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at 36 Weeks] - F.[Tobacco use at Intake] END,0) NT_12T
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) DC_12T
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) DF_12T
	--,ISNULL(CASE
	--	WHEN ((F.Competitive = 1 OR F.Formula = 1)) AND F.[Tobacco use at 36 Weeks] IS NOT NULL  THEN F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) DFC_12T
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Tobacco use at 36 Weeks] IS NOT NULL THEN F.[Tobacco use at Intake]
	--	ELSE 0
	--END,0) DN_12T
	,ISNULL(CASE 
		WHEN  F.[Tobacco use at 36 Weeks] IS NOT NULL 
		THEN F.[Tobacco use at Intake] 
		ELSE 0
	END,0) DT_12T
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Illicit Drug use at Intake] > 0 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL
	--	THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) NC_12I
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Illicit Drug use at Intake] > 0 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL
	--	THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) NF_12I
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Illicit Drug use at Intake] > 0 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) NFC_12I
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Illicit Drug use at Intake] > 0 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) NN_12I
	,ISNULL(CASE WHEN F.[Illicit Drug use at Intake] > 0 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at 36 Weeks] - F.[Illicit Drug use at Intake] END,0) NT_12I
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) DC_12I
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) DF_12I
	--,ISNULL(CASE
	--	WHEN ((F.Competitive = 1 OR F.Formula = 1)) AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL  THEN F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) DFC_12I
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1  AND F.[Illicit Drug use at 36 Weeks] IS NOT NULL THEN F.[Illicit Drug use at Intake]
	--	ELSE 0
	--END,0) DN_12I
	,ISNULL(CASE 
		WHEN  F.[Illicit Drug use at 36 Weeks] IS NOT NULL 
		THEN F.[Illicit Drug use at Intake] 
		ELSE 0
	END,0) DT_12I
----------------------------------------
--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Active During Quarter] > 0
--		THEN F.[Health Habits Assessment Y/N]
--		ELSE 0
--	END,0) NC_12S
--	,ISNULL(CASE WHEN F.Formula = 1 AND F.[Active During Quarter] > 0
--		THEN F.[Health Habits Assessment Y/N]
--		ELSE 0
--	END,0) NF_12S
--	,ISNULL(CASE
--		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Active During Quarter] > 0 THEN F.[Health Habits Assessment Y/N]
--		ELSE 0
--	END,0) NFC_12S
--	,ISNULL(CASE 
--		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Active During Quarter] > 0 THEN F.[Health Habits Assessment Y/N]
--		ELSE 0
--	END,0) NN_12S
	,ISNULL(CASE WHEN F.[Active During Quarter] > 0 THEN F.[Health Habits Assessment Y/N] END,0) NT_12S
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 THEN F.[Active During Quarter]
	--	ELSE 0
	--END,0) DC_12S
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Active During Quarter]
	--	ELSE 0
	--END,0) DF_12S
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Active During Quarter]
	--	ELSE 0
	--END,0) DFC_12S
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Active During Quarter]
	--	ELSE 0
	--END,0) DN_12S
	,ISNULL( F.[Active During Quarter],0) DT_12S
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Pregnancy since 1st child] > 0
	--	THEN F.[Well Woman Care]
	--	ELSE 0
	--END,0) NC_13A
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Pregnancy since 1st child] > 0
	--	THEN F.[Well Woman Care]
	--	ELSE 0
	--END,0) NF_13A
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Pregnancy since 1st child] > 0 THEN F.[Well Woman Care]
	--	ELSE 0
	--END,0) NFC_13A
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Pregnancy since 1st child] > 0 THEN F.[Well Woman Care]
	--	ELSE 0
	--END,0) NN_13A
	,ISNULL(CASE WHEN F.[Pregnancy since 1st child] > 0 THEN F.[Well Woman Care] END,0) NT_13A
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Pregnancy since 1st child]
	--	ELSE 0
	--END,0) DC_13A
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Pregnancy since 1st child]
	--	ELSE 0
	--END,0) DF_13A
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Pregnancy since 1st child]
	--	ELSE 0
	--END,0) DFC_13A
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy since 1st child]
	--	ELSE 0
	--END,0) DN_13A
	,ISNULL( F.[Pregnancy since 1st child],0) DT_13A
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Pregnancy at 6 Mos] > 0
	--	THEN F.[Well Woman Care 6 mos]
	--	ELSE 0
	--END,0) NC_136
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Pregnancy at 6 Mos] > 0
	--	THEN F.[Well Woman Care 6 mos]
	--	ELSE 0
	--END,0) NF_136
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Pregnancy at 6 Mos] > 0 THEN F.[Well Woman Care 6 mos]
	--	ELSE 0
	--END,0) NFC_136
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Pregnancy at 6 Mos] > 0 THEN F.[Well Woman Care 6 mos]
	--	ELSE 0
	--END,0) NN_136
	,ISNULL(CASE WHEN F.[Pregnancy at 6 Mos] > 0 THEN F.[Well Woman Care 6 mos] END,0) NT_136
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) DC_136
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) DF_136
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) DFC_136
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) DN_136
	,ISNULL( F.[Pregnancy at 6 Mos],0) DT_136
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Pregnancy at 12 Mos] > 0
	--	THEN F.[Well Woman Care 12 mos]
	--	ELSE 0
	--END,0) NC_1312
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Pregnancy at 12 Mos] > 0
	--	THEN F.[Well Woman Care 12 mos]
	--	ELSE 0
	--END,0) NF_1312
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Pregnancy at 12 Mos] > 0 THEN F.[Well Woman Care 12 mos]
	--	ELSE 0
	--END,0) NFC_1312
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Pregnancy at 12 Mos] > 0 THEN F.[Well Woman Care 12 mos]
	--	ELSE 0
	--END,0) NN_1312
	,ISNULL(CASE WHEN F.[Pregnancy at 12 Mos] > 0 THEN F.[Well Woman Care 12 mos] END,0) NT_1312
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) DC_1312
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) DF_1312
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) DFC_1312
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) DN_1312
	,ISNULL( F.[Pregnancy at 12 Mos],0) DT_1312
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Pregnancy at 18 Mos] > 0
	--	THEN F.[Well Woman Care 18 mos]
	--	ELSE 0
	--END,0) NC_1318
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Pregnancy at 18 Mos] > 0
	--	THEN F.[Well Woman Care 18 mos]
	--	ELSE 0
	--END,0) NF_1318
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Pregnancy at 18 Mos] > 0 THEN F.[Well Woman Care 18 mos]
	--	ELSE 0
	--END,0) NFC_1318
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Pregnancy at 18 Mos] > 0 THEN F.[Well Woman Care 18 mos]
	--	ELSE 0
	--END,0) NN_1318
	,ISNULL(CASE WHEN F.[Pregnancy at 18 Mos] > 0 THEN F.[Well Woman Care 18 mos] END,0) NT_1318
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) DC_1318
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) DF_1318
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) DFC_1318
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) DN_1318
	,ISNULL( F.[Pregnancy at 18 Mos],0) DT_1318
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Pregnancy at 24 Mos] > 0
	--	THEN F.[Well Woman Care 24 mos]
	--	ELSE 0
	--END,0) NC_1324
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Pregnancy at 24 Mos] > 0
	--	THEN F.[Well Woman Care 24 mos]
	--	ELSE 0
	--END,0) NF_1324
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Pregnancy at 24 Mos] > 0 THEN F.[Well Woman Care 24 mos]
	--	ELSE 0
	--END,0) NFC_1324
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Pregnancy at 24 Mos] > 0 THEN F.[Well Woman Care 24 mos]
	--	ELSE 0
	--END,0) NN_1324
	,ISNULL(CASE WHEN F.[Pregnancy at 24 Mos] > 0 THEN F.[Well Woman Care 24 mos] END,0) NT_1324
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) DC_1324
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) DF_1324
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) DFC_1324
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) DN_1324
	,ISNULL( F.[Pregnancy at 24 Mos],0) DT_1324
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Subseq Preg Question - 6 Months] > 0
	--	THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) NC_146
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Subseq Preg Question - 6 Months] > 0
	--	THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) NF_146
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Subseq Preg Question - 6 Months] > 0 THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) NFC_146
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Subseq Preg Question - 6 Months] > 0 THEN F.[Pregnancy at 6 Mos]
	--	ELSE 0
	--END,0) NN_146
	,ISNULL(CASE WHEN F.[Subseq Preg Question - 6 Months] > 0 THEN F.[Pregnancy at 6 Mos] END,0) NT_146
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Subseq Preg Question - 6 Months]
	--	ELSE 0
	--END,0) DC_146
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Subseq Preg Question - 6 Months]
	--	ELSE 0
	--END,0) DF_146
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Subseq Preg Question - 6 Months]
	--	ELSE 0
	--END,0) DFC_146
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 6 Months]
	--	ELSE 0
	--END,0) DN_146
	,ISNULL( F.[Subseq Preg Question - 6 Months],0) DT_146
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Subseq Preg Question - 12 Months] > 0
	--	THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) NC_1412
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Subseq Preg Question - 12 Months] > 0
	--	THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) NF_1412
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Subseq Preg Question - 12 Months] > 0 THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) NFC_1412
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Subseq Preg Question - 12 Months] > 0 THEN F.[Pregnancy at 12 Mos]
	--	ELSE 0
	--END,0) NN_1412
	,ISNULL(CASE WHEN F.[Subseq Preg Question - 12 Months] > 0 THEN F.[Pregnancy at 12 Mos] END,0) NT_1412
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Subseq Preg Question - 12 Months]
	--	ELSE 0
	--END,0) DC_1412
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Subseq Preg Question - 12 Months]
	--	ELSE 0
	--END,0) DF_1412
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Subseq Preg Question - 12 Months]
	--	ELSE 0
	--END,0) DFC_1412
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 12 Months]
	--	ELSE 0
	--END,0) DN_1412
	,ISNULL( F.[Subseq Preg Question - 12 Months],0) DT_1412
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Subseq Preg Question - 18 Months] > 0
	--	THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) NC_1418
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Subseq Preg Question - 18 Months] > 0
	--	THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) NF_1418
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Subseq Preg Question - 18 Months] > 0 THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) NFC_1418
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Subseq Preg Question - 18 Months] > 0 THEN F.[Pregnancy at 18 Mos]
	--	ELSE 0
	--END,0) NN_1418
	,ISNULL(CASE WHEN F.[Subseq Preg Question - 18 Months] > 0 THEN F.[Pregnancy at 18 Mos] END,0) NT_1418
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Subseq Preg Question - 18 Months]
	--	ELSE 0
	--END,0) DC_1418
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Subseq Preg Question - 18 Months]
	--	ELSE 0
	--END,0) DF_1418
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Subseq Preg Question - 18 Months]
	--	ELSE 0
	--END,0) DFC_1418
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 18 Months]
	--	ELSE 0
	--END,0) DN_1418
	,ISNULL( F.[Subseq Preg Question - 18 Months],0) DT_1418
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Subseq Preg Question - 24 Months] > 0
	--	THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) NC_1424
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Subseq Preg Question - 24 Months] > 0
	--	THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) NF_1424
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Subseq Preg Question - 24 Months] > 0 THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) NFC_1424
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Subseq Preg Question - 24 Months] > 0 THEN F.[Pregnancy at 24 Mos]
	--	ELSE 0
	--END,0) NN_1424
	,ISNULL(CASE WHEN F.[Subseq Preg Question - 24 Months] > 0 THEN F.[Pregnancy at 24 Mos] END,0) NT_1424
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Subseq Preg Question - 24 Months]
	--	ELSE 0
	--END,0) DC_1424
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Subseq Preg Question - 24 Months]
	--	ELSE 0
	--END,0) DF_1424
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Subseq Preg Question - 24 Months]
	--	ELSE 0
	--END,0) DFC_1424
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Subseq Preg Question - 24 Months]
	--	ELSE 0
	--END,0) DN_1424
	,ISNULL( F.[Subseq Preg Question - 24 Months],0) DT_1424
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NC_15E36
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NF_15E36
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NFC_15E36
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.Birth = 1 THEN F.[Depression Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NN_15E36
	,ISNULL(CASE F.Birth
		WHEN 1
		THEN F.[Depression Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15E36
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.Birth
	--	ELSE 0
	--END,0) DC_15E36
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.Birth
	--	ELSE 0
	--END,0) DF_15E36
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.Birth
	--	ELSE 0
	--END,0) DFC_15E36
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.Birth
	--	ELSE 0
	--END,0) DN_15E36
	,ISNULL( F.Birth,0) DT_15E36	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NC_15E14
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NF_15E14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NFC_15E14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NN_15E14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15E14
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DC_15E14
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DF_15E14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DFC_15E14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DN_15E14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15E14	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NC_15E46
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NF_15E46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NFC_15E46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NN_15E46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15E46
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DC_15E46
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DF_15E46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DFC_15E46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DN_15E46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15E46	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NC_15E12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NF_15E12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NFC_15E12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NN_15E12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15E12
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DC_15E12
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DF_15E12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DFC_15E12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DN_15E12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15E12	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NC_15P36
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NF_15P36
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NFC_15P36
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[PHQ-9 Survey Taken at 36 Weeks]
	--	ELSE 0
	--END,0) NN_15P36
	,ISNULL(CASE F.[36 Weeks Preg Y/N]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15P36
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DC_15P36
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DF_15P36
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DFC_15P36
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DN_15P36
	,ISNULL( F.[36 Weeks Preg Y/N],0) DT_15P36	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NC_15P14
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NF_15P14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NFC_15P14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NN_15P14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15P14
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DC_15P14
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DF_15P14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DFC_15P14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DN_15P14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15P14	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NC_15P46
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NF_15P46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NFC_15P46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NN_15P46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15P46
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DC_15P46
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DF_15P46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DFC_15P46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DN_15P46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15P46	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NC_15P12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NF_15P12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NFC_15P12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NN_15P12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15P12
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DC_15P12
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DF_15P12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DFC_15P12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DN_15P12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15P12	
----------------------------------------
--,ISNULL(CASE
--		WHEN F.Competitive = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
--		ELSE 0
--	END,0) NC_15EP36
--	,ISNULL(CASE 
--		WHEN F.Formula = 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
--		ELSE 0
--	END,0) NF_15EP36
--	,ISNULL(CASE
--		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
--		ELSE 0
--	END,0) NFC_15EP36
--	,ISNULL(CASE 
--		WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[36 Weeks Preg Y/N] = 1 THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
--		ELSE 0
--	END,0) NN_15EP36
	,ISNULL(CASE F.[36 Weeks Preg Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at 36 Weeks] + F.[PHQ-9 Survey Taken at 36 Weeks]
		ELSE 0
	END,0) NT_15EP36
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DC_15EP36
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DF_15EP36
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DFC_15EP36
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[36 Weeks Preg Y/N]
	--	ELSE 0
	--END,0) DN_15EP36
	,ISNULL( F.[36 Weeks Preg Y/N],0) DT_15EP36	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NC_15EP14
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NF_15EP14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NFC_15EP14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[1 - 8 Weeks Infancy Y/N] = 1 THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
	--	ELSE 0
	--END,0) NN_15EP14
	,ISNULL(CASE F.[1 - 8 Weeks Infancy Y/N]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 1-4 weeks] + F.[PHQ-9 Survey Taken at Infancy 1-4 weeks]
		ELSE 0
	END,0) NT_15EP14
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DC_15EP14
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DF_15EP14
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DFC_15EP14
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[1 - 8 Weeks Infancy Y/N]
	--	ELSE 0
	--END,0) DN_15EP14
	,ISNULL( F.[1 - 8 Weeks Infancy Y/N],0) DT_15EP14	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NC_15EP46
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NF_15EP46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NFC_15EP46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 6 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
	--	ELSE 0
	--END,0) NN_15EP46
	,ISNULL(CASE F.[Infant Health Survey 6 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 4-6 mos] + F.[PHQ-9 Survey Taken at Infancy 4-6 mos]
		ELSE 0
	END,0) NT_15EP46
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DC_15EP46
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DF_15EP46
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DFC_15EP46
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DN_15EP46
	,ISNULL( F.[Infant Health Survey 6 Mos],0) DT_15EP46	
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NC_15EP12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NF_15EP12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NFC_15EP12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Infant Health Survey 12 Mos] = 1 THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
	--	ELSE 0
	--END,0) NN_15EP12
	,ISNULL(CASE F.[Infant Health Survey 12 Mos]
		WHEN 1
		THEN F.[Depression Survey Taken at Infancy 12 mos] + F.[PHQ-9 Survey Taken at Infancy 12 mos]
		ELSE 0
	END,0) NT_15EP12
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DC_15EP12
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DF_15EP12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DFC_15EP12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos]
	--	ELSE 0
	--END,0) DN_15EP12
	,ISNULL( F.[Infant Health Survey 12 Mos],0) DT_15EP12
----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 
	--		AND (
	--				F.[PHQ-9 Score at 36 Weeks] >= 10 
	--				OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
	--				OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
	--				OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
	--				OR F.[Depression Score at 36 Weeks] >= 10
	--				OR F.[Depression Score at Infancy 1-4 weeks] >= 10
	--				OR F.[Depression Score at Infancy 12 mos] >= 10
	--				OR F.[Depression Score at Infancy 4-6 mos] >= 10
	--			)
	--			AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
	--	THEN 1
	--	ELSE 0
	--END,0) NC_15S10
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 
	--		AND (
	--				F.[PHQ-9 Score at 36 Weeks] >= 10 
	--				OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
	--				OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
	--				OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
	--				OR F.[Depression Score at 36 Weeks] >= 10
	--				OR F.[Depression Score at Infancy 1-4 weeks] >= 10
	--				OR F.[Depression Score at Infancy 12 mos] >= 10
	--				OR F.[Depression Score at Infancy 4-6 mos] >= 10
	--			)
	--			AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
	--	THEN 1
	--	ELSE 0
	--END,0) NF_15S10
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1)  
	--		AND (
	--				F.[PHQ-9 Score at 36 Weeks] >= 10 
	--				OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
	--				OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
	--				OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
	--				OR F.[Depression Score at 36 Weeks] >= 10
	--				OR F.[Depression Score at Infancy 1-4 weeks] >= 10
	--				OR F.[Depression Score at Infancy 12 mos] >= 10
	--				OR F.[Depression Score at Infancy 4-6 mos] >= 10
	--			)
	--			AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
	--	THEN 1
	--	ELSE 0
	--END,0) NFC_15S10
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1  
	--		AND (
	--				F.[PHQ-9 Score at 36 Weeks] >= 10 
	--				OR F.[PHQ-9 Score at Infancy 1-4 weeks] >= 10
	--				OR F.[PHQ-9 Score at Infancy 12 mos] >= 10
	--				OR F.[PHQ-9 Score at Infancy 4-6 mos] >= 10
	--				OR F.[Depression Score at 36 Weeks] >= 10
	--				OR F.[Depression Score at Infancy 1-4 weeks] >= 10
	--				OR F.[Depression Score at Infancy 12 mos] >= 10
	--				OR F.[Depression Score at Infancy 4-6 mos] >= 10
	--			)
	--	AND F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos] > 0
	--	THEN 1
	--	ELSE 0
	--END,0) NN_15S10
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
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DC_15S10
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DF_15S10
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DFC_15S10
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos]
	--	ELSE 0
	--END,0) DN_15S10
	,ISNULL( F.[Infant Health Survey 12 Mos] + F.[1 - 8 Weeks Infancy Y/N] + F.[36 Weeks Preg Y/N] + F.[Infant Health Survey 6 Mos],0) DT_15S10	
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Breastfeeding question] > 0
	--	THEN F.[Breastfeeding at birth]
	--	ELSE 0
	--END,0) NC_16I
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Breastfeeding question] > 0
	--	THEN F.[Breastfeeding at birth]
	--	ELSE 0
	--END,0) NF_16I
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Breastfeeding question] > 0 THEN F.[Breastfeeding at birth]
	--	ELSE 0
	--END,0) NFC_16I
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Breastfeeding question] > 0 THEN F.[Breastfeeding at birth]
	--	ELSE 0
	--END,0) NN_16I
	,ISNULL(CASE WHEN F.[Answered Breastfeeding question] > 0 THEN F.[Breastfeeding at birth] END,0) NT_16I
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Breastfeeding question]
	--	ELSE 0
	--END,0) DC_16I
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Breastfeeding question]
	--	ELSE 0
	--END,0) DF_16I
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Breastfeeding question]
	--	ELSE 0
	--END,0) DFC_16I
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Breastfeeding question]
	--	ELSE 0
	--END,0) DN_16I
	,ISNULL( F.[Answered Breastfeeding question],0) DT_16I
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Breastfeeding Question 6 mos] > 0
	--	THEN F.[Breastfeeding at 6 mos]
	--	ELSE 0
	--END,0) NC_166
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Breastfeeding Question 6 mos] > 0
	--	THEN F.[Breastfeeding at 6 mos]
	--	ELSE 0
	--END,0) NF_166
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Breastfeeding Question 6 mos] > 0 THEN F.[Breastfeeding at 6 mos]
	--	ELSE 0
	--END,0) NFC_166
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Breastfeeding Question 6 mos] > 0 THEN F.[Breastfeeding at 6 mos]
	--	ELSE 0
	--END,0) NN_166
	,ISNULL(CASE WHEN F.[Breastfeeding Question 6 mos] > 0 THEN F.[Breastfeeding at 6 mos] END,0) NT_166
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Breastfeeding Question 6 mos]
	--	ELSE 0
	--END,0) DC_166
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Breastfeeding Question 6 mos]
	--	ELSE 0
	--END,0) DF_166
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Breastfeeding Question 6 mos]
	--	ELSE 0
	--END,0) DFC_166
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 6 mos]
	--	ELSE 0
	--END,0) DN_166
	,ISNULL(F.[Breastfeeding Question 6 mos],0) DT_166
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Breastfeeding Question 12 mos] > 0
	--	THEN F.[Breastfeeding at 12 mos]
	--	ELSE 0
	--END,0) NC_1612
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Breastfeeding Question 12 mos] > 0
	--	THEN F.[Breastfeeding at 12 mos]
	--	ELSE 0
	--END,0) NF_1612
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Breastfeeding Question 12 mos] > 0 THEN F.[Breastfeeding at 12 mos]
	--	ELSE 0
	--END,0) NFC_1612
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Breastfeeding Question 12 mos] > 0 THEN F.[Breastfeeding at 12 mos]
	--	ELSE 0
	--END,0) NN_1612
	,ISNULL(CASE WHEN F.[Breastfeeding Question 12 mos] > 0 THEN F.[Breastfeeding at 12 mos] END,0) NT_1612
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Breastfeeding Question 12 mos] 
	--	ELSE 0
	--END,0) DC_1612
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Breastfeeding Question 12 mos]
	--	ELSE 0
	--END,0) DF_1612
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Breastfeeding Question 12 mos]
	--	ELSE 0
	--END,0) DFC_1612
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 12 mos]
	--	ELSE 0
	--END,0) DN_1612
	,ISNULL(F.[Breastfeeding Question 12 mos],0) DT_1612
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Breastfeeding Question 18 mos] > 0
	--	THEN F.[Breastfeeding at 18 mos]
	--	ELSE 0
	--END,0) NC_1618
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Breastfeeding Question 18 mos] > 0
	--	THEN F.[Breastfeeding at 18 mos]
	--	ELSE 0
	--END,0) NF_1618
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Breastfeeding Question 18 mos] > 0 THEN F.[Breastfeeding at 18 mos]
	--	ELSE 0
	--END,0) NFC_1618
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Breastfeeding Question 18 mos] > 0 THEN F.[Breastfeeding at 18 mos]
	--	ELSE 0
	--END,0) NN_1618
	,ISNULL(CASE WHEN F.[Breastfeeding Question 18 mos] > 0 THEN F.[Breastfeeding at 18 mos] END,0) NT_1618
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Breastfeeding Question 18 mos]
	--	ELSE 0
	--END,0) DC_1618
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Breastfeeding Question 18 mos]
	--	ELSE 0
	--END,0) DF_1618
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Breastfeeding Question 18 mos]
	--	ELSE 0
	--END,0) DFC_1618
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 18 mos]
	--	ELSE 0
	--END,0) DN_1618
	,ISNULL(F.[Breastfeeding Question 18 mos],0) DT_1618
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Breastfeeding Question 24 mos] > 0
	--	THEN F.[Breastfeeding at 24 mos]
	--	ELSE 0
	--END,0) NC_1624
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Breastfeeding Question 24 mos] > 0
	--	THEN F.[Breastfeeding at 24 mos]
	--	ELSE 0
	--END,0) NF_1624
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Breastfeeding Question 24 mos] > 0 THEN F.[Breastfeeding at 24 mos]
	--	ELSE 0
	--END,0) NFC_1624
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Breastfeeding Question 24 mos] > 0 THEN F.[Breastfeeding at 24 mos]
	--	ELSE 0
	--END,0) NN_1624
	,ISNULL(CASE WHEN F.[Breastfeeding Question 24 mos] > 0 THEN F.[Breastfeeding at 24 mos] END,0) NT_1624
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Breastfeeding Question 24 mos]
	--	ELSE 0
	--END,0) DC_1624
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Breastfeeding Question 24 mos]
	--	ELSE 0
	--END,0) DF_1624
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Breastfeeding Question 24 mos]
	--	ELSE 0
	--END,0) DFC_1624
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Breastfeeding Question 24 mos]
	--	ELSE 0
	--END,0) DN_1624
	,ISNULL(F.[Breastfeeding Question 24 mos],0) DT_1624
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Well-Child 6 Mos] > 0
	--	THEN F.[Well-Child Visits 6 mos]
	--	ELSE 0
	--END,0) NC_176
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Well-Child 6 Mos] > 0
	--	THEN F.[Well-Child Visits 6 mos]
	--	ELSE 0
	--END,0) NF_176
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Well-Child 6 Mos] > 0 THEN F.[Well-Child Visits 6 mos]
	--	ELSE 0
	--END,0) NFC_176
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Well-Child 6 Mos] > 0 THEN F.[Well-Child Visits 6 mos]
	--	ELSE 0
	--END,0) NN_176
	,ISNULL(CASE WHEN F.[Answered Well-Child 6 Mos] > 0 THEN F.[Well-Child Visits 6 mos] END,0) NT_176
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Well-Child 6 Mos]
	--	ELSE 0
	--END,0) DC_176
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Well-Child 6 Mos]
	--	ELSE 0
	--END,0) DF_176
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Well-Child 6 Mos]
	--	ELSE 0
	--END,0) DFC_176
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 6 Mos]
	--	ELSE 0
	--END,0) DN_176
	,ISNULL(F.[Answered Well-Child 6 Mos],0) DT_176
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Well-Child 12 Mos] > 0 
	--	THEN F.[Well-Child Visits 12 mos]
	--	ELSE 0
	--END,0) NC_1712
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Well-Child 12 Mos] > 0 
	--	THEN F.[Well-Child Visits 12 mos]
	--	ELSE 0
	--END,0) NF_1712
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Well-Child 12 Mos] > 0  THEN F.[Well-Child Visits 12 mos]
	--	ELSE 0
	--END,0) NFC_1712
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Well-Child 12 Mos] > 0 THEN F.[Well-Child Visits 12 mos]
	--	ELSE 0
	--END,0) NN_1712
	,ISNULL(CASE WHEN F.[Answered Well-Child 12 Mos] > 0 THEN F.[Well-Child Visits 12 mos] END,0) NT_1712
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Well-Child 12 Mos]
	--	ELSE 0
	--END,0) DC_1712
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Well-Child 12 Mos]
	--	ELSE 0
	--END,0) DF_1712
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Well-Child 12 Mos]
	--	ELSE 0
	--END,0) DFC_1712
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 12 Mos]
	--	ELSE 0
	--END,0) DN_1712
	,ISNULL(F.[Answered Well-Child 12 Mos],0) DT_1712
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Well-Child 18 Mos] > 0 
	--	THEN F.[Well-Child Visits 18 mos]
	--	ELSE 0
	--END,0) NC_1718
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Well-Child 18 Mos] > 0 
	--	THEN F.[Well-Child Visits 18 mos]
	--	ELSE 0
	--END,0) NF_1718
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Well-Child 18 Mos] > 0  THEN F.[Well-Child Visits 18 mos]
	--	ELSE 0
	--END,0) NFC_1718
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Well-Child 18 Mos] > 0 THEN F.[Well-Child Visits 18 mos]
	--	ELSE 0
	--END,0) NN_1718
	,ISNULL(CASE WHEN F.[Answered Well-Child 18 Mos] > 0 THEN F.[Well-Child Visits 18 mos] END,0) NT_1718
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Well-Child 18 Mos]
	--	ELSE 0
	--END,0) DC_1718
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Well-Child 18 Mos]
	--	ELSE 0
	--END,0) DF_1718
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Well-Child 18 Mos]
	--	ELSE 0
	--END,0) DFC_1718
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 18 Mos]
	--	ELSE 0
	--END,0) DN_1718
	,ISNULL(F.[Answered Well-Child 18 Mos],0) DT_1718
----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Answered Well-Child 24 Mos] > 0 
	--	THEN F.[Well-Child Visits 24 mos]
	--	ELSE 0
	--END,0) NC_1724
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Answered Well-Child 24 Mos] > 0 
	--	THEN F.[Well-Child Visits 24 mos]
	--	ELSE 0
	--END,0) NF_1724
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Answered Well-Child 24 Mos] > 0 THEN F.[Well-Child Visits 24 mos]
	--	ELSE 0
	--END,0) NFC_1724
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Answered Well-Child 24 Mos] > 0 THEN F.[Well-Child Visits 24 mos]
	--	ELSE 0
	--END,0) NN_1724
	,ISNULL(CASE WHEN F.[Answered Well-Child 24 Mos] > 0 THEN F.[Well-Child Visits 24 mos] END,0) NT_1724
	--,ISNULL(CASE WHEN F.Competitive = 1
	--	THEN F.[Answered Well-Child 24 Mos]
	--	ELSE 0
	--END,0) DC_1724
	--,ISNULL(CASE WHEN F.Formula = 1
	--	THEN F.[Answered Well-Child 24 Mos]
	--	ELSE 0
	--END,0) DF_1724
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) THEN F.[Answered Well-Child 24 Mos]
	--	ELSE 0
	--END,0) DFC_1724
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Answered Well-Child 24 Mos]
	--	ELSE 0
	--END,0) DN_1724
	,ISNULL(F.[Answered Well-Child 24 Mos],0) DT_1724

----------------------------------------
	--,ISNULL(CASE WHEN F.Competitive = 1 AND F.[Expected well child 6 Mos] > 0
	--	THEN F.[Completed well child 6 mos]
	--	ELSE 0
	--END,0) NC_17_2_6
	--,ISNULL(CASE WHEN F.Formula = 1 AND F.[Expected well child 6 Mos] > 0
	--	THEN F.[Completed well child 6 mos]
	--	ELSE 0
	--END,0) NF_17_2_6
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Expected well child 6 Mos] > 0 THEN F.[Completed well child 6 mos]
	--	ELSE 0
	--END,0) NFC_17_2_6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Expected well child 6 Mos] > 0 THEN F.[Completed well child 6 mos]
	--	ELSE 0
	--END,0) NN_17_2_6
	,ISNULL(CASE WHEN F.[Expected well child 6 Mos] > 0 THEN F.[Completed well child 6 mos] END,0) NT_17_2_6
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Expected well child 6 Mos]
	--	ELSE 0
	--END,0) DC_17_2_6
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Expected well child 6 Mos]
	--	ELSE 0
	--END,0) DF_17_2_6
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 6 Mos]
	--	ELSE 0
	--END,0) DFC_17_2_6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 6 Mos]
	--	ELSE 0
	--END,0) DN_17_2_6
	,ISNULL(F.[Expected well child 6 Mos],0) DT_17_2_6
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Expected well child 12 Mos] > 0 THEN F.[Completed well child 12 mos]
	--	ELSE 0
	--END,0) NC_17_2_12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Expected well child 12 Mos] > 0 THEN F.[Completed well child 12 mos]
	--	ELSE 0
	--END,0) NF_17_2_12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Expected well child 12 Mos] > 0 THEN F.[Completed well child 12 mos]
	--	ELSE 0
	--END,0) NFC_17_2_12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Expected well child 12 Mos] > 0 THEN F.[Completed well child 12 mos]
	--	ELSE 0
	--END,0) NN_17_2_12
	,ISNULL(CASE WHEN F.[Expected well child 12 Mos] > 0 THEN F.[Completed well child 12 mos] END,0) NT_17_2_12
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Expected well child 12 Mos]
	--	ELSE 0
	--END,0) DC_17_2_12
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Expected well child 12 Mos]
	--	ELSE 0
	--END,0) DF_17_2_12
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 12 Mos]
	--	ELSE 0
	--END,0) DFC_17_2_12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 12 Mos]
	--	ELSE 0
	--END,0) DN_17_2_12
	,ISNULL(F.[Expected well child 12 Mos],0) DT_17_2_12
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Expected well child 18 Mos] > 0 THEN F.[Completed well child 18 mos]
	--	ELSE 0
	--END,0) NC_17_2_18
	--,ISNULL(CASE
	--	WHEN F.Formula = 1 AND F.[Expected well child 18 Mos] > 0 THEN F.[Completed well child 18 mos]
	--	ELSE 0
	--END,0) NF_17_2_18
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Expected well child 18 Mos] > 0 THEN F.[Completed well child 18 mos]
	--	ELSE 0
	--END,0) NFC_17_2_18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Expected well child 18 Mos] > 0 THEN F.[Completed well child 18 mos]
	--	ELSE 0
	--END,0) NN_17_2_18
	,ISNULL(CASE WHEN F.[Expected well child 18 Mos] > 0 THEN F.[Completed well child 18 mos] END,0) NT_17_2_18
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Expected well child 18 Mos]
	--	ELSE 0
	--END,0) DC_17_2_18
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Expected well child 18 Mos]
	--	ELSE 0
	--END,0) DF_17_2_18
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 18 Mos]
	--	ELSE 0
	--END,0) DFC_17_2_18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 18 Mos]
	--	ELSE 0
	--END,0) DN_17_2_18
	,ISNULL(F.[Expected well child 18 Mos],0) DT_17_2_18
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Expected well child 24 Mos] > 0 THEN F.[Completed well child 24 mos]
	--	ELSE 0
	--END,0) NC_17_2_24
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Expected well child 24 Mos] > 0 THEN F.[Completed well child 24 mos]
	--	ELSE 0
	--END,0) NF_17_2_24
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Expected well child 24 Mos] > 0 THEN F.[Completed well child 24 mos]
	--	ELSE 0
	--END,0) NFC_17_2_24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Expected well child 24 Mos] > 0 THEN F.[Completed well child 24 mos]
	--	ELSE 0
	--END,0) NN_17_2_24
	,ISNULL(CASE WHEN F.[Expected well child 24 Mos] > 0 THEN F.[Completed well child 24 mos] END,0) NT_17_2_24
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Expected well child 24 Mos]
	--	ELSE 0
	--END,0) DC_17_2_24
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Expected well child 24 Mos]
	--	ELSE 0
	--END,0) DF_17_2_24
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Expected well child 24 Mos]
	--	ELSE 0
	--END,0) DFC_17_2_24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Expected well child 24 Mos]
	--	ELSE 0
	--END,0) DN_17_2_24
	,ISNULL(F.[Expected well child 24 Mos],0) DT_17_2_24


----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Insurance Section on Govt Svc Assmnt] > 0 THEN F.[Client Health Insurance]
	--	ELSE 0
	--END,0) NC_18M
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Insurance Section on Govt Svc Assmnt] > 0 THEN F.[Client Health Insurance]
	--	ELSE 0
	--END,0) NF_18M
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Insurance Section on Govt Svc Assmnt] > 0 THEN F.[Client Health Insurance]
	--	ELSE 0
	--END,0) NFC_18M
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Insurance Section on Govt Svc Assmnt] > 0 THEN F.[Client Health Insurance]
	--	ELSE 0
	--END,0) NN_18M
	,ISNULL(CASE WHEN F.[Insurance Section on Govt Svc Assmnt] > 0 THEN F.[Client Health Insurance] END,0) NT_18M
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt]
	--	ELSE 0
	--END,0) DC_18M
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt]
	--	ELSE 0
	--END,0) DF_18M
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Insurance Section on Govt Svc Assmnt]
	--	ELSE 0
	--END,0) DFC_18M
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Insurance Section on Govt Svc Assmnt]
	--	ELSE 0
	--END,0) DN_18M
	,ISNULL(F.[Insurance Section on Govt Svc Assmnt],0) DT_18M
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey Intake mos Y/N] > 0 THEN F.[Client Health Ins Intake]
	--	ELSE 0
	--END,0) NC_18MIntake
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey Intake mos Y/N] > 0 THEN F.[Client Health Ins Intake]
	--	ELSE 0
	--END,0) NF_18MIntake
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey Intake mos Y/N] > 0 THEN F.[Client Health Ins Intake]
	--	ELSE 0
	--END,0) NFC_18MIntake
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey Intake mos Y/N] > 0 THEN F.[Client Health Ins Intake]
	--	ELSE 0
	--END,0) NN_18MIntake
	,ISNULL(CASE WHEN F.[Govt Svc Survey Intake mos Y/N] > 0 THEN F.[Client Health Ins Intake] END,0) NT_18MIntake
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey Intake mos Y/N]
	--	ELSE 0
	--END,0) DC_18MIntake
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey Intake mos Y/N]
	--	ELSE 0
	--END,0) DF_18MIntake
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey Intake mos Y/N]
	--	ELSE 0
	--END,0) DFC_18MIntake
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey Intake mos Y/N]
	--	ELSE 0
	--END,0) DN_18MIntake
	,ISNULL(F.[Govt Svc Survey Intake mos Y/N],0) DT_18MIntake
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey Birth mos Y/N] > 0 THEN F.[Client Health Ins Birth]
	--	ELSE 0
	--END,0) NC_18MBirth
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey Birth mos Y/N] > 0 THEN F.[Client Health Ins Birth]
	--	ELSE 0
	--END,0) NF_18MBirth
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey Birth mos Y/N] > 0 THEN F.[Client Health Ins Birth]
	--	ELSE 0
	--END,0) NFC_18MBirth
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey Birth mos Y/N] > 0 THEN F.[Client Health Ins Birth]
	--	ELSE 0
	--END,0) NN_18MBirth
	,ISNULL(CASE WHEN F.[Govt Svc Survey Birth mos Y/N] > 0 THEN F.[Client Health Ins Birth] END,0) NT_18MBirth
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey Birth mos Y/N]
	--	ELSE 0
	--END,0) DC_18MBirth
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey Birth mos Y/N]
	--	ELSE 0
	--END,0) DF_18MBirth
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey Birth mos Y/N]
	--	ELSE 0
	--END,0) DFC_18MBirth
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey Birth mos Y/N]
	--	ELSE 0
	--END,0) DN_18MBirth
	,ISNULL(F.[Govt Svc Survey Birth mos Y/N],0) DT_18MBirth
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 6 mos Y/N] > 0 THEN F.[Client Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NC_18M6
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 6 mos Y/N] > 0 THEN F.[Client Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NF_18M6
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 6 mos Y/N] > 0 THEN F.[Client Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NFC_18M6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 6 mos Y/N] > 0 THEN F.[Client Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NN_18M6
	,ISNULL(CASE WHEN F.[Govt Svc Survey 6 mos Y/N] > 0 THEN F.[Client Health Ins 6 Mos] END,0) NT_18M6
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
	--	ELSE 0
	--END,0) DC_18M6
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 6 mos Y/N]
	--	ELSE 0
	--END,0) DF_18M6
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Y/N]
	--	ELSE 0
	--END,0) DFC_18M6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Y/N]
	--	ELSE 0
	--END,0) DN_18M6
	,ISNULL(F.[Govt Svc Survey 6 mos Y/N],0) DT_18M6
	----------------------------------------
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 12 mos Y/N] > 0 THEN F.[Client Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NC_18M12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 12 mos Y/N] > 0 THEN F.[Client Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NF_18M12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 12 mos Y/N] > 0 THEN F.[Client Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NFC_18M12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 12 mos Y/N] > 0 THEN F.[Client Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NN_18M12
	,ISNULL(CASE WHEN F.[Govt Svc Survey 12 mos Y/N] > 0 THEN F.[Client Health Ins 12 Mos] END,0) NT_18M12
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
	--	ELSE 0
	--END,0) DC_18M12
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 12 mos Y/N]
	--	ELSE 0
	--END,0) DF_18M12
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Y/N]
	--	ELSE 0
	--END,0) DFC_18M12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Y/N]
	--	ELSE 0
	--END,0) DN_18M12
	,ISNULL(F.[Govt Svc Survey 12 mos Y/N],0) DT_18M12
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 18 mos Y/N] > 0 THEN F.[Client Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NC_18M18
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 18 mos Y/N] > 0 THEN F.[Client Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NF_18M18
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 18 mos Y/N] > 0 THEN F.[Client Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NFC_18M18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 18 mos Y/N] > 0 THEN F.[Client Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NN_18M18
	,ISNULL(CASE WHEN F.[Govt Svc Survey 18 mos Y/N] > 0 THEN F.[Client Health Ins 18 Mos] END,0) NT_18M18
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
	--	ELSE 0
	--END,0) DC_18M18
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 18 mos Y/N]
	--	ELSE 0
	--END,0) DF_18M18
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Y/N]
	--	ELSE 0
	--END,0) DFC_18M18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Y/N]
	--	ELSE 0
	--END,0) DN_18M18
	,ISNULL(F.[Govt Svc Survey 18 mos Y/N],0) DT_18M18
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 24 mos Y/N] > 0 THEN F.[Client Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NC_18M24
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 24 mos Y/N] > 0 THEN F.[Client Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NF_18M24
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 24 mos Y/N] > 0 THEN F.[Client Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NFC_18M24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 24 mos Y/N] > 0 THEN F.[Client Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NN_18M24
	,ISNULL(CASE WHEN F.[Govt Svc Survey 24 mos Y/N] > 0 THEN F.[Client Health Ins 24 Mos] END,0) NT_18M24
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
	--	ELSE 0
	--END,0) DC_18M24
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 24 mos Y/N]
	--	ELSE 0
	--END,0) DF_18M24
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Y/N]
	--	ELSE 0
	--END,0) DFC_18M24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Y/N]
	--	ELSE 0
	--END,0) DN_18M24
	,ISNULL(F.[Govt Svc Survey 24 mos Y/N],0) DT_18M24
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 THEN F.[Child Health Insurance]
	--	ELSE 0
	--END,0) NC_18C
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Insurance Section on Govt Svc Assmnt - Child] > 0 THEN F.[Child Health Insurance]
	--	ELSE 0
	--END,0) NF_18C
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Insurance Section on Govt Svc Assmnt - Child] > 0 THEN F.[Child Health Insurance]
	--	ELSE 0
	--END,0) NFC_18C
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Insurance Section on Govt Svc Assmnt - Child] > 0 THEN F.[Child Health Insurance]
	--	ELSE 0
	--END,0) NN_18C
	,ISNULL(CASE WHEN F.[Insurance Section on Govt Svc Assmnt - Child] > 0 THEN F.[Child Health Insurance] END,0) NT_18C
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
	--	ELSE 0
	--END,0) DC_18C
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
	--	ELSE 0
	--END,0) DF_18C
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
	--	ELSE 0
	--END,0) DFC_18C
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Insurance Section on Govt Svc Assmnt - Child]
	--	ELSE 0
	--END,0) DN_18C
	,ISNULL(F.[Insurance Section on Govt Svc Assmnt - Child],0) DT_18C
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 6 mos Child Y/N] > 0 THEN F.[Child Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NC_18C6
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 6 mos Child Y/N] > 0 THEN F.[Child Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NF_18C6
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 6 mos Child Y/N] > 0 THEN F.[Child Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NFC_18C6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 6 mos Child Y/N] > 0 THEN F.[Child Health Ins 6 Mos]
	--	ELSE 0
	--END,0) NN_18C6
	,ISNULL(CASE WHEN F.[Govt Svc Survey 6 mos Child Y/N] > 0 THEN F.[Child Health Ins 6 Mos] END,0) NT_18C6
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
	--	ELSE 0
	--END,0) DC_18C6
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
	--	ELSE 0
	--END,0) DF_18C6
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
	--	ELSE 0
	--END,0) DFC_18C6
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 6 mos Child Y/N]
	--	ELSE 0
	--END,0) DN_18C6
	,ISNULL(F.[Govt Svc Survey 6 mos Child Y/N],0) DT_18C6
	----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 12 mos Child Y/N] > 0  THEN F.[Child Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NC_18C12
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 12 mos Child Y/N] > 0  THEN F.[Child Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NF_18C12
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 12 mos Child Y/N] > 0 THEN F.[Child Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NFC_18C12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 12 mos Child Y/N] > 0 THEN F.[Child Health Ins 12 Mos]
	--	ELSE 0
	--END,0) NN_18C12
	,ISNULL(CASE WHEN F.[Govt Svc Survey 12 mos Child Y/N] > 0 THEN F.[Child Health Ins 12 Mos] END,0) NT_18C12
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
	--	ELSE 0
	--END,0) DC_18C12
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
	--	ELSE 0
	--END,0) DF_18C12
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
	--	ELSE 0
	--END,0) DFC_18C12
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 12 mos Child Y/N]
	--	ELSE 0
	--END,0) DN_18C12
	,ISNULL(F.[Govt Svc Survey 12 mos Child Y/N],0) DT_18C12
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 18 mos Child Y/N] > 0  THEN F.[Child Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NC_18C18
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 18 mos Child Y/N] > 0  THEN F.[Child Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NF_18C18
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 18 mos Child Y/N] > 0  THEN F.[Child Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NFC_18C18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 18 mos Child Y/N] > 0 THEN F.[Child Health Ins 18 Mos]
	--	ELSE 0
	--END,0) NN_18C18
	,ISNULL(CASE WHEN F.[Govt Svc Survey 18 mos Child Y/N] > 0 THEN F.[Child Health Ins 18 Mos] END,0) NT_18C18
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
	--	ELSE 0
	--END,0) DC_18C18
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
	--	ELSE 0
	--END,0) DF_18C18
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
	--	ELSE 0
	--END,0) DFC_18C18
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 18 mos Child Y/N]
	--	ELSE 0
	--END,0) DN_18C18
	,ISNULL(F.[Govt Svc Survey 18 mos Child Y/N],0) DT_18C18
----------------------------------------
	--,ISNULL(CASE 
	--	WHEN F.Competitive = 1 AND F.[Govt Svc Survey 24 mos Child Y/N] > 0  THEN F.[Child Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NC_18C24
	--,ISNULL(CASE 
	--	WHEN F.Formula = 1 AND F.[Govt Svc Survey 24 mos Child Y/N] > 0  THEN F.[Child Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NF_18C24
	--,ISNULL(CASE
	--	WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Govt Svc Survey 24 mos Child Y/N] > 0 THEN F.[Child Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NFC_18C24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 AND F.[Govt Svc Survey 24 mos Child Y/N] > 0 THEN F.[Child Health Ins 24 Mos]
	--	ELSE 0
	--END,0) NN_18C24
	,ISNULL(CASE WHEN F.[Govt Svc Survey 24 mos Child Y/N] > 0 THEN F.[Child Health Ins 24 Mos] END,0) NT_18C24
	--,ISNULL(CASE F.Competitive
	--	WHEN 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
	--	ELSE 0
	--END,0) DC_18C24
	--,ISNULL(CASE F.Formula
	--	WHEN 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
	--	ELSE 0
	--END,0) DF_18C24
	--,ISNULL(CASE
	--	WHEN F.Competitive = 1 OR F.Formula = 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
	--	ELSE 0
	--END,0) DFC_18C24
	--,ISNULL(CASE 
	--	WHEN F.Competitive <> 1 AND F.Formula <> 1 THEN F.[Govt Svc Survey 24 mos Child Y/N]
	--	ELSE 0
	--END,0) DN_18C24
	,ISNULL(F.[Govt Svc Survey 24 mos Child Y/N],0) DT_18C24

FROM FHVI F

--OPTION(RECOMPILE)


GO
