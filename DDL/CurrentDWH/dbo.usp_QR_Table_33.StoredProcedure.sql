USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_33]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_33] 
	-- Add the parameters for the stored procedure here

	@Quarter INT
	,@QuarterYear INT
	,@ReportType VARCHAR(50)
	,@State VARCHAR(5)
	,@AgencyID INT
AS

--DECLARE
--	@Quarter INT
--	,@QuarterYear INT
--	,@ReportType VARCHAR(50)
--	,@State VARCHAR(5)
--	,@AgencyID INT

--SET @Quarter = 2
--	SET @QuarterYear = 2013
--	SET @ReportType = 'NATIONAL'
--	--SET @State = 14
--	--SET @AgencyID = 259


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

IF OBJECT_ID('dbo.UC_QR_Table_33', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_33;

SET QUOTED_IDENTIFIER ON


SET NOCOUNT ON;


SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE 
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_EDUCATION_0_HS_GED IS NOT NULL
				THEN C.Client_ID
			END) [Number of Clients 12 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D12.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							D12.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled'
							OR D12.CLIENT_EDUCATION_1_ENROLLED_TYPE NOT IN ('College','High school or GED program','Middle school (12th - 7th & 8th grades)','Post-high school vocational/technical training program')
						))
				THEN C.Client_ID
			END) [No Diploma Not in School 12 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D12.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D12.CLIENT_SCHOOL_MIDDLE_HS <> 'Not enrolled'
								OR D12.CLIENT_EDUCATION_1_ENROLLED_TYPE IN ('College','High school or GED program','Middle school (12th - 7th & 8th grades)','Post-high school vocational/technical training program')
							))
				THEN C.Client_ID
			END) [No Diploma In School 12 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D12.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D12.CLIENT_SCHOOL_MIDDLE_HS IS NULL
								AND D12.CLIENT_EDUCATION_1_ENROLLED_TYPE IS NULL
							))
				THEN C.Client_ID
			END) [No Diploma Missing 12 Mos]
			
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'NO'
					AND (D12.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Not in School 12 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT <> 'NO'
					AND (D12.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma In School 12 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D12.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NULL
					AND (D12.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D12.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Missing 12 Mos]
			
			
,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D18.CLIENT_EDUCATION_0_HS_GED IS NOT NULL
				THEN C.Client_ID
			END) [Number of Clients 18 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D18.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							D18.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled'
							OR D18.CLIENT_EDUCATION_1_ENROLLED_TYPE NOT IN ('College','High school or GED program','Middle school (18th - 7th & 8th grades)','Post-high school vocational/technical training program')
						))
				THEN C.Client_ID
			END) [No Diploma Not in School 18 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D18.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D18.CLIENT_SCHOOL_MIDDLE_HS <> 'Not enrolled'
								OR D18.CLIENT_EDUCATION_1_ENROLLED_TYPE IN ('College','High school or GED program','Middle school (18th - 7th & 8th grades)','Post-high school vocational/technical training program')
							))
				THEN C.Client_ID
			END) [No Diploma In School 18 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D18.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D18.CLIENT_SCHOOL_MIDDLE_HS IS NULL
								AND D18.CLIENT_EDUCATION_1_ENROLLED_TYPE IS NULL
							))
				THEN C.Client_ID
			END) [No Diploma Missing 18 Mos]
			
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D18.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'NO'
					AND (D18.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Not in School 18 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D18.CLIENT_EDUCATION_1_ENROLLED_CURRENT <> 'NO'
					AND (D18.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma In School 18 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D18.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NULL
					AND (D18.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D18.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Missing 18 Mos]
	,[CLIENT_TRIBAL_0_PARITY]
	
INTO UC_QR_Table_33
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @QuarterDate 
	--INNER JOIN EADT EAD2
	--	ON EAD2.CaseNumber = EAD.CaseNumber
	--	AND EAD2.RankingLatest = 1
	--	AND EAD2.ProgramStartDate < = @QuarterDate 
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID

	LEFT JOIN DataWarehouse..Demographics_Survey D12
		ON D12.CL_EN_GEN_ID = EAD.CLID
		AND D12.ProgramID = EAD.ProgramID
		AND D12.SurveyDate < = @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(D12.SurveyID) LIKE '%DEMOGRAP%12%'
	LEFT JOIN DataWarehouse..Demographics_Survey D18
		ON D18.CL_EN_GEN_ID = EAD.CLID
		AND D18.ProgramID = EAD.ProgramID
		AND D18.SurveyDate < = @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(D18.SurveyID) LIKE '%DEMOGRAP%18%'
	LEFT JOIN DataWarehouse..Demographics_Survey DIN
		ON DIN.CL_EN_GEN_ID = EAD.CLID
		AND DIN.SurveyDate < = @QuarterDate
		AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID)  LIKE '%DEMOGRAP%Intake%'
						 
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	AND ((DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
		OR D12.CLIENT_EDUCATION_0_HS_GED IS NOT NULL
		OR D18.CLIENT_EDUCATION_0_HS_GED IS NOT NULL)
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)

GROUP BY 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE 
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
GO
