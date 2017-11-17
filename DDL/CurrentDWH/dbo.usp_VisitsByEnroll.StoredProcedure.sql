USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_VisitsByEnroll]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_VisitsByEnroll]
	(@StartDate		DATE
	,@EndDate		DATE
	,@Team			NVARCHAR(4000)
	)

AS

--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@Team			NVARCHAR(4000)
--SET @StartDate		= CAST('7/1/2012' AS DATE)
--SET @EndDate		= CAST('6/30/2013' AS DATE)
--SET @Team			= '1848,1085'


DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @Team
		

IF OBJECT_ID('tempdb..#Client') IS NOT NULL DROP TABLE #Client
IF OBJECT_ID('tempdb..#ClientSplit') IS NOT NULL DROP TABLE #ClientSplit
IF OBJECT_ID('tempdb..#ClientRoot') IS NOT NULL DROP TABLE #ClientRoot
IF OBJECT_ID('tempdb..#ClientWAdd') IS NOT NULL DROP TABLE #ClientWAdd
IF OBJECT_ID('tempdb..#ClientFinal') IS NOT NULL DROP TABLE #ClientFinal
IF OBJECT_ID('tempdb..#HVESroot') IS NOT NULL DROP TABLE #HVESroot
IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined

----------------------------------------------------------------
--Calculates active clients and attaches DOB and EDD #Client
----------------------------------------------------------------

SELECT
	EAD.CLID
	,EAD.CaseNumber
	,EAD.ProgramID
	,EAD.ProgramStartDate
	,EAD.EndDate
	,EAD.ReasonForDismissal
	,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD EDD
	,IBS.INFANT_BIRTH_0_DOB DOB
	,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) DOBEDD
INTO #Client
FROM UV_EADT EAD
LEFT OUTER JOIN Maternal_Health_Survey MHS
	ON EAD.CLID = MHS.CL_EN_GEN_ID
	AND EAD.ProgramID = MHS.ProgramID
LEFT OUTER JOIN Infant_Birth_Survey IBS
	ON EAD.CLID = IBS.CL_EN_GEN_ID
	AND EAD.ProgramID = IBS.ProgramID
LEFT JOIN dbo.UC_Client_Exclusion_YWCA YWCA 
	ON YWCA.CLID = EAD.CLID
	AND EAD.SiteID = 222
WHERE 
DATEADD(YEAR,2,ISNULL(IBS.INFANT_BIRTH_0_DOB,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD)) BETWEEN @rStartDate AND @rEndDate
	AND EAD.RankingLatest = 1 --- ????
	AND YWCA.CLID IS NULL

	
------------------------------------------------------
--Calculates start and stop for stages #ClientSplit
------------------------------------------------------

