USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_2] 
	-- Add the parameters for the stored procedure here
	@Quarter INT
	,@QuarterYear INT
	,@ReportType VARCHAR(50)
	,@State VARCHAR(5)
	,@AgencyID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


    -- Insert statements for procedure here
DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	CAST((
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					) AS DATE)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,@QuarterDate)) 
IF OBJECT_ID('dbo.UC_QR_Table_2', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_2;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;
WITH DEMOG AS (
SELECT
					D.CL_EN_GEN_ID
					,D.ProgramID
					,D.SiteID
					,D.SurveyDate
					,D.CLIENT_MARITAL_0_STATUS
					,D.CLIENT_EDUCATION_0_HS_GED
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
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
						END) [Household Income]
					,A.State
				FROM DataWarehouse..Demographics_Survey D
					INNER JOIN DataWarehouse..Agencies A
						ON A.Site_ID = D.SiteID

				WHERE DataWarehouse.dbo.fnGetFormName(D.SurveyID) LIKE '%INTAKE%'
					AND D.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
)


SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT CASE
			WHEN EAD.RankingOrig = 1 
				AND EAD.ProgramStartDate < = @QuarterDate
			THEN EAD.CLID
		END) [New Clients Enrolled]
	,MIN(M.MedAgeNational) MedAgeNat
	,MIN(M.MedAgeState) MedAgeState
	,MIN(M.MedAgeSite) MedianSite
	,MIN(M.MedAgeTeam) MedianTeam
	,ISNULL(COUNT(DISTINCT CASE
				WHEN 
					DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate)  > = 0
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END),0) [Age Data]
	,ISNULL(COUNT(DISTINCT CASE
				WHEN 
					DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate)  BETWEEN 0 AND 5478.74
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END),0) [Less than 15]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 5478.75 AND 6574.49
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END
		),0) [Between 15 and 17]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 6574.5 AND 7304.99
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END
		),0) [Between 18 AND 19]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN  7305 AND 9131.24
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END
		),0) [Between 20 AND 24]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 9131.25 AND 10957.49
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END
		),0) [Between 25 AND 29]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate)  > = 10957.5
					AND EAD.RankingOrig = 1 
					AND EAD.ProgramStartDate < = @QuarterDate
				THEN C.Client_ID
			END
		),0) [Greater than or Equal to 30]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN D.CLIENT_EDUCATION_0_HS_GED IS NOT NULL
				THEN C.Client_ID
			END),0) [Education data]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN D.CLIENT_EDUCATION_0_HS_GED = 'Yes - completed high school'
				THEN C.Client_ID
			END),0) [Completed High School]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN D.CLIENT_EDUCATION_0_HS_GED = 'Yes - completed GED'
				THEN C.Client_ID
			END),0) [Completed GED]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN D.CLIENT_MARITAL_0_STATUS IS NOT NULL
				THEN C.Client_ID
			END),0) [Married data]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN D.CLIENT_MARITAL_0_STATUS = 'Married (legal or common law)'
				THEN C.Client_ID
			END),0) [Married]
	,MIN(MI.MedIncNat) MedNatInc
	,MIN(MI.MedIncState) MedStateInc
	,MIN(MI.MedIncSite) MedSiteInc
	,MIN(MI.MedIncTeam) MedTeamInc
	,MAX(D.[Household Income]) [Household Income Max]
	,MIN(D.[Household Income]) [Household Income Min]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN GCSS.SERVICE_USE_0_FOODSTAMP_CLIENT IN (2)
				THEN C.Client_ID
			END),0) [Food Stamps]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN GCSS.SERVICE_USE_0_MEDICAID_CHILD IN (2)
					OR GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2)
				THEN C.Client_ID
			END),0) [Medicaid]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN GCSS.SERVICE_USE_0_TANF_CLIENT IN (2)
				THEN C.Client_ID
			END),0) [TANF]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN GCSS.SERVICE_USE_0_WIC_CLIENT IN (2)
				THEN C.Client_ID
			END),0) [WIC]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN GCSS.CL_EN_GEN_ID IS NOT NULL
				THEN C.Client_ID
			END),0) [Govt Svc Data]		
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_2]
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate 
	--INNER JOIN EADT EAD2
	--	ON EAD2.CaseNumber = EAD.CaseNumber
	--	AND EAD2.RankingLatest = 1
	--	AND EAD2.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate 
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DEMOG D
			ON D.CL_EN_GEN_ID = C.Client_Id
			--AND D.ProgramID = EAD.ProgramID
			--AND D.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

		LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GCSS
			ON GCSS.CL_EN_GEN_ID = C.Client_Id
			AND GCSS.ProgramID = EAD.ProgramID
			AND GCSS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
			AND DataWarehouse.dbo.fnGetFormName(GCSS.SurveyID) LIKE '%GOV%INTAKE%'
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
      LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
     LEFT OUTER JOIN dbo.Median_Age(@Quarter,@QuarterYear,2) M
		ON PAS.ProgramID = M.ProgramID
		AND ISNULL(TS.[CLIENT_TRIBAL_0_PARITY],1) = ISNULL(M.PrimMulti,1)
     LEFT OUTER JOIN dbo.Median_Income(@Quarter,@QuarterYear,2) MI
		ON PAS.ProgramID = MI.ProgramID
		AND ISNULL(TS.[CLIENT_TRIBAL_0_PARITY],1) = ISNULL(MI.PrimMulti,1)

WHERE
	YWCA.CLID IS NULL
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)


GROUP BY 	
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 
	--,EAD.SiteID
	,EAD.ProgramID
	,[CLIENT_TRIBAL_0_PARITY]
	



UNION ALL 

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,NULL
	
FROM DataWarehouse..UV_PAS P
	--INNER JOIN DataWarehouse..Tribal_Survey T
	--	ON T.SiteID = P.SiteID	
	--	AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL

UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,NULL,NULL,NULL,NULL,0,0,0,0,0,0,0,0,0,0,0,0,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
