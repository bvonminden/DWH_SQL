USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_14b]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_14b]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Data INT
)

AS
--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@CompStartDate	Date 
--	,@CompEndDate	Date 
--	,@ParentEntity Varchar(4000)
--	,@REName VARCHAR(50) 
--	,@ReportType VARCHAR(50)
--	,@Data INT 
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 1
--SET @REName			 = NULL
--SET @ReportType		 =2
--SET @Data			 = 0;

DECLARE 
	@rStartDate Date
	,@rEndDate Date
	,@rCompStartDate Date
	,@rCompEndDate Date
	,@rParentEntity Varchar(4000)
	,@rREName Varchar(50)
	,@rReportType Varchar(50)
SET		@rStartDate = @StartDate
SET 	@rEndDate = @EndDate
SET 	@rCompStartDate = @CompStartDate
SET 	@rCompEndDate = @CompEndDate
SET 	@rParentEntity = @ParentEntity
SET 	@rREName = @REName
SET 	@rReportType = @ReportType;
	

WITH Staff AS
(
SELECT 
	S.ProgramID
	,CASE WHEN ISNULL(S.S_FTE,0)>0 OR S.NS_Flag = 1 THEN S.Entity_Id END Sup
	,S.Entity_Id Entity_Id
	,CASE WHEN (ISNULL(S.HV_FTE,0)>0 OR S.NHV_Flag = 1)
			AND (ISNULL(S.S_FTE,0)=0 AND S.NS_Flag = 0)
		  THEN S.Entity_Id END HV_COUNT_curr
FROM dbo.fn_FID_Staff_listv2 (@rStartDate,@rEndDate) S)
,Staffcomp AS
(SELECT 
	S.ProgramID
	,CASE WHEN ISNULL(S.S_FTE,0)>0 OR S.NS_Flag = 1 THEN S.Entity_Id END Sup
	,S.Entity_Id Entity_Id
	,CASE WHEN (ISNULL(S.HV_FTE,0)>0 OR S.NHV_Flag = 1)
			AND (ISNULL(S.S_FTE,0)=0 AND S.NS_Flag = 0)
		  THEN S.Entity_Id END HV_COUNT_curr
FROM dbo.fn_FID_Staff_listv2 (@rCompStartDate,@rCompEndDate) S)


SELECT 
	dbo.udf_StateVSTribal(ROOT.Abbreviation,ROOT.SiteID) [State]
	,ROOT.[US State]
	,ROOT.StateID
	,ROOT.SiteID [Site_ID]
	,ROOT.AGENCY_INFO_0_NAME
	,'' ProgramID
	,'' ProgramName
	,CASE WHEN ROOT.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN ROOT.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,COUNT(DISTINCT CASE 
						WHEN WS.SurveyDate BETWEEN @rStartDate AND @rEndDate 
						THEN WS.SurveyResponseID 
					END) Surv_Count_curr
	,COUNT(DISTINCT S.HV_COUNT_curr) HV_COUNT_curr 
	,CAST(COUNT(DISTINCT CASE 
						WHEN WS.SurveyDate BETWEEN @rStartDate AND @rEndDate 
						THEN WS.SurveyResponseID 
					END) AS FLOAT)/CASE COUNT(DISTINCT S.HV_COUNT_curr) WHEN 0 THEN 1 ELSE COUNT(DISTINCT S.HV_COUNT_curr) END MeetingAvg_curr
	,COUNT(DISTINCT S.Sup) Sup_curr
	,COUNT(DISTINCT CASE 
						WHEN WSC.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate 
						THEN WSC.SurveyResponseID 
					END) Surv_Count_comp
	,COUNT(DISTINCT SC.HV_COUNT_curr) HV_COUNT_comp 
	,CAST(COUNT(DISTINCT CASE 
						WHEN WSC.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
						THEN WSC.SurveyResponseID 
					END) AS FLOAT)/CASE COUNT(DISTINCT SC.HV_COUNT_curr) WHEN 0 THEN 1 ELSE COUNT(DISTINCT SC.HV_COUNT_curr) END MeetingAvg_comp
	,COUNT(DISTINCT SC.Sup) Sup_comp
FROM (
		SELECT 
			DISTINCT S.Entity_Id,P.*
		FROM dbo.fn_FID_Staff_listv2 (@rCompStartDate,@rEndDate) S
INNER JOIN UV_PAS P
	ON (S.ProgramID = P.Program_ID_NHV
	OR S.ProgramID = P.Program_ID_Referrals
	OR S.ProgramID = P.Program_ID_Staff_Supervision)
	AND P.SiteID = S.SiteID
	) ROOT


	
LEFT JOIN Staff S
	ON S.Entity_Id = ROOT.Entity_Id
	AND S.ProgramID = ROOT.ProgramID

LEFT JOIN Staffcomp SC
	ON SC.Entity_Id = ROOT.Entity_Id
	AND SC.ProgramID = ROOT.ProgramID

LEFT OUTER JOIN	Weekly_Supervision_Survey WS
	ON WS.NURSE_SUPERVISION_0_STAFF_SUP IN (S.Sup)
	AND WS.ProgramID IN (ROOT.Program_ID_NHV,ROOT.Program_ID_Referrals,ROOT.Program_ID_Staff_Supervision)
	AND WS.SurveyDate BETWEEN @rStartDate AND @rEndDate
LEFT OUTER JOIN	Weekly_Supervision_Survey WSC
	ON WS.NURSE_SUPERVISION_0_STAFF_SUP IN (SC.Sup)
	AND WSC.ProgramID IN (ROOT.Program_ID_NHV,ROOT.Program_ID_Referrals,ROOT.Program_ID_Staff_Supervision)
	AND WSC.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate	

WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN ROOT.StateID
		WHEN @rReportType = 3 THEN ROOT.SiteID
		WHEN @rReportType = 4 THEN ROOT.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))


GROUP BY dbo.udf_StateVSTribal(ROOT.Abbreviation,ROOT.SiteID) 
	,ROOT.[US State]
	,ROOT.StateID
	,ROOT.SiteID 
	,ROOT.AGENCY_INFO_0_NAME
	
UNION

SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,'' ProgramID
	,'' ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
      ,0,0,0,0,0,0,0,0
FROM UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
GO
