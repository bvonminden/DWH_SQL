USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_22]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_22] 
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
IF OBJECT_ID('dbo.UC_QR_Table_22', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_22;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;



SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) State
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT EAD.CLID) [New Babies Born]
	,COUNT(DISTINCT CASE
						WHEN ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
						THEN EAD.CLID
					END) [Premature births]
	,COUNT(DISTINCT CASE
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Not Hispanic or Latina]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Hispanic or Latina]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Declined to self-identify'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Declined to self-identify]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [No Response]

	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [American Indian or Alaska Native]
	,COUNT(DISTINCT CASE 
		WHEN (
				C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian;Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander;Asian'
			)
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Asian or Pacific Islander]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Black or African American]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [White]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [Declined to self-identify R]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Asian;Native Hawaiian or other Pacific Islander'
			AND C.DEMO_CLIENT_INTAKE_0_RACE <> 'Native Hawaiian or other Pacific Islander;Asian'
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID

	END) [Multiracial]
	,COUNT(DISTINCT CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL
			AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
		THEN EAD.CLID
		
	END) [No Response R]

,ISNULL(COUNT(DISTINCT  CASE
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina'

		THEN C.Client_ID
		
	END),1) [Not Hispanic or Latina Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina'

		THEN C.Client_ID
		
	END),1) [Hispanic or Latina Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Declined to self-identify'

		THEN C.Client_ID
		
	END),1) [Declined to self-identify Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL

		THEN C.Client_ID
		
	END),1) [No Response Count]

	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'American Indian or Alaska Native'

		THEN C.Client_ID
		
	END),1) [American Indian or Alaska Native Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN (
				C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Asian;Native Hawaiian or other Pacific Islander'
				OR C.DEMO_CLIENT_INTAKE_0_RACE = 'Native Hawaiian or other Pacific Islander;Asian'
			)

		THEN C.Client_ID
	END),1) [Asian or Pacific Islander Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Black or African American'

		THEN C.Client_ID
		
	END),1) [Black or African American Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'White'

		THEN C.Client_ID
		
	END),1) [White Count]
	,ISNULL(COUNT(DISTINCT  CASE 
		WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify'

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

		THEN C.Client_ID
		
	END),1) [No Response R Count]
	,[CLIENT_TRIBAL_0_PARITY]

INTO UC_QR_Table_22
	
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
	INNER JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		AND IBS.ProgramID = EAD.ProgramID
		AND IBS.INFANT_BIRTH_0_DOB < = @QuarterDate
		AND IBS.INFANT_BIRTH_1_GEST_AGE IS NOT NULL
		AND IBS.ProgramID = EAD.ProgramID
		AND IBS.SurveyDate < = @QuarterDate
	--LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
	--	ON MHS.CL_EN_GEN_ID = EAD.CLID
	--	AND MHS.SurveyDate < = @QuarterDate
	--	AND MHS.CLIENT_HEALTH_PREGNANCY_0_EDD IS NOT NULL
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