SELECT 
	C.CLID
	,C.ProgramID
	,C.ProgramStartDate
	,C.ReasonForDismissal
	,C.EndDate
	,C.EDD
	,C.DOB
	,C.DOBEDD
	,CASE WHEN C.ProgramStartDate < C.DOBEDD THEN 1 END Stage1
	,CASE WHEN C.ProgramStartDate < C.DOBEDD THEN C.ProgramStartDate END Stage1Start
	,CASE WHEN C.ProgramStartDate < C.DOBEDD THEN CASE WHEN C.DOB IS NOT NULL THEN C.DOB ELSE ISNULL(C.EndDate,GETDATE()) END END Stage1End
	,C.DOBEDD Stage1CompletionDate
	,CASE WHEN C.DOB IS NOT NULL AND C.DOB BETWEEN C.ProgramStartDate AND C.EndDate THEN 1 ELSE 0 END Complete1
	,CASE WHEN C.ProgramStartDate < DATEADD(YEAR,1,C.DOBEDD) AND ISNULL(C.EndDate,GETDATE()) > C.DOBEDD THEN 2 END Stage2
	,CASE WHEN C.ProgramStartDate < DATEADD(YEAR,1,C.DOBEDD) AND ISNULL(C.EndDate,GETDATE()) > C.DOBEDD THEN CASE WHEN C.ProgramStartDate < C.DOBEDD THEN C.DOBEDD ELSE C.ProgramStartDate END END Stage2Start
	,CASE WHEN C.ProgramStartDate < DATEADD(YEAR,1,C.DOBEDD) AND ISNULL(C.EndDate,GETDATE()) > C.DOBEDD THEN CASE WHEN DATEADD(YEAR,1,C.DOBEDD) < ISNULL(C.EndDate,GETDATE()) THEN DATEADD(YEAR,1,C.DOBEDD) ELSE ISNULL(C.EndDate,GETDATE()) END END Stage2End
	,DATEADD(YEAR,1,C.DOBEDD) Stage2CompletionDate
	,CASE WHEN CASE WHEN C.ProgramStartDate < DATEADD(YEAR,1,C.DOBEDD) AND ISNULL(C.EndDate,GETDATE()) > C.DOBEDD THEN CASE WHEN DATEADD(YEAR,1,C.DOBEDD) < ISNULL(C.EndDate,GETDATE()) THEN DATEADD(YEAR,1,C.DOBEDD) ELSE ISNULL(C.EndDate,GETDATE()) END END >= DATEADD(YEAR,1,C.DOBEDD) THEN 1 ELSE 0 END Complete2
	,CASE WHEN ISNULL(C.EndDate,GETDATE()) > DATEADD(YEAR,1,C.DOBEDD) THEN 3 END Stage3
	,CASE WHEN ISNULL(C.EndDate,GETDATE()) > DATEADD(YEAR,1,C.DOBEDD) THEN CASE WHEN C.ProgramStartDate < DATEADD(YEAR,1,C.DOBEDD) THEN DATEADD(YEAR,1,C.DOBEDD) ELSE C.ProgramStartDate END END Stage3Start
	,CASE WHEN ISNULL(C.EndDate,GETDATE()) > DATEADD(YEAR,1,C.DOBEDD) THEN ISNULL(C.EndDate,GETDATE()) END Stage3End
	--,CASE WHEN C.ReasonForDismissal = 'Child reached 2nd birthday' THEN C.EndDate ELSE DATEADD(YEAR,2,C.DOBEDD) END Stage3CompletionDate
	,DATEADD(YEAR,2,C.DOBEDD) Stage3CompletionDate
	,CASE WHEN CASE WHEN ISNULL(C.EndDate,GETDATE()) > DATEADD(YEAR,1,C.DOBEDD) THEN ISNULL(C.EndDate,GETDATE()) END >= DATEADD(YEAR,2,C.DOBEDD) THEN 1 ELSE 0 END Complete3
INTO #ClientSplit
FROM #Client C
INNER JOIN UV_PAS P
	ON C.ProgramID = P.ProgramID
WHERE
(C.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))

---------------------------------------------------
--Separates Clients into stages 1,2,3 #ClientRoot
---------------------------------------------------

--SELECT DATA.*
--INTO #ClientRoot
--FROM
--(SELECT 
--	C1.CLID
--	,C1.ProgramID
--	,C1.Stage1 Stage
--	,C1.Stage1Start StageStart
--	,C1.Stage1End StageEnd
--	,C1.Stage1CompletionDate CompletionDate
--	,CASE WHEN C1.DOB IS NOT NULL THEN 1 ELSE 0 END Complete
--	--,CASE WHEN C1.Stage1End >= C1.Stage1CompletionDate THEN 1 ELSE 0 END Complete
--FROM #ClientSplit C1
--WHERE C1.Stage1 = 1

--UNION

--SELECT 
--	C2.CLID
--	,C2.ProgramID
--	,C2.Stage2 Stage
--	,C2.Stage2Start StageStart
--	,C2.Stage2End StageEnd
--	,C2.Stage2CompletionDate CompletionDate
--	--,CASE WHEN C2.Stage2End = DATEADD(YEAR,1,C2.DOBEDD) THEN 1 ELSE 0 END Complete
--	,CASE WHEN C2.Stage2End >= C2.Stage2CompletionDate THEN 1 ELSE 0 END Complete
--FROM #ClientSplit C2
--WHERE C2.Stage2 = 2

--UNION

--SELECT 
--	C3.CLID
--	,C3.ProgramID
--	,C3.Stage3 Stage
--	,C3.Stage3Start StageStart
--	,C3.Stage3End StageEnd
--	,C3.Stage3CompletionDate CompletionDate
--	--,CASE WHEN C3.Stage3End >= DATEADD(YEAR,2,C3.DOBEDD) THEN 1 ELSE 0 END Complete
--	,CASE WHEN C3.Stage3End >= C3.Stage3CompletionDate THEN 1 ELSE 0 END Complete
--FROM #ClientSplit C3
--WHERE C3.Stage3 = 3) DATA
--INNER JOIN UV_PAS P
--	ON DATA.ProgramID = P.ProgramID
--WHERE --DATA.CompletionDate BETWEEN @rStartDate AND @rEndDate  --- Changes Based on Query
----AND 
--(P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))

