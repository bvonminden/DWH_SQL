USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_FHVI_B5_V3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_FHVI_B5_V3]
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
					,DataWarehouse.dbo.udf_StateVSTribal(A.State,D.SiteID)State
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
,FHVI AS 
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
		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID
			
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..UV_EDD EDD
			ON EDD.CaseNumber = EAD.CaseNumber
		LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
			ON MHS.CL_EN_GEN_ID = EAD.CLID
			AND MHS.SurveyDate < = @QuarterDate
		
		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
		--LEFT JOIN DataWarehouse..Demographics_Survey DS
		--	ON DS.CL_EN_GEN_ID = EAD.CLID
		--	AND DS.ProgramID = EAD.ProgramID
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
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.MedCompIncINT > 0 AND F.MedCompInc12M > 0
		THEN F.MedCompInc12M - F.MedCompIncINT
		ELSE 0
	END,0) NC_51
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
		THEN F.MedFormInc12M - F.MedFormIncINT
		ELSE 0
	END,0) NF_51
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.MedCompIncINT > 0 AND F.MedCompInc12M > 0  AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
		THEN (F.MedCompInc12M + F.MedFormInc12M) - (F.MedCompIncINT + F.MedFormIncINT)
		ELSE 0
	END,0) NFC_51
	,ISNULL(CASE
		----assessment has both Competitive and Formula---which is actually an error, per Kyla
		WHEN F.MedCompIncINT > 0 AND F.MedCompInc12M > 0 AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
			THEN CASE --select only one of the median calculations
					WHEN (F.MedCompInc12M - F.MedCompIncINT) > (F.MedFormInc12M - F.MedFormIncINT)
						THEN F.MedCompInc12M - F.MedCompIncINT --highest median calculaton
						ELSE F.MedFormInc12M - F.MedFormIncINT
				END
		----competitive
		WHEN F.MedCompIncINT > 0 AND F.MedCompInc12M > 0  
			THEN F.MedCompInc12M - F.MedCompIncINT 
		---formula
		WHEN F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
			THEN F.MedFormInc12M - F.MedFormIncINT
		ELSE 0
	END,0) NT_51

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.MedCompIncINT > 0 AND F.MedCompInc12M > 0
		THEN (F.MedCompIncINT)
		ELSE 0
	END,0) DC_51
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
		THEN (F.MedFormIncINT)
		ELSE 0
	END,0) DF_51
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.MedCompIncINT > 0 AND F.MedCompInc12M > 0  AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
		THEN (F.MedCompIncINT + F.MedFormIncINT)
		ELSE 0
	END,0) DFC_51
	,ISNULL(CASE
		----assessment has both Competitive and Formula---which is actually an error, per Kyla
		WHEN F.MedCompIncINT > 0 AND F.MedCompInc12M > 0  AND F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
			THEN CASE --select only one of the median calculations
					WHEN F.MedCompIncINT > F.MedFormIncINT
						THEN F.MedCompIncINT --highest median calculaton
						ELSE F.MedFormIncINT
				END
		----competitive
		WHEN F.MedCompIncINT > 0 AND F.MedCompInc12M > 0  
			THEN F.MedCompIncINT 
		---formula
		WHEN F.MedFormIncINT > 0 AND F.MedFormInc12M > 0
			THEN F.MedFormIncINT
		ELSE 0
	END,0) DT_51
------------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN F.[In-Kind Benefits Count 12Mos] - F.[In-Kind Benefits Count Intake]
		ELSE 0
	END,0) NC_51_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN F.[In-Kind Benefits Count 12Mos] - F.[In-Kind Benefits Count Intake]
		ELSE 0
	END,0) NF_51_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN F.[In-Kind Benefits Count 12Mos] - F.[In-Kind Benefits Count Intake]
		ELSE 0
	END,0) NFC_51_2
	,ISNULL(CASE
		WHEN  F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN F.[In-Kind Benefits Count 12Mos] - F.[In-Kind Benefits Count Intake]
		ELSE 0
	END,0) NT_51_2

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN (F.[In-Kind Benefits Count Intake])
		ELSE 0
	END,0) DC_51_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN (F.[In-Kind Benefits Count Intake])
		ELSE 0
	END,0) DF_51_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN (F.[In-Kind Benefits Count Intake])
		ELSE 0
	END,0) DFC_51_2
	,ISNULL(CASE
		WHEN F.[In-Kind Benefits Intake and 12Mos] = 1
		THEN (F.[In-Kind Benefits Count Intake])
		ELSE 0
	END,0) DT_51_2
