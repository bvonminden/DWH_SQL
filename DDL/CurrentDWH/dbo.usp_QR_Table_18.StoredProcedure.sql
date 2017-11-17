USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_18]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_18] 
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
IF OBJECT_ID('dbo.UC_QR_Table_18', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_18;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;
WITH HVES AS 
(
	SELECT 
		HV.CL_EN_GEN_ID
		,HV.CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_DOMAIN_0_PERSHLTH_VISIT
			 END) [Personal Health]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
			 END) [Environmental Health]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
			 END) [Life Course Development]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_DOMAIN_0_MATERNAL_VISIT
			 END) [Maternal Role]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_DOMAIN_0_FRNDFAM_VISIT
			 END) [Friends and Family]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_INVOLVE_0_CLIENT_VISIT
			 END) [Degree of Involvement]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_CONFLICT_0_CLIENT_VISIT
			 END) [Degree Conflict With Material]
		,AVG(CASE
				WHEN HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
				THEN HV.CLIENT_UNDERSTAND_0_CLIENT_VISIT
			 END) [Degree Understanding of Material]
	FROM DataWarehouse..Home_Visit_Encounter_Survey HV
		INNER JOIN DataWarehouse..UV_EADT E ON E.CLID = HV.CL_EN_GEN_ID AND E.ProgramID = HV.ProgramID
		
		INNER JOIN DataWarehouse..UV_EDD EDD ON EDD.CaseNumber = E.CaseNumber
	WHERE HV.CLIENT_COMPLETE_0_VISIT = 'Completed'
		AND HV.SurveyDate < = @QuarterDate
		AND HV.SurveyDate > = DATEADD(DAY,365.25,EDD.EDD)
	GROUP BY HV.CL_EN_GEN_ID
		,HV.CLIENT_COMPLETE_0_VISIT
		,HV.ProgramID
)

	
SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,AVG(HV.[Personal Health])/100 [Personal Health]
	,AVG(HV.[Environmental Health])/100 [Environmental Health]
	,AVG(HV.[Life Course Development])/100 [Life Course Development]
	,AVG(HV.[Maternal Role])/100 [Maternal Role]
	,AVG(HV.[Friends and Family])/100 [Friends and Family]
	,AVG(HV.[Degree of Involvement]) [Degree of Involvement]
	,AVG(HV.[Degree Conflict With Material]) [Degree Conflict With Material]
	,AVG(HV.[Degree Understanding of Material]) [Degree Understanding of Material]
	
	,CASE
		WHEN ISNULL(AVG(HV.[Personal Health]),0) 
			+ISNULL(AVG(HV.[Environmental Health]),0)
			+ISNULL(AVG(HV.[Life Course Development]),0)
			+ISNULL(AVG(HV.[Maternal Role]),0)
			+ISNULL(AVG(HV.[Friends and Family]),0)
			+ISNULL(AVG(HV.[Degree of Involvement]),0) 
			+ISNULL(AVG(HV.[Degree Conflict With Material]),0) 
			+ISNULL(AVG(HV.[Degree Understanding of Material]),0) > 0
		THEN 1
	 END [Section Complete]
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_18]	
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
		LEFT JOIN HVES HV 
			ON HV.CL_EN_GEN_ID = EAD.CLID
			AND HV.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
      LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID

WHERE
	YWCA.CLID IS NULL
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)
	
--WHERE
--	CASE WHEN A.State = 'TX' AND A.Site_ID IN (222) AND EAD.ProgramStartDate < '9/1/2010' AND PAS.ProgramName LIKE '%DALLAS%' THEN 'YWCA' END <> 'YWCA'
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
	,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
	
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
	,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
