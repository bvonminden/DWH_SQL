USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_27]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_27] 
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
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 
IF OBJECT_ID('dbo.UC_QR_Table_27', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_27;

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
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
					AND MS_IHS.SurveyName LIKE '%6%'
				THEN EAD.CLID
			END
		) [Data 6 Mos]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'YES'
					AND MS_IHS.SurveyName LIKE '%6%'
				THEN EAD.CLID
			END
		),1) [at 6 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
					AND MS_IHS.SurveyName LIKE '%12%'
				THEN EAD.CLID
			END
		) [Data 12 Mos]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'YES'
					AND MS_IHS.SurveyName LIKE '%12%'
				THEN EAD.CLID
			END
		),1) [at 12 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
					AND MS_IHS.SurveyName LIKE '%18%'
				THEN EAD.CLID
			END
		) [Data 18 Mos]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'YES'
					AND MS_IHS.SurveyName LIKE '%18%'
				THEN EAD.CLID
			END
		),1) [at 18 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
					AND MS_IHS.SurveyName LIKE '%24%'
				THEN EAD.CLID
			END
		) [Data 24 Mos]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE = 'YES'
					AND MS_IHS.SurveyName LIKE '%24%'
				THEN EAD.CLID
			END
		),1) [at 24 Mos]
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_27]	
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
		AND IHS.INFANT_HEALTH_IMMUNIZ_0_UPDATE IS NOT NULL
		AND IHS.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..Mstr_surveys MS_IHS
		ON MS_IHS.SurveyID = IHS.SurveyID

	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	AND  EAD.ProgramStartDate < = @QuarterDate	
	AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)
	
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
	,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
