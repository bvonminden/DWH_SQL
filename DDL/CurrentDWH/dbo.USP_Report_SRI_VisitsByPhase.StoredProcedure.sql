USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_VisitsByPhase]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_VisitsByPhase] 
(@StartDate		DATE
	,@EndDate		DATE
	,@ProgramID			VARCHAR(4000)
	,@Tribal	INT
	)


AS

--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@Team			VARCHAR(4000)
--SET @StartDate		= CAST('7/1/2013' AS DATE)
--SET @EndDate		= CAST('6/30/2014' AS DATE)
--SET @Team			= '1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'


DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @ProgramID




-----------------------------------------
-- Expected visits at client level.  Final table is #ExpectedFinal
------------------------------------------


BEGIN
IF OBJECT_ID('tempdb..#Client') IS NOT NULL DROP TABLE #Client
IF OBJECT_ID('tempdb..#ClientSplit') IS NOT NULL DROP TABLE #ClientSplit
IF OBJECT_ID('tempdb..#ClientRoot') IS NOT NULL DROP TABLE #ClientRoot
IF OBJECT_ID('tempdb..#ClientWAdd') IS NOT NULL DROP TABLE #ClientWAdd
IF OBJECT_ID('tempdb..#ClientFinal') IS NOT NULL DROP TABLE #ClientFinal
IF OBJECT_ID('tempdb..#HVESroot') IS NOT NULL DROP TABLE #HVESroot
IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
IF OBJECT_ID('tempdb..#ExpectedFinal') IS NOT NULL DROP TABLE #ExpectedFinal
END
----------------------------------------------------------------
--Calculates active clients and attaches DOB and EDD #Client
----------------------------------------------------------------

SELECT 
	Data2.CLientID CLID
	,Data2.CaseNumber
	,Data2.ProgramID
	,Data2.ProgramStartDate 
	,Data2.ProgramEndDate EndDate
	,Data2.ReasonForDismissal 
	,DC.EDD 
	,DC.InfantDOB DOB
	,DC.FirstName + ' ' + LastName FullName
	,ISNULL(DC.InfantDOB,DC.EDD) DOBEDD
	INTO #Client
FROM(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY ClientID,CaseNumber,ProgramID ORDER BY ProgramStartDate DESC,EADRecordID DESC) rownum
	FROM(
		SELECT 
			EAD.CLientID
			,EAD.CaseNumber
			,EAD.ProgramID
			,EAD.ProgramStartDate
			,EAD.ProgramEndDate
			,EAD.ReasonForDismissal
			,EAD.EADRecordID
		FROM FactClientEAD EAD
		WHERE
			EAD.ProgramStartDate <= @EndDate AND ISNULL(EAD.ProgramEndDate,@EndDate) >= @StartDate
		GROUP BY 
			EAD.CLientID
			,EAD.CaseNumber
			,EAD.ProgramID
			,EAD.ProgramStartDate
			,EAD.ProgramEndDate
			,EAD.ReasonForDismissal
			,EAD.EADRecordID
		) Data
	)Data2
	LEFT JOIN DimClient DC ON Data2.ClientID = DC.ClientID
	WHERE Data2.rownum = 1
			AND ((DC.Tribal = 1 AND 1 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))) OR (DC.Tribal = 0 AND 0 IN (SELECT * FROM dbo.udf_ParseMultiParam(@Tribal))))
	--ADD Filter here for Tribal

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
INNER JOIN DimProgramsAndSites P
	ON C.ProgramID = P.ProgramID
WHERE
(C.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))

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
	FE.ClientID CL_EN_GEN_ID
	,FE.ProgramID
	--,EF.SiteID
	,FE.SurveyDate
	,FE.SurveyResponseID
	,N.NurseID NURSE_PERSONAL_0_NAME
	,FE.StartTime CLIENT_TIME_0_START_VISIT
	,FE.VisitStatus CLIENT_COMPLETE_0_VISIT
	,FE.VisitDuration CLIENT_TIME_1_DURATION_VISIT
	,FE.Form Survey
	,N.FullName Full_Name
INTO #HVESroot
FROM 
FactEncounter FE
JOIN DimNurse N ON FE.NurseID = N.NurseID
WHERE FE.FormTypeID IN(1,2) AND FE.VisitStatus = 'Completed'
AND (FE.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
		

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
	,P.TeamName Team_Name
	,P.SiteID
	,P.SiteName AGENCY_INFO_0_NAME
	,P.StateID
	,P.StateName [US State]
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
LEFT OUTER JOIN DimProgramsAndSites P
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
--INTO #ExpectedFinal
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


BEGIN
IF OBJECT_ID('tempdb..#Client') IS NOT NULL DROP TABLE #Client
IF OBJECT_ID('tempdb..#ClientSplit') IS NOT NULL DROP TABLE #ClientSplit
IF OBJECT_ID('tempdb..#ClientRoot') IS NOT NULL DROP TABLE #ClientRoot
IF OBJECT_ID('tempdb..#ClientWAdd') IS NOT NULL DROP TABLE #ClientWAdd
IF OBJECT_ID('tempdb..#ClientFinal') IS NOT NULL DROP TABLE #ClientFinal
IF OBJECT_ID('tempdb..#HVESroot') IS NOT NULL DROP TABLE #HVESroot
IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
END
GO
