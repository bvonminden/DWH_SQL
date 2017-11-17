USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_KM_ClientsToFTE]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_KM_ClientsToFTE]
(@StartDate DATE,@EndDate DATE,@Team nvarchar(4000))

AS
--DECLARE @StartDate DATE,@EndDate DATE
--SET @StartDate = CAST('1/1/2013' AS DATE)
--SET @EndDate = CAST('12/31/2013' AS DATE);

WITH Clients AS
(SELECT COUNT(DISTINCT EAD.CLID) clients, P.ProgramID, P.SiteID, P.StateID, @StartDate StartDate,@EndDate EndDate--, 1
FROM UV_EADT EAD
LEFT OUTER JOIN UV_PAS P
	ON EAD.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)
LEFT OUTER JOIN
	(SELECT DISTINCT HVES.CL_EN_GEN_ID,HVES.ProgramID
	FROM Home_Visit_Encounter_Survey HVES
	WHERE HVES.SurveyDate <= @EndDate
	AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed') HVES
	ON EAD.CLID = HVES.CL_EN_GEN_ID
	AND EAD.ProgramID = HVES.ProgramID
LEFT OUTER JOIN
	(SELECT AES.CL_EN_GEN_ID, AES.ProgramID
	FROM Alternative_Encounter_Survey AES
	WHERE AES.CLIENT_TALKED_0_WITH_ALT LIKE '%Client;%'
	OR AES.CLIENT_TALKED_0_WITH_ALT  = 'Client'
	AND AES.SurveyDate <= @EndDate) AES
	ON EAD.CLID = AES.CL_EN_GEN_ID
	AND EAD.ProgramID = AES.ProgramID
WHERE EAD.ProgramStartDate <= @EndDate 
	AND ISNULL(EAD.EndDate,@EndDate) >= @EndDate
	AND (HVES.CL_EN_GEN_ID IS NOT NULL OR AES.CL_EN_GEN_ID IS NOT NULL)
GROUP BY P.ProgramID, P.SiteID, P.StateID)

,Nurses AS
(SELECT
	S.ProgramID
	,S.SiteID
	,S.StateID
	,S.Entity_Id
	,(S.HV_FTE) SumFTE
	--,SUM(CASE WHEN (S.NHV_Flag = 1 OR ISNULL(S.HV_FTE,0) > 0) THEN S.Entity_Id END) CountNHV
	--,SUM(CASE WHEN (S.NHV_Flag = 1 ) THEN S.Entity_Id END) CountNHV2
	--,SUM(CASE WHEN S.NHV_Flag = 1 AND ISNULL(S.HV_FTE,0) = 0 THEN S.Entity_Id END) MissingFTE
	--,SUM(CASE WHEN S.HV_FTE > 0 AND ISNULL(S.NHV_Flag,0) = 0 THEN S.Entity_Id END) MissingPosition
FROM dbo.fn_FID_Staff_list (@StartDate,@EndDate) S
WHERE ISNULL(S.EndDate,GETDATE()) >= @EndDate)

,ProgramFTE AS
(SELECT DISTINCT
	DATA.StateID
	,DATA.SiteID
	,DATA.ProgramID
	,SUM(DATA.StateFTE) OVER(Partition By DATA.StateID) StateFTE
	,SUM(DATA.SiteFTE) OVER(Partition By DATA.SiteID) SiteFTE
	,SUM(DATA.ProgramFTE) OVER(Partition By DATA.ProgramID) ProgramFTE
FROM
	(SELECT
		N.Entity_Id
		,N.StateID
		,N.SiteID
		,N.ProgramID
		,ROW_NUMBER() OVER(Partition By N.Entity_Id,N.StateID Order By N.StateID) rstate
		,ROW_NUMBER() OVER(Partition By N.Entity_Id,N.SiteID Order By N.SiteID) rsite
		,ROW_NUMBER() OVER(Partition By N.Entity_Id,N.ProgramID Order By N.ProgramID) rteam
		,CASE WHEN ROW_NUMBER() OVER(Partition By N.Entity_Id,N.StateID Order By N.StateID,N.SumFTE DESC) = 1 THEN SumFTE END StateFTE
		,CASE WHEN ROW_NUMBER() OVER(Partition By N.Entity_Id,N.SiteID Order By N.SiteID,N.SumFTE DESC)  = 1 THEN SumFTE END SiteFTE
		,CASE WHEN ROW_NUMBER() OVER(Partition By N.Entity_Id,N.ProgramID Order By N.ProgramID,N.SumFTE DESC)  = 1 THEN SumFTE END ProgramFTE
		,SumFTE
	FROM Nurses N) DATA)

SELECT P.[US State],P.Abbreviation,P.StateID,P.Site,P.SiteID,P.Team_Name,P.ProgramID,C.clients,N.StateFTE,N.SiteFTE,N.ProgramFTE
FROM UV_PAS P
LEFT JOIN Clients C
	ON P.ProgramID = C.ProgramID
LEFT JOIN ProgramFTE N
	ON P.ProgramID = N.ProgramID
WHERE P.ProgramID IN(SELECT * FROM dbo.udf_ParseMultiParam(@Team))
ORDER BY P.[US State],P.Site,P.Team_Name
GO
