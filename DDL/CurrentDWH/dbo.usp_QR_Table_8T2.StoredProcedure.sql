USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_8T2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_8T2] 
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
IF OBJECT_ID('dbo.UC_QR_Table_8T2', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_8T2;

SET QUOTED_IDENTIFIER ON


SET NOCOUNT ON;
WITH EADT AS
(
SELECT
	RANK() OVER(PARTITION BY EAD2.CaseNumber ORDER BY 
	EAD2.CLID,EAD2.ProgramStartDate,ISNULL(EAD2.EndDate,GETDATE()),EAD2.RecID) RankingOrig
	,RANK() OVER(PARTITION BY EAD2.CaseNumber ORDER BY 
	EAD2.CLID DESC,EAD2.ProgramStartDate DESC,ISNULL(EAD2.EndDate,GETDATE()) DESC,EAD2.RecID DESC) RankingLatest,EAD2.*
from DataWarehouse..EnrollmentAndDismissal  EAD2
		INNER JOIN DataWarehouse..UV_PAS PAS
		ON EAD2.ProgramID IN (PAS.Program_ID_NHV,PAS.Program_ID_Referrals,PAS.Program_ID_Staff_Supervision)
			--AND PAS.ProgramName NOT LIKE '%TEST%'
			--AND PAS.ProgramName NOT LIKE '%TRAIN%'
			--AND PAS.ProgramName NOT LIKE '%PROOF%'
			--AND PAS.ProgramName NOT LIKE '%DEMO%'
			--AND PAS.Site NOT LIKE '%TEST%'
			--AND PAS.Site NOT LIKE '%TRAIN%'
			--AND PAS.Site NOT LIKE '%DEMO%'
			--AND PAS.Site NOT LIKE '%PROOF%'
WHERE EAD2.ReasonForDismissal = 'Enrolled in NFP'
)
, R2NT AS
(
SELECT
	RANK() OVER(PARTITION BY R2N2.CL_EN_GEN_ID ORDER BY 
	R2N2.SurveyDate DESC,R2N2.SurveyID DESC,R2N2.SurveyResponseID) Ranking,R2N2.*
from [DataWarehouse]..[Referrals_to_NFP_Survey]  R2N2
		INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.Program_ID_Referrals = R2N2.ProgramID 
			--AND PAS.ProgramName LIKE '%REFER%'
			--AND PAS.Site NOT LIKE '%TEST%'
			--AND PAS.Site NOT LIKE '%TRAIN%'
			--AND PAS.Site NOT LIKE '%DEMO%'
			--AND PAS.Site NOT LIKE '%PROOF%'
)




SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT R2N.SurveyResponseID) [DENOM]
	,COUNT(DISTINCT CASE WHEN EAD.CLID IS NOT NULL THEN R2N.SurveyResponseID END) [Total (N)]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'WIC'
			THEN R2N.SurveyResponseID
			
		END) WIC
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Pregnancy Testing Clinic'
			THEN R2N.SurveyResponseID
			
		END) [Pregnancy Testing Clinic]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Healthcare Provider / Clinic'
			THEN R2N.SurveyResponseID
			
		END) [Healthcare Provider / Clinic]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'School'
			THEN R2N.SurveyResponseID
			
		END) School
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'NFP Client (current or past)'
			THEN R2N.SurveyResponseID
			
		END) [NFP Client (current or past)]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Other home visiting program'
			THEN R2N.SurveyResponseID
			
		END) [Other home visiting program]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Medicaid'
			THEN R2N.SurveyResponseID
			
		END) Medicaid
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Self'
			THEN R2N.SurveyResponseID
			
		END) [Self]
	,COUNT(DISTINCT
		CASE
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) =  'Other (includes other human service agency)'
			THEN R2N.SurveyResponseID
			
		END) [Other (includes other human service agency)]

		
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN 'Individual Healthcare Provider'
			THEN R2N.SurveyResponseID
		END) [Individual Healthcare Provider]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN 'TANF'
			THEN R2N.SurveyResponseID
		END) [TANF]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Food Stamps'
			THEN R2N.SurveyResponseID
		END) [Food Stamps]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Child Welfare Services'
			THEN R2N.SurveyResponseID
		END) [Child Welfare Services]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Judicial System'
			THEN R2N.SurveyResponseID
		END) [Judicial System]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Clinic'
			THEN R2N.SurveyResponseID
		END) [Clinic]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Hospital'
			THEN R2N.SurveyResponseID
		END) [Hospital]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Managed Care Organization'
			THEN R2N.SurveyResponseID
		END) [Managed Care Organization]
	,COUNT(DISTINCT
		CASE RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4)
			WHEN ' Other (none of the above)'
			THEN R2N.SurveyResponseID
		END) [Other (none of the above)]


	,COUNT(DISTINCT
		CASE 
			WHEN EAD.CLID IS NOT NULL AND  RIGHT(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE,LEN(R2N.REFERRAL_PROSPECT_0_SOURCE_CODE)- 4) IS NULL
			THEN R2N.SurveyResponseID
			
		END) Unknown
	,[CLIENT_TRIBAL_0_PARITY]

INTO datawarehouse.[dbo].[UC_QR_Table_8T2]
FROM R2NT R2N
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.Program_ID_Referrals = R2N.ProgramID 
		
	INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
	INNER JOIN DataWarehouse..Clients C
		ON C.Client_Id = R2N.CL_EN_GEN_ID
		--AND C.Last_Name <> 'FAKE'
	LEFT JOIN EADT EAD
		ON EAD.CLID = R2N.CL_EN_GEN_ID
		AND EAD.ProgramID = R2N.ProgramID
		AND EAD.ProgramStartDate < = @QuarterDate 
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	AND R2N.SurveyDate BETWEEN '11/1/2010' AND @QuarterDate
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
	,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
