USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_38]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_38] 
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
IF OBJECT_ID('dbo.UC_QR_Table_38', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_38;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;
WITH HV2 AS
(
SELECT 
		H.CL_EN_GEN_ID
		,MAX(H.SurveyDate) LastVisit
		,MIN(H.SurveyDate) FirstVisit
		,H.ProgramID
	FROM DataWarehouse..UV_HVES H
	WHERE H.SurveyDate < = @QuarterDate
	GROUP BY H.CL_EN_GEN_ID, H.ProgramID
)


	SELECT 
		DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
		,PAS.SITE [Site]
		,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
		,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
		,CASE
			WHEN @ReportType = 'National' THEN 1
		END [National]
		,COUNT(DISTINCT EAD.CaseNumber) [Number of Clients]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_0_HS_GED IS NOT NULL THEN EAD.CaseNumber END) [Answered Education Q]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%HIGH%' THEN EAD.CaseNumber END) [High School Diploma]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%GED%' THEN EAD.CaseNumber END) [GED]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%Vocation%' THEN EAD.CaseNumber END) [Vocation]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' THEN EAD.CaseNumber END) [No HS GED]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NOT NULL THEN EAD.CaseNumber END) [Answered Enrolled Q]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%YES%' THEN EAD.CaseNumber END) [Enrolled in School]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' THEN EAD.CaseNumber END) [Not Enrolled in School]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL THEN EAD.CaseNumber END) [Answered Working Q]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%FULL%' THEN EAD.CaseNumber END) [Working Full Time]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%PART%' THEN EAD.CaseNumber END) [Working Part Time]
		,COUNT(DISTINCT CASE WHEN D.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%NO%' THEN EAD.CaseNumber END) [Not Working]
		,[CLIENT_TRIBAL_0_PARITY]
INTO dbo.UC_QR_Table_38
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @QuarterDate 

	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..UV_EDD EDD
		ON EDD.CaseNumber = EAD.CaseNumber	
	LEFT JOIN HV2
		ON HV2.CL_EN_GEN_ID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID

	LEFT JOIN DataWarehouse..Demographics_Survey D
		ON D.CL_EN_GEN_ID = EAD.CaseNumber 
		AND D.ProgramID = EAD.ProgramID
		AND D.SurveyDate < = @QuarterDate
		AND D.SurveyResponseID =	(
										SELECT TOP 1 DD.SurveyResponseID
										FROM DataWarehouse..Demographics_Survey DD
										WHERE DD.CL_EN_GEN_ID = EAD.CLID
											AND DD.SurveyDate < = @QuarterDate
										ORDER BY DD.SurveyDate DESC
									)

	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
    INNER JOIN DataWarehouse..AC_Dates AC
		ON AC.CLID = EAD.CLID
		AND AC.ProgramID = EAD.ProgramID
		AND AC.ProgramStartDate <= @QuarterDate
		AND AC.EndDate > @QuarterDate
		AND EAD.RankingLatest = 1
		
WHERE
	YWCA.CLID IS NULL
	AND  ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)


GROUP BY 	
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE 
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