------------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NC_52_1
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NF_52_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NFC_52_1
	,ISNULL(CASE
		WHEN F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NT_52_1

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN (F.[Currently Working Hours Intake])
		ELSE 0
	END,0) DC_52_1
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN (F.[Currently Working Hours Intake])
		ELSE 0
	END,0) DF_52_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN (F.[Currently Working Hours Intake])
		ELSE 0
	END,0) DFC_52_1
	,ISNULL(CASE
		WHEN  F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] > = 18
		THEN (F.[Currently Working Hours Intake])
		ELSE 0
	END,0) DT_52_1
------------------------------------------
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NC_52_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NF_52_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NFC_52_2
	,ISNULL(CASE
		WHEN  F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN F.[Currently Working Hours 12Mos] - F.[Currently Working Hours Intake]
		ELSE 0
	END,0) NT_52_2

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN 1
		ELSE 0
	END,0) DC_52_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN 1
		ELSE 0
	END,0) DF_52_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN 1
		ELSE 0
	END,0) DFC_52_2
	,ISNULL(CASE
		WHEN  F.[Currently Working Q Intake and 12Mos] = 1 AND F.[Age at Enrollment] < 18
		THEN 1
		ELSE 0
	END,0) DT_52_2
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN F.[Childcare Hours 12Mos] - F.[Childcare Hours Intake]
		ELSE 0
	END,0) NC_52_3
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN F.[Childcare Hours 12Mos] - F.[Childcare Hours Intake]
		ELSE 0
	END,0) NF_52_3
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN F.[Childcare Hours 12Mos] - F.[Childcare Hours Intake]
		ELSE 0
	END,0) NFC_52_3
	,ISNULL(CASE
		WHEN  F.[Childcare Q Intake and 12Mos] = 1 
		THEN F.[Childcare Hours 12Mos] - F.[Childcare Hours Intake]
		ELSE 0
	END,0) NT_52_3
	
	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN (F.[Childcare Hours Intake])
		ELSE 0
	END,0) DC_52_3
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN (F.[Childcare Hours Intake])
		ELSE 0
	END,0) DF_52_3
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Childcare Q Intake and 12Mos] = 1 
		THEN (F.[Childcare Hours Intake])
		ELSE 0
	END,0) DFC_52_3
	,ISNULL(CASE
		WHEN  F.[Childcare Q Intake and 12Mos] = 1 
		THEN (F.[Childcare Hours Intake])
		ELSE 0
	END,0) DT_52_3
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 
		THEN F.[Completed Diploma 12 Mos]
		ELSE 0
	END,0) NC_53_1
	,ISNULL(CASE 
		WHEN F.Formula = 1
		THEN F.[Completed Diploma 12 Mos]
		ELSE 0
	END,0) NF_53_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1)
		THEN F.[Completed Diploma 12 Mos]
		ELSE 0
	END,0) NFC_53_1
	,ISNULL(F.[Completed Diploma 12 Mos],0) NT_53_1

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Education Question Answered 12 Mos] = 1
		THEN (F.[No Diploma Intake])
		ELSE 0
	END,0) DC_53_1
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Education Question Answered 12 Mos] = 1
		THEN (F.[No Diploma Intake])
		ELSE 0
	END,0) DF_53_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Education Question Answered 12 Mos] = 1
		THEN (F.[No Diploma Intake])
		ELSE 0
	END,0) DFC_53_1
	,ISNULL(CASE
		WHEN  F.[Education Question Answered 12 Mos] = 1
		THEN (F.[No Diploma Intake])
		ELSE 0
	END,0) DT_53_1
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN F.[Education Hours 12Mos] - F.[Education Hours Intake]
		ELSE 0
	END,0) NC_53_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN F.[Education Hours 12Mos] - F.[Education Hours Intake]
		ELSE 0
	END,0) NF_53_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN F.[Education Hours 12Mos] - F.[Education Hours Intake]
		ELSE 0
	END,0) NFC_53_2
	,ISNULL(CASE
		WHEN F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN F.[Education Hours 12Mos] - F.[Education Hours Intake]
		ELSE 0
	END,0) NT_53_2	

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN (F.[Education Hours Intake])
		ELSE 0
	END,0) DC_53_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN (F.[Education Hours Intake])
		ELSE 0
	END,0) DF_53_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN (F.[Education Hours Intake])
		ELSE 0
	END,0) DFC_53_2
	,ISNULL(CASE
		WHEN F.[Completed Diploma Intake Answered Hours Q] = 1
		THEN (F.[Education Hours Intake])
		ELSE 0
	END,0) DT_53_2
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN F.[Completed Diploma in School 12Mos] - F.[Completed Diploma in School Intake]
		ELSE 0
	END,0) NC_53_3
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN F.[Completed Diploma in School 12Mos] - F.[Completed Diploma in School Intake]
		ELSE 0
	END,0) NF_53_3
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN F.[Completed Diploma in School 12Mos] - F.[Completed Diploma in School Intake]
		ELSE 0
	END,0) NFC_53_3
	,ISNULL(CASE
		WHEN F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN F.[Completed Diploma in School 12Mos] - F.[Completed Diploma in School Intake]
		ELSE 0
	END,0) NT_53_3

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[Completed Diploma in School Intake])
		ELSE 0
	END,0) DC_53_3
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[Completed Diploma in School Intake])
		ELSE 0
	END,0) DF_53_3
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[Completed Diploma in School Intake])
		ELSE 0
	END,0) DFC_53_3
	,ISNULL(CASE
		WHEN F.[Completed Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[Completed Diploma in School Intake])
		ELSE 0
	END,0) DT_53_3
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN F.[No Diploma in School 12Mos] - F.[No Diploma in School Intake]
		ELSE 0
	END,0) NC_53_4
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN F.[No Diploma in School 12Mos] - F.[No Diploma in School Intake]
		ELSE 0
	END,0) NF_53_4
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN F.[No Diploma in School 12Mos] - F.[No Diploma in School Intake]
		ELSE 0
	END,0) NFC_53_4
	,ISNULL(CASE
		WHEN  F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN F.[No Diploma in School 12Mos] - F.[No Diploma in School Intake]
		ELSE 0
	END,0) NT_53_4

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[No Diploma in School Intake])
		ELSE 0
	END,0) DC_53_4
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[No Diploma in School Intake])
		ELSE 0
	END,0) DF_53_4
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[No Diploma in School Intake])
		ELSE 0
	END,0) DFC_53_4
	,ISNULL(CASE
		WHEN F.[No Diploma Intake Answered Enrollment Q] = 1
		THEN (F.[No Diploma in School Intake])
		ELSE 0
	END,0) DT_53_4
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN F.[Client with Health Insurance 12Mos] - F.[Client with Health Insurance Intake]
		ELSE 0
	END,0) NC_54_1
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN F.[Client with Health Insurance 12Mos] - F.[Client with Health Insurance Intake]
		ELSE 0
	END,0) NF_54_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN F.[Client with Health Insurance 12Mos] - F.[Client with Health Insurance Intake]
		ELSE 0
	END,0) NFC_54_1
	,ISNULL(CASE
		WHEN F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN F.[Client with Health Insurance 12Mos] - F.[Client with Health Insurance Intake]
		ELSE 0
	END,0) NT_54_1

	,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN (F.[Client with Health Insurance Intake])
		ELSE 0
	END,0) DC_54_1
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN (F.[Client with Health Insurance Intake])
		ELSE 0
	END,0) DF_54_1
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN (F.[Client with Health Insurance Intake])
		ELSE 0
	END,0) DFC_54_1
	,ISNULL(CASE
		WHEN F.[Use Gvt Svcs Intake and 12Mos] = 1
		THEN (F.[Client with Health Insurance Intake])
		ELSE 0
	END,0) DT_54_1
