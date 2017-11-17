USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_VisitsByPhase]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_VisitsByPhase]
	(@StartDate DATE, @EndDate DATE)

AS
--DECLARE @StartDate DATE, @EndDate DATE
--SET @StartDate = CAST('7/1/2012' AS DATE)
--SET @EndDate = CAST('6/30/2013' AS DATE);


WITH HVES AS
(SELECT *
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
	WHERE CAST(HVE.SurveyDate AS DATE) BETWEEN @StartDate AND @EndDate

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
		,HV.CLIENT_TIME_1_DURATION_ALT
		,'AES' Survey
	FROM Alternative_Encounter_Survey HV
	WHERE (HV.CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' OR HV.CLIENT_TALKED_0_WITH_ALT = 'CLIENT') AND CAST(HV.SurveyDate AS DATE) BETWEEN @StartDate AND @EndDate ) HVES)





SELECT 
	HVES.CL_EN_GEN_ID 	
	,HVES.ProgramID
	,HVES.SurveyDate
	--,HVES.SurveyResponseID
	,HVES.NURSE_PERSONAL_0_NAME
	--,HVES.CLIENT_COMPLETE_0_VISIT
	,HVES.Survey
	,EAD.ProgramStartDate
	,EAD.EndDate
	,IBS.INFANT_BIRTH_0_DOB DOB
	,CASE WHEN HVES.SurveyDate BETWEEN EAD.ProgramStartDate AND ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate)
			   AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) THEN 1
		  WHEN HVES.SurveyDate BETWEEN ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate) AND DATEADD(YY,1,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate))
			   AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) THEN 2
		  WHEN HVES.SurveyDate BETWEEN DATEADD(YY,1,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate)) AND ISNULL(EAD.EndDate,@EndDate)--DATEADD(YY,2,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate))
			   AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) THEN 3
		  ELSE 0 END Stage
	--,CASE WHEN HVES.SurveyDate BETWEEN EAD.ProgramStartDate AND ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
	--	  THEN DATEDIFF(DAY
	--					,CASE WHEN EAD.ProgramStartDate > @StartDate 
	--						  THEN EAD.ProgramStartDate ELSE @StartDate END
	--					,CASE WHEN @EndDate <= ISNULL(IBS.INFANT_BIRTH_0_DOB,ISNULL(EAD.EndDate,@EndDate)) AND @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
	--						  WHEN EAD.EndDate <= @EndDate AND EAD.EndDate <= ISNULL(IBS.INFANT_BIRTH_0_DOB,ISNULL(EAD.EndDate,@EndDate)) THEN EAD.EndDate
	--						  WHEN IBS.INFANT_BIRTH_0_DOB <= @EndDate AND IBS.INFANT_BIRTH_0_DOB <= ISNULL(EAD.EndDate,@EndDate) THEN IBS.INFANT_BIRTH_0_DOB END 
	--					)
	--	  WHEN HVES.SurveyDate BETWEEN IBS.INFANT_BIRTH_0_DOB AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
	--	  THEN DATEDIFF(DAY
	--					,CASE WHEN EAD.ProgramStartDate > @StartDate AND EAD.ProgramStartDate > IBS.INFANT_BIRTH_0_DOB THEN EAD.ProgramStartDate 
	--						  WHEN IBS.INFANT_BIRTH_0_DOB > @StartDate AND IBS.INFANT_BIRTH_0_DOB > EAD.ProgramStartDate THEN IBS.INFANT_BIRTH_0_DOB
	--						  WHEN @StartDate > IBS.INFANT_BIRTH_0_DOB AND @StartDate > EAD.ProgramStartDate THEN @StartDate END
	--					,CASE WHEN @EndDate <= DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
	--						  WHEN EAD.EndDate <= @EndDate AND EAD.EndDate <= DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) THEN EAD.EndDate
	--						  WHEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) <= @EndDate AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) <= ISNULL(EAD.EndDate,@EndDate) THEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) END 
	--					)
	--	  WHEN HVES.SurveyDate BETWEEN DATEADD(YY,1,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate)) AND ISNULL(EAD.EndDate,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
	--	  THEN DATEDIFF(DAY
	--					,CASE WHEN EAD.ProgramStartDate > @StartDate AND EAD.ProgramStartDate > DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) THEN EAD.ProgramStartDate 
	--						  WHEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) > @StartDate AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) > EAD.ProgramStartDate THEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB)
	--						  WHEN @StartDate > DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND @StartDate > EAD.ProgramStartDate THEN @StartDate END
	--					,CASE WHEN @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
	--						  WHEN EAD.EndDate <= @EndDate THEN EAD.EndDate END 
	--					)
	--	  ELSE 0 END DaysDuring
	,CASE WHEN HVES.SurveyDate BETWEEN EAD.ProgramStartDate AND ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN EAD.ProgramStartDate > @StartDate 
					THEN EAD.ProgramStartDate ELSE @StartDate 
					END
		  WHEN HVES.SurveyDate BETWEEN IBS.INFANT_BIRTH_0_DOB AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN EAD.ProgramStartDate > @StartDate AND EAD.ProgramStartDate > IBS.INFANT_BIRTH_0_DOB THEN EAD.ProgramStartDate 
					WHEN IBS.INFANT_BIRTH_0_DOB > @StartDate AND IBS.INFANT_BIRTH_0_DOB > EAD.ProgramStartDate THEN IBS.INFANT_BIRTH_0_DOB
					WHEN @StartDate > IBS.INFANT_BIRTH_0_DOB AND @StartDate > EAD.ProgramStartDate THEN @StartDate 
					END
		  WHEN HVES.SurveyDate BETWEEN DATEADD(YY,1,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate)) AND ISNULL(EAD.EndDate,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN EAD.ProgramStartDate > @StartDate AND EAD.ProgramStartDate > DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) THEN EAD.ProgramStartDate 
					WHEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) > @StartDate AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) > EAD.ProgramStartDate THEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB)
					WHEN @StartDate > DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND @StartDate > EAD.ProgramStartDate THEN @StartDate 
					END
		  END Stage_Start
	,CASE WHEN HVES.SurveyDate BETWEEN EAD.ProgramStartDate AND ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN @EndDate <= ISNULL(IBS.INFANT_BIRTH_0_DOB,ISNULL(EAD.EndDate,@EndDate)) AND @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
					WHEN EAD.EndDate <= @EndDate AND EAD.EndDate <= ISNULL(IBS.INFANT_BIRTH_0_DOB,ISNULL(EAD.EndDate,@EndDate)) THEN EAD.EndDate
					WHEN IBS.INFANT_BIRTH_0_DOB <= @EndDate AND IBS.INFANT_BIRTH_0_DOB <= ISNULL(EAD.EndDate,@EndDate) THEN IBS.INFANT_BIRTH_0_DOB 
					END 
		  WHEN HVES.SurveyDate BETWEEN IBS.INFANT_BIRTH_0_DOB AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN @EndDate <= DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) AND @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
					WHEN EAD.EndDate <= @EndDate AND EAD.EndDate <= DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) THEN EAD.EndDate
					WHEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) <= @EndDate AND DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) <= ISNULL(EAD.EndDate,@EndDate) THEN DATEADD(YY,1,IBS.INFANT_BIRTH_0_DOB) 
					END 
		  WHEN HVES.SurveyDate BETWEEN DATEADD(YY,1,ISNULL(IBS.INFANT_BIRTH_0_DOB,@EndDate)) AND ISNULL(EAD.EndDate,@EndDate) AND HVES.SurveyDate <= ISNULL(EAD.EndDate,@EndDate) 
		  THEN CASE WHEN @EndDate <= ISNULL(EAD.EndDate,@EndDate) THEN @EndDate 
					WHEN EAD.EndDate <= @EndDate THEN EAD.EndDate 
					END
		  END Stage_End
