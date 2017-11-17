USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_24]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_24] 
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
IF OBJECT_ID('dbo.UC_QR_Table_24', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_24;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;


SELECT --EAD.CLID,IBS.[Inf1 Weight - Grams],INFANT_BIRTH_1_WEIGHT_GRAMS,INFANT_BIRTH_1_WEIGHT_POUNDS,INFANT_BIRTH_1_WEIGHT_OUNCES,
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE 
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT CASE
			WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
			THEN EAD.CLID
			END) [New Babies Born]
	,COUNT(DISTINCT CASE
		WHEN (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Low Birth Weight]
	,COUNT(DISTINCT CASE
		WHEN (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 1499.99 )
		THEN C.Client_ID
		
	END) [Very Low Birth Weight]
	,COUNT(DISTINCT CASE
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Not Hispanic or Latina]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Hispanic or Latina]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Declined to self-identify'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Declined to self-identify]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [No Response]

	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [American Indian or Alaska Native]
	,COUNT(DISTINCT CASE 
		WHEN (
				C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian;Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander;Asian'
			)
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Asian or Pacific Islander]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Black or African American]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [White]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Declined to self-identify R]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Asian;Native Hawaiian or other Pacific Islander'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Native Hawaiian or other Pacific Islander;Asian'
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [Multiracial]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL
			AND (IBS.[Inf1 Weight - Grams] BETWEEN 0.00001 AND 2499.99 )
		THEN C.Client_ID
		
	END) [No Response R]



,ISNULL(COUNT(DISTINCT  CASE
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Not Hispanic or Latina Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Hispanic or Latina Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Declined to self-identify'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Declined to self-identify Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [No Response Count]

	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [American Indian or Alaska Native Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN (
				C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian;Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander;Asian'
			)
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Asian or Pacific Islander Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Black or African American Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [White Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [Declined to self-identify R Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Asian;Native Hawaiian or other Pacific Islander'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Native Hawaiian or other Pacific Islander;Asian'
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL
		THEN C.Client_ID
	END),1) [Multiracial Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL
		AND IBS.INFANT_BIRTH_0_DOB IS NOT NULL	
		THEN C.Client_ID
		
	END),1) [No Response R Count]
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_24]
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
	INNER JOIN (SELECT 

				ISNULL(	CASE 
							WHEN I.INFANT_BIRTH_1_WEIGHT_GRAMS > 0
							THEN I.INFANT_BIRTH_1_WEIGHT_GRAMS
						END,(ISNULL(I.INFANT_BIRTH_1_WEIGHT_OUNCES,0)*28.3495)
										+(ISNULL(I.INFANT_BIRTH_1_WEIGHT_POUNDS,0) *453.592)) [Inf1 Weight - Grams]
					, I.INFANT_BIRTH_0_DOB
					,I.CL_EN_GEN_ID
					,I.ProgramID
					,I.SurveyDate
					,INFANT_BIRTH_1_WEIGHT_GRAMS
					,INFANT_BIRTH_1_WEIGHT_POUNDS
					,INFANT_BIRTH_1_WEIGHT_OUNCES
				FROM DataWarehouse..Infant_Birth_Survey I) IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		AND IBS.ProgramID = EAD.ProgramID
		AND IBS.SurveyDate < = @QuarterDate
		AND (IBS.[Inf1 Weight - Grams] IS NOT NULL )
		
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	AND  EAD.ProgramStartDate < = @QuarterDate	
	--AND CASE WHEN A.State = 'TX' AND A.Site_ID IN (222) AND EAD.ProgramStartDate < '9/1/2010' AND PAS.ProgramName LIKE '%DALLAS%' THEN 'YWCA' END <> 'YWCA'
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)

GROUP BY --EAD.CLID,IBS.[Inf1 Weight - Grams],INFANT_BIRTH_1_WEIGHT_GRAMS,INFANT_BIRTH_1_WEIGHT_POUNDS,INFANT_BIRTH_1_WEIGHT_OUNCES,
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
