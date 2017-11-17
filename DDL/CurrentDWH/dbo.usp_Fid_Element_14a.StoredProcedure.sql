USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_14a]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_14a]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity VARCHAR(4000) 
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
--	,@ParentEntity VARCHAR(4000)
--	,@REName VARCHAR(50) 
--	,@ReportType INT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @Data			 = 0;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity VARCHAR(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rData INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rData			 = @Data;


IF @rData = 0
BEGIN

SELECT 

	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,FA.Meetings_team_curr
	,FA.Meetings_case_curr
	,FA.Meetings_team_comp
	,FA.Meetings_case_comp
	,FA.Meetings_length_team_curr
	,FA.Meetings_length_case_curr
	,FA.Meetings_length_team_comp
	,FA.Meetings_length_case_comp	
	,CAST(DATEDIFF(DAY,@rStartDate,@rEndDate)/7 AS INT) Weeks_in_Period_curr
	,CAST(DATEDIFF(DAY,@rCompStartDate,@rCompEndDate)/7 AS INT) Weeks_in_Period_comp
	

FROM dbo.fn_Fidelity_Agency(@rStartDate,@rEndDate,@rCompStartDate,@rCompEndDate,@rParentEntity,@rREName,@rReportType) FA
	INNER JOIN UV_PAS P
		ON FA.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)

WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

UNION

SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
      ,0,0,0,0,0,0,0,0,CAST(DATEDIFF(DAY,@rStartDate,@rEndDate)/7 AS INT) Weeks_in_Period_curr
	,CAST(DATEDIFF(DAY,@rCompStartDate,@rCompEndDate)/7 AS INT) Weeks_in_Period_comp
FROM UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

END

ELSE -------------------------- DATA RETURN -----------------------------
BEGIN
SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,COUNT(DISTINCT CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Team Meeting')
						AND TS.SurveyDate BETWEEN @rStartDate AND @rEndDate
					THEN TS.SurveyResponseID
				END) Meetings_team_curr
	,COUNT(DISTINCT CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Case Conference')
						AND TS.SurveyDate BETWEEN @rStartDate AND @rEndDate
					THEN TS.SurveyResponseID
				END) Meetings_case_curr
	,COUNT(DISTINCT CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Team Meeting')
						AND TS.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
					THEN TS.SurveyResponseID
				END) Meetings_team_comp
	,COUNT(DISTINCT CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Case Conference')
						AND TS.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
					THEN TS.SurveyResponseID
				END) Meetings_case_comp
				
				
	,SUM( CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Team Meeting')
						AND TS.SurveyDate BETWEEN @rStartDate AND @rEndDate
					THEN TS.AGENCY_MEETING_1_LENGTH
				END) Meetings_length_team_curr
	,SUM( CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Case Conference')
						AND TS.SurveyDate BETWEEN @rStartDate AND @rEndDate
					THEN TS.AGENCY_MEETING_1_LENGTH
				END) Meetings_length_case_curr
	,SUM( CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Team Meeting')
						AND TS.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
					THEN TS.AGENCY_MEETING_1_LENGTH
				END) Meetings_length_team_comp
	,SUM( CASE 
					WHEN TS.AGENCY_MEETING_0_TYPE  IN ('Case Conference')
						AND TS.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
					THEN TS.AGENCY_MEETING_1_LENGTH
				END) Meetings_length_case_comp
	,CAST(DATEDIFF(DAY,@rStartDate,@rEndDate)/7 AS INT) Weeks_in_Period_curr
	,CAST(DATEDIFF(DAY,@rCompStartDate,@rCompEndDate)/7 AS INT) Weeks_in_Period_comp
	,TS.SurveyResponseID
	,TS.RankingLatest
FROM (
		SELECT 
			RANK() OVER(PARTITION BY TS.SurveyDate,TS.CL_EN_GEN_ID,TS.ProgramID,TS.AGENCY_MEETING_0_TYPE 
				ORDER BY TS.SurveyDate DESC,TS.SurveyResponseID DESC) RankingLatest
			,TS.*
		FROM Team_Meetings_Conf_Survey TS
	) TS
	INNER JOIN UV_PAS P
		ON TS.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)
WHERE TS.RankingLatest = 1
	AND CASE
			WHEN @rReportType = 1 THEN 1
			WHEN @rReportType = 2 THEN P.StateID
			WHEN @rReportType = 3 THEN P.SiteID
			WHEN @rReportType = 4 THEN P.ProgramID
		  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
GROUP BY 
	P.SiteID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,TS.SurveyResponseID
	,TS.RankingLatest
END
GO
