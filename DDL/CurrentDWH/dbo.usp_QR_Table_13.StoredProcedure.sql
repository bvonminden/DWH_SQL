USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_13]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_13] 
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
IF OBJECT_ID('dbo.UC_QR_Table_13', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_13;
SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;
WITH HVES AS 
(
	SELECT 
		HV.CL_EN_GEN_ID
		,MAX(HV.SurveyDate) MaxSurveyDate
		,HV.CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
		,COUNT(DISTINCT HV.SurveyResponseID) [Visits]
		,'Home Visit' Form
		,CAST(AVG(HV.CLIENT_TIME_1_DURATION_VISIT) AS NUMERIC(18,6)) AvgDuration
		,CAST(MAX(HV.CLIENT_TIME_1_DURATION_VISIT) AS NUMERIC(18,6)) MaxDuration
		,CAST(MIN(HV.CLIENT_TIME_1_DURATION_VISIT) AS NUMERIC(18,6)) MinDuration
	FROM (	SELECT 
				H.CL_EN_GEN_ID
				,H.SurveyDate
				,H.CLIENT_COMPLETE_0_VISIT
				,H.ProgramID
				,H.NURSE_PERSONAL_0_NAME
				,H.SurveyResponseID
				,'Home Visit' Form
				,CLIENT_TIME_1_DURATION_VISIT
			FROM DataWarehouse..Home_Visit_Encounter_Survey H
			WHERE H.CLIENT_COMPLETE_0_VISIT = 'Completed'

				) HV
		INNER JOIN DataWarehouse..UV_EADT E ON E.CLID = HV.CL_EN_GEN_ID AND E.ProgramID = HV.ProgramID
		
		INNER JOIN DataWarehouse..UV_EDD EDD ON EDD.CaseNumber = E.CaseNumber
			AND HV.SurveyDate < EDD.EDD
	WHERE HV.SurveyDate < = @QuarterDate
		
	GROUP BY HV.CL_EN_GEN_ID
		,HV.CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
)



SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) State
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID)	ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT CASE
						WHEN EDD.EDD < = @QuarterDate
						THEN C.Client_Id
					END) [Potential Pregnancy Completers]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN C.Client_Id
			END),0) [Pregnancy completers]
	,AVG(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN CAST(HV.Visits AS DECIMAL(18,2))
		END) [Potential Preg Completers Visit Completed]
	,MAX(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN HV.Visits
		END) [Potential Preg Completers Visit Completed Max]
	,MIN(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN HV.Visits
		END) [Potential Preg Completers Visit Completed Min]
	,AVG(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN CAST(HV.Visits AS DECIMAL(18,2))
			END) [Preg Completers Visit Completed]
	,MAX(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN HV.Visits
			END) [Preg Completers Visit Completed Max]
	,MIN(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN HV.Visits
			END) [Preg Completers Visit Completed Min]		
	,AVG(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN HV.AvgDuration END) [Potential Preg Completers Visit Time]
	,MAX(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN HV.MaxDuration END) [Potential Preg Completers Visit Time MAX]
	,MIN(CASE
			WHEN EDD.EDD < = @QuarterDate
			THEN HV.MinDuration END) [Potential Preg Completers Visit Time MIN]
	,AVG(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN HV.AvgDuration
			END) [Preg Completers Visit Time]
	,MAX(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN HV.MaxDuration
			END) [Preg Completers Visit Time MAX]
	,MIN(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD)
				THEN HV.MinDuration
			END) [Preg Completers Visit Time MIN]
	,(AVG(CASE
			WHEN EDD.EDD < = @QuarterDate AND 4+(((CAST(DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD) AS DECIMAL(18,2))/7)-4)/2) BETWEEN 0 AND 22
			THEN 4+(((CAST(DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD) AS DECIMAL(18,2))/7)-4)/2) END)) [Potential Preg Completers Expected Visits]
	,(AVG(
			CASE 
				WHEN (ISNULL(EAD.EndDate,GETDATE())) > (EDD.EDD) AND 4+(((CAST(DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD) AS DECIMAL(18,2))/7)-4)/2) BETWEEN 0 AND 22
				THEN 4+(((CAST(DATEDIFF(DAY,EAD.ProgramStartDate,EDD.EDD) AS DECIMAL(18,2))/7)-4)/2)
			END)) [Preg Completers Expected Visits ]
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_13]	
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @QuarterDate 
		AND (EAD.ReasonForDismissal NOT LIKE '%INFANT%DEATH%' OR EAD.ReasonForDismissal IS NULL)
	--INNER JOIN EADT EAD2
	--	ON EAD2.CaseNumber = EAD.CaseNumber
	--	AND EAD2.RankingLatest = 1
	--	AND EAD2.ProgramStartDate < = @QuarterDate 
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID

		LEFT JOIN HVES HV 
			ON HV.CL_EN_GEN_ID = EAD.CLID
			AND HV.ProgramID = EAD.ProgramID
	INNER JOIN DataWarehouse..UV_EDD EDD 
		ON EDD.CaseNumber = EAD.CaseNumber

	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND PAS.SiteID = 222
      LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID

WHERE
	YWCA.CLID IS NULL
	AND  EDD.EDD < = @QuarterDate
	AND HV.Visits > 0
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