INTO #HVES
FROM HVES
	
LEFT JOIN dbo.UC_Client_Exclusion_YWCA YWCA 
	ON YWCA.CLID = HVES.CL_EN_GEN_ID
	AND HVES.SiteID = 222
	
LEFT JOIN UV_EADT EAD
	ON HVES.CL_EN_GEN_ID = EAD.CLID
	AND HVES.ProgramID = EAD.ProgramID

LEFT JOIN 
	(SELECT 
		I.CL_EN_GEN_ID
		,I.ProgramID
		,(I.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
		,RANK() OVER(Partition By I.CL_EN_GEN_ID,I.ProgramID Order By I.SurveyDate DESC,I.SurveyResponseID DESC) Rank
	FROM Infant_Birth_Survey I
	WHERE I.INFANT_BIRTH_0_DOB IS NOT NULL) IBS
	ON HVES.CL_EN_GEN_ID = IBS.CL_EN_GEN_ID
	AND HVES.ProgramID = IBS.ProgramID
	AND IBS.Rank = 1

WHERE 
HVES.NURSE_PERSONAL_0_NAME IS NOT NULL
AND YWCA.CLID IS NULL
AND HVES.SurveyDate BETWEEN EAD.ProgramStartDate AND ISNULL(EAD.EndDate,@EndDate)
AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'

----- inprocess
SELECT H.*
	,DATEDIFF(DAY,H.Stage_Start,H.Stage_End) DaysDuring
	,CASE WHEN H.Stage = 1
		  THEN CASE WHEN DATEDIFF(WK,H.Stage_Start,H.ProgramStartDate) BETWEEN 0 AND 4 AND DATEDIFF(WK,H.ProgramStartDate,H.Stage_End) > 4 -- start in 4w
						THEN DATEDIFF(WK,H.Stage_Start,H.ProgramStartDate)
					WHEN DATEDIFF(WK,H.Stage_Start,H.ProgramStartDate) BETWEEN 0 AND 4 AND DATEDIFF(WK,H.ProgramStartDate,H.Stage_End) <= 4 -- start and end in 4w
						THEN DATEDIFF(WK,H.Stage_Start,H.Stage_End)
					WHEN DATEDIFF(WK,H.Stage_Start,H.ProgramStartDate) > 4 -- start after 4w
						THEN 0
					ELSE 4 END
		  WHEN H.Stage = 2
		  THEN CASE WHEN DATEDIFF(WK,H.Stage_Start,H.DOB) BETWEEN 0 AND 6 AND DATEDIFF(WK,H.DOB,H.Stage_End) >6 -- start in 6w
						THEN DATEDIFF(WK,H.Stage_Start,H.DOB)
					WHEN DATEDIFF(WK,H.Stage_Start,H.DOB) BETWEEN 0 AND 6 AND DATEDIFF(WK,H.DOB,H.Stage_End) <=6 -- start and end in 6w
						THEN DATEDIFF(WK,H.Stage_Start,H.Stage_End)
					WHEN DATEDIFF(WK,H.Stage_Start,H.DOB) > 6 -- start after 6w
						THEN 0
					ELSE 6 END
		  WHEN H.Stage = 3
		  THEN CASE WHEN DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_End) < 0 ----no time in 21+
						THEN 0
					WHEN DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_Start) < 0 AND DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_End) >= 0  ----some time in 21+
						THEN DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_End)
					WHEN DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_Start) >= 0 AND DATEDIFF(WK,DATEADD(MM,21,H.DOB),H.Stage_End) >= 0  ----all time in 21+
						THEN DATEDIFF(WK,H.Stage_Start,H.Stage_End)
					ELSE 6 END
		  END Stage_Add
