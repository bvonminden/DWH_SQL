USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_28]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_28] 
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
IF OBJECT_ID('dbo.UC_QR_Table_28', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_28;

SET QUOTED_IDENTIFIER ON


SET NOCOUNT ON;


SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST IS NOT NULL
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
				THEN C.Client_ID
			END
		) [Data 6 Mos]
		,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST LIKE '%YES%'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
				THEN C.Client_ID
			END
		) [at 6 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST = 'Yes - result was positive'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
				THEN C.Client_ID
			END
		) [Positive at 6 Mos]
		
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST IS NOT NULL
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
				THEN C.Client_ID
			END
		) [Data 12 Mos]
		,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST LIKE '%YES%'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
				THEN C.Client_ID
			END
		) [at 12 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST = 'Yes - result was positive'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
				THEN C.Client_ID
			END
		) [Positive at 12 Mos]
		
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST IS NOT NULL
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
				THEN C.Client_ID
			END
		) [Data 18 Mos]
		,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST LIKE '%YES%'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
				THEN C.Client_ID
			END
		) [at 18 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST = 'Yes - result was positive'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
				THEN C.Client_ID
			END
		) [Positive at 18 Mos]
		
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST IS NOT NULL
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%24%'
				THEN C.Client_ID
			END
		) [Data 24 Mos]
		,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST LIKE '%YES%'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%24%'
				THEN C.Client_ID
			END
		) [at 24 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_LEAD_0_TEST = 'Yes - result was positive'
					AND DataWarehouse.dbo.fnGetFormName(IHS.SurveyID) LIKE '%24%'
				THEN C.Client_ID
			END
		) [Positive at 24 Mos]
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_28]	
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
	INNER JOIN DataWarehouse..Infant_Health_Survey IHS
		ON IHS.CL_EN_GEN_ID = EAD.CLID
		AND IHS.SurveyDate BETWEEN '10/1/2006' AND @QuarterDate
		AND IHS.ProgramID = EAD.ProgramID
		AND IHS.INFANT_HEALTH_LEAD_0_TEST IS NOT NULL
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
	,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