------------------------------------------------------------------
--Adds Client stage calculations to Clientroot into #ClientWAdd
------------------------------------------------------------------

SELECT 
	C.*
	,DATEDIFF(DAY,C.Stage1Start,C.Stage1End) DaysDuring1
	,DATEDIFF(DAY,C.Stage2Start,C.Stage2End) DaysDuring2
	,DATEDIFF(DAY,C.Stage3Start,C.Stage3End) DaysDuring3
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage1Start,CASE WHEN C.Stage1CompletionDate < C.Stage1End THEN C.Stage1CompletionDate ELSE C.Stage1End END) AS FLOAT)/7 > 4
						THEN CAST(4 AS FLOAT)
					ELSE CAST(DATEDIFF(DAY,C.Stage1Start,C.Stage1End) AS FLOAT)/7 END Stage1Add
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2End) AS FLOAT)/7 > 6
						THEN CAST(6 AS FLOAT)
					ELSE CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2End) AS FLOAT)/7 END Stage2Add
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage2Start,CASE WHEN C.Stage2CompletionDate < C.Stage2End THEN C.Stage2CompletionDate ELSE C.Stage2End END) AS FLOAT) > 274
						THEN DATEDIFF(DAY,DATEADD(MM,9,C.Stage3Start),CASE WHEN C.Stage3CompletionDate < C.Stage3End THEN C.Stage3CompletionDate ELSE C.Stage3End END)/7
					ELSE CAST(0 AS FLOAT) END Stage3Add
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage1Start,C.Stage1CompletionDate) AS FLOAT)/7 > 4
						THEN CAST(4 AS FLOAT)
					ELSE CAST(DATEDIFF(DAY,C.Stage1Start,C.Stage1CompletionDate) AS FLOAT)/7 END Stage1AddExpComp
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2CompletionDate) AS FLOAT)/7 > 6
						THEN CAST(6 AS FLOAT)
					ELSE CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2CompletionDate) AS FLOAT)/7 END Stage2AddExpComp
	,CASE WHEN CAST(DATEDIFF(DAY,C.Stage3Start,C.Stage3CompletionDate) AS FLOAT) > 274
						THEN DATEDIFF(DAY,DATEADD(MM,9,C.Stage3Start),C.Stage3CompletionDate)/7
					ELSE CAST(0 AS FLOAT) END Stage3AddExpComp
INTO #ClientWAdd
FROM #ClientSplit C

------------------------------------------------------------------
--Adds expected visits to client calculation into #ClientFinal
------------------------------------------------------------------

SELECT 
	C.*
	,FLOOR((CAST(DATEDIFF(DAY,C.Stage1Start,CASE WHEN C.Stage1CompletionDate < C.Stage1End THEN C.Stage1CompletionDate ELSE C.Stage1End END) AS FLOAT)/7 + C.Stage1Add)/2) Exp1Visits
	,FLOOR((CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2End) AS FLOAT)/7 + C.Stage2Add)/2) Exp2Visits
	,FLOOR(CAST(DATEDIFF(DAY,C.Stage3Start,CASE WHEN C.Stage3CompletionDate < C.Stage3End THEN C.Stage3CompletionDate ELSE C.Stage3End END) AS FLOAT)/14)-FLOOR(C.Stage3Add/2) Exp3Visits
	,FLOOR((CAST(DATEDIFF(DAY,C.Stage1Start,C.Stage1CompletionDate) AS FLOAT)/7 + C.Stage1AddExpComp)/2) Exp1VisitsExpComp
	,FLOOR((CAST(DATEDIFF(DAY,C.Stage2Start,C.Stage2CompletionDate) AS FLOAT)/7 + C.Stage2AddExpComp)/2) Exp2VisitsExpComp
	,FLOOR(CAST(DATEDIFF(DAY,C.Stage3Start,C.Stage3CompletionDate) AS FLOAT)/14)-FLOOR(C.Stage3AddExpComp/2) Exp3VisitsExpComp
INTO #ClientFinal
FROM #ClientWAdd C

