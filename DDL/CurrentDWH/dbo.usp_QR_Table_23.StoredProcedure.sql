USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_23]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_23] 
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
IF OBJECT_ID('dbo.UC_QR_Table_23', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_23;

SET QUOTED_IDENTIFIER ON


SET NOCOUNT ON;


SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) State
	,PAS.SITE 
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
				WHEN 
					DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 0 AND 5478.74
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END) [Less than 15]
	,COUNT(DISTINCT (
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 5478.75 AND 6574.49
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END
		)) [Between 15 and 17]
	,COUNT(DISTINCT (
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 6574.5 AND 7304.99
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END
		)) [Between 18 AND 19]
	,COUNT(DISTINCT (
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN  7305 AND 9131.24
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END
		)) [Between 20 AND 24]
	,COUNT(DISTINCT (
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 9131.25 AND 10957.49
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END
		)) [Between 25 AND 29]
	,COUNT(DISTINCT (
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD))  > = 10957.5
					AND ((IBS.INFANT_BIRTH_1_GEST_AGE < 37 AND IBS.INFANT_BIRTH_1_GEST_AGE > 0))
				THEN EAD.CLID
			END
		)) [Greater than or Equal to 30]
		
,ISNULL(COUNT(DISTINCT CASE
				WHEN 
					DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 0 AND 5478.74

				THEN EAD.CLID
			END),1) [Age Less than 15]
	,ISNULL(COUNT(DISTINCT(
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 5478.75 AND 6574.49

				THEN EAD.CLID
			END
		)),1) [Age Between 15 and 17]
	,ISNULL(COUNT(DISTINCT(
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 6574.5 AND 7304.99

				THEN EAD.CLID
			END
		)),1) [Age Between 18 AND 19]
	,ISNULL(COUNT(DISTINCT(
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN  7305 AND 9131.24

				THEN EAD.CLID
			END
		)),1) [Age Between 20 AND 24]
	,ISNULL(COUNT(DISTINCT(
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD)) BETWEEN 9131.25 AND 10957.49

				THEN EAD.CLID
			END
		)),1) [Age Between 25 AND 29]
	,ISNULL(COUNT(DISTINCT(
			CASE
				WHEN DATEDIFF(DAY,C.DOB,(EDD.EDD))  > = 10957.5

				THEN EAD.CLID
			END
		)),1) [Age Greater than or Equal to 30]
	,[CLIENT_TRIBAL_0_PARITY]
INTO datawarehouse.[dbo].[UC_QR_Table_23]	
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
	LEFT JOIN DataWarehouse..UV_EDD EDD
		ON EDD.CaseNumber = EAD.CaseNumber
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
	
--OPTION(RECOMPILE)
END
GO