INTO #HVES2
FROM #HVES H


SELECT 
	H.*
	,CASE WHEN H.Stage IN(1,2)
		  THEN FLOOR((DATEDIFF(WK,H.Stage_Start,H.Stage_End) + H.Stage_Add)/2)
		  WHEN H.Stage = 3
		  THEN FLOOR(DATEDIFF(WK,H.Stage_Start,H.Stage_End)/2)-FLOOR(H.Stage_Add/2)
		  END ExpVisits
	,ROW_NUMBER() OVER(PARTITION BY H.CL_EN_GEN_ID,H.ProgramID,H.Stage ORDER BY H.Survey) ClientRow
	,ROW_NUMBER() OVER(PARTITION BY H.CL_EN_GEN_ID,H.ProgramID,H.NURSE_PERSONAL_0_NAME,H.Stage ORDER BY H.Survey) ClientNurseRow
	,S.Full_Name
	,P.ProgramName
	,P.SiteID
	,P.Site
	,P.AGENCY_INFO_0_NAME
	,P.StateID
	,P.[US State]
	,P.Abbreviation
FROM #HVES2 H
INNER JOIN UV_PAS P
	ON H.ProgramID   = P.ProgramID
LEFT JOIN IA_Staff S
	ON H.NURSE_PERSONAL_0_NAME = S.Entity_Id
WHERE H.SurveyDate BETWEEN @StartDate AND @EndDate

GO