---------------------------------------------------
--Runs total visits into #HVESroot
---------------------------------------------------

SELECT 
	HVES.CL_EN_GEN_ID
	,HVES.ProgramID
	,HVES.SiteID
	,HVES.SurveyDate
	,HVES.SurveyResponseID
	,HVES.NURSE_PERSONAL_0_NAME
	,HVES.CLIENT_TIME_0_START_VISIT
	,HVES.CLIENT_COMPLETE_0_VISIT
	,HVES.CLIENT_TIME_1_DURATION_VISIT
	,HVES.Survey
	,S.Full_Name
INTO #HVESroot
FROM 
(
	SELECT 
		HVE.CL_EN_GEN_ID
		,HVE.ProgramID
		,HVE.SiteID
		,HVE.SurveyDate
		,HVE.SurveyResponseID
		,HVE.NURSE_PERSONAL_0_NAME
		,HVE.CLIENT_TIME_0_START_VISIT
		,HVE.CLIENT_COMPLETE_0_VISIT
		,HVE.CLIENT_TIME_1_DURATION_VISIT
		,'HVES' Survey
	FROM Home_Visit_Encounter_Survey HVE
	--WHERE CAST(HVE.SurveyDate AS DATE) BETWEEN @StartDate AND @EndDate

	UNION

	SELECT
		HV.CL_EN_GEN_ID
		,HV.ProgramID
		,HV.SiteID
		,HV.SurveyDate
		,HV.SurveyResponseID
		,HV.NURSE_PERSONAL_0_NAME
		,HV.CLIENT_TIME_0_START_ALT CLIENT_TIME_0_START_VISIT
		,'Completed' CLIENT_COMPLETE_0_VISIT
		,HV.CLIENT_TIME_1_DURATION_ALT CLIENT_TIME_1_DURATION_VISIT
		,'AES' Survey
	FROM Alternative_Encounter_Survey HV
	WHERE (HV.CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' OR HV.CLIENT_TALKED_0_WITH_ALT = 'CLIENT')
) HVES
LEFT JOIN IA_Staff S
	ON HVES.NURSE_PERSONAL_0_NAME = S.Entity_Id
WHERE HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
AND (HVES.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
		

----------------------------------------------------------------------------
--Combines #ClientFinal with #HVESroot to create a table of combined data
----------------------------------------------------------------------------

SELECT 
	C.CLID
	,C.ProgramStartDate
	,C.EndDate
	,C.ReasonForDismissal
	,C.DOBEDD
	,P.ProgramID
	,P.Team_Name
	,P.SiteID
	,P.AGENCY_INFO_0_NAME
	,P.StateID
	,P.[US State]
	,C.Stage1
	,C.Stage2
	,C.Stage3
	,C.Stage1Start
	,C.Stage1End
	,C.Stage1CompletionDate
	,C.Stage2Start
	,C.Stage2End
	,C.Stage2CompletionDate
	,C.Stage3Start
	,C.Stage3End
	,C.Stage3CompletionDate
	,H.SurveyDate
	,H.NURSE_PERSONAL_0_NAME
	,H.Full_Name
	,H.Survey
	,C.Exp1Visits
	,C.Exp1VisitsExpComp
	,C.Exp2Visits
	,C.Exp2VisitsExpComp
	,C.Exp3Visits
	,C.Exp3VisitsExpComp
	--,ROW_NUMBER() OVER(PARTITION BY H.CL_EN_GEN_ID,H.ProgramID,C.Stage ORDER BY H.Survey) ClientRow
	--,ROW_NUMBER() OVER(PARTITION BY H.CL_EN_GEN_ID,H.ProgramID,H.NURSE_PERSONAL_0_NAME,C.Stage ORDER BY H.Survey) ClientNurseRow
INTO #Combined
FROM #ClientFinal C
LEFT OUTER JOIN #HVESroot H
	ON C.CLID = H.CL_EN_GEN_ID
	AND C.ProgramID = H.ProgramID
	--AND H.SurveyDate BETWEEN C.Stage1Start AND CASE WHEN C.Stage1End < C.Stage1CompletionDate THEN C.Stage1End ELSE C.Stage1CompletionDate END
LEFT OUTER JOIN UV_PAS P
	ON C.ProgramID = P.ProgramID



SELECT  
	C.CLID
	,C.ProgramID
	,C.Team_Name
	,C.SiteID
	,C.AGENCY_INFO_0_NAME
	,C.StateID
	,C.[US State]
	,C.ProgramStartDate
	,C.EndDate
	--,C.Stage1
	--,C.Stage1Start
	--,C.Stage1End
	--,C.Stage1CompletionDate
	--,C.Stage2
	--,C.Stage2Start
	--,C.Stage2End
	--,C.Stage2CompletionDate
	--,C.Stage3
	--,C.Stage3Start
	--,C.Stage3End
	--,C.Stage3CompletionDate
	,COUNT(C.SurveyDate) Visits
	--,C.NURSE_PERSONAL_0_NAME
	--,C.Full_Name
	--,SUM(CASE WHEN C.Survey = 'HVES' THEN 1 END) HVES
	--,SUM(CASE WHEN C.Survey = 'AES' THEN 1 END) AES
	,C.Exp1Visits
	,C.Exp1VisitsExpComp
	,C.Exp2Visits
	,ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) Exp2VisitsExpComp
	,C.Exp3Visits
	,ISNULL(C.Exp3VisitsExpComp,CASE WHEN ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) IS NOT NULL THEN 20 END) Exp3VisitsExpComp
	,CASE WHEN ISNULL(C.Exp1Visits,0) + ISNULL(C.Exp2Visits,0) + ISNULL(C.Exp3Visits,0) > 0 
		  THEN ISNULL(C.Exp1Visits,0) + ISNULL(C.Exp2Visits,0) + ISNULL(C.Exp3Visits,0) 
		  ELSE 1 END ExpVisits
	,CASE WHEN ISNULL(C.Exp1VisitsExpComp,0) + ISNULL(ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END),0) + ISNULL(ISNULL(C.Exp3VisitsExpComp,CASE WHEN ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) IS NOT NULL THEN 20 END),0) > 0
		  THEN ISNULL(C.Exp1VisitsExpComp,0) + ISNULL(ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END),0) + ISNULL(ISNULL(C.Exp3VisitsExpComp,CASE WHEN ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) IS NOT NULL THEN 20 END),0) 
		  ELSE 1 END ExpVisitsExpComp
	,CASE WHEN C.ReasonForDismissal = 'Child reached 2nd birthday'  OR (C.EndDate IS NULL AND @EndDate > C.DOBEDD)THEN 1 ELSE 0 END Complete
