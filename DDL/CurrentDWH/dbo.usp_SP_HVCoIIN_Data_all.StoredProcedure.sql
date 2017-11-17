USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_SP_HVCoIIN_Data_all]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SP_HVCoIIN_Data_all]



--DECLARE 
@Team VARCHAR(4000), @StartDate DATE, @EndDate DATE

--SET @Team = 1394
--SET @StartDate = CAST('1/1/2014' AS DATE)
--SET @EndDate = CAST('6/30/2014' AS DATE)

AS

SELECT 
	P.Abbreviation
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,P.SiteID
	,P.Team_Name
	,P.ProgramID
	,C.Last_Name
	,C.First_Name
	,EAD.ProgramStartDate
	,EAD.EndDate
	,HVES.CL_EN_GEN_ID
	,C.CaseNumber
	,CASE WHEN EAD.EndDate > @EndDate OR EAD.EndDate IS NULL THEN C.CaseNumber END CaseNumberActiveAtEnd
	,HVES.SurveyDate VisitDate
	,HVES_First.SurveyDate FirstVisit
	,DATEDIFF(Day,HVES2.SurveyDate,HVES.SurveyDate) Days_since_Last
	,r.SurveyDate referral
	,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
	,IBS.INFANT_BIRTH_0_DOB
	,DATEDIFF(Day,r.SurveyDate,EAD.ProgramStartDate) DaystoEnroll
FROM 
	(SELECT
		CL_EN_GEN_ID
		,ProgramID
		,SurveyDate
		,ROW_NUMBER() OVER(Partition By CL_EN_GEN_ID, ProgramID ORDER BY SurveyDate) VisitOrder
	FROM UC_Fidelity_HVES) HVES
	INNER JOIN UV_PAS P
		ON HVES.ProgramID = P.ProgramID
LEFT JOIN 
	(SELECT 
		ProgramID
		,CL_EN_GEN_ID
		,SurveyDate
		,ROW_NUMBER() OVER(Partition By CL_EN_GEN_ID, ProgramID ORDER BY SurveyDate) VisitOrder
	FROM UC_Fidelity_HVES) HVES2
	ON HVES.ProgramID = HVES2.ProgramID
	AND HVES.CL_EN_GEN_ID = HVES2.CL_EN_GEN_ID
	AND HVES.VisitOrder = HVES2.VisitOrder + 1
LEFT JOIN 
	(SELECT 
		ProgramID
		,CL_EN_GEN_ID
		,SurveyDate
		,ROW_NUMBER() OVER(Partition By CL_EN_GEN_ID, ProgramID ORDER BY SurveyDate) VisitOrder
	FROM UC_Fidelity_HVES) HVES_First
	ON HVES.ProgramID = HVES_First.ProgramID
	AND HVES.CL_EN_GEN_ID = HVES_First.CL_EN_GEN_ID
	AND HVES_First.VisitOrder = 1
LEFT OUTER JOIN UV_EADT EAD
	INNER JOIN Clients C
		ON EAD.CLID = C.Client_Id
	ON HVES.CL_EN_GEN_ID = EAD.CLID
LEFT JOIN 
	(SELECT S.CL_EN_GEN_ID, T.Program_ID_NHV ProgramID, Max(S.SurveyDate) SurveyDate 
	FROM Referrals_to_NFP_Survey S
	INNER JOIN Teams T 
		ON S.ProgramID = T.Program_ID_NHV
		OR S.ProgramID = T.Program_ID_Referrals
		OR S.ProgramID = T.Program_ID_Staff_Supervision
	GROUP BY S.CL_EN_GEN_ID, T.Program_ID_NHV) r
	ON HVES.CL_EN_GEN_ID = r.CL_EN_GEN_ID
	AND HVES.ProgramID = r.ProgramID
LEFT JOIN
	(SELECT CL_EN_GEN_ID,ProgramID,CLIENT_HEALTH_PREGNANCY_0_EDD FROM Maternal_Health_Survey) MHS
	ON HVES.CL_EN_GEN_ID = MHS.CL_EN_GEN_ID
	AND HVES.ProgramID = MHS.ProgramID
LEFT JOIN
	(SELECT CL_EN_GEN_ID,ProgramID,INFANT_BIRTH_0_DOB FROM Infant_Birth_Survey) IBS
	ON HVES.CL_EN_GEN_ID = IBS.CL_EN_GEN_ID
	AND HVES.ProgramID = IBS.ProgramID
WHERE HVES.ProgramID IN(SELECT * FROM dbo.udf_ParseMultiParam(@Team))
--AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate
--AND HVES.CL_EN_GEN_ID = 522270
AND EAD.ProgramStartDate <= @EndDate AND (EAD.EndDate >= @StartDate OR EAD.EndDate IS NULL)


ORDER BY HVES.VisitOrder

GO
