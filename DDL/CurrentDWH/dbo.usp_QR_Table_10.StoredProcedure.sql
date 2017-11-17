USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_10]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_10] 
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
--declare 
--	@Quarter INT
--	,@QuarterYear INT
--	,@ReportType VARCHAR(50)
--	,@State VARCHAR(5)
--	,@AgencyID INT
	
--set @Quarter = 4
--set @QuarterYear = 2013
--set @ReportType = 'agency'
--set @State = null
--set @AgencyID = 345
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
IF OBJECT_ID('dbo.UC_QR_Table_10', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_10;

--Added a temp table to make this query faster.
--SET QUOTED_IDENTIFIER ON

--SET NOCOUNT ON;
--WITH HV2 AS
--(
--SELECT 
--		H.CL_EN_GEN_ID
--		,MAX(H.SurveyDate) LastVisit
--		,MIN(H.SurveyDate) FirstVisit
--		,H.ProgramID
--	FROM DataWarehouse..UV_HVES H
--		INNER JOIN DataWarehouse..UV_EADT E
--			ON E.CLID = H.CL_EN_GEN_ID
--			AND E.ProgramID = H.ProgramID
--		LEFT JOIN DataWarehouse..UV_EDD ED
--			ON ED.CaseNumber = E.CaseNumber
			
--	WHERE H.SurveyDate < = @QuarterDate
--		AND H.SurveyDate < ED.EDD
--	GROUP BY H.CL_EN_GEN_ID, H.ProgramID
--)

IF OBJECT_ID('tempdb..#HV2') IS NOT NULL DROP TABLE #HV2
                 	
CREATE TABLE #HV2
(
	[RowID] [int] IDENTITY(1,1) NOT NULL
	,CL_EN_GEN_ID INT
	,LastVisit Datetime
	,FirstVisit Datetime
	,ProgramID INT
	PRIMARY KEY (RowID)
)

		
INSERT INTO #HV2
SELECT 
		H.CL_EN_GEN_ID
		,MAX(H.SurveyDate) LastVisit
		,MIN(H.SurveyDate) FirstVisit
		,H.ProgramID
	FROM DataWarehouse..UV_HVES H
		INNER JOIN DataWarehouse..UV_EADT E
			ON E.CLID = H.CL_EN_GEN_ID
			AND E.ProgramID = H.ProgramID
		LEFT JOIN DataWarehouse..UV_EDD ED
			ON ED.CaseNumber = E.CaseNumber			
	WHERE H.SurveyDate < = @QuarterDate
		AND H.SurveyDate < ED.EDD
	GROUP BY H.CL_EN_GEN_ID, H.ProgramID
	
SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN EDD.EDD < = @QuarterDate
				THEN C.Client_ID
			END),0) [Potential Pregnancy Completers]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN (EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate)
					AND (EAD.ReasonForDismissal NOT LIKE '%2%'
					OR (
							EAD.ReasonForDismissal = 'No Activity for 180 days'
							OR EAD.ReasonForDismissal = 'Edit later_No Activity for 180 days'
							OR (DATEDIFF(DAY,HV2.LastVisit,@QuarterDate) > 180
								AND (EAD.ReasonForDismissal IS NULL)
								AND EAD.EndDate < = @QuarterDate
								AND HV2.LastVisit < EDD.EDD
								AND HV2.LastVisit < = @QuarterDate)
						))
				THEN C.Client_ID
			END),0) [Attrition During Pregnancy]
	,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Agency Closure'
	   THEN C.Client_ID
	   
	 END) [Agency Closure]
	 
	 ,COUNT(DISTINCT CASE
					WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client received what she needs from the program'
	   THEN C.Client_ID
	   
	 END) [Client received what she needs from the program]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client returned to work or school'
	   THEN C.Client_ID
	   
	 END) [Client returned to work or school]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Dissatisfied with program'
	   THEN C.Client_ID
	   
	 END) [Dissatisfied with program]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Excessive missed appointments/attempted visits'
	   THEN C.Client_ID
	   
	 END) [Excessive missed appointments/attempted visits]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Maternal death'
	   THEN C.Client_ID
	   
	 END) [Maternal death]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Miscarried/fetal death/infant death'
	   THEN C.Client_ID
	   
	 END) [Miscarried/fetal death/infant death]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Moved out of service area'
	   THEN C.Client_ID
	   
	 END) [Moved out of service area]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Pressure from family'
	   THEN C.Client_ID
	   
	 END) [Pressure from family]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Refused new nurse'
	   THEN C.Client_ID
	   
	 END) [Refused new nurse]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Refused participation'
	   THEN C.Client_ID
	   
	 END) [Refused participation]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Unable to locate'
	   THEN C.Client_ID
	   
	 END) [Unable to locate]

	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND	(
				EAD.ReasonForDismissal = 'Already enrolled in another program'
				OR EAD.ReasonForDismissal = 'Did not meet local criteria'
				OR EAD.ReasonForDismissal = 'Did not meet NFP criteria'
				OR EAD.ReasonForDismissal = 'Program full'
			)
	   THEN C.Client_ID
	   
	 END) [Other]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Child no longer in family custody'
	   THEN C.Client_ID
	   
	 END) [Child no longer in family custody]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client incarcerated'
	   THEN C.Client_ID
	   
	 END) [Client incarcerated]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND	(
				EAD.ReasonForDismissal = 'Declined further participation'
				OR EAD.ReasonForDismissal = 'Declined to participate'
				OR EAD.ReasonForDismissal IS NULL
			)
	   THEN C.Client_ID
	   
	 END) [No Specific Reason]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
				   AND	(
							EAD.ReasonForDismissal = 'No Activity for 180 days'
							OR EAD.ReasonForDismissal = 'Edit later_No Activity for 180 days'
					OR (DATEDIFF(DAY,HV2.LastVisit,@QuarterDate) > 180
						AND (EAD.ReasonForDismissal IS NULL)
						AND EAD.EndDate < = @QuarterDate
						AND HV2.LastVisit < EDD.EDD
						AND HV2.LastVisit < = @QuarterDate)
						)
	   THEN C.Client_ID
	   
	 END) [No Activity for 180 days]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Nurse resigned/no room in other nurse caseloads'
	   THEN C.Client_ID
	   
	 END) [Nurse resigned/no room in other nurse caseloads]
	
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Safety of the nurse'
	   THEN C.Client_ID
	   
	 END) [Safety of the nurse]
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Unable to accommodate requested schedule'
	   THEN C.Client_ID
	   
	 END) [Unable to accommodate requested schedule]
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
						 
					
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Unable to serve client due to language'
	   THEN C.Client_ID
	   
	 END) [Unable to serve client due to language] 

	 
	 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client received what she needs from the program'
	   THEN C.Client_ID
	 END) [Client received what she needed from the program_new] 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client is receiving services from another program'
	   THEN C.Client_ID
	 END) [Client is receiving services from another program] 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Miscarried/fetal death'
	   THEN C.Client_ID
	 END) [Miscarried/fetal death] 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Infant death'
	   THEN C.Client_ID
	 END) [Infant death] 
	 ,COUNT(DISTINCT CASE
				WHEN EAD.EndDate BETWEEN EAD.ProgramStartDate AND DATEADD(DAY,-1,cast(EDD.EDD as datetime))
					AND EAD.EndDate < = @QuarterDate
	   AND EAD.ReasonForDismissal = 'Client refused continuation following CWS report'
	   THEN C.Client_ID
	 END) [Client refused continuation following CWS report] 

	,[CLIENT_TRIBAL_0_PARITY]

INTO UC_QR_Table_10	
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @QuarterDate 
		AND EAD.RankingLatestProg = 1
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..UV_EDD EDD
		ON EDD.CaseNumber = EAD.CLID
	LEFT JOIN #HV2 HV2
		ON HV2.CL_EN_GEN_ID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND PAS.SiteID = 222
      LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID

WHERE
	YWCA.CLID IS NULL
	AND  EAD.ProgramStartDate < = @QuarterDate	
	AND EDD.EDD < = @QuarterDate
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END
GO