FROM #Combined C
GROUP BY 
	C.CLID
	,C.ProgramID
	,C.Team_Name
	,C.SiteID
	,C.AGENCY_INFO_0_NAME
	,C.StateID
	,C.[US State]
	,C.ProgramStartDate
	,C.EndDate
	--,C.ReasonForDismissal
	--,C.DOBEDD
	,C.Stage1
	,C.Stage1Start
	,C.Stage1End
	,C.Stage1CompletionDate
	,C.Stage2
	,C.Stage2Start
	,C.Stage2End
	,C.Stage2CompletionDate
	,C.Stage3
	,C.Stage3Start
	,C.Stage3End
	,C.Stage3CompletionDate
	,C.Exp1Visits
	,C.Exp1VisitsExpComp
	,C.Exp2Visits
	,ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) 
	,C.Exp3Visits
	,ISNULL(C.Exp3VisitsExpComp,CASE WHEN ISNULL(C.Exp2VisitsExpComp,CASE WHEN C.Exp1VisitsExpComp IS NOT NULL THEN 29 END) IS NOT NULL THEN 20 END) 
	,CASE WHEN C.ReasonForDismissal = 'Child reached 2nd birthday'  OR (C.EndDate IS NULL AND @EndDate > C.DOBEDD)THEN 1 ELSE 0 END 



IF OBJECT_ID('tempdb..#Client') IS NOT NULL DROP TABLE #Client
IF OBJECT_ID('tempdb..#ClientSplit') IS NOT NULL DROP TABLE #ClientSplit
IF OBJECT_ID('tempdb..#ClientRoot') IS NOT NULL DROP TABLE #ClientRoot
IF OBJECT_ID('tempdb..#ClientWAdd') IS NOT NULL DROP TABLE #ClientWAdd
IF OBJECT_ID('tempdb..#ClientFinal') IS NOT NULL DROP TABLE #ClientFinal
IF OBJECT_ID('tempdb..#HVESroot') IS NOT NULL DROP TABLE #HVESroot
IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined

GO