------------------------------------------
,ISNULL(CASE 
		WHEN F.Competitive = 1 AND F.[Use Gvt Svcs 12Mos] = 1
		THEN F.[Child with Health Insurance 12Mos]
		ELSE 0
	END,0) NC_54_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 AND F.[Use Gvt Svcs 12Mos] = 1
		THEN F.[Child with Health Insurance 12Mos]
		ELSE 0
	END,0) NF_54_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) AND F.[Use Gvt Svcs 12Mos] = 1
		THEN F.[Child with Health Insurance 12Mos]
		ELSE 0
	END,0) NFC_54_2
	,ISNULL(CASE
		WHEN  F.[Use Gvt Svcs 12Mos] = 1
		THEN F.[Child with Health Insurance 12Mos]
		ELSE 0
	END,0) NT_54_2

	,ISNULL(CASE 
		WHEN F.Competitive = 1 
		THEN (F.[Use Gvt Svcs 12Mos])
		ELSE 0
	END,0) DC_54_2
	,ISNULL(CASE 
		WHEN F.Formula = 1 
		THEN (F.[Use Gvt Svcs 12Mos])
		ELSE 0
	END,0) DF_54_2
	,ISNULL(CASE
		WHEN (F.Competitive = 1 OR F.Formula = 1) 
		THEN (F.[Use Gvt Svcs 12Mos])
		ELSE 0
	END,0) DFC_54_2
	,ISNULL(F.[Use Gvt Svcs 12Mos],0) DT_54_2

FROM FHVI F



--OPTION(RECOMPILE)

END

GO
